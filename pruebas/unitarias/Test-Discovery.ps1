<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Discovery.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida el descubrimiento automático de plugins por manifiesto.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }
. (Join-Path $RutaRaizRepositorio "motor\manifest\ManifestLoader.ps1")
. (Join-Path $RutaRaizRepositorio "motor\discovery\PluginDiscovery.ps1")
$PluginsDescubiertos = Find-HermesEnterprisePlugins -RutaDirectorioPlugins (Join-Path $RutaRaizRepositorio "plugins")
Assert-HermesEnterpriseCondition (($PluginsDescubiertos | Where-Object { $_.Manifest.Nombre -eq "HelloPlugin" }).Count -eq 1) "Discovery no encontró HelloPlugin."
Write-Host "Test-Discovery completado correctamente." -ForegroundColor Green
