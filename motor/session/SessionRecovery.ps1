<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : SessionRecovery.ps1
Propósito:
    Crea respaldos de sesión y permite recuperar la última sesión válida.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioSessionRecovery = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioSessionRecovery "SessionPersistence.ps1")

function Backup-HermesEnterpriseSession {
    [CmdletBinding()][OutputType([string])]
    param(
        [Parameter(Mandatory=$true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory=$true)][psobject]$SessionDescriptor
    )
    $RutaBackup = Join-Path (Get-HermesEnterpriseSessionDirectory -RutaRaizRepositorio $RutaRaizRepositorio) "backup"
    if (-not (Test-Path $RutaBackup)) { New-Item -ItemType Directory -Path $RutaBackup -Force | Out-Null }
    $NombreArchivo = "$($SessionDescriptor.IdentificadorSesion)_$((Get-Date).ToString('yyyyMMddHHmmss')).json"
    $RutaArchivo = Join-Path $RutaBackup $NombreArchivo
    $SessionDescriptor | ConvertTo-Json -Depth 10 | Set-Content -Path $RutaArchivo -Encoding UTF8
    return $RutaArchivo
}

function Restore-HermesEnterpriseLatestSessionBackup {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory=$true)][string]$RutaRaizRepositorio)
    $RutaBackup = Join-Path (Get-HermesEnterpriseSessionDirectory -RutaRaizRepositorio $RutaRaizRepositorio) "backup"
    if (-not (Test-Path $RutaBackup)) { return $null }
    $Archivos = @(Get-ChildItem -Path $RutaBackup -Filter "*.json" | Sort-Object LastWriteTime -Descending)
    if ($Archivos.Count -eq 0) { return $null }
    $Sesion = Get-Content -Path $Archivos[0].FullName -Raw | ConvertFrom-Json
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
