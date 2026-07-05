# CHANGELOG

Todas las notas de cambio relevantes de HERMES-ENTERPRISE se documentan en este archivo.

## [0.5.1] - 2026-07-04

### Agregado

- Fase 1.6: Smoke Test Enterprise del Kernel.
- Primera prueba de integración completa en `pruebas/integracion/Test-FullKernel.ps1`.
- Script público `scripts/Test-HermesEnterprise.ps1` para ejecutar la validación integral.
- Función auxiliar `Test-HermesEnterpriseKernelReady` para verificar servicios requeridos.
- Función auxiliar `Get-HermesEnterpriseKernelSummary` para resumir estado, servicios, plugins, eventos y métricas.

### Validación

- La integración valida Bootstrap, Kernel, Configuration, Dependency Injection, Service Locator, Logger, EventBus, Runtime, PluginManager, Health Monitor, Metrics, Documentation Engine y Shutdown.

### Compatibilidad

- No se incorporó Azure Foundry, MCP, A2A, IA ni proveedores externos.
- No se modificaron contratos públicos existentes.
- No se realizaron refactorizaciones masivas.

## [0.5.0] - 2026-07-04

### Agregado

- Fase 1: Observabilidad del Kernel Enterprise.
- Health Monitor del Kernel mediante `Get-HermesEnterpriseKernelHealth`.
- Métricas internas mínimas mediante `Write-HermesEnterpriseKernelMetric`.
- Registro automático de `KernelHealth` y `KernelMetrics` en el contenedor de dependencias del Kernel.
- Métrica automática `Kernel.Start` almacenada mediante Logger Enterprise como `MetricaKernel`.
- Pruebas unitarias focalizadas para Health Monitor y Kernel Metrics.

### Documentación

- Actualizado `documentacion/KERNEL.md` con Health Monitor, Kernel Metrics, registro automático y métrica inicial de arranque.
- Actualizado `documentacion/SRS_HERMES_ENTERPRISE.md` con requisitos RF/RNF de observabilidad del Kernel.
- Actualizado `documentacion/ARCHITECTURE_DECISIONS.md` con decisión arquitectónica ADR-0005.

### Compatibilidad

- No se eliminaron módulos existentes.
- No se renombraron directorios.
- No se modificaron contratos públicos existentes.
- No se incorporó IA, MCP distribuido, A2A ni proveedores externos.
