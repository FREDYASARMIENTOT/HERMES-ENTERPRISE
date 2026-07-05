<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : PluginFaultPolicy.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Define la política explícita para manejar plugins que fallan durante el ciclo de vida.
    Fase 2.4: no implementa retry, recovery automático ni aislamiento pesado.
====================================================================================================
#>
Set-StrictMode -Version Latest

function New-HermesEnterprisePluginFaultPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $false)]
        [ValidateSet("Continue", "Disable", "Abort")]
        [string]$AccionPorDefecto = "Continue"
    )

    return [pscustomobject][ordered]@{
        AccionPorDefecto = $AccionPorDefecto
        AccionesPermitidas = @("Continue", "Disable", "Abort")
        RetryHabilitado = $false
        RecoveryAutomaticoHabilitado = $false
    }
}

function Invoke-HermesEnterprisePluginFaultPolicy {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][psobject]$ContextoPlugin,
        [Parameter(Mandatory = $true)][psobject]$PoliticaFallaPlugin
    )

    $AccionFallaPlugin = $PoliticaFallaPlugin.AccionPorDefecto
    $ContextoPlugin.AccionFallaPlugin = $AccionFallaPlugin

    switch ($AccionFallaPlugin) {
        "Continue" {
            $ContextoPlugin.PluginDeshabilitado = $false
            return $ContextoPlugin
        }
        "Disable" {
            $ContextoPlugin.PluginDeshabilitado = $true
            return $ContextoPlugin
        }
        "Abort" {
            $MensajeFallaPlugin = "Política Abort aplicada al plugin $($ContextoPlugin.NombrePlugin) en estado Faulted."
            throw $MensajeFallaPlugin
        }
        default {
            throw "Acción de política de falla de plugin no soportada: $AccionFallaPlugin"
        }
    }
}
