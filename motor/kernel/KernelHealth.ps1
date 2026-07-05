<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : KernelHealth.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Implementa el Health Monitor mínimo del Kernel Enterprise para consultar el estado operativo
    de los componentes base sin modificar su ciclo de vida ni sus contratos públicos existentes.

Características:
    - Cero dependencias externas.
    - Lectura no intrusiva del objeto Kernel Enterprise.
    - Compatible con la arquitectura incremental de Fase 1.
    - Diseñado para ser registrado como servicio interno KernelHealth.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseKernelHealthMonitor {
    [CmdletBinding()]
    param()

    # El monitor se modela como objeto explícito para permitir evolución futura sin cambiar la
    # firma pública Get-HermesEnterpriseKernelHealth. En esta primera iteración no mantiene estado.
    return [pscustomobject][ordered]@{
        NombreComponente = "KernelHealth"
        VersionComponente = "1.0.0"
        FechaCreacion = (Get-Date).ToString("o")
    }
}

function Get-HermesEnterpriseKernelHealth {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNull()]
        [psobject]$KernelEnterprise
    )

    # El Health Monitor no arranca ni detiene componentes; únicamente interpreta el estado actual
    # del Kernel y devuelve un objeto diagnóstico estable para pruebas, soporte y observabilidad.
    $EstadoRuntime = "NoDisponible"
    if ($null -ne $KernelEnterprise.Runtime -and -not [string]::IsNullOrWhiteSpace($KernelEnterprise.Runtime.EstadoRuntime)) {
        $EstadoRuntime = $KernelEnterprise.Runtime.EstadoRuntime
    }

    $EstadoLogger = "NoDisponible"
    if ($null -ne $KernelEnterprise.Logger -and -not [string]::IsNullOrWhiteSpace($KernelEnterprise.Logger.RutaArchivoLog)) {
        $EstadoLogger = "Operativo"
    }

    $EstadoEventBus = "NoDisponible"
    if ($null -ne $KernelEnterprise.EventBus -and $null -ne $KernelEnterprise.EventBus.EventosPublicados) {
        $EstadoEventBus = "Operativo"
    }

    $EstadoConfiguracion = "NoDisponible"
    if ($null -ne $KernelEnterprise.AdministradorConfiguracion -and $null -ne $KernelEnterprise.Configuracion) {
        $EstadoConfiguracion = "Operativo"
    }

    $EstadoPlugins = "NoDisponible"
    $CantidadPluginsCargados = 0
    if ($null -ne $KernelEnterprise.PluginManager -and $null -ne $KernelEnterprise.PluginManager.PluginsCargados) {
        $EstadoPlugins = "Operativo"
        $CantidadPluginsCargados = $KernelEnterprise.PluginManager.PluginsCargados.Count
    }

    $UsoMemoriaBytes = [System.GC]::GetTotalMemory($false)
    $EstadoMemoria = "Operativo"
    if ($UsoMemoriaBytes -gt 536870912) {
        $EstadoMemoria = "Advertencia"
    }

    return [pscustomobject][ordered]@{
        NombreComponente = "KernelHealth"
        EstadoGeneral = "Operativo"
        EstadoKernel = $KernelEnterprise.EstadoKernel
        EstadoRuntime = $EstadoRuntime
        EstadoPlugins = $EstadoPlugins
        EstadoLogger = $EstadoLogger
        EstadoEventBus = $EstadoEventBus
        EstadoConfiguracion = $EstadoConfiguracion
        EstadoMemoria = $EstadoMemoria
        UsoMemoriaBytes = $UsoMemoriaBytes
        CantidadPluginsCargados = $CantidadPluginsCargados
        FechaConsulta = (Get-Date).ToString("o")
    }
}
