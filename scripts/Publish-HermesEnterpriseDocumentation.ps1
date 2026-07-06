<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Publish-HermesEnterpriseDocumentation.ps1
Propósito:
    Publica la documentación de HERMES Enterprise delegando en el motor documental existente.
====================================================================================================
#>
[CmdletBinding()]
param([Parameter(Mandatory = $false)][switch]$SoloValidar)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScripts = Split-Path -Parent $PSCommandPath
$RutaGeneradorDocumentacion = Join-Path $RutaDirectorioScripts "New-HermesEnterpriseDocumentation.ps1"

if (-not (Test-Path $RutaGeneradorDocumentacion)) { throw "No se encontró el generador documental: $RutaGeneradorDocumentacion" }

if ($SoloValidar.IsPresent) {
    & $RutaGeneradorDocumentacion -SoloValidar
}
else {
    & $RutaGeneradorDocumentacion
}

Write-Host "Documentación HERMES Enterprise publicada." -ForegroundColor Green
