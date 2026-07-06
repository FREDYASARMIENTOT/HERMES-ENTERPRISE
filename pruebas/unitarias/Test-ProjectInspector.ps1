<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-ProjectInspector.ps1
Propósito:
    Valida que ProjectInspector descubre proyectos sin modificar el sistema de archivos.
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

. (Join-Path $RutaRaizRepositorio "motor\context\ProjectInspector.ps1")

$RutaTemporal = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP "HermesProjectInspectorTest_$(Get-Random)"))
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null

try {
    $Info = Get-HermesEnterpriseProjectInfo -Ruta $RutaTemporal
    Assert-HermesEnterpriseCondition ($Info.NombreProyecto -eq (Split-Path $RutaTemporal -Leaf)) "ProjectInspector no infirió el nombre del proyecto."
    Assert-HermesEnterpriseCondition ($Info.RutaLocal -eq $RutaTemporal) "ProjectInspector no devolvió la ruta local."
    Assert-HermesEnterpriseCondition ($Info.EstadoGit -eq "Unknown") "ProjectInspector no reportó estado Git desconocido."
}
finally {
    Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Test-ProjectInspector completado correctamente." -ForegroundColor Green
