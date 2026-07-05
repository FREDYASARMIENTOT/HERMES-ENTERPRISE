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

---

## 7. Alcance Fase 2.2: Validación SemVer de plugins

La Fase 2.2 fortalece la validación de versiones de plugins sin cambiar el formato actual de `plugin.json`.

### RF-007: Validación SemVer Major.Minor.Patch

El sistema debe validar explícitamente que las versiones de plugins y Kernel mínimo usen el formato:

```text
Major.Minor.Patch
```

Criterios de aceptación:

- La validación debe usar `[version]` después de comprobar el formato estricto.
- Versiones abreviadas como `1.2` deben rechazarse.
- Versiones válidas como `1.2.3` deben exponer Major, Minor y Patch.
- Los errores deben ser descriptivos.
- Los manifiestos existentes con versión `0.4.0` deben seguir siendo compatibles.
- No se deben modificar contratos públicos del Kernel ni el formato de `plugin.json`.

---

## 8. Trazabilidad Fase 2.2

| Requisito | Componente | Prueba | Documento |
|---|---|---|---|
| RF-007 | motor/validation/VersionValidator.ps1, motor/manifest/ManifestLoader.ps1 | pruebas/unitarias/Test-VersionValidator.ps1, pruebas/unitarias/Test-Manifest.ps1, pruebas/unitarias/Test-PluginManager.ps1 | documentacion/SRS_HERMES_ENTERPRISE.md |

---

## 9. Alcance Fase 2.3: Sandbox v1 de plugins

La Fase 2.3 agrega aislamiento lógico mínimo para errores de plugins sin introducir aislamiento por procesos ni cambiar contratos públicos del Kernel.

### RF-008: Plugin Sandbox v1

El sistema debe capturar errores durante el ciclo de vida de un plugin y conservar diagnóstico local en el contexto del plugin.

Criterios de aceptación:

- Un error en un plugin no debe detener la inicialización del PluginManager.
- Los demás plugins válidos deben continuar cargando normalmente.
- El plugin defectuoso debe quedar registrado con estado `Faulted`.
- El contexto debe incluir `EstadoSandbox` y `ErroresSandbox`.
- No se deben modificar `plugin.json`, Bootstrap, Kernel público, Runtime, Logger, EventBus, Dependency Container ni Service Locator.

---

## 10. Trazabilidad Fase 2.3

| Requisito | Componente | Prueba | Documento |
|---|---|---|---|
| RF-008 | motor/lifecycle/LifecycleManager.ps1 | pruebas/unitarias/Test-PluginSandbox.ps1, pruebas/unitarias/Test-Lifecycle.ps1, pruebas/unitarias/Test-PluginManager.ps1 | documentacion/SRS_HERMES_ENTERPRISE.md, documentacion/ARCHITECTURE_DECISIONS.md |

---

## 11. Alcance Fase 2.4: Política de plugins Faulted

La Fase 2.4 define una política explícita para decidir qué hacer cuando un plugin queda en estado `Faulted`.

### RF-009: Plugin Fault Policy

El sistema debe exponer una política con acciones permitidas:

- `Continue`.
- `Disable`.
- `Abort`.

Criterios de aceptación:

- `Continue` debe mantener compatibilidad y permitir continuar con otros plugins.
- `Disable` debe marcar el plugin defectuoso como deshabilitado sin implementar recuperación automática.
- `Abort` debe detener explícitamente la inicialización cuando un plugin falla.
- La política no debe incorporar retry, recovery automático, hot reload, auto restart ni aislamiento pesado.
- No se debe modificar el formato de `plugin.json` ni contratos públicos del Kernel.

---

## 12. Trazabilidad Fase 2.4

| Requisito | Componente | Prueba | Documento |
|---|---|---|---|
| RF-009 | motor/lifecycle/PluginFaultPolicy.ps1, motor/lifecycle/LifecycleManager.ps1, motor/plugins/PluginManager.ps1 | pruebas/unitarias/Test-PluginFaultPolicy.ps1, pruebas/unitarias/Test-PluginSandbox.ps1, pruebas/unitarias/Test-PluginManager.ps1 | documentacion/SRS_HERMES_ENTERPRISE.md, documentacion/ARCHITECTURE_DECISIONS.md |
