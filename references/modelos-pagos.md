# Modelos pagos — perfil `paid`

> Catálogo conferido em 24/10/2026 via `opencode models --provider opencode-go`.
> Preços em USD por milhão de tokens (entrada / saída).

O perfil pago não troca os prompts dos agentes. Troca só a linha `model:` de cada
um, a partir de `profiles/paid.json`. O gargalo deixa de ser fila e passa a ser custo.

## Mapa por papel

| Subagente | Modelo | In / Out | Por que esse |
|---|---|---|---|
| `codigo` | `deepseek-v4-pro#high` | $0,66 / $1,98 | Código é onde erro custa caro. O pro é o cérebro DeepSeek de trabalho, não o flash. |
| `visao` | `gemini-4-argon#high` | $2,00 / $10,00 | Multimodal confiável. Caro por token, barato por tarefa: um print custa ~$0,02. |
| `contexto-longo` | `beam-free#high` | $0 / $0 | Mesmo modelo do perfil free, agora sem fila. Ler repo grande é o caso mais caro por token — pagar $2/M para reler 150k tokens não se justifica. |
| `frontend` | `glm-5.3#high` | $1,40 / $4,40 | Versão cheia do GLM, no lugar do flash. |
| `audio` | `mimo-v2.6-pro` | $0,44 / $0,87 | Versão pro do único modelo com áudio. Sem variantes. |
| `rapido` | `qwen3.8-flash#low` | $0,15 / $0,47 | Classificação não merece modelo caro. |

## O que muda no comportamento da skill

| | Free | Pago |
|---|---|---|
| Teto de paralelos | 3 | até 6 |
| `#max` | raramente vale | passa a fazer sentido em problema difícil |
| Fallback | cai para pago quando o free trava | invertido: cai para free se faltar crédito ou cota |
| Argumento principal | custo zero | isolamento de contexto e velocidade |

## Alternativas por papel

Se quiser trocar, estes são do mesmo provedor e resolvem o mesmo papel:

- **Código mais forte**: `kimi-k2.7-code` ($0,95 / $4,00).
- **Visão barata**: `claude-haiku-5-5` ou `gpt-6-luna` ($0,10 / $0,50) — 20x mais baratos que o gemini, com menos contexto.
- **Leitura longa mais forte**: `kimi-k3.1-pro` ($2,00 / $10,00) — caro; só se o beam errar.
- **Frontend barato**: `qwen3.8-flash#high` ($0,15 / $0,47).
- **Mais barato de todos**: `muse-spark-1.3-contributor` ($0,10 / $0,20).

## Custo real de uma tarefa

Ordem de grandeza, não medição:

- Print + parecer de CSS: ~$0,02.
- Repo médio (150k tokens): ~$0,10 com beam, ~$0,50 com modelo $2/M.
- Áudio de 3 minutos: ~$0,01.
- Corrigir typo: menos de $0,001.

O que encarece não é o preço por token — é delegar sem necessidade. A seção
"O preço da delegação" do `SKILL.md` vale igual nos dois perfis.

## Requisito

Crédito ativo no provedor `opencode-go`. Sem ele, os agentes falham na primeira
chamada. Confira com:

```bash
opencode models --provider opencode-go
```
