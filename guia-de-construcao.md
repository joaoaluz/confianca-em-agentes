# Guia de construção: confiar em agentes sem revisar tudo

Este guia é para **você** ler. Ele explica por que cada peça existe, como construir a sua e como
saber quando dar mais autonomia aos agentes. O playbook `implantar-confianca.md` é a parte que o
Claude executa; este é o manual para entender, ajustar e evoluir o que ele criou.

Base: três palestras de Lauren Tan (links na seção 15), mais o estado da arte de 2025–2026.
Pensado para quem tem planos Pro (Claude Code e Codex), não orçamento de laboratório.

---

## 1. O objetivo realista: revisão por exceção

Nenhuma fonte séria propõe "ninguém olha nada". O que muda é **onde** fica a sua atenção:

| Você passa a revisar | Em vez de |
|---|---|
| A **intenção**: specs, critérios de aceite, cenários holdout | O código linha por linha |
| As **evidências** dos PRs amarelos: testes, prints, vídeos | O diff inteiro |
| O **código** só dos PRs vermelhos (auth, pagamentos, migrações…) | Tudo, com o mesmo peso |
| O **sistema**: falhas que viram regras, métricas que decidem a autonomia | Os mesmos erros, toda semana |

O fluxo completo:

```
você aprova a spec ──► agente implementa ──► barreiras determinísticas ──► avaliador independente
                                                                                   │
                                                              classificador de risco
                                                                                   │
                     verde: merge automático ◄──────────────────────────────────────┤
                     amarelo: você olha as evidências ◄─────────────────────────────┤
                     vermelho: você revisa o código ◄───────────────────────────────┘

depois do merge: feature flags, monitoramento, reversão rápida, métricas
                 └──► promovem ou rebaixam a autonomia de cada tipo de mudança
```

---

## 2. O que o estado da arte diz (2025–2026)

| Fonte | Ideia central | Onde entra |
|---|---|---|
| **Lauren Tan** (3 palestras) | Pirâmide: código → checagens → verificação → texto. Lint com mensagem para o agente. Evidências no lugar de ler código. 11.000 PRs/mês com ~0,5% de reversão | Fases 2, 6, 9 |
| **Anthropic**, harness para agentes longos (nov/2025) | Lista de funcionalidades em JSON, todas "falhando" no início; um item por vez; teste de ponta a ponta no navegador; proibido editar testes | Fases 4, 5 |
| **Anthropic**, design de harness (mar/2026) | Planejador, gerador e avaliador separados. Um avaliador **cético e calibrado** é mais fácil de conseguir do que um gerador autocrítico. Limite duro por critério | Fases 4, 7 |
| **OpenAI**, harness engineering (fev/2026) | ~1 milhão de linhas sem código escrito à mão. `AGENTS.md` de ~100 linhas como mapa; docs como sistema de registro; arquitetura em camadas checada por linters com mensagens de correção; revisão entre agentes; agentes de limpeza recorrentes | Fases 2, 3, 6, 10 |
| **StrongDM**, software factory (fev/2026) | Cenários **holdout** fora do código, para o agente não otimizar para eles; "gêmeos digitais" de serviços externos; ninguém lê o código | Fase 5 |
| **DORA 2025** | IA é um **amplificador**: melhora o que é bom e piora o que é ruim. Lotes pequenos, controle de versão forte e boa plataforma interna fazem a diferença | Fases 8, 9 |
| **Meta**, testes guiados por mutação (2025) | Testes gerados a partir de mutantes pegam falhas que a cobertura de linhas não mostra | Fase 5 |
| **Pesquisa sobre trapaça** (2026) | Agentes burlam testes mesmo instruídos a não fazê-lo. A defesa é mecânica: testes só-leitura e conjuntos escondidos | Fase 5 |
| **Augment Code** (set/2026) | Níveis por tipo de mudança: sinalizar, bloquear, aprovar. Promoção quando reversões e incidentes ficam ≤ à base humana; rebaixamento automático; troca de modelo zera a amostra | Fases 8, 10 |
| **Monperrus**, "The End of Code Review" (jun/2026) | Aprovação estruturada por agentes no lugar do "ok" humano, mas humanos para alto risco, arquitetura nova e código regulado. Cuidado com pontos cegos em comum e injeção de prompt no revisor | Fases 7, 8 |
| **SlopCodeBench** (2026) | O código de agentes piora a cada rodada (erosão e verbosidade subiram em ~3 de 4 execuções); pedir qualidade no prompt não segura a piora | Fases 2, 9 |
| **GitHub Spec Kit** | Spec, plano e tarefas antes do código, com Claude Code, Codex e outros agentes | Fase 4 |
| **Claude Code** (docs 2026) | Hooks, permissões, sandbox, modo auto, subagentes, Code Review multiagente | Todas |

