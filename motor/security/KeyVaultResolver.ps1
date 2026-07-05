<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : KeyVaultResolver.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Lee secretos desde Azure Key Vault mediante Azure CLI. No escribe ni persiste secretos.
====================================================================================================
#>
Set-StrictMode -Version Latest

$SCRIPT:HermesEnterpriseKeyVaultName = "kv-hermes-enterprise-ur"

function Get-HermesEnterpriseKeyVaultSecret {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$NombreSecreto,
        [Parameter(Mandatory = $false)][string]$NombreKeyVault = $SCRIPT:HermesEnterpriseKeyVaultName
    )

    try {
        return az keyvault secret show --vault-name $NombreKeyVault --name $NombreSecreto --query value -o tsv 2>$null
    }
    catch {
        return $null
    }
}

function Get-HermesEnterpriseKeyVaultOpenAiCredential {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $Endpoint = Get-HermesEnterpriseKeyVaultSecret -NombreSecreto "AzureOpenAI-Endpoint"
    $Deployment = Get-HermesEnterpriseKeyVaultSecret -NombreSecreto "AzureOpenAI-Deployment"
    $ApiKey = Get-HermesEnterpriseKeyVaultSecret -NombreSecreto "AzureOpenAI-ApiKey"

    return [pscustomobject][ordered]@{
        Endpoint = $Endpoint
        Deployment = $Deployment
        ApiKey = $ApiKey
        Tipo = "api-key"
        Origen = "AzureKeyVault"
        TieneCredenciales = (-not [string]::IsNullOrWhiteSpace($Endpoint)) -and (-not [string]::IsNullOrWhiteSpace($ApiKey))
        Error = if ((-not [string]::IsNullOrWhiteSpace($Endpoint)) -and (-not [string]::IsNullOrWhiteSpace($ApiKey))) { $null } else { "No se pudieron recuperar todos los secretos requeridos de Key Vault." }
    }
}
