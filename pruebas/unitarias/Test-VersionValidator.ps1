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

$ResultadoFormatoPlugin = Test-HermesEnterpriseSemanticVersion -VersionSemantica "1.2.3" -NombreCampo "Version"
Assert-HermesEnterpriseCondition $ResultadoFormatoPlugin.EsValida "El validador rechazó una versión SemVer Major.Minor.Patch válida."
Assert-HermesEnterpriseCondition ($ResultadoFormatoPlugin.Major -eq 1) "El validador no extrajo Major correctamente."
Assert-HermesEnterpriseCondition ($ResultadoFormatoPlugin.Minor -eq 2) "El validador no extrajo Minor correctamente."
Assert-HermesEnterpriseCondition ($ResultadoFormatoPlugin.Patch -eq 3) "El validador no extrajo Patch correctamente."

$ResultadoFormatoInvalido = Test-HermesEnterpriseSemanticVersion -VersionSemantica "1.2" -NombreCampo "Version"
Assert-HermesEnterpriseCondition (-not $ResultadoFormatoInvalido.EsValida) "El validador aceptó una versión sin Patch."
Assert-HermesEnterpriseCondition ($ResultadoFormatoInvalido.Mensaje.Contains("Major.Minor.Patch")) "El validador no generó un error descriptivo para SemVer inválido."

$ResultadoCompatible = Test-HermesEnterprisePluginKernelVersion -VersionKernelActual "0.4.0" -VersionKernelMinimaRequerida "0.3.0"
$ResultadoIncompatible = Test-HermesEnterprisePluginKernelVersion -VersionKernelActual "0.3.0" -VersionKernelMinimaRequerida "0.4.0"
$ResultadoKernelInvalido = Test-HermesEnterprisePluginKernelVersion -VersionKernelActual "0.4" -VersionKernelMinimaRequerida "0.4.0"
Assert-HermesEnterpriseCondition $ResultadoCompatible.EsCompatible "El validador rechazó una versión compatible."
Assert-HermesEnterpriseCondition (-not $ResultadoIncompatible.EsCompatible) "El validador aceptó una versión incompatible."
Assert-HermesEnterpriseCondition (-not $ResultadoKernelInvalido.EsCompatible) "El validador aceptó una versión de Kernel sin formato Major.Minor.Patch."
Write-Host "Test-VersionValidator completado correctamente." -ForegroundColor Green