### Onde as fontes divergem

- **StrongDM** e **OpenAI** dizem que humanos não precisam revisar código. Mas a OpenAI avisa que
  as barreiras mínimas de merge dela seriam "irresponsáveis" num ambiente de pouco volume, e a
  StrongDM gasta cerca de US$ 1.000 por engenheiro por dia em tokens.
- **Augment**, **Monperrus** e **DORA** mantêm humanos no alto risco e pedem autonomia
  **conquistada com dados**.
- Muitos números são autodeclarados ou vêm de fornecedores. Use como referência do que é
  possível, não como meta.

O playbook fica no meio-termo: **autonomia por tipo de mudança, promovida por métricas e retirada
automaticamente quando algo escapa.**

---

## 3. A pirâmide completa

A pirâmide de Lauren Tan (palestra "All Code Is Slop"), mais o que a envolve:

| Camada | Pergunta que ela responde | Fase |
|---|---|---|
| Contenção | "Se der errado, quanto estrago faz?" | 1 |
| 1. O próprio código | "O jeito certo é o caminho mais curto?" | 2 |
| 2. Checagens estáticas e testes | "O jeito errado quebra o build?" | 2, 5 |
| 3. Verificação (execução e formal) | "Funciona de verdade? O agente entendeu a intenção?" | 6 |
| 4. Texto (regras, skills, `CLAUDE.md`) | "O que exige julgamento?" | 3 |
| Intenção | "O que exatamente queremos?" | 4 |
| Julgamento independente | "Alguém que não fez concorda?" | 7 |
| Política de risco | "Quem precisa olhar isto?" | 8 |
| Rede pós-merge | "Se escapar, percebemos e voltamos rápido?" | 9 |
| Autonomia medida | "Os números permitem confiar mais?" | 10 |

---

## 4. Ordem de construção

**Antes: nem todo projeto precisa de tudo.** Três perguntas decidem quanto aplicar: quanto tempo o
código vai viver, quanto custa um erro que escapa e quantas mudanças acontecem por semana. A Fase 0
do playbook escolhe um perfil (protótipo, projeto pessoal, produto, regulado, infra, biblioteca,
hardware, legado, app com IA, app mobile) e, com ele, as fases que se aplicam e o teto de autonomia.

Em qualquer perfil vale o mínimo: o agente sem credenciais de produção, a prova de que funciona,
lint, tipos e testes automáticos, correção repetida virando regra e PRs pequenos.

A tabela abaixo é o caminho completo, o de um produto com usuários:

| Semana | Fases | Pronto quando |
|---|---|---|
| 1 | 0 e 1 | Linha de base medida; segredos fora do alcance; caminhos protegidos |
| 2 | 2 | Uma violação real foi barrada pelo hook e corrigida pelo Claude sozinho |
| 3 | 3 e 4 | `CLAUDE.md` curto; uma spec aprovada antes do código |
| 4 | 5 | Testes de aceitação protegidos; primeiros holdouts; primeiro relatório de mutação |
| 5 | 6 | `scripts/verificar` gera evidências que você confere em 1 minuto |
| 6 | 7 | Avaliador concorda com você nos exemplos de calibração |
| 7–8 | 8 em modo sombra | 20 a 30 PRs classificados, com você revisando tudo e comparando |
| depois | 9 e 10 | Merge automático do verde ligado; métricas mensais; um agente agendado |

Com dois agentes, a Fase 3 inclui um `AGENTS.md` único (seção 9). Com o Spec Kit, a Fase 4 usa os
comandos dele (seção 10). Em fluxos com dados, as Fases 1, 5 e 6 ganham o ambiente de teste da seção 11.

---

## 5. Como construir cada peça

### 5.1 Mensagens de lint para agentes

O hook entrega a mensagem do lint ao Claude no momento exato do erro. Então ela é uma instrução:

