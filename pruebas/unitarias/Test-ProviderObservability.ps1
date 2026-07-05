<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProviderObservability.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida observabilidad agregada del Provider Framework sin integrar proveedores reales,
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

function Initialize-ObservableProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Initialized"; return $ContextoProvider }
function Disconnect-ObservableProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Disconnected"; return $ContextoProvider }
function ValidateConfiguration-ObservableProvider { param([psobject]$ContextoProvider) return [pscustomobject]@{ EsValida = $true; Errores = @() } }

function Initialize-UnhealthyProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Initialized"; return $ContextoProvider }
function Disconnect-UnhealthyProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Disconnected"; return $ContextoProvider }
function ValidateConfiguration-UnhealthyProvider { param([psobject]$ContextoProvider) return [pscustomobject]@{ EsValida = $false; Errores = @("Config local invalida") } }

$AdministradorProviders = New-HermesEnterpriseProviderManager
$ProviderObservable = New-HermesEnterpriseProviderContext -NombreProvider "ObservableProvider" -VersionProvider "0.1.0" -CapacidadesProvider @("Lifecycle", "Health")
$ProviderNoSaludable = New-HermesEnterpriseProviderContext -NombreProvider "UnhealthyProvider" -VersionProvider "0.1.0" -CapacidadesProvider @("Lifecycle")

Register-HermesEnterpriseManagedProvider -AdministradorProviders $AdministradorProviders -ContextoProvider $ProviderObservable | Out-Null
Register-HermesEnterpriseManagedProvider -AdministradorProviders $AdministradorProviders -ContextoProvider $ProviderNoSaludable | Out-Null
Initialize-HermesEnterpriseProvider -AdministradorProviders $AdministradorProviders -NombreProvider "ObservableProvider" | Out-Null
try { Initialize-HermesEnterpriseProvider -AdministradorProviders $AdministradorProviders -NombreProvider "UnhealthyProvider" | Out-Null } catch { }

$ObservabilidadProviders = Get-HermesEnterpriseProviderObservability -AdministradorProviders $AdministradorProviders

Assert-HermesEnterpriseCondition ($ObservabilidadProviders.NombreComponente -eq "Enterprise Provider Framework") "La observabilidad no identifica el componente Provider Framework."
Assert-HermesEnterpriseCondition ($ObservabilidadProviders.TotalProvidersRegistrados -eq 2) "La observabilidad no consolidó providers registrados."
Assert-HermesEnterpriseCondition ($ObservabilidadProviders.TotalProvidersInicializados -eq 1) "La observabilidad no consolidó providers inicializados."
Assert-HermesEnterpriseCondition ($ObservabilidadProviders.TotalProvidersUnhealthy -eq 1) "La observabilidad no consolidó providers Unhealthy."
Assert-HermesEnterpriseCondition ($ObservabilidadProviders.TotalProvidersConfigurationInvalid -eq 1) "La observabilidad no consolidó providers con configuración inválida."
Assert-HermesEnterpriseCondition (-not $ObservabilidadProviders.LimitesIncluidos.ProvidersReales) "La observabilidad no debe declarar providers reales implementados."
Assert-HermesEnterpriseCondition (-not $ObservabilidadProviders.LimitesIncluidos.AzureFoundry) "La observabilidad no debe declarar Azure Foundry implementado."
Assert-HermesEnterpriseCondition (-not $ObservabilidadProviders.LimitesIncluidos.HTTP) "La observabilidad no debe declarar HTTP implementado."
Assert-HermesEnterpriseCondition ($ObservabilidadProviders.Providers.Count -eq 2) "La observabilidad no incluye detalle por provider."
Assert-HermesEnterpriseCondition (($ObservabilidadProviders.Providers | Where-Object { $_.NombreProvider -eq "ObservableProvider" }).HealthEstado -eq "Healthy") "El detalle no conserva Health Healthy."
Assert-HermesEnterpriseCondition (($ObservabilidadProviders.Providers | Where-Object { $_.NombreProvider -eq "UnhealthyProvider" }).Estado -eq "ConfigurationInvalid") "El detalle no conserva estado ConfigurationInvalid."

Write-Host "Test-ProviderObservability completado correctamente." -ForegroundColor Green
