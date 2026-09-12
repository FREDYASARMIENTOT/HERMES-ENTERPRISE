<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-GitHubInspector.ps1
Propósito:
    Valida que GitHubInspector expone información MOCK sin usar API reales.
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

. (Join-Path $RutaRaizRepositorio "motor\context\GitHubInspector.ps1")

$Info = Get-HermesEnterpriseGitHubInfo -NombreProyecto "TestProject"
Assert-HermesEnterpriseCondition ($Info.NombreProyecto -eq "TestProject") "GitHubInspector no conservó el nombre del proyecto."
Assert-HermesEnterpriseCondition ($Info.Modo -eq "MOCK") "GitHubInspector no indica modo MOCK."
Assert-HermesEnterpriseCondition ($Info.TieneRemoto -eq $false) "GitHubInspector reportó remoto inexistente."
Assert-HermesEnterpriseCondition ($Info.Estado -eq "MockDetected") "GitHubInspector no reportó estado MockDetected."

Write-Host "Test-GitHubInspector completado correctamente." -ForegroundColor Green
