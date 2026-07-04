<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Manifest.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida la carga de manifiestos plugin.json del Enterprise Plugin Framework.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }
. (Join-Path $RutaRaizRepositorio "motor\manifest\ManifestLoader.ps1")
$RutaManifestHelloPlugin = Join-Path $RutaRaizRepositorio "plugins\HelloPlugin\plugin.json"
$ManifestPlugin = Get-HermesEnterprisePluginManifest -RutaArchivoManifest $RutaManifestHelloPlugin
Assert-HermesEnterpriseCondition ($ManifestPlugin.Nombre -eq "HelloPlugin") "El manifiesto no cargó el nombre esperado."
Assert-HermesEnterpriseCondition ($ManifestPlugin.Version -eq "0.4.0") "El manifiesto no cargó la versión esperada."
Assert-HermesEnterpriseCondition ($ManifestPlugin.KernelMinimo -eq "0.4.0") "El manifiesto no declara KernelMinimo esperado."
Write-Host "Test-Manifest completado correctamente." -ForegroundColor Green
