<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : LifecycleManager.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Ejecuta el ciclo de vida estándar de plugins Enterprise.
====================================================================================================
#>
Set-StrictMode -Version Latest

$RutaDirectorioLifecycleManager = Split-Path -Parent $PSCommandPath
$RutaDirectorioMotorLifecycle = Split-Path -Parent $RutaDirectorioLifecycleManager
. (Join-Path $RutaDirectorioMotorLifecycle "plugins\PluginLoader.ps1")

function New-HermesEnterprisePluginLifecycleContext {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$PluginDescubierto)

    return [pscustomobject][ordered]@{
        NombrePlugin = $PluginDescubierto.Manifest.Nombre
        Manifest = $PluginDescubierto.Manifest
        RutaDirectorioPlugin = $PluginDescubierto.RutaDirectorioPlugin
        EstadoActual = "Created"
        EstadosEjecutados = New-Object System.Collections.Generic.List[string]
        ServiciosRegistrados = @{}
        ProveedoresRegistrados = @{}
    }
}

function Invoke-HermesEnterprisePluginLifecycle {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$PluginDescubierto,
        [Parameter(Mandatory = $false)][switch]$MantenerIniciado
    )

    Import-HermesEnterprisePluginScript -RutaScriptPlugin $PluginDescubierto.RutaScriptPlugin | Out-Null
    $ContextoPlugin = New-HermesEnterprisePluginLifecycleContext -PluginDescubierto $PluginDescubierto
    $NombrePlugin = $PluginDescubierto.Manifest.Nombre

    & "Install-$NombrePlugin" $ContextoPlugin | Out-Null
    & "Initialize-$NombrePlugin" $ContextoPlugin | Out-Null
    & "Start-$NombrePlugin" $ContextoPlugin | Out-Null

    if (-not $MantenerIniciado.IsPresent) {
        & "Stop-$NombrePlugin" $ContextoPlugin | Out-Null
        & "Dispose-$NombrePlugin" $ContextoPlugin | Out-Null
    }

    return $ContextoPlugin
}
