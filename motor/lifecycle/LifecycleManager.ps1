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
        EstadoSandbox = "Created"
        EstadosEjecutados = New-Object System.Collections.Generic.List[string]
        ErroresSandbox = New-Object System.Collections.Generic.List[object]
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

    $EtapaSandbox = "Install"

    try {
        # Sandbox v1: aislamiento lógico mínimo. El plugin se ejecuta en el mismo proceso,
        # pero cualquier error del ciclo de vida queda capturado en el contexto del plugin
        # para evitar que un plugin defectuoso detenga al PluginManager o al Kernel.
        $ContextoPlugin.EstadoSandbox = "Running"

        & "Install-$NombrePlugin" $ContextoPlugin | Out-Null
        $EtapaSandbox = "Initialize"
        & "Initialize-$NombrePlugin" $ContextoPlugin | Out-Null
        $EtapaSandbox = "Start"
        & "Start-$NombrePlugin" $ContextoPlugin | Out-Null

        if (-not $MantenerIniciado.IsPresent) {
            $EtapaSandbox = "Stop"
            & "Stop-$NombrePlugin" $ContextoPlugin | Out-Null
            $EtapaSandbox = "Dispose"
            & "Dispose-$NombrePlugin" $ContextoPlugin | Out-Null
        }

        $ContextoPlugin.EstadoSandbox = "Healthy"
    }
    catch {
        $ContextoPlugin.EstadoActual = "Faulted"
        $ContextoPlugin.EstadoSandbox = "Faulted"
        $ContextoPlugin.ErroresSandbox.Add([pscustomobject][ordered]@{
            Etapa = $EtapaSandbox
            TipoError = $_.Exception.GetType().FullName
            Mensaje = $_.Exception.Message
        }) | Out-Null
    }

    return $ContextoPlugin
}
