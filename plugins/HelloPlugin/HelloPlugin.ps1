<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : HelloPlugin.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Plugin de ejemplo para validar el Enterprise Plugin Framework sin integrar proveedores reales.
====================================================================================================
#>
Set-StrictMode -Version Latest

function Install-HelloPlugin {
    param([Parameter(Mandatory = $true)][psobject]$ContextoPlugin)
    $ContextoPlugin.EstadosEjecutados.Add("Installed")
    $ContextoPlugin.EstadoActual = "Installed"
    return $ContextoPlugin
}

function Initialize-HelloPlugin {
    param([Parameter(Mandatory = $true)][psobject]$ContextoPlugin)
    $ContextoPlugin.EstadosEjecutados.Add("Initialized")
    $ContextoPlugin.EstadoActual = "Initialized"
    return $ContextoPlugin
}

function Start-HelloPlugin {
    param([Parameter(Mandatory = $true)][psobject]$ContextoPlugin)
    $ContextoPlugin.EstadosEjecutados.Add("Started")
    $ContextoPlugin.EstadoActual = "Started"
    $ContextoPlugin.ServiciosRegistrados["HelloService"] = [pscustomobject]@{ Nombre = "HelloService"; Mensaje = "Hola desde HelloPlugin" }
    $ContextoPlugin.ProveedoresRegistrados["HelloProvider"] = [pscustomobject]@{ Nombre = "HelloProvider"; Plugin = "HelloPlugin" }
    return $ContextoPlugin
}

function Pause-HelloPlugin {
    param([Parameter(Mandatory = $true)][psobject]$ContextoPlugin)
    $ContextoPlugin.EstadosEjecutados.Add("Paused")
    $ContextoPlugin.EstadoActual = "Paused"
    return $ContextoPlugin
}

function Resume-HelloPlugin {
    param([Parameter(Mandatory = $true)][psobject]$ContextoPlugin)
    $ContextoPlugin.EstadosEjecutados.Add("Resumed")
    $ContextoPlugin.EstadoActual = "Resumed"
    return $ContextoPlugin
}

function Stop-HelloPlugin {
    param([Parameter(Mandatory = $true)][psobject]$ContextoPlugin)
    $ContextoPlugin.EstadosEjecutados.Add("Stopped")
    $ContextoPlugin.EstadoActual = "Stopped"
    return $ContextoPlugin
}

function Dispose-HelloPlugin {
    param([Parameter(Mandatory = $true)][psobject]$ContextoPlugin)
    $ContextoPlugin.EstadosEjecutados.Add("Disposed")
    $ContextoPlugin.EstadoActual = "Disposed"
    return $ContextoPlugin
}
