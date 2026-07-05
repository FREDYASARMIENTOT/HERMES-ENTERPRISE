<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : CredentialResolver.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Decide el origen de credenciales para Azure AI Foundry: Environment, Azure AD o
    Azure Key Vault. Prueba la credencial contra el endpoint antes de devolverla.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioCredentialResolver = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioCredentialResolver "AzureAdResolver.ps1")
. (Join-Path $RutaDirectorioCredentialResolver "KeyVaultResolver.ps1")
. (Join-Path (Join-Path $RutaDirectorioCredentialResolver "..\providers") "AzureFoundryRest.ps1")

$SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault = "2024-10-21"

function Resolve-HermesEnterpriseAzureFoundryEndpoint {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $Endpoint = $env:AZURE_FOUNDRY_ENDPOINT
    if ([string]::IsNullOrWhiteSpace($Endpoint)) {
        $Endpoint = $env:AZURE_OPENAI_ENDPOINT
    }
    $Origen = "Environment"

    if ([string]::IsNullOrWhiteSpace($Endpoint)) {
        $Endpoint = Get-HermesEnterpriseKeyVaultSecret -NombreSecreto "AzureOpenAI-Endpoint"
        $Origen = "AzureKeyVault"
    }

    return [pscustomobject][ordered]@{
        Endpoint = $Endpoint
        Origen = $Origen
    }
}

function Test-HermesEnterpriseAzureFoundryCredential {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Endpoint,
        [Parameter(Mandatory = $false)][string]$ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault
    )

    $Uri = Build-HermesEnterpriseAzureFoundryRequestUri -Endpoint $Endpoint -Ruta "/openai/models" -ApiVersion $ApiVersion

    # 1. Intentar Azure AD.
    $TokenAzureAD = Get-HermesEnterpriseAzureAdToken
    if ($TokenAzureAD.TieneCredenciales) {
        $CredencialAd = [pscustomobject][ordered]@{
            Endpoint = $Endpoint
            ApiKey = $TokenAzureAD.Token
            Tipo = $TokenAzureAD.Tipo
            Origen = "$($TokenAzureAD.Origen) + AzureKeyVault"
            TieneCredenciales = $true
            Error = $null
        }
        try {
            Invoke-HermesEnterpriseAzureFoundryRestMethod -Uri $Uri -Credencial $CredencialAd -Metodo "GET" | Out-Null
            return $CredencialAd
        }
        catch {
            # Azure AD no funciona para este recurso; continuar con API Key.
        }
    }

    # 2. Fallback a API Key: entorno primero, Key Vault como respaldo.
    $ApiKey = $env:AZURE_FOUNDRY_API_KEY
    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        $ApiKey = $env:AZURE_OPENAI_API_KEY
    }
    $OrigenApiKey = "Environment"
    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        $ApiKey = Get-HermesEnterpriseKeyVaultSecret -NombreSecreto "AzureOpenAI-ApiKey"
        $OrigenApiKey = "AzureKeyVault"
    }

    if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
        $CredencialKey = [pscustomobject][ordered]@{
            Endpoint = $Endpoint
            ApiKey = $ApiKey
            Tipo = "api-key"
            Origen = "$OrigenApiKey + AzureKeyVault"
            TieneCredenciales = $true
            Error = $null
        }
        try {
            Invoke-HermesEnterpriseAzureFoundryRestMethod -Uri $Uri -Credencial $CredencialKey -Metodo "GET" | Out-Null
            return $CredencialKey
        }
        catch {
            return [pscustomobject][ordered]@{
                Endpoint = $Endpoint
                ApiKey = $ApiKey
                Tipo = "api-key"
                Origen = "$OrigenApiKey + AzureKeyVault"
                TieneCredenciales = $false
                Error = $_.Exception.Message
            }
        }
    }

    return [pscustomobject][ordered]@{
        Endpoint = $Endpoint
        ApiKey = $null
        Tipo = $null
        Origen = "Ninguno"
        TieneCredenciales = $false
        Error = "No se pudo autenticar con Azure AD ni con API Key."
    }
}

function Get-HermesEnterpriseAzureFoundryCredential {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param()

    $EndpointResuelto = Resolve-HermesEnterpriseAzureFoundryEndpoint
    if ([string]::IsNullOrWhiteSpace($EndpointResuelto.Endpoint)) {
        return [pscustomobject][ordered]@{
            Endpoint = $null
            ApiKey = $null
            Tipo = $null
            Origen = "Ninguno"
            TieneCredenciales = $false
            Error = "No se pudo resolver el endpoint desde variables de entorno ni Azure Key Vault."
        }
    }

    return Test-HermesEnterpriseAzureFoundryCredential -Endpoint $EndpointResuelto.Endpoint
}

function Test-HermesEnterpriseAzureFoundrySimulationMode {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $Credencial = Get-HermesEnterpriseAzureFoundryCredential
    return -not $Credencial.TieneCredenciales
}
