<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Get-AzureFoundryDeployments.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Comando público de la Fase 4.1 para listar los deployments disponibles en Azure AI Foundry.
    En modo simulado devuelve ur-hermes-mini, ur-hermes-coder y ur-ep-gpt-5.5.

Uso:
    .\scripts\Get-AzureFoundryDeployments.ps1
    .\scripts\Get-AzureFoundryDeployments.ps1 -Verbose

Alias: List-Deployments
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

$Deployments = Get-AzureFoundryDeployments -ContextoProvider $ContextoProvider

foreach ($Deployment in $Deployments) {
    Write-Host $Deployment.Nombre
}

return $Deployments
