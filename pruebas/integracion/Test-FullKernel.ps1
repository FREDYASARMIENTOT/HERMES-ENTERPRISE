<#
====================================================================================================
Proyecto : HERMES-ENTERPRISE
Archivo  : Test-FullKernel.ps1
Autor    : Fredy Alejandro Sarmiento Torres
Propósito:
    Define la primera prueba de integración completa del Kernel Enterprise.

Alcance de Fase 1.6:
    - Certificar que Bootstrap, Kernel, configuración, dependencias, logger, eventos, runtime,
      plugins, health, métricas, documentación y shutdown funcionan como un único sistema.
    - No incorpora IA, Azure Foundry, MCP, A2A ni proveedores externos.
====================================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$RutaDirectorioPruebasIntegracion = Split-Path -Parent $PSCommandPath
$RutaDirectorioPruebas = Split-Path -Parent $RutaDirectorioPruebasIntegracion
$RutaRaizRepositorio = Split-Path -Parent $RutaDirectorioPruebas

function Assert-HermesEnterpriseCondition {
    param([bool]$CondicionEvaluada, [string]$MensajeError)
    if (-not $CondicionEvaluada) { throw $MensajeError }
}

. (Join-Path $RutaRaizRepositorio "motor\bootstrap\Bootstrap.ps1")
. (Join-Path $RutaRaizRepositorio "motor\kernel\KernelValidator.ps1")

$KernelEnterprise = Start-HermesEnterpriseBootstrap -RutaRaizRepositorio $RutaRaizRepositorio -NombreEntorno "Integracion"

Assert-HermesEnterpriseCondition ($KernelEnterprise.EstadoKernel -eq "Iniciado") "El Kernel no inició correctamente."
Assert-HermesEnterpriseCondition ($KernelEnterprise.Runtime.EstadoRuntime -eq "EnEjecucion") "El Runtime no quedó en ejecución."

$ResultadoKernelReady = Test-HermesEnterpriseKernelReady -KernelEnterprise $KernelEnterprise
Assert-HermesEnterpriseCondition $ResultadoKernelReady.EsValido "KernelReady reportó servicios faltantes: $($ResultadoKernelReady.ServiciosFaltantes -join ', ')"

$ServiciosEsperados = @("ConfigurationManager", "Logger", "Runtime", "EventBus", "PluginManager", "KernelHealth", "KernelMetrics")
foreach ($NombreServicioEsperado in $ServiciosEsperados) {
    Assert-HermesEnterpriseCondition `
        ($KernelEnterprise.ContenedorDependencias.ServiciosRegistrados.ContainsKey($NombreServicioEsperado)) `
        "No existe servicio registrado: $NombreServicioEsperado"
}

Assert-HermesEnterpriseCondition ($KernelEnterprise.PluginManager.PluginsCargados.Count -ge 1) "No se cargaron plugins durante la integración."
Assert-HermesEnterpriseCondition ($KernelEnterprise.PluginManager.PluginsCargados.ContainsKey("HelloPlugin")) "HelloPlugin no fue cargado por PluginManager."

Write-HermesEnterpriseLogEvent -LoggerKernel $KernelEnterprise.Logger -Nivel "INFO" -Mensaje "Integration INFO" -DatosEvento @{ Prueba = "FullKernel" } | Out-Null
Write-HermesEnterpriseLogEvent -LoggerKernel $KernelEnterprise.Logger -Nivel "WARN" -Mensaje "Integration WARNING" -DatosEvento @{ Prueba = "FullKernel" } | Out-Null

$EventoRecibido = $false
Subscribe-HermesEnterpriseEvent -EventBusKernel $KernelEnterprise.EventBus -NombreEvento "Kernel.Integration.Test" -AccionEvento { param($EventoPublicado) $script:EventoRecibido = $true } | Out-Null
Publish-HermesEnterpriseEvent -EventBusKernel $KernelEnterprise.EventBus -NombreEvento "Kernel.Integration.Test" -DatosEvento @{ Prueba = "FullKernel" } | Out-Null
Assert-HermesEnterpriseCondition $EventoRecibido "El EventBus no entregó Kernel.Integration.Test."

