<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ExecutionDashboard.ps1
Propósito:
    Tests unitarios para ExecutionDashboard.ps1
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

. (Join-Path $RutaRaizRepositorio "motor\sandbox\ExecutionDashboard.ps1")

Write-Host "[1/2] Test Show-HermesEnterpriseExecutionDashboard..." -ForegroundColor Cyan

$Salida = Show-HermesEnterpriseExecutionDashboard -RutaSandbox "C:\Test\Sandbox001" -Escenario "EmptyFolder" -Estado "RUNNING" -Porcentaje 50 -TiempoTranscurridoSegundos 125 -PasoActual "3/7 - Ejecutar escenario" -Errores @() -Warnings @() -Quiet

Assert-HermesEnterpriseCondition ($Salida -like "*HERMES ENTERPRISE*") "Dashboard no contiene título"
Assert-HermesEnterpriseCondition ($Salida -like "*Sandbox:*") "Dashboard no contiene etiqueta Sandbox"
Assert-HermesEnterpriseCondition ($Salida -like "*Escenario:*") "Dashboard no contiene etiqueta Escenario"
Assert-HermesEnterpriseCondition ($Salida -like "*50%*") "Dashboard no muestra porcentaje"
Assert-HermesEnterpriseCondition ($Salida -like "*02:05*") "Dashboard no muestra tiempo formateado"
Write-Host "Show-HermesEnterpriseExecutionDashboard: PASS" -ForegroundColor Green

Write-Host "[2/2] Test Show-HermesEnterpriseExecutionProgress..." -ForegroundColor Cyan

$SalidaProgress = Show-HermesEnterpriseExecutionProgress -Porcentaje 75 -Mensaje "Paso de prueba" -Quiet

Assert-HermesEnterpriseCondition ($SalidaProgress -like "*75%*") "Progress no muestra porcentaje"
Assert-HermesEnterpriseCondition ($SalidaProgress -like "*[#-]*") "Progress no muestra barra de progreso"
Assert-HermesEnterpriseCondition ($SalidaProgress -like "*Paso de prueba*") "Progress no muestra mensaje"
Write-Host "Show-HermesEnterpriseExecutionProgress: PASS" -ForegroundColor Green

Write-Host "Test-ExecutionDashboard completado correctamente." -ForegroundColor Green
