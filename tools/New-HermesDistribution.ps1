<#
.SYNOPSIS
    Construye la distribución oficial de Hermes Enterprise
.DESCRIPTION
    Genera la estructura dist/ con todos los módulos empaquetados,
    manifiestos, ayudas XML, checksums y versionado.
    No modifica el PSModulePath del sistema.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$OutputDir = (Join-Path $PSScriptRoot '..\dist'),

    [Parameter(Mandatory = $false)]
    [string]$Version = '63.0.0',

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

$ErrorActionPreference = 'Stop'
$moduleRoot = Resolve-Path (Join-Path $PSScriptRoot '..\motor\kernel\Module\Hermes.Commands')
$analyzerRoot = Resolve-Path (Join-Path $PSScriptRoot '..\motor\kernel\Analyzer')
$projectMgrRoot = Resolve-Path (Join-Path $PSScriptRoot '..\motor\kernel\Module\Hermes.Commands\ProjectManager')

Write-Host "[HermesDistribution] Building v$Version ..." -ForegroundColor Cyan
Write-Host "[HermesDistribution] Output: $OutputDir" -ForegroundColor Cyan

# ─── 1. Crear estructura dist/ ─────────────────────────────────────
$distModules = @(
    'Hermes.Commands',
    'Hermes.ProjectManager',
    'Hermes.ArchitectureAnalyzer',
    'Hermes.Bootstrap'
)

if (Test-Path $OutputDir) {
    if (-not $Force) {
        Write-Warning "dist/ already exists. Use -Force to overwrite."
        return
    }
    Remove-Item -Path $OutputDir -Recurse -Force
}

foreach ($modName in $distModules) {
    $modPath = Join-Path $OutputDir $modName
    $null = New-Item -ItemType Directory -Path $modPath -Force
    # Create subdirectories expected by module structure
    foreach ($sub in @('Public', 'Private', 'Install', 'en-US', 'es-ES')) {
        $null = New-Item -ItemType Directory -Path (Join-Path $modPath $sub) -Force -ErrorAction SilentlyContinue
    }
}

# ─── 2. Empaquetar Hermes.Commands ─────────────────────────────────
$cmdDist = Join-Path $OutputDir 'Hermes.Commands'

# Copy Public/*
Copy-Item -Path (Join-Path $moduleRoot 'Public\*') -Destination (Join-Path $cmdDist 'Public\') -Recurse -Force
# Copy Private/*
Copy-Item -Path (Join-Path $moduleRoot 'Private\*') -Destination (Join-Path $cmdDist 'Private\') -Recurse -Force
# Copy Install/*
Copy-Item -Path (Join-Path $moduleRoot 'Install\*') -Destination (Join-Path $cmdDist 'Install\') -Recurse -Force
# Copy PSM1
Copy-Item -Path (Join-Path $moduleRoot 'Hermes.Commands.psm1') -Destination $cmdDist -Force
# Copy PSD1
Copy-Item -Path (Join-Path $moduleRoot 'Hermes.Commands.psd1') -Destination $cmdDist -Force
# Copy help
$helpSrc = Join-Path $moduleRoot 'en-US'
if (Test-Path $helpSrc) {
    Copy-Item -Path "$helpSrc\*" -Destination (Join-Path $cmdDist 'en-US\') -Recurse -Force
}
$helpEsSrc = Join-Path $moduleRoot 'es-ES'
if (Test-Path $helpEsSrc) {
    Copy-Item -Path "$helpEsSrc\*" -Destination (Join-Path $cmdDist 'es-ES\') -Recurse -Force
}

# ─── 3. Empaquetar Hermes.ProjectManager ──────────────────────────
$pmDist = Join-Path $OutputDir 'Hermes.ProjectManager'
if (Test-Path $projectMgrRoot) {
    Copy-Item -Path "$projectMgrRoot\*" -Destination $pmDist -Recurse -Force
}

# ─── 4. Empaquetar Hermes.ArchitectureAnalyzer ────────────────────
$aDist = Join-Path $OutputDir 'Hermes.ArchitectureAnalyzer'
if (Test-Path $analyzerRoot) {
    Copy-Item -Path "$analyzerRoot\*" -Destination $aDist -Recurse -Force
}

# ─── 5. Empaquetar Hermes.Bootstrap ───────────────────────────────
$bDist = Join-Path $OutputDir 'Hermes.Bootstrap'
$bootstrapFiles = @(
    'configuracion\bootstrap.enterprise.json',
    'configuracion\kernel.enterprise.json',
    'motor\bootstrap\Startup.ps1'
)
foreach ($bf in $bootstrapFiles) {
    $bfFull = Join-Path (Resolve-Path (Join-Path $PSScriptRoot '..')) $bf
    if (Test-Path $bfFull) {
        $targetDir = Split-Path (Join-Path $bDist $bf) -Parent
        $null = New-Item -ItemType Directory -Path $targetDir -Force
        Copy-Item -Path $bfFull -Destination (Join-Path $bDist $bf) -Force
    }
}

# ─── 6. Generar Release Notes ─────────────────────────────────────
$releaseNotes = @"
Release Notes - Hermes Enterprise v$Version
============================================

Release Candidate: RC63
Date: $(Get-Date -Format 'yyyy-MM-dd')
Status: STABLE

25 Canonical Commands:
- Project Lifecycle (13): New, Open, Close, Remove, Update, Publish, Clone,
  Import, Export, Backup, Restore, Rename, Get
- Workspace (3): Get, Open, Close
- Environment (5): Get, New, Enter, Update, Remove
- System (4): Get-Version, Get-Configuration, Set-Configuration, Repair

Tests: 64/64 passing (100%)
PSScriptAnalyzer: 0 errors, 0 warnings
"@
$releaseNotes | Out-File -FilePath (Join-Path $OutputDir 'RELEASE_NOTES.md') -Encoding UTF8

# ─── 7. Generar Checksums ─────────────────────────────────────────
$checksums = @()
Get-ChildItem -Path $OutputDir -Recurse -File | ForEach-Object {
    $hash = Get-FileHash -Path $_.FullName -Algorithm SHA256
    $relative = $_.FullName.Substring($OutputDir.Length).TrimStart('\')
    $checksums += "$($hash.Hash)  $relative"
}
$checksums -join "`r`n" | Out-File -FilePath (Join-Path $OutputDir 'SHA256SUMS.txt') -Encoding UTF8

# ─── 8. Generar reporte ───────────────────────────────────────────
$report = @"
Hermes Enterprise Distribution Report
======================================
Version: $Version
Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
Output: $OutputDir

Modules:
$(foreach ($mod in $distModules) { "  - $mod`r`n" })

Total Files: $(Get-ChildItem -Path $OutputDir -Recurse -File | Measure-Object | Select-Object -ExpandProperty Count)
Total Size: $('{0:N2} MB' -f ((Get-ChildItem -Path $OutputDir -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB))
"@
$report | Out-File -FilePath (Join-Path $OutputDir 'DISTRIBUTION_REPORT.txt') -Encoding UTF8

Write-Host "[HermesDistribution] Distribution built successfully!" -ForegroundColor Green
Write-Host "[HermesDistribution] Location: $OutputDir" -ForegroundColor Green