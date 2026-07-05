<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureFoundryDeployment.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Descubrimiento y descripción de deployments de Azure AI Foundry. Incluye fallback a
    Azure Management API cuando el endpoint de datos no está disponible.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioAzureFoundryDeployment = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioAzureFoundryDeployment "..\security\CredentialResolver.ps1")
. (Join-Path $RutaDirectorioAzureFoundryDeployment "AzureFoundryRest.ps1")

$SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault = "2024-10-21"

function Get-HermesEnterpriseAzureFoundryDeploymentsFromManagementApi {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param()

    try {
        $Respuesta = az rest `
            --method get `
            --url "https://management.azure.com/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/resourceGroups/RG-Datamining-IA-UR/providers/Microsoft.CognitiveServices/accounts/Modelo-IA-UR/deployments?api-version=2023-05-01" `
            --query 'value[]' -o json 2>$null | ConvertFrom-Json

        $DeploymentsMapeados = New-Object System.Collections.Generic.List[object]
        foreach ($Item in $Respuesta) {
            $DeploymentsMapeados.Add([pscustomobject][ordered]@{
                Nombre = $Item.name
                Modelo = if ($Item.properties.model.name) { $Item.properties.model.name } else { $Item.properties.model }
                Capacidades = @("Chat")
                MaxTokens = 0
                Estado = if ($Item.properties.provisioningState -eq "Succeeded") { "Healthy" } else { $Item.properties.provisioningState }
            }) | Out-Null
        }
        return $DeploymentsMapeados.ToArray()
    }
    catch {
        return @()
    }
}

function Get-AzureFoundryDeploymentList {
    [CmdletBinding()]
    [OutputType([pscustomobject[]])]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContextoProvider,
        [Parameter(Mandatory = $false)][psobject[]]$DeploymentsSimulados = @(),
        [Parameter(Mandatory = $false)][string]$ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault
    )

    $ModoSimulado = Test-HermesEnterpriseAzureFoundrySimulationMode
    if ($ModoSimulado) {
        return $DeploymentsSimulados
    }

    $Credencial = Get-HermesEnterpriseAzureFoundryCredential
    if (-not $Credencial.TieneCredenciales) {
        return Get-HermesEnterpriseAzureFoundryDeploymentsFromManagementApi
    }

    $Uri = Build-HermesEnterpriseAzureFoundryRequestUri -Endpoint $Credencial.Endpoint -Ruta "/openai/models" -ApiVersion $ApiVersion

    try {
        $Respuesta = Invoke-HermesEnterpriseAzureFoundryRestMethod -Uri $Uri -Credencial $Credencial -Metodo "GET"
        $DeploymentsMapeados = New-Object System.Collections.Generic.List[object]

        foreach ($Modelo in $Respuesta.data) {
            $DeploymentsMapeados.Add([pscustomobject][ordered]@{
                Nombre = $Modelo.id
                Modelo = $Modelo.id
                Capacidades = @("Chat")
                MaxTokens = if ($Modelo.PSObject.Properties.Match("max_tokens")) { $Modelo.max_tokens } else { 0 }
                Estado = "Healthy"
            }) | Out-Null
        }

        return $DeploymentsMapeados.ToArray()
    }
    catch {
        $DeploymentsDesdeManagementApi = Get-HermesEnterpriseAzureFoundryDeploymentsFromManagementApi
        if ($DeploymentsDesdeManagementApi.Count -gt 0) {
            return $DeploymentsDesdeManagementApi
        }
        throw "No se pudieron obtener deployments desde el endpoint de datos ni desde Azure Management API. Error: $($_.Exception.Message)"
    }
}

function Get-AzureFoundryDeploymentInfo {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContextoProvider,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreDeployment,
        [Parameter(Mandatory = $false)][psobject[]]$DeploymentsSimulados = @(),
        [Parameter(Mandatory = $false)][string]$ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault
    )

    $Deployments = Get-AzureFoundryDeploymentList -ContextoProvider $ContextoProvider -DeploymentsSimulados $DeploymentsSimulados -ApiVersion $ApiVersion
    $Deployment = $Deployments | Where-Object { $_.Nombre -eq $NombreDeployment } | Select-Object -First 1

    if ($null -eq $Deployment) {
        return [pscustomobject][ordered]@{
            Encontrado = $false
            Nombre = $NombreDeployment
            Modelo = $null
            Capacidades = @()
            MaxTokens = 0
            Endpoint = $null
            Estado = "DeploymentNotFound"
        }
    }

    $Endpoint = $null
    if (-not (Test-HermesEnterpriseAzureFoundrySimulationMode)) {
        $Credencial = Get-HermesEnterpriseAzureFoundryCredential
        $Endpoint = "$($Credencial.Endpoint.TrimEnd('/'))/openai/deployments/$NombreDeployment"
    }

    return [pscustomobject][ordered]@{
        Encontrado = $true
        Nombre = $Deployment.Nombre
        Modelo = $Deployment.Modelo
        Capacidades = $Deployment.Capacidades
        MaxTokens = $Deployment.MaxTokens
        Endpoint = $Endpoint
        Estado = $Deployment.Estado
    }
}
