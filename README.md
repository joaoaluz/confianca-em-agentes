# Confiança em agentes

Agente de IA escreve código mais rápido do que eu consigo ler. Ou eu viro revisor em tempo integral,
ou o projeto vira *slop*: aquele código que até funciona, mas que ninguém tem coragem de tocar.

Este repo é o meio-termo que eu montei. Em vez de ler cada linha, eu reviso **o que** o agente vai
fazer (a spec) e **a prova** de que funcionou (testes, prints, vídeo). O resto fica por conta de quem
não cansa: lint, testes que o agente não consegue burlar e regras que quebram o build. Código mesmo,
só onde dói se der errado.

## O que tem aqui

- [**implantar-confianca.md**](implantar-confianca.md): o playbook. Você entrega pro Claude Code e ele
  monta tudo no seu projeto, uma fase por vez, pedindo sua aprovação a cada passo.
- [**guia-de-construcao.md**](guia-de-construcao.md): o porquê de cada peça, pra quando bater a dúvida.
- [**fundamentos.md**](fundamentos.md): os 13 erros que o agente mais comete em app com usuário,
  banco e pagamento (concorrência, webhook duplicado, autorização…), com prompts de correção e uma
  auditoria que só lê.
- [**roteiro-de-aprendizado.md**](roteiro-de-aprendizado.md): seis semanas pra pegar o jeito.
- [**modelos/segredos/**](modelos/segredos/): senhas, tokens e chaves sem sofrimento no deploy.
- [**apresentacao-confiar-em-agentes.html**](apresentacao-confiar-em-agentes.html): os slides, pra quem
  prefere ver a ler.

## Pra começar

Copie o playbook pro seu projeto e peça ao Claude Code:

```
Leia @implantar-confianca.md e execute a Fase 0.
```

A Fase 0 só olha, não mexe em nada. No fim, ela te diz que tipo de projeto é esse, o que está faltando
e por onde começar.

App já no ar, com usuário de verdade? Rode também a auditoria do `fundamentos.md`. Ela também só
lê, e te diz o que corrigir primeiro.

## Regras da casa

1. Uma tarefa por vez.
2. "Pronto, funciona!" sem prova não vale.
3. Corrigiu o agente duas vezes? Vira regra.
4. Limpe antes de construir: o agente copia o que vê.
5. Segredo de verdade nunca passa pelo agente.

## Créditos

A espinha dorsal veio das palestras da Lauren Tan
([workshop](https://www.youtube.com/watch?v=I_oMJk6barY),
[resumo](https://www.youtube.com/watch?v=O0722w0Xby8) e
[All Code Is Slop (Except Mine)](https://www.youtube.com/watch?v=O_zcc6Xl12g)). O resto veio do que
Anthropic, OpenAI, StrongDM, DORA e o pessoal do SlopCodeBench publicaram por aí. Fontes completas no
guia e no playbook.

Use, adapte, discorde. Só não confie cegamente: nem nos agentes, nem neste README.
