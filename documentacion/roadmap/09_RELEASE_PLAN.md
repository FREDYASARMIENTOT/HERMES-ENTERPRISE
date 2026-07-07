---
title: HERMES Enterprise - Release Plan
date: 2026-07-07
author: HERMES Enterprise Architecture Board
status: DRAFT
version: 1.0.0
related_docs:
  - 01_MASTER_ROADMAP.md
  - 02_SANDBOX_ENGINE.md
  - 03_DEVELOPER_CONTEXT.md
  - 04_PROJECT_WIZARD.md
  - 05_SESSION_MEMORY.md
  - 06_ARCHITECTURE_TARGET.md
  - 07_BACKLOG.md
  - 08_RISK_REGISTER.md
  - 10_METRICS_KPI.md
---

# HERMES Enterprise — Plan de Releases

> Roadmap detallado de versiones del framework, con objetivos, cambios, migrations y criterios de éxito  
> **Release actual:** v0.18 (Sandbox Stabilization)  
> **Próximo hito:** v0.19 (Q3 2026)  
> **Target GA:** v1.0 (Q4 2026)  
> **Fecha de emisión:** 2026-07-07

---

## Navegación

| Documento | Descripción |
|-----------|-------------|
| → [01_MASTER_ROADMAP.md](01_MASTER_ROADMAP.md) | Roadmap maestro |
| → [02_SANDBOX_ENGINE.md](02_SANDBOX_ENGINE.md) | Motor de Sandbox |
| → [03_DEVELOPER_CONTEXT.md](03_DEVELOPER_CONTEXT.md) | Contexto de desarrollador |
| → [04_PROJECT_WIZARD.md](04_PROJECT_WIZARD.md) | Asistente de proyectos |
| → [05_SESSION_MEMORY.md](05_SESSION_MEMORY.md) | Motor de memoria y sesión |
| → [06_ARCHITECTURE_TARGET.md](06_ARCHITECTURE_TARGET.md) | Arquitectura objetivo |
| → [07_BACKLOG.md](07_BACKLOG.md) | Backlog completo |
| → [08_RISK_REGISTER.md](08_RISK_REGISTER.md) | Registro de riesgos |
| → [10_METRICS_KPI.md](10_METRICS_KPI.md) | Métricas e indicadores |

---

## Tabla de Contenidos

