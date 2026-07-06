<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : SessionLoader.ps1
Propósito:
    Detecta sesiones existentes y carga la sesión más reciente.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioSessionLoader = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioSessionLoader "SessionPersistence.ps1")

function Test-HermesEnterpriseSessionExists {
    [CmdletBinding()][OutputType([bool])]
    param([Parameter(Mandatory=$true)][string]$RutaRaizRepositorio)
    $Sesiones = Get-HermesEnterpriseSessionList -RutaRaizRepositorio $RutaRaizRepositorio
    return ($null -ne $Sesiones -and $Sesiones.Count -gt 0)
}

function Get-HermesEnterpriseLatestSession {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$RutaRaizRepositorio)
    $RutaDirectorio = Get-HermesEnterpriseSessionDirectory -RutaRaizRepositorio $RutaRaizRepositorio
    $Archivos = @(Get-ChildItem -Path $RutaDirectorio -Filter "*.json" | Sort-Object LastWriteTime -Descending)
    if ($Archivos.Count -eq 0) { return $null }
    return Load-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -IdentificadorSesion $Archivos[0].BaseName
}

function Load-HermesEnterpriseDefaultSession {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$RutaRaizRepositorio)
    if (-not (Test-HermesEnterpriseSessionExists -RutaRaizRepositorio $RutaRaizRepositorio)) { return $null }
    return Get-HermesEnterpriseLatestSession -RutaRaizRepositorio $RutaRaizRepositorio
}
