<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-FirstRunWizard.ps1
Propósito:
    Valida que FirstRunWizard configura preferencias sin crear proyectos.
====================================================================================================
#>
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition {
    param([bool]$CondicionEvaluada, [string]$MensajeError)
    if (-not $CondicionEvaluada) { throw $MensajeError }
}

. (Join-Path $RutaRaizRepositorio "motor\wizards\FirstRunWizard.ps1")

$Preferencias = Start-HermesEnterpriseFirstRunWizard
Assert-HermesEnterpriseCondition ($Preferencias.Configurado -eq $true) "FirstRunWizard no reportó configuración."
Assert-HermesEnterpriseCondition ($Preferencias.Idioma -eq "es") "FirstRunWizard no usó idioma por defecto."
Assert-HermesEnterpriseCondition ($Preferencias.ProveedorIA -eq "AzureFoundryProvider") "FirstRunWizard no usó provider por defecto."
Assert-HermesEnterpriseCondition ($Preferencias.ModeloIA -eq "ur-hermes-mini") "FirstRunWizard no usó modelo por defecto."
Assert-HermesEnterpriseCondition ($Preferencias.PSObject.Properties.Name -notcontains "Proyecto") "FirstRunWizard no debe crear proyecto."

Write-Host "Test-FirstRunWizard completado correctamente." -ForegroundColor Green
