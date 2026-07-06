<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Start-HermesEnterprise.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Script público para iniciar HERMES Enterprise. Carga el Kernel y gestiona la sesión
    de desarrollo: recupera una sesión existente o ejecuta el Session Wizard.
====================================================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$NombreEntorno = "Desarrollo",

    [Parameter(Mandatory = $false)]
    [switch]$DevolverKernel,

    [Parameter(Mandatory = $false)]
    [switch]$DevolverSesion
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts

. (Join-Path $RutaRaizRepositorio "motor\bootstrap\Bootstrap.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelValidator.ps1")
. (Join-Path $RutaRaizRepositorio "motor\session\SessionManager.ps1")

$KernelEnterprise = Start-HermesEnterpriseBootstrap -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno $NombreEntorno
$ResultadoValidacionKernel = Test-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise

if (-not $ResultadoValidacionKernel.EsValido) {
    throw "El Kernel Enterprise no superó la validación: $($ResultadoValidacionKernel.Errores -join '; ')"
}

$Sesion = Open-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio
if ($null -eq $Sesion) {
    Write-Host "No se detectó sesión previa. Iniciando Session Wizard..." -ForegroundColor Yellow
    $Sesion = New-HermesEnterpriseSession -NombreProyecto "HermesProject" -RutaBase $RutaRaizRepositorio
}
else {
    Write-Host "Sesión recuperada: $($Sesion.IdentificadorSesion)" -ForegroundColor Green
}

Write-Host "Hermes Enterprise Kernel iniciado correctamente." -ForegroundColor Green
Write-Host "Estado  : $($KernelEnterprise.EstadoKernel)"
Write-Host "Runtime : $($KernelEnterprise.Runtime.EstadoRuntime)"
Write-Host "Sesión  : $($Sesion.IdentificadorSesion)"
Write-Host "Proyecto: $($Sesion.NombreProyecto)"

if ($DevolverSesion.IsPresent) {
    return $Sesion
}

if ($DevolverKernel.IsPresent) {
    return $KernelEnterprise
}
