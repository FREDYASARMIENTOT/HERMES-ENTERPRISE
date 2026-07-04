<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Lifecycle.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida el ciclo de vida Install, Initialize, Start, Stop y Dispose de plugins.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }
. (Join-Path $RutaRaizRepositorio "motor\manifest\ManifestLoader.ps1")
. (Join-Path $RutaRaizRepositorio "motor\lifecycle\LifecycleManager.ps1")
$PluginDescubierto = [pscustomobject]@{
    RutaDirectorioPlugin = Join-Path $RutaRaizRepositorio "plugins\HelloPlugin"
    RutaScriptPlugin = Join-Path $RutaRaizRepositorio "plugins\HelloPlugin\HelloPlugin.ps1"
    Manifest = Get-HermesEnterprisePluginManifest -RutaArchivoManifest (Join-Path $RutaRaizRepositorio "plugins\HelloPlugin\plugin.json")
}
$EstadoCicloVida = Invoke-HermesEnterprisePluginLifecycle -PluginDescubierto $PluginDescubierto
Assert-HermesEnterpriseCondition ($EstadoCicloVida.EstadoActual -eq "Disposed") "El ciclo de vida no finalizó en estado Disposed."
Assert-HermesEnterpriseCondition ($EstadoCicloVida.EstadosEjecutados.Count -eq 5) "El ciclo de vida no ejecutó las cinco etapas esperadas."
Write-Host "Test-Lifecycle completado correctamente." -ForegroundColor Green
