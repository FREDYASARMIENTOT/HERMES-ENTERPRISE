<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Invoke-AzureFoundryChat.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Comando público de la Fase 4.3 para enviar el primer chat completion a Azure AI Foundry.
    Por defecto envía "Hola" al deployment ur-hermes-mini.

Uso:
    .\scripts\Invoke-AzureFoundryChat.ps1
    .\scripts\Invoke-AzureFoundryChat.ps1 -Mensaje "Hola" -Deployment ur-hermes-mini

Alias: Invoke-Chat
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string]$Mensaje = "Hola",
    [Parameter(Mandatory = $false)][string]$Deployment = "ur-hermes-mini"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScript = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScript

. (Join-Path $RutaRaizRepositorio "motor\providers\AzureFoundryProvider.ps1")

$ContextoProvider = New-HermesEnterpriseAzureFoundryProvider
Connect-AzureFoundryProvider -ContextoProvider $ContextoProvider | Out-Null

$Resultado = Invoke-AzureFoundryChat -ContextoProvider $ContextoProvider -Mensaje $Mensaje -Deployment $Deployment

Write-Host $Resultado.Respuesta

return $Resultado
