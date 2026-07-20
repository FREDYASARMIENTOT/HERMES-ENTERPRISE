function Get-RepoRootAndReportsDir {
    # Calculate repo root relative to this script (motor/tools)
    $scriptDir = Split-Path -Parent $PSScriptRoot
    $repoRoot = Join-Path -Path $scriptDir -ChildPath '..\..' | Resolve-Path -ErrorAction SilentlyContinue
    if ($null -eq $repoRoot) { $repoRoot = (Get-Item -Path $scriptDir).Parent.Parent.FullName } else { $repoRoot = $repoRoot.Path }
    $reportsDir = Join-Path -Path $repoRoot -ChildPath 'reports'
    if (-not (Test-Path $reportsDir)) { New-Item -ItemType Directory -Path $reportsDir | Out-Null }
    return @{ RepoRoot = $repoRoot; ReportsDir = $reportsDir }
}

function Escribir-ProgresoHermes {
    param(
        [string]$Evento,
        [string]$Paso,
        [string]$Detalle = ''
    )
    $dirs = Get-RepoRootAndReportsDir
    $reportsDir = $dirs.ReportsDir
    $timestamp = (Get-Date).ToString('o')
    $entry = "{0} | {1} | {2} | {3}" -f $timestamp, $Evento, $Paso, $Detalle
    $logPath = Join-Path -Path $reportsDir -ChildPath 'hermes.log'
    Add-Content -Path $logPath -Value $entry
    $statusPath = Join-Path -Path $reportsDir -ChildPath 'EstadoEjecucion.json'
    $status = @{
        timestamp = $timestamp;
        paso = $Paso;
        evento = $Evento;
        detalle = $Detalle
    }
    $status | ConvertTo-Json | Out-File -FilePath $statusPath -Encoding utf8
}

function Start-EventBus {
    param()
    Write-Host "[Observabilidad] EventBus iniciado"
    Escribir-ProgresoHermes -Evento 'Inicio' -Paso 'EventBus' -Detalle 'Start'
}

function Stop-EventBus {
    param()
    Write-Host "[Observabilidad] EventBus detenido"
    Escribir-ProgresoHermes -Evento 'Progreso' -Paso 'EventBus' -Detalle 'Stop'
}

function Write-HermesLog {
    param(
        [string]$Message
    )
    $dirs = Get-RepoRootAndReportsDir
    $reportsDir = $dirs.ReportsDir
    $timestamp = (Get-Date).ToString('o')
    $path = Join-Path -Path $reportsDir -ChildPath 'hermes.log'
    Add-Content -Path $path -Value ("$timestamp | LOG | $Message")
}

function Write-HermesStatus {
    param(
        [string]$Key,
        [string]$Value
    )
    $dirs = Get-RepoRootAndReportsDir
    $reportsDir = $dirs.ReportsDir
    $statusPath = Join-Path -Path $reportsDir -ChildPath 'EstadoEjecucion.json'
    $obj = @{}
    if (Test-Path $statusPath) { $obj = (Get-Content $statusPath -Raw | ConvertFrom-Json) }
    $obj.$Key = $Value
    $obj | ConvertTo-Json | Out-File -FilePath $statusPath -Encoding utf8
}