| Ruim | Boa |
|---|---|
| `no-restricted-syntax: setTimeout` | `setTimeout não é permitido em componentes: costuma esconder um problema de estado. Use <padrão> ou mova a lógica para <lugar>.` |
| `import not allowed` | `ui/ não pode importar db/. Passe pelos serviços em services/<domínio>.` |

### 5.2 Skills

- **A `description` decide quando a skill é usada.** Comece com "Use quando…" e descreva a situação.
- **Curta**, no imperativo, com passos verificáveis ("cite arquivo e linha", não "seja cuidadoso").
- **Comandos reais e testados.** Um comando errado na skill é pior que nenhum.
- **Uma intenção por skill.** Prefira um script estável (`scripts/verificar`) a 15 passos descritos em texto.

### 5.3 Specs que dá para revisar em 2 minutos

- Critérios **observáveis**: "Dado / quando / então", com um resultado que dá para ver ou medir.
- "Fora do escopo" explícito: evita que o agente "aproveite para melhorar" outras coisas.
- **Plano de verificação**: para cada critério, como será provado e qual evidência você vai ver.
- Specs enxutas. Specs que crescem demais fazem o agente perder o fio.

### 5.4 Testes à prova de trapaça

| Técnica | Que trapaça ela impede |
|---|---|
| Aceitação escrita primeiro e protegida pelo hook | Apagar ou afrouxar o teste para passar |
| Cenários holdout fora do repositório | Otimizar para os testes que o agente consegue ver |
| Mutação nos arquivos alterados | Testes que passam, mas não pegam nada |
| Testes de propriedade | Tratar só os casos que estão no teste |
| Sinais no CI (`skip`, teste apagado, cobertura em queda) | Esconder a trapaça no meio de um PR grande |

### 5.5 Evidências que valem mais que ler o código

Peça sempre: saída dos testes de aceitação, prints ou vídeo do fluxo, diagrama de estados quando o
fluxo mudou, e a seção "o que não foi verificado". Para conferir um PR amarelo em 1 minuto:

1. A evidência cobre **cada** critério da spec?
2. O vídeo ou print mostra o resultado esperado, sem erro no console?
3. O que ficou sem verificar é aceitável?

Se alguma resposta for "não", devolva o PR; não comece a ler o código.

### 5.6 O avaliador cético

- **Separado** de quem implementou, e de preferência **outro modelo**.
- Instrução explícita para procurar motivos para **não** aprovar e para verificar tudo sozinho.
- **Limite duro** por critério: um critério falhou, reprovou.
- **Calibrado com exemplos seus.** O avaliador padrão tende a "se convencer" de que problemas são
  aceitáveis. Compare os vereditos dele com o seu julgamento e ajuste até concordar.
- Ele trata o diff como **dado**: conteúdo do PR pode tentar manipulá-lo (injeção de prompt).

### 5.7 Hooks: o que cada evento consegue fazer

| Evento | Quando roda | Como barra | Uso típico |
|---|---|---|---|
| `PreToolUse` | Antes de uma ação | Código 2, ou JSON com `permissionDecision: "deny"` e o motivo | Proteger testes, migrações, CI, segredos |
| `PostToolUse` | Depois de uma edição | Não desfaz; o código 2 entrega o erro ao Claude | Lint do arquivo editado |
| `Stop` | Quando o Claude vai encerrar | Código 2, ou `"decision": "block"` com `reason` | Não encerrar com testes quebrados |

Boas práticas:
- **Rápido** (segundos). Um hook lento em toda edição deixa tudo arrastado.
- **Mensagem útil**: diga o que está errado e como corrigir.
- No `Stop`, saia com 0 quando `stop_hook_active` for `true`, senão vira loop (o Claude Code
  também limita as continuações seguidas).
- **Teste à mão** simulando a entrada antes de confiar.
- **Versione** `.claude/settings.json` e os scripts. Preferências só suas vão em `.claude/settings.local.json`.
- Hooks de Edit/Write não veem escrita feita por Bash: o CI é a rede de segurança final.

### 5.8 Contenção

- **Permissões:** ordem deny → ask → allow. Regras de Bash comparam texto e podem ser
  contornadas; servem de conveniência, não de muro.
- **Sandbox:** isola comandos com restrição de arquivos e de rede. Roda em macOS, Linux e WSL2,
  **não no Windows nativo**. No seu PC, use WSL2, um devcontainer ou sessões na nuvem para
  trabalho autônomo.
