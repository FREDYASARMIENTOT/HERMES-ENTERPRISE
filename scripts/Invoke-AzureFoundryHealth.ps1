<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Invoke-AzureFoundryHealth.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Comando público de la Fase 4.2 para verificar el health de Azure AI Foundry.
    Realiza GET /openai/models (o equivalente). Responde:
      200 -> Healthy
      401 -> Invalid Key
      404 -> Deployment inexistente

Uso:
    .\scripts\Invoke-AzureFoundryHealth.ps1

Alias: Invoke-Health
====================================================================================================
#>
[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScript = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScript

. (Join-Path $RutaRaizRepositorio "motor\providers\AzureFoundryProvider.ps1")

$ContextoProvider = New-HermesEnterpriseAzureFoundryProvider
Connect-AzureFoundryProvider -ContextoProvider $ContextoProvider | Out-Null

$Health = Invoke-AzureFoundryHealth -ContextoProvider $ContextoProvider

$Color = switch ($Health.Estado) {
    "Healthy" { "Green" }
    "InvalidKey" { "Red" }
    "DeploymentNotFound" { "Yellow" }
    default { "Magenta" }
}

Write-Host $Health.Mensaje -ForegroundColor $Color

return $Health
