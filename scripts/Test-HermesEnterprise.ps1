<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-HermesEnterprise.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Ejecuta la prueba de integración completa del Kernel Enterprise como smoke test oficial de
    la infraestructura base antes de avanzar hacia fases evolutivas posteriores.
====================================================================================================
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts
$RutaPruebaIntegracionKernel = Join-Path $RutaRaizRepositorio "pruebas\integracion\Test-FullKernel.ps1"

if (-not (Test-Path -Path $RutaPruebaIntegracionKernel)) {
    throw "No existe la prueba de integración requerida: $RutaPruebaIntegracionKernel"
}

Write-Host "Ejecutando Smoke Test Enterprise del Kernel..." -ForegroundColor Cyan
& $RutaPruebaIntegracionKernel
Write-Host "Smoke Test Enterprise completado correctamente." -ForegroundColor Green
