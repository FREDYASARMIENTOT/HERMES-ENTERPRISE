<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-HermesEnterprise.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Ejecuta el smoke test oficial de HERMES-ENTERPRISE: Kernel Enterprise, Provider Framework y
    el primer provider real (AzureFoundryProvider en modo simulado).
====================================================================================================
#>

[CmdletBinding()]
param()

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScripts
$RutaPruebaIntegracionKernel = Join-Path $RutaRaizRepositorio "pruebas\integracion\Test-FullKernel.ps1"
$RutaPruebasUnitarias = Join-Path $RutaRaizRepositorio "pruebas\unitarias"

if (-not (Test-Path -Path $RutaPruebaIntegracionKernel)) {
    throw "No existe la prueba de integración requerida: $RutaPruebaIntegracionKernel"
}

$PruebasUnitariasRequeridas = @(
    "Test-ProviderFramework.ps1",
    "Test-ProviderManagerValidation.ps1",
    "Test-ProviderObservability.ps1",
    "Test-ProviderFrameworkMaturity.ps1",
    "Test-MockProvider.ps1",
    "Test-AzureFoundryProvider.ps1",
    "Test-AzureFoundryProviderConnection.ps1",
    "Test-AzureFoundryProviderTelemetry.ps1",
    "Test-GitHubWorkspace.ps1"
)

Write-Host "Ejecutando Smoke Test Enterprise del Kernel..." -ForegroundColor Cyan
& $RutaPruebaIntegracionKernel
Write-Host "Smoke Test Enterprise del Kernel completado correctamente." -ForegroundColor Green

foreach ($Prueba in $PruebasUnitariasRequeridas) {
    $RutaPrueba = Join-Path $RutaPruebasUnitarias $Prueba
    if (-not (Test-Path -Path $RutaPrueba)) {
        throw "No existe la prueba unitaria requerida: $RutaPrueba"
    }

    Write-Host "Ejecutando $Prueba..." -ForegroundColor Cyan
    & $RutaPrueba
    Write-Host "$Prueba completado correctamente." -ForegroundColor Green
}

Write-Host "Smoke Test Enterprise completo correctamente." -ForegroundColor Green
