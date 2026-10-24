---
name: orquestrador
description: Delega partes de uma tarefa para subagentes especializados, cada um rodando o modelo mais adequado ao papel, em perfil free ou pago (visão, contexto longo, frontend, áudio, código, rápido), e integra os resultados no contexto da sessão principal. Use sempre que o usuário pedir para delegar, "chamar o modelo X", "mandar pro subagente", "fazer em paralelo", comparar modelos, analisar print/imagem/PDF, processar arquivo gigante, ou quando a tarefa tiver partes separáveis que se beneficiam de modelos diferentes. Também use quando o usuário perguntar qual modelo serve para quê, ou quando a tarefa envolver ler mais de ~150k tokens de uma vez.
---

# Orquestrador

Você é o modelo da sessão principal. Seu trabalho aqui não é executar tudo — é **segurar o contexto** e mandar o trabalho braçal para o subagente certo, no modelo certo.

O motivo é simples: cada subagente roda em sessão filha com **contexto limpo**. Ele não vê esta conversa. Isso é vantagem (não contamina, não gasta seu contexto) e risco (se o brief for vago, ele inventa). Quase todo erro de orquestração nasce de brief ruim, não de modelo ruim.

## Quando orquestrar

Orquestre quando a tarefa tem uma parte que:

- **Precisa de outro sentido** — áudio e vídeo quase sempre; imagem e PDF só quando são muitos, ou quando você quer uma segunda leitura independente. Se é uma imagem só e você tem visão, leia você mesmo.
- **É grande demais** — repo inteiro, log gigante, planilha enorme. Melhor queimar 1M de contexto do filho do que os 200k do pai.
- **É especialidade clara** — CSS/layout, análise de dados, revisão.
- **É independente** — dá para rodar em paralelo sem esperar o outro.

Não orquestre quando:

- A resposta cabe em 1-2 passos. Subagente tem overhead: latência de spawn, contexto frio, tokens.
- Você já tem tudo no contexto e a tarefa é contínua. Quebrar em filho faz ele perder o fio.
- O usuário pediu velocidade acima de qualidade. No perfil free, a fila costuma ser mais lenta que você respondendo direto.
- **É uma imagem só e você já tem visão.** Ver a seção "O preço da delegação" abaixo: medido, isso saiu caro e não melhorou a resposta.

## O preço da delegação

Medido no benchmark desta skill (1 execução por configuração, 4 tarefas):

| | Com orquestração | Sem orquestração |
|---|---|---|
| Pass rate | 0,846 | 0,875 |
| Tokens por tarefa | 46.141 | 22.534 |
| Tempo por tarefa | 148 s | 131 s |

Numa tarefa de uma imagem só, a orquestração gastou **10x mais tokens** (39.314 vs 3.873) e entregou uma descrição com um elemento inventado. O filho não viu melhor que o pai — viu diferente, e pior.

Delegar não é de graça. A conta fecha quando:

- o material **não cabe** no seu contexto (aí o custo é inevitável);
- a tarefa precisa de **um segundo par de olhos independente**, não de um eco do seu;
- são **várias imagens** ou imagem + código, e paralelizar economiza tempo de verdade;
- a especialidade é real (CSS, transcrição, análise de repo).

Não fecha quando você delega para "usar o modelo certo" uma tarefa que você resolveria em uma leitura. Especialização que não muda o resultado é só custo.

## O protocolo

**1. Classifique.** Antes de chamar qualquer coisa, diga em uma linha o que a tarefa precisa: visão? contexto longo? código? interface? áudio? velocidade?

**2. Escolha um subagente.** Use a tabela abaixo. Um subagente por tarefa. Se precisar de dois, eles são independentes — então vão em paralelo.

**3. Escreva um brief autocontido.** Este é o passo que decide o resultado. O filho não sabe nada do que foi conversado. O brief precisa ter, nesta ordem:

- **Objetivo** — o que ele tem que entregar, em uma frase.
- **Contexto mínimo** — só o que ele precisa saber. Não cole a conversa inteira.
- **Caminhos** — arquivos, pastas, URLs. Absolutos quando possível.
- **Formato de saída** — exatamente o que você quer de volta: lista, JSON, patch, texto corrido, tabela. Se você não disser, ele escolhe, e geralmente escolhe errado.
- **Limites** — o que ele NÃO deve fazer (não editar, não instalar, não inventar).

**4. Lance e observe.** Para uma tarefa só, use foreground: você espera, recebe, e continua. Para tarefas independentes, dispare em paralelo — mas respeite o perfil: **3 de uma vez no `free`** (que enfileira), **até 6 no `paid`**. Acima disso o ganho some: no free porque a fila come, no pago porque você passa a pagar por trabalho que não estava esperando.

