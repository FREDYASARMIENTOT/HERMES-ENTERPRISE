<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureFoundryRest.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Cliente REST mínimo para Azure AI Foundry. Construye URIs, serializa JSON y ejecuta
    llamadas GET/POST autenticadas. No resuelve credenciales ni interpreta negocio.
====================================================================================================
#>
Set-StrictMode -Version Latest

$SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault = "2024-10-21"

function Build-HermesEnterpriseAzureFoundryRequestUri {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Endpoint,
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Ruta,
        [Parameter(Mandatory = $false)][string]$ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault
    )

    $EndpointNormalizado = $Endpoint.TrimEnd('/')
    $Separador = if ($Ruta.Contains('?')) { '&' } else { '?' }
    return "$EndpointNormalizado$Ruta${Separador}api-version=$ApiVersion"
}

function Invoke-HermesEnterpriseAzureFoundryRestMethod {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Uri,
        [Parameter(Mandatory = $true)][psobject]$Credencial,
        [Parameter(Mandatory = $false)][ValidateSet("GET", "POST")][string]$Metodo = "GET",
        [Parameter(Mandatory = $false)][hashtable]$Cuerpo = @{}
    )

    $Headers = @{
        "Content-Type" = "application/json"
    }

    if ($Credencial.Tipo -eq "Bearer") {
        $Headers["Authorization"] = "Bearer $($Credencial.ApiKey)"
    }
    else {
        $Headers["api-key"] = $Credencial.ApiKey
    }

    $ParametrosInvoke = @{
        Uri = $Uri
        Method = $Metodo
        Headers = $Headers
        UseBasicParsing = $true
        ErrorAction = "Stop"
    }

    if ($Metodo -eq "POST" -and $Cuerpo.Count -gt 0) {
        $ParametrosInvoke["Body"] = ($Cuerpo | ConvertTo-Json -Depth 10 -Compress)
    }

    return Invoke-RestMethod @ParametrosInvoke
}
