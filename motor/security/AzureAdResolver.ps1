<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureAdResolver.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Resuelve token de autenticación de Azure Active Directory para Azure Cognitive Services.
    No almacena tokens en disco; únicamente en memoria de sesión.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Get-HermesEnterpriseAzureAdToken {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)][string]$Recurso = "https://cognitiveservices.azure.com"
    )

    try {
        $Token = az account get-access-token --resource $Recurso --query accessToken -o tsv 2>$null
        if (-not [string]::IsNullOrWhiteSpace($Token)) {
            return [pscustomobject][ordered]@{
                Token = $Token
                Tipo = "Bearer"
                Origen = "AzureAD"
                TieneCredenciales = $true
                Error = $null
            }
        }
    }
    catch {
        return [pscustomobject][ordered]@{
            Token = $null
            Tipo = $null
            Origen = "AzureAD"
            TieneCredenciales = $false
            Error = $_.Exception.Message
        }
    }

    return [pscustomobject][ordered]@{
        Token = $null
        Tipo = $null
        Origen = "AzureAD"
        TieneCredenciales = $false
        Error = "Token de Azure AD vacío."
    }
}

function Build-HermesEnterpriseAzureAdAuthorizationHeader {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Token
    )

    return @{ "Authorization" = "Bearer $Token" }
}
