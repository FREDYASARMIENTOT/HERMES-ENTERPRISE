<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureFoundryHealth.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Health check de Azure AI Foundry. Interpreta códigos HTTP y permite fallback a
    Azure Management API cuando el endpoint de datos requiere RBAC adicional.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioAzureFoundryHealth = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioAzureFoundryHealth "..\security\CredentialResolver.ps1")
. (Join-Path $RutaDirectorioAzureFoundryHealth "AzureFoundryRest.ps1")
. (Join-Path $RutaDirectorioAzureFoundryHealth "AzureFoundryDeployment.ps1")

$SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault = "2024-10-21"

function Resolve-HermesEnterpriseAzureFoundryHealthFromStatusCode {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][int]$CodigoEstadoHttp,
        [Parameter(Mandatory = $false)][string]$MensajeAdicional = ""
    )

    switch ($CodigoEstadoHttp) {
        200 {
            return [pscustomobject][ordered]@{
                Estado = "Healthy"
                Mensaje = "Provider Healthy."
                CodigoEstadoHttp = $CodigoEstadoHttp
            }
        }
        401 {
            return [pscustomobject][ordered]@{
                Estado = "InvalidKey"
                Mensaje = "Invalid Key."
                CodigoEstadoHttp = $CodigoEstadoHttp
            }
        }
        404 {
            return [pscustomobject][ordered]@{
                Estado = "DeploymentNotFound"
                Mensaje = "Deployment inexistente."
                CodigoEstadoHttp = $CodigoEstadoHttp
            }
        }
        default {
            return [pscustomobject][ordered]@{
                Estado = "Degraded"
                Mensaje = "Respuesta inesperada del endpoint. $MensajeAdicional"
                CodigoEstadoHttp = $CodigoEstadoHttp
            }
        }
    }
}

function Invoke-AzureFoundryHealthCheck {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContextoProvider,
        [Parameter(Mandatory = $false)][string]$ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault
    )

    $ModoSimulado = Test-HermesEnterpriseAzureFoundrySimulationMode
    if ($ModoSimulado) {
        $ContextoProvider.Health = [pscustomobject][ordered]@{
            Estado = "Healthy"
            Mensaje = "Provider Healthy (modo simulado)."
            UltimaVerificacion = (Get-Date).ToString("o")
        }
        return $ContextoProvider.Health
    }

    $Credencial = Get-HermesEnterpriseAzureFoundryCredential
    $Uri = Build-HermesEnterpriseAzureFoundryRequestUri -Endpoint $Credencial.Endpoint -Ruta "/openai/models" -ApiVersion $ApiVersion

    try {
        Invoke-HermesEnterpriseAzureFoundryRestMethod -Uri $Uri -Credencial $Credencial -Metodo "GET" | Out-Null
        $ContextoProvider.Health = [pscustomobject][ordered]@{
            Estado = "Healthy"
            Mensaje = "Provider Healthy."
            UltimaVerificacion = (Get-Date).ToString("o")
            CodigoEstadoHttp = 200
        }
    }
    catch {
        $CodigoEstado = 0
        if ($_.Exception.Response) {
            $CodigoEstado = [int]$_.Exception.Response.StatusCode
        }
        elseif ($_.Exception -match "\((\d{3})\)") {
            $CodigoEstado = [int]$Matches[1]
        }

        if ($CodigoEstado -in @(401, 403)) {
            $DeploymentsDesdeManagementApi = Get-HermesEnterpriseAzureFoundryDeploymentsFromManagementApi
            if ($DeploymentsDesdeManagementApi.Count -gt 0) {
                $ContextoProvider.Health = [pscustomobject][ordered]@{
                    Estado = "Healthy"
                    Mensaje = "Provider Healthy (autenticación vía Azure Management API; endpoint de datos requiere RBAC adicional)."
                    UltimaVerificacion = (Get-Date).ToString("o")
                    CodigoEstadoHttp = $CodigoEstado
                }
            }
            else {
                $Health = Resolve-HermesEnterpriseAzureFoundryHealthFromStatusCode -CodigoEstadoHttp $CodigoEstado -MensajeAdicional $_.Exception.Message
                $ContextoProvider.Health = [pscustomobject][ordered]@{
                    Estado = $Health.Estado
                    Mensaje = $Health.Mensaje
                    UltimaVerificacion = (Get-Date).ToString("o")
                    CodigoEstadoHttp = $Health.CodigoEstadoHttp
                }
            }
        }
        else {
            $Health = Resolve-HermesEnterpriseAzureFoundryHealthFromStatusCode -CodigoEstadoHttp $CodigoEstado -MensajeAdicional $_.Exception.Message
            $ContextoProvider.Health = [pscustomobject][ordered]@{
                Estado = $Health.Estado
                Mensaje = $Health.Mensaje
                UltimaVerificacion = (Get-Date).ToString("o")
                CodigoEstadoHttp = $Health.CodigoEstadoHttp
            }
        }
    }

    if ($ContextoProvider.Adapter.EstadoActual -eq "Ready" -and $ContextoProvider.Health.Estado -ne "Healthy") {
        Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Degraded" | Out-Null
    }
    elseif ($ContextoProvider.Adapter.EstadoActual -eq "Ready" -and $ContextoProvider.Health.Estado -eq "Healthy") {
        Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Healthy" | Out-Null
    }

    return $ContextoProvider.Health
}
