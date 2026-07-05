# SRS HERMES-ENTERPRISE

| Campo | Valor |
|---|---|
| Proyecto | HERMES-ENTERPRISE |
| AutorPrincipal | Fredy Alejandro Sarmiento Torres |
| VersionDocumento | 1.0.0 |
| Estado | Evolutivo incremental |

---

## 1. Propósito

Este SRS define requisitos funcionales y no funcionales trazables para la evolución incremental de HERMES-ENTERPRISE.

La Fase 1 fortalece el Kernel sin agregar inteligencia artificial ni proveedores externos.

---

## 2. Alcance Fase 1: Observabilidad del Kernel

La Fase 1 agrega observabilidad interna mínima al Kernel Enterprise manteniendo compatibilidad con la arquitectura existente.

### RF-001: Health Monitor del Kernel

El sistema debe exponer una función pública:

```powershell
Get-HermesEnterpriseKernelHealth
```

La función debe permitir consultar:

- EstadoRuntime.
- EstadoPlugins.
- EstadoLogger.
- EstadoEventBus.
- EstadoConfiguracion.
- EstadoMemoria.

Criterios de aceptación:

- El Health Monitor no debe iniciar ni detener componentes.
- El Health Monitor debe operar sobre el objeto Kernel existente.
- El Health Monitor debe tener prueba unitaria focalizada.
- El componente debe quedar disponible mediante `motor/kernel/KernelHealth.ps1`.

### RF-002: Métricas internas del Kernel

El sistema debe exponer una función pública:

```powershell
Write-HermesEnterpriseKernelMetric
```

La función debe registrar métricas internas con los siguientes campos mínimos:

- HoraInicio.
- HoraFin.
- TiempoEjecucionMilisegundos.
- CantidadErrores.
- CantidadAdvertencias.
- UsoMemoriaBytes.
- Estado.
- NombreComponente.
- NombreOperacion.

Criterios de aceptación:

- Las métricas deben almacenarse mediante Logger Enterprise.
- El formato debe permanecer compatible con JSONL.
- El Kernel debe publicar una métrica inicial `Kernel.Start` durante el arranque.
- El componente debe quedar disponible mediante `motor/kernel/KernelMetrics.ps1`.

### RF-003: Registro automático de componentes internos

El Kernel debe registrar automáticamente los servicios internos:

- KernelHealth.
- KernelMetrics.

Criterios de aceptación:

- El registro debe usar el contenedor de dependencias existente.
- No debe cambiarse la estructura pública del Kernel.
- No deben eliminarse ni renombrarse servicios existentes.

---

## 3. Requisitos no funcionales

### RNF-001: Compatibilidad incremental

Toda mejora debe extender la arquitectura existente sin romper módulos ni contratos públicos previos.

### RNF-002: Cero dependencias externas en Fase 1

Health Monitor y Kernel Metrics no deben requerir librerías, servicios, APIs externas ni proveedores cloud.

### RNF-003: Observabilidad local

La observabilidad inicial debe almacenarse localmente mediante Logger Enterprise hasta que una fase posterior incorpore telemetría avanzada.

### RNF-004: Pruebas automatizadas

Cada nuevo componente de Fase 1 debe contar con pruebas unitarias PowerShell sin dependencias externas.

---

## 4. Trazabilidad Fase 1

| Requisito | Componente | Prueba | Documento |
|---|---|---|---|
| RF-001 | motor/kernel/KernelHealth.ps1 | pruebas/unitarias/Test-KernelHealth.ps1 | documentacion/KERNEL.md |
| RF-002 | motor/kernel/KernelMetrics.ps1 | pruebas/unitarias/Test-KernelMetrics.ps1 | documentacion/KERNEL.md |
| RF-003 | motor/kernel/Kernel.ps1 | pruebas/unitarias/Test-KernelHealth.ps1, pruebas/unitarias/Test-KernelMetrics.ps1 | documentacion/KERNEL.md |

---

## 5. Alcance Fase 1.6: Smoke Test Enterprise del Kernel

La Fase 1.6 no agrega funcionalidades de negocio. Su objetivo es certificar que la infraestructura construida hasta Fase 1 opera como un único sistema integrado.

### RF-004: Prueba de integración completa del Kernel

El sistema debe incluir una prueba de integración:

```powershell
pruebas/integracion/Test-FullKernel.ps1
```

La prueba debe verificar en una única ejecución:

- Bootstrap.
- Kernel.
- Configuration Manager.
- Dependency Injection.
- Service Locator.
- Logger.
- EventBus.
- Runtime.
- Plugin Manager.
- Health Monitor.
- Kernel Metrics.
- Documentation Engine.
- Shutdown.

Criterios de aceptación:

- El Kernel debe iniciar en estado `Iniciado`.
- Runtime debe pasar a `EnEjecucion`.
- Los servicios requeridos deben estar registrados.
- Debe existir al menos un plugin cargado.
- Logger debe almacenar INFO, WARNING y métricas.
- EventBus debe entregar `Kernel.Integration.Test`.
- Health debe reportar estados operativos.
- Metrics debe registrar `Integration.FullSystem`.
- La segunda ejecución del motor documental debe reportar cero documentos actualizados.
- Shutdown debe dejar Runtime y Kernel en estado `Detenido`.

### RF-005: Script público de smoke test

El sistema debe incluir un script público:

```powershell
scripts/Test-HermesEnterprise.ps1
```

El script debe ejecutar la prueba de integración completa y fallar de forma explícita si el Kernel no supera la validación.

### RF-006: Validadores auxiliares de readiness y resumen

El Kernel debe exponer funciones auxiliares no disruptivas:

```powershell
Test-HermesEnterpriseKernelReady
Get-HermesEnterpriseKernelSummary
```

Estas funciones no deben modificar el estado del Kernel. Solo deben consultar servicios registrados, estado, plugins, eventos y métricas.

---

## 6. Trazabilidad Fase 1.6

| Requisito | Componente | Prueba | Documento |
|---|---|---|---|
| RF-004 | pruebas/integracion/Test-FullKernel.ps1 | pruebas/integracion/Test-FullKernel.ps1 | documentacion/SRS_HERMES_ENTERPRISE.md |
| RF-005 | scripts/Test-HermesEnterprise.ps1 | pruebas/integracion/Test-FullKernel.ps1 | CHANGELOG.md |
| RF-006 | motor/kernel/KernelValidator.ps1 | pruebas/integracion/Test-FullKernel.ps1 | documentacion/ARCHITECTURE_DECISIONS.md |
