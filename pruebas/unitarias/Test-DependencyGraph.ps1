<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-DependencyGraph.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida resolución básica de dependencias entre plugins.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }
. (Join-Path $RutaRaizRepositorio "motor\dependencygraph\DependencyResolver.ps1")
$Plugins = @(
    [pscustomobject]@{ Manifest = [pscustomobject]@{ Nombre = "PluginBase"; Dependencias = @() } },
    [pscustomobject]@{ Manifest = [pscustomobject]@{ Nombre = "PluginDependiente"; Dependencias = @("PluginBase") } }
)
$OrdenCarga = Resolve-HermesEnterprisePluginLoadOrder -PluginsDescubiertos $Plugins
Assert-HermesEnterpriseCondition ($OrdenCarga[0].Manifest.Nombre -eq "PluginBase") "El grafo no ordenó primero la dependencia base."
Assert-HermesEnterpriseCondition ($OrdenCarga[1].Manifest.Nombre -eq "PluginDependiente") "El grafo no ordenó después el plugin dependiente."
Write-Host "Test-DependencyGraph completado correctamente." -ForegroundColor Green
