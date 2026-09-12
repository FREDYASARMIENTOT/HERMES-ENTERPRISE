<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-DeveloperContextManager.ps1
Propósito:
    Valida que DeveloperContextManager construye contexto y administra Session automáticamente.
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

. (Join-Path $RutaRaizRepositorio "motor\context\DeveloperContextManager.ps1")

$RutaTemporal = [System.IO.Path]::GetFullPath((Join-Path $env:TEMP "HermesDCMTest_$(Get-Random)"))
New-Item -ItemType Directory -Path $RutaTemporal -Force | Out-Null

try {
    $Manager = New-HermesEnterpriseDeveloperContextManager -RutaRaizRepositorio $RutaTemporal
    $Contexto = $Manager.BuildContext("TestProject", $RutaTemporal)
    Assert-HermesEnterpriseCondition ($null -ne $Contexto) "DeveloperContextManager no construyó contexto."
    Assert-HermesEnterpriseCondition ($null -ne $Contexto.Session) "DeveloperContextManager no creó session automáticamente."
    Assert-HermesEnterpriseCondition ($Contexto.Proyecto.NombreProyecto -eq "TestProject") "DeveloperContextManager no usó nombre de proyecto."
    Assert-HermesEnterpriseCondition ($Contexto.Workspace.Ruta -eq $RutaTemporal) "DeveloperContextManager no usó workspace."

    # Segunda invocación debe recuperar la sesión existente
    $Contexto2 = $Manager.BuildContext("TestProject", $RutaTemporal)
    Assert-HermesEnterpriseCondition ($Contexto2.Session.IdentificadorSesion -eq $Contexto.Session.IdentificadorSesion) "DeveloperContextManager no recuperó sesión existente."
}
finally {
    Remove-Item -Path $RutaTemporal -Recurse -Force -ErrorAction SilentlyContinue
}

Write-Host "Test-DeveloperContextManager completado correctamente." -ForegroundColor Green