$EstadoSaludKernel = Get-HermesEnterpriseKernelHealth -KernelEnterprise $KernelEnterprise
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoRuntime -eq "EnEjecucion") "Health no reportó Runtime EnEjecucion."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoLogger -eq "Operativo") "Health no reportó Logger Operativo."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoEventBus -eq "Operativo") "Health no reportó EventBus Operativo."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoConfiguracion -eq "Operativo") "Health no reportó Configuración Operativa."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoPlugins -eq "Operativo") "Health no reportó Plugins Operativo."
Assert-HermesEnterpriseCondition ($EstadoSaludKernel.EstadoMemoria -in @("Operativo", "Advertencia")) "Health no reportó Memoria válida."

$MetricaIntegracion = Write-HermesEnterpriseKernelMetric `
    -KernelEnterprise $KernelEnterprise `
    -NombreComponente "Integration" `
    -NombreOperacion "Integration.FullSystem" `
    -HoraInicio (Get-Date).AddMilliseconds(-50) `
    -HoraFin (Get-Date) `
    -CantidadErrores 0 `
    -CantidadAdvertencias 0 `
    -Estado "Operativo"
Assert-HermesEnterpriseCondition ($MetricaIntegracion.TiempoEjecucionMilisegundos -ge 0) "La métrica de integración no calculó tiempo."
Assert-HermesEnterpriseCondition ($MetricaIntegracion.UsoMemoriaBytes -gt 0) "La métrica de integración no registró memoria."

$ContenidoLogKernel = Get-Content -Path $KernelEnterprise.Logger.RutaArchivoLog -Raw
Assert-HermesEnterpriseCondition ($ContenidoLogKernel.Contains('"Mensaje":"Integration INFO"')) "Logger no almacenó INFO de integración."
Assert-HermesEnterpriseCondition ($ContenidoLogKernel.Contains('"Mensaje":"Integration WARNING"')) "Logger no almacenó WARNING de integración."
Assert-HermesEnterpriseCondition ($ContenidoLogKernel.Contains('"NombreOperacion":"Integration.FullSystem"')) "Logger no almacenó métrica de integración."

$RutaScriptDocumentacion = Join-Path $RutaRaizRepositorio "scripts\New-HermesEnterpriseDocumentation.ps1"
$SalidaDocumentacionPrimera = & pwsh -NoProfile -ExecutionPolicy Bypass -File $RutaScriptDocumentacion 2>&1 | Out-String
$SalidaDocumentacionSegunda = & pwsh -NoProfile -ExecutionPolicy Bypass -File $RutaScriptDocumentacion 2>&1 | Out-String
Assert-HermesEnterpriseCondition ($SalidaDocumentacionSegunda.Contains("Documentos actualizados : 0")) "La segunda generación documental no fue idempotente.`n$SalidaDocumentacionSegunda"

$ResumenKernel = Get-HermesEnterpriseKernelSummary -KernelEnterprise $KernelEnterprise
Assert-HermesEnterpriseCondition ($ResumenKernel.EstadoKernel -eq "Iniciado") "El resumen no reportó Kernel iniciado."
Assert-HermesEnterpriseCondition ($ResumenKernel.ServiciosRegistrados -ge $ServiciosEsperados.Count) "El resumen no reportó servicios suficientes."
Assert-HermesEnterpriseCondition ($ResumenKernel.PluginsCargados -ge 1) "El resumen no reportó plugins cargados."
Assert-HermesEnterpriseCondition ($ResumenKernel.EventosPublicados -ge 1) "El resumen no reportó eventos publicados."

Stop-HermesEnterpriseKernel -KernelEnterprise $KernelEnterprise | Out-Null
Assert-HermesEnterpriseCondition ($KernelEnterprise.Runtime.EstadoRuntime -eq "Detenido") "El Runtime no quedó detenido."
Assert-HermesEnterpriseCondition ($KernelEnterprise.EstadoKernel -eq "Detenido") "El Kernel no quedó detenido."

Write-Host "Test-FullKernel completado correctamente." -ForegroundColor Green
