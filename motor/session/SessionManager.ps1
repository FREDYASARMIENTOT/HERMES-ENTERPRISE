<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : SessionManager.ps1
Propósito:
    Orquesta el ciclo de vida de sesiones HERMES Enterprise: crear, abrir, cerrar, guardar,
    recuperar y actualizar el contexto de desarrollo.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioSessionManager = Split-Path -Parent $PSCommandPath
. (Join-Path $RutaDirectorioSessionManager "SessionDescriptor.ps1")
. (Join-Path $RutaDirectorioSessionManager "SessionLoader.ps1")
. (Join-Path $RutaDirectorioSessionManager "SessionPersistence.ps1")
. (Join-Path $RutaDirectorioSessionManager "SessionRecovery.ps1")
. (Join-Path $RutaDirectorioSessionManager "SessionTelemetry.ps1")
. (Join-Path $RutaDirectorioSessionManager "SessionWizard.ps1")
. (Join-Path $RutaDirectorioSessionManager "..\providers\WorkspaceProvider.ps1")

function New-HermesEnterpriseSession {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $false)][string]$NombreProyecto = "HermesProject",
        [Parameter(Mandatory = $false)][string]$RutaBase = ".",
        [Parameter(Mandatory = $false)][string]$ModeloIA = "ur-hermes-mini",
        [Parameter(Mandatory = $false)][string]$ProveedorIA = "AzureFoundryProvider"
    )
    $RutaRaizRepositorio = (Resolve-Path $RutaBase).Path
    return Start-HermesEnterpriseSessionWizard -RutaRaizRepositorio $RutaRaizRepositorio -NombreProyecto $NombreProyecto -RutaBase $RutaBase -ModeloIA $ModeloIA -ProveedorIA $ProveedorIA
}

function Open-HermesEnterpriseSession {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][string]$RutaRaizRepositorio)
    $Sesion = Load-HermesEnterpriseDefaultSession -RutaRaizRepositorio $RutaRaizRepositorio
    if ($null -eq $Sesion) { return $null }
    $Sesion.EstadoSesion = "Active"
    $Sesion.UltimaActividad = Get-Date
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $Sesion -Operacion "SessionOpened" -Mensaje "Sesión abierta desde persistencia."
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $Sesion
    return $Sesion
}

function Close-HermesEnterpriseSession {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $true)][psobject]$SessionDescriptor
    )
    $null = Backup-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $SessionDescriptor
    $SessionDescriptor.EstadoSesion = "Closed"
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $SessionDescriptor -Operacion "SessionClosed" -Mensaje "Sesión cerrada."
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $SessionDescriptor
    return $SessionDescriptor
}

function Save-HermesEnterpriseSessionState {
    [CmdletBinding()][OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $true)][psobject]$SessionDescriptor
    )
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $SessionDescriptor -Operacion "SessionSaved" -Mensaje "Sesión guardada."
    return Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $SessionDescriptor
}

function Restore-HermesEnterpriseSession {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][string]$RutaRaizRepositorio)
    $Sesion = Restore-HermesEnterpriseLatestSessionBackup -RutaRaizRepositorio $RutaRaizRepositorio
    if ($null -eq $Sesion) { return $null }
    $Sesion.EstadoSesion = "Recovered"
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $Sesion -Operacion "SessionRecovered" -Mensaje "Sesión recuperada desde respaldo."
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $Sesion
    return $Sesion
}

function Set-HermesEnterpriseSessionProject {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $true)][psobject]$SessionDescriptor,
        [Parameter(Mandatory = $true)][string]$NombreProyecto,
        [Parameter(Mandatory = $false)][string]$RutaBase = "."
    )
    $Proyecto = New-HermesEnterpriseProject -NombreProyecto $NombreProyecto -RutaBase $RutaBase
    $SessionDescriptor.NombreProyecto = $NombreProyecto
    $SessionDescriptor.RutaWorkspace = $Proyecto.RutaLocal
    $SessionDescriptor.RepositorioGit = Test-HermesEnterpriseGitRepository -Ruta $Proyecto.RutaLocal
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $SessionDescriptor -Operacion "ProjectChanged" -Mensaje "Proyecto cambiado a $NombreProyecto."
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $SessionDescriptor
    return $SessionDescriptor
}

