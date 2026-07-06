<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Get-HermesEnterpriseSandbox.ps1
Propósito:
    Lista los Sandboxes existentes bajo la raíz configurada, mostrando metadatos desde sandbox.json.
====================================================================================================
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RutaRaizSandbox = "D:\Sandbox"
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-HermesEnterpriseSandbox {
    [CmdletBinding()][OutputType([pscustomobject[]])]
    param([Parameter(Mandatory = $true)][string]$RutaRaizSandbox)

    $RutaAbsoluta = [System.IO.Path]::GetFullPath($RutaRaizSandbox)
    if (-not (Test-Path $RutaAbsoluta)) { return @() }

    $Directorios = Get-ChildItem -Path $RutaAbsoluta -Directory -Filter "Test*" -ErrorAction SilentlyContinue | Sort-Object Name
    $Resultado = @()

    foreach ($Directorio in $Directorios) {
        $RutaMetadata = Join-Path $Directorio.FullName "sandbox.json"
        $Metadata = if (Test-Path $RutaMetadata) {
            Get-Content -Path $RutaMetadata -Raw | ConvertFrom-Json
        } else {
            [pscustomobject][ordered]@{
                Numero    = ""
                Fecha     = ""
                Proyecto  = ""
                Estado    = "Unknown"
                Resultado = ""
            }
        }

        $Resultado += [pscustomobject][ordered]@{
            Nombre    = $Directorio.Name
            Ruta      = $Directorio.FullName
            Numero    = $Metadata.Numero
            Fecha     = $Metadata.Fecha
            Proyecto  = $Metadata.Proyecto
            Estado    = $Metadata.Estado
            Resultado = $Metadata.Resultado
        }
    }

    return ,$Resultado
}

if ($MyInvocation.InvocationName -ne '.') {
    Get-HermesEnterpriseSandbox -RutaRaizSandbox $RutaRaizSandbox
}
