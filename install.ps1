# Instala a skill `orquestrador` e os 6 subagentes no opencode v2.
# Uso:  powershell -ExecutionPolicy Bypass -File .\install.ps1
#       powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall

param([switch]$Uninstall)

$ErrorActionPreference = "Stop"
$root     = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfg      = Join-Path $env:USERPROFILE ".config\opencode"
$skillDst = Join-Path $cfg "skills\orquestrador"
$agentsDst= Join-Path $cfg "agents"

if ($Uninstall) {
    if (Test-Path $skillDst) { Remove-Item $skillDst -Recurse -Force }
    foreach ($a in Get-ChildItem (Join-Path $root "agents") -Filter *.md) {
        $t = Join-Path $agentsDst $a.Name
        if (Test-Path $t) { Remove-Item $t -Force }
    }
    Write-Host "Removido." -ForegroundColor Yellow
    return
}

New-Item -ItemType Directory -Force -Path $skillDst, $agentsDst | Out-Null
New-Item -ItemType Directory -Force -Path (Join-Path $skillDst "references"), (Join-Path $skillDst "evals") | Out-Null

Copy-Item (Join-Path $root "SKILL.md") $skillDst -Force
Copy-Item (Join-Path $root "README.md") $skillDst -Force
Copy-Item (Join-Path $root "references\modelos-free.md") (Join-Path $skillDst "references") -Force
Copy-Item (Join-Path $root "evals\evals.json") (Join-Path $skillDst "evals") -Force
Copy-Item (Join-Path $root "agents\*.md") $agentsDst -Force

Write-Host "Instalado em $skillDst" -ForegroundColor Green
Write-Host "Agentes em $agentsDst" -ForegroundColor Green
Write-Host "O opencode recarrega sozinho. Valide com: opencode debug agents" -ForegroundColor DarkGray
