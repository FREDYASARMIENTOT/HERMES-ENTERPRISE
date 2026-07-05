<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProviderAdapter.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida ProviderAdapter base como contrato genérico y state machine declarativa, sin Azure,
    HTTP, SDKs, IA, credenciales reales ni providers externos.
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

. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderAdapter.ps1")

$Adapter = New-HermesEnterpriseProviderAdapter -NombreProvider "AdapterProvider" -VersionProvider "0.1.0" -Autor "HERMES-ENTERPRISE"

Assert-HermesEnterpriseCondition ($Adapter.NombreProvider -eq "AdapterProvider") "El adapter no conserva el nombre del provider."
Assert-HermesEnterpriseCondition ($Adapter.VersionProvider -eq "0.1.0") "El adapter no conserva la versión del provider."
Assert-HermesEnterpriseCondition ($Adapter.EstadoActual -eq "Created") "El adapter no inicia en estado Created."
Assert-HermesEnterpriseCondition ($Adapter.OperacionesRequeridas -contains "Initialize") "El contrato no incluye Initialize."
Assert-HermesEnterpriseCondition ($Adapter.OperacionesRequeridas -contains "ValidateConfiguration") "El contrato no incluye ValidateConfiguration."
Assert-HermesEnterpriseCondition ($Adapter.OperacionesRequeridas -contains "Connect") "El contrato no incluye Connect."
Assert-HermesEnterpriseCondition ($Adapter.OperacionesRequeridas -contains "Disconnect") "El contrato no incluye Disconnect."
Assert-HermesEnterpriseCondition ($Adapter.OperacionesRequeridas -contains "Health") "El contrato no incluye Health."
Assert-HermesEnterpriseCondition ($Adapter.OperacionesRequeridas -contains "DescribeCapabilities") "El contrato no incluye DescribeCapabilities."
Assert-HermesEnterpriseCondition (-not $Adapter.LimitesIncluidos.AzureFoundry) "El adapter base no debe declarar Azure Foundry."
Assert-HermesEnterpriseCondition (-not $Adapter.LimitesIncluidos.HTTP) "El adapter base no debe declarar HTTP."
Assert-HermesEnterpriseCondition (-not $Adapter.LimitesIncluidos.SDKExterno) "El adapter base no debe declarar SDK externo."
Assert-HermesEnterpriseCondition (-not $Adapter.LimitesIncluidos.ProviderReal) "El adapter base no debe declarar provider real."

$StateMachine = Get-HermesEnterpriseProviderAdapterStateMachine
$EstadosEsperados = @("Created", "Configured", "Validated", "Initialized", "Ready", "Healthy", "Degraded", "Faulted", "Disposed")
foreach ($EstadoEsperado in $EstadosEsperados) {
    Assert-HermesEnterpriseCondition ($StateMachine.EstadosPermitidos -contains $EstadoEsperado) "El state machine no incluye estado $EstadoEsperado."
}

Assert-HermesEnterpriseCondition (Test-HermesEnterpriseProviderAdapterStateTransition -EstadoOrigen "Created" -EstadoDestino "Configured") "No permite transición Created -> Configured."
Assert-HermesEnterpriseCondition (Test-HermesEnterpriseProviderAdapterStateTransition -EstadoOrigen "Ready" -EstadoDestino "Healthy") "No permite transición Ready -> Healthy."
Assert-HermesEnterpriseCondition (Test-HermesEnterpriseProviderAdapterStateTransition -EstadoOrigen "Healthy" -EstadoDestino "Degraded") "No permite transición Healthy -> Degraded."
Assert-HermesEnterpriseCondition (-not (Test-HermesEnterpriseProviderAdapterStateTransition -EstadoOrigen "Created" -EstadoDestino "Ready")) "Permitió transición inválida Created -> Ready."

Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $Adapter -NuevoEstado "Configured" | Out-Null
Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $Adapter -NuevoEstado "Validated" | Out-Null
Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $Adapter -NuevoEstado "Initialized" | Out-Null
Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $Adapter -NuevoEstado "Ready" | Out-Null
Assert-HermesEnterpriseCondition ($Adapter.EstadoActual -eq "Ready") "El adapter no avanzó hasta Ready."
Assert-HermesEnterpriseCondition ($Adapter.HistorialEstados.Count -eq 5) "El historial no registró las transiciones esperadas."

$ResultadoContrato = Test-HermesEnterpriseProviderAdapterContract -ProviderAdapter $Adapter
Assert-HermesEnterpriseCondition $ResultadoContrato.EsValido "El adapter base no cumple su contrato declarativo."
Assert-HermesEnterpriseCondition ($ResultadoContrato.Errores.Count -eq 0) "El contrato declarativo devolvió errores inesperados."

$FalloTransicion = $false
try {
    Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $Adapter -NuevoEstado "Created" | Out-Null
}
catch {
    $FalloTransicion = $true
}
Assert-HermesEnterpriseCondition $FalloTransicion "El adapter permitió regresar de Ready a Created."

Write-Host "Test-ProviderAdapter completado correctamente." -ForegroundColor Green
