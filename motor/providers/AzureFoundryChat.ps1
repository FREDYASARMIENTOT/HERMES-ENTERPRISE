<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : AzureFoundryChat.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Envía conversaciones a un deployment de Azure AI Foundry y devuelve la respuesta en un
    objeto uniforme. Soporta modo simulado para pruebas sin credenciales.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioAzureFoundryChat = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioAzureFoundryChat "..\security\CredentialResolver.ps1")
. (Join-Path $RutaDirectorioAzureFoundryChat "AzureFoundryRest.ps1")

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

    $ModoSimulado = Test-HermesEnterpriseAzureFoundrySimulationMode
    if ($ModoSimulado) {
        return [pscustomobject][ordered]@{
            Deployment = $Deployment
            MensajeEntrada = $Mensaje
            Respuesta = $Mensaje
            Modelo = "simulado"
            TokensEntrada = 0
            TokensSalida = 0
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

    $Respuesta = Invoke-HermesEnterpriseAzureFoundryRestMethod -Uri $Uri -Credencial $Credencial -Metodo "POST" -Cuerpo $Cuerpo

    return [pscustomobject][ordered]@{
        Deployment = $Deployment
        MensajeEntrada = $Mensaje
        Respuesta = $Respuesta.choices[0].message.content
        Modelo = $Respuesta.model
        TokensEntrada = $Respuesta.usage.prompt_tokens
        TokensSalida = $Respuesta.usage.completion_tokens
        Modo = "Real"
    }
}