- **Modo `auto`:** um classificador confere as ações arriscadas antes de rodarem. É a alternativa
  segura a pular permissões; `bypassPermissions` só em ambiente isolado.
- **Credenciais:** o agente nunca tem acesso de produção. O que ele não alcança, ele não estraga.

### 5.9 Medindo o slop

O SlopCodeBench mostrou que o código de agentes piora a cada rodada de mudanças: em cerca de 3 de
cada 4 execuções, a complexidade se concentrou em funções gigantes e as repetições aumentaram. O
código saiu 2,3 vezes mais verboso e 2 vezes mais erodido que o de projetos de código aberto
escritos por pessoas. E pedir qualidade no prompt reduziu o slop inicial, mas não a velocidade da piora.

Na prática:
- **Limite duro:** complexidade de no máximo 10 por função, no lint, com uma mensagem que ensina a
  dividir a função.
- **Duplicação que nunca sobe:** um detector (ex.: jscpd) no CI, com o limite no valor atual.
- **Dois números por mês:** erosão (quanto da complexidade está em funções acima do limite) e
  verbosidade (percentual de linhas duplicadas). Se subirem, é sinal para o agente de limpeza.

São indicadores, não verdade absoluta: os próprios autores dizem que "slop" ainda não tem uma
definição precisa.

### 5.10 Segredos e variáveis de ambiente

O agente **nunca** vê nem entrega o valor de um segredo real: tudo o que passa por ele vai para o
provedor do modelo e fica no histórico. Ele mantém um **manifesto** (cada variável, para quê, como
gerar e em quais ambientes) e usa um **script** que gera cada valor com o algoritmo certo:
- em dev, valores descartáveis no `.env.local`, sem mostrar;
- em produção, só você roda o script, e os valores vão direto para o cofre.

No CI, uma checagem garante que toda variável usada pelo Spring está no manifesto e que nenhum
segredo tem valor padrão. Cada PR termina com a seção "Configuração": o que é novo, como gerar e
onde cadastrar. Detalhes na Fase 1.7 do playbook; modelos testados em `modelos/segredos/`.

---

## 6. A política de risco na prática

**Os três níveis**

- **Verde:** nada sensível, PR pequeno, nenhum sinal de alerta. Entra sozinho quando todas as
  barreiras passam (depois do modo sombra).
- **Amarelo:** toca algo compartilhado, adiciona dependência, mexe em testes existentes ou é
  grande. Você olha as evidências (seção 5.5).
- **Vermelho:** auth, pagamentos, dados pessoais, migrações, infra, CI, teste de aceitação
  alterado, ou o agente declarou confiança baixa. Você revisa o código.

**Por que o modo sombra:** durante 20 a 30 PRs, o classificador e o avaliador trabalham, mas você
revisa tudo e anota onde discordou deles. É a forma barata de descobrir se o seu mapa de risco e o
seu avaliador merecem confiança **antes** de deixar algo entrar sozinho.

**Calibração honesta:** o agente declarar "confiança baixa" e pedir para escalar é algo bom. Um
agente que nunca escala é um sinal de alerta, não de qualidade.

---

## 7. A escada de autonomia

| Nível | Como você trabalha | Para subir ao próximo |
|---|---|---|
| **0. Você lê tudo** | Como hoje | Linha de base medida (Fase 0) |
| **1. O agente prova** | Você lê o código **e** as evidências | Nas últimas 10 tarefas, o agente provou o resultado sem você colar nada no chat |
| **2. Revisão por evidências** | Verde e amarelo: só evidências. Vermelho: código | Avaliador concordou com você nos exemplos e em ~20 PRs reais |
| **3. Merge automático do verde** | Verde entra sozinho; amarelo por evidências; vermelho por código | Modo sombra sem nenhum problema relevante passando pelo verde; reversões ≤ linha de base |
| **4. Fábrica** | Agentes agendados abrem PRs; tipos de mudança promovidos por métricas | 2 meses ou mais no nível 3 sem incidente; métricas mensais estáveis |

O merge automático **não é obrigatório**. Para muitos projetos, o nível 2 já devolve a maior parte
do seu tempo. E a escada também desce: incidente rebaixa, troca de modelo recomeça o modo sombra.

---

## 8. Orçamento: fazer isso num plano Pro

Nos planos Pro você não paga por token: tem **limites de uso por janela de 5 horas** (e semanais).
Os US$ 1.000 por dia da StrongDM são de outro mundo. A estratégia é gastar o limite só onde a IA é
insubstituível.