**5. Integre e encerre.** Quando o filho devolve, ele acabou. Traga o resultado para o seu contexto, combine com o que você já sabe, e responda ao usuário. **Não reabra a sessão do filho** para "continuar" — ela foi feita para uma tarefa e cumpriu. Se precisa de mais, escreva um brief novo. Sessão de filho não é chat.

**5b. Verifique antes de repassar.** O que o filho afirma não é fato seu. Antes de escrever a resposta final:

- Se ele descreveu um **elemento ou função** que você não pode confirmar, não repasse como certeza. Diga "o subagente descreveu X" ou marque como incerto.
- Se ele disse que **terminou** mas a resposta abre com "limite de passos atingido", isso é entrega parcial. Diga isso ao usuário em vez de esconder.
- Se ele usou um **caminho alternativo** (whisper local em vez de ouvir o áudio, grep em vez de ler), o resultado tem o viés daquele caminho. Registre.

Repassar afirmação de filho como se fosse sua é o jeito mais fácil de transformar uma boa orquestração em uma resposta errada com cara de confiável.

## Catálogo

| Subagente | Use para | Não use para |
|---|---|---|
| `codigo` | implementar, refatorar, escrever teste, debugar arquivo isolado | decisão de arquitetura que depende da conversa |
| `visao` | várias imagens, PDF, segunda leitura independente, antes/depois | uma imagem só que você já consegue ver |
| `contexto-longo` | repo inteiro, log enorme, contrato de 300 páginas | tarefa rápida |
| `frontend` | CSS, Tailwind, componente visual, carrossel, landing | lógica de backend |
| `audio` | áudio de WhatsApp, transcrição (via whisper local), vídeo com fala | qualquer coisa sem áudio |
| `rapido` | classificar, extrair campo, resumir 10 linhas | raciocínio difícil |

O modelo de cada papel depende do **perfil instalado**. Veja o que está ativo:

```bash
opencode debug agents
```

| Subagente | Perfil `free` (padrão) | Perfil `paid` |
|---|---|---|
| `codigo` | deepseek-v4.1-flash-free `#high` | deepseek-v4-pro `#high` |
| `visao` | nemotron-3.5-super-vl-free `#high` | gemini-4-argon `#high` |
| `contexto-longo` | beam-free `#high` | beam-free `#high` (sem fila) |
| `frontend` | glm-5.3-flash-free `#high` | glm-5.3 `#high` |
| `audio` | mimo-v2.6-flash-free | mimo-v2.6-pro |
| `rapido` | flint-40b-free `#low` | qwen3.8-flash `#low` |

O perfil se troca no instalador (`install.ps1 -Profile paid`), não editando arquivo à mão.
Ficha técnica e preços: `references/modelos-free.md` e `references/modelos-pagos.md`.

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

- **Modelo fora / fila travada** — tente de novo uma vez. Se falhar de novo, troque de perfil: no `free`, caia para o irmão pago (`opencode-go/deepseek-v4.1-flash`, centavos); no `paid`, caia para o free correspondente ou para o `codigo`. Trocar de perfil não exige reinserir nada — é `install.ps1 -Profile <outro>`.
- **Filho parou por limite de passos** — a resposta costuma vir pela metade com "máximo de passos atingido". Não é falha de modelo, é de orçamento: o brief pediu mais leitura do que os `steps` do agente permitem. `contexto-longo` tem 40, `audio` tem 30. Se ainda estourar, reduza o escopo do brief ("só o diretório web/") em vez de aumentar o cap de novo.
- **Resultado vago** — não reabra o filho pedindo "melhore". O brief estava fraco. Reescreva com formato de saída explícito e lance de novo.
- **Resultado errado mas bem formatado** — desconfie do brief, não do modelo. Falta contexto ou falta restrição.
- **Filho inventou um elemento** — em `visao`, é o erro clássico: nomear a função de uma forma que ele só viu como geometria. Corrija na resposta final e, se repetir, reforce no brief: "descreva forma e posição; se não tiver certeza da função, diga que não identificou".
- **Filho tentou editar quando não devia** — os agentes de leitura já têm `edit` negado. Se aconteceu, foi em `codigo`.

## Exemplo

Usuário: "esse print do site do cliente tá feio, o que eu mudo?"

1. Classifique: um print só. Você tem visão — **olhe você mesmo**. Delegar aqui custou 10x mais tokens e trouxe um elemento inventado no benchmark.
2. Se precisar da parte de CSS, aí sim: lance `frontend` com o print e o formato ("3 mudanças, cada uma com problema + propriedade + valor").
3. Você junta o que viu com o que o `frontend` propôs, e responde em 5 linhas.

O ponto não é "nunca ver imagem". É: **não pague dois modelos para olhar a mesma coisa**.
