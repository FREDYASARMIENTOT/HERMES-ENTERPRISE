<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProviderCapabilityDescriptor.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida descriptores de capacidades de providers como metainformación local, sin IA,
    llamadas HTTP, SDKs, transporte externo ni providers reales.
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

. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderCapabilityDescriptor.ps1")

$DescriptorCapacidades = New-HermesEnterpriseProviderCapabilityDescriptor `
    -NombreProvider "CapabilityProvider" `
    -VersionProvider "0.1.0" `
    -CapacidadesSoportadas @("Chat", "Embeddings", "Vision") `
    -CapacidadesExperimentales @("Streaming") `
    -MetadatosCapacidades @{ Familia = "Mock" }

Assert-HermesEnterpriseCondition ($DescriptorCapacidades.NombreProvider -eq "CapabilityProvider") "El descriptor no conserva el nombre del provider."
Assert-HermesEnterpriseCondition ($DescriptorCapacidades.VersionProvider -eq "0.1.0") "El descriptor no conserva la versión del provider."
Assert-HermesEnterpriseCondition ($DescriptorCapacidades.CapacidadesSoportadas -contains "Chat") "El descriptor no registra Chat como capacidad soportada."
Assert-HermesEnterpriseCondition ($DescriptorCapacidades.CapacidadesExperimentales -contains "Streaming") "El descriptor no registra capacidad experimental."
Assert-HermesEnterpriseCondition (-not $DescriptorCapacidades.LimitesIncluidos.ImplementaIA) "El descriptor no debe declarar IA implementada."
Assert-HermesEnterpriseCondition (-not $DescriptorCapacidades.LimitesIncluidos.HTTP) "El descriptor no debe declarar HTTP implementado."
Assert-HermesEnterpriseCondition (-not $DescriptorCapacidades.LimitesIncluidos.ProviderReal) "El descriptor no debe declarar provider real."

Assert-HermesEnterpriseCondition (Test-HermesEnterpriseProviderCapability -DescriptorCapacidadesProvider $DescriptorCapacidades -NombreCapacidad "Chat") "No detectó capacidad soportada Chat."
Assert-HermesEnterpriseCondition (Test-HermesEnterpriseProviderCapability -DescriptorCapacidadesProvider $DescriptorCapacidades -NombreCapacidad "Streaming" -IncluirExperimentales) "No detectó capacidad experimental al solicitar incluir experimentales."
Assert-HermesEnterpriseCondition (-not (Test-HermesEnterpriseProviderCapability -DescriptorCapacidadesProvider $DescriptorCapacidades -NombreCapacidad "Streaming")) "Marcó capacidad experimental como estable."
Assert-HermesEnterpriseCondition (-not (Test-HermesEnterpriseProviderCapability -DescriptorCapacidadesProvider $DescriptorCapacidades -NombreCapacidad "ToolCalling")) "Marcó capacidad inexistente como soportada."

$ResumenCapacidades = Get-HermesEnterpriseProviderCapabilitySummary -DescriptorCapacidadesProvider $DescriptorCapacidades
Assert-HermesEnterpriseCondition ($ResumenCapacidades.TotalCapacidadesSoportadas -eq 3) "El resumen no consolidó capacidades soportadas."
Assert-HermesEnterpriseCondition ($ResumenCapacidades.TotalCapacidadesExperimentales -eq 1) "El resumen no consolidó capacidades experimentales."
Assert-HermesEnterpriseCondition ($ResumenCapacidades.CapacidadesSoportadas -contains "Embeddings") "El resumen no conserva capacidades soportadas."

$DescriptorInvalido = New-HermesEnterpriseProviderCapabilityDescriptor `
    -NombreProvider "InvalidCapabilityProvider" `
    -VersionProvider "0.1.0" `
    -CapacidadesSoportadas @("Chat", "HTTP", "ApiKey")

$ResultadoValidacion = Test-HermesEnterpriseProviderCapabilityDescriptor -DescriptorCapacidadesProvider $DescriptorInvalido
Assert-HermesEnterpriseCondition (-not $ResultadoValidacion.EsValido) "El validador aceptó capacidades técnicas o sensibles no permitidas."
Assert-HermesEnterpriseCondition ($ResultadoValidacion.Errores -contains "Capacidad reservada no permitida: HTTP") "El validador no bloqueó HTTP como capacidad reservada."
Assert-HermesEnterpriseCondition ($ResultadoValidacion.Errores -contains "Capacidad sensible no permitida: ApiKey") "El validador no bloqueó ApiKey como capacidad sensible."

Write-Host "Test-ProviderCapabilityDescriptor completado correctamente." -ForegroundColor Green
