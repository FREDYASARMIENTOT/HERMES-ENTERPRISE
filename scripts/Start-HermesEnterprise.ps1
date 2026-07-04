<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Start-HermesEnterprise.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Script público para iniciar el Kernel Enterprise desde la raíz del repositorio.
====================================================================================================
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$NombreEntorno = "Desarrollo",

    [Parameter(Mandatory = $false)]
    [switch]$DevolverKernel
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts

. (Join-Path $RutaRaizRepositorio "motor\bootstrap\Bootstrap.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelValidator.ps1")

$KernelEnterprise = Start-HermesEnterpriseBootstrap -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno $NombreEntorno
$ResultadoValidacionKernel = Test-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise

if (-not $ResultadoValidacionKernel.EsValido) {
    throw "El Kernel Enterprise no superó la validación: $($ResultadoValidacionKernel.Errores -join '; ')"
}

Write-Host "Hermes Enterprise Kernel iniciado correctamente." -ForegroundColor Green
Write-Host "Estado  : $($KernelEnterprise.EstadoKernel)"
Write-Host "Runtime : $($KernelEnterprise.Runtime.EstadoRuntime)"

if ($DevolverKernel.IsPresent) {
    return $KernelEnterprise
}