1. [Visión General](#1-visión-general)
2. [Release v0.18 — Sandbox Stabilization](#2-release-v018--sandbox-stabilization)
3. [Release v0.19 — Snapshot/Restore + Developer Context](#3-release-v019--snapshotrestore-developer-context)
4. [Release v0.20 — Memory Engine + Project Generator](#4-release-v020--memory-engine--project-generator)
5. [Release v1.0 — Enterprise Platform (GA)](#5-release-v10--enterprise-platform-ga)
6. [Release v2.0 — Autonomous Platform](#6-release-v20--autonomous-platform)
7. [Calendario Consolidado](#7-calendario-consolidado)
8. [Matriz de Breaking Changes](#8-matriz-de-breaking-changes)
9. [Migrations Guide Overview](#9-migrations-guide-overview)
10. [Criterios de Éxito Globales](#10-criterios-de-éxito-globales)

---

## 1. Visión General

### 1.1 Filosofía de Releases

HERMES Enterprise sigue una estrategia de releases **incrementales**, donde cada versión aporta un conjunto coherente de capacidades que construyen sobre las versiones anteriores. Las reglas generales son:

```
┌─────────────────────────────────────────────────────────────────┐
│                    FILOSOFÍA DE RELEASES                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✓ Cada release tiene un TEMA CLARO y coherente                  │
│  ✓ Los releases son pequeños y frecuentes (no big-bang)         │
│  ✓ Breaking changes solo en major bumps                         │
│  ✓ Cada minor release es backward compatible                    │
│  ✓ Los patch releases son solo para fixes críticos              │
│  ✓ Siempre existe un camino de migración documentado            │
│  ✓ Cada release tiene criterios de éxito medibles              │
│  ✓ Cada release se publica con release notes completas          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 1.2 Roadmap de Releases

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│                       ROADMAP VISUAL                                │
│                                                                     │
│  v0.18 ───────────────── v0.19 ──────────────── v0.20 ────────     │
│  JUL 2026                SEP 2026               NOV 2026            │
│  "Sandbox"               "Snapshot+Ctx"         "Intelligence"      │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│                                                                     │
│  ─── v1.0 ───────────── v1.x (incremental) ──── v2.0 ────────     │
│      DIC 2026           2027 Q1-Q3              2027 Q4             │
│      "GA"                (patches,minor)        "Autonomous"        │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 1.3 Resumen de Releases

| Release | Nombre Clave | Fecha Target | Versión SemVer | Foco Principal |
|---------|-------------|--------------|----------------|----------------|
| v0.18.x | Sandbox Stabilization | JUL 2026 | 0.18.x | Completar 12 escenarios, Snapshot Engine |
| v0.19 | Context & Restore | SEP 2026 | 0.19.0 | Snapshot/Restore/Rollback + Developer Context 6/6 |
| v0.20 | Intelligence | NOV 2026 | 0.20.0 | Memory Engine + Project Generator + VS Code |
| v1.0 | GA | DIC 2026 | 1.0.0 | Enterprise Platform completa, production-ready |
| v2.0 | Autonomous | Q4 2027 | 2.0.0 | AI-assisted, self-healing, distributed |

---

## 2. Release v0.18 — Sandbox Stabilization

### 2.1 Descripción

El release v0.18 es la versión actual del framework. Su foco es la estabilización del motor de sandbox, completando los escenarios faltantes (8-12) y sentando las bases para Snapshot/Restore.

### 2.2 Sub-releases

```
┌─────────────────────────────────────────────────────────────┐
│  v0.18 RELEASE TRAIN                                         │
├─────────────┬──────────────┬─────────────────────────────────┤
│  Versión    │  Fecha       │  Contenido                      │
├─────────────┼──────────────┼─────────────────────────────────┤
│  v0.18.0    │  (released)  │  Initial sandbox engine (7/12) │
│  v0.18.1    │  JUL W27     │  Scenarios 8-9 (Isolated,      │
│             │              │  Network-Restricted)            │
│  v0.18.2    │  JUL W29     │  Scenarios 10-11 (Multi-Tenant,│
│             │              │  Resource-Limited)              │
│  v0.18.3    │  JUL W30     │  Scenario 12 (Full Integration)│
│             │              │  + Snapshot Engine Phase 1      │
│  v0.18.5    │  AGO W31     │  Snapshot Engine Phase 2       │
│             │              │  + Git auto-first-commit        │
│             │              │  (Milestone M1)                 │
└─────────────┴──────────────┴─────────────────────────────────┘
```

### 2.3 Objetivos v0.18

| Objetivo | Métrica | Criterio de Éxito |
|----------|---------|-------------------|
| Sandbox Engine completo | 12/12 escenarios | Todos los tests passant |
| Snapshot Engine básico | State capture funcional | Captura sin corrupción |
| Git workflow mejorado | Auto-first-commit | Hook post-init operativo |
| Estabilidad general | 0 crashes | Sin pérdidas de datos |

### 2.4 Cambios v0.18

#### Features Nuevas

| Feature | Descripción | Sub-releases |
|---------|-------------|--------------|
| Scenario 8: Isolated Build Environment | Sandbox con build tools aislados | v0.18.1 |
| Scenario 9: Network-Restricted | Sandbox con acceso red limitado | v0.18.1 |
| Scenario 10: Multi-Tenant | Múltiples sesiones concurrentes | v0.18.2 |
| Scenario 11: Resource-Limited | Sandbox con quotas de CPU/RAM | v0.18.2 |
| Scenario 12: Full Integration | Escenario end-to-end | v0.18.3 |
| Snapshot Engine (Phase 1-2) | Captura de estado del sistema | v0.18.3 - v0.18.5 |
| Git auto-first-commit | Hook automatizado post-init | v0.18.5 |

#### Mejoras

| Mejora | Descripción | Sub-release |
|--------|-------------|-------------|
| Sandbox hardening | Corrección de bugs de aislamiento | v0.18.2 |
| Test coverage improvement | Unit tests para scenarios 8-12 | v0.18.1 a v0.18.3 |
| Error messages mejorados | Mensajes más descriptivos | v0.18.1 |

#### Fixes

| Fix | Severidad | Sub-release |
|-----|-----------|-------------|
| Fix: Sandbox cleanup leaks | Alta | v0.18.1 |
| Fix: Race condition en multi-tenant | Alta | v0.18.2 |
| Fix: Timeout handling en supervisor | Media | v0.18.2 |

#### Breaking Changes

**❌ NONE** — v0.18 es completamente backward compatible con v0.17.

### 2.5 Migrations

No aplica. Primera versión del train v0.18.

### 2.6 Timeline

```
Jul 2026
W27    W28    W29    W30    W31
├──────┼──────┼──────┼──────┤
│v0.18.1│     v0.18.2│v0.18.3│v0.18.5│
        │            │       │       │
  Scenarios 8-9   Scenarios 10-11  Sc.12+Snap1+Git
                                   Snap2 (M1 ★)
```

### 2.7 Criterios de Éxito v0.18.5

- [ ] 12/12 Sandbox scenarios en estado PASS
- [ ] Snapshot Engine captura estado en < 5 segundos sin corrupción
- [ ] Test coverage > 70% en motor/sandbox/
- [ ] Git auto-first-commit funcional en 100% de proyectos creados
- [ ] 0 bugs de severidad crítica abiertos
- [ ] Performance baseline establecido (latencia, memory usage)
- [ ] Documentación actualizada de todos los 12 escenarios
- [ ] Changelog consolidado desde v0.18.0 a v0.18.5

---

## 3. Release v0.19 — Snapshot/Restore + Developer Context

### 3.1 Descripción

El release v0.19 completa las capacidades de **Snapshot/Restore/Rollback** y el **Developer Context** (6/6 contextos activos). Este es un release crítico que permite al framework ofrecer persistencia real de estado y recuperación ante fallos.

### 3.2 Objetivos v0.19

| Objetivo | Métrica | Criterio de Éxito |
|----------|---------|-------------------|
| Restauración de estado | < 5s restore | 100% fiel al snapshot |
| Rollback funcional | < 10s rollback | A cualquier punto guardado |
| Developer Context completo | 6/6 contextos activos | Todos funcionales |
| ORR Score | ≥ 75% | +11 vs hoy |
| Data integrity | 0% corruzione post-restore | Verificación criptográfica |

### 3.3 Cambios v0.19

#### Features Nuevas

| Feature | Descripción | Prioridad |
|---------|-------------|-----------|
| Restore Engine | Restaurar sistema a snapshot guardado | P0 |
| Rollback Mechanism | Volver a punto en el tiempo específico | P1 |
| Context: Architecture | Información estructural del proyecto | P0 |
| Context: Tasks | Tareas activas y su estado | P0 |
| Context: Objectives | Objetivos del equipo/sprint | P0 |
| Context: CodingStandards | Estándares aplicados | P0 |
| Context: Environment (completion) | Variables de entorno completas | P1 |

#### Mejoras

| Mejora | Descripción |
|--------|-------------|
| Snapshot integrity | Hash criptográfico de verificación |
| Snapshot compress | Compresión de snapshots grandes |
| Context refresh | Auto-refresh de contextos caducados |
| Error handling | Manejo robusto de errores en restore |

#### Breaking Changes

**❌ NONE** — v0.19 es completamente backward compatible con v0.18.

### 3.4 Migrations

No se requieren migrations desde v0.18. El formato de snapshot es nuevo pero no incompatible.

### 3.5 Sub-releases

```
┌─────────────────────────────────────────────────────────────┐
│  v0.19 RELEASE TRAIN                                         │
├─────────────┬──────────────┬─────────────────────────────────┤
│  Versión    │  Fecha       │  Contenido                      │
├─────────────┼──────────────┼─────────────────────────────────┤
│  v0.19.0    │  SEP W34     │  Restore Engine + Contexts A/T │
│  v0.19.1    │  SEP W35     │  Rollback + Contexts O/CS      │
│  v0.19.2    │  SEP W36     │  Context Env completion        │
│             │              │  + Integration tests            │
│  v0.19.5    │  SEP W38     │  (Beta) All features tested    │
│             │              │  + Documentation                │
│             │              │  (Milestone M2)                 │
└─────────────┴──────────────┴─────────────────────────────────┘
```

### 3.6 Timeline

```
Ago-Sep 2026
W34      W35      W36      W37      W38
├────────┼────────┼────────┼────────┤
│ v0.19  │ v0.19  │ v0.19  │        │ v0.19.5│
│ .0     │ .1     │ .2     │        │ (Beta) │
│        │        │        │        │ (M2 ★) │
│        │        │        │        │        │
│Restore │Rollback│Context │        │Integration│
│Engine  │+Context│Env +   │        │+ Docs   │
│+Ctx A/T│O/CS    │Tests   │        │         │
```

### 3.7 Criterios de Éxito v0.19.5

- [ ] Snapshot/Restore 100% funcional con 0% data loss
- [ ] Rollback funcional a cualquier snapshot guardado
- [ ] Tiempo de restauración < 5 segundos
- [ ] Developer Context 6/6 implementado y documentado
- [ ] Integrity checks criptográficos en snapshots
- [ ] Test coverage > 75%
- [ ] 0 bugs críticos en Snapshot/Restore
- [ ] ORR Score ≥ 75%
- [ ] Documentación completa de Snapshot/Restore/Rollback
- [ ] Todos los integration tests pasando

---

## 4. Release v0.20 — Memory Engine + Project Generator

### 4.1 Descripción

El release v0.20 introduce la **persistencia inteligente** mediante el Motor de Memoria y el **Generador de Proyectos** completo. Es el primer release que provee capacidades de "inteligencia" al framework: aprende, recuerda, genera.

### 4.2 Objetivos v0.20

| Objetivo | Métrica | Criterio de Éxito |
|----------|---------|-------------------|
| Memory Engine operativo | < 100ms latencia lectura | State persistence cross-session |
| Project Generator completo | ≥ 5 templates | Proyectos listos para usar |
| VS Code auto-config | Auto-configuration funcional | Sin setup manual |
| ORR Score | ≥ 82% | +7 vs v0.19 |
| Developer satisfaction | > 4.0/5.0 | Encuesta interna |

### 4.3 Cambios v0.20

#### Features Nuevas

| Feature | Descripción | Prioridad |
|---------|-------------|-----------|
| Memory Engine: Architecture | Almacenamiento y recuperación | P1 |
| Memory Engine: Query API | Búsqueda en memoria | P1 |
| Memory Engine: Lifecycle | Compaction, eviction, archive | P1 |
| Memory Engine: Persistence | Backend SQLite + JSON fallback | P1 |
| VS Code Auto-Config | Configuración automática del IDE | P1 |
| VS Code Status Integration | Status bar + indicators | P1 |
| Project Generator: Templates | Motor de templates | P1 |
| Project Generator: Multi-framework | Soporte multi-stack | P1 |
| Project Generator: Best Practices | Scaffolding con best-practices | P1 |

#### Mejoras

| Mejora | Descripción |
|--------|-------------|
| Performance baseline | Benchmarks y optimización hot-paths |
| Integration tests completos | Suite completa de integraciones |

#### Breaking Changes

**❌ NONE** — v0.20 es completamente backward compatible con v0.19.

### 4.4 Migrations

| Migración | De | Hacia | Herramienta |
|-----------|----|----|-------------|
| Memory Engine init | N/A | Nuevo directorio data/memory | Auto-creado en primer uso |
| VS Code config | Manual | Auto-detectado | Auto-apply on session start |

### 4.5 Sub-releases

```
┌─────────────────────────────────────────────────────────────┐
│  v0.20 RELEASE TRAIN                                         │
├─────────────┬──────────────┬─────────────────────────────────┤
│  Versión    │  Fecha       │  Contenido                      │
├─────────────┼──────────────┼─────────────────────────────────┤
│  v0.20.0    │  NOV W42     │  Memory Engine (Storage + API) │
│  v0.20.1    │  NOV W43     │  Memory Lifecycle + Persistence│
│  v0.20.2    │  NOV W44     │  Project Generator (templates) │
│  v0.20.3    │  NOV W45     │  VS Code Auto-Config           │
│  v0.20.5    │  NOV W47     │  (RC) Full validation          │
│             │              │  + Multi-framework support      │
│             │              │  (Milestone M3)                 │
└─────────────┴──────────────┴─────────────────────────────────┘
```

### 4.6 Timeline

```
Nov 2026
W42      W43      W44      W45      W46      W47
├────────┼────────┼────────┼────────┼────────┤
│v0.20.0│v0.20.1│v0.20.2│v0.20.3│        │v0.20.5│
       │        │        │        │        │ (RC)  │
       │        │        │        │        │ (M3 ★)│
│       │        │        │        │        │       │
│Memory │Lifecycle│ProjGen│VS Code│        │Full   │
│Storage│+Pers.  │(templ)│AutoCfg │        │Valida.│
│+API   │        │       │       │        │       │
```

### 4.7 Criterios de Éxito v0.20.5

- [ ] Memory Engine: latencia de lectura < 100ms
- [ ] Memory Engine: estado persiste entre sesiones (verified)
- [ ] Memory Engine: compaction y eviction funcionan según política
- [ ] Project Generator: ≥ 5 templates funcionales
- [ ] Project Generator: proyecto generado listo para build en < 60s
- [ ] VS Code auto-config detecta proyecto y aplica settings
- [ ] Performance no degradado vs v0.19
- [ ] Test coverage > 78%
- [ ] 0 bugs críticos en Memory/Generator
- [ ] ORR Score ≥ 82%
- [ ] Todos los integration tests pasando

---

## 5. Release v1.0 — Enterprise Platform (GA)

### 5.1 Descripción

**v1.0 es el release GA (General Availability)** — la versión "production-ready" del framework. Completa la plataforma enterprise con event bus asíncrono, plugin system robusto con hot-reload, observabilidad completa, security hardening, circuit breakers y toda la documentación operativa necesaria.

### 5.2 Objetivos v1.0

| Objetivo | Métrica | Criterio de Éxito |
|----------|---------|-------------------|
| Event bus asíncrono | 100% async pub/sub | Sin deadlocks |
| Plugin system robusto | Hot-reload + SPI completo | Plugins cargables sin restart |
| Observabilidad total | OpenTelemetry + métricas + traces | Full visibility |
| Security | 0 vulnerabilidades conocidas | CIS compliant |
| Stability | ORR ≥ 95% | Production-ready |
| Performance | < 200ms p99 | No degradation |
| Documentation | 100% completa | Runbooks, API, guides |

### 5.3 Cambios v1.0

#### Features Nuevas

| Feature | Descripción | Prioridad |
|---------|-------------|-----------|
| Event Bus Async | Pub/sub completamente asíncrono con DLQ | P2 |
| Plugin SPI completo | Service Provider Interface robusto | P2 |
| Plugin Hot-Reload | Recarga de plugins sin restart | P2 |
| Telemetry & Observability | OpenTelemetry + métricas + traces | P2 |
| Health Checks | Verificación de salud por componente | P2 |
| Circuit Breakers | Resiliencia ante fallos | P2 |
| Security Hardening | Policies, audit, sandboxing robusto | P1 |
| Performance Optimization | Optimización de hot paths | P2 |
| E2E Test Suite | Tests de extremo a extremo | P2 |
| Production Runbooks | Documentación operativa | P1 |

#### Mejoras

| Mejora | Descripción |
|--------|-------------|
| API stabilization | Contratos finales para GA |
| Error handling | Manejo robusto en todos los caminos |
| Logging | Logging estructurado y consistente |

#### Breaking Changes

**🔴 BREAKING: Event Bus signature change**

| Cambio | De | Hacia | Migración |
|--------|----|----|-----------|
| Event dispatch | Síncrono | Asíncrono | Actualizar subscribers para async |
| Event payload | Object | Typed `DomainEvent` | Migrar a nuevo formato |

**🔴 BREAKING: Plugin manifest format v2**

| Cambio | De | Hacia | Migración |
|--------|----|----|-----------|
| manifest.json | schema v1 | schema v2 | Tool de migración auto incluído |

**🟡 DEPRECATIONS (eliminados en v2.0)**

| API Deprecated | Reemplazo | Plazo |
|----------------|-----------|-------|
| `Plugin.Register(name, callback)` | `Plugin.RegisterWithSPI(spi)` | v2.0 |
| `EventBus.PublishSync()` | `EventBus.PublishAsync()` | v1.5 |
| `Config.GetValue(key)` | `Config.GetTyped<T>(key)` | v1.5 |

### 5.4 Migrations

#### Migration Tools Included

```
┌─────────────────────────────────────────────────────────────┐
│  MIGRATION TOOLS v0.20 → v1.0                               │
├─────────────────────────────────────────────────────────────┤
│                                                                  │
│   hermes migrate --from 0.20 --to 1.0                           │
│                                                                  │
│   • Detecta breaking changes que aplican a tu instalación     │
│   • Aplica migraciones automáticamente donde es posible       │
│   • Reporta cambios manuales necesarios                        │
│   • Crea backup previo                                         │
│   • Validación post-migración                                  │
│                                                                  │
│   Migrations automáticas:                                       │
│   ✓ Plugin manifest v1 → v2                                  │
│   ✓ Config format updates                                     │
│   ✓ Memory Engine schema                                      │
│                                                                  │
│   Migrations manuales:                                          │
│   ✗ Custom plugins: actualizar firmas                         │
│   ✗ Custom event subscribers: async refactor                  │
│                                                                  │
└─────────────────────────────────────────────────────────────┘
```

#### Migration Checklist

- [ ] Ejecutar `hermes migrate --from 0.20 --to 1.0 --dry-run`
- [ ] Revisar reporte de migración
- [ ] Actualizar plugins custom si aplica
- [ ] Actualizar event subscribers custom si aplica
- [ ] Ejecutar migración real: `hermes migrate --from 0.20 --to 1.0`
- [ ] Validar con: `hermes verify`
- [ ] Consultar runbooks si hay issues

### 5.5 Sub-releases

```
┌─────────────────────────────────────────────────────────────┐
│  v1.0 RELEASE TRAIN                                          │
├─────────────┬──────────────┬─────────────────────────────────┤
│  Versión    │  Fecha       │  Contenido                      │
├─────────────┼──────────────┼─────────────────────────────────┤
│  v1.0-rc.1  │  DIC W48     │  Release Candidate 1           │
│  v1.0-rc.2  │  DIC W49     │  Release Candidate 2           │
│  v1.0       │  DIC W50     │  🎉 GA RELEASE                  │
│             │              │  (Milestone M4)                 │
└─────────────┴──────────────┴─────────────────────────────────┘
```

### 5.6 Timeline

```
Dic 2026
W48      W49      W50
├────────┼────────┼────────┤
│ v1.0   │ v1.0   │ v1.0   │
│ -rc.1  │ -rc.2  │ (GA) ★ │
│        │        │  M4    │
│ RC 1   │ RC 2   │ 🎉 LAN│
│ test   │ fixes  │ ZAM.   │
```

### 5.7 Criterios de Éxito v1.0

- [ ] ORR Score ≥ 95%
- [ ] 0 bugs críticos (sev 1-2)
- [ ] 0 bugs mayores sin workaround
- [ ] Event bus 100% asíncrono, sin deadlocks
- [ ] Plugin system con hot-reload funcional
- [ ] Observabilidad completa (métricas, traces, logs)
- [ ] Health checks en todos los componentes
- [ ] Circuit breakers operativos
- [ ] Security audit aprobado (0 CVEs known)
- [ ] Performance p99 < 200ms
- [ ] Stress test: 1000 ops/min sin degradación
- [ ] Documentation 100%: API, runbooks, guides
- [ ] Migration tools validados
- [ ] 100% E2E tests passing
- [ ] Sign-off: Architecture Board + Ops Lead

### 5.8 LTS Support

v1.0 tendrá soporte LTS de 12 meses:

| Tipo de soporte | Duración |
|-----------------|----------|
| Critical security patches | 12 meses |
| Critical bug fixes | 12 meses |
| Minor features (v1.x) | 6 meses |
| General Q&A | 12 meses |

---

## 6. Release v2.0 — Autonomous Platform

### 6.1 Descripción

v2.0 es la **próxima generación** del framework. Transforma a HERMES de una plataforma enterprise a una **plataforma autónoma** con capacidades AI-assisted, self-healing, distributed execution y dashboards web. Es el release mayor después de GA.

### 6.2 Objetivos v2.0

| Objetivo | Métrica | Criterio de Éxito |
|----------|---------|-------------------|
| AI-Assisted Development | Auto-sugerencias contextuales | > 60% aceptadas |
| Self-Healing | Detección + reparación automática | > 80% auto-resueltos |
| Distributed Execution | Múltiples workers | Scale-out funcional |
| Web Dashboard | UI completa | 100% features via web |
| Cloud Provider Support | Azure + AWS | Multi-cloud |
| Predictive Analytics | Anticipa issues | > 50% precisión |

### 6.3 Cambios v2.0

#### Features Nuevas (Epic 8)

| Feature | Descripción | Status |
|---------|-------------|--------|
| Web Dashboard MVP | UI web para gestión | Planificado |
| AI-Assisted Development | Sugerencias contextuales | Planificado |
| Self-Healing Engine | Auto-reparación de errores | Planificado |
| Distributed Workers | Ejecución en cluster | Planificado |
| Cloud Provider Integration | Azure/AWS backends | Planificado |
| Predictive Analytics | Detección proactiva de issues | Planificado |
| Autonomous Optimization | Auto-tuning de recursos | Planificado |

#### Breaking Changes

**🔴 BREAKING: Plugin interface v2**

| Cambio | De | Hacia | Migración |
|--------|----|----|-----------|
| IPlugin | interface simple | SPI-based | Re-escribir plugins |
| Plugin manifest | v2 | v3 | Migration tool |
| Event payload | DomainEvent | CloudEvent | Wrapper adapter |

**🔴 BREAKING: API versioning bump**

| API | v1.0 | v2.0 | Migration |
|-----|------|------|-----------|
| Memory Engine | `Store(key, value)` | `Store(item: MemoryItem)` | Wrapper |
| Event Bus | `Publish(event)` | `Emit(cloudEvent)` | Adapter |
| Sandbox | `Execute(code)` | `Submit(JobRequest)` | Major refactor |

### 6.4 Migrations

```
┌─────────────────────────────────────────────────────────────┐
│  MIGRATION v1.0 → v2.0 (Major)                              │
├─────────────────────────────────────────────────────────────┤
│                                                                  │
│   hermes migrate --from 1.0 --to 2.0                           │
│                                                                  │
│   ⚠️  MIGRATION COMPLEJA - Requiere intervención manual       │
│                                                                  │
│   Automático:                                                   │
│   ✓ Data format conversion                                     │
│   ✓ Config transformation                                      │
│   ✓ Plugin manifest upgrade                                    │
│                                                                  │
│   Manual:                                                       │
│   ✗ Re-escribir custom plugins (IPlugin v2)                   │
│   ✗ Refactor custom event subscribers                         │
│   ✗ Update custom sandbox providers                            │
│                                                                  │
│   Estrategia recomendada:                                       │
│   • Ejecutar v1.0 y v2.0 en paralelo                          │
│   • Migrar usuarios gradualmente (canary)                      │
│   • Mantener v1.0 LTS durante transición                      │
│                                                                  │
└─────────────────────────────────────────────────────────────┘
```

### 6.5 Timeline v2.0

```
2027
Q1              Q2              Q3              Q4
├───────────────┼───────────────┼───────────────┼───────────────┤
│ v2.0-alpha    │               │ v2.0-beta     │     v2.0 (GA) │
│               │               │               │       ★ M5    │
│ Core redesign │ AI engine     │ Integration + │ Launch        │
│ SPI v2        │ Dashboard MVP │ testing       │               │
│               │               │               │               │
```

### 6.6 Criterios de Éxito v2.0

- [ ] Platform distributed operativa con ≥ 3 workers
- [ ] AI suggestions aceptadas en > 60% de casos
- [ ] Self-healing resuelve > 80% de errores comunes
- [ ] Web dashboard 100% funcional
- [ ] Multi-cloud: Azure + AWS certificados
- [ ] Performance: < 100ms p50 en operaciones core
- [ ] ORR Score ≥ 98%
- [ ] 0 bugs críticos

---

## 7. Calendario Consolidado

### 7.1 Timeline Master

```
┌────────────────────────────────────────────────────────────────────┐
│                                                                    │
│            HERMES ENTERPRISE — MASTER CALENDAR                     │
│                                                                    │
│ 2026                                                               │
│ JUL              AUG              SEP              OCT             │
│ ├─ W27─W30 ──────┼─ W31─W34 ──────┼─ W35─W39 ──────┼─ W40─W43 ──┐ │
│ │                 │                │                │              │ │
│ │ v0.18.x         │ v0.18.5 (M1)   │ v0.19.x        │ v0.19.5 (M2)│ │
│ │ Scenarios       │ Snap+Git       │ Restore+Ctx    │ Full test   │ │
│ │                 │                │                │             │ │
│ └─────────────────┴────────────────┴────────────────┴─────────────┘ │
│                                                                    │
│ 2026 (cont.)                          2027                         │
│ NOV              DIC              Q1-Q3         Q4                 │
│ ├─ W42─W47 ──────┼─ W48─W52 ──────┼─────────────┼────────────────┐│
│ │                │                │              │                ││
│ │ v0.20.x        │ v1.0 GA (M4)   │ v1.1 → v1.x │ v2.0 (M5)     ││
│ │ Memory+ProjGen │ 🎉 Production  │ Incremental  │ Autonomous    ││
│ │                │                │ + patches    │ Platform      ││
│ └────────────────┴────────────────┴──────────────┴────────────────┘│
│                                                                    │
│  MILESTONES:                                                       │
│  ★ M1: Fin Sprint A — Sandbox Stabilized (Ago W31)                │
│  ★ M2: Fin Sprint B — Context Complete (Sep W38)                  │
│  ★ M3: Fin Sprint C — Intelligence Ready (Nov W47)                │
│  ★ M4: Fin Sprint D — GA Release (Dic W52)                        │
│  ★ M5: v2.0 Autonomous Platform (2027 Q4)                         │
│                                                                    │
└────────────────────────────────────────────────────────────────────┘
```

### 7.2 Release Gates

| Gate | Release | Criterios para avanzar |
|------|---------|------------------------|
| G1 | v0.18.5 → v0.19.0 | 12/12 scenarios passing, test coverage > 70% |
| G2 | v0.19.5 → v0.20.0 | ORR ≥ 75%, Snapshot/Restore 100% funcional |
| G3 | v0.20.5 → v1.0-rc.1 | ORR ≥ 82%, Memory Engine < 100ms, 5+ templates |
| G4 | v1.0-rc.2 → v1.0 GA | ORR ≥ 95%, 0 critical bugs, production runbooks |
| G5 | v1.x → v2.0-alpha | v1.0 estable 3 meses, user feedback recopilado |

### 7.3 Freeze Windows

| Window | Duration | Scope |
|--------|----------|-------|
| RC Code Freeze | 1 semana | Sin features nuevas. Solo fixes |
| GA Code Freeze | 2 semanas | Stabilización total |
| Holiday Freeze | Dic 22 - Ene 2 | Sin releases programados |

---

## 8. Matriz de Breaking Changes

### 8.1 Resumen por Release

| Versión | # Breaking | # Deprecations | # Migrations automáticas |
|---------|------------|----------------|--------------------------|
| v0.18 → v0.19 | 0 | 0 | 0 |
| v0.19 → v0.20 | 0 | 0 | 0 |
| v0.20 → v1.0 | 2 | 3 | 2 (auto), 2 (manual) |
| v1.0 → v2.0 | 4 | 5+ | 3 (auto), múltiples (manual) |

### 8.2 Detalle de Breaking Changes

#### v0.20 → v1.0

| ID | Componente | Cambio | Impacto | Esfuerzo Migración |
|----|-----------|--------|---------|-------------------|
| BC-001 | Event Bus | Sinc → Async | Alto (subscribers custom) | 4-8h |
| BC-002 | Plugin Manifest | v1 → v2 | Bajo (auto-migrado) | 0h (tool) |
| BC-003 | Config API | `GetValue` → `GetTyped<T>` | Bajo (deprecatado) | 2-4h |

#### v1.0 → v2.0

| ID | Componente | Cambio | Impacto | Esfuerzo Migración |
|----|-----------|--------|---------|-------------------|
| BC-004 | IPlugin | v1 → v2 (SPI) | Alto (plugins custom) | 8-40h |
| BC-005 | Manifest | v2 → v3 | Bajo (auto-migrado) | 0h (tool) |
| BC-006 | Event system | DomainEvent → CloudEvent | Alto | 8-16h |
| BC-007 | Sandbox API | `Execute` → `Submit(JobRequest)` | Alto | 4-8h |

### 8.3 Política de Deprecación

```
┌─────────────────────────────────────────────────────────────────┐
│  DEPRECATION POLICY                                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  1. Toda API a eliminar se marca @Deprecated en release N       │
│  2. Documenta el reemplazo en migration guide                   │
│  3. Advertencia emitida al usar la API deprecated               │
│  4. Eliminación solo en el siguiente major bump                 │
│  5. Tool de migración automática (cuando sea posible)           │
│                                                                  │
│  Ejemplo timeline:                                               │
│  ├─ v0.20: Config.GetValue() marked @Deprecated                 │
│  ├─ v1.0:  Warning emitted on use, migration tool available     │
│  ├─ v1.5:  API still works, stronger warning                    │
│  └─ v2.0:  API removed                                          │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. Migrations Guide Overview

### 9.1 Migration Tools

Cada major release (y minor con changes significativos) incluye una herramienta de migración:

```
hermes migrate --from <ORIGIN> --to <TARGET> [OPTIONS]

OPTIONS:
  --dry-run            Simula la migración sin aplicar cambios
  --backup             Crea backup completo antes (default: ON)
  --validate           Valida el resultado post-migración
  --report             Genera reporte detallado
  --force              Fuerza migración incluso con warnings
```

### 9.2 Guía de Migraciones por Release

| De → A | Complejidad | Duración típica | Herramientas automáticas |
|--------|-------------|----------------|--------------------------|
| v0.18 → v0.19 | Sin migración (compatible) | N/A | N/A |
| v0.19 → v0.20 | Sin migración (compatible) | N/A | N/A |
| v0.20 → v1.0 | Media | 2-4h para custom plugins | ✓ manifest, ✓ config |
| v1.0 → v2.0 | Alta | 1-5 días | ✓ manifest, ✓ config, ✓ data format |

### 9.3 Rollback de Migration

Si la migración falla o causa problemas:

```
hermes migrate --rollback-to <version>

• Restaura backup pre-migración
• Vuelve a versión anterior del código
• Preserva user data
```

---

## 10. Criterios de Éxito Globales

### 10.1 Scorecard Consolidado

```
┌─────────────────────────────────────────────────────────────────┐
│                    GLOBAL SCORECARD                               │
├────────────┬────────┬────────┬────────┬────────┬─────────────────┤
│  KPI       │  v0.18 │  v0.19 │  v0.20 │  v1.0  │  v2.0          │
│            │  (act) │        │        │  (GA)  │                │
├────────────┼────────┼────────┼────────┼────────┼─────────────────┤
│  ORR Score │  64%   │  75%   │  82%   │  95%   │  98%           │
│  Coverage  │  70%   │  75%   │  78%   │  85%   │  90%           │
│  p99 Lat.  │  N/A   │  <500ms│  <500ms│  <200ms│  <100ms        │
│  Bugs Sev1 │   0    │   0    │   0    │   0    │   0            │
│  Bugs Sev2 │   ~1   │   0    │   0    │   0    │   0            │
│  Scenarios │  7/12  │  12/12 │  12/12 │  12/12 │  20+           │
│  Contexts  │  2/6   │  6/6   │  6/6   │  6/6   │  8+            │
│  Templates │   0    │   0    │  5+    │  10+   │  30+           │
│  Plugins   │   ~5   │   ~5   │   ~8   │  15+   │  50+           │
│  Docs %    │  70%   │  80%   │  88%   │  100%  │  100%          │
│            │        │        │        │        │                │
└────────────┴────────┴────────┴────────┴────────┴─────────────────┘
```

### 10.2 Criterios Gate por Release

| Criterio | v0.18.5 M1 | v0.19.5 M2 | v0.20.5 M3 | v1.0 M4 | v2.0 M5 |
|----------|-----------|-----------|-----------|--------|--------|
| Tests PASSED | ≥ 70% cov | ≥ 75% cov | ≥ 78% cov | ≥ 85% cov | ≥ 90% cov |
| ORR | ≥ 68% | ≥ 75% | ≥ 82% | ≥ 95% | ≥ 98% |
| Bugs Sev1 | 0 | 0 | 0 | 0 | 0 |
| Bugs Sev2 | < 3 | 0 | 0 | 0 | 0 |
| Performance | baseline | no- degrade | no-degrade | p99<200ms | p99<100ms |
| Docs updated | ✓ | ✓ | ✓ | ✓ (100%) | ✓ |
| Migration tools | N/A | N/A | N/A | ✓ | ✓ |
| Sign-offs | 1 | 1 | 2 | 3 | 3 |

### 10.3 Release Readiness Checklist Global

Antes de cualquier release:

```
┌─────────────────────────────────────────────────────────────────┐
│  RELEASE READINESS CHECKLIST                                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  □ Todos los tests unitarios e integración pasando              │
│  □ Performance tests sin regresión                              │
│  □ Security scan sin vulnerabilidades conocidas                 │
│  □ Code review aprobado                                         │
│  □ Changelog completo y revisado                                │
│  □ Documentation actualizada                                    │
│  □ Migration tools (si aplica) probados                         │
│  □ Release notes redactadas                                     │
│  □ Tag creado en repositorio                                    │
│  □ Package build exitoso                                        │
│  □ Smoke test en ambiente de staging                           │
│  □ Rollback procedure validado                                  │
│  □ Sign-off de stakeholders                                     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Navegación Final

| Documento | Enlace | Propósito |
|-----------|--------|-----------|
| Master Roadmap | [01_MASTER_ROADMAP.md](01_MASTER_ROADMAP.md) | Plan maestro |
| Sandbox Engine | [02_SANDBOX_ENGINE.md](02_SANDBOX_ENGINE.md) | Motor de sandbox |
| Developer Context | [03_DEVELOPER_CONTEXT.md](03_DEVELOPER_CONTEXT.md) | Contexto del dev |
| Project Wizard | [04_PROJECT_WIZARD.md](04_PROJECT_WIZARD.md) | Asistente de proyectos |
| Session Memory | [05_SESSION_MEMORY.md](05_SESSION_MEMORY.md) | Motor de memoria |
| Architecture Target | [06_ARCHITECTURE_TARGET.md](06_ARCHITECTURE_TARGET.md) | Arquitectura |
| Full Backlog | [07_BACKLOG.md](07_BACKLOG.md) | Historias |
| Risk Register | [08_RISK_REGISTER.md](08_RISK_REGISTER.md) | Riesgos |
| Release Plan | [09_RELEASE_PLAN.md](09_RELEASE_PLAN.md) | **Este documento** |
| Metrics & KPIs | [10_METRICS_KPI.md](10_METRICS_KPI.md) | Métricas |

---

## Anexos

### Anexo A: Comunicación de Releases

| Canal | Contenido | Timing |
|-------|-----------|--------|
| Release Notes (GitHub) | Detallado con features/fixes/breaking | On release |
| Internal newsletter | Resumen ejecutivo | On release |
| Migration guide | Detallado para upgrades | On major/minor release |
| Community forum | Q&A, troubleshooting | Post-release |

### Anexo B: Matriz RACI (por release)

| Actividad | Architecture Board | Eng Manager | Product Owner | QA Lead | Ops Lead |
|-----------|-------------------|-------------|---------------|---------|----------|
| Planificación | A | R | C | C | C |
| Desarrollo | I | A/R | I | I | I |
| Testing | I | A | I | R | C |
| Documentation | A | C | C | R | C |
| Release approval | A/R | R | R | R | R |
| Migration support | I | R | I | C | A/R |
| Post-release review | A | R | R | R | R |

### Anexo C: Historial de Cambios

| Fecha | Versión | Autor | Cambios |
|-------|---------|-------|---------|
| 2026-07-07 | 1.0.0 | HERMES Enterprise Architecture Board | Versión inicial DRAFT |

---

> **Prev:** [08_RISK_REGISTER.md](08_RISK_REGISTER.md) | **Next:** [10_METRICS_KPI.md](10_METRICS_KPI.md)
