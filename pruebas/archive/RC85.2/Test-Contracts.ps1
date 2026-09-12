<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Contracts.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida contratos lógicos de plugins en PowerShell.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)
function Assert-HermesEnterpriseCondition { param([bool]$CondicionEvaluada,[string]$MensajeError) if (-not $CondicionEvaluada) { throw $MensajeError } }
. (Join-Path $RutaRaizRepositorio "motor\contracts\PluginContracts.ps1")
$RutaScriptHelloPlugin = Join-Path $RutaRaizRepositorio "plugins\HelloPlugin\HelloPlugin.ps1"
. $RutaScriptHelloPlugin
$ResultadoContrato = Test-HermesEnterprisePluginContract -NombrePlugin "HelloPlugin"
Assert-HermesEnterpriseCondition $ResultadoContrato.EsValido "HelloPlugin no cumple el contrato IPlugin esperado."
Write-Host "Test-Contracts completado correctamente." -ForegroundColor Green
