<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Invoke-HermesEnterpriseTests.ps1
Propósito:
    Ejecuta las pruebas de HERMES Enterprise mediante el smoke test oficial.
====================================================================================================
#>
[CmdletBinding()]
param([Parameter(Mandatory = $false)][string]$Filtro = "")

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaSmokeTest = Join-Path $RutaDirectorioScripts "Test-HermesEnterprise.ps1"

if (-not (Test-Path $RutaSmokeTest)) { throw "No se encontró el smoke test: $RutaSmokeTest" }

& $RutaSmokeTest

Write-Host "Pruebas HERMES Enterprise ejecutadas correctamente." -ForegroundColor Green
