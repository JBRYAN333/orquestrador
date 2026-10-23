# orquestrador

Skill de orquestração multi-modelo para o opencode v2.

O modelo da sessão principal segura o contexto e delega partes do trabalho para subagentes que rodam em **modelos diferentes**, escolhidos por especialidade. Cada subagente roda em sessão filha com contexto limpo, devolve o resultado, e é encerrado.

## Por que existe

Modelo free não é um só. Cada um tem um ponto forte: um vê imagem, outro aguenta 1M de contexto, outro ouve áudio, outro é rápido porque é pequeno. Usar sempre o mesmo modelo é desperdício — e em free tier, desperdício vira fila.

## Estrutura

```
orquestrador/
├── SKILL.md                     # protocolo de orquestração
├── references/
│   └── modelos-free.md          # ficha técnica + fallback
├── evals/
│   └── evals.json               # casos de teste
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

## Limites conhecidos

- Subagente não vê a conversa. Brief ruim = resultado ruim.
- Free tier enfileira. Teto confortável: 3 em paralelo.
- Sessão filha é de tarefa única. Não é chat; não reabra para "continuar".
