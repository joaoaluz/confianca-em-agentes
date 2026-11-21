<#
.SYNOPSIS
  Gera, confere e documenta os segredos e variáveis de ambiente descritos no manifesto
  (config/segredos.json). O script nunca imprime o valor de um segredo, exceto com -Mostrar
  no modo remoto, que só uma pessoa num terminal interativo consegue usar.

.DESCRIPTION
  Modos:
    gerar      dev/teste: cria ou completa o arquivo local (.env.local, .env.teste.local)
               com valores novos e descartáveis. Mantém o que já existe (use -Regerar para trocar).
               Outros ambientes (ex.: prod): gera e envia direto ao GitHub (gh), só para o que
               ainda não existe lá, depois de uma confirmação digitada. Só humanos.
    verificar  Lista o que falta num ambiente, sem mostrar valores.
    checar     (CI) Toda variável ${NOME} da configuração do Spring precisa estar no manifesto,
               e nenhum segredo pode ter valor padrão.
    exemplo    Gera o .env.example, só com nomes e descrições.

  Tipos de geração no manifesto:
    senha:N      N caracteres aleatórios (A-Z, a-z, 0-9, - e _)
    base64:N     N bytes aleatórios em Base64 (base64:32 = 256 bits: JWT HS256, AES-256)
    hex:N        N bytes aleatórios em hexadecimal
    rsa:BITS     par RSA via openssl; a chave privada (PEM) vai em Base64 na variável e a
                 chave pública fica em .segredos/
    fixo:VALOR   o próprio valor (configuração que não é segredo)
    externo      não se gera: a pessoa obtém no serviço e cadastra

.EXAMPLE
  .\scripts\segredos.ps1 -Modo gerar -Ambiente dev
  .\scripts\segredos.ps1 -Modo verificar -Ambiente dev
  .\scripts\segredos.ps1 -Modo checar
  .\scripts\segredos.ps1 -Modo exemplo
  .\scripts\segredos.ps1 -Modo gerar -Ambiente prod      # só humanos, num terminal interativo
#>
[CmdletBinding()]
param(
    [ValidateSet('gerar', 'verificar', 'checar', 'exemplo')]
    [string]$Modo = 'gerar',
    [string]$Ambiente = 'dev',
    [string]$Manifesto = 'config/segredos.json',
    [string]$Arquivo = '',
    [string[]]$PastasConfig = @('src/main/resources'),
    [switch]$Regerar,
    [switch]$Mostrar
)

$ErrorActionPreference = 'Stop'
$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create()
$alfabeto = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'   # 64 símbolos: sem viés
$ambientesLocais = @('dev', 'teste')
$remoto = $ambientesLocais -notcontains $Ambiente

function Get-BytesAleatorios([int]$Quantidade) {
    $bytes = New-Object byte[] $Quantidade
    $rng.GetBytes($bytes)
    return , $bytes
}

function Write-Texto([string]$Caminho, [string[]]$Linhas) {
    $completo = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Caminho)
    [IO.File]::WriteAllLines($completo, $Linhas, (New-Object System.Text.UTF8Encoding $false))
}

function Invoke-Nativo([scriptblock]$Comando) {
    # Roda um programa externo sem que mensagens em stderr virem erro fatal; devolve o código de saída.
    $anterior = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Comando 2>&1 | Out-Null; return $LASTEXITCODE }
    finally { $ErrorActionPreference = $anterior }
}

function Find-OpenSsl {
    $cmd = Get-Command openssl -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    if ($env:ProgramFiles) {
        $doGit = Join-Path $env:ProgramFiles 'Git\usr\bin\openssl.exe'   # vem com o Git para Windows
        if (Test-Path $doGit) { return $doGit }
    }
    return $null
}

function New-ChaveRsa([string]$Nome, [int]$Bits, [string]$Pasta) {
    $openssl = Find-OpenSsl
    if (-not $openssl) { return $null }
    # Caminho absoluto: o .NET resolve caminhos relativos pela pasta do processo, não pela do PowerShell.
    $Pasta = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Pasta)
    New-Item -ItemType Directory -Force -Path $Pasta | Out-Null
    $privada = Join-Path $Pasta "$Nome.pem"
    $publica = Join-Path $Pasta "$Nome.pub.pem"
    $c1 = Invoke-Nativo { & $openssl genpkey -algorithm RSA -pkeyopt "rsa_keygen_bits:$Bits" -out $privada }
    $c2 = Invoke-Nativo { & $openssl pkey -in $privada -pubout -out $publica }
    if ($c1 -ne 0 -or $c2 -ne 0) { throw "O openssl falhou ao gerar a chave RSA de $Nome." }
    $valor = [Convert]::ToBase64String([IO.File]::ReadAllBytes($privada))
    return @{ Valor = $valor; Privada = $privada; Publica = $publica }
}