| Onde vai o consumo | Custo | Como economizar |
|---|---|---|
| Lint, tipos, testes, CI, mutação, holdouts | zero tokens | Coloque aqui o máximo de garantia |
| Contexto fixo (`AGENTS.md`, `CLAUDE.md`, MCPs, skills) | entra em toda mensagem | Mapa curto, MCPs desligados quando sem uso, `/context` para ver o que pesa |
| Exploração e verificação feitas pelo agente | alto | `scripts/verificar` e feature map, em vez de navegar e tirar prints |
| Avaliador e revisão por IA | médio, por PR | Só no amarelo e no vermelho; no verde, no modo sombra e por amostragem |
| Evals e juiz com o modelo real | alto, ocasional | Só quando mudar skill, prompt ou modelo |
| Agentes agendados | contínuo | No máximo um, semanal, com o modelo mais barato que dê conta |

Hábitos que mais rendem:
- Uma tarefa por sessão e `/clear` entre tarefas.
- O modelo mais forte para planejar e julgar; o mais barato para busca e tarefas mecânicas.
- Acompanhe com `/usage` (Claude Code) e `/status` (Codex).
- O Code Review gerenciado (em média US$ 15–25 por PR, nos planos Team/Enterprise) é opcional:
  `/code-review` local e a revisão cruzada entre os agentes cobrem o essencial.

O investimento das Fases 2 e 5 é o que mais economiza: cada regra dura evita ciclos de "erra,
corrige, erra de novo", que são os que mais queimam limite.

---

## 9. Dois agentes: Claude Code + Codex

Ter os dois é uma vantagem. São famílias de modelo diferentes, então um revisa o outro como o
"avaliador de outro modelo" que o estado da arte recomenda, já incluído nos dois planos. E quando um
esgota a janela de 5 horas, o outro continua.

| Papel | Sugestão inicial |
|---|---|
| Spec, plano e quadro de tarefas | Claude Code, com o Spec Kit |
| Implementar tarefas bem especificadas | Quem tiver limite disponível; tarefas independentes em paralelo |
| Revisar | Sempre o agente que **não** escreveu |
| Barreiras duras | O repositório: lint, testes, pre-commit, CI |

Regras de convivência:
- **Uma fonte de verdade:** `AGENTS.md` é o mapa (o Codex lê); o `CLAUDE.md` importa com `@AGENTS.md`.
- **Regras no repositório:** hooks do Claude Code não valem para o Codex. Pre-commit e CI valem
  para os dois, e para humanos.
- **Sem colisão:** um quadro de tarefas com dono, um branch ou worktree por agente, nunca os dois
  nos mesmos arquivos ao mesmo tempo.
- **Mesmo avaliador:** o prompt do avaliador fica num arquivo compartilhado, usado pelos dois.
- **Mesma política de risco** para os dois.
- **Métricas por agente:** reversões e achados de revisão separados por quem escreveu. Em algumas
  semanas, os números dizem quem rende mais em cada tipo de tarefa; a tabela acima é só o começo.

### Com o plugin `codex-plugin-cc`

Plugin oficial da OpenAI que chama o Codex de dentro do Claude Code, com o login local do Codex.
Exige Node.js 18.18+ e o Codex CLI.

| Comando | O que faz | Como usar neste sistema |
|---|---|---|
| `/codex:review` | Revisa as mudanças, só leitura | Revisão cruzada da Fase 7 |
| `/codex:adversarial-review` | Questiona o desenho da mudança, só leitura | Mudanças vermelhas e decisões de arquitetura |
| `/codex:rescue` | Delega uma tarefa; por padrão escreve sem pedir aprovação | Só em branch ou worktree separado, ou em modo somente leitura |
| `/codex:transfer` | Envia a sessão do Claude para o Codex | Só em sessões sem segredos |
| `/codex:setup` | Configura o plugin e o "review gate" | Deixe o review gate **desligado** |

Por que o review gate fica desligado: ele faz o Codex revisar a cada resposta do Claude, e o próprio
README avisa que isso pode virar um loop e esgotar os limites. Neste sistema, a revisão cruzada
acontece por PR, só no amarelo e no vermelho.

