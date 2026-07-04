<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-PluginLoader.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida que el loader pueda cargar el script de HelloPlugin y exponer sus funciones.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }
. (Join-Path $RutaRaizRepositorio "motor\plugins\PluginLoader.ps1")
$RutaScriptHelloPlugin = Join-Path $RutaRaizRepositorio "plugins\HelloPlugin\HelloPlugin.ps1"
$ResultadoCarga = Import-HermesEnterprisePluginScript -RutaScriptPlugin $RutaScriptHelloPlugin
Assert-HermesEnterpriseCondition $ResultadoCarga.Cargado "El loader no cargó HelloPlugin."
Assert-HermesEnterpriseCondition ($null -ne (Get-Command Install-HelloPlugin -ErrorAction SilentlyContinue)) "HelloPlugin no expuso Install-HelloPlugin."
Write-Host "Test-PluginLoader completado correctamente." -ForegroundColor Green
