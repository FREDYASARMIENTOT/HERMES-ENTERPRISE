<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : SessionPersistence.ps1
Propósito:
    Persiste y carga SessionDescriptor en formato JSON local.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Get-HermesEnterpriseSessionDirectory {
    [CmdletBinding()][OutputType([string])]
    param([Parameter(Mandatory=$true)][string]$RutaRaizRepositorio)
    $Ruta = Join-Path $RutaRaizRepositorio ".hermes\sessions"
    if (-not (Test-Path $Ruta)) { New-Item -ItemType Directory -Path $Ruta -Force | Out-Null }
    return $Ruta
}

function Get-HermesEnterpriseSessionFilePath {
    [CmdletBinding()][OutputType([string])]
    param(
        [Parameter(Mandatory=$true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory=$true)][string]$IdentificadorSesion
    )
    return Join-Path (Get-HermesEnterpriseSessionDirectory -RutaRaizRepositorio $RutaRaizRepositorio) "$IdentificadorSesion.json"
}

function Save-HermesEnterpriseSession {
    [CmdletBinding()][OutputType([string])]
    param(
        [Parameter(Mandatory=$true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory=$true)][psobject]$SessionDescriptor
    )
    $RutaArchivo = Get-HermesEnterpriseSessionFilePath -RutaRaizRepositorio $RutaRaizRepositorio -IdentificadorSesion $SessionDescriptor.IdentificadorSesion
    [void]($SessionDescriptor.UltimaActividad = Get-Date)
    $SessionDescriptor | ConvertTo-Json -Depth 10 | Set-Content -Path $RutaArchivo -Encoding UTF8
    return $RutaArchivo
}

function Load-HermesEnterpriseSession {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory=$true)][string]$IdentificadorSesion
    )
    $RutaArchivo = Get-HermesEnterpriseSessionFilePath -RutaRaizRepositorio $RutaRaizRepositorio -IdentificadorSesion $IdentificadorSesion
    if (-not (Test-Path $RutaArchivo)) { return $null }
    $Raw = Get-Content -Path $RutaArchivo -Raw
    $Sesion = $Raw | ConvertFrom-Json
    if ($null -eq $Sesion.Historial) {
        $Sesion.Historial = New-Object System.Collections.Generic.List[psobject]
    }
    elseif ($Sesion.Historial -isnot [System.Collections.Generic.List[psobject]]) {
        $Lista = New-Object System.Collections.Generic.List[psobject]
        foreach ($Evento in $Sesion.Historial) { $Lista.Add($Evento) }
        $Sesion.Historial = $Lista
    }
    return $Sesion
}

function Get-HermesEnterpriseSessionList {
    [CmdletBinding()][OutputType([pscustomobject[]])]
    param([Parameter(Mandatory=$true)][string]$RutaRaizRepositorio)
    $Ruta = Get-HermesEnterpriseSessionDirectory -RutaRaizRepositorio $RutaRaizRepositorio
    return Get-ChildItem -Path $Ruta -Filter "*.json" | Select-Object -ExpandProperty BaseName
}
