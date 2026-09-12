<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Kernel.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida el comportamiento central del Kernel Enterprise usando mocks para subsistemas
    no implementados.
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$global:HERMES_REPO_ROOT = "D:\HERMES-ENTERPRISE"

# ---------------------------------------------------------------------------
# Mocks de funciones que Kernel.ps1 llama pero que no están implementadas
# ---------------------------------------------------------------------------
function New-HermesEnterpriseConfigurationManager {
    param([string]$RutaArchivoConfiguracion)
    return [pscustomobject]@{ Ruta = $RutaArchivoConfiguracion }
}

function Get-HermesEnterpriseConfiguration {
    param($AdministradorConfiguracion)
    return [pscustomobject]@{ config = "mock" }
}

function New-HermesEnterpriseModuleRegistry {
    return [pscustomobject]@{ modules = @() }
}

function New-HermesEnterpriseDependencyContainer {
    return [pscustomobject]@{ services = @{} }
}

function New-HermesEnterpriseServiceLocator {
    param($ContenedorDependencias)
    return [pscustomobject]@{ container = $ContenedorDependencias }
}

function New-HermesEnterpriseLogger {
    param([string]$RutaArchivoLog, [string]$NombreComponente)
    return [pscustomobject]@{ ruta = $RutaArchivoLog; componente = $NombreComponente }
}

function New-HermesEnterpriseEventBus {
    return [pscustomobject]@{ }
}

function New-HermesEnterpriseRuntime {
    param($EventBusKernel)
    return [pscustomobject]@{ eventBus = $EventBusKernel; running = $false }
}

function New-HermesEnterprisePluginManager {
    param($RutaRaizRepositorio, $VersionKernelActual)
    return [pscustomobject]@{ root = $RutaRaizRepositorio; version = $VersionKernelActual }
}

function New-HermesEnterpriseKernelHealthMonitor {
    return [pscustomobject]@{ healthy = $true }
}

function New-HermesEnterpriseKernelMetricsCollector {
    return [pscustomobject]@{ metrics = @{} }
}

function Register-HermesEnterpriseService {
    param($ContenedorDependencias, $NombreServicio, $InstanciaServicio)
    $ContenedorDependencias.services[$NombreServicio] = $InstanciaServicio
}

function Register-HermesEnterpriseModule {
    param($RegistroModulos, $NombreModulo, $VersionModulo, $RutaModulo, $CapacidadesModulo)
    $RegistroModulos.modules += @{ nombre = $NombreModulo; version = $VersionModulo; ruta = $RutaModulo; capacidades = $CapacidadesModulo }
}

function Initialize-HermesEnterprisePlugins {
    param($AdministradorPlugins)
}

function Start-HermesEnterpriseRuntime {
    param($RuntimeKernel)
    $RuntimeKernel.running = $true
}

function Stop-HermesEnterpriseRuntime {
    param($RuntimeKernel)
    $RuntimeKernel.running = $false
}

function Write-HermesEnterpriseLogEvent {
    param($LoggerKernel, $Nivel, $Mensaje, $DatosEvento)
}

function Publish-HermesEnterpriseEvent {
    param($EventBusKernel, $NombreEvento, $DatosEvento)
}

function Write-HermesEnterpriseKernelMetric {
    param($KernelEnterprise, $NombreComponente, $NombreOperacion, $HoraInicio, $HoraFin, $CantidadErrores, $CantidadAdvertencias, $Estado)
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
Describe "Kernel" -Tag "Core" {

    It "ContextoKernel debe crearse correctamente con el nombre del proyecto" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\KernelContext.ps1")
        $ContextoKernel = New-HermesEnterpriseKernelContext -RutaRaizRepositorio $global:HERMES_REPO_ROOT -NombreEntorno "Pruebas"
        $ContextoKernel.NombreProyecto | Should Be "HERMES-ENTERPRISE"
        $ContextoKernel.NombreEntorno | Should Be "Pruebas"
        $ContextoKernel.IdentificadorContexto | Should Not BeNullOrEmpty
    }

    It "Debe iniciar en estado Creado" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\KernelContext.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Kernel.ps1")
        $ContextoKernel = New-HermesEnterpriseKernelContext -RutaRaizRepositorio $global:HERMES_REPO_ROOT -NombreEntorno "Pruebas"
        $Kernel = New-HermesEnterpriseKernel -ContextoKernel $ContextoKernel
        $Kernel.EstadoKernel | Should Be "Creado"
    }

    It "Debe arrancar y alcanzar estado Operativo" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\KernelContext.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Kernel.ps1")
        $ContextoKernel = New-HermesEnterpriseKernelContext -RutaRaizRepositorio $global:HERMES_REPO_ROOT -NombreEntorno "Pruebas"
        $Kernel = New-HermesEnterpriseKernel -ContextoKernel $ContextoKernel
        Start-HermesEnterpriseKernel -KernelEnterprise $Kernel | Out-Null
        $Kernel.EstadoKernel | Should Match "^(Operativo|Iniciado|OperativoConErrores)$"
    }

    It "Debe detenerse correctamente y quedar en estado Detenido" {
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\KernelContext.ps1")
        . (Join-Path $global:HERMES_REPO_ROOT "motor\kernel\Kernel.ps1")
        $ContextoKernel = New-HermesEnterpriseKernelContext -RutaRaizRepositorio $global:HERMES_REPO_ROOT -NombreEntorno "Pruebas"
        $Kernel = New-HermesEnterpriseKernel -ContextoKernel $ContextoKernel
        Start-HermesEnterpriseKernel -KernelEnterprise $Kernel | Out-Null
        Stop-HermesEnterpriseKernel -KernelEnterprise $Kernel | Out-Null
        $Kernel.EstadoKernel | Should Be "Detenido"
    }
}