<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-GitInspector.ps1
Propósito:
    Valida que GitInspector detecta repositorios Git sin ejecutar operaciones destructivas.
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

. (Join-Path $RutaRaizRepositorio "motor\context\GitInspector.ps1")

$RutaTemporal = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP "HermesGitInspectorTest_$(Get-Random)"))
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null

try {
    $Info = Get-HermesEnterpriseGitInfo -Ruta $RutaTemporal
    Assert-HermesEnterpriseCondition ($Info.TieneGit -eq $false) "GitInspector reportó .git inexistente."
    Assert-HermesEnterpriseCondition ($Info.Estado -eq "NoRepository") "GitInspector no reportó estado NoRepository."

    New-Item -ItemType Directory -Path (Join-Path $RutaTemporal ".git") -Force | Out-Null
    $Info2 = Get-HermesEnterpriseGitInfo -Ruta $RutaTemporal
    Assert-HermesEnterpriseCondition ($Info2.TieneGit -eq $true) "GitInspector no detectó .git."
    Assert-HermesEnterpriseCondition ($Info2.Estado -eq "Detected") "GitInspector no reportó estado Detected."
}
finally {
    Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Test-GitInspector completado correctamente." -ForegroundColor Green