Lembre também:
- Tudo o que o plugin envia (diffs, contexto, a transcrição no `transfer`) vai para a OpenAI.
- Os hooks de guarda do Claude não valem para o que o Codex escreve.
- Há issues abertas sobre links simbólicos no `adversarial-review` e sobre o encerramento de
  sessões no Windows. Confira o estado delas antes de depender do plugin.

---

## 10. Spec Kit + este sistema

O Spec Kit (GitHub) cuida da **intenção**: transforma uma ideia em spec, plano e tarefas, com
Claude Code, Codex e outros agentes. Este sistema cuida da **confiança**: garante que o que foi
entregue corresponde à spec. Um não substitui o outro: o Spec Kit fica na frente, este sistema atrás.

| Spec Kit | O que entrega | O que este sistema acrescenta |
|---|---|---|
| `constitution` | Princípios do projeto | Cada princípio importante vira regra dura (lint, teste, CI) |
| `specify`, `clarify` | Spec com critérios de aceite | Zona de risco e plano de verificação com evidências |
| `plan`, `analyze` | Plano técnico consistente | Nada |
| `tasks` | Lista de tarefas | Dono por tarefa, uma de cada vez |
| `implement` | Código | Verificação, evidências, avaliador, política de risco, métricas |

Cuidados:
- **Specs enxutas.** Equipes que deixaram specs e contexto crescerem viram os agentes perderem o
  fio. Use o fluxo completo em mudanças amarelas e vermelhas; mudança verde e trivial pode ter uma
  spec de 3 linhas, o que também economiza tokens.
- **A constituição é texto.** Princípio que importa de verdade precisa de uma checagem que o garanta.
- Birgitta Böckeler (martinfowler.com) descreve níveis de uso de specs: escritas antes do código,
  mantidas vivas depois ("spec-anchored") ou como a própria fonte do código. Este playbook fica
  perto do segundo: a spec continua no repositório como referência do avaliador e das evidências.

---

## 11. Fluxos com dados (ex.: chatbot)

Fluxos com estado (chatbot, checkout, cadastro) só são verificáveis de verdade quando o agente
consegue ver o que ficou salvo.

**Ambiente**
- Banco de teste descartável por worktree (Docker Compose ou Testcontainers), com dados sintéticos
  e zerado a cada rodada. Nunca dados de produção.
- Serviços externos (WhatsApp, CRM, e-mail, o próprio modelo de IA) trocados por versões falsas
  locais que registram o que receberam: a versão simples dos "gêmeos digitais" da StrongDM.
- Relógio congelado nos testes: "amanhã às 15h" precisa dar sempre a mesma data.

**Acesso do agente**
- Banco: usuário **somente leitura** no banco de teste (modelos em PostgreSQL e Oracle na Fase 1.6 do
  playbook). O agente confere; quem escreve é a aplicação.
- Documentos: pasta própria de documentos sintéticos (ex.: `tests/fixtures/documentos/`). Se o
  bot busca em documentos, indexe só esses no ambiente de teste.
- Produção: a credencial não existe na máquina do agente.

**Testes em 4 camadas**

| Camada | O que garante | Custo em tokens |
|---|---|---|
| Máquina de estados + testes de propriedade | Transições certas; mensagem salva uma vez; reenvio não duplica | zero |
| Conversas como dados, com respostas gravadas no lugar do modelo | O fluxo inteiro e o que ficou no banco | zero |
| Modelo real, com nota de um juiz de outro modelo | A conversa é boa para o usuário (taxa de satisfação) | alto: só quando mudar prompt ou modelo |
| Conversas holdout, fora do repositório | O agente não otimizou para os casos que conhece | zero (rodam no CI) |

O exemplo de conversa como dados está na Fase 5, item 6, do playbook.

**Evidência no PR:** a transcrição da conversa, o antes e depois do banco (sem dados sensíveis) e,
quando houver, as notas do juiz.

### Apps mobile (React Native) com Maestro

No mobile, o Maestro faz o papel do navegador: fluxos em YAML, fáceis de o agente ler e escrever,
que rodam num aparelho físico conectado por USB (se `adb devices` lista o celular, ele usa). Roda
nativo no Windows, com Java 17+, e tem um MCP oficial que entrega a hierarquia da tela em texto,
mais barata em tokens que screenshots.

O que muda em relação à web:
- **Um celular é um recurso único.** Com um aparelho só, um agente verifica por vez; o script de
  verificação usa uma trava para o Claude e o Codex não disputarem a tela.
