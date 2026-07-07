<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : ExecutionLogger.ps1
Propósito:
    Registra logs y estado continuo de la ejecución del Sandbox.
    Escribe Execution.log, Execution.json y CurrentState.json después de cada paso.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Write-HermesEnterpriseExecutionLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RutaSandbox,
        [Parameter(Mandatory = $true)][string]$Mensaje,
        [Parameter(Mandatory = $false)][ValidateSet("INFO", "WARNING", "ERROR", "SUCCESS")]
        [string]$Nivel = "INFO"
    )

    $RutaLogs = Join-Path $RutaSandbox "Logs"
    if (-not (Test-Path $RutaLogs)) {
        New-Item -ItemType Directory -Path $RutaLogs -Force | Out-Null
    }

    $Timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $Linea = "[$Timestamp] [$Nivel] $Mensaje"

    $RutaExecutionLog = Join-Path $RutaLogs "Execution.log"
    Add-Content -Path $RutaExecutionLog -Value $Linea -Encoding UTF8

    switch ($Nivel) {
        "ERROR"   { Write-Host $Linea -ForegroundColor Red }
        "WARNING" { Write-Host $Linea -ForegroundColor Yellow }
        "SUCCESS" { Write-Host $Linea -ForegroundColor Green }
        default   { Write-Host $Linea -ForegroundColor Gray }
    }
}

function Write-HermesEnterpriseExecutionState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$RutaSandbox,
        [Parameter(Mandatory = $true)][string]$Paso,
        [Parameter(Mandatory = $true)][ValidateSet("PENDING", "RUNNING", "COMPLETED", "FAILED", "SKIPPED")]
        [string]$Estado,
        [Parameter(Mandatory = $false)][int]$Porcentaje = 0,
        [Parameter(Mandatory = $false)][string]$Detalle = ""
    )

    $RutaLogs = Join-Path $RutaSandbox "Logs"
    if (-not (Test-Path $RutaLogs)) {
        New-Item -ItemType Directory -Path $RutaLogs -Force | Out-Null
    }

    $EstadoActual = [pscustomobject][ordered]@{
        Paso        = $Paso
        Estado      = $Estado
        Porcentaje  = $Porcentaje
        Detalle     = $Detalle
        Timestamp   = (Get-Date).ToString("o")
    }

    $RutaCurrentState = Join-Path $RutaLogs "CurrentState.json"
    $EstadoActual | ConvertTo-Json -Depth 5 | Set-Content -Path $RutaCurrentState -Encoding UTF8

    $RutaExecutionJson = Join-Path $RutaLogs "Execution.json"
    $Historial = @()
    if (Test-Path $RutaExecutionJson) {
        $Historial = Get-Content -Path $RutaExecutionJson -Raw | ConvertFrom-Json
        if ($Historial -isnot [array]) { $Historial = @($Historial) }
    }

    $Historial += $EstadoActual
    $Historial | ConvertTo-Json -Depth 5 | Set-Content -Path $RutaExecutionJson -Encoding UTF8
}

function Get-HermesEnterpriseExecutionState {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][string]$RutaSandbox)

    $RutaCurrentState = Join-Path $RutaSandbox "Logs" "CurrentState.json"
    if (Test-Path $RutaCurrentState) {
        return Get-Content -Path $RutaCurrentState -Raw | ConvertFrom-Json
    }

    return $null
}
