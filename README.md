# orquestrador

Skill de orquestração multi-modelo para o opencode v2.

O modelo da sessão principal segura o contexto e delega partes do trabalho para subagentes que rodam em **modelos diferentes**, escolhidos por especialidade. Cada subagente roda em sessão filha com contexto limpo, devolve o resultado, e é encerrado.

## Por que existe

Modelo free não é um só. Cada um tem um ponto forte: um vê imagem, outro aguenta 1M de contexto, outro é rápido porque é pequeno. Usar sempre o mesmo modelo é desperdício — e em free tier, desperdício vira fila.

Só que "modelo certo" não é slogan: o benchmark deste repo mostrou onde a especialização realmente paga e onde ela só custa. Os resultados estão abaixo, incluindo as duas vezes em que a skill perdeu.

## Estrutura

```
orquestrador/
├── SKILL.md                     # protocolo de orquestração
├── references/
│   └── modelos-free.md          # ficha técnica + fallback + o que o benchmark desmentiu
├── evals/
│   ├── evals.json               # 4 casos com expectativas verificáveis
│   └── files/                   # fixtures (print, README com typo)
├── benchmarks/
│   ├── iteration-1/             # benchmark.json + review.html
│   └── iteration-2/
├── agents/                      # os 6 subagentes (vão para ~/.config/opencode/agents/)
├── install.ps1                  # instalador Windows
├── LICENSE
└── README.md
```

Os subagentes ficam fora da skill, em `~/.config/opencode/agents/`:

| Agente | Modelo |
|---|---|
| `codigo` | deepseek-v4.1-flash-free `#high` |
| `visao` | nemotron-3.5-super-vl-free `#high` |
| `contexto-longo` | beam-free `#high` |
| `frontend` | glm-5.3-flash-free `#high` |
| `audio` | mimo-v2.6-flash-free |
| `rapido` | flint-40b-free `#low` |

Skill não carrega modelo. O agente carrega. A skill só decide o roteamento.

## Instalação

Windows:

```powershell
git clone https://github.com/JBRYAN333/orquestrador
cd orquestrador
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

Manual: copiar o conteúdo para `~/.config/opencode/skills/orquestrador/` e os seis `.md`
de `agents/` para `~/.config/opencode/agents/`. O opencode recarrega sozinho, sem reiniciar.

Validar:

```bash
opencode debug agents
```

Desinstalar:

```powershell
powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
```

## Uso

Não precisa invocar. A skill dispara quando a tarefa tem parte visual, áudio, volume grande, ou quando o usuário pede para delegar. Também aceita chamada explícita:

```
/orquestrador analisa o print e me diz o que mudar
```

## Benchmark

4 tarefas, 2 configurações (com e sem orquestração), 1 execução cada. Baseline = `deepseek-v4.1-flash-free` resolvendo sozinho, proibido de delegar. Detalhe completo em `benchmarks/*/benchmark.json` e no `review.html` de cada iteração.

### Iteração 1 — a skill perdeu

| | Com skill | Sem skill |
|---|---|---|
| Pass rate | 0,846 | **0,875** |
| Tokens/tarefa | 46.141 | 22.534 |
| Tempo/tarefa | 148 s | 131 s |

Duas falhas concretas:

- **`contexto-longo` estourou 20 passos** num repo médio e entregou "máximo de passos atingido" no topo da resposta.
- **`visao` inventou um elemento**: descreveu a scrollbar horizontal do print como "controles de paginação".
- Numa tarefa de **uma imagem só**, a orquestração gastou **10x mais tokens** (39.314 vs 3.873) sem melhorar a resposta.

### Iteração 2 — corrigido nos dois casos que falharam

| Eval | Iteração 1 | Iteração 2 | Baseline |
|---|---|---|---|
| Repo Next→Vite | 4/5 (194,5 s) | **5/5 (53,2 s)** | 5/5 (194,9 s) |
| Áudio de cliente | 3/4 (368,7 s) | **4/4 (224,3 s)** | 2/4 (290,7 s) |

As duas falhas eram de **orçamento de passos**, não de modelo: `contexto-longo` foi de 20 para 40 e `audio` de 12 para 30. Nos dois casos re-executados, 9/9 contra 7/9 do baseline.

### O que o benchmark desmentiu

- **`mimo-v2.6` não ouve nativamente.** O agente `audio` transcreveu via `faster-whisper` no shell, igual ao baseline. O prompt do agente agora assume isso e obriga a declarar o caminho usado.
- **Modelo com visão já é suficiente para uma imagem.** Delegar print único custa caro e não melhora a leitura.
- **Passos são orçamento, não proteção.** Cap baixo corta a entrega no meio e produz resposta confiável com cara de completa.

### Limites do benchmark

1 execução por configuração — é sinal direcional, não estatística. A skill está instalada globalmente, então o braço de controle precisou ser instruído a não delegar. No eval 1 o agente pai conhecia o CSS original do fixture, o que contamina a precisão visual.

## Limites conhecidos

- Subagente não vê a conversa. Brief ruim = resultado ruim.
- Free tier enfileira. Teto confortável: 3 em paralelo.
- Sessão filha é de tarefa única. Não é chat; não reabra para "continuar".
- Delegar multiplica tokens. A conta só fecha quando o material não cabe no seu contexto ou a especialidade muda o resultado.
