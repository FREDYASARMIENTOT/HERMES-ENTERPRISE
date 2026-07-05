<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : KernelValidator.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Ejecuta validaciones estructurales mínimas sobre el Kernel Enterprise.
====================================================================================================
#>

Set-StrictMode -Version Latest

function Test-HermesEnterpriseKernel {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$KernelEnterprise)

    $ErroresValidacionKernel = New-Object System.Collections.Generic.List[string]

    if ($KernelEnterprise.EstadoKernel -ne "Iniciado") { $ErroresValidacionKernel.Add("El Kernel no está iniciado.") }
    if ($null -eq $KernelEnterprise.Runtime) { $ErroresValidacionKernel.Add("Runtime no inicializado.") }
    if ($null -eq $KernelEnterprise.Logger) { $ErroresValidacionKernel.Add("Logger no inicializado.") }
    if ($null -eq $KernelEnterprise.EventBus) { $ErroresValidacionKernel.Add("EventBus no inicializado.") }
    if ($null -eq $KernelEnterprise.RegistroModulos) { $ErroresValidacionKernel.Add("ModuleRegistry no inicializado.") }
    if ($null -eq $KernelEnterprise.PluginManager) { $ErroresValidacionKernel.Add("PluginManager no inicializado.") }

    return [pscustomobject][ordered]@{
        EsValido = ($ErroresValidacionKernel.Count -eq 0)
        Errores = @($ErroresValidacionKernel)
    }
}

function Test-HermesEnterpriseKernelReady {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$KernelEnterprise)

    $ServiciosRequeridosKernelEnterprise = @(
        "ConfigurationManager",
        "Logger",
        "Runtime",
        "EventBus",
        "PluginManager",
        "KernelHealth",
        "KernelMetrics"
    )

    $ServiciosFaltantesKernelEnterprise = New-Object System.Collections.Generic.List[string]

    if ($null -eq $KernelEnterprise.ContenedorDependencias -or $null -eq $KernelEnterprise.ContenedorDependencias.ServiciosRegistrados) {
        foreach ($NombreServicioRequerido in $ServiciosRequeridosKernelEnterprise) {
            $ServiciosFaltantesKernelEnterprise.Add($NombreServicioRequerido)
        }
    }
    else {
        foreach ($NombreServicioRequerido in $ServiciosRequeridosKernelEnterprise) {
            if (-not $KernelEnterprise.ContenedorDependencias.ServiciosRegistrados.ContainsKey($NombreServicioRequerido)) {
                $ServiciosFaltantesKernelEnterprise.Add($NombreServicioRequerido)
            }
        }
    }

    return [pscustomobject][ordered]@{
        EsValido = ($ServiciosFaltantesKernelEnterprise.Count -eq 0)
        Estado = if ($ServiciosFaltantesKernelEnterprise.Count -eq 0) { "OK" } else { "ServiciosFaltantes" }
        ServiciosFaltantes = $ServiciosFaltantesKernelEnterprise.ToArray()
        ServiciosRequeridos = $ServiciosRequeridosKernelEnterprise
    }
}

function Get-HermesEnterpriseKernelSummary {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$KernelEnterprise)

    $CantidadServiciosRegistrados = 0
    if ($null -ne $KernelEnterprise.ContenedorDependencias -and $null -ne $KernelEnterprise.ContenedorDependencias.ServiciosRegistrados) {
        $CantidadServiciosRegistrados = $KernelEnterprise.ContenedorDependencias.ServiciosRegistrados.Count
    }

    $CantidadPluginsCargados = 0
    if ($null -ne $KernelEnterprise.PluginManager -and $null -ne $KernelEnterprise.PluginManager.PluginsCargados) {
        $CantidadPluginsCargados = $KernelEnterprise.PluginManager.PluginsCargados.Count
    }

    $CantidadEventosPublicados = 0
    if ($null -ne $KernelEnterprise.EventBus -and $null -ne $KernelEnterprise.EventBus.EventosPublicados) {
        $CantidadEventosPublicados = $KernelEnterprise.EventBus.EventosPublicados.Count
    }

    $CantidadMetricasRegistradas = 0
    if ($null -ne $KernelEnterprise.Logger -and -not [string]::IsNullOrWhiteSpace($KernelEnterprise.Logger.RutaArchivoLog) -and (Test-Path -Path $KernelEnterprise.Logger.RutaArchivoLog)) {
        $ContenidoLogKernelEnterprise = Get-Content -Path $KernelEnterprise.Logger.RutaArchivoLog -Raw
        $CantidadMetricasRegistradas = ([regex]::Matches($ContenidoLogKernelEnterprise, '"TipoRegistro":"MetricaKernel"')).Count
    }

    return [pscustomobject][ordered]@{
        VersionKernel = $KernelEnterprise.ContextoKernel.VersionKernel
        EstadoKernel = $KernelEnterprise.EstadoKernel
        EstadoRuntime = if ($null -ne $KernelEnterprise.Runtime) { $KernelEnterprise.Runtime.EstadoRuntime } else { "NoDisponible" }
        ServiciosRegistrados = $CantidadServiciosRegistrados
        PluginsCargados = $CantidadPluginsCargados
        EventosPublicados = $CantidadEventosPublicados
        MetricasRegistradas = $CantidadMetricasRegistradas
        FechaResumen = (Get-Date).ToString("o")
    }
}
