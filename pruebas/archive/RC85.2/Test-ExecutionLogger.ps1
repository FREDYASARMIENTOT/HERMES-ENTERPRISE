<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ExecutionLogger.ps1
Propósito:
    Tests unitarios para ExecutionLogger.ps1
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition {
    param([bool]$CondicionEvaluada, [string]$MensajeError)
    if (-not $CondicionEvaluada) { throw $MensajeError }
}

. (Join-Path $RutaRaizRepositorio "motor\sandbox\ExecutionLogger.ps1")

$RutaTempTest = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP "HermesLoggerTest_$(Get-Random)"))

function Limpiar-PruebaLogger {
    if (Test-Path $RutaTempTest) {
        Remove-Item -Path $RutaTempTest -Recurse -Force -ErrorAction SilentlyContinue
    }
}

try {
    Limpiar-PruebaLogger
    New-Item -ItemType Directory -Path $RutaTempTest -Force | Out-Null

    Write-Host "[1/4] Test Write-HermesEnterpriseExecutionLog..." -ForegroundColor Cyan
    Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaTempTest -Mensaje "Test INFO" -Nivel INFO
    Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaTempTest -Mensaje "Test SUCCESS" -Nivel SUCCESS
    Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaTempTest -Mensaje "Test WARNING" -Nivel WARNING
    Write-HermesEnterpriseExecutionLog -RutaSandbox $RutaTempTest -Mensaje "Test ERROR" -Nivel ERROR

    $RutaExecutionLog = Join-Path $RutaTempTest "Logs" "Execution.log"
    Assert-HermesEnterpriseCondition (Test-Path $RutaExecutionLog) "No se creó Execution.log"
    $ContenidoLog = Get-Content -Path $RutaExecutionLog -Raw
    Assert-HermesEnterpriseCondition ($ContenidoLog -like "*Test INFO*") "Log no contiene mensaje INFO"
    Assert-HermesEnterpriseCondition ($ContenidoLog -like "*Test ERROR*") "Log no contiene mensaje ERROR"
    Assert-HermesEnterpriseCondition ($ContenidoLog -like "*[INFO]*") "Log no contiene nivel INFO"
    Assert-HermesEnterpriseCondition ($ContenidoLog -like "*[ERROR]*") "Log no contiene nivel ERROR"
    Write-Host "Write-HermesEnterpriseExecutionLog: PASS" -ForegroundColor Green

    Write-Host "[2/4] Test Write-HermesEnterpriseExecutionState..." -ForegroundColor Cyan
    Write-HermesEnterpriseExecutionState -RutaSandbox $RutaTempTest -Paso "TestPaso" -Estado "RUNNING" -Porcentaje 50 -Detalle "Test ejecutándose"

    $RutaCurrentState = Join-Path $RutaTempTest "Logs" "CurrentState.json"
    Assert-HermesEnterpriseCondition (Test-Path $RutaCurrentState) "No se creó CurrentState.json"
    $EstadoActual = Get-Content -Path $RutaCurrentState -Raw | ConvertFrom-Json
    Assert-HermesEnterpriseCondition ($EstadoActual.Paso -eq "TestPaso") "Paso incorrecto en CurrentState"
    Assert-HermesEnterpriseCondition ($EstadoActual.Estado -eq "RUNNING") "Estado incorrecto en CurrentState"
    Assert-HermesEnterpriseCondition ($EstadoActual.Porcentaje -eq 50) "Porcentaje incorrecto en CurrentState"

    $RutaExecutionJson = Join-Path $RutaTempTest "Logs" "Execution.json"
    Assert-HermesEnterpriseCondition (Test-Path $RutaExecutionJson) "No se creó Execution.json"
    $Historial = Get-Content -Path $RutaExecutionJson -Raw | ConvertFrom-Json
    Assert-HermesEnterpriseCondition ($Historial.Count -ge 1) "Historial de ejecución vacío o incorrecto"
    Write-Host "Write-HermesEnterpriseExecutionState: PASS" -ForegroundColor Green

    Write-Host "[3/4] Test Get-HermesEnterpriseExecutionState..." -ForegroundColor Cyan
    $EstadoRecuperado = Get-HermesEnterpriseExecutionState -RutaSandbox $RutaTempTest
    Assert-HermesEnterpriseCondition ($null -ne $EstadoRecuperado) "Get-HermesEnterpriseExecutionState retornó null"
    Assert-HermesEnterpriseCondition ($EstadoRecuperado.Paso -eq "TestPaso") "Estado recuperado tiene paso incorrecto"
    Assert-HermesEnterpriseCondition ($EstadoRecuperado.Estado -eq "RUNNING") "Estado recuperado tiene estado incorrecto"
    Write-Host "Get-HermesEnterpriseExecutionState: PASS" -ForegroundColor Green

    Write-Host "[4/4] Test acumulación de pasos..." -ForegroundColor Cyan
    Write-HermesEnterpriseExecutionState -RutaSandbox $RutaTempTest -Paso "PasoCompletado" -Estado "COMPLETED" -Porcentaje 100
    $HistorialActualizado = Get-Content -Path $RutaExecutionJson -Raw | ConvertFrom-Json
    Assert-HermesEnterpriseCondition ($HistorialActualizado.Count -eq 2) "Historial no acumuló segundo paso"
    Assert-HermesEnterpriseCondition ($HistorialActualizado[1].Paso -eq "PasoCompletado") "Segundo paso incorrecto en historial"

    $UltimoEstado = Get-HermesEnterpriseExecutionState -RutaSandbox $RutaTempTest
    Assert-HermesEnterpriseCondition ($UltimoEstado.Paso -eq "PasoCompletado") "Último estado no actualizado correctamente"
    Write-Host "Acumulación de pasos: PASS" -ForegroundColor Green
}
finally {
    Limpiar-PruebaLogger
}

Write-Host "Test-ExecutionLogger completado correctamente." -ForegroundColor Green