function Set-HermesEnterpriseSessionWorkspace {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $true)][psobject]$SessionDescriptor,
        [Parameter(Mandatory = $true)][string]$RutaWorkspace
    )
    $SessionDescriptor.RutaWorkspace = Resolve-Path $RutaWorkspace
    $SessionDescriptor.RepositorioGit = Test-HermesEnterpriseGitRepository -Ruta $RutaWorkspace
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $SessionDescriptor -Operacion "WorkspaceChanged" -Mensaje "Workspace cambiado a $RutaWorkspace."
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $SessionDescriptor
    return $SessionDescriptor
}

function Set-HermesEnterpriseSessionModel {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $true)][psobject]$SessionDescriptor,
        [Parameter(Mandatory = $true)][string]$ModeloIA
    )
    $SessionDescriptor.ModeloIA = $ModeloIA
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $SessionDescriptor -Operacion "ModelChanged" -Mensaje "Modelo cambiado a $ModeloIA."
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $SessionDescriptor
    return $SessionDescriptor
}

function Set-HermesEnterpriseSessionProvider {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $true)][psobject]$SessionDescriptor,
        [Parameter(Mandatory = $true)][string]$ProveedorIA
    )
    $SessionDescriptor.ProveedorIA = $ProveedorIA
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $SessionDescriptor -Operacion "ProviderChanged" -Mensaje "Proveedor cambiado a $ProveedorIA."
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $SessionDescriptor
    return $SessionDescriptor
}

function Set-HermesEnterpriseSessionBranch {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $true)][psobject]$SessionDescriptor,
        [Parameter(Mandatory = $true)][string]$Branch
    )
    $SessionDescriptor.BranchActual = $Branch
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $SessionDescriptor -Operacion "BranchChanged" -Mensaje "Rama cambiada a $Branch."
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $SessionDescriptor
    return $SessionDescriptor
}

function Update-HermesEnterpriseSessionStatus {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][string]$RutaRaizRepositorio,
        [Parameter(Mandatory = $true)][psobject]$SessionDescriptor,
        [Parameter(Mandatory = $true)][string]$EstadoSesion
    )
    $SessionDescriptor.EstadoSesion = $EstadoSesion
    [void]($SessionDescriptor.UltimaActividad = Get-Date)
    $null = Write-HermesEnterpriseSessionEvent -SessionDescriptor $SessionDescriptor -Operacion "StatusUpdated" -Mensaje "Estado actualizado a $EstadoSesion."
    $null = Save-HermesEnterpriseSession -RutaRaizRepositorio $RutaRaizRepositorio -SessionDescriptor $SessionDescriptor
    return $SessionDescriptor
}

function Get-HermesEnterpriseSessionSummary {
    [CmdletBinding()][OutputType([pscustomobject])]
    param([Parameter(Mandatory = $true)][psobject]$SessionDescriptor)
    return [pscustomobject][ordered]@{
        IdentificadorSesion = $SessionDescriptor.IdentificadorSesion
        NombreProyecto = $SessionDescriptor.NombreProyecto
        RutaWorkspace = $SessionDescriptor.RutaWorkspace
        BranchActual = $SessionDescriptor.BranchActual
        ProveedorIA = $SessionDescriptor.ProveedorIA
        ModeloIA = $SessionDescriptor.ModeloIA
        EstadoSesion = $SessionDescriptor.EstadoSesion
        UltimaActividad = $SessionDescriptor.UltimaActividad
        TotalEventos = if ($null -eq $SessionDescriptor.Historial) { 0 } else { $SessionDescriptor.Historial.Count }
    }
}
