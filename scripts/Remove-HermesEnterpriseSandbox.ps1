<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Remove-HermesEnterpriseSandbox.ps1
Propósito:
    Elimina únicamente el Sandbox especificado. Nunca elimina la raíz D:\Sandbox ni otros Test.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RutaSandbox = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Remove-HermesEnterpriseSandbox {
    [CmdletBinding()][OutputType([bool])]
    param([Parameter(Mandatory = $true)][string]$RutaSandbox)

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($RutaSandbox)
    $Nombre = Split-Path -Path $RutaAbsoluta -Leaf
    $RutaPadre = Split-Path -Path $RutaAbsoluta -Parent

    if (-not ($Nombre -match "^Test\d{3}-")) {
        throw "La ruta no parece un Sandbox de HERMES Enterprise: $RutaAbsoluta"
    }

    if (-not (Test-Path (Join-Path $RutaAbsoluta "sandbox.json"))) {
        throw "La ruta no contiene un sandbox.json válido: $RutaAbsoluta"
    }

    if (Test-Path $RutaAbsoluta) {
        Remove-Item -Path $RutaAbsoluta -Recurse -Force -ErrorAction Stop
        return $true
    }

    return $false
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($RutaSandbox)) {
        throw "El parámetro -RutaSandbox es obligatorio al ejecutar el script directamente."
    }
    Remove-HermesEnterpriseSandbox -RutaSandbox $RutaSandbox
}
