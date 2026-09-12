<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProviderManagerValidation.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida la compuerta de configuración y health local del Provider Manager sin proveedores reales,
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

function Initialize-ValidConfigProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Initialized"; return $ContextoProvider }
function Disconnect-ValidConfigProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Disconnected"; return $ContextoProvider }
function ValidateConfiguration-ValidConfigProvider { param([psobject]$ContextoProvider) return [pscustomobject]@{ EsValida = $true; Errores = @() } }

function Initialize-InvalidConfigProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Initialized"; return $ContextoProvider }
function Disconnect-InvalidConfigProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Disconnected"; return $ContextoProvider }
function ValidateConfiguration-InvalidConfigProvider { param([psobject]$ContextoProvider) return [pscustomobject]@{ EsValida = $false; Errores = @("Configuracion simulada invalida") } }

$AdministradorProviders = New-HermesEnterpriseProviderManager
$ContextoValido = New-HermesEnterpriseProviderContext -NombreProvider "ValidConfigProvider" -VersionProvider "0.1.0" -ConfiguracionProvider @{ Modo = "Local" }
$ContextoInvalido = New-HermesEnterpriseProviderContext -NombreProvider "InvalidConfigProvider" -VersionProvider "0.1.0" -ConfiguracionProvider @{ Modo = "Local" }

Register-HermesEnterpriseManagedProvider -AdministradorProviders $AdministradorProviders -ContextoProvider $ContextoValido | Out-Null
Register-HermesEnterpriseManagedProvider -AdministradorProviders $AdministradorProviders -ContextoProvider $ContextoInvalido | Out-Null

$ResultadoValidacion = Test-HermesEnterpriseManagedProviderConfiguration -AdministradorProviders $AdministradorProviders -NombreProvider "ValidConfigProvider"
Assert-HermesEnterpriseCondition $ResultadoValidacion.EsValida "El manager rechazó una configuración local válida."
Assert-HermesEnterpriseCondition ($ContextoValido.Health.Estado -eq "Healthy") "El health no quedó Healthy después de validar configuración."

Initialize-HermesEnterpriseProvider -AdministradorProviders $AdministradorProviders -NombreProvider "ValidConfigProvider" | Out-Null
Assert-HermesEnterpriseCondition ((Get-HermesEnterpriseProviderHealth -AdministradorProviders $AdministradorProviders -NombreProvider "ValidConfigProvider").Estado -eq "Healthy") "El health no se conserva Healthy después de inicializar."

$FalloConfiguracion = $false
try {
    Initialize-HermesEnterpriseProvider -AdministradorProviders $AdministradorProviders -NombreProvider "InvalidConfigProvider" | Out-Null
}
catch {
    $FalloConfiguracion = $true
}

Assert-HermesEnterpriseCondition $FalloConfiguracion "El manager inicializó un provider con configuración inválida."
Assert-HermesEnterpriseCondition ($ContextoInvalido.Estado -eq "ConfigurationInvalid") "El provider inválido no quedó en estado ConfigurationInvalid."
Assert-HermesEnterpriseCondition ($ContextoInvalido.Health.Estado -eq "Unhealthy") "El health del provider inválido no quedó Unhealthy."
Assert-HermesEnterpriseCondition (-not $AdministradorProviders.ProvidersInicializados.ContainsKey("InvalidConfigProvider")) "El provider inválido fue agregado a ProvidersInicializados."

Write-Host "Test-ProviderManagerValidation completado correctamente." -ForegroundColor Green
