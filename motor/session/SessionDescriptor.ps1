<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : SessionDescriptor.ps1
Propósito:
    Representa una sesión de desarrollo HERMES Enterprise como objeto raíz portátil.
====================================================================================================
#>
Set-StrictMode -Version Latest

function New-HermesEnterpriseSessionDescriptor {
    [CmdletBinding()][OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory=$true)][ValidateNotNullOrEmpty()][string]$IdentificadorSesion,
        [Parameter(Mandatory=$false)][string]$NombreProyecto = "",
        [Parameter(Mandatory=$false)][string]$RutaWorkspace = "",
        [Parameter(Mandatory=$false)][string]$RepositorioGit = "",
        [Parameter(Mandatory=$false)][string]$BranchActual = "main",
        [Parameter(Mandatory=$false)][string]$ProveedorIA = "AzureFoundryProvider",
        [Parameter(Mandatory=$false)][string]$ModeloIA = "ur-hermes-mini",
        [Parameter(Mandatory=$false)][string[]]$PluginsInstalados = @(),
        [Parameter(Mandatory=$false)][hashtable]$ConfiguracionActiva = @{},
        [Parameter(Mandatory=$false)][datetime]$FechaCreacion = (Get-Date),
        [Parameter(Mandatory=$false)][datetime]$UltimaActividad = (Get-Date),
        [Parameter(Mandatory=$false)][string]$VersionHermes = "0.7.0",
        [Parameter(Mandatory=$false)][string]$EstadoSesion = "Created",
        [Parameter(Mandatory=$false)][string]$Usuario = $env:USERNAME,
        [Parameter(Mandatory=$false)][System.Collections.Generic.List[psobject]]$Historial = (New-Object System.Collections.Generic.List[psobject]),
        [Parameter(Mandatory=$false)][psobject]$Contexto = $null
    )
    return [pscustomobject][ordered]@{
        IdentificadorSesion = $IdentificadorSesion
        NombreProyecto = $NombreProyecto
        RutaWorkspace = $RutaWorkspace
        RepositorioGit = $RepositorioGit
        BranchActual = $BranchActual
        ProveedorIA = $ProveedorIA
        ModeloIA = $ModeloIA
        PluginsInstalados = $PluginsInstalados
        ConfiguracionActiva = $ConfiguracionActiva
        FechaCreacion = $FechaCreacion
        UltimaActividad = $UltimaActividad
        VersionHermes = $VersionHermes
        EstadoSesion = $EstadoSesion
        Usuario = $Usuario
        Historial = $Historial
        Contexto = $Contexto
    }
}
