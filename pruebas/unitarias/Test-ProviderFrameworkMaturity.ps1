<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProviderFrameworkMaturity.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida el reporte de madurez del Provider Framework sin integrar proveedores reales,
    credenciales, HTTP, IA ni transporte externo.
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

. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderContext.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderManager.ps1")

function Initialize-MatureProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Initialized"; return $ContextoProvider }
function Disconnect-MatureProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Disconnected"; return $ContextoProvider }
function ValidateConfiguration-MatureProvider { param([psobject]$ContextoProvider) return [pscustomobject]@{ EsValida = $true; Errores = @() } }

$AdministradorProviders = New-HermesEnterpriseProviderManager
$ProviderMaduro = New-HermesEnterpriseProviderContext -NombreProvider "MatureProvider" -VersionProvider "0.1.0" -CapacidadesProvider @("Lifecycle", "ConfigurationValidation", "Health", "Observability")
Register-HermesEnterpriseManagedProvider -AdministradorProviders $AdministradorProviders -ContextoProvider $ProviderMaduro | Out-Null
Initialize-HermesEnterpriseProvider -AdministradorProviders $AdministradorProviders -NombreProvider "MatureProvider" | Out-Null

$ReporteMadurez = Get-HermesEnterpriseProviderFrameworkMaturityReport -AdministradorProviders $AdministradorProviders -VersionFramework "0.3.3"

Assert-HermesEnterpriseCondition ($ReporteMadurez.NombreComponente -eq "Enterprise Provider Framework") "El reporte no identifica el componente Provider Framework."
Assert-HermesEnterpriseCondition ($ReporteMadurez.EstadoMadurez -eq "InfraestructuraBaseCertificada") "El reporte no declaró la infraestructura base certificada."
Assert-HermesEnterpriseCondition ($ReporteMadurez.VersionFramework -eq "0.3.3") "El reporte no conserva la versión evaluada del framework."
Assert-HermesEnterpriseCondition ($ReporteMadurez.TotalProvidersRegistrados -eq 1) "El reporte no consolidó providers registrados."
Assert-HermesEnterpriseCondition ($ReporteMadurez.TotalProvidersInicializados -eq 1) "El reporte no consolidó providers inicializados."
Assert-HermesEnterpriseCondition ($ReporteMadurez.TotalProvidersUnhealthy -eq 0) "El reporte marcó providers Unhealthy inexistentes."
Assert-HermesEnterpriseCondition ($ReporteMadurez.TotalProvidersConfigurationInvalid -eq 0) "El reporte marcó configuración inválida inexistente."

Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.ProviderContract "El reporte no certifica contrato base IProvider."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.ProviderContext "El reporte no certifica ProviderContext."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.ProviderRegistry "El reporte no certifica ProviderRegistry."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.ProviderManager "El reporte no certifica ProviderManager."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.ConfigurationValidation "El reporte no certifica validación local de configuración."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.Health "El reporte no certifica Health."
Assert-HermesEnterpriseCondition $ReporteMadurez.Capacidades.Observability "El reporte no certifica Observability."

Assert-HermesEnterpriseCondition (-not $ReporteMadurez.LimitesIncluidos.ProvidersReales) "El reporte no debe declarar providers reales implementados."
Assert-HermesEnterpriseCondition (-not $ReporteMadurez.LimitesIncluidos.AzureFoundry) "El reporte no debe declarar Azure Foundry implementado."
Assert-HermesEnterpriseCondition (-not $ReporteMadurez.LimitesIncluidos.HTTP) "El reporte no debe declarar HTTP implementado."
Assert-HermesEnterpriseCondition (-not $ReporteMadurez.LimitesIncluidos.IA) "El reporte no debe declarar IA implementada."
Assert-HermesEnterpriseCondition (-not $ReporteMadurez.LimitesIncluidos.CredencialesReales) "El reporte no debe declarar credenciales reales."

Assert-HermesEnterpriseCondition ($ReporteMadurez.PruebasRecomendadas -contains "pruebas/unitarias/Test-ProviderFramework.ps1") "El reporte no incluye Test-ProviderFramework como prueba recomendada."
Assert-HermesEnterpriseCondition ($ReporteMadurez.PruebasRecomendadas -contains "pruebas/unitarias/Test-ProviderObservability.ps1") "El reporte no incluye Test-ProviderObservability como prueba recomendada."
Assert-HermesEnterpriseCondition ($ReporteMadurez.ProximaFaseRecomendada -eq "AdapterScaffoldingSinProvidersReales") "El reporte no recomienda la siguiente fase correcta."

Write-Host "Test-ProviderFrameworkMaturity completado correctamente." -ForegroundColor Green
