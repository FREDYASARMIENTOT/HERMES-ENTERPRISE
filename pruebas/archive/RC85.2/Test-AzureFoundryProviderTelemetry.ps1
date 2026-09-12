<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-AzureFoundryProviderTelemetry.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida la telemetría del Azure Foundry Provider: CorrelationId, latencia, tokens,
    costo estimado, manejo de errores y sanitización de secretos en logs.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition {
    param([bool]$CondicionEvaluada, [string]$MensajeError)
    if (-not $CondicionEvaluada) { throw $MensajeError }
}

. (Join-Path $RutaRaizRepositorio "motor\logging\Logger.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\AzureFoundryTelemetry.ps1")
. (Join-Path $RutaRaizRepositorio "motor\providers\AzureFoundryProvider.ps1")

# Prueba 1: sanitización de secretos.
$DatosSucios = @{
    ApiKey = "fake-api-key-for-test-only-12345"
    Token = "fake-token-for-test-only"
    Authorization = "Bearer fake-auth-for-test-only"
    Password = "fake-password-test"
    Deployment = "ur-hermes-mini"
    LatenciaMs = 150
}
$DatosLimpios = Protect-HermesEnterpriseAzureFoundryTelemetryData -Datos $DatosSucios

Assert-HermesEnterpriseCondition ($DatosLimpios.ApiKey -eq "***REDACTED***") "ApiKey no fue sanitizada."
Assert-HermesEnterpriseCondition ($DatosLimpios.Token -eq "***REDACTED***") "Token no fue sanitizado."
Assert-HermesEnterpriseCondition ($DatosLimpios.Authorization -eq "***REDACTED***") "Authorization no fue sanitizado."
Assert-HermesEnterpriseCondition ($DatosLimpios.Password -eq "***REDACTED***") "Password no fue sanitizado."
Assert-HermesEnterpriseCondition ($DatosLimpios.Deployment -eq "ur-hermes-mini") "Deployment fue sanitizado indebidamente."

# Prueba 2: costo estimado.
$Costo = Get-HermesEnterpriseAzureFoundryEstimatedCost -Modelo "gpt-5-mini-2025-08-07" -TokensEntrada 1000 -TokensSalida 500
Assert-HermesEnterpriseCondition ($Costo -gt 0) "Costo estimado no es positivo."

# Prueba 3: telemetría real si hay acceso a Azure.
$HayAccesoAzure = $false
try { $token = az account get-access-token --resource https://cognitiveservices.azure.com --query accessToken -o tsv 2>$null; $HayAccesoAzure = -not [string]::IsNullOrWhiteSpace($token) } catch { Write-Debug "Azure AD token unavailable for telemetry" }
if (-not $HayAccesoAzure) {
    try { $secret = az keyvault secret show --vault-name kv-hermes-enterprise-ur --name AzureOpenAI-Endpoint --query value -o tsv 2>$null; $HayAccesoAzure = -not [string]::IsNullOrWhiteSpace($secret) } catch { Write-Debug "Key Vault access unavailable for telemetry" }
}

if ($HayAccesoAzure) {
    $RutaLogReal = Join-Path ([System.IO.Path]::GetTempPath()) "hermes-telemetry-real-$(Get-Random).log"
    $LoggerReal = New-HermesEnterpriseLogger -RutaArchivoLog $RutaLogReal -NombreComponente "AzureFoundryProviderTest"

    $EndpointOriginal = $env:AZURE_FOUNDRY_ENDPOINT
    $ApiKeyOriginal = $env:AZURE_FOUNDRY_API_KEY
    $env:AZURE_FOUNDRY_ENDPOINT = ""
    $env:AZURE_FOUNDRY_API_KEY = ""

    try {
        $ProviderReal = New-HermesEnterpriseAzureFoundryProvider -LoggerKernel $LoggerReal
        Connect-AzureFoundryProvider -ContextoProvider $ProviderReal | Out-Null

        $ChatReal = Invoke-AzureFoundryChat -ContextoProvider $ProviderReal -Mensaje "Hola" -Deployment "ur-hermes-mini"
        Assert-HermesEnterpriseCondition (-not [string]::IsNullOrWhiteSpace($ChatReal.CorrelationId)) "Chat real no incluye CorrelationId."
        Assert-HermesEnterpriseCondition ($ChatReal.LatenciaMs -gt 0) "Chat real no registra latencia positiva."
        Assert-HermesEnterpriseCondition ($ChatReal.TokensEntrada -ge 0) "Chat real no registra TokensEntrada."
        Assert-HermesEnterpriseCondition ($ChatReal.TokensSalida -gt 0) "Chat real no registra TokensSalida."
        Assert-HermesEnterpriseCondition ($null -ne $ChatReal.PSObject.Properties["CostoEstimadoUSD"]) "Chat real no registra CostoEstimadoUSD."
        Assert-HermesEnterpriseCondition ($ChatReal.Deployment -eq "ur-hermes-mini") "Chat real no conserva deployment."

        $LineasLogReal = Get-Content -Path $RutaLogReal
        $Eventos = $LineasLogReal | ConvertFrom-Json
        $EventoChat = $Eventos | Where-Object { $_.Datos.NombreOperacion -eq "ChatCompletion" } | Select-Object -First 1
        Assert-HermesEnterpriseCondition ($null -ne $EventoChat) "No se encontró evento de ChatCompletion en log."
        Assert-HermesEnterpriseCondition ($EventoChat.Datos.LatenciaMilisegundos -gt 0) "Telemetría no registra latencia."
        Assert-HermesEnterpriseCondition ($EventoChat.Datos.TokensEntrada -ge 0) "Telemetría no registra tokens de entrada."
        Assert-HermesEnterpriseCondition ($EventoChat.Datos.TokensSalida -gt 0) "Telemetría no registra tokens de salida."
        Assert-HermesEnterpriseCondition ($EventoChat.Datos.CostoEstimadoUSD -ge 0) "Telemetría no registra costo estimado."
        Assert-HermesEnterpriseCondition ($EventoChat.Datos.Deployment -eq "ur-hermes-mini") "Telemetría no registra deployment."

        foreach ($Linea in $LineasLogReal) {
            Assert-HermesEnterpriseCondition (-not ($Linea -match '"(?i)(apikey|api_key|authorization|token|secret|password|credential)"\s*:\s*"[^"]{8,}"')) "Log real contiene posible secreto sin redactar."
        }
    }
    finally {
        $env:AZURE_FOUNDRY_ENDPOINT = $EndpointOriginal
        $env:AZURE_FOUNDRY_API_KEY = $ApiKeyOriginal
        Remove-Item -Path $RutaLogReal -Force -ErrorAction SilentlyContinue
    }
}

Write-Host "Test-AzureFoundryProviderTelemetry completado correctamente." -ForegroundColor Green
