---
title: Plan de Migración Incremental — Hermes Enterprise (Builder++ RC3.x → RC4.0)
version: RC3.2.1
---

1. Visión general

Este documento describe la estrategia incremental para migrar Hermes Enterprise desde su arquitectura actual basada en scripts y parches hacia una plataforma modular por capas (Builder++ RC3.2). El objetivo es ejecutar la migración en etapas pequeñas, cada una dejando el framework funcional y desplegable.

2. Objetivos

- Desacoplar el Framework (código fuente) de los proyectos generados.
- Centralizar la resolución de rutas y configuración.
- Mover lógica a servicios modulares que obedecen SOLID.
- Garantizar pruebas automatizadas y posibilidad de rollback en cada etapa.

3. Arquitectura actual

Breve: mezcla de scripts y shims; parámetros a veces serializados; dependencias implícitas entre scripts; referencias a rutas relativas y uso de subprocesos para delegación.

4. Arquitectura objetivo

Capas: Bootstrap, Configuration, Infrastructure, Workspace, Project, Git, Template, Logging, Testing, Provision, Pipeline, AI, CLI. Servicios modulares inyectados por un contenedor (HermesContainer). Hermes.config.json como source of truth.

5. Riesgos

- Dependencias circulares al extraer funcionalidad.
- Rotura de contratos externos (CLI, scripts de usuarios).
- Tests frágiles que tocan filesystem real.
- Pérdida de estado en migraciones entre versiones.

6. Estrategia de rollback

- Cada fase produce artefactos reversibles: toggles feature-flag, pruebas unitarias verdes.
- Mantener compatibilidad de la interfaz CLI Start-HermesProject.ps1 hasta RC4.0.
- Para cada cambio crear script de rollback que restaure archivos modificados desde staging area (no commiteado).

7. Criterios de aceptación

- Paso de Pester (unit + integration en sandbox) 100% para cambios de alta prioridad; tolerancia mínima para legacy adapters.
- No proyectos creados dentro de D:\HERMES-ENTERPRISE (salvo sandbox).
- Documentación generada y audit trail de cambios.

---

Fases detalladas

RC3.2 — Creación del núcleo (non-invasive)

Objetivo:
- Preparar el terreno: config global, path resolver (API), contenedor de servicios (interfaz), sin cambiar comportamiento externo.

Archivos afectados:
- docs/* (planificación)
- Hermes.config.json (creación)
- tools/HermesPathResolver.psm1 (API provisional)
- Start-HermesProject.ps1 (shim: read config & pass through, no behavior change)

Servicios afectados:
- ConfigurationService (esqueleto)
- WorkspaceService (esqueleto)
- Container (HermesContainer) (esqueleto)

Pruebas requeridas:
- Smoke tests: Start-HermesProject.ps1 sigue funcionando con los mismos parámetros.
- Validación: Hermes.config.json leído correctamente.

Riesgos:
- Cambio inadvertido del flujo por el shim modificado.

Rollback:
- Restaurar Start-HermesProject.ps1 y eliminar Hermes.config.json

---

RC3.3 — Migración gradual de servicios (iterativa)

Objetivo:
- Extraer servicios uno por uno (Configuration → Workspace → Project → Git → Provision → Logging → Pipeline).

Proceso por iteración (por servicio):
- Diseñar interfaz público del servicio.
- Implementar módulo en core/<Service> con tests unitarios.
- Añadir adaptador que reemplaza gradualmente llamadas en scripts apuntando al servicio;
  los scripts seguirán funcionando usando el adaptador que delega al servicio.
- Validar con tests de integración en sandbox.
- Marcar adaptador como default y retire uso directo.

Archivos afectados:
- core/<Service>/*.psm1
- scripts que dependan del servicio (adaptadores)

Pruebas requeridas:
- Unit tests (service)
- Integration tests (adapter + scripts) en sandbox

Riesgos:
- Interfaz mal definida → retrabajo. Mitigación: diseño de contrato antes de implementación.

Rollback:
- Revertir a adaptador antiguo (mantener adaptador coexistente hasta confirmar)

---

RC3.4 — Compatibilidad y Wrappers

Objetivo:
- Proveer wrappers y adaptadores para compatibilidad con integraciones externas (CLI, hooks, plugins).

Acciones:
- Implementar adaptadores que traduzcan llamadas legacy a servicios nuevos.
- Publicar contract tests que validen compatibilidad.

Pruebas:
- Contract tests
- End-to-end en sandbox

Rollback:
- Revertir adaptadores y retomar llamadas directas al código antiguo.

---

RC4.0 — Retiro del código legado

Objetivo:
- Remover código legacy y dejar sólo la plataforma modular.

Acciones:
- Eliminar scripts duplicados
- Re-homing de tests al nuevo módulo
- Limpiar stubs y compatibilidad temporal

Pruebas:
- Full regression suite en sandbox y en staging

Rollback:
- Mantener branch de soporte con código legacy durante periodo de soporte definido.

---

Dependencias y matriz

WorkspaceService → ConfigurationService → LoggingService → GitService → ProvisionService → PipelineService → BootstrapService

(Ver docs/DEPENDENCY_MATRIX.md para matriz completa)

Roadmap visual

RC3.2 → RC3.3 → RC3.4 → RC4.0

Checklists por fase

RC3.2 checklist:
- [ ] Hermes.config.json creado
- [ ] ConfigurationService skeleton created
- [ ] HermesContainer skeleton
- [ ] Shim reads config and passes WorkspaceRoot
- [ ] Smoke tests OK

RC3.3 checklist (per service):
- [ ] Interface designed
- [ ] Module implemented
- [ ] Unit tests green
- [ ] Adapter implemented
- [ ] Integration tests (sandbox) green
- [ ] Monitor metrics

RC3.4 checklist:
- [ ] All adapters in place
- [ ] Compatibility tests
- [ ] Documentation updated

RC4.0 checklist:
- [ ] Legacy code removed
- [ ] Full test suite green
- [ ] Documentation and audit complete

---

Matriz de dependencias detallada

Se generará docs/DEPENDENCY_MATRIX.md con la lista completa de dependencias entre servicios y scripts.

Roadmap y cronograma preliminar (sujeto a aprobación)

- RC3.2 (2 semanas): núcleo y configuración
- RC3.3 (6–8 semanas): migración iterativa de servicios (1 servicio por 1 semana con buffers)
- RC3.4 (2 semanas): adaptadores y compatibilidad
- RC4.0 (2 semanas): retiro y limpieza

Riesgos y mitigaciones (docs/RISKS.md)

- Riesgo: rotura de CLI — Mitigación: mantener shim compatible y tests de contrato
- Riesgo: pérdida de datos — Mitigación: backup / stage

Rollback global

Cada fase tendrá scripts de rollback y branch de soporte. El cambio no se considerará aceptado hasta que los tests y auditoría pasen.

---

Documentos a generar automáticamente:
- docs/ROADMAP.md
- docs/DEPENDENCY_MATRIX.md
- docs/ROLLBACK.md
- docs/RISKS.md

(Estos archivos se generarán ahora.)
