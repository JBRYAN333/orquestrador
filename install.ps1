# Instala a skill `orquestrador` e os 6 subagentes no opencode v2.
#
#   powershell -ExecutionPolicy Bypass -File .\install.ps1
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Profile paid
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -DryRun
#   powershell -ExecutionPolicy Bypass -File .\install.ps1 -Uninstall
#
# Os prompts dos agentes são os mesmos nos dois perfis. O que muda é só a linha
# `model:` de cada arquivo, aplicada a partir de profiles\<perfil>.json.

param(
    [ValidateSet("free", "paid")]
    [string]$Profile = "free",
    [switch]$Uninstall,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

$root      = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfg       = Join-Path $env:USERPROFILE ".config\opencode"
$skillDst  = Join-Path $cfg "skills\orquestrador"
$agentsDst = Join-Path $cfg "agents"
$profileFn = Join-Path $root "profiles\$Profile.json"

if ($Uninstall) {
    if ($DryRun) {
        Write-Host "[dry-run] removeria $skillDst" -ForegroundColor DarkGray
        foreach ($a in Get-ChildItem (Join-Path $root "agents") -Filter *.md) {
            Write-Host "[dry-run] removeria $(Join-Path $agentsDst $a.Name)" -ForegroundColor DarkGray
        }
        return
    }
    if (Test-Path $skillDst) { Remove-Item $skillDst -Recurse -Force }
    foreach ($a in Get-ChildItem (Join-Path $root "agents") -Filter *.md) {
        $t = Join-Path $agentsDst $a.Name
        if (Test-Path $t) { Remove-Item $t -Force }
    }
    Write-Host "Removido." -ForegroundColor Yellow
    return
}

if (-not (Test-Path $profileFn)) {
    throw "Perfil não encontrado: $profileFn"
}
$profileData = Get-Content $profileFn -Raw | ConvertFrom-Json
$models = @{}
$profileData.models.PSObject.Properties | ForEach-Object { $models[$_.Name] = $_.Value }

$utf8 = New-Object System.Text.UTF8Encoding($false)

function Install-SkillFiles {
    if ($DryRun) {
        Write-Host "[dry-run] copiaria a skill para $skillDst" -ForegroundColor DarkGray
        return
    }
    New-Item -ItemType Directory -Force -Path $skillDst, $agentsDst | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $skillDst "references"), (Join-Path $skillDst "evals") | Out-Null
    Copy-Item (Join-Path $root "SKILL.md") $skillDst -Force
    Copy-Item (Join-Path $root "README.md") $skillDst -Force
    Copy-Item (Join-Path $root "references\modelos-free.md") (Join-Path $skillDst "references") -Force
    if (Test-Path (Join-Path $root "references\modelos-pagos.md")) {
        Copy-Item (Join-Path $root "references\modelos-pagos.md") (Join-Path $skillDst "references") -Force
    }
    Copy-Item (Join-Path $root "evals\evals.json") (Join-Path $skillDst "evals") -Force
}

function Install-Agents {
    foreach ($a in Get-ChildItem (Join-Path $root "agents") -Filter *.md) {
        $name = [System.IO.Path]::GetFileNameWithoutExtension($a.Name)
        $text = [System.IO.File]::ReadAllText($a.FullName)

        if ($models.ContainsKey($name)) {
            $model = $models[$name]
            $pattern = "(?m)^model:\s*\S+.*$"
            if ($text -notmatch $pattern) {
                Write-Warning "$name.md não tem linha 'model:' — copiado sem ajuste de modelo."
            } else {
                $text = [regex]::Replace($text, $pattern, "model: $model", 1)
            }
        } else {
            Write-Warning "$name.md não está no perfil '$Profile' — usando o modelo do arquivo."
            $model = "(do arquivo)"
        }

        if ($DryRun) {
            Write-Host ("[dry-run] {0,-16} -> {1}" -f $name, $model) -ForegroundColor DarkGray
        } else {
            [System.IO.File]::WriteAllText((Join-Path $agentsDst $a.Name), $text, $utf8)
            Write-Host ("{0,-16} -> {1}" -f $name, $model) -ForegroundColor Green
        }
    }
}

Write-Host "Perfil: $($profileData.label)" -ForegroundColor Cyan
if ($profileData.note) { Write-Host $profileData.note -ForegroundColor DarkGray }

Install-SkillFiles
Install-Agents

if (-not $DryRun) {
    Write-Host ""
    Write-Host "Skill em $skillDst" -ForegroundColor Green
    Write-Host "Agentes em $agentsDst" -ForegroundColor Green
    Write-Host "O opencode recarrega sozinho. Valide com: opencode debug agents" -ForegroundColor DarkGray
}
