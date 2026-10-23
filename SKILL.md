---
name: orquestrador
description: Delega partes de uma tarefa para subagentes especializados, cada um rodando no modelo free mais adequado (visão, contexto longo, frontend, áudio, código, rápido), e integra os resultados no contexto da sessão principal. Use sempre que o usuário pedir para delegar, "chamar o modelo X", "mandar pro subagente", "fazer em paralelo", comparar modelos, analisar print/imagem/PDF, processar arquivo gigante, ou quando a tarefa tiver partes separáveis que se beneficiam de modelos diferentes. Também use quando o usuário perguntar qual modelo serve para quê, ou quando a tarefa envolver ler mais de ~150k tokens de uma vez.
---

# Orquestrador

Você é o modelo da sessão principal. Seu trabalho aqui não é executar tudo — é **segurar o contexto** e mandar o trabalho braçal para o subagente certo, no modelo certo.

O motivo é simples: cada subagente roda em sessão filha com **contexto limpo**. Ele não vê esta conversa. Isso é vantagem (não contamina, não gasta seu contexto) e risco (se o brief for vago, ele inventa). Quase todo erro de orquestração nasce de brief ruim, não de modelo ruim.

## Quando orquestrar

Orquestre quando a tarefa tem uma parte que:

- **Precisa de outro sentido** — imagem, print, PDF, áudio, vídeo. O modelo principal não vê isso bem.
- **É grande demais** — repo inteiro, log gigante, planilha enorme. Melhor queimar 1M de contexto do filho do que os 200k do pai.
- **É especialidade clara** — CSS/layout, análise de dados, revisão.
- **É independente** — dá para rodar em paralelo sem esperar o outro.

Não orquestre quando:

- A resposta cabe em 1-2 passos. Subagente tem overhead: latência de spawn, contexto frio, tokens.
- Você já tem tudo no contexto e a tarefa é contínua. Quebrar em filho faz ele perder o fio.
- O usuário pediu velocidade acima de qualidade. Um modelo free em fila é mais lento que você respondendo direto.

## O protocolo

**1. Classifique.** Antes de chamar qualquer coisa, diga em uma linha o que a tarefa precisa: visão? contexto longo? código? interface? áudio? velocidade?

**2. Escolha um subagente.** Use a tabela abaixo. Um subagente por tarefa. Se precisar de dois, eles são independentes — então vão em paralelo.

**3. Escreva um brief autocontido.** Este é o passo que decide o resultado. O filho não sabe nada do que foi conversado. O brief precisa ter, nesta ordem:

- **Objetivo** — o que ele tem que entregar, em uma frase.
- **Contexto mínimo** — só o que ele precisa saber. Não cole a conversa inteira.
- **Caminhos** — arquivos, pastas, URLs. Absolutos quando possível.
- **Formato de saída** — exatamente o que você quer de volta: lista, JSON, patch, texto corrido, tabela. Se você não disser, ele escolhe, e geralmente escolhe errado.
- **Limites** — o que ele NÃO deve fazer (não editar, não instalar, não inventar).

**4. Lance e observe.** Para uma tarefa só, use foreground: você espera, recebe, e continua. Para tarefas independentes, dispare em paralelo — mas no máximo **3 de uma vez**. Modelo free tem fila; 5 em paralelo costuma ser mais lento que 3 em sequência.

**5. Integre e encerre.** Quando o filho devolve, ele acabou. Traga o resultado para o seu contexto, combine com o que você já sabe, e responda ao usuário. **Não reabra a sessão do filho** para "continuar" — ela foi feita para uma tarefa e cumpriu. Se precisa de mais, escreva um brief novo. Sessão de filho não é chat.

## Catálogo

| Subagente | Modelo | Use para | Não use para |
|---|---|---|---|
| `codigo` | deepseek-v4.1-flash-free `#high` | implementar, refatorar, escrever teste, debugar arquivo isolado | decisão de arquitetura que depende da conversa |
| `visao` | nemotron-3.5-super-vl-free `#high` | print, screenshot, layout, comparar antes/depois, ler PDF | texto puro |
| `contexto-longo` | beam-free `#high` | repo inteiro, log enorme, contrato de 300 páginas | tarefa rápida |
| `frontend` | glm-5.3-flash-free `#high` | CSS, Tailwind, componente visual, carrossel, landing | lógica de backend |
| `audio` | mimo-v2.6-flash-free | áudio de WhatsApp, transcrição, vídeo com fala | qualquer coisa sem áudio |
| `rapido` | flint-40b-free `#low` | classificar, extrair campo, resumir 10 linhas | raciocínio difícil |

Detalhes de ficha técnica e fallback: `references/modelos-free.md`.

## Escrevendo o brief

Ruim:

> "Analisa essa imagem e me diz o que tem."

O filho não tem a imagem, não sabe o objetivo, não sabe o formato. Ele vai pedir desculpa ou inventar.

Bom:

> Objetivo: descrever o layout da tela para eu reconstruir em React.
> Imagem: C:\Users\jryan\Desktop\print.png
> Contexto: é um dashboard de CRM, tema escuro.
> Entregue: (1) hierarquia de seções de cima para baixo, (2) componentes identificáveis, (3) cores em hex aproximadas, (4) o que está desalinhado.
> Não edite arquivos. Não sugira código.

A diferença não é tamanho — é o filho conseguir executar sem te fazer pergunta.

## Falhas e fallback

- **Modelo free fora / fila travada** — tente de novo uma vez. Se falhar de novo, caia para o irmão pago (`opencode-go/deepseek-v4.1-flash`, centavos) ou para o `codigo`.
- **Resultado vago** — não reabra o filho pedindo "melhore". O brief estava fraco. Reescreva com formato de saída explícito e lance de novo.
- **Resultado errado mas bem formatado** — desconfie do brief, não do modelo. Falta contexto ou falta restrição.
- **Filho tentou editar quando não devia** — os agentes de leitura já têm `edit` negado. Se aconteceu, foi em `codigo`.

## Exemplo

Usuário: "esse print do site do cliente tá feio, o que eu mudo?"

1. Classifique: visão + frontend. Duas partes, independentes.
2. Lance `visao` e `frontend` em paralelo, cada um com o caminho do print e o formato de saída.
3. `visao` devolve: hierarquia, cores, desalinhamentos.
4. `frontend` devolve: 3 mudanças concretas de CSS.
5. Você junta, decide o que faz sentido pro cliente, e responde em 5 linhas.

Você não viu o print. Não precisou. Esse é o ponto.
