<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Connect-AzureFoundryProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Comando público de la Fase 4.1 para conectar el Provider Framework con Azure AI Foundry.
    Valida configuración, inicializa el provider, ejecuta health check e imprime el estado.

Uso:
    .\scripts\Connect-AzureFoundryProvider.ps1
    .\scripts\Connect-AzureFoundryProvider.ps1 -Verbose

Requiere:
    Variables de entorno AZURE_FOUNDRY_ENDPOINT y AZURE_FOUNDRY_API_KEY para modo real.
    Si no están definidas, opera en modo simulado.
====================================================================================================
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScript = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScript

. (Join-Path $RutaRaizRepositorio "motor\providers\AzureFoundryProvider.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\ProviderManager.ps1")

$Configuracion = @{
    Endpoint = $env:AZURE_FOUNDRY_ENDPOINT
    ApiVersion = $env:AZURE_FOUNDRY_API_VERSION
    DeploymentDefault = "ur-hermes-mini"
}

if ([string]::IsNullOrWhiteSpace($Configuracion.Endpoint)) {
    $Configuracion.Endpoint = "https://simulated.azure-foundry.local"
}
if ([string]::IsNullOrWhiteSpace($Configuracion.ApiVersion)) {
    $Configuracion.ApiVersion = "2024-10-21"
}

$ContextoProvider = New-HermesEnterpriseProviderContext `
    -NombreProvider "AzureFoundryProvider" `
    -VersionProvider "0.4.0" `
    -ConfiguracionProvider $Configuracion `
    -CapacidadesProvider @("Chat", "Health", "Deployments") `
    -MetadatosProvider @{ Tipo = "AzureFoundry"; Region = "eastus" }

$ContextoProvider = New-HermesEnterpriseAzureFoundryProvider
$ContextoProvider.ConfiguracionProvider = $Configuracion

$AdministradorProviders = New-HermesEnterpriseProviderManager
Register-HermesEnterpriseManagedProvider -AdministradorProviders $AdministradorProviders -ContextoProvider $ContextoProvider | Out-Null

$ResultadoValidacion = Test-HermesEnterpriseManagedProviderConfiguration -AdministradorProviders $AdministradorProviders -NombreProvider "AzureFoundryProvider"
if (-not $ResultadoValidacion.EsValida) {
    throw "Configuración inválida: $($ResultadoValidacion.Errores -join '; ')"
}

Initialize-HermesEnterpriseProvider -AdministradorProviders $AdministradorProviders -NombreProvider "AzureFoundryProvider" | Out-Null
Connect-AzureFoundryProvider -ContextoProvider $ContextoProvider | Out-Null

$Health = Get-AzureFoundryProviderHealth -ContextoProvider $ContextoProvider
Write-Host "Provider $($Health.Estado)" -ForegroundColor $(if ($Health.Estado -eq "Healthy") { "Green" } else { "Red" })

if ($Health.Estado -eq "Healthy") {
    $DeploymentDefault = $ContextoProvider.UltimaConfiguracion.DeploymentDefault
    Write-Host "Deployment encontrado:" -ForegroundColor Cyan
    Write-Host $DeploymentDefault
}

return $ContextoProvider
