# Confiança em agentes

Playbook, guia e modelos para trabalhar com agentes de IA de código (Claude Code e Codex) **sem
revisar tudo e sem deixar o código apodrecer**. Baseado nas palestras de Lauren Tan e no estado da
arte de 2025–2026.

A ideia central é a **revisão por exceção**: você revisa a intenção (a spec) e as evidências; código,
só onde o risco pede. O resto fica garantido por checagens que o computador cobra, testes que o agente
não consegue burlar e métricas que decidem quanta autonomia cada tipo de mudança merece.

## O que tem aqui

| Arquivo | Para quem | O que é |
|---|---|---|
| [implantar-confianca.md](implantar-confianca.md) | O agente | Playbook em 11 fases (0 a 10), com perfis de projeto, roteiro de instalação e modelos prontos |
| [guia-de-construcao.md](guia-de-construcao.md) | Você | O porquê de cada peça: escada de autonomia, orçamento, dois agentes, Spec Kit, dados, mobile, segredos |
| [roteiro-de-aprendizado.md](roteiro-de-aprendizado.md) | Você | 6 semanas para aprender a trabalhar com agentes sem slop |
| [modelos/segredos/](modelos/segredos/) | O projeto | Manifesto e script testado para senhas, tokens e chaves, do dev ao deploy |
| [apresentacao-confiar-em-agentes.html](apresentacao-confiar-em-agentes.html) | Estudo | 39 slides com o resumo de tudo; abra no navegador |

## Como usar

1. **Aprender:** siga o [roteiro de aprendizado](roteiro-de-aprendizado.md) num projeto de estudo.
2. **Aplicar num projeto:** copie o playbook para a raiz do projeto e peça ao Claude Code:

   ```
   Leia @implantar-confianca.md e execute a Fase 0.
   ```

   Ou instale como skill, para usar em qualquer projeto: copie o arquivo para
   `~/.claude/skills/implantar-confianca/SKILL.md` e rode `/implantar-confianca`.
3. A **Fase 0 só lê o projeto**: devolve o perfil, o diagnóstico, a linha de base e o que falta
   instalar. Daí em diante, uma fase por sessão, sempre com a sua aprovação.

## Princípios

- Uma tarefa por sessão.
- Exija prova, não promessa.
- Corrigiu duas vezes? Vira regra que o computador cobra.
- Limpe antes de construir: o agente copia o que vê.
- O agente nunca vê segredos reais nem credenciais de produção.

## Créditos e fontes

- Lauren Tan: [workshop](https://www.youtube.com/watch?v=I_oMJk6barY),
  [resumo](https://www.youtube.com/watch?v=O0722w0Xby8) e
  [All Code Is Slop (Except Mine)](https://www.youtube.com/watch?v=O_zcc6Xl12g).
- Estado da arte (Anthropic, OpenAI, StrongDM, DORA, SlopCodeBench, Spec Kit e outros): veja as
  seções de fontes do [guia](guia-de-construcao.md) e do [playbook](implantar-confianca.md).

Material de estudo: teste cada peça no seu contexto antes de confiar nela.
