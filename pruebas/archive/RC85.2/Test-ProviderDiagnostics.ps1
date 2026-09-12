<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProviderDiagnostics.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida diagnósticos locales de configuración, capacidades y health de providers sin HTTP,
    SDKs, IA, credenciales reales ni providers externos.
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

. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderConfigurationManager.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderCapabilityDescriptor.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderDiagnostics.ps1")

$AdministradorConfiguracionProviders = New-HermesEnterpriseProviderConfigurationManager
$EsquemaConfiguracion = [pscustomobject][ordered]@{
    NombreProvider = "DiagnosticProvider"
    VersionEsquema = "0.1.0"
    ClavesRequeridas = @("Modelo", "Region")
    ClavesPermitidas = @("Modelo", "Region", "TimeoutSegundos")
    ValoresPorDefecto = @{ TimeoutSegundos = 30 }
}
Register-HermesEnterpriseProviderConfigurationSchema -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders -EsquemaConfiguracionProvider $EsquemaConfiguracion | Out-Null

$DescriptorCapacidades = New-HermesEnterpriseProviderCapabilityDescriptor `
    -NombreProvider "DiagnosticProvider" `
    -VersionProvider "0.1.0" `
    -CapacidadesSoportadas @("Chat", "Embeddings") `
    -CapacidadesExperimentales @("Vision")

$HealthProvider = [pscustomobject][ordered]@{
    Estado = "Healthy"
    UltimaVerificacion = "2026-01-01T00:00:00.0000000Z"
    Mensaje = "Provider localmente saludable."
}

$DiagnosticoValido = Invoke-HermesEnterpriseProviderDiagnostics `
    -NombreProvider "DiagnosticProvider" `
    -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders `
    -ConfiguracionProvider @{ Modelo = "mock-model"; Region = "local" } `
    -DescriptorCapacidadesProvider $DescriptorCapacidades `
    -CapacidadesRequeridas @("Chat") `
    -HealthProvider $HealthProvider

Assert-HermesEnterpriseCondition ($DiagnosticoValido.NombreComponente -eq "Provider Diagnostics") "El diagnóstico no identifica el componente."
Assert-HermesEnterpriseCondition ($DiagnosticoValido.NombreProvider -eq "DiagnosticProvider") "El diagnóstico no conserva el nombre del provider."
Assert-HermesEnterpriseCondition $DiagnosticoValido.EsListoLocalmente "El diagnóstico válido no quedó listo localmente."
Assert-HermesEnterpriseCondition $DiagnosticoValido.Configuracion.EsValida "El diagnóstico válido marcó configuración inválida."
Assert-HermesEnterpriseCondition $DiagnosticoValido.Capacidades.EsValida "El diagnóstico válido marcó capacidades inválidas."
Assert-HermesEnterpriseCondition $DiagnosticoValido.Health.EsValido "El diagnóstico válido marcó health inválido."
Assert-HermesEnterpriseCondition (-not $DiagnosticoValido.LimitesIncluidos.HTTP) "El diagnóstico no debe declarar HTTP."
Assert-HermesEnterpriseCondition (-not $DiagnosticoValido.LimitesIncluidos.SDKExterno) "El diagnóstico no debe declarar SDK externo."
Assert-HermesEnterpriseCondition (-not $DiagnosticoValido.LimitesIncluidos.ProviderReal) "El diagnóstico no debe declarar provider real."

$DiagnosticoInvalido = Invoke-HermesEnterpriseProviderDiagnostics `
    -NombreProvider "DiagnosticProvider" `
    -AdministradorConfiguracionProviders $AdministradorConfiguracionProviders `
    -ConfiguracionProvider @{ Modelo = "mock-model"; ApiKey = "NO-DEBE-USARSE" } `
    -DescriptorCapacidadesProvider $DescriptorCapacidades `
    -CapacidadesRequeridas @("Streaming") `
    -HealthProvider ([pscustomobject]@{ Estado = "Unhealthy"; Mensaje = "Config local invalida" })

Assert-HermesEnterpriseCondition (-not $DiagnosticoInvalido.EsListoLocalmente) "El diagnóstico inválido quedó listo localmente."
Assert-HermesEnterpriseCondition (-not $DiagnosticoInvalido.Configuracion.EsValida) "El diagnóstico inválido no detectó configuración inválida."
Assert-HermesEnterpriseCondition ($DiagnosticoInvalido.Configuracion.Errores -contains "Falta clave requerida: Region") "El diagnóstico no reportó parámetro requerido faltante."
Assert-HermesEnterpriseCondition ($DiagnosticoInvalido.Configuracion.Errores -contains "Clave sensible no permitida: ApiKey") "El diagnóstico no reportó clave sensible."
Assert-HermesEnterpriseCondition (-not $DiagnosticoInvalido.Capacidades.EsValida) "El diagnóstico no detectó capacidad faltante."
Assert-HermesEnterpriseCondition ($DiagnosticoInvalido.Capacidades.Errores -contains "Capacidad requerida no soportada: Streaming") "El diagnóstico no reportó capacidad faltante."
Assert-HermesEnterpriseCondition (-not $DiagnosticoInvalido.Health.EsValido) "El diagnóstico no detectó health Unhealthy."

Write-Host "Test-ProviderDiagnostics completado correctamente." -ForegroundColor Green
