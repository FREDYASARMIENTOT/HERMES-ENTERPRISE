<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Open-HermesEnterpriseProject.ps1
Propósito:
    Abre un proyecto local en VS Code utilizando HERMES Enterprise.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Ruta,
    [Parameter(Mandatory = $false)][switch]$NuevaVentana,
    [Parameter(Mandatory = $false)][switch]$SoloMostrarComando
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts
. (Join-Path $RutaRaizRepositorio "motor\providers\WorkspaceProvider.ps1")

$Descriptor = Open-HermesEnterpriseProject -Ruta $Ruta
$Operacion = if ($NuevaVentana.IsPresent) { "NewWorkspace" } else { "OpenFolder" }
$ComandoVSCode = Invoke-HermesEnterpriseVSCodeCommand -Operacion $Operacion -Ruta $Ruta

Write-Host "Proyecto: $($Descriptor.NombreProyecto)" -ForegroundColor Cyan
Write-Host "Ruta    : $($Descriptor.RutaLocal)" -ForegroundColor Cyan
Write-Host "Git     : $($Descriptor.RepositorioGit)" -ForegroundColor Cyan
Write-Host "VS Code : $($ComandoVSCode.Comando)" -ForegroundColor Cyan

if ($SoloMostrarComando.IsPresent) { return $ComandoVSCode }
return $Descriptor