- **`testID` é o seletor.** Coloque nos componentes e liste no feature map.
- **`adb reverse`** liga o celular ao Metro e ao backend de teste da sua máquina, sem expor nada na rede.
- **O CI não tem o seu celular.** Aceitação e holdouts no CI pedem um emulador no runner ou
  aparelhos na nuvem; até lá, o CI roda os testes rápidos (Jest) e o aparelho fica para a
  verificação local.
- **Merge não é publicação.** App publicado não volta atrás num comando: publicação gradual nas
  lojas, flags remotas e monitoramento de crashes, com a publicação sempre nas mãos de um humano.
- **Use um aparelho de teste.** O agente vê a tela inteira, inclusive notificações.

Os detalhes (fluxo de exemplo, permissões, riscos de código nativo) estão na Fase 6.7 do playbook.

---

## 12. Rotina semanal (20 minutos)

1. Leia `.claude/falhas.md` e `.claude/incidentes.md`. Algo se repetiu? → `virar-regra`.
2. Olhe as métricas: reversões por nível. Algum tipo de mudança deve subir ou descer?
3. **Amostra:** leia o código de 1 ou 2 PRs verdes escolhidos ao acaso.
4. **Holdouts:** surgiu algum fluxo importante sem cenário?
5. Mudou o modelo ou o harness? → modo sombra de novo para os tipos afetados.

---

## 13. Armadilhas comuns

- **Pular para a fábrica.** Se o ciclo interno produz slop, automatizá-lo só produz mais slop, e
  mais conta de tokens.
- **Avaliador como única barreira.** Revisores de IA têm pontos cegos em comum com o autor.
- **Testes que o agente pode editar**, ou holdouts guardados dentro do repositório.
- **`CLAUDE.md` gigante.** Vira ruído. Mapa curto, detalhes nos docs, o importante em regra dura.
- **Hook lento ou barulhento.** Se tudo falha o tempo todo, ninguém presta atenção.
- **Regras de Bash como segurança.** São contornáveis; o muro é sandbox, servidor e CI.
- **Contar com sandbox no Windows nativo.** Não existe; use WSL2, devcontainer ou nuvem.
- **Esquecer o custo.** Verificação consome a maior parte dos tokens (na palestra "All Code Is Slop", Lauren Tan cita
  uma desenvolvedora que gasta ~70% nisso e diz que com ela é parecido).
  O Code Review gerenciado custa em média US$ 15–25 por PR. Defina um orçamento.
- **Copiar números alheios.** 11.000 PRs por mês, zero linhas manuais e US$ 1.000 por dia são
  contextos de laboratório. Meça os seus.
- **Spec Kit sem freio.** O fluxo completo em toda mudança gasta tokens e gera specs que ninguém lê.
- **Dois agentes no mesmo arquivo**, ou regras duras que só existem nos hooks de um deles.
- **Juiz com o modelo real em todo PR.** É a parte cara dos testes de conversa; rode quando mudar
  prompt ou modelo.
- **Banco de teste com dados reais**, ou o agente com credencial de escrita.
- **Ligar o review gate do `codex-plugin-cc`**, ou usar o `/codex:rescue` em modo escrita no seu
  branch de trabalho.
- **Segredo real passando pelo agente**: no chat, no código ou como valor padrão no `application.yml`.
- **Aplicar tudo em todo projeto.** Protótipo não precisa de política de risco, e código regulado
  não deve chegar ao merge automático. O perfil da Fase 0 decide.

---

## 14. Checklist de implantação

