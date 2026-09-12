<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-KernelHealth.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Define la primera prueba RED para el Health Monitor del Kernel Enterprise.

Alcance de Fase 1.1:
    - No implementa todavía producción.
    - Fija el contrato público esperado Get-HermesEnterpriseKernelHealth.
    - Debe fallar hasta que la Fase 1.2 agregue el componente motor/kernel/KernelHealth.ps1.
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition {
    param(
        [bool]$CondicionEvaluada,
        [string]$MensajeError
    )

    if (-not $CondicionEvaluada) {
        throw $MensajeError
    }
}

# -----------------------------------------------------------------------------------------
# Importar únicamente los módulos que forman parte de la matriz de impacto de Fase 1.1.
# El Health Monitor deberá observar el estado del Kernel sin modificar contratos existentes.
# -----------------------------------------------------------------------------------------

. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelContext.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\Kernel.ps1")
. (Join-Path $RutaRaizRepositorio "motor\logging\Logger.ps1")
. (Join-Path $RutaRaizRepositorio "motor\eventos\EventBus.ps1")
. (Join-Path $RutaRaizRepositorio "motor\configuracion\ConfigurationManager.ps1")
. (Join-Path $RutaRaizRepositorio "motor\registro\ModuleRegistry.ps1")
. (Join-Path $RutaRaizRepositorio "motor\dependencias\DependencyInjection.ps1")
. (Join-Path $RutaRaizRepositorio "motor\dependencias\ServiceLocator.ps1")
. (Join-Path $RutaRaizRepositorio "motor\runtime\Runtime.ps1")
. (Join-Path $RutaRaizRepositorio "motor\plugins\PluginManager.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelMetrics.ps1")

# -----------------------------------------------------------------------------------------
# Esta importación representa el contrato de producción esperado.
# En Fase 1.1 debe fallar porque el componente aún no existe.
# En Fase 1.2 deberá existir y exponer Get-HermesEnterpriseKernelHealth.
# -----------------------------------------------------------------------------------------

. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelHealth.ps1")

$ContextoKernel = New-HermesEnterpriseKernelContext -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno "Pruebas"
$KernelEnterprise = New-HermesEnterpriseKernel -ContextoKernel $ContextoKernel
Start-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise | Out-Null

$EstadoSaludKernel = Get-HermesEnterpriseKernelHealth -KernelEnterprise $KernelEnterprise

Assert-HermesEnterpriseCondition ($null -ne $EstadoSaludKernel) "El Health Monitor no devolvió un objeto de salud."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoRuntime -eq "EnEjecucion") "El Health Monitor no reportó correctamente el estado del Runtime."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoLogger -eq "Operativo") "El Health Monitor no reportó correctamente el estado del Logger."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoEventBus -eq "Operativo") "El Health Monitor no reportó correctamente el estado del EventBus."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoConfiguracion -eq "Operativo") "El Health Monitor no reportó correctamente el estado de Configuración."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoPlugins -eq "Operativo") "El Health Monitor no reportó correctamente el estado de Plugins."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoMemoria -in @("Operativo", "Advertencia")) "El Health Monitor no reportó correctamente el estado de Memoria."
Assert-HermesEnterpriseCondition ($KernelEnterprise.ContenedorDependencias.ServiciosRegistrados.ContainsKey("KernelHealth")) "El Kernel no registró automáticamente el servicio KernelHealth."

Stop-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise | Out-Null

Write-Host "Test-KernelHealth completado correctamente." -ForegroundColor Green
