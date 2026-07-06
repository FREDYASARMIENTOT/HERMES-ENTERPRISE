<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProjectWizard.ps1
Propósito:
    Valida que ProjectWizard crea estructura de proyecto, workspace, Git y GitHub MOCK.
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

. (Join-Path $RutaRaizRepositorio "motor\wizards\ProjectWizard.ps1")

$RutaBaseTemporal = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP "HermesProjectWizardTest_$(Get-Random)"))
New-Item -ItemType Directory -Path $RutaBaseTemporal -Force | Out-Null

try {
    $Resultado = Start-HermesEnterpriseProjectWizard -RutaBase $RutaBaseTemporal -NombreProyecto "WizardProject" -CrearGit -CrearGitHub
    Assert-HermesEnterpriseCondition ($Resultado.Proyecto.NombreProyecto -eq "WizardProject") "ProjectWizard no creó proyecto."
    Assert-HermesEnterpriseCondition (Test-Path $Resultado.Ruta) "ProjectWizard no creó carpeta."
    Assert-HermesEnterpriseCondition ($Resultado.Workspace.RutaArchivo -like "*.code-workspace") "ProjectWizard no generó workspace."
    Assert-HermesEnterpriseCondition ($Resultado.Git.GitInit.Operacion -eq "init") "ProjectWizard no preparó git init."
    Assert-HermesEnterpriseCondition ($Resultado.GitHub.Estado -eq "MOCK-Repository-Create") "ProjectWizard no preparó GitHub MOCK."
}
finally {
    Remove-Item -Path $RutaBaseTemporal -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Test-ProjectWizard completado correctamente." -ForegroundColor Green
