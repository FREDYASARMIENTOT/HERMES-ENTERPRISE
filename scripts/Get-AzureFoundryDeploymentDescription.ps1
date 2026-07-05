<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Get-AzureFoundryDeploymentDescription.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Comando público de la Fase 4.1 para describir un deployment de Azure AI Foundry.
    Imprime Nombre, Modelo, Capacidades, Max Tokens, Endpoint y Estado.

Uso:
    .\scripts\Get-AzureFoundryDeploymentDescription.ps1 -Deployment ur-hermes-mini

Alias: DescribeDeployment
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)][string]$Deployment = "ur-hermes-mini"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScript = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScript

. (Join-Path $RutaRaizRepositorio "motor\providers\AzureFoundryProvider.ps1")

$ContextoProvider = New-HermesEnterpriseAzureFoundryProvider
Connect-AzureFoundryProvider -ContextoProvider $ContextoProvider | Out-Null

$Descripcion = Get-AzureFoundryDeploymentDescription -ContextoProvider $ContextoProvider -NombreDeployment $Deployment

if (-not $Descripcion.Encontrado) {
    Write-Host "Deployment no encontrado: $Deployment" -ForegroundColor Red
    return $Descripcion
}

Write-Host "Nombre:        $($Descripcion.Nombre)"
Write-Host "Modelo:        $($Descripcion.Modelo)"
Write-Host "Capacidades:   $($Descripcion.Capacidades -join ', ')"
Write-Host "Max Tokens:    $($Descripcion.MaxTokens)"
Write-Host "Endpoint:      $($Descripcion.Endpoint)"
Write-Host "Estado:        $($Descripcion.Estado)"

return $Descripcion
