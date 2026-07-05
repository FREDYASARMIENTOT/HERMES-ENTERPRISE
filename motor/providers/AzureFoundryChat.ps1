<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureFoundryChat.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Envía conversaciones a un deployment de Azure AI Foundry, devuelve la respuesta en un
    objeto uniforme y registra telemetría de latencia, tokens y costo estimado.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioAzureFoundryChat = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioAzureFoundryChat "..\security\CredentialResolver.ps1")
. (Join-Path $RutaDirectorioAzureFoundryChat "AzureFoundryRest.ps1")
. (Join-Path $RutaDirectorioAzureFoundryChat "AzureFoundryTelemetry.ps1")

$SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault = "2024-10-21"

function Invoke-AzureFoundryChatCompletion {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContextoProvider,
        [Parameter(Mandatory = $false)][string]$Mensaje = "Hola",
        [Parameter(Mandatory = $false)][string]$Deployment = "",
        [Parameter(Mandatory = $false)][string]$ApiVersion = $SCRIPT:HermesEnterpriseAzureFoundryApiVersionDefault
    )

    if ([string]::IsNullOrWhiteSpace($Deployment)) {
        $Deployment = $ContextoProvider.UltimaConfiguracion.DeploymentDefault
    }

    $CorrelationId = New-HermesEnterpriseAzureFoundryCorrelationId
    $HoraInicio = Get-Date
    $EstadoTelemetry = "OK"
    $ErrorMensaje = ""

    try {
        $ModoSimulado = Test-HermesEnterpriseAzureFoundrySimulationMode
        if ($ModoSimulado) {
            return [pscustomobject][ordered]@{
                Deployment = $Deployment
                MensajeEntrada = $Mensaje
                Respuesta = $Mensaje
                Modelo = "simulado"
                TokensEntrada = 0
                TokensSalida = 0
                CostoEstimadoUSD = 0.0
                LatenciaMs = 0
                CorrelationId = $CorrelationId
                Modo = "Simulado"
            }
        }

        $Credencial = Get-HermesEnterpriseAzureFoundryCredential
        $Ruta = "/openai/deployments/$Deployment/chat/completions"
        $Uri = Build-HermesEnterpriseAzureFoundryRequestUri -Endpoint $Credencial.Endpoint -Ruta $Ruta -ApiVersion $ApiVersion

        $Cuerpo = @{
            messages = @(
                @{ role = "user"; content = $Mensaje }
            )
            max_completion_tokens = 50
        }

        $Resultado = Invoke-HermesEnterpriseAzureFoundryRestMethod -Uri $Uri -Credencial $Credencial -Metodo "POST" -Cuerpo $Cuerpo -CorrelationId $CorrelationId

        if (-not $Resultado.Success) {
            $EstadoTelemetry = "Error"
            $ErrorMensaje = $Resultado.Error
            throw "Error en chat completion: $($Resultado.Error)"
        }

        $Respuesta = $Resultado.Data
        $TokensEntrada = $Respuesta.usage.prompt_tokens
        $TokensSalida = $Respuesta.usage.completion_tokens
        $Modelo = $Respuesta.model
        $CostoEstimado = Get-HermesEnterpriseAzureFoundryEstimatedCost -Modelo $Modelo -TokensEntrada $TokensEntrada -TokensSalida $TokensSalida

        $RespuestaUniforme = [pscustomobject][ordered]@{
            Deployment = $Deployment
            MensajeEntrada = $Mensaje
            Respuesta = $Respuesta.choices[0].message.content
            Modelo = $Modelo
            TokensEntrada = $TokensEntrada
            TokensSalida = $TokensSalida
            CostoEstimadoUSD = $CostoEstimado
            LatenciaMs = $Resultado.LatenciaMs
            CorrelationId = $CorrelationId
            Modo = "Real"
        }

        Write-HermesEnterpriseAzureFoundryTelemetry `
            -LoggerKernel $ContextoProvider.Logger `
            -CorrelationId $CorrelationId `
            -NombreOperacion "ChatCompletion" `
            -HoraInicio $HoraInicio `
            -HoraFin (Get-Date) `
            -Deployment $Deployment `
            -TokensEntrada $TokensEntrada `
            -TokensSalida $TokensSalida `
            -Modelo $Modelo `
            -Estado $EstadoTelemetry | Out-Null

        return $RespuestaUniforme
    }
    catch {
        $EstadoTelemetry = "Error"
        $ErrorMensaje = $_.Exception.Message
        throw
    }
    finally {
        if ($EstadoTelemetry -eq "Error") {
            Write-HermesEnterpriseAzureFoundryTelemetry `
                -LoggerKernel $ContextoProvider.Logger `
                -CorrelationId $CorrelationId `
                -NombreOperacion "ChatCompletion" `
                -HoraInicio $HoraInicio `
                -HoraFin (Get-Date) `
                -Deployment $Deployment `
                -Estado $EstadoTelemetry `
                -ErrorMensaje $ErrorMensaje | Out-Null
        }
    }
}
