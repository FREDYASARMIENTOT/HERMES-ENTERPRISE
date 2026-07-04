<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-VersionValidator.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida compatibilidad de versión entre plugin y Kernel.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }
. (Join-Path $RutaRaizRepositorio "motor\validation\VersionValidator.ps1")
$ResultadoCompatible = Test-HermesEnterprisePluginKernelVersion -VersionKernelActual "0.4.0" -VersionKernelMinimaRequerida "0.3.0"
$ResultadoIncompatible = Test-HermesEnterprisePluginKernelVersion -VersionKernelActual "0.3.0" -VersionKernelMinimaRequerida "0.4.0"
Assert-HermesEnterpriseCondition $ResultadoCompatible.EsCompatible "El validador rechazó una versión compatible."
Assert-HermesEnterpriseCondition (-not $ResultadoIncompatible.EsCompatible) "El validador aceptó una versión incompatible."
Write-Host "Test-VersionValidator completado correctamente." -ForegroundColor Green
