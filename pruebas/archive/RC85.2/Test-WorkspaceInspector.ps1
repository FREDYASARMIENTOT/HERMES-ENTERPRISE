<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-WorkspaceInspector.ps1
Propósito:
    Valida que WorkspaceInspector descubre workspaces sin modificar el sistema de archivos.
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

. (Join-Path $RutaRaizRepositorio "motor\context\WorkspaceInspector.ps1")

$RutaTemporal = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP "HermesWorkspaceInspectorTest_$(Get-Random)"))
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null

try {
    $Info = Get-HermesEnterpriseWorkspaceInfo -Ruta $RutaTemporal
    Assert-HermesEnterpriseCondition ($Info.Ruta -eq $RutaTemporal) "WorkspaceInspector no devolvió la ruta absoluta."
    Assert-HermesEnterpriseCondition ($Info.Existe -eq $true) "WorkspaceInspector no detectó existencia."
    Assert-HermesEnterpriseCondition ($Info.Nombre -eq (Split-Path $RutaTemporal -Leaf)) "WorkspaceInspector no devolvió el nombre."
    Assert-HermesEnterpriseCondition ($Info.TieneWorkspaceVSCode -eq $false) "WorkspaceInspector reportó workspace VS Code inexistente."

    $RutaWorkspaceFile = Join-Path $RutaTemporal "test.code-workspace"
    '{"folders":[{"path":"."}]}' | Out-File -FilePath $RutaWorkspaceFile -Encoding utf8 -NoNewline
    $InfoConWorkspace = Get-HermesEnterpriseWorkspaceInfo -Ruta $RutaTemporal
    Assert-HermesEnterpriseCondition ($InfoConWorkspace.TieneWorkspaceVSCode -eq $true) "WorkspaceInspector no detectó archivo .code-workspace."
}
finally {
    Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Test-WorkspaceInspector completado correctamente." -ForegroundColor Green
