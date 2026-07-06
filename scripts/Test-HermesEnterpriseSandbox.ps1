<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-HermesEnterpriseSandbox.ps1
Propósito:
    Ejecuta el Smoke Test Enterprise dentro de un Sandbox. Si falla, registra el error y detiene.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RutaSandbox = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioScript = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioScript

function Test-HermesEnterpriseSandbox {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][string]$RutaSandbox)

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($RutaSandbox)
    $RutaSmokeTest = Join-Path $RutaRaizRepositorio "scripts\Test-HermesEnterprise.ps1"
    $RutaLogs = Join-Path $RutaAbsoluta "Logs"

    $Resultado = [pscustomobject][ordered]@{
        RutaSandbox = $RutaAbsoluta
        Inicio      = (Get-Date).ToString("o")
        Estado      = "Unknown"
        Salida      = ""
        Errores     = @()
    }

    try {
        $Salida = & $RutaSmokeTest 2>&1 | Out-String
        $Resultado.Salida = $Salida
        $Resultado.Estado = "PASSED"
        $Resultado.Fin = (Get-Date).ToString("o")
    }
    catch {
        $MensajeError = $_.Exception.Message
        $Resultado.Errores += $MensajeError
        $Resultado.Estado = "FAILED"

        $RutaErrorLog = Join-Path $RutaLogs "smoke-test-error.log"
        "[$((Get-Date).ToString('o'))] ERROR: $MensajeError" | Set-Content -Path $RutaErrorLog -Encoding UTF8

        throw
    }

    return $Resultado
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($RutaSandbox)) {
        throw "El parámetro -RutaSandbox es obligatorio al ejecutar el script directamente."
    }
    Test-HermesEnterpriseSandbox -RutaSandbox $RutaSandbox
}
