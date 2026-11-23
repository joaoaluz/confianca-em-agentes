# Roteiro de aprendizado: trabalhar com agentes sem slop

Seis semanas, uma habilidade por semana, sempre praticando num **projeto de estudo** (pequeno, seu,
sem usuários reais). Cada semana tem o que estudar, o que fazer e o sinal de que você aprendeu.
Não pule para a próxima sem o sinal.

## As 5 regras de bolso

1. **Peça pequeno.** Uma tarefa por sessão.
2. **Exija prova, não promessa.** "Rode e me mostre" vale mais que "pronto, funciona".
3. **Corrigiu duas vezes? Vira regra.** De preferência uma regra que o computador cobra (lint, teste).
4. **Limpe antes de construir.** O agente copia o que vê no código.
5. **Revise a intenção e as evidências.** Código, só onde o risco pede.

---

## Semana 1: ver o slop acontecer

- **Estude:** a palestra [All Code Is Slop](https://www.youtube.com/watch?v=O_zcc6Xl12g) (17 min) e os slides "A pirâmide invertida" e "O código é um jardim".
- **Faça:** peça ao Claude 3 tarefas pequenas no projeto de estudo, sem nenhuma regra. Depois leia
  tudo: os comandos que ele rodou, o raciocínio e o diff. Anote em `.claude/falhas.md` o que você
  corrigiria.
- **Sinal:** você aponta pelo menos 3 tipos de slop no que ele fez (código duplicado, função
  gigante, comentário justificando gambiarra, teste que não testa nada, "pronto" sem ter rodado).

## Semana 2: fazer o agente provar

- **Estude:** o [workshop de Lauren Tan](https://www.youtube.com/watch?v=I_oMJk6barY&t=323s) (verificação e mapa de
  funcionalidades, a partir de 5:23) e a Fase 6 do playbook.
- **Faça:** crie um jeito de o agente verificar sozinho um fluxo do projeto (um `scripts/verificar`
  ou, no app React Native, um fluxo do Maestro). Em toda tarefa, peça a evidência.
- **Sinal:** 5 tarefas seguidas em que o agente provou o resultado sem você colar erro ou print no chat.

## Semana 3: transformar correção em regra

- **Estude:** os slides "Comentário é desculpa, lint é regra" e "Regras duras × moles", e a Fase 2.
- **Faça:** pegue 2 falhas da semana 1 e transforme em regras de lint, com mensagens que explicam a
  correção certa. Ligue no hook pós-edição e no pre-commit. Acrescente um limite de complexidade
  por função (ex.: no máximo 10) e uma checagem de código duplicado.
- **Por que regra e não instrução:** no SlopCodeBench, pedir qualidade no prompt reduziu o slop
  inicial em até um terço, mas **não mudou a velocidade com que o código piorava**. Regra escrita
  ajuda no começo; regra que o computador cobra segura com o tempo.
- **Sinal:** o agente bate numa regra e corrige sozinho, sem você dizer nada.

## Semana 4: spec antes do código, testes que não dá para burlar

- **Estude:** as Fases 4 e 5 (e a seção do Spec Kit, se quiser usar).
- **Faça:** escreva a spec de uma funcionalidade pequena, com 3 critérios de aceite. Peça os testes
  de aceitação primeiro, proteja-os da edição e só então peça a implementação.
- **Sinal:** você aprovou a spec em 5 minutos e soube se a funcionalidade estava certa sem ler o código.

## Semana 5: um segundo olhar e medir o slop

- **Estude:** a Fase 7 (avaliador) e o resumo do SlopCodeBench abaixo.
- **Faça:** ponha um avaliador (o subagente ou o Codex) para revisar 3 mudanças. Meça a
  complexidade e a duplicação do projeto no começo e no fim da semana.
- **Sinal:** o avaliador pegou algo que você deixaria passar, e as métricas não pioraram.

## Semana 6: escolher o que revisar

- **Estude:** os slides "Política de risco", "A escada de autonomia" e "Serve para todo projeto?",
  e a rotina semanal (seção 12 do guia).
- **Faça:** classifique as próximas 10 mudanças em verde, amarelo ou vermelho. Nas verdes, olhe só
  as evidências. Faça a rotina semanal de 20 minutos.
- **Sinal:** você revisou menos, nenhum problema escapou e você sabe em que nível da escada está.

## Depois do roteiro

Rode a **Fase 0** do `implantar-confianca.md` num projeto de verdade. Ela só lê o projeto e devolve
o perfil, o diagnóstico e o que falta. A partir daí, siga as fases que o perfil pedir.

Se o projeto tem usuários, banco ou pagamento, a Fase 0 também roda a auditoria de
`fundamentos.md`. Corrija um fundamento por vez, sempre com o teste falhando antes da correção.

---

## Para medir o slop: o SlopCodeBench

O [SlopCodeBench](https://www.scbench.ai/) (artigo de março de 2026, atualizado em maio) mede como o código de agentes se
degrada quando eles estendem o próprio código por várias rodadas, como num projeto real.

- **Erosão:** quanto da complexidade do código está concentrada em funções muito complexas
  (complexidade ciclomática acima de 10).
- **Verbosidade:** a fração de linhas duplicadas ou com padrões ruins.
- **O que acharam:** a erosão subiu em 77% das execuções e a verbosidade em 75,5%. O código dos
  agentes saiu 2,3 vezes mais verboso e 2 vezes mais erodido que o de repositórios Python de código
  aberto escritos por pessoas.
- **Para você:** não precisa rodar o benchmark. Use a mesma ideia no seu projeto: um limite de
  complexidade no lint (ex.: a regra `complexity` do ESLint, ou `C901` no Ruff) e um detector de
  duplicação (ex.: jscpd), acompanhando os números semana a semana.
- **Cuidado:** os próprios autores dizem que "slop" ainda não tem definição precisa e que o
  benchmark está no começo. São indicadores, não verdade absoluta.

Fontes: [site e leaderboard](https://www.scbench.ai/), [artigo](https://arxiv.org/abs/2603.24755),
[código](https://github.com/SprocketLab/slop-code-bench).
