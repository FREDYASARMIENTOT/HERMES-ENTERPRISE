Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = 'D:/HERMES-ENTERPRISE'
$reportsDir = Join-Path $repoRoot 'reports'
if (-not (Test-Path $reportsDir)) {
    New-Item -Path $reportsDir -ItemType Directory -Force | Out-Null
}

# NOTA: Asegurar que NO existan rutas corruptas del tipo D:/D/...
$modulesToTest = @(
    (Join-Path $repoRoot 'Start-HermesProject.ps1'),
    (Join-Path $repoRoot 'tools/HermesPathResolver.psm1'),
    (Join-Path $repoRoot 'tools/EnterprisePipeline.ps1'),
    (Join-Path $repoRoot 'motor/bootstrap/BootstrapOrchestrator.ps1'),
    (Join-Path $repoRoot 'motor/scheduler/Scheduler.ps1'),
    (Join-Path $repoRoot 'motor/config/Configuration.psm1'),
    (Join-Path $repoRoot 'tools/Observabilidad.ps1')
)

$results = @()

foreach ($modPath in $modulesToTest) {
    $item = [PSCustomObject]@{
        Module  = [System.IO.Path]::GetFileName($modPath)
        Path    = $modPath
        Status  = 'PENDING'
        Error   = $null
        TimeMs  = 0
    }

    if (-not (Test-Path $modPath)) {
        $item.Status = 'MISSING'
        $item.Error  = "Archivo no encontrado en el disco"
        $results += $item
        continue
    }

    try {
        $sw = [System.Diagnostics.Stopwatch]::StartNew()
        Import-Module $modPath -Force -ErrorAction Stop
        $sw.Stop()
        $item.TimeMs = $sw.ElapsedMilliseconds
        $item.Status = 'PASS'
    }
    catch {
        $item.Status = 'FAIL'
        $item.Error  = $_.Exception.Message
    }

    $results += $item
}

# Persistir evidencia
$jsonPath = Join-Path $reportsDir 'ModuleValidation.json'
$txtPath  = Join-Path $reportsDir 'ModuleValidation.txt'

$results | ConvertTo-Json -Depth 5 | Out-File -FilePath $jsonPath -Encoding utf8
$results | Format-Table -AutoSize | Out-String | Out-File -FilePath $txtPath -Encoding utf8

Write-Host "Validación completada. Reportes generados en $reportsDir"
