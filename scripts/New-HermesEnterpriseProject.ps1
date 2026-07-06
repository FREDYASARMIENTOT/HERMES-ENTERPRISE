<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : New-HermesEnterpriseProject.ps1
Propósito:
    Crea un nuevo proyecto local utilizando HERMES Enterprise.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][ValidateNotNullOrEmpty()][string]$Nombre,
    [Parameter(Mandatory = $false)][string]$RutaBase = ".",
    [Parameter(Mandatory = $false)][string]$LenguajePrincipal = "PowerShell",
    [Parameter(Mandatory = $false)][string]$TipoProyecto = "HermesModule",
    [Parameter(Mandatory = $false)][switch]$CrearReadme
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts
. (Join-Path $RutaRaizRepositorio "motor\providers\WorkspaceProvider.ps1")

$Proyecto = New-HermesEnterpriseProject -NombreProyecto $Nombre -RutaBase $RutaBase -LenguajePrincipal $LenguajePrincipal -TipoProyecto $TipoProyecto

if ($CrearReadme.IsPresent) {
    $Readme = New-HermesEnterpriseProjectReadme -Ruta $Proyecto.RutaLocal -NombreProyecto $Nombre -Descripcion "Proyecto gestionado por HERMES Enterprise."
    $Readme.Contenido | Out-File -FilePath $Readme.RutaArchivo -Encoding utf8 -NoNewline
    Write-Host "README creado: $($Readme.RutaArchivo)" -ForegroundColor Cyan
}

Write-Host "Proyecto creado: $($Proyecto.RutaLocal)" -ForegroundColor Green
return $Proyecto
