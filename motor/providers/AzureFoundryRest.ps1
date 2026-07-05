<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureFoundryRest.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Cliente REST mínimo para Azure AI Foundry. Construye URIs, serializa JSON, ejecuta
    llamadas GET/POST autenticadas, mide latencia y devuelve respuestas unificadas con
    manejo centralizado de errores HTTP.
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
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Uri,
        [Parameter(Mandatory = $true)][psobject]$Credencial,
        [Parameter(Mandatory = $false)][ValidateSet("GET", "POST")][string]$Metodo = "GET",
        [Parameter(Mandatory = $false)][hashtable]$Cuerpo = @{},
        [Parameter(Mandatory = $false)][string]$CorrelationId = ""
    )

    if ([string]::IsNullOrWhiteSpace($CorrelationId)) {
        $CorrelationId = [guid]::NewGuid().ToString()
    }

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

    $HoraInicio = Get-Date
    try {
        $Respuesta = Invoke-RestMethod @ParametrosInvoke
        $LatenciaMs = [Math]::Max(0, [int]((Get-Date) - $HoraInicio).TotalMilliseconds)

        return [pscustomobject][ordered]@{
            Success = $true
            StatusCode = 200
            Data = $Respuesta
            LatenciaMs = $LatenciaMs
            Error = $null
            CorrelationId = $CorrelationId
        }
    }
    catch {
        $LatenciaMs = [Math]::Max(0, [int]((Get-Date) - $HoraInicio).TotalMilliseconds)
        $CodigoEstado = 0
        $MensajeError = $_.Exception.Message

        if ($_.Exception.Response) {
            $CodigoEstado = [int]$_.Exception.Response.StatusCode
        }
        elseif ($_.Exception -match "\((\d{3})\)") {
            $CodigoEstado = [int]$Matches[1]
        }

        return [pscustomobject][ordered]@{
            Success = $false
            StatusCode = $CodigoEstado
            Data = $null
            LatenciaMs = $LatenciaMs
            Error = $MensajeError
            CorrelationId = $CorrelationId
        }
    }
}
