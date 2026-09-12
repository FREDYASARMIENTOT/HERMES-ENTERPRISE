<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-KernelMetrics.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Define la prueba RED de Fase 1.3 para métricas internas mínimas del Kernel Enterprise.

Alcance de Fase 1.3:
    - Validar que existe un componente KernelMetrics incremental.
    - Validar que las métricas se almacenan mediante Logger Enterprise.
    - No agregar todavía telemetría distribuida, dashboards ni proveedores externos.
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

# -----------------------------------------------------------------------------------------
# Importar únicamente los módulos de la matriz de impacto de Fase 1.3.
# -----------------------------------------------------------------------------------------

. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelContext.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelHealth.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelMetrics.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\Kernel.ps1")
. (Join-Path $RutaRaizRepositorio "motor\logging\Logger.ps1")
. (Join-Path $RutaRaizRepositorio "motor\eventos\EventBus.ps1")
. (Join-Path $RutaRaizRepositorio "motor\configuracion\ConfigurationManager.ps1")
. (Join-Path $RutaRaizRepositorio "motor\registro\ModuleRegistry.ps1")
. (Join-Path $RutaRaizRepositorio "motor\dependencias\DependencyInjection.ps1")
. (Join-Path $RutaRaizRepositorio "motor\dependencias\ServiceLocator.ps1")
. (Join-Path $RutaRaizRepositorio "motor\runtime\Runtime.ps1")
. (Join-Path $RutaRaizRepositorio "motor\plugins\PluginManager.ps1")

$ContextoKernel = New-HermesEnterpriseKernelContext -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno "Pruebas"
$KernelEnterprise = New-HermesEnterpriseKernel -ContextoKernel $ContextoKernel
Start-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise | Out-Null

Assert-HermesEnterpriseCondition ($KernelEnterprise.ContenedorDependencias.ServiciosRegistrados.ContainsKey("KernelMetrics")) "El Kernel no registró automáticamente el servicio KernelMetrics."

$MetricaPrueba = Write-HermesEnterpriseKernelMetric `
    -KernelEnterprise $KernelEnterprise `
    -NombreComponente "Kernel" `
    -NombreOperacion "PruebaMetrica" `
    -HoraInicio (Get-Date).AddMilliseconds(-25) `
    -HoraFin (Get-Date) `
    -CantidadErrores 0 `
    -CantidadAdvertencias 1 `
    -Estado "Operativo"

Assert-HermesEnterpriseCondition ($MetricaPrueba.TipoRegistro -eq "MetricaKernel") "La métrica no declaró el tipo de registro esperado."
Assert-HermesEnterpriseCondition ($MetricaPrueba.TiempoEjecucionMilisegundos -ge 0) "La métrica no calculó el tiempo de ejecución."
Assert-HermesEnterpriseCondition ($MetricaPrueba.UsoMemoriaBytes -gt 0) "La métrica no registró uso de memoria."

$ContenidoLogKernel = Get-Content -Path $KernelEnterprise.Logger.RutaArchivoLog -Raw
Assert-HermesEnterpriseCondition ($ContenidoLogKernel.Contains('"TipoRegistro":"MetricaKernel"')) "El Logger Enterprise no almacenó el tipo de registro de métrica."
Assert-HermesEnterpriseCondition ($ContenidoLogKernel.Contains('"NombreOperacion":"PruebaMetrica"')) "El Logger Enterprise no almacenó el nombre de la operación medida."
Assert-HermesEnterpriseCondition ($ContenidoLogKernel.Contains('"NombreOperacion":"Kernel.Start"')) "El Kernel no publicó automáticamente la métrica inicial de arranque."

Stop-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise | Out-Null

Write-Host "Test-KernelMetrics completado correctamente." -ForegroundColor Green
