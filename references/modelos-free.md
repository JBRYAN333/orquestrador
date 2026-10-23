# Modelos free — ficha técnica e fallback

> Medido no catálogo do opencode em 23/10/2026. Se um modelo sumir, rode
> `opencode debug agents` e confira os agentes que ainda resolvem.

## Tabela

| Modelo | Lançamento | Contexto | Saída | Entrada | Variantes |
|---|---|---|---|---|---|
| `opencode/deepseek-v4.1-flash-free` | 10/09/26 | 200k | 32k | texto + imagem | low, high, max |
| `opencode/glm-5.3-flash-free` | 26/08/26 | 200k | 32k | texto + imagem + vídeo + PDF | low, high, max |
| `opencode/mimo-v2.6-flash-free` | 22/09/26 | 200k | 32k | texto + imagem + áudio + vídeo | — |
| `opencode/nemotron-3.5-super-vl-free` | 15/10/26 | 1M | 131k | texto + imagem | none, minimal, low, medium, high, xhigh |
| `opencode/beam-free` | 05/10/26 | 1M | 131k | só texto | low, medium, high, xhigh, max |
| `opencode/flint-40b-free` | 21/10/26 | 256k | 65k | só texto | low, medium, high, xhigh, max |

Knowledge cutoff: deepseek 2025-05, beam 2026-06, flint 2026-06.

## Escolha por sintoma

| O sintoma | O modelo |
|---|---|
| "não consigo ver a imagem" | nemotron (visão + 1M) |
| "o arquivo não cabe" | beam (1M, texto) |
| "preciso de PDF ou vídeo" | glm (aceita os dois) |
| "é áudio" | mimo (único com áudio) |
| "responde rápido, é simples" | flint (40B) |
| "é código de verdade" | deepseek `#high` |

## O que o benchmark desmentiu

Medido em 23/10/2026, 1 execução por caso:

- **`mimo` com áudio nativo não se provou.** Na prática o agente `audio` transcreveu via
  `faster-whisper` no shell, igual ao baseline. Trate o áudio como "precisa de whisper local",
  não como "o modelo ouve". `small` funciona; `medium` estoura memória em 8 GB (`mkl_malloc`).
- **`nemotron` inventa função a partir de forma.** Descreveu uma scrollbar horizontal como
  "controles de paginação". O prompt do agente agora proíbe nomear função sem certeza.
- **`beam` com 20 steps não fecha um repo médio.** Subiu para 40. Com 20, entregou veredito
  correto mas perdeu achados que o baseline encontrou.
- **`deepseek-v4.1-flash-free` como baseline já tem visão e vai bem em imagem única.**
  Delegar imagem para o `visao` só compensa com várias imagens, imagem + código, ou quando
  você quer uma segunda leitura independente.

## Variantes

`#low` responde rápido e raso. `#high` é o padrão de trabalho. `#max` só compensa em
problema que exige várias hipóteses — custa tempo e às vezes piora por overthinking.

Em modelo free, `#max` raramente vale: a fila já é o gargalo, não o raciocínio.

## Fallback

Ordem quando um free falha:

1. Repetir uma vez (fila costuma ser transitória).
2. `opencode-go/deepseek-v4.1-flash` — mesmo cérebro, pago, $0.15/M in. Centavos por tarefa.
3. `opencode-go/deepseek-v4-pro` — só se o problema for realmente difícil.

Nunca caia para `opencode/big-pickle`: é de 2025, 160k úteis, sem visão.

## Limite de paralelismo

Free tier não tem SLA. Três subagentes simultâneos é o teto confortável.
Acima disso a fila come o ganho de paralelizar.
