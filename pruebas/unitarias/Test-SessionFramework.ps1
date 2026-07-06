<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-SessionFramework.ps1
Propósito:
    Valida SessionDescriptor, SessionPersistence, SessionLoader, SessionRecovery,
    SessionTelemetry, SessionWizard y SessionManager.
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

. (Join-Path $RutaRaizRepositorio "motor\session\SessionManager.ps1")

$RutaTemporal = Join-Path $env:TEMP "HermesSessionTest_$(Get-Random)"
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null

# SessionDescriptor
$Descriptor = New-HermesEnterpriseSessionDescriptor -IdentificadorSesion "test-001" -NombreProyecto "TestProject" -RutaWorkspace $RutaTemporal -ModeloIA "ur-hermes-mini"
Assert-HermesEnterpriseCondition ($Descriptor.IdentificadorSesion -eq "test-001") "SessionDescriptor no conserva identificador."
Assert-HermesEnterpriseCondition ($Descriptor.ModeloIA -eq "ur-hermes-mini") "SessionDescriptor no conserva modelo."

# Persistence
$RutaGuardada = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaTemporal -SessionDescriptor $Descriptor
Assert-HermesEnterpriseCondition (Test-Path $RutaGuardada) "SessionPersistence no guardó archivo."
$Cargada = Load-HermesEnterpriseSession -RutaRaizRepositorio $RutaTemporal -IdentificadorSesion "test-001"
Assert-HermesEnterpriseCondition ($Cargada.IdentificadorSesion -eq "test-001") "SessionLoader no cargó sesión."

# Telemetry
Write-HermesEnterpriseSessionEvent -SessionDescriptor $Descriptor -Operacion "TestOperation" -Mensaje "Evento de prueba" | Out-Null
$Telemetry = Get-HermesEnterpriseSessionTelemetrySummary -SessionDescriptor $Descriptor
Assert-HermesEnterpriseCondition ($Telemetry.TotalEventos -gt 0) "SessionTelemetry no registró evento."

# Recovery
$RutaBackup = Backup-HermesEnterpriseSession -RutaRaizRepositorio $RutaTemporal -SessionDescriptor $Descriptor
Assert-HermesEnterpriseCondition (Test-Path $RutaBackup) "SessionRecovery no creó respaldo."
$Recuperada = Restore-HermesEnterpriseLatestSessionBackup -RutaRaizRepositorio $RutaTemporal
Assert-HermesEnterpriseCondition ($Recuperada.IdentificadorSesion -eq "test-001") "SessionRecovery no recuperó sesión."

# Wizard tool detection
$Herramientas = Get-HermesEnterpriseInstalledTools
Assert-HermesEnterpriseCondition ($Herramientas.PowerShell -eq $true) "SessionWizard no detectó PowerShell."

# SessionManager: create/open/close
$Sesion = New-HermesEnterpriseSession -NombreProyecto "SessionManagerProject" -RutaBase $RutaTemporal
Assert-HermesEnterpriseCondition ($Sesion.NombreProyecto -eq "SessionManagerProject") "SessionManager no creó sesión."
Assert-HermesEnterpriseCondition (Test-HermesEnterpriseSessionExists -RutaRaizRepositorio $RutaTemporal) "SessionManager no persistió sesión."

$SesionAbierta = Open-HermesEnterpriseSession -RutaRaizRepositorio $RutaTemporal
Assert-HermesEnterpriseCondition ($SesionAbierta.EstadoSesion -eq "Active") "SessionManager no abrió sesión."

$SesionCerrada = Close-HermesEnterpriseSession -RutaRaizRepositorio $RutaTemporal -SessionDescriptor $SesionAbierta
Assert-HermesEnterpriseCondition ($SesionCerrada.EstadoSesion -eq "Closed") "SessionManager no cerró sesión."

$SesionCambiada = Set-HermesEnterpriseSessionProject -RutaRaizRepositorio $RutaTemporal -SessionDescriptor (Open-HermesEnterpriseSession -RutaRaizRepositorio $RutaTemporal) -NombreProyecto "OtroProyecto" -RutaBase $RutaTemporal
Assert-HermesEnterpriseCondition ($SesionCambiada.NombreProyecto -eq "OtroProyecto") "SessionManager no cambió proyecto."

$Resumen = Get-HermesEnterpriseSessionSummary -SessionDescriptor $SesionCambiada
Assert-HermesEnterpriseCondition ($Resumen.IdentificadorSesion -eq $SesionCambiada.IdentificadorSesion) "SessionSummary no coincide."

Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "Test-SessionFramework completado correctamente." -ForegroundColor Green
