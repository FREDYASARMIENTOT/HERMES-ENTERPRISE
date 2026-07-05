<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureFoundryHealth.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Health check de Azure AI Foundry. Interpreta códigos HTTP, permite fallback a
    Azure Management API y registra telemetría de latencia.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioAzureFoundryHealth = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioAzureFoundryHealth "..\security\CredentialResolver.ps1")
. (Join-Path $RutaDirectorioAzureFoundryHealth "AzureFoundryRest.ps1")
. (Join-Path $RutaDirectorioAzureFoundryHealth "AzureFoundryDeployment.ps1")
. (Join-Path $RutaDirectorioAzureFoundryHealth "AzureFoundryTelemetry.ps1")

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

    $CorrelationId = New-HermesEnterpriseAzureFoundryCorrelationId
    $HoraInicio = Get-Date
    $EstadoTelemetry = "OK"
    $ErrorMensaje = ""

    $ModoSimulado = Test-HermesEnterpriseAzureFoundrySimulationMode
    if ($ModoSimulado) {
        $ContextoProvider.Health = [pscustomobject][ordered]@{
            Estado = "Healthy"
            Mensaje = "Provider Healthy (modo simulado)."
            UltimaVerificacion = (Get-Date).ToString("o")
        }
        Write-HermesEnterpriseAzureFoundryTelemetry `
            -LoggerKernel $ContextoProvider.Logger `
            -CorrelationId $CorrelationId `
            -NombreOperacion "HealthCheck" `
            -HoraInicio $HoraInicio `
            -HoraFin (Get-Date) `
            -Estado $EstadoTelemetry | Out-Null
        return $ContextoProvider.Health
    }

    $Credencial = Get-HermesEnterpriseAzureFoundryCredential
    $Uri = Build-HermesEnterpriseAzureFoundryRequestUri -Endpoint $Credencial.Endpoint -Ruta "/openai/models" -ApiVersion $ApiVersion
    $Resultado = Invoke-HermesEnterpriseAzureFoundryRestMethod -Uri $Uri -Credencial $Credencial -Metodo "GET" -CorrelationId $CorrelationId

    if ($Resultado.Success) {
        $ContextoProvider.Health = [pscustomobject][ordered]@{
            Estado = "Healthy"
            Mensaje = "Provider Healthy."
            UltimaVerificacion = (Get-Date).ToString("o")
            CodigoEstadoHttp = $Resultado.StatusCode
            LatenciaMs = $Resultado.LatenciaMs
            CorrelationId = $CorrelationId
        }
    }
    else {
        $CodigoEstado = $Resultado.StatusCode
        $ErrorMensaje = $Resultado.Error

        if ($CodigoEstado -in @(401, 403)) {
            $DeploymentsDesdeManagementApi = Get-HermesEnterpriseAzureFoundryDeploymentsFromManagementApi
            if ($DeploymentsDesdeManagementApi.Count -gt 0) {
                $EstadoTelemetry = "Partial"
                $ContextoProvider.Health = [pscustomobject][ordered]@{
                    Estado = "Healthy"
                    Mensaje = "Provider Healthy (autenticación vía Azure Management API; endpoint de datos requiere RBAC adicional)."
                    UltimaVerificacion = (Get-Date).ToString("o")
                    CodigoEstadoHttp = $CodigoEstado
                    LatenciaMs = $Resultado.LatenciaMs
                    CorrelationId = $CorrelationId
                }
            }
            else {
                $EstadoTelemetry = "Error"
                $Health = Resolve-HermesEnterpriseAzureFoundryHealthFromStatusCode -CodigoEstadoHttp $CodigoEstado -MensajeAdicional $Resultado.Error
                $ContextoProvider.Health = [pscustomobject][ordered]@{
                    Estado = $Health.Estado
                    Mensaje = $Health.Mensaje
                    UltimaVerificacion = (Get-Date).ToString("o")
                    CodigoEstadoHttp = $Health.CodigoEstadoHttp
                    LatenciaMs = $Resultado.LatenciaMs
                    CorrelationId = $CorrelationId
                }
            }
        }
        else {
            $EstadoTelemetry = "Error"
            $Health = Resolve-HermesEnterpriseAzureFoundryHealthFromStatusCode -CodigoEstadoHttp $CodigoEstado -MensajeAdicional $Resultado.Error
            $ContextoProvider.Health = [pscustomobject][ordered]@{
                Estado = $Health.Estado
                Mensaje = $Health.Mensaje
                UltimaVerificacion = (Get-Date).ToString("o")
                CodigoEstadoHttp = $Health.CodigoEstadoHttp
                LatenciaMs = $Resultado.LatenciaMs
                CorrelationId = $CorrelationId
            }
        }
    }

    if ($ContextoProvider.Adapter.EstadoActual -eq "Ready" -and $ContextoProvider.Health.Estado -ne "Healthy") {
        Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Degraded" | Out-Null
    }
    elseif ($ContextoProvider.Adapter.EstadoActual -eq "Ready" -and $ContextoProvider.Health.Estado -eq "Healthy") {
        Move-HermesEnterpriseProviderAdapterState -ProviderAdapter $ContextoProvider.Adapter -NuevoEstado "Healthy" | Out-Null
    }

    Write-HermesEnterpriseAzureFoundryTelemetry `
        -LoggerKernel $ContextoProvider.Logger `
        -CorrelationId $CorrelationId `
        -NombreOperacion "HealthCheck" `
        -HoraInicio $HoraInicio `
        -HoraFin (Get-Date) `
        -Estado $EstadoTelemetry `
        -ErrorMensaje $ErrorMensaje | Out-Null

    return $ContextoProvider.Health
}
