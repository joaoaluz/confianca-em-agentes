# Modelo: segredos e variáveis de ambiente

Para nunca mais travar no deploy por causa de senha, token ou chave, sem que nenhum valor real passe
pelo agente. O agente mantém o **mapa** (o manifesto) e usa a **máquina de gerar** (o script); os
valores de produção nascem no seu terminal e vão direto para o cofre.

| Arquivo | Vai para o projeto em | Para quê |
|---|---|---|
| `segredos.json` | `config/segredos.json` | O manifesto: cada variável, para quê, como gerar e em quais ambientes |
| `segredos.ps1` | `scripts/segredos.ps1` | Gera, confere e documenta, sem imprimir valores |

## Uso

```powershell
.\scripts\segredos.ps1 -Modo gerar -Ambiente dev      # cria ou completa o .env.local
.\scripts\segredos.ps1 -Modo verificar -Ambiente dev  # diz o que falta, sem mostrar valores
.\scripts\segredos.ps1 -Modo checar                   # no CI: configuração do Spring x manifesto
.\scripts\segredos.ps1 -Modo exemplo                  # gera o .env.example (só nomes)
.\scripts\segredos.ps1 -Modo gerar -Ambiente prod     # SÓ VOCÊ: gera e envia aos secrets do GitHub
```

- Roda no Windows PowerShell 5.1 e no PowerShell 7 (`pwsh`), inclusive no Linux do CI.
- `gerar` em dev e teste **mantém** o que já existe; `-Regerar` troca os valores.
- `gerar` em prod só cria o que ainda não existe no GitHub, exige terminal interativo e a
  confirmação digitada. Um agente não consegue rodar esse modo.
- Se uma senha de produção também precisa ser aplicada em outro sistema (ex.: o DBA cria o usuário
  no banco), use `-Mostrar` para vê-la uma única vez no **seu** terminal, ou automatize isso no pipeline.

## Tipos de geração

| No manifesto | O que gera | Uso típico |
|---|---|---|
| `senha:32` | 32 caracteres aleatórios (letras, números, `-` e `_`) | Senhas de banco e de usuários técnicos |
| `base64:32` | 32 bytes aleatórios em Base64 (256 bits) | Segredo JWT HS256, chave AES-256 |
| `hex:32` | 32 bytes aleatórios em hexadecimal | Tokens internos |
| `rsa:2048` | Par RSA; a privada (PEM, PKCS#8) vai em Base64 na variável e a pública fica em `.segredos/` | JWT RS256 |
| `fixo:<valor>` | O próprio valor (não é segredo) | URLs e usuários de dev e teste |
| `externo` | Nada: você obtém no serviço | Tokens de APIs de terceiros |

Para `rsa`, o script usa o openssl; o que vem com o Git para Windows serve.

## No `.gitignore`

```
.env.local
.env.*.local
.segredos/
```

O script avisa se algum desses arquivos não estiver ignorado.

## No Spring

```yaml
# src/main/resources/application.yml: placeholders SEM valor padrão
spring:
  datasource:
    url: ${SPRING_DATASOURCE_URL}
    username: ${SPRING_DATASOURCE_USERNAME}
    password: ${SPRING_DATASOURCE_PASSWORD}
app:
  jwt:
    secret: ${APP_JWT_SECRET}
```

```yaml
# src/main/resources/application-dev.yml: só no perfil de desenvolvimento
spring:
  config:
    import: optional:file:.env.local[.properties]
```

- Sem valor padrão, o Spring **não sobe** se faltar uma variável: o erro aparece no deploy, não em produção.
- Em produção, as variáveis de ambiente entram direto: `SPRING_DATASOURCE_PASSWORD` vira `spring.datasource.password`.
- Valide na subida, com `@ConfigurationProperties` e `@Validated` (registrada com `@ConfigurationPropertiesScan`):

```java
@Validated
@ConfigurationProperties(prefix = "app.jwt")
public record JwtProperties(@NotBlank String secret) {}
```

- Com RS256, a variável traz o PEM em Base64: decodifique com `Base64.getDecoder()` e leia como chave PKCS#8.

## Banco de teste com o mesmo arquivo

```yaml
# compose.yaml (trecho): suba com  podman compose --env-file .env.local up -d
services:
  oracle:
    image: gvenzl/oracle-free:23-slim
    ports: ["1521:1521"]
    environment:
      ORACLE_PASSWORD: ${ORACLE_ADMIN_PASSWORD}
      APP_USER: ${SPRING_DATASOURCE_USERNAME}
      APP_USER_PASSWORD: ${SPRING_DATASOURCE_PASSWORD}
```

O banco nasce com as mesmas senhas que o Spring vai usar, sem ninguém digitar nada.

## No CI e no deploy (GitHub Actions)

```yaml
# conferir o manifesto em todo PR
- name: Conferir manifesto de segredos
  run: pwsh scripts/segredos.ps1 -Modo checar
```

```yaml
# deploy: os valores vêm do ambiente "prod" do GitHub
jobs:
  deploy:
    environment: prod
    steps:
      - run: ./deploy.sh
        env:
          SPRING_DATASOURCE_PASSWORD: ${{ secrets.SPRING_DATASOURCE_PASSWORD }}
          APP_JWT_SECRET: ${{ secrets.APP_JWT_SECRET }}
```

## O que foi testado

No Windows PowerShell 5.1, num projeto Spring de exemplo:
- a geração dos tipos (senha de 32 caracteres, Base64 de 32 bytes e par RSA válido);
- a manutenção dos valores numa segunda rodada;
- `verificar` e `checar`, com configuração boa e ruim, incluindo os códigos de saída;
- o bloqueio do modo prod sem terminal interativo;
- o aviso de `.gitignore`.

O envio ao GitHub (`gh`) **não** foi testado, porque o GitHub CLI não está instalado nesta máquina.
