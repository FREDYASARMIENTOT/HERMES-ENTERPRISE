# GOLDEN REFACTORING SEQUENCE V2

> **Roadmap Reconciliado con Bootstrap Implementation Plan**
>
> Basado en el análisis conjunto de:
> - `CLINE.md` — Reglas de trabajo permanente
> - `MASTER_REFACTORING_ROADMAP.md` — 20 mejoras originales (M-001 a M-020)
> - `GOLDEN_REFACTORING_SEQUENCE.md` — 78 commits originales (001-078)
> - `BOOTSTRAP_IMPLEMENTATION_PLAN.md` — 7 motores + pipeline definitivo
>
> Versión: 2.0
> Fecha: 2026-07-29
> Principio rector: **NO REESCRIBIR. CONECTAR.**

---

## Tabla de Contenidos

1. [Análisis de Reconciliación](#1-análisis-de-reconciliación)
2. [Matriz de Decisión para Cada Commit Original](#2-matriz-de-decisión-para-cada-commit-original)
3. [Nuevo Mapa de Motores y Componentes](#3-nuevo-mapa-de-motores-y-componentes)
4. [Nuevo Orden de Commits (V2)](#4-nuevo-orden-de-commits-v2)
5. [Nuevos Checkpoints](#5-nuevos-checkpoints)
6. [Nuevos Riesgos](#6-nuevos-riesgos)
7. [Nuevas Validaciones](#7-nuevas-validaciones)
8. [Estrategia de Rollback V2](#8-estrategia-de-rollback-v2)
9. [Criterio de Finalización V2](#9-criterio-de-finalización-v2)

---

## 1. Análisis de Reconciliación

### 1.1 Hallazgos Clave de la Auditoría

La auditoría arquitectónica (`BOOTSTRAP_IMPLEMENTATION_PLAN.md`) descubrió que **componentes que el roadmap original marcaba para eliminación o refactorización son en realidad funcionales y deben preservarse**.

| Componente | Líneas | Decisión Original (V1) | Decisión Corregida (V2) | Justificación |
|-----------|--------|----------------------|------------------------|---------------|
| `EnvironmentManager.ps1` | 680 | No listado (desconocido) | **Preservar, no tocar** | Es el motor de entorno completo: detección Python, venv, dependencias, rollback |
| `BootstrapRequest.ps1` | 282 | No listado (desconocido) | **Preservar, no tocar** | DTO completo con builders y validaciones |
| `BootstrapState.ps1` | 170 | No listado (desconocido) | **Preservar, no tocar** | Contrato de estado inmutable con serialización y validación |
| `GitHub.ps1` | 31 | Marcado para eliminar (M-015) | **Preservar, no tocar** | 5 funciones completas: auth, repo create, push, sync |
| `BootstrapWizard.ps1` | ~80 | Refactorizar (M-007) | **Wrapper mínimo** | Ya es mayormente UI, solo extraer lógica de bootstrap |
| `Start-HermesProject.ps1` | ~80 | Refactorizar (M-006) | **Wrapper mínimo** | Ya es delgado, solo delegar en pipeline |
| `BootstrapOrchestrator.ps1` (engine) | 9 | Refactorizar (M-007) | **Wrapper en pipeline** | Stub que debe delegar en `Invoke-HermesBootstrapPipeline` |
| `bootstrap.enterprise.json` | — | Eliminar (M-008) | **Preservar y consumir** | Debe ser la fuente de verdad para configuración |

### 1.2 Errores del Roadmap Original (V1)

| Error | Impacto | Corrección en V2 |
|-------|---------|------------------|
| **M-015** marcaba `motor/bootstrap/GitHub.ps1` como "código muerto" para eliminar | Eliminaría el único módulo GitHub funcional | Preservar, es un activo de 31 líneas con 5 funciones |
| **M-008** marcaba `bootstrap.enterprise.json` para eliminar | Perdería la configuración de bootstrap | Preservar, es la fuente de verdad para motores |
| **M-008** marcaba `configuracion/` para eliminar | Perdería `kernel.enterprise.json` | Preservar ambos archivos, evaluar fusión después |
| **M-010** (paths hardcoded) no consideraba que `bootstrap.enterprise.json` ya contiene rutas configurables | Refactorización innecesaria | Usar bootstrap.enterprise.json como fuente de rutas |
| **M-006** (refactor Start-HermesProject) subestimaba que ya es un entrypoint delgado | Refactorización grande innecesaria | Solo agregar delegación al pipeline |
| **M-007** (separar orchestrator de wizard) asumía que ambos están mezclados | Refactorización grande innecesaria | El wizard ya es UI, el orchestrator es stub |
| **78 commits** asumían que todo se construye desde cero | Sobrecarga de 78 operaciones | Reducir a ~40 commits aprovechando activos existentes |

### 1.3 Nuevo Principio Rector

```
NO REESCRIBIR. CONECTAR.

+--------------------------------------------------+
| 1. IDENTIFICAR activos funcionales existentes     |
| 2. PRESERVAR todo código que ya funciona           |
| 3. CONECTAR activos mediante wrappers y pipelines  |
| 4. SOLO reescribir cuando no exista alternativa   |
| 5. NO eliminar sin verificar referencias primero  |
+--------------------------------------------------+
```

---

## 2. Matriz de Decisión para Cada Commit Original

### 2.1 Fase 0 — Preparación (Commits 001-005 originales)

| Commit V1 | Decisión V2 | Justificación |
|-----------|-------------|---------------|
| **001** — tag rc13-pre-refactor | ✅ **CONSERVAR** | Sigue siendo necesario como snapshot de seguridad |
| **002** — eliminar .gitkeep | ✅ **CONSERVAR** | Sigue siendo válido, bajo riesgo |
| **003** — limpiar sandboxes | ✅ **CONSERVAR** | Sigue siendo válido, pero NO eliminar sandbox que tenga datos de prueba de integración |
| **004** — limpiar reports | ✅ **CONSERVAR** | Sigue siendo válido, pero preservar FileIndex.json y reports activos |
| **005** — try/catch en kernel | ✅ **CONSERVAR** | Sigue siendo válido, mejora resiliencia |

### 2.2 Fase 1 — Limpieza (Commits 006-026 originales)

| Commit V1 | Decisión V2 | Justificación |
|-----------|-------------|---------------|
| **006** — eliminar Azure vestigial | ✅ **CONSERVAR** | Sigue siendo válido, bajo riesgo |
| **007** — eliminar stub modules (security, validation, scheduler) | ✅ **CONSERVAR** | Sigue siendo válido, verificar referencias |
| **008** — eliminar stub (dependencygraph, discovery, providers) | ✅ **CONSERVAR** | Ídem |
| **009** — eliminar stub (plugins, registro, lifecycle) | ✅ **CONSERVAR** | Ídem |
| **010** — eliminar stub (contracts, capabilities, observability) | ✅ **CONSERVAR** | Pero NO eliminar `motor/observability/` si contiene código funcional |
| **011** — eliminar stub (manifest, wizards, sandbox, session, context) | ⚠️ **MODIFICAR** | NO eliminar `motor/session/` si `BootstrapState.ps1` depende de él. Verificar antes. |
| **012** — eliminar scripts unreferenced | ⚠️ **MODIFICAR** | NO eliminar `tools/EnterprisePipeline.ps1` sin verificar si el pipeline V2 lo necesita |
| **013** — eliminar builders | ✅ **CONSERVAR** | `builders/` sigue siendo código muerto |
| **014** — eliminar GitHub stub + HelloPlugin | 🔴 **RECHAZADO** | `motor/bootstrap/GitHub.ps1` (31 líneas) es FUNCIONAL, no stub. NO ELIMINAR. Solo eliminar `plugins/HelloPlugin/` |
| **015** — eliminar KernelHost/Core | ✅ **CONSERVAR** | Sigue siendo válido, kernel único |
| **016** — fusionar módulos Git | 🔴 **RECHAZADO** | `motor/bootstrap/Git.ps1` no existe (solo existe `motor/bootstrap/functions/GitHub.ps1`). No hay duplicación Git que fusionar. |
| **017** — eliminar Observabilidad vestigial | 🔴 **RECHAZADO** | Verificar si `tools/Observabilidad.ps1` tiene funcionalidad única vs `motor/tools/Observabilidad.ps1` |
| **018** — eliminar bootstrap.yaml | ✅ **CONSERVAR** | Sigue siendo válido, es formato redundante |
| **019** — eliminar configuracion/ | 🔴 **RECHAZADO** | `configuracion/bootstrap.enterprise.json` y `configuracion/kernel.enterprise.json` son ACTIVOS. Preservar y consumir. |
| **020** — fusionar motor/config/ | 🔴 **RECHAZADO** | No hay duplicación. `motor/config/Configuration.psm1` y `configuracion/` tienen propósitos diferentes. |
| **021** — mover CHANGELOG.md | ⚠️ **MODIFICAR** | Mover a `docs/` pero verificar que no haya referencias |
| **022** — mover LICENSE | ⚠️ **MODIFICAR** | Mover a `docs/` pero verificar referencias |
| **023** — mover .env | ⚠️ **MODIFICAR** | Mover a `docs/.env.example` |
| **024** — eliminar directorios vacíos | ✅ **CONSERVAR** | Válido |
| **025** — verificar ServiceContainer | ✅ **CONSERVAR** | Válido |
| **026** — eliminar ServiceLocator | ⚠️ **MODIFICAR** | Verificar si `motor/dependencias/ServiceLocator.ps1` existe realmente |

### 2.3 Fase 2 — Consolidación (Commits 027-039 originales)

| Commit V1 | Decisión V2 | Justificación |
|-----------|-------------|---------------|
| **027-034** — tests unitarios | ✅ **CONSERVAR** | Sigue siendo válido, prioridad alta |
| **035** — test baseline | ✅ **CONSERVAR** | Válido |
| **036** — CI/CD pipeline | ✅ **CONSERVAR** | Válido, prioridad alta |
| **037** — verificar EventBus único | ✅ **CONSERVAR** | Válido |
| **038** — verificar DI único | ✅ **CONSERVAR** | Válido |
| **039** — verificar estructura limpia | ✅ **CONSERVAR** | Válido |

### 2.4 Fase 3 — Arquitectura (Commits 040-048 originales)

| Commit V1 | Decisión V2 | Justificación |
|-----------|-------------|---------------|
| **040** — eliminar paths hardcoded | ⚠️ **MODIFICAR** | Usar `bootstrap.enterprise.json` como fuente. No eliminar paths sin verificar. |
| **041** — extraer BootstrapEngine | 🔴 **RECHAZADO** | El pipeline V2 (`BootstrapPipeline.ps1`) reemplaza el concepto de BootstrapEngine. No crear engine artificial. |
| **042** — tests BootstrapEngine | 🔴 **RECHAZADO** | No existe BootstrapEngine en V2. Tests van contra el pipeline. |
| **043** — extraer VSCodeIntegration | 🔴 **RECHAZADO** | Si VSCodeIntegration no existe o es mínimo, no extraerlo como módulo separado todavía. |
| **044** — thin entrypoint <50 líneas | 🔴 **RECHAZADO** | `Start-HermesProject.ps1` ya es delgado (~80 líneas). No es prioridad. |
| **045** — separar orchestrator state | 🔴 **RECHAZADO** | `BootstrapState.ps1` ya maneja el estado. No separar. |
| **046** — tests orchestrator | ⚠️ **MODIFICAR** | Tests contra el pipeline, no contra orchestrator aislado |
| **047** — strip wizard to UI | ✅ **CONSERVAR** | Válido, el wizard debe ser solo UI |
| **048** — verificar integración | ✅ **CONSERVAR** | Válido, pero contra el pipeline V2 |

### 2.5 Fase 4 — Optimización (Commits 049-057 originales)

| Commit V1 | Decisión V2 | Justificación |
|-----------|-------------|---------------|
| **049-057** — renombrar nomenclatura | 🔴 **RECHAZADO** | **Riesgo arquitectónico alto**. Renombrar EventBus→BusEventos, Logger→Registrador rompe todas las referencias sin beneficio funcional. No hacer. |

### 2.6 Fase 5 — Hardening (Commits 058-078 originales)

| Commit V1 | Decisión V2 | Justificación |
|-----------|-------------|---------------|
| **058** — PSScriptAnalyzer en CI | ✅ **CONSERVAR** | Válido |
| **059-064** — validación parámetros | ✅ **CONSERVAR** | Válido, buena práctica |
| **065** — timeouts Git | ✅ **CONSERVAR** | Válido |
| **066** — telemetría básica | ✅ **CONSERVAR** | Válido |
| **067** — verify.ps1 | ✅ **CONSERVAR** | Válido |
| **068** — badges README | ✅ **CONSERVAR** | Válido |
| **069** — ADRs | ✅ **CONSERVAR** | Válido |
| **070-078** — tests integración | ⚠️ **MODIFICAR** | Actualizar para reflejar la nueva arquitectura de 7 motores + pipeline |

---

## 3. Nuevo Mapa de Motores y Componentes

### 3.1 Arquitectura Objetivo Final

```
HERMES-ENTERPRISE/
│
├── Start-HermesProject.ps1          # Entrypoint público (delgado, delega en pipeline)
├── CLINE.md                          # Reglas de trabajo
├── AUDIT_REPORT.md                   # Auditoría
├── MASTER_REFACTORING_ROADMAP.md     # Roadmap original (V1)
├── GOLDEN_REFACTORING_SEQUENCE_V2.md # Este documento
├── BOOTSTRAP_IMPLEMENTATION_PLAN.md  # Plan de bootstrap
│
├── motor/
│   ├── kernel/
│   │   └── Kernel.ps1               # Único kernel enterprise
│   │
│   ├── bootstrap/
│   │   ├── Start-HermesProject.ps1  # Entrypoint delgado
│   │   ├── request/
│   │   │   └── BootstrapRequest.ps1 # DTO (PRESERVAR)
│   │   ├── engine/
│   │   │   ├── BootstrapPipeline.ps1        # NUEVO: orquestador central
│   │   │   ├── BootstrapState.ps1           # Contrato estado (PRESERVAR)
│   │   │   ├── BootstrapOrchestrator.ps1    # Stub → wrapper del pipeline
│   │   │   ├── BootstrapWizard.ps1          # UI (PRESERVAR)
│   │   │   ├── WorkspaceEngine.ps1          # NUEVO: Motor 1
│   │   │   ├── EnvironmentEngine.ps1        # NUEVO: Motor 2 (wrapper)
│   │   │   ├── ProjectGenerator.ps1         # NUEVO: Motor 3
│   │   │   ├── GitEngine.ps1                # NUEVO: Motor 4
│   │   │   ├── GitHubEngine.ps1             # NUEVO: Motor 5 (wrapper)
│   │   │   ├── ValidationEngine.ps1         # NUEVO: Motor 6
│   │   │   └── RecoveryEngine.ps1           # NUEVO: Motor 7
│   │   ├── environment/
│   │   │   └── EnvironmentManager.ps1       # 680 líneas (PRESERVAR)
│   │   └── functions/
│   │       ├── GitHub.ps1                   # 31 líneas (PRESERVAR)
│   │       └── Python.ps1                   # 8 líneas (PRESERVAR)
│   │
│   ├── config/
│   │   └── ConfigurationManager.ps1         # Gestor de configuración
│   ├── eventos/
│   │   └── EventBus.ps1                     # Único EventBus
│   ├── dependencias/
│   │   └── DependencyInjection.ps1          # Único DI container
│   ├── logging/
│   │   └── Logger.ps1                       # Logger estructurado
│   ├── runtime/
│   │   └── Runtime.ps1                      # Ciclo de vida
│   └── tools/
│       └── Observabilidad.ps1               # Única observabilidad
│
├── configuracion/                           # PRESERVAR (contiene activos)
│   ├── bootstrap.enterprise.json            # Configuración de bootstrap
│   └── kernel.enterprise.json               # Configuración del kernel
│
├── pruebas/
│   ├── unitarias/
│   ├── integracion/
│   └── bootstrap/
│
├── reports/                                 # Reports activos
├── docs/                                    # Documentación
├── sandbox/                                 # Sandbox (1 activo)
│
└── .github/
    └── workflows/
        └── ci.yml                           # CI/CD pipeline
```

### 3.2 Tabla de Componentes: Decisión Final

| Componente | Ruta | Acción | Justificación |
|-----------|------|--------|---------------|
| EnvironmentManager | `motor/bootstrap/environment/EnvironmentManager.ps1` | **PRESERVAR** (680 líneas funcionales) | Motor completo de detección Python y venv |
| BootstrapRequest | `motor/bootstrap/request/BootstrapRequest.ps1` | **PRESERVAR** (282 líneas funcionales) | DTO completo con builders y validación |
| BootstrapState | `motor/bootstrap/engine/BootstrapState.ps1` | **PRESERVAR** (170 líneas funcionales) | Contrato de estado inmutable |
| GitHub.ps1 | `motor/bootstrap/functions/GitHub.ps1` | **PRESERVAR** (31 líneas funcionales) | 5 funciones GitHub operativas |
| Python.ps1 | `motor/bootstrap/functions/Python.ps1` | **PRESERVAR** (8 líneas funcionales) | Función de creación de entorno |
| BootstrapWizard | `motor/bootstrap/engine/BootstrapWizard.ps1` | **WRAPPER MÍNIMO** | Extraer lógica bootstrap, dejar solo UI |
| Start-HermesEntry | `motor/bootstrap/Start-HermesProject.ps1` | **WRAPPER MÍNIMO** | Delegar en pipeline |
| bootstrap.enterprise.json | `configuracion/bootstrap.enterprise.json` | **CONSUMIR** | Fuente de verdad para bootstrap |
| kernel.enterprise.json | `configuracion/kernel.enterprise.json` | **CONSUMIR** | Configuración del kernel |
| WorkspaceEngine | `motor/bootstrap/engine/` | **CREAR** (NUEVO, ~120 líneas) | Motor 1 del pipeline |
| EnvironmentEngine | `motor/bootstrap/engine/` | **CREAR** (NUEVO, ~80 líneas wrapper) | Motor 2, wrapper de EnvironmentManager |
| ProjectGenerator | `motor/bootstrap/engine/` | **CREAR** (NUEVO, ~200 líneas) | Motor 3 |
| GitEngine | `motor/bootstrap/engine/` | **CREAR** (NUEVO, ~100 líneas) | Motor 4 |
| GitHubEngine | `motor/bootstrap/engine/` | **CREAR** (NUEVO, ~90 líneas wrapper) | Motor 5, wrapper de GitHub.ps1 |
| ValidationEngine | `motor/bootstrap/engine/` | **CREAR** (NUEVO, ~150 líneas) | Motor 6 |
| RecoveryEngine | `motor/bootstrap/engine/` | **CREAR** (NUEVO, ~150 líneas) | Motor 7 |
| BootstrapPipeline | `motor/bootstrap/engine/` | **CREAR** (NUEVO, ~200 líneas) | Orquestador central |
| BootstrapOrchestrator | `motor/bootstrap/engine/BootstrapOrchestrator.ps1` | **WRAPPER** | Delegar en BootstrapPipeline |

---

## 4. Nuevo Orden de Commits (V2)

### Principios de la Nueva Secuencia

1. **Primero limpiar, luego construir** — Fase 0 y 1 eliminan lo que sobra
2. **Preservar activos antes de construir** — No eliminar nada que el pipeline necesite
3. **Construir motores de abajo hacia arriba** — Primero los motores individuales, luego el pipeline
4. **Conectar antes de pulir** — Hardening después de que todo funcione
5. **No renombrar** — La nomenclatura español/inglés no se toca

### Resumen de Commits

| Fase | Commits | Descripción | Días |
|------|---------|-------------|------|
| S0 | 001-004 | Preparación (tag, .gitkeep, sandbox, reports) | 0.5 |
| S1 | 005-019 | Limpieza sin eliminar activos | 2 |
| S2 | 020-029 | Pruebas unitarias + CI/CD | 2 |
| S3 | 030-041 | Construcción de motores + pipeline | 3 |
| S4 | 042-045 | Integración y validación | 1 |
| S5 | 046-055 | Hardening + documentación | 1.5 |

**Total: ~55 commits** (vs 78 originales) — **29% menos commits, ~30% menos tiempo estimado**

---

### FASE 0 — Preparación (Commits 001-004)

#### Commit 001

| Campo | Valor |
|-------|-------|
| **ID** | 001 |
| **Nombre** | Tag snapshot pre-refactor |
| **Descripción** | Crear tag `rc13-pre-refactor-v2` con el estado actual del repositorio |
| **Archivos** | Ninguno (solo git) |
| **Dependencias** | Ninguna |
| **Tiempo** | 5 min |
| **Riesgo** | Nulo |
| **Mensaje Git** | `chore(repo): tag rc13-pre-refactor-v2 for safety snapshot` |

#### Commit 002

| Campo | Valor |
|-------|-------|
| **ID** | 002 |
| **Nombre** | Eliminar .gitkeep |
| **Descripción** | Eliminar todos los archivos .gitkeep en directorios vacíos |
| **Archivos** | `agentes/.gitkeep`, `arquitectura/.gitkeep`, `herramientas/.gitkeep`, `memoria/.gitkeep`, `perfiles/.gitkeep`, `plantillas/.gitkeep`, `protocolos/.gitkeep`, `proveedores/.gitkeep`, `pruebas/.gitkeep`, `motor/.gitkeep`, `builders/.gitkeep`, `configuracion/.gitkeep`, `documentacion/.gitkeep`, `engine/.gitkeep`, `infra/.gitkeep` |
| **Dependencias** | 001 |
| **Tiempo** | 10 min |
| **Riesgo** | Bajo |
| **Mensaje Git** | `chore(repo): remove all .gitkeep placeholder files` |

#### Commit 003

| Campo | Valor |
|-------|-------|
| **ID** | 003 |
| **Nombre** | Limpiar sandboxes no activos |
| **Descripción** | Eliminar todos los sandboxes excepto `sandbox/Local/` y 1 proyecto de referencia |
| **Archivos** | `sandbox/ProyectoPrueba001/`, `sandbox/ProyectoTest001/` a `sandbox/ProyectoTest018/`, `ProyectoTest025/` |
| **Dependencias** | 002 |
| **Tiempo** | 15 min |
| **Riesgo** | Bajo |
| **Mensaje Git** | `chore(sandbox): remove obsolete test projects, keep only Local/` |

#### Commit 004

| Campo | Valor |
|-------|-------|
| **ID** | 004 |
| **Nombre** | Limpiar reports de diagnóstico estáticos |
| **Descripción** | Eliminar reports de diagnóstico que no son activos. Preservar: `FileIndex.json`, `BASELINE_GOLDEN_PATH.md`, `BootstrapDiagnostic.md`. |
| **Archivos** | `reports/ArchitectureInventory.json`, `reports/CreateProjectResult.json`, `reports/DeudaTecnica.json`, `reports/ExecutionTrace.json`, `reports/ExecutionTrace.md`, `reports/FilesystemTest.json`, `reports/FilesystemTest.md`, `reports/GitRepository.json`, `reports/ImportForensics.json`, `reports/ImportForensics.md`, `reports/ImportTrace.json`, `reports/ImportTrace.txt`, `reports/JsonList.json`, `reports/ModuleInventoryDetailed.json`, `reports/ModulesList.json`, `reports/ModuleStructure.json`, `reports/ModuleStructure.md`, `reports/ModuleValidation.json`, `reports/ModuleValidation.txt`, `reports/pester_result.xml`, `reports/ProvisionReport.md`, `reports/PythonList.json`, `reports/ReporteForenseWorkspace.json`, `reports/ReporteIntegridad.json`, `reports/RepositoryCounts.json`, `reports/RepositoryTree.json`, `reports/ResolveWorkspace_output.txt`, `reports/ResolveWorkspace.json`, `reports/ScriptsList.json`, `reports/SyntaxAudit.csv`, `reports/YamlList.json` |
| **Dependencias** | 002 |
| **Tiempo** | 15 min |
| **Riesgo** | Bajo |
| **Mensaje Git** | `chore(reports): remove stale diagnostic reports, keep active only` |

**Checkpoint S0**: Tag creado, proyecto limpio de placeholders, sandboxes obsoletos y reports estáticos.

---

### FASE 1 — Limpieza (Commits 005-019)

#### Commit 005

| Campo | Valor |
|-------|-------|
| **ID** | 005 |
| **Nombre** | Eliminar Azure vestigial |
| **Descripción** | Eliminar `motor/providers/azure/` completo y cualquier referencia a Azure en scripts que no sean funcionales |
| **Archivos** | `motor/providers/azure/AzureProviderAuthentication.ps1`, `motor/providers/azure/AzureResourceDiscovery.ps1`, `motor/providers/` (vacío) |
| **Dependencias** | 004 |
| **Tiempo** | 15 min |
| **Riesgo** | Bajo |
| **Validación** | `grep -ri "azure" --include="*.ps1" motor/` = vacío |
| **Mensaje Git** | `chore(azure): remove vestigial Azure provider modules` |

#### Commit 006

| Campo | Valor |
|-------|-------|
| **ID** | 006 |
| **Nombre** | Eliminar módulos stub de motor/ (batch 1) |
| **Descripción** | Eliminar directorios stub: `motor/security/`, `motor/validation/`, `motor/scheduler/`, `motor/dependencygraph/` |
| **Archivos** | Directorios vacíos con .gitkeep (ya eliminados en 002) |
| **Dependencias** | 002, 005 |
| **Tiempo** | 15 min |
| **Riesgo** | Bajo |
| **Validación** | Verificar con `grep -r "security\|validation\|scheduler\|dependencygraph" --include="*.ps1" .` que no hay referencias |
| **Mensaje Git** | `refactor(motor): remove stub modules (security, validation, scheduler, dependencygraph)` |

#### Commit 007

| Campo | Valor |
|-------|-------|
| **ID** | 007 |
| **Nombre** | Eliminar módulos stub (batch 2) |
| **Descripción** | Eliminar: `motor/discovery/`, `motor/plugins/`, `motor/manifest/`, `motor/capabilities/` |
| **Archivos** | Directorios vacíos |
| **Dependencias** | 006 |
| **Tiempo** | 15 min |
| **Riesgo** | Bajo |
| **Validación** | Verificar referencias |
| **Mensaje Git** | `refactor(motor): remove stub modules (discovery, plugins, manifest, capabilities)` |

#### Commit 008

| Campo | Valor |
|-------|-------|
| **ID** | 008 |
| **Nombre** | Eliminar módulos stub (batch 3) |
| **Descripción** | Eliminar: `motor/observability/`, `motor/context/`, `motor/contracts/`, `motor/registro/` |
| **Archivos** | Directorios vacíos |
| **Dependencias** | 007 |
| **Tiempo** | 15 min |
| **Riesgo** | **MEDIO** — Verificar si `motor/observability/` contiene código funcional distinto de `motor/tools/Observabilidad.ps1` |
| **Validación** | `grep -r "observability" --include="*.ps1" .` = vacío |
| **Mensaje Git** | `refactor(motor): remove stub modules (observability, context, contracts, registro)` |

#### Commit 009

| Campo | Valor |
|-------|-------|
| **ID** | 009 |
| **Nombre** | Eliminar módulos stub (batch 4) |
| **Descripción** | Eliminar: `motor/lifecycle/`, `motor/wizards/`, `motor/sandbox/`, `motor/session/` |
| **Archivos** | Directorios vacíos |
| **Dependencias** | 008 |
| **Tiempo** | 15 min |
| **Riesgo** | Bajo |
| **Validación** | Verificar referencias |
| **Mensaje Git** | `refactor(motor): remove stub modules (lifecycle, wizards, sandbox, session)` |

#### Commit 010

| Campo | Valor |
|-------|-------|
| **ID** | 010 |
| **Nombre** | Eliminar plugins/HelloPlugin/ |
| **Descripción** | Eliminar `plugins/HelloPlugin/` completo (plugin de ejemplo no funcional) |
| **Archivos** | `plugins/HelloPlugin/` |
| **Dependencias** | 009 |
| **Tiempo** | 5 min |
| **Riesgo** | Bajo |
| **Mensaje Git** | `refactor(plugins): remove HelloPlugin stub` |

#### Commit 011

| Campo | Valor |
|-------|-------|
| **ID** | 011 |
| **Nombre** | Eliminar scripts unreferenced |
| **Descripción** | Eliminar: `hello.ps1`, `Patch-Hermes-AzureTrace.ps1`, `builders/DocumentBuilder.ps1`, `builders/DocumentMetadata.ps1`, `builders/MarkdownUtilities.ps1`, `reports/backups/WorkspaceResolver.psm1.bak` |
| **Archivos** | 6 archivos |
| **Dependencias** | 005, 010 |
| **Tiempo** | 15 min |
| **Riesgo** | **MEDIO** — Verificar que ningún script reference estos archivos |
| **Validación** | `grep -r "DocumentBuilder\|WorkspaceResolver\|HermesPathResolver" --include="*.ps1" .` = vacío |
| **Mensaje Git** | `refactor(tools): remove unreferenced scripts and builders` |

#### Commit 012

| Campo | Valor |
|-------|-------|
| **ID** | 012 |
| **Nombre** | Verificar estado de GitHub.ps1 — NO ELIMINAR |
| **Descripción** | Verificar que `motor/bootstrap/functions/GitHub.ps1` tiene 31 líneas funcionales. Documentar que NO debe eliminarse. Agregar comentario de preservación. |
| **Archivos** | `motor/bootstrap/functions/GitHub.ps1` (agregar header comentado) |
| **Dependencias** | 011 |
| **Tiempo** | 10 min |
| **Riesgo** | Bajo |
| **Mensaje Git** | `docs(github): add preservation notice to GitHub.ps1` |

#### Commit 013

| Campo | Valor |
|-------|-------|
| **ID** | 013 |
| **Nombre** | Eliminar KernelHost/Core — consolidar kernel único |
| **Descripción** | Eliminar `motor/kernel/Core/` completo. Verificar que `motor/kernel/Kernel.ps1` cargue sin errores después. |
| **Archivos** | `motor/kernel/Core/KernelHost.ps1`, `motor/kernel/Core/ServiceContainer.ps1`, `motor/kernel/Core/EventBus.ps1`, `motor/kernel/Core/ComponentRegistry.ps1`, `motor/kernel/Core/BootLoader.ps1`, `motor/kernel/Core/run_mission_bootstrap.ps1`, `motor/kernel/Core/descriptors/DummyComponent.json`, `motor/kernel/Core/components/BootstrapOrchestrator.ps1` |
| **Dependencias** | 009 |
| **Tiempo** | 1h |
| **Riesgo** | **ALTO** — Verificar que Kernel.ps1 no dependa de Core/ |
| **Validación** | `. motor/kernel/Kernel.ps1; $k = New-HermesEnterpriseKernel -ContextoKernel $ctx; Start-HermesEnterpriseKernel -KernelEnterprise $k` funciona |
| **Mensaje Git** | `refactor(kernel): remove KernelHost/Core, consolidate to single Kernel.ps1` |

#### Commit 014

| Campo | Valor |
|-------|-------|
| **ID** | 014 |
| **Nombre** | Eliminar bootstrap.yaml |
| **Descripción** | Eliminar `bootstrap.yaml` (formato redundante con bootstrap.enterprise.json) |
| **Archivos** | `bootstrap.yaml` |
| **Dependencias** | 013 |
| **Tiempo** | 5 min |
| **Riesgo** | Bajo |
| **Validación** | `Test-Path bootstrap.yaml` = $false |
| **Mensaje Git** | `chore(config): remove bootstrap.yaml, keep only bootstrap.enterprise.json` |

#### Commit 015

| Campo | Valor |
|-------|-------|
| **ID** | 015 |
| **Nombre** | Mover CHANGELOG.md → docs/ |
| **Descripción** | Mover `CHANGELOG.md` a `docs/CHANGELOG.md`. Actualizar referencias si existen. |
| **Archivos** | `CHANGELOG.md` → `docs/CHANGELOG.md` |
| **Dependencias** | 014 |
| **Tiempo** | 10 min |
| **Riesgo** | Bajo |
| **Mensaje Git** | `docs(repo): move CHANGELOG.md to docs/` |

#### Commit 016

| Campo | Valor |
|-------|-------|
| **ID** | 016 |
| **Nombre** | Mover LICENSE → docs/ |
| **Descripción** | Mover `LICENSE` a `docs/LICENSE` |
| **Archivos** | `LICENSE` → `docs/LICENSE` |
| **Dependencias** | 015 |
| **Tiempo** | 5 min |
| **Riesgo** | Bajo |
| **Mensaje Git** | `docs(repo): move LICENSE to docs/` |

#### Commit 017

| Campo | Valor |
|-------|-------|
| **ID** | 017 |
| **Nombre** | Mover .env → docs/.env.example |
| **Descripción** | Mover `.env` a `docs/.env.example` |
| **Archivos** | `.env` → `docs/.env.example` |
| **Dependencias** | 016 |
| **Tiempo** | 5 min |
| **Riesgo** | Bajo |
| **Mensaje Git** | `docs(repo): move .env template to docs/` |

#### Commit 018

| Campo | Valor |
|-------|-------|
| **ID** | 018 |
| **Nombre** | Eliminar directorios vacíos residuales |
| **Descripción** | Eliminar directorios que quedaron vacíos: `agentes/`, `arquitectura/`, `herramientas/`, `memoria/`, `perfiles/`, `protocolos/`, `proveedores/`, `engine/`, `infra/`, `builders/`, `plugins/` (vacío) |
| **Archivos** | Directorios vacíos |
| **Dependencias** | 002-017 |
| **Tiempo** | 10 min |
| **Riesgo** | Bajo |
| **Validación** | `ls agentes/ arquitectura/ herramientas/ memoria/ perfiles/ plantillas/ protocolos/ proveedores/` todos fallan |
| **Mensaje Git** | `chore(repo): remove empty residual directories` |

#### Commit 019

| Campo | Valor |
|-------|-------|
| **ID** | 019 |
| **Nombre** | Verificar estado del motor de limpieza |
| **Descripción** | Verificar que la estructura de `motor/` contiene solo los directorios que deben preservarse. Contar archivos .ps1. |
| **Archivos** | Ninguno (solo verificación) |
| **Dependencias** | 018 |
| **Tiempo** | 15 min |
| **Riesgo** | Bajo |
| **Validación** | `ls -d motor/*/` muestra solo los directorios esperados |
| **Mensaje Git** | `chore(motor): verify clean structure after removal phase` |

**Checkpoint S1**: Proyecto limpio de módulos stub, Azure vestigial, código muerto. Activos preservados.

---

### FASE 2 — Pruebas + CI/CD (Commits 020-029)

#### Commits 020-028: Tests unitarios Pester

| Commit | ID | Descripción | Archivo de test |
|--------|----|-------------|-----------------|
| 020 | — | Test: Kernel.ps1 base | `pruebas/unitarias/Test-Kernel.ps1` |
| 021 | — | Test: EventBus | `pruebas/unitarias/Test-EventBus.ps1` |
| 022 | — | Test: Logger | `pruebas/unitarias/Test-Logger.ps1` |
| 023 | — | Test: ConfigurationManager | `pruebas/unitarias/Test-ConfigurationManager.ps1` |
| 024 | — | Test: DependencyInjection | `pruebas/unitarias/Test-DependencyInjection.ps1` |
| 025 | — | Test: BootstrapState | `pruebas/unitarias/Test-BootstrapState.ps1` |
| 026 | — | Test: BootstrapRequest | `pruebas/unitarias/Test-BootstrapRequest.ps1` |
| 027 | — | Test: EnvironmentManager (wrapped) | `pruebas/unitarias/Test-EnvironmentEngine.ps1` |
| 028 | — | Test: GitHub.ps1 (wrapped) | `pruebas/unitarias/Test-GitHubEngine.ps1` |

#### Commit 029

| Campo | Valor |
|-------|-------|
| **ID** | 029 |
| **Nombre** | Agregar CI/CD pipeline GitHub Actions |
| **Descripción** | Crear `.github/workflows/ci.yml` que ejecute: (1) Pester tests, (2) PSScriptAnalyzer lint, (3) verify.ps1 (cuando exista) |
| **Archivos** | Nuevo: `.github/workflows/ci.yml` |
| **Dependencias** | 020-028 |
| **Tiempo** | 1h |
| **Riesgo** | Bajo |
| **Mensaje Git**** | `ci(github): add GitHub Actions pipeline with tests and lint` |

**Checkpoint S2**: Tests unitarios pasando al 100%. CI/CD pipeline funcional.

---

### FASE 3 — Construcción de Motores + Pipeline (Commits 030-041)

#### Commit 030

| Campo | Valor |
|-------|-------|
| **ID** | 030 |
| **Nombre** | Crear WorkspaceEngine (Motor 1) |
| **Descripción** | Crear `motor/bootstrap/engine/WorkspaceEngine.ps1` con función `Initialize-WorkspaceEngine`. Valida ruta, detecta colisiones, crea árbol de directorios. |
| **Archivos** | Nuevo: `motor/bootstrap/engine/WorkspaceEngine.ps1` (~120 líneas) |
| **Dependencias** | BootstrapState existente |
| **Tiempo** | 2h |
| **Riesgo** | Bajo |
| **Mensaje Git** | `feat(bootstrap): add WorkspaceEngine for directory scaffolding (Motor 1)` |

#### Commit 031

| Campo | Valor |
|-------|-------|
| **ID** | 031 |
| **Nombre** | Crear EnvironmentEngine (Motor 2) |
| **Descripción** | Crear `motor/bootstrap/engine/EnvironmentEngine.ps1` con función `Initialize-EnvironmentEngine`. Wrapper de `EnvironmentManager` existente (680 líneas). NO modificar EnvironmentManager. |
| **Archivos** | Nuevo: `motor/bootstrap/engine/EnvironmentEngine.ps1` (~80 líneas) |
| **Dependencias** | EnvironmentManager existente, 030 |
| **Tiempo** | 1h |
| **Riesgo** | Medio — el wrapper debe probarse contra EnvironmentManager real |
| **Mensaje Git** | `feat(bootstrap): add EnvironmentEngine wrapper (Motor 2, reuses EnvironmentManager)` |

#### Commit 032

| Campo | Valor |
|-------|-------|
| **ID** | 032 |
| **Nombre** | Crear ProjectGenerator (Motor 3) |
| **Descripción** | Crear `motor/bootstrap/engine/ProjectGenerator.ps1` con función `Initialize-ProjectGenerator`. Genera README.md, LICENSE, CHANGELOG.md, .gitignore, src/main.py, tests/test_main.py, pyproject.toml, .env.example. |
| **Archivos** | Nuevo: `motor/bootstrap/engine/ProjectGenerator.ps1` (~200 líneas) |
| **Dependencias** | 030 |
| **Tiempo** | 3h |
| **Riesgo** | Medio — muchos archivos a generar |
| **Mensaje Git** | `feat(bootstrap): add ProjectGenerator for project files (Motor 3)` |

#### Commit 033

| Campo | Valor |
|-------|-------|
| **ID** | 033 |
| **Nombre** | Crear GitEngine (Motor 4) |
| **Descripción** | Crear `motor/bootstrap/engine/GitEngine.ps1` con función `Initialize-GitEngine`. git init, config user, commit inicial, rama main. |
| **Archivos** | Nuevo: `motor/bootstrap/engine/GitEngine.ps1` (~100 líneas) |
| **Dependencias** | 030 |
| **Tiempo** | 1.5h |
| **Riesgo** | Bajo |
| **Mensaje Git** | `feat(bootstrap): add GitEngine for repo initialization (Motor 4)` |

#### Commit 034

| Campo | Valor |
|-------|-------|
| **ID** | 034 |
| **Nombre** | Crear GitHubEngine (Motor 5) |
| **Descripción** | Crear `motor/bootstrap/engine/GitHubEngine.ps1` con función `Initialize-GitHubEngine`. Wrapper de `GitHub.ps1` existente (31 líneas). NO modificar GitHub.ps1. |
| **Archivos** | Nuevo: `motor/bootstrap/engine/GitHubEngine.ps1` (~90 líneas) |
| **Dependencias** | GitHub.ps1 existente, 033 |
| **Tiempo** | 1h |
| **Riesgo** | Medio — depende de gh CLI |
| **Mensaje Git** | `feat(bootstrap): add GitHubEngine wrapper (Motor 5, reuses GitHub.ps1)` |

#### Commit 035

| Campo | Valor |
|-------|-------|
| **ID** | 035 |
| **Nombre** | Crear ValidationEngine (Motor 6) |
| **Descripción** | Crear `motor/bootstrap/engine/ValidationEngine.ps1` con función `Invoke-ValidationEngine`. Ejecuta 14 checks de validación sobre el proyecto generado. |
| **Archivos** | Nuevo: `motor/bootstrap/engine/ValidationEngine.ps1` (~150 líneas) |
| **Dependencias** | 030-034 |
| **Tiempo** | 2h |
| **Riesgo** | Bajo |
| **Mensaje Git** | `feat(bootstrap): add ValidationEngine with 14 integrity checks (Motor 6)` |

#### Commit 036

| Campo | Valor |
|-------|-------|
| **ID** | 036 |
| **Nombre** | Crear RecoveryEngine (Motor 7) |
| **Descripción** | Crear `motor/bootstrap/engine/RecoveryEngine.ps1` con funciones `Resume-BootstrapPipeline` e `Invoke-BootstrapRollback`. Persistencia de contexto en BOOTSTRAP_CONTEXT.json. Rollback por fase. |
| **Archivos** | Nuevo: `motor/bootstrap/engine/RecoveryEngine.ps1` (~150 líneas) |
| **Dependencias** | BootstrapState existente |
| **Tiempo** | 2h |
| **Riesgo** | Medio — rollback de GitHub requiere confirmación |
| **Mensaje Git** | `feat(bootstrap): add RecoveryEngine with resume and rollback (Motor 7)` |

#### Commit 037

| Campo | Valor |
|-------|-------|
| **ID** | 037 |
| **Nombre** | Crear BootstrapPipeline (orquestador central) |
| **Descripción** | Crear `motor/bootstrap/engine/BootstrapPipeline.ps1` con función `Invoke-HermesBootstrapPipeline`. Orquesta los 7 motores en secuencia: Workspace → Environment → ProjectGen → Git → GitHub → Validation → Recovery. Maneja estado, errores, persistencia y BootstrapReport. |
| **Archivos** | Nuevo: `motor/bootstrap/engine/BootstrapPipeline.ps1` (~200 líneas) |
| **Dependencias** | 030-036 |
| **Tiempo** | 4h |
| **Riesgo** | **ALTO** — Es el componente central. Requiere pruebas exhaustivas. |
| **Mensaje Git** | `feat(bootstrap): add BootstrapPipeline orchestrating all 7 engines` |

**Checkpoint S3a**: 7 motores creados. Pipeline creado pero sin probar contra motores reales.

#### Commit 038

| Campo | Valor |
|-------|-------|
| **ID** | 038 |
| **Nombre** | Tests: WorkspaceEngine + EnvironmentEngine |
| **Descripción** | Crear tests unitarios para Motores 1 y 2 |
| **Archivos** | Nuevos: `pruebas/unitarias/Test-WorkspaceEngine.ps1`, `pruebas/unitarias/Test-EnvironmentEngine.ps1` |
| **Dependencias** | 030-031 |
| **Tiempo** | 1h |
| **Mensaje Git** | `test(bootstrap): add unit tests for WorkspaceEngine and EnvironmentEngine` |

#### Commit 039

| Campo | Valor |
|-------|-------|
| **ID** | 039 |
| **Nombre** | Tests: ProjectGenerator + GitEngine |
| **Descripción** | Crear tests unitarios para Motores 3 y 4 |
| **Archivos** | Nuevos: `pruebas/unitarias/Test-ProjectGenerator.ps1`, `pruebas/unitarias/Test-GitEngine.ps1` |
| **Dependencias** | 032-033 |
| **Tiempo** | 1h |
| **Mensaje Git** | `test(bootstrap): add unit tests for ProjectGenerator and GitEngine` |

#### Commit 040

| Campo | Valor |
|-------|-------|
| **ID** | 040 |
| **Nombre** | Tests: GitHubEngine + ValidationEngine + RecoveryEngine |
| **Descripción** | Crear tests unitarios para Motores 5, 6, 7 |
| **Archivos** | Nuevos: `pruebas/unitarias/Test-GitHubEngine.ps1`, `pruebas/unitarias/Test-ValidationEngine.ps1`, `pruebas/unitarias/Test-RecoveryEngine.ps1` |
| **Dependencias** | 034-036 |
| **Tiempo** | 1.5h |
| **Mensaje Git** | `test(bootstrap): add unit tests for GitHubEngine, ValidationEngine, RecoveryEngine` |

#### Commit 041

| Campo | Valor |
|-------|-------|
| **ID** | 041 |
| **Nombre** | Tests: BootstrapPipeline |
| **Descripción** | Crear tests unitarios para el pipeline completo. Probar: flujo normal, errores por fase, reanudación, rollback, reporte. |
| **Archivos** | Nuevo: `pruebas/unitarias/Test-BootstrapPipeline.ps1` |
| **Dependencias** | 037-040 |
| **Tiempo** | 2h |
| **Riesgo** | Alto — pipeline es el componente orquestador |
| **Mensaje Git** | `test(bootstrap): add unit tests for BootstrapPipeline orchestration` |

**Checkpoint S3b**: Todos los motores y pipeline tienen tests unitarios.

---

### FASE 4 — Integración (Commits 042-045)

#### Commit 042

| Campo | Valor |
|-------|-------|
| **ID** | 042 |
| **Nombre** | Actualizar BootstrapOrchestrator stub → wrapper |
| **Descripción** | Modificar `motor/bootstrap/engine/BootstrapOrchestrator.ps1` (9 líneas stub) para que delegue en `Invoke-HermesBootstrapPipeline`. NO eliminar el archivo — convertirlo en wrapper. |
| **Archivos** | `motor/bootstrap/engine/BootstrapOrchestrator.ps1` (modificado) |
| **Dependencias** | 037, 041 |
| **Tiempo** | 30 min |
| **Riesgo** | Bajo |
| **Mensaje Git** | `refactor(bootstrap): convert BootstrapOrchestrator stub to pipeline wrapper` |

#### Commit 043

| Campo | Valor |
|-------|-------|
| **ID** | 043 |
| **Nombre** | Integrar bootstrap.enterprise.json como fuente de configuración |
| **Descripción** | Modificar BootstrapPipeline para consumir `configuracion/bootstrap.enterprise.json`. Extraer: rutas por defecto, opciones de templates, configuración de GitHub, etc. |
| **Archivos** | `motor/bootstrap/engine/BootstrapPipeline.ps1` (modificado) |
| **Dependencias** | 037, bootstrap.enterprise.json existente |
| **Tiempo** | 1h |
| **Riesgo** | Medio — cambios en el pipeline |
| **Mensaje Git** | `feat(bootstrap): integrate bootstrap.enterprise.json as configuration source` |

#### Commit 044

| Campo | Valor |
|-------|-------|
| **ID** | 044 |
| **Nombre** | Prueba de integración: pipeline completo en sandbox |
| **Descripción** | Ejecutar `Invoke-HermesBootstrapPipeline` contra `sandbox/TestPipeline`. Verificar: (1) estructura de carpetas, (2) .venv creado, (3) README generado, (4) git init, (5) validación pasa. **NO ejecutar GitHub Engine** (sin gh CLI). |
| **Archivos** | Ninguno — prueba manual documentada en docs/ |
| **Dependencias** | 042-043 |
| **Tiempo** | 2h |
| **Riesgo** | Alto — primera ejecución real del pipeline |
| **Mensaje Git** | Ninguno (prueba manual) |

#### Commit 045

| Campo | Valor |
|-------|-------|
| **ID** | 045 |
| **Nombre** | Actualizar Start-HermesProject.ps1 para delegar en pipeline |
| **Descripción** | Modificar `motor/bootstrap/Start-HermesProject.ps1` para que el entrypoint público delegue en `Invoke-HermesBootstrapPipeline` en lugar de contener lógica propia. |
| **Archivos** | `motor/bootstrap/Start-HermesProject.ps1` (modificado) |
| **Dependencias** | 037, 042 |
| **Tiempo** | 30 min |
| **Riesgo** | Bajo — el entrypoint ya es delgado |
| **Mensaje Git** | `refactor(bootstrap): thin Start-HermesProject to delegate to pipeline` |

**Checkpoint S4**: Pipeline integrado con entrypoint público y configuración. Verificado contra sandbox.

---

### FASE 5 — Hardening (Commits 046-055)

#### Commit 046

| Campo | Valor |
|-------|-------|
| **ID** | 046 |
| **Nombre** | Establecer baseline de tests (100% pasando) |
| **Descripción** | Ejecutar `Invoke-Pester pruebas/` y asegurar 100% pass. Corregir tests que fallen. Documentar baseline. |
| **Archivos** | Varios (correcciones menores) |
| **Dependencias** | 020-041 |
| **Tiempo** | 1h |
| **Riesgo** | Medio |
| **Mensaje Git** | `test(core): establish test baseline at 100% pass` |

#### Commit 047

| Campo | Valor |
|-------|-------|
| **ID** | 047 |
| **Nombre** | Agregar PSScriptAnalyzer al CI |
| **Descripción** | Agregar `Invoke-ScriptAnalyzer` al pipeline CI. |
| **Archivos** | `.github/workflows/ci.yml` (modificado) |
| **Dependencias** | 029 |
| **Tiempo** | 30 min |
| **Mensaje Git** | `ci(github): add PSScriptAnalyzer lint step to pipeline` |

#### Commit 048

| Campo | Valor |
|-------|-------|
| **ID** | 048 |
| **Nombre** | Agregar validación de parámetros en módulos core |
| **Descripción** | Agregar `[ValidateNotNullOrEmpty()]`, `[ValidateScript()]`, y `[ValidateSet()]` en funciones públicas de: Kernel.ps1, EventBus.ps1, DependencyInjection.ps1, Logger.ps1, ConfigurationManager.ps1, Runtime.ps1. |
| **Archivos** | `motor/kernel/Kernel.ps1`, `motor/eventos/EventBus.ps1`, `motor/dependencias/DependencyInjection.ps1`, `motor/logging/Logger.ps1`, `motor/config/ConfigurationManager.ps1`, `motor/runtime/Runtime.ps1` |
| **Dependencias** | 046 |
| **Tiempo** | 2h |
| **Riesgo** | Bajo |
| **Mensaje Git** | `fix(core): add parameter validation to all core module functions` |

#### Commit 049

| Campo | Valor |
|-------|-------|
| **ID** | 049 |
| **Nombre** | Agregar validación de parámetros en motores bootstrap |
| **Descripción** | Agregar validación de parámetros en todos los motores (1-7) y el pipeline. |
| **Archivos** | `WorkspaceEngine.ps1`, `EnvironmentEngine.ps1`, `ProjectGenerator.ps1`, `GitEngine.ps1`, `GitHubEngine.ps1`, `ValidationEngine.ps1`, `RecoveryEngine.ps1`, `BootstrapPipeline.ps1` |
| **Dependencias** | 030-037 |
| **Tiempo** | 1h |
| **Riesgo** | Bajo |
| **Mensaje Git** | `fix(bootstrap): add parameter validation to all engines and pipeline` |

#### Commit 050

| Campo | Valor |
|-------|-------|
| **ID** | 050 |
| **Nombre** | Agregar timeouts en operaciones de red |
| **Descripción** | Agregar timeouts en GitEngine y GitHubEngine para operaciones de red. |
| **Archivos** | `motor/bootstrap/engine/GitEngine.ps1`, `motor/bootstrap/engine/GitHubEngine.ps1` |
| **Dependencias** | 033-034 |
| **Tiempo** | 30 min |
| **Riesgo** | Bajo |
| **Mensaje Git** | `fix(bootstrap): add network timeouts to GitEngine and GitHubEngine` |

#### Commit 051

| Campo | Valor |
|-------|-------|
| **ID** | 051 |
| **Nombre** | Agregar manejo de errores en kernel startup |
| **Descripción** | Verificar que `New-HermesEnterpriseKernel` y `Start-HermesEnterpriseKernel` tengan try/catch en todas las operaciones. |
| **Archivos** | `motor/kernel/Kernel.ps1` |
| **Dependencias** | Ninguna |
| **Tiempo** | 1h |
| **Riesgo** | Bajo |
| **Mensaje Git** | `fix(kernel): add error handling to kernel startup` |

#### Commit 052

| Campo | Valor |
|-------|-------|
| **ID** | 052 |
| **Nombre** | Crear verify.ps1 — script de integridad |
| **Descripción** | Crear `tools/verify.ps1` que valide: (1) estructura de directorios, (2) todos los módulos core cargan, (3) tests pasan al 80%+, (4) no hay paths hardcoded, (5) PSScriptAnalyzer pasa. |
| **Archivos** | Nuevo: `tools/verify.ps1` |
| **Dependencias** | 046-051 |
| **Tiempo** | 3h |
| **Riesgo** | Bajo |
| **Mensaje Git** | `chore(tools): create verify.ps1 integrity check script` |

#### Commit 053

| Campo | Valor |
|-------|-------|
| **ID** | 053 |
| **Nombre** | Agregar badges CI/CD al README |
| **Descripción** | Agregar badges de estado de GitHub Actions al README.md. |
| **Archivos** | `README.md` |
| **Dependencias** | 029, 047 |
| **Tiempo** | 15 min |
| **Mensaje Git** | `docs(readme): add CI/CD status badges` |

#### Commit 054

| Campo | Valor |
|-------|-------|
| **ID** | 054 |
| **Nombre** | Tests de integración: flujos bootstrap |
| **Descripción** | Crear tests de integración que prueben: (1) Workspace → Environment → ProjectGen, (2) ProjectGen → Git → GitHub (mocked), (3) Pipeline completo con Force en errores, (4) Reanudación desde Fase 3, (5) Rollback de Workspace Engine. |
| **Archivos** | Nuevo: `pruebas/integracion/Test-BootstrapIntegration.ps1` |
| **Dependencias** | 030-041, 044 |
| **Tiempo** | 4h |
| **Riesgo** | Alto — tests complejos |
| **Mensaje Git** | `test(int): add bootstrap integration tests` |

#### Commit 055

| Campo | Valor |
|-------|-------|
| **ID** | 055 |
| **Nombre** | Documentación técnica final |
| **Descripción** | Actualizar `docs/ARCHITECTURE_DECISIONS.md` con decisiones de V2. Agregar ADR-004 "Arquitectura de 7 motores", ADR-005 "Principio No Reescribir". Actualizar `README.md` con la nueva arquitectura. |
| **Archivos** | `docs/ARCHITECTURE_DECISIONS.md`, `docs/adr/ADR-004-seven-engines.md`, `docs/adr/ADR-005-no-rewrite.md`, `README.md` |
| **Dependencias** | Todos los anteriores |
| **Tiempo** | 2h |
| **Riesgo** | Bajo |
| **Mensaje Git** | `docs(architecture): add ADRs for V2 engine architecture and no-rewrite principle` |

**Checkpoint S5**: Todos los tests pasan. verify.ps1 pasa. CI/CD pipeline funcional. Documentación actualizada.

---

## 5. Nuevos Checkpoints

### Checkpoint S0 — Preparación

| Campo | Resultado |
|-------|-----------|
| **Estado** | [ ] Completado |
| **Commits ejecutados** | 001-004 |
| **Verificación** | `git tag -l rc13-pre-refactor-v2` existe; `ls sandbox/` solo Local/; `ls reports/*.json` solo FileIndex.json |
| **Riesgo residual** | Nulo |
| **Próximo** | S1 — Limpieza |

### Checkpoint S1 — Limpieza

| Campo | Resultado |
|-------|-----------|
| **Estado** | [ ] Completado |
| **Commits ejecutados** | 005-019 |
| **Verificación** | `ls -d motor/*/` muestra solo directorios preservados; `grep -ri "azure" motor/` = vacío; `Test-Path motor/kernel/Core/` = $false; `grep -r "DocumentBuilder" . --include="*.ps1"` = vacío |
| **Riesgo residual** | **ALTO** (commit 013 — kernel puede romperse) |
| **Próximo** | S2 — Pruebas |

### Checkpoint S2 — Pruebas + CI/CD

| Campo | Resultado |
|-------|-----------|
| **Estado** | [ ] Completado |
| **Commits ejecutados** | 020-029 |
| **Verificación** | `Invoke-Pester pruebas/unitarias/` = 100%; `.github/workflows/ci.yml` existe |
| **Riesgo residual** | Medio (tests pueden fallar inicialmente) |
| **Próximo** | S3 — Construcción |

### Checkpoint S3a — Motores Construidos

| Campo | Resultado |
|-------|-----------|
| **Estado** | [ ] Completado |
| **Commits ejecutados** | 030-037 |
| **Verificación** | `ls motor/bootstrap/engine/` contiene WorkspaceEngine.ps1, EnvironmentEngine.ps1, ProjectGenerator.ps1, GitEngine.ps1, GitHubEngine.ps1, ValidationEngine.ps1, RecoveryEngine.ps1, BootstrapPipeline.ps1; `. motor/bootstrap/engine/BootstrapPipeline.ps1` carga sin errores |
| **Riesgo residual** | Alto (pipeline no probado contra motores) |
| **Próximo** | S3b — Tests de motores |

### Checkpoint S3b — Tests de Motores

| Campo | Resultado |
|-------|-----------|
| **Estado** | [ ] Completado |
| **Commits ejecutados** | 038-041 |
| **Verificación** | `Invoke-Pester pruebas/unitarias/` = 100% (incluyendo tests de motores y pipeline) |
| **Riesgo residual** | Medio (integración real no probada) |
| **Próximo** | S4 — Integración |

### Checkpoint S4 — Integración

| Campo | Resultado |
|-------|-----------|
| **Estado** | [ ] Completado |
| **Commits ejecutados** | 042-045 |
| **Verificación** | `Start-HermesProject -NombreProyecto "Test" -AbrirVSCode:$false` ejecuta sin error; sandbox/TestPipeline/ existe con estructura completa; `motor/bootstrap/engine/BootstrapOrchestrator.ps1` delega en pipeline; `motor/bootstrap/Start-HermesProject.ps1` es delgado |
| **Riesgo residual** | Medio (no probado con GitHub real) |
| **Próximo** | S5 — Hardening |

### Checkpoint S5 — Hardening

| Campo | Resultado |
|-------|-----------|
| **Estado** | [ ] Completado |
| **Commits ejecutados** | 046-055 |
| **Verificación** | `Invoke-Pester pruebas/` = 100%; `.\tools\verify.ps1` reporta "All checks passed"; CI pipeline pasa con tests + lint + verify |
| **Riesgo residual** | Bajo |
| **Próximo** | FINALIZADO |

---

## 6. Nuevos Riesgos

### Riesgos por Sprint (V2 vs V1)

| Sprint | Cambio vs V1 | Principales Riesgos |
|--------|--------------|---------------------|
| **S0** | Sin cambios | Nulo |
| **S1** | **No eliminar** GitHub.ps1 ni configuracion/ | **ALTO** en commit 013 (kernel): si kernel depende de Core/ → rotura funcional |
| **S2** | **Nuevos tests** para BootstrapState y BootstrapRequest | Medio — tests pueden fallar |
| **S3** | **Nuevo**: construcción de 7 motores + pipeline | **MUY ALTO** — primera implementación real |
| **S4** | **Reducido**: menos refactoring, más integración | Medio — pipeline real contra sandbox |
| **S5** | **Reducido**: sin renombrar | Bajo — solo validaciones y tests |

### Riesgos Arquitectónicos Específicos de V2

| # | Riesgo | Sprint | Probabilidad | Impacto | Mitigación |
|---|--------|--------|-------------|---------|------------|
| R1 | Kernel.ps1 depende de Core/ eliminado | S1 | 30% | Alto | Verificar con `grep` antes de eliminar; tener tag de rollback |
| R2 | EnvironmentManager tiene bugs no detectados | S3 | 20% | Alto | Tests unitarios del wrapper primero |
| R3 | Pipeline muy complejo para 7 motores | S3 | 25% | Alto | Construir motores primero, pipeline después. Tests por motor. |
| R4 | GitHub.ps1 tiene dependencias ocultas | S3 | 10% | Medio | Review manual de GitHub.ps1 (31 líneas) antes de wrapper |
| R5 | bootstrap.enterprise.json tiene rutas inválidas | S4 | 30% | Medio | Validar al cargar en pipeline |
| R6 | Sin Python en el sistema → pipeline bloqueado | S4 | 40% | Alto | Error claro en EnvironmentEngine, no crash |
| R7 | Sin Git en el sistema → pipeline bloqueado | S4 | 20% | Medio | Error claro en GitEngine, no crash |
| R8 | Los 14 checks de Validation fallan en entorno real | S4 | 30% | Medio | Validation no bloquea el pipeline (solo reporta) |

---

## 7. Nuevas Validaciones

### Validaciones Genéricas (aplican a TODOS los commits V2)

| # | Validación | Comando |
|---|-----------|---------|
| V1 | Git status limpio | `git status` — sin cambios sin commit |
| V2 | No hay archivos huérfanos | `git clean -n` — vacío |
| V3 | Tests unitarios pasan | `Invoke-Pester pruebas/unitarias/` — 100% |
| V4 | Kernel carga | `. motor/kernel/Kernel.ps1` — sin errores |
| V5 | Pipeline carga | `. motor/bootstrap/engine/BootstrapPipeline.ps1` — sin errores |

### Validaciones Específicas por Commit V2

| Commit | Validaciones |
|--------|-------------|
| 001 | `git tag -l rc13-pre-refactor-v2` existe |
| 002 | `grep -r "\.gitkeep" .` = vacío |
| 003 | `ls sandbox/` solo `Local/` |
| 004 | `ls reports/*.json` solo `FileIndex.json` |
| 005 | `grep -ri "azure" --include="*.ps1" motor/` = vacío |
| 006-011 | `ls -d motor/*/` muestra solo: kernel/, bootstrap/, config/, configuracion/, eventos/, dependencias/, logging/, runtime/, tools/ |
| 012 | `(Get-Content motor/bootstrap/functions/GitHub.ps1).Count -eq 31` (preservado) |
| 013 | `. motor/kernel/Kernel.ps1; $k = New-HermesEnterpriseKernel -ContextoKernel $ctx; Start-HermesEnterpriseKernel -KernelEnterprise $k` funciona |
| 014 | `Test-Path bootstrap.yaml` = $false |
| 015-017 | `Test-Path docs/CHANGELOG.md` = $true; `Test-Path docs/LICENSE` = $true; `Test-Path docs/.env.example` = $true |
| 018 | `ls agentes/ arquitectura/ herramientas/ memoria/ perfiles/ plantillas/ protocolos/ proveedores/` todos fallan |
| 019 | `(Get-ChildItem -Recurse -Filter *.ps1 motor/).Count` < 30 (reducción verificable) |
| 020-028 | `Invoke-Pester pruebas/unitarias/` = 100% |
| 029 | `.github/workflows/ci.yml` existe |
| 030-036 | Cada motor existe y carga sin errores: `. motor/bootstrap/engine/WorkspaceEngine.ps1` etc. |
| 037 | `. motor/bootstrap/engine/BootstrapPipeline.ps1`; `Get-Command Invoke-HermesBootstrapPipeline` existe |
| 038-041 | `Invoke-Pester pruebas/unitarias/` = 100% (tests de motores + pipeline) |
| 042 | `. motor/bootstrap/engine/BootstrapOrchestrator.ps1`; función `Invoke-EnterprisePipeline` existe |
| 043 | Pipeline carga bootstrap.enterprise.json sin errores |
| 045 | `. motor/bootstrap/Start-HermesProject.ps1`; `Get-Command Start-HermesProject` existe |
| 046 | `Invoke-Pester pruebas/` = 100% pass |
| 047 | CI pipeline incluye lint |
| 048 | Pasar parámetros nulos a funciones core falla con mensaje claro |
| 049 | Pasar parámetros nulos a motores falla con mensaje claro |
| 050 | Operaciones Git tienen timeout ≤ 30s |
| 051 | `Start-HermesEnterpriseKernel -KernelEnterprise $null` → error claro, no crash |
| 052 | `.\tools\verify.ps1` reporta "All checks passed" (o equivalente) |
| 053 | README.md contiene badges |
| 054 | `Invoke-Pester pruebas/integracion/` = 100% (si existe) |
| 055 | `Test-Path docs/adr/ADR-004-seven-engines.md` = $true; `Test-Path docs/adr/ADR-005-no-rewrite.md` = $true |

---

## 8. Estrategia de Rollback V2

### 8.1 Principios

1. **Cada commit es atómico y reversible** — usar `git revert <commit>` individualmente
2. **Los commits de limpieza son reversibles pero pierden archivos** — solo revertir si hay error en tiempo real
3. **Los commits de construcción (030-037)** requieren revertir commits dependientes en orden inverso
4. **Tag de seguridad** `rc13-pre-refactor-v2` permite restaurar el estado completo

### 8.2 Procedimiento de Rollback Estándar

```powershell
# 1. Identificar el commit a revertir
git log --oneline -10

# 2. Revertir (crea un nuevo commit que deshace los cambios)
git revert <commit-hash> --no-edit

# 3. Verificar que el proyecto sigue funcionando
Invoke-Pester pruebas/unitarias/
```

### 8.3 Rollback por Escenario

| Escenario | Acción | Comandos |
|-----------|--------|----------|
| **Commit individual falla** | Revertir ese commit | `git revert <hash>` |
| **Fase completa falla** | Revertir commits en orden inverso | `git revert <hash-N>...<hash-1>` |
| **Pipeline (037) rompe todo** | Revertir 037-030 en orden inverso | `git revert 037 036 035 034 033 032 031 030` |
| **Kernel (013) rompe carga** | Revertir 013 | `git revert 013` + verificar |
| **Catástrofe total** | Restaurar tag | `git checkout rc13-pre-refactor-v2` |

### 8.4 Estrategia por Nivel de Riesgo

| Riesgo | Estrategia |
|--------|-----------|
| **Bajo** (002-004, 014-019) | Commit directo. Rollback: `git revert <commit>` |
| **Medio** (005-012, 030-036, 038-055) | Commit con validación manual antes. Rollback: `git revert <commit>` |
| **Alto** (013, 037, 041, 044, 054) | Feature branch + PR + code review + tests pasando antes de mergear. Rollback: `git revert <merge-commit>` |

### 8.5 Rollback de un Motor Específico

Si un motor individual (ej. ProjectGenerator) introduce un bug después de integrado:

```powershell
# 1. Desactivar el motor en BootstrapPipeline (no eliminar código)
git revert 032  # Revierte ProjectGenerator

# 2. El pipeline continúa funcionando sin ese motor
# (el pipeline trata motores faltantes como "Skipped")

# 3. Corregir el motor en una branch feature
git checkout -b fix/project-generator
# ... correcciones ...
git push origin fix/project-generator

# 4. Una vez corregido, mergear de vuelta
```

---

## 9. Criterio de Finalización V2

### 9.1 Lista de Verificación Completa

#### Estructurales
- [ ] `motor/` contiene solo: `kernel/`, `bootstrap/`, `config/`, `configuracion/`, `eventos/`, `dependencias/`, `logging/`, `runtime/`, `tools/`
- [ ] `motor/kernel/Core/` no existe
- [ ] `motor/security/`, `motor/validation/`, `motor/scheduler/` no existen
- [ ] `bootstrap.yaml` no existe
- [ ] `hello.ps1`, `Patch-Hermes-AzureTrace.ps1` no existen
- [ ] `builders/`, `plugins/HelloPlugin/` no existen
- [ ] `agentes/`, `arquitectura/`, `herramientas/`, `memoria/`, `perfiles/`, `plantillas/`, `protocolos/`, `proveedores/` no existen
- [ ] `CHANGELOG.md`, `LICENSE`, `.env.example` están en `docs/`

#### Activos Preservados (NO ELIMINADOS)
- [ ] `motor/bootstrap/environment/EnvironmentManager.ps1` existe (680 líneas)
- [ ] `motor/bootstrap/request/BootstrapRequest.ps1` existe (282 líneas)
- [ ] `motor/bootstrap/engine/BootstrapState.ps1` existe (170 líneas)
- [ ] `motor/bootstrap/functions/GitHub.ps1` existe (31 líneas)
- [ ] `motor/bootstrap/functions/Python.ps1` existe (8 líneas)
- [ ] `configuracion/bootstrap.enterprise.json` existe
- [ ] `configuracion/kernel.enterprise.json` existe

#### Nuevos Componentes
- [ ] `motor/bootstrap/engine/WorkspaceEngine.ps1` existe
- [ ] `motor/bootstrap/engine/EnvironmentEngine.ps1` existe
- [ ] `motor/bootstrap/engine/ProjectGenerator.ps1` existe
- [ ] `motor/bootstrap/engine/GitEngine.ps1` existe
- [ ] `motor/bootstrap/engine/GitHubEngine.ps1` existe
- [ ] `motor/bootstrap/engine/ValidationEngine.ps1` existe
- [ ] `motor/bootstrap/engine/RecoveryEngine.ps1` existe
- [ ] `motor/bootstrap/engine/BootstrapPipeline.ps1` existe
- [ ] `motor/bootstrap/engine/BootstrapOrchestrator.ps1` delega en pipeline

#### Pruebas
- [ ] `Invoke-Pester pruebas/unitarias/` pasa con 100%
- [ ] `Invoke-Pester pruebas/integracion/` (si existe) pasa con 100%
- [ ] Cobertura de tests > 50% en módulos core
- [ ] Todos los 7 motores tienen tests unitarios
- [ ] BootstrapPipeline tiene tests unitarios

#### CI/CD
- [ ] `.github/workflows/ci.yml` existe
- [ ] CI pipeline ejecuta: tests Pester + PSScriptAnalyzer + verify.ps1

#### Calidad
- [ ] `PSScriptAnalyzer` pasa sin errores
- [ ] `grep -r "D:/\|C:/\|D:\\|C:\\" --include="*.ps1" .` = vacío
- [ ] `grep -r "\.gitkeep" .` = vacío
- [ ] No hay archivos .bak en el proyecto
- [ ] `Start-HermesEnterpriseKernel` tiene try/catch en todas las operaciones
- [ ] Las operaciones Git tienen timeouts de red

#### Funcional
- [ ] `Invoke-HermesBootstrapPipeline` ejecuta sin error con parámetros válidos
- [ ] El pipeline genera proyecto funcional en `sandbox/`
- [ ] `Start-HermesProject.ps1` funciona como entrypoint (delega en pipeline)
- [ ] El pipeline puede reanudarse desde una fase intermedia
- [ ] El pipeline ejecuta rollback al fallar una fase
- [ ] `tools/verify.ps1` corre sin errores

#### Documentación
- [ ] `docs/adr/ADR-004-seven-engines.md` existe
- [ ] `docs/adr/ADR-005-no-rewrite.md` existe
- [ ] `README.md` tiene badges de CI/CD
- [ ] `GOLDEN_REFACTORING_SEQUENCE_V2.md` refleja el estado final

### 9.2 Declaración de Finalización

> **La reconciliación del roadmap de Hermes Enterprise RC13 se considera completa cuando TODAS las casillas anteriores estén marcadas.**
>
> En ese momento:
> - El proyecto tiene **el doble de funcionalidad bootstrap** que al inicio
> - **Ningún activo funcional fue eliminado** (EnvironmentManager, BootstrapRequest, BootstrapState, GitHub.ps1, Python.ps1 preservados)
> - **7 motores independientes** conectados por un pipeline central
> - **~410 líneas netas de nuevo código** que conectan ~1,100 líneas de código existente
> - **55 commits** vs los 78 originales (29% menos)
> - El principio **"No reescribir. Conectar."** se ha cumplido en cada decisión

---

> **Fin del documento GOLDEN_REFACTORING_SEQUENCE_V2.md**
>
> Versión 2.0 — Pendiente de aprobación humana