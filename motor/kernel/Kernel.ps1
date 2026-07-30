<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Kernel.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Define el Kernel Enterprise y coordina su ciclo de vida principal.
====================================================================================================
#>

Set-StrictMode -Version Latest

function New-HermesEnterpriseKernel {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$ContextoKernel)

    return [pscustomobject][ordered]@{
        ContextoKernel = $ContextoKernel
        EstadoKernel = "Creado"
        AdministradorConfiguracion = $null
        Configuracion = $null
        RegistroModulos = $null
        ContenedorDependencias = $null
        LocalizadorServicios = $null
        Logger = $null
        EventBus = $null
        Runtime = $null
        PluginManager = $null
        ErroresArranque = @()
    }
}

function Start-HermesEnterpriseKernel {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$KernelEnterprise)

    $HoraInicioArranqueKernel = Get-Date

    if ($KernelEnterprise.EstadoKernel -eq "Iniciado") {
        return $KernelEnterprise
    }

    $RutaConfiguracionKernel = Join-Path $KernelEnterprise.ContextoKernel.RutaConfiguracion "kernel.enterprise.json"
    $RutaLogKernel = Join-Path $KernelEnterprise.ContextoKernel.RutaLogs "kernel.enterprise.jsonl"

    # --- Inicialización de subsistemas con try/catch individual ---
    try {
        $KernelEnterprise.AdministradorConfiguracion = New-HermesEnterpriseConfigurationManager -RutaArchivoConfiguracion $RutaConfiguracionKernel
    } catch {
        Write-Error "[Kernel] Error al crear ConfigurationManager: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "ConfigurationManager"; Error = $_.Exception.Message }
    }

    try {
        $KernelEnterprise.Configuracion = Get-HermesEnterpriseConfiguration -AdministradorConfiguracion $KernelEnterprise.AdministradorConfiguracion
    } catch {
        Write-Error "[Kernel] Error al obtener configuración: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Configuration"; Error = $_.Exception.Message }
    }

    try {
        $KernelEnterprise.RegistroModulos = New-HermesEnterpriseModuleRegistry
    } catch {
        Write-Error "[Kernel] Error al crear ModuleRegistry: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "ModuleRegistry"; Error = $_.Exception.Message }
    }

    try {
        $KernelEnterprise.ContenedorDependencias = New-HermesEnterpriseDependencyContainer
    } catch {
        Write-Error "[Kernel] Error al crear DependencyContainer: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "DependencyContainer"; Error = $_.Exception.Message }
    }

    try {
        $KernelEnterprise.LocalizadorServicios = New-HermesEnterpriseServiceLocator -ContenedorDependencias $KernelEnterprise.ContenedorDependencias
    } catch {
        Write-Error "[Kernel] Error al crear ServiceLocator: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "ServiceLocator"; Error = $_.Exception.Message }
    }

    try {
        $KernelEnterprise.Logger = New-HermesEnterpriseLogger -RutaArchivoLog $RutaLogKernel -NombreComponente "Kernel"
    } catch {
        Write-Error "[Kernel] Error al crear Logger: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Logger"; Error = $_.Exception.Message }
    }

    try {
        $KernelEnterprise.EventBus = New-HermesEnterpriseEventBus
    } catch {
        Write-Error "[Kernel] Error al crear EventBus: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "EventBus"; Error = $_.Exception.Message }
    }

    try {
        $KernelEnterprise.Runtime = New-HermesEnterpriseRuntime -EventBusKernel $KernelEnterprise.EventBus
    } catch {
        Write-Error "[Kernel] Error al crear Runtime: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Runtime"; Error = $_.Exception.Message }
    }

    try {
        $KernelEnterprise.PluginManager = New-HermesEnterprisePluginManager -RutaRaizRepositorio $KernelEnterprise.ContextoKernel.RutaRaizRepositorio -VersionKernelActual $KernelEnterprise.ContextoKernel.VersionKernel
    } catch {
        Write-Error "[Kernel] Error al crear PluginManager: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "PluginManager"; Error = $_.Exception.Message }
    }

    # --- Registro de servicios con try/catch individual ---
    try {
        Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "ConfigurationManager" -InstanciaServicio $KernelEnterprise.AdministradorConfiguracion | Out-Null
    } catch {
        Write-Error "[Kernel] Error al registrar ConfigurationManager: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Register.ConfigurationManager"; Error = $_.Exception.Message }
    }

    try {
        Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "ModuleRegistry" -InstanciaServicio $KernelEnterprise.RegistroModulos | Out-Null
    } catch {
        Write-Error "[Kernel] Error al registrar ModuleRegistry: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Register.ModuleRegistry"; Error = $_.Exception.Message }
    }

    try {
        Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "Logger" -InstanciaServicio $KernelEnterprise.Logger | Out-Null
    } catch {
        Write-Error "[Kernel] Error al registrar Logger: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Register.Logger"; Error = $_.Exception.Message }
    }

    try {
        Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "EventBus" -InstanciaServicio $KernelEnterprise.EventBus | Out-Null
    } catch {
        Write-Error "[Kernel] Error al registrar EventBus: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Register.EventBus"; Error = $_.Exception.Message }
    }

    try {
        Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "Runtime" -InstanciaServicio $KernelEnterprise.Runtime | Out-Null
    } catch {
        Write-Error "[Kernel] Error al registrar Runtime: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Register.Runtime"; Error = $_.Exception.Message }
    }

    try {
        Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "PluginManager" -InstanciaServicio $KernelEnterprise.PluginManager | Out-Null
    } catch {
        Write-Error "[Kernel] Error al registrar PluginManager: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Register.PluginManager"; Error = $_.Exception.Message }
    }

    try {
        Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "KernelHealth" -InstanciaServicio (New-HermesEnterpriseKernelHealthMonitor) | Out-Null
    } catch {
        Write-Error "[Kernel] Error al registrar KernelHealth: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Register.KernelHealth"; Error = $_.Exception.Message }
    }

    try {
        Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "KernelMetrics" -InstanciaServicio (New-HermesEnterpriseKernelMetricsCollector) | Out-Null
    } catch {
        Write-Error "[Kernel] Error al registrar KernelMetrics: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Register.KernelMetrics"; Error = $_.Exception.Message }
    }

    # --- Registro de módulo ---
    try {
        Register-HermesEnterpriseModule -RegistroModulos $KernelEnterprise.RegistroModulos -NombreModulo "Kernel" -VersionModulo $KernelEnterprise.ContextoKernel.VersionKernel -RutaModulo "motor/kernel" -CapacidadesModulo @("Bootstrap", "Runtime", "Servicios") | Out-Null
    } catch {
        Write-Error "[Kernel] Error al registrar módulo Kernel: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "Register.Module"; Error = $_.Exception.Message }
    }

    # --- Inicialización de plugins ---
    try {
        Initialize-HermesEnterprisePlugins -AdministradorPlugins $KernelEnterprise.PluginManager | Out-Null
    } catch {
        Write-Error "[Kernel] Error al inicializar plugins: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "PluginInitialization"; Error = $_.Exception.Message }
    }

    # --- Inicio de Runtime ---
    try {
        Start-HermesEnterpriseRuntime -RuntimeKernel $KernelEnterprise.Runtime | Out-Null
    } catch {
        Write-Error "[Kernel] Error al iniciar Runtime: $($_.Exception.Message)"
        $KernelEnterprise.ErroresArranque += @{ Subsistema = "RuntimeStart"; Error = $_.Exception.Message }
    }

    # --- Métricas finales ---
    $CantidadErrores = $KernelEnterprise.ErroresArranque.Count
    $EstadoFinal = if ($CantidadErrores -gt 0) { "OperativoConErrores" } else { "Operativo" }

    try {
        Write-HermesEnterpriseKernelMetric `
            -KernelEnterprise $KernelEnterprise `
            -NombreComponente "Kernel" `
            -NombreOperacion "Kernel.Start" `
            -HoraInicio $HoraInicioArranqueKernel `
            -HoraFin (Get-Date) `
            -CantidadErrores $CantidadErrores `
            -CantidadAdvertencias 0 `
            -Estado $EstadoFinal | Out-Null
    } catch {
        Write-Error "[Kernel] Error al registrar métricas: $($_.Exception.Message)"
    }

    try {
        Write-HermesEnterpriseLogEvent -LoggerKernel $KernelEnterprise.Logger -Nivel "INFO" -Mensaje "Kernel Enterprise iniciado" -DatosEvento @{ VersionKernel = $KernelEnterprise.ContextoKernel.VersionKernel; ErroresArranque = $CantidadErrores } | Out-Null
    } catch {
        Write-Error "[Kernel] Error al escribir log de inicio: $($_.Exception.Message)"
    }

    try {
        Publish-HermesEnterpriseEvent -EventBusKernel $KernelEnterprise.EventBus -NombreEvento "Kernel.Iniciado" -DatosEvento @{ VersionKernel = $KernelEnterprise.ContextoKernel.VersionKernel; ErroresArranque = $CantidadErrores } | Out-Null
    } catch {
        Write-Error "[Kernel] Error al publicar evento de inicio: $($_.Exception.Message)"
    }

    $KernelEnterprise.EstadoKernel = $EstadoFinal
    return $KernelEnterprise
}

function Stop-HermesEnterpriseKernel {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$KernelEnterprise)

    if ($KernelEnterprise.EstadoKernel -ne "Detenido" -and $KernelEnterprise.EstadoKernel -ne $null) {
        if ($null -ne $KernelEnterprise.Runtime) {
            try {
                Stop-HermesEnterpriseRuntime -RuntimeKernel $KernelEnterprise.Runtime | Out-Null
            } catch {
                Write-Error "[Kernel] Error al detener Runtime: $($_.Exception.Message)"
            }
        }

        if ($null -ne $KernelEnterprise.Logger) {
            try {
                Write-HermesEnterpriseLogEvent -LoggerKernel $KernelEnterprise.Logger -Nivel "INFO" -Mensaje "Kernel Enterprise detenido" -DatosEvento @{} | Out-Null
            } catch {
                Write-Error "[Kernel] Error al escribir log de detención: $($_.Exception.Message)"
            }
        }

        $KernelEnterprise.EstadoKernel = "Detenido"
    }

    return $KernelEnterprise
}