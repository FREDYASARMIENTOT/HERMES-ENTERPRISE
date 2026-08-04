<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-AzureFoundryProvider.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida AzureFoundryProvider en modo simulado (sin credenciales reales) para garantizar que
    el primer provider real cumple el contrato del Provider Framework y ejecuta los comandos
    de la Fase 4.1, 4.2 y 4.3 sin salir de red.
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

# Forzar modo simulado guardando credenciales previas.
$EndpointOriginal = $env:AZURE_FOUNDRY_ENDPOINT
$ApiKeyOriginal = $env:AZURE_FOUNDRY_API_KEY
$env:AZURE_FOUNDRY_ENDPOINT = ""
$env:AZURE_FOUNDRY_API_KEY = ""

. (Join-Path $RutaRaizRepositorio "motor\providers\AzureFoundryProvider.ps1")

# Determinar si hay acceso real a Azure (Azure AD o Key Vault).
$HayAccesoAzure = $false
try { $token = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv 2>$null; $HayAccesoAzure = -not [string]::IsNullOrWhiteSpace($token) } catch { Write-Debug "No Azure access token available" }
if (-not $HayAccesoAzure) {
    try { $secret = az keyvault secret show --vault-name kv-hermes-enterprise-ur --name AzureOpenAI-Endpoint --query value -o tsv 2>$null; $HayAccesoAzure = -not [string]::IsNullOrWhiteSpace($secret) } catch { Write-Debug "No Key Vault access available" }
}

try {
    # Fase 4.1: creación y configuración.
    $Provider = New-HermesEnterpriseAzureFoundryProvider
    Assert-HermesEnterpriseCondition ($Provider.Adapter.EstadoActual -eq "Created") "AzureFoundryProvider no inicia en Created."
    Assert-HermesEnterpriseCondition ($Provider.ConfigurationManager.EsquemasConfiguracionProvider.Count -eq 1) "AzureFoundryProvider no registró esquema de configuración."
    Assert-HermesEnterpriseCondition ($Provider.Adapter.LimitesIncluidos.AzureFoundry -eq $true) "AzureFoundryProvider no declara AzureFoundry."
    Assert-HermesEnterpriseCondition ($Provider.Adapter.LimitesIncluidos.HTTP -eq $true) "AzureFoundryProvider no declara HTTP."
    Assert-HermesEnterpriseCondition ($Provider.Adapter.LimitesIncluidos.IA -eq $true) "AzureFoundryProvider no declara IA."

    $ConfiguracionValida = @{
        Endpoint = "https://simulated.azure-foundry.local"
        ApiVersion = "2024-10-21"
        DeploymentDefault = "ur-hermes-mini"
    }

    $Provider.ConfiguracionProvider = $ConfiguracionValida
    $ResultadoConfiguracion = ValidateConfiguration-AzureFoundryProvider -ContextoProvider $Provider
    Assert-HermesEnterpriseCondition $ResultadoConfiguracion.EsValida "AzureFoundryProvider rechazó configuración válida."
    Assert-HermesEnterpriseCondition ($Provider.Adapter.EstadoActual -eq "Validated") "AzureFoundryProvider no llegó a Validated tras validar configuración."

    Initialize-AzureFoundryProvider -ContextoProvider $Provider | Out-Null
    Assert-HermesEnterpriseCondition ($Provider.Adapter.EstadoActual -eq "Initialized") "AzureFoundryProvider no llegó a Initialized."

    Connect-AzureFoundryProvider -ContextoProvider $Provider | Out-Null

    if ($HayAccesoAzure) {
        Assert-HermesEnterpriseCondition ($Provider.Adapter.EstadoActual -in @("Ready", "Healthy")) "AzureFoundryProvider no llegó a Ready/Healthy con Azure real."

        $Health = Get-AzureFoundryProviderHealth -ContextoProvider $Provider
        Assert-HermesEnterpriseCondition ($Health.Estado -eq "Healthy") "AzureFoundryProvider no reportó Healthy con Azure real."

        $Deployments = Get-AzureFoundryDeployments -ContextoProvider $Provider
        Assert-HermesEnterpriseCondition ($Deployments.Count -gt 0) "No se detectaron deployments reales."
        Assert-HermesEnterpriseCondition (($Deployments | Select-Object -ExpandProperty Nombre) -contains "ur-hermes-mini") "Falta ur-hermes-mini en deployments reales."

        $Summary = Get-AzureFoundryProviderSummary -ContextoProvider $Provider
        Assert-HermesEnterpriseCondition $Summary.DescriptorValido "Summary no confirma descriptor válido."
        Assert-HermesEnterpriseCondition ($Summary.LimitesIncluidos.CredencialesReales -eq $true) "Summary debe declarar credenciales reales cuando hay acceso a Azure."
    }
    else {
        Assert-HermesEnterpriseCondition ($Provider.Adapter.EstadoActual -eq "Ready") "AzureFoundryProvider no llegó a Ready tras conectar en modo simulado."

        $Health = Get-AzureFoundryProviderHealth -ContextoProvider $Provider
        Assert-HermesEnterpriseCondition ($Health.Estado -eq "Healthy") "AzureFoundryProvider no reportó Healthy en modo simulado."

        $Deployments = Get-AzureFoundryDeployments -ContextoProvider $Provider
        Assert-HermesEnterpriseCondition ($Deployments.Count -eq 3) "AzureFoundryProvider no devolvió 3 deployments simulados."
        Assert-HermesEnterpriseCondition (($Deployments | Select-Object -ExpandProperty Nombre) -contains "ur-hermes-mini") "Falta ur-hermes-mini simulado."
        Assert-HermesEnterpriseCondition (($Deployments | Select-Object -ExpandProperty Nombre) -contains "ur-hermes-coder") "Falta ur-hermes-coder simulado."
        Assert-HermesEnterpriseCondition (($Deployments | Select-Object -ExpandProperty Nombre) -contains "ur-ep-gpt-5.5") "Falta ur-ep-gpt-5.5 simulado."

        $Summary = Get-AzureFoundryProviderSummary -ContextoProvider $Provider
        Assert-HermesEnterpriseCondition $Summary.DescriptorValido "Summary no confirma descriptor válido."
        Assert-HermesEnterpriseCondition ($Summary.LimitesIncluidos.CredencialesReales -eq $false) "Summary no debe declarar credenciales reales en modo simulado."
    }

    Disconnect-AzureFoundryProvider -ContextoProvider $Provider | Out-Null
    Assert-HermesEnterpriseCondition ($Provider.Adapter.EstadoActual -eq "Disposed") "AzureFoundryProvider no finalizó en Disposed."

    Write-Host "Test-AzureFoundryProvider completado correctamente." -ForegroundColor Green
}
finally {
    $env:AZURE_FOUNDRY_ENDPOINT = $EndpointOriginal
    $env:AZURE_FOUNDRY_API_KEY = $ApiKeyOriginal
}
