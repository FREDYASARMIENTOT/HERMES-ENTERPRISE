<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ExecutionSupervisor.ps1
Propósito:
    Tests unitarios para ExecutionSupervisor.ps1 en modo NoPause
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

function Test-HermesEnterpriseCount {
    param($Coleccion)
    if ($null -eq $Coleccion) { return 0 }
    if ($Coleccion -is [array]) { return $Coleccion.Count }
    return 1
}

. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Initialize-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Invoke-HermesEnterpriseScenario.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Test-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Export-HermesEnterpriseSandboxReport.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandboxUserGuide.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseSandboxInstructions.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Get-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "scripts\Remove-HermesEnterpriseSandbox.ps1")
. (Join-Path $RutaRaizRepositorio "motor\sandbox\ExecutionLogger.ps1")
. (Join-Path $RutaRaizRepositorio "motor\sandbox\ExecutionDashboard.ps1")
. (Join-Path $RutaRaizRepositorio "motor\sandbox\ExecutionSupervisor.ps1")

$RutaTempTest = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP "HermesSupervisorTest_$(Get-Random)"))

function Limpiar-PruebaSupervisor {
    if (Test-Path $RutaTempTest) {
        Remove-Item -Path $RutaTempTest -Recurse -Force -ErrorAction SilentlyContinue
    }
}

try {
    Limpiar-PruebaSupervisor

    Write-Host "[1/3] Test ExecutionSupervisor con NoPause y SkipSmokeTest..." -ForegroundColor Cyan

    # Ejecutar el supervisor en modo silencioso (capturando stdout y stderr)
    $null = Start-HermesEnterpriseExecutionSupervisor -RutaRaizSandbox $RutaTempTest -Escenario "EmptyFolder" -NombreProyecto "TestProject" -NoPause -SkipSmokeTest 2>&1 | Out-Null

    $Sandboxes = @(Get-ChildItem -Path $RutaTempTest -Directory -Filter "Test*" -ErrorAction SilentlyContinue)
    Assert-HermesEnterpriseCondition ($Sandboxes.Count -eq 1) "No se creó exactamente un Sandbox. Encontrados: $($Sandboxes.Count)"

    $RutaSandbox = $Sandboxes[0].FullName
    $Metadata = Get-Content -Path (Join-Path $RutaSandbox "sandbox.json") -Raw | ConvertFrom-Json
    Assert-HermesEnterpriseCondition ($Metadata.Estado -eq "Completed") "Estado del Sandbox no es Completed. Actual: $($Metadata.Estado)"
    Assert-HermesEnterpriseCondition ($Metadata.Resultado -eq "SUCCESS") "Resultado del Sandbox no es SUCCESS"
    Write-Host "ExecutionSupervisor NoPause: PASS" -ForegroundColor Green

    Write-Host "[2/3] Validar logs generados..." -ForegroundColor Cyan

    $RutaExecutionLog = Join-Path $RutaSandbox "Logs" "Execution.log"
    Assert-HermesEnterpriseCondition (Test-Path $RutaExecutionLog) "No se generó Execution.log"
    $ContenidoLog = Get-Content -Path $RutaExecutionLog -Raw
    Assert-HermesEnterpriseCondition ($ContenidoLog -like "*Paso 1/7*") "Log no contiene paso 1"
    Assert-HermesEnterpriseCondition ($ContenidoLog -like "*Paso 7/7*") "Log no contiene paso 7"
    Assert-HermesEnterpriseCondition ($ContenidoLog -like "*completada*") "Log no contiene mensaje de completado"

    $RutaExecutionJson = Join-Path $RutaSandbox "Logs" "Execution.json"
    Assert-HermesEnterpriseCondition (Test-Path $RutaExecutionJson) "No se generó Execution.json"
    $HistorialRaw = Get-Content -Path $RutaExecutionJson -Raw | ConvertFrom-Json
    $Historial = @($HistorialRaw)
    Assert-HermesEnterpriseCondition ($Historial.Count -ge 7) "Historial no contiene todos los pasos. Total: $($Historial.Count)"
    Write-Host "Logs generados: PASS" -ForegroundColor Green

    Write-Host "[3/3] Validar artefactos generados..." -ForegroundColor Cyan

    $UserGuide = Join-Path $RutaSandbox "UserGuide.md"
    Assert-HermesEnterpriseCondition (Test-Path $UserGuide) "No se generó UserGuide.md"

    $Instructions = Join-Path $RutaSandbox "SandboxInstructions.ps1"
    Assert-HermesEnterpriseCondition (Test-Path $Instructions) "No se generó SandboxInstructions.ps1"

    $RutaReports = Join-Path $RutaSandbox "Reports"
    Assert-HermesEnterpriseCondition (Test-Path (Join-Path $RutaReports "InstallationReport.json")) "No se generó InstallationReport.json"
    Assert-HermesEnterpriseCondition (Test-Path (Join-Path $RutaReports "ValidationReport.json")) "No se generó ValidationReport.json"
    Assert-HermesEnterpriseCondition (Test-Path (Join-Path $RutaReports "AcceptanceReport.json")) "No se generó AcceptanceReport.json"
    Write-Host "Artefactos generados: PASS" -ForegroundColor Green
}
finally {
    Limpiar-PruebaSupervisor
}

Write-Host "Test-ExecutionSupervisor completado correctamente." -ForegroundColor Green