function New-Valor($Item, [string]$PastaChaves) {
    $tipo, $parametro = $Item.gerar -split ':', 2
    switch ($tipo) {
        'senha' {
            $bytes = Get-BytesAleatorios ([int]$parametro)
            return @{ Valor = -join ($bytes | ForEach-Object { $alfabeto[$_ -band 63] }) }
        }
        'base64' { return @{ Valor = [Convert]::ToBase64String((Get-BytesAleatorios ([int]$parametro))) } }
        'hex' { return @{ Valor = -join ((Get-BytesAleatorios ([int]$parametro)) | ForEach-Object { $_.ToString('x2') }) } }
        'rsa' { return New-ChaveRsa $Item.nome ([int]$parametro) $PastaChaves }
        'fixo' { return @{ Valor = $parametro; Fixo = $true } }
        'externo' { return $null }
        default { throw "Tipo de geração desconhecido em $($Item.nome): $($Item.gerar)" }
    }
}

function Read-ArquivoEnv([string]$Caminho) {
    $valores = [ordered]@{}
    if (Test-Path $Caminho) {
        foreach ($linha in Get-Content -Path $Caminho) {
            if ($linha -match '^\s*([A-Za-z_][A-Za-z0-9_.]*)\s*=(.*)$') { $valores[$Matches[1]] = $Matches[2] }
        }
    }
    return $valores
}

function Test-Ignorado([string]$Caminho) {
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) { return $true }
    $codigo = Invoke-Nativo { git check-ignore -q $Caminho }
    return ($codigo -eq 0 -or $codigo -eq 128)   # 128: não é um repositório git
}

function Get-NomesRemotos([string]$Amb) {
    $anterior = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $linhas = @(& gh secret list --env $Amb 2>$null) + @(& gh variable list --env $Amb 2>$null)
    } finally { $ErrorActionPreference = $anterior }
    return @($linhas | Where-Object { $_ } | ForEach-Object { ($_ -split '\s+')[0] })
}

# ---------- manifesto ----------
if (-not (Test-Path $Manifesto)) { throw "Manifesto não encontrado: $Manifesto" }
$itens = @((Get-Content -Raw -Encoding UTF8 -Path $Manifesto | ConvertFrom-Json).segredos)
$doAmbiente = @($itens | Where-Object { $_.ambientes -contains $Ambiente })
if (-not $Arquivo) {
    $Arquivo = if ($Ambiente -eq 'dev') { '.env.local' } else { ".env.$Ambiente.local" }
}

