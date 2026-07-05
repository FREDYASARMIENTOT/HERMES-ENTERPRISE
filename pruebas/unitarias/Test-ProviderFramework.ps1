<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProviderFramework.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida la infraestructura base del Provider Framework sin integrar proveedores reales,
    credenciales, HTTP, IA, streaming ni llamadas externas.
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

. (Join-Path $RutaRaizRepositorio "motor\contracts\ProviderContracts.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderContext.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderRegistry.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderManager.ps1")

function Initialize-MockProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Initialized"; return $ContextoProvider }
function Connect-MockProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Connected"; return $ContextoProvider }
function Disconnect-MockProvider { param([psobject]$ContextoProvider) $ContextoProvider.Estado = "Disconnected"; return $ContextoProvider }
function ValidateConfiguration-MockProvider { param([psobject]$ContextoProvider) return [pscustomobject]@{ EsValida = $true; Errores = @() } }
function GetProviderInformation-MockProvider { return [pscustomobject]@{ NombreProvider = "MockProvider"; Version = "0.1.0" } }

$ResultadoContrato = Test-HermesEnterpriseProviderContract -NombreProvider "MockProvider"
Assert-HermesEnterpriseCondition $ResultadoContrato.EsValido "MockProvider no cumple el contrato IProvider esperado."
Assert-HermesEnterpriseCondition ($ResultadoContrato.Contrato -eq "IProvider") "El contrato evaluado no corresponde a IProvider."

$ContextoProvider = New-HermesEnterpriseProviderContext `
    -NombreProvider "MockProvider" `
    -VersionProvider "0.1.0" `
    -ConfiguracionProvider @{ Entorno = "Pruebas" } `
    -CapacidadesProvider @("Lifecycle", "Registry") `
    -MetadatosProvider @{ Tipo = "Mock" }

Assert-HermesEnterpriseCondition ($ContextoProvider.NombreProvider -eq "MockProvider") "El contexto no conserva el nombre del provider."
Assert-HermesEnterpriseCondition ($ContextoProvider.VersionProvider -eq "0.1.0") "El contexto no conserva la version del provider."
Assert-HermesEnterpriseCondition ($ContextoProvider.Estado -eq "Created") "El contexto no inicia en estado Created."
Assert-HermesEnterpriseCondition ($ContextoProvider.Health.Estado -eq "Unknown") "El contexto no inicializa Health en estado Unknown."
Assert-HermesEnterpriseCondition (-not $ContextoProvider.ConfiguracionProvider.ContainsKey("ApiKey")) "El contexto no debe contener credenciales reales."

$RegistroProviders = New-HermesEnterpriseProviderRegistry
Register-HermesEnterpriseProvider -ProveedorRegistry $RegistroProviders -NombreProveedor "MockProvider" -Proveedor $ContextoProvider | Out-Null
Assert-HermesEnterpriseCondition ((Get-HermesEnterpriseRegisteredProviders -ProveedorRegistry $RegistroProviders).Count -eq 1) "El registro no listó el provider registrado."
Assert-HermesEnterpriseCondition ((Get-HermesEnterpriseProvider -ProveedorRegistry $RegistroProviders -NombreProveedor "MockProvider").NombreProvider -eq "MockProvider") "El registro no consultó el provider esperado."
Unregister-HermesEnterpriseProvider -ProveedorRegistry $RegistroProviders -NombreProveedor "MockProvider" | Out-Null
Assert-HermesEnterpriseCondition (-not (Test-HermesEnterpriseProviderRegistered -ProveedorRegistry $RegistroProviders -NombreProveedor "MockProvider")) "El registro no eliminó el provider esperado."

$AdministradorProviders = New-HermesEnterpriseProviderManager
Register-HermesEnterpriseManagedProvider -AdministradorProviders $AdministradorProviders -ContextoProvider $ContextoProvider | Out-Null
Initialize-HermesEnterpriseProvider -AdministradorProviders $AdministradorProviders -NombreProvider "MockProvider" | Out-Null
Assert-HermesEnterpriseCondition ((Get-HermesEnterpriseProviderState -AdministradorProviders $AdministradorProviders -NombreProvider "MockProvider") -eq "Initialized") "El manager no inicializó el provider."
Stop-HermesEnterpriseProvider -AdministradorProviders $AdministradorProviders -NombreProvider "MockProvider" | Out-Null
Assert-HermesEnterpriseCondition ((Get-HermesEnterpriseProviderState -AdministradorProviders $AdministradorProviders -NombreProvider "MockProvider") -eq "Disconnected") "El manager no apagó el provider."

Write-Host "Test-ProviderFramework completado correctamente." -ForegroundColor Green
