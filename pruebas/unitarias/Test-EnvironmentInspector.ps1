<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-EnvironmentInspector.ps1
Propósito:
    Valida que EnvironmentInspector descubre variables de entorno locales sin exponer secretos.
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

. (Join-Path $RutaRaizRepositorio "motor\context\EnvironmentInspector.ps1")

$Info = Get-HermesEnterpriseEnvironmentInfo
Assert-HermesEnterpriseCondition ($null -ne $Info.VariablesEntorno) "EnvironmentInspector no devolvió variables."
Assert-HermesEnterpriseCondition ($Info.VariablesEntorno.ContainsKey("PATH")) "EnvironmentInspector no capturó PATH."
Assert-HermesEnterpriseCondition (-not [string]::IsNullOrWhiteSpace($Info.IdiomaPreferido)) "EnvironmentInspector no devolvió idioma preferido."
Assert-HermesEnterpriseCondition (-not [string]::IsNullOrWhiteSpace($Info.Region)) "EnvironmentInspector no devolvió región."
Assert-HermesEnterpriseCondition (-not [string]::IsNullOrWhiteSpace($Info.Usuario)) "EnvironmentInspector no devolvió usuario."

Write-Host "Test-EnvironmentInspector completado correctamente." -ForegroundColor Green