- [ ] **Fase 0:** relatório aprovado, perfil do projeto, linha de base e mapa de risco
- [ ] **Fase 1:** permissões, guarda de caminhos, segredos fora do alcance, sandbox ou alternativa
- [ ] **Fase 2:** regras duras com mensagens para o agente, hook pós-edição testado, `virar-regra`, limites de complexidade e duplicação
- [ ] **Fase 3:** `CLAUDE.md` ≤ ~100 linhas, `docs/` organizado, skills de procedimento
- [ ] **Fase 4:** modelo de spec, `planejar-mudanca`, uma spec aprovada
- [ ] **Fase 5:** aceitação protegida, holdouts no CI, mutação nos arquivos alterados
- [ ] **Fase 6:** `scripts/verificar`, feature map, template de PR com evidências
- [ ] **Fase 7:** avaliador calibrado, `/code-review` e `/security-review` no fluxo
- [ ] **Fase 8:** classificador, `CODEOWNERS`, modo sombra concluído
- [ ] **Fase 9:** flags, monitoramento por versão, reversão testada, métricas
- [ ] **Fase 10:** regras de autonomia escritas, um agente agendado rodando
- [ ] **Orçamento:** consumo acompanhado (`/usage`, `/status`), avaliador só onde há risco
- [ ] **Dois agentes:** `AGENTS.md` único, regras duras em pre-commit e CI, quadro de tarefas com dono, plugin com review gate desligado (se usar)
- [ ] **Spec Kit (opcional):** templates com zona de risco e plano de verificação
- [ ] **Dados:** banco de teste descartável, usuário somente leitura, conversas como dados
- [ ] **Mobile (se houver):** fluxos do Maestro com `testID`, trava do aparelho, publicação gradual nas lojas
- [ ] **Segredos:** manifesto, `scripts/segredos.ps1`, checagem no CI e seção "Configuração" nos PRs

---

## 15. Fontes

- Lauren Tan: [workshop](https://www.youtube.com/watch?v=I_oMJk6barY), [resumo](https://www.youtube.com/watch?v=O0722w0Xby8), ["All Code Is Slop (Except Mine)"](https://www.youtube.com/watch?v=O_zcc6Xl12g)
- Anthropic: [Effective harnesses for long-running agents](https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents) (nov/2025)
- Anthropic: [Harness design for long-running application development](https://www.anthropic.com/engineering/harness-design-long-running-apps) (mar/2026)
- OpenAI: [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/) (fev/2026)
- StrongDM: [Software Factory](https://factory.strongdm.ai/), e a [análise de Simon Willison](https://simonwillison.net/2026/Feb/7/software-factory/) (fev/2026)
- Google: [DORA 2025, State of AI-assisted Software Development](https://dora.dev/dora-report-2025/)
- Meta: [Mutation-Guided LLM-based Test Generation at Meta](https://arxiv.org/abs/2501.12862) (FSE 2025)
- [Do Coding Agents Deceive Us? Detecting and Preventing Cheating](https://arxiv.org/abs/2606.07379) (2026)
- Augment Code: [Agentic Code Review: When Agents Review the Code Agents Wrote](https://www.augmentcode.com/guides/agentic-code-review-authority-boundaries) (set/2026)
- Martin Monperrus: [The End of Code Review: Coding Agents Supersede Human Inspection](https://arxiv.org/abs/2606.13175) (jun/2026)
- Orlanski e outros: [SlopCodeBench](https://www.scbench.ai/) ([artigo](https://arxiv.org/abs/2603.24755), [código](https://github.com/SprocketLab/slop-code-bench)), 2026
- Stephanie Jarmak: [Engineering Reliable Coding Agents](https://arxiv.org/abs/2608.13867) (ago/2026), sobre como o sistema em volta do modelo decide a confiabilidade
- Claude Code: [hooks](https://code.claude.com/docs/en/hooks), [permissões](https://code.claude.com/docs/en/permissions), [sandbox](https://code.claude.com/docs/en/sandboxing), [modos de permissão](https://code.claude.com/docs/en/permission-modes), [Code Review](https://code.claude.com/docs/en/code-review), [custos e uso](https://code.claude.com/docs/en/costs) e o [anúncio do Code Review](https://claude.com/blog/code-review)
- GitHub Spec Kit: [fluxo de comandos](https://github.github.io/spec-kit/reference/agentic-sdd.html)
- Birgitta Böckeler: [Understanding Spec-Driven-Development: Kiro, spec-kit, and Tessl](https://www.martinfowler.com/articles/exploring-gen-ai/sdd-3-tools.html)
- Qodo: [What Is Spec-Driven Development?](https://www.qodo.ai/glossary/what-is-spec-driven-development/), sobre manter specs enxutas
- OpenAI: [Codex, preços e limites](https://developers.openai.com/codex/pricing)
- OpenAI: [codex-plugin-cc](https://github.com/openai/codex-plugin-cc), plugin oficial para usar o Codex dentro do Claude Code
- Maestro: [Android e aparelhos físicos](https://docs.maestro.dev/get-started/supported-platform/android), [MCP](https://docs.maestro.dev/get-started/maestro-mcp), [instalação no Windows](https://docs.maestro.dev/getting-started/installing-maestro/windows), [comandos](https://docs.maestro.dev/reference/commands-available)
