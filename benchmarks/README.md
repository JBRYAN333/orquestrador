# Benchmarks

Resultados do ciclo de avaliação do skill-creator. Cada pasta é uma iteração com `benchmark.json` (dados) e `review.html` (viewer estático, abre no navegador sem servidor).

## Como foi medido

- **Execuções**: 1 por configuração por eval. Sinal direcional, não estatística.
- **Com skill**: o agente principal orquestra, chamando os subagentes de `agents/`.
- **Sem skill**: um único subagente `general` (`deepseek-v4.1-flash-free`) instruído a não delegar e não carregar skills. A skill está instalada globalmente, então a proibição explícita foi necessária — é a limitação metodológica principal.
- **Tokens**: `tokens_input + tokens_output + tokens_reasoning` somados das sessões do run, lidos de `opencode.db`.
- **Tempo**: `time_updated - time_created` da sessão, não cronômetro de parede.
- **Nota**: cada eval tem expectativas verificáveis em `evals/evals.json`; o `grading.json` de cada run cita a evidência linha a linha.

## Iteração 1

4 evals, 8 runs.

| Eval | Com skill | Sem skill |
|---|---|---|
| 1. Print de dashboard | 5/6 | 6/6 |
| 2. Repo Next→Vite | 4/5 | 5/5 |
| 3. Áudio de cliente | 3/4 | 2/4 |
| 4. Restraint (typo) | 3/3 | 3/3 |
| **Total** | **15/18 (0,846)** | **16/18 (0,875)** |

Falhas: `contexto-longo` estourou 20 passos; `visao` inventou paginação onde havia scrollbar; custo de delegação 10x maior numa imagem só.

## Iteração 2

Re-executou só os dois casos que falharam, depois de corrigir o orçamento de passos (20→40 e 12→30) e o prompt do `visao`.

| Eval | Iteração 1 | Iteração 2 | Baseline |
|---|---|---|---|
| 2. Repo Next→Vite | 4/5 (194,5 s) | 5/5 (53,2 s) | 5/5 (194,9 s) |
| 3. Áudio de cliente | 3/4 (368,7 s) | 4/4 (224,3 s) | 2/4 (290,7 s) |

## O que não foi provado

- Variância: 1 run por config. Rodar 3x por eval é o próximo passo se alguém quiser número com margem.
- O eval 1 não foi re-rodado depois da correção do `visao`. A correção está no prompt do agente, mas sem medição.
- O baseline do eval 1 foi refeito uma vez: a primeira tentativa abriu o HTML fonte e leu os hex exatos, o que invalidava a comparação.
