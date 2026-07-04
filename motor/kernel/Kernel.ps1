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
    }
}

function Start-HermesEnterpriseKernel {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$KernelEnterprise)

    if ($KernelEnterprise.EstadoKernel -eq "Iniciado") {
        return $KernelEnterprise
    }

    $RutaConfiguracionKernel = Join-Path $KernelEnterprise.ContextoKernel.RutaConfiguracion "kernel.enterprise.json"
    $RutaLogKernel = Join-Path $KernelEnterprise.ContextoKernel.RutaLogs "kernel.enterprise.jsonl"

    $KernelEnterprise.AdministradorConfiguracion = New-HermesEnterpriseConfigurationManager -RutaArchivoConfiguracion $RutaConfiguracionKernel
    $KernelEnterprise.Configuracion = Get-HermesEnterpriseConfiguration -AdministradorConfiguracion $KernelEnterprise.AdministradorConfiguracion
    $KernelEnterprise.RegistroModulos = New-HermesEnterpriseModuleRegistry
    $KernelEnterprise.ContenedorDependencias = New-HermesEnterpriseDependencyContainer
    $KernelEnterprise.LocalizadorServicios = New-HermesEnterpriseServiceLocator -ContenedorDependencias $KernelEnterprise.ContenedorDependencias
    $KernelEnterprise.Logger = New-HermesEnterpriseLogger -RutaArchivoLog $RutaLogKernel -NombreComponente "Kernel"
    $KernelEnterprise.EventBus = New-HermesEnterpriseEventBus
    $KernelEnterprise.Runtime = New-HermesEnterpriseRuntime -EventBusKernel $KernelEnterprise.EventBus

    Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "ConfigurationManager" -InstanciaServicio $KernelEnterprise.AdministradorConfiguracion | Out-Null
    Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "ModuleRegistry" -InstanciaServicio $KernelEnterprise.RegistroModulos | Out-Null
    Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "Logger" -InstanciaServicio $KernelEnterprise.Logger | Out-Null
    Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "EventBus" -InstanciaServicio $KernelEnterprise.EventBus | Out-Null
    Register-HermesEnterpriseService -ContenedorDependencias $KernelEnterprise.ContenedorDependencias -NombreServicio "Runtime" -InstanciaServicio $KernelEnterprise.Runtime | Out-Null

    Register-HermesEnterpriseModule -RegistroModulos $KernelEnterprise.RegistroModulos -NombreModulo "Kernel" -VersionModulo $KernelEnterprise.ContextoKernel.VersionKernel -RutaModulo "motor/kernel" -CapacidadesModulo @("Bootstrap", "Runtime", "Servicios") | Out-Null

    Start-HermesEnterpriseRuntime -RuntimeKernel $KernelEnterprise.Runtime | Out-Null
    Write-HermesEnterpriseLogEvent -LoggerKernel $KernelEnterprise.Logger -Nivel "INFO" -Mensaje "Kernel Enterprise iniciado" -DatosEvento @{ VersionKernel = $KernelEnterprise.ContextoKernel.VersionKernel } | Out-Null
    Publish-HermesEnterpriseEvent -EventBusKernel $KernelEnterprise.EventBus -NombreEvento "Kernel.Iniciado" -DatosEvento @{ VersionKernel = $KernelEnterprise.ContextoKernel.VersionKernel } | Out-Null

    $KernelEnterprise.EstadoKernel = "Iniciado"
    return $KernelEnterprise
}

function Stop-HermesEnterpriseKernel {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][psobject]$KernelEnterprise)

    if ($KernelEnterprise.EstadoKernel -ne "Detenido") {
        if ($null -ne $KernelEnterprise.Runtime) {
            Stop-HermesEnterpriseRuntime -RuntimeKernel $KernelEnterprise.Runtime | Out-Null
        }

        if ($null -ne $KernelEnterprise.Logger) {
            Write-HermesEnterpriseLogEvent -LoggerKernel $KernelEnterprise.Logger -Nivel "INFO" -Mensaje "Kernel Enterprise detenido" -DatosEvento @{} | Out-Null
        }

        $KernelEnterprise.EstadoKernel = "Detenido"
    }

    return $KernelEnterprise
}
