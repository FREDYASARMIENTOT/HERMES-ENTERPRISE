<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Invoke-HermesEnterpriseScenario.ps1
Propósito:
    Ejecuta HERMES Enterprise dentro de un Sandbox preparado y recolecta el DeveloperContext.
    Si ocurre un error, lo registra y detiene la ejecución. No reintenta automáticamente.
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

. (Join-Path $RutaRaizRepositorio "motor\context\ContextBuilder.ps1")

function Invoke-HermesEnterpriseScenario {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][string]$RutaSandbox)

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($RutaSandbox)
    $RutaMetadata = Join-Path $RutaAbsoluta "sandbox.json"
    $RutaLogs = Join-Path $RutaAbsoluta "Logs"
    $RutaWorkspace = Join-Path $RutaAbsoluta "Workspace"

    if (-not (Test-Path $RutaMetadata)) {
        throw "No se encontró sandbox.json en $RutaAbsoluta"
    }

    $Metadata = Get-Content -Path $RutaMetadata -Raw | ConvertFrom-Json
    $Resultado = [pscustomobject][ordered]@{
        Escenario        = $Metadata.Escenario
        RutaSandbox      = $RutaAbsoluta
        Inicio           = (Get-Date).ToString("o")
        Fin              = ""
        Estado           = "Unknown"
        DeveloperContext = $null
        Errores          = @()
    }

    try {
        $Contexto = Build-HermesEnterpriseDeveloperContext `
            -RutaWorkspace $RutaWorkspace `
            -NombreProyecto $Metadata.Proyecto `
            -Modelo $Metadata.Modelo `
            -ProveedorIA $Metadata.Provider

        $Resultado.DeveloperContext = $Contexto
        $Resultado.Fin = (Get-Date).ToString("o")
        $Resultado.Estado = "Executed"

        $Metadata.Estado = "Executed"
        $Metadata | ConvertTo-Json -Depth 5 | Set-Content -Path $RutaMetadata -Encoding UTF8
    }
    catch {
        $MensajeError = $_.Exception.Message
        $Resultado.Errores += $MensajeError
        $Resultado.Estado = "FAILED"

        $RutaErrorLog = Join-Path $RutaLogs "scenario-error.log"
        "[$((Get-Date).ToString('o'))] ERROR: $MensajeError" | Set-Content -Path $RutaErrorLog -Encoding UTF8

        $Metadata.Estado = "FAILED"
        $Metadata.Resultado = $MensajeError
        $Metadata | ConvertTo-Json -Depth 5 | Set-Content -Path $RutaMetadata -Encoding UTF8

        throw
    }

    return $Resultado
}

if ($MyInvocation.InvocationName -ne '.') {
    if ([string]::IsNullOrWhiteSpace($RutaSandbox)) {
        throw "El parámetro -RutaSandbox es obligatorio al ejecutar el script directamente."
    }
    Invoke-HermesEnterpriseScenario -RutaSandbox $RutaSandbox
}
