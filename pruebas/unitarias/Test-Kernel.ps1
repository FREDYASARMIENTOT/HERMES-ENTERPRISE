<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-Kernel.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Valida el comportamiento central del Kernel Enterprise antes de implementar integraciones
    externas como Azure Foundry, MCP, memoria o agentes.
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasUnitarias = Split-Path -Parent $PSCommandPath
$RutaRaizRepositorio = Split-Path -Parent (Split-Path -Parent $RutaDirectorioPruebasUnitarias)

function Assert-HermesEnterpriseCondition {
    param([bool]$CondicionEvaluada, [string]$MensajeError)
    if (-not $CondicionEvaluada) { throw $MensajeError }
}

. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelContext.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\Kernel.ps1")
. (Join-Path $RutaRaizRepositorio "motor\logging\Logger.ps1")
. (Join-Path $RutaRaizRepositorio "motor\eventos\EventBus.ps1")
. (Join-Path $RutaRaizRepositorio "motor\configuracion\ConfigurationManager.ps1")
. (Join-Path $RutaRaizRepositorio "motor\registro\ModuleRegistry.ps1")
. (Join-Path $RutaRaizRepositorio "motor\dependencias\DependencyInjection.ps1")
. (Join-Path $RutaRaizRepositorio "motor\dependencias\ServiceLocator.ps1")
. (Join-Path $RutaRaizRepositorio "motor\runtime\Runtime.ps1")
. (Join-Path $RutaRaizRepositorio "motor\bootstrap\Bootstrap.ps1")

$ContextoKernel = New-HermesEnterpriseKernelContext -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno "Pruebas"
Assert-HermesEnterpriseCondition ($ContextoKernel.NombreProyecto -eq "HERMES-ENTERPRISE") "El contexto del Kernel no define el proyecto esperado."

$KernelEnterprise = New-HermesEnterpriseKernel -ContextoKernel $ContextoKernel
Assert-HermesEnterpriseCondition ($KernelEnterprise.EstadoKernel -eq "Creado") "El Kernel no inicia en estado Creado."

Start-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise | Out-Null
Assert-HermesEnterpriseCondition ($KernelEnterprise.EstadoKernel -eq "Iniciado") "El Kernel no cambia a estado Iniciado."
Assert-HermesEnterpriseCondition ($null -ne $KernelEnterprise.Runtime) "El Kernel no inicializó Runtime."
Assert-HermesEnterpriseCondition ($null -ne $KernelEnterprise.Logger) "El Kernel no inicializó Logger."
Assert-HermesEnterpriseCondition ($null -ne $KernelEnterprise.EventBus) "El Kernel no inicializó EventBus."

Stop-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise | Out-Null
Assert-HermesEnterpriseCondition ($KernelEnterprise.EstadoKernel -eq "Detenido") "El Kernel no cambia a estado Detenido."

Write-Host "Test-Kernel completado correctamente." -ForegroundColor Green