switch ($Modo) {
    'exemplo' {
        $linhas = @('# Gerado por scripts/segredos.ps1 a partir do manifesto. NUNCA coloque valores aqui.', '')
        foreach ($i in $itens) {
            $linhas += "# $($i.para_que) | gerar: $($i.gerar) | ambientes: $($i.ambientes -join ', ')"
            $linhas += "$($i.nome)="
            $linhas += ''
        }
        Write-Texto '.env.example' $linhas
        Write-Host ".env.example atualizado com $($itens.Count) variáveis."
    }

    'checar' {
        $porNome = @{}
        foreach ($i in $itens) { $porNome[$i.nome] = $i }
        $arquivos = @(foreach ($p in $PastasConfig) {
                if (Test-Path $p) { Get-ChildItem -Path $p -Recurse -File -Include 'application*.yml', 'application*.yaml', 'application*.properties' }
            })
        $erros = @()
        $total = 0
        foreach ($a in $arquivos) {
            $texto = Get-Content -Raw -Path $a.FullName
            if (-not $texto) { continue }
            foreach ($m in [regex]::Matches($texto, '\$\{([A-Z][A-Z0-9_]*)(:[^}]*)?\}')) {
                $total++
                $nome = $m.Groups[1].Value
                if (-not $porNome.ContainsKey($nome)) {
                    $erros += "$($a.Name): $nome não está no manifesto ($Manifesto)"
                }
                elseif ($m.Groups[2].Success -and $porNome[$nome].gerar -notlike 'fixo*') {
                    $erros += "$($a.Name): $nome é segredo e não pode ter valor padrão"
                }
            }
        }
        if ($erros.Count) {
            Write-Host 'Problemas na configuração:'
            $erros | ForEach-Object { Write-Host "  - $_" }
            exit 1
        }
        Write-Host "Ok: $total referências em $($arquivos.Count) arquivo(s), todas no manifesto e sem valor padrão em segredos."
    }

    'verificar' {
        if ($remoto) {
            $presentes = Get-NomesRemotos $Ambiente
        }
        else {
            $locais = Read-ArquivoEnv $Arquivo
            $presentes = @($locais.Keys | Where-Object { $locais[$_] })
        }
        $faltando = @($doAmbiente | Where-Object { $presentes -notcontains $_.nome })
        if ($faltando.Count) {
            Write-Host "Faltam $($faltando.Count) de $($doAmbiente.Count) em '$Ambiente':"
            $faltando | ForEach-Object { Write-Host "  - $($_.nome): $($_.para_que) (gerar: $($_.gerar))" }
            exit 1
        }
        Write-Host "Ok: os $($doAmbiente.Count) itens de '$Ambiente' existem (valores não exibidos)."
    }

    'gerar' {
        if (-not $remoto) {
            $atuais = Read-ArquivoEnv $Arquivo
            $saida = [ordered]@{}
            $relatorio = @()
            foreach ($i in $doAmbiente) {
                $existente = $atuais[$i.nome]
                if ($existente -and -not $Regerar) {
                    $saida[$i.nome] = $existente
                    $relatorio += [pscustomobject]@{ Nome = $i.nome; Situacao = 'mantido' }
                    continue
                }
                $novo = New-Valor $i '.segredos'
                if ($null -eq $novo) {
                    $saida[$i.nome] = ''
                    $relatorio += [pscustomobject]@{ Nome = $i.nome; Situacao = "PREENCHA: $($i.para_que)" }
                    continue
                }
                $saida[$i.nome] = $novo.Valor
                $situacao = 'gerado'
                if ($novo.Fixo) { $situacao = 'fixo' }
                elseif ($novo.Publica) { $situacao = "gerado (chave pública em $($novo.Publica))" }
                $relatorio += [pscustomobject]@{ Nome = $i.nome; Situacao = $situacao }
            }
            foreach ($k in @($atuais.Keys)) {
                if (-not $saida.Contains($k)) {
                    $saida[$k] = $atuais[$k]
                    $relatorio += [pscustomobject]@{ Nome = $k; Situacao = 'fora do manifesto (mantido)' }
                }
            }
            $linhas = @("# Gerado por scripts/segredos.ps1 (ambiente $Ambiente). Não versione este arquivo.")
            foreach ($k in $saida.Keys) { $linhas += "$k=$($saida[$k])" }
            Write-Texto $Arquivo $linhas
            $relatorio | Format-Table -AutoSize | Out-String | Write-Host
            foreach ($caminho in @($Arquivo, '.segredos')) {
                if ((Test-Path $caminho) -and -not (Test-Ignorado $caminho)) {
                    Write-Warning "$caminho não está no .gitignore: acrescente antes de qualquer commit."
                }
            }
            break
        }

        # ----- ambiente remoto (ex.: prod): só humanos -----
        if ([Console]::IsInputRedirected) {
            throw "O ambiente '$Ambiente' só pode ser gerado por uma pessoa, num terminal interativo."
        }
        if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
            throw 'GitHub CLI (gh) não encontrado. Instale com: winget install --id GitHub.cli -e'
        }
        $existentes = Get-NomesRemotos $Ambiente
        $alvo = @($doAmbiente | Where-Object { $Regerar -or ($existentes -notcontains $_.nome) })
        if (-not $alvo.Count) { Write-Host "Nada a fazer: tudo de '$Ambiente' já existe no GitHub."; break }
        Write-Host "Vou gerar $($alvo.Count) item(ns) e enviar ao ambiente '$Ambiente' do GitHub." -ForegroundColor Yellow
        if ($Regerar) { Write-Host 'Com -Regerar, valores existentes serão TROCADOS: atualize também quem usa cada um (ex.: a senha no banco).' -ForegroundColor Yellow }
        $confirmacao = Read-Host 'Para confirmar, digite o nome do ambiente'
        if ($confirmacao -ne $Ambiente) { Write-Host 'Cancelado.'; exit 1 }

        $pastaTemporaria = Join-Path ([IO.Path]::GetTempPath()) ('segredos-' + [guid]::NewGuid())
        try {
            foreach ($i in $alvo) {
                $novo = New-Valor $i $pastaTemporaria
                if ($null -eq $novo) {
                    Write-Host "$($i.nome): cadastre você mesmo com: gh secret set $($i.nome) --env $Ambiente"
                    continue
                }
                if ($novo.Fixo) {
                    $codigo = Invoke-Nativo { gh variable set $i.nome --env $Ambiente --body $novo.Valor }
                }
                else {
                    $codigo = Invoke-Nativo { $novo.Valor | gh secret set $i.nome --env $Ambiente }
                }
                if ($codigo -ne 0) { throw "Falha ao enviar $($i.nome) para o GitHub." }
                $extra = ''
                if ($novo.Publica) {
                    New-Item -ItemType Directory -Force -Path '.segredos' | Out-Null
                    $destino = Join-Path '.segredos' "$($i.nome).$Ambiente.pub.pem"
                    Copy-Item $novo.Publica $destino -Force
                    $extra = " (chave pública em $destino)"
                }
                Write-Host "$($i.nome): enviado$extra"
                if ($Mostrar -and -not $novo.Fixo) {
                    Write-Host "  valor (anote onde precisar e limpe a tela): $($novo.Valor)" -ForegroundColor DarkYellow
                }
            }
        }
        finally {
            if (Test-Path $pastaTemporaria) { Remove-Item -Recurse -Force $pastaTemporaria }
        }
    }
}

exit 0   # sucesso explícito: sem isto, o código de saída herdaria o do último programa externo
