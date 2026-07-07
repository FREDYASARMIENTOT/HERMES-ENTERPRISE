---
title: HERMES Enterprise - Master Roadmap
date: 2026-07-07
author: HERMES Enterprise Architecture Board
status: DRAFT
version: 1.0.0
related_docs:
  - 02_SANDBOX_ENGINE.md
  - 03_DEVELOPER_CONTEXT.md
  - 04_PROJECT_WIZARD.md
  - 05_SESSION_MEMORY.md
  - 06_ARCHITECTURE_TARGET.md
  - 07_BACKLOG.md
  - 08_RISK_REGISTER.md
  - 09_RELEASE_PLAN.md
  - 10_METRICS_KPI.md
---

# HERMES Enterprise — Master Roadmap

> Documento maestro de evolución arquitectónica y funcional del framework  
> **Versión actual:** 0.9.1 (v0.18 — Sandbox Stabilization)  
> **Nivel de madurez:** 64% (según ORR.md)  
> **Fecha de emisión:** 2026-07-07  
> **Próximo hito:** v0.19 — Snapshot/Restore + Developer Context

---

## Navegación

| Documento | Descripción |
|-----------|-------------|
| → [02_SANDBOX_ENGINE.md](02_SANDBOX_ENGINE.md) | Motor de Sandbox y escenarios |
| → [03_DEVELOPER_CONTEXT.md](03_DEVELOPER_CONTEXT.md) | Contexto de desarrollador |
| → [04_PROJECT_WIZARD.md](04_PROJECT_WIZARD.md) | Asistente de proyectos |
| → [05_SESSION_MEMORY.md](05_SESSION_MEMORY.md) | Motor de memoria y sesión |
| → [06_ARCHITECTURE_TARGET.md](06_ARCHITECTURE_TARGET.md) | Arquitectura objetivo |
| → [07_BACKLOG.md](07_BACKLOG.md) | Backlog completo de ítems |
| → [08_RISK_REGISTER.md](08_RISK_REGISTER.md) | Registro de riesgos |
| → [09_RELEASE_PLAN.md](09_RELEASE_PLAN.md) | Plan de releases |
| → [10_METRICS_KPI.md](10_METRICS_KPI.md) | Métricas e indicadores |

---

## Tabla de Contenidos

1. [Executive Summary](#executive-summary)
2. [Estado Actual del Framework](#estado-actual-del-framework)
3. [Evaluación de Madurez](#evaluación-de-madurez)
4. [Arquitectura Actual](#arquitectura-actual)
5. [Arquitectura Objetivo](#arquitectura-objetivo)
6. [Análisis de Brechas](#análisis-de-brechas)
7. [Roadmap Completo (Sprints)](#roadmap-completo)
8. [Timeline (Gantt)](#timeline)
9. [Prioridades](#prioridades)
10. [Riesgos](#riesgos)
11. [Dependencias](#dependencias)
12. [KPIs](#kpis)
13. [Definition of Done](#definition-of-done)
14. [Definition of Ready](#definition-of-ready)
15. [Estrategia de Release](#estrategia-de-release)
16. [Versioning (SemVer)](#versioning)
17. [Métricas](#métricas)
18. [Estimaciones](#estimaciones)
19. [Backlog Completo](#backlog-completo)
20. [Navegación Final](#navegación-final)

---

## 1. Executive Summary

HERMES Enterprise es un framework de automatización de nivel empresarial construido sobre PowerShell 7 y .NET, diseñado para proveer un entorno de desarrollo controlado, seguro y extensible. El framework opera como un motor orquestador (`motor/`) que coordina 21 submódulos especializados para proveer capacidades de sandboxing, contexto de desarrollador, gestión de sesiones, plugins, validación, logging, seguridad y más.

**Estado actual:** 64% de readiness (ORR.md). El núcleo del motor funciona correctamente con el Sandbox Engine en 7 escenarios de prueba, pero carece de capacidades críticas para una plataforma enterprise de producción madura.

**Visión:** Evolucionar desde un framework funcional de nivel alpha hacia una plataforma enterprise autónoma y productiva, completando las capacidades faltantes en 4 sprints mayores, con un horizonte de 6-9 meses hasta la versión GA (v1.0).

**Objetivos estratégicos:**

| Objetivo | Métrica de éxito | Horizonte |
|----------|------------------|-----------|
| Estabilización completa del Sandbox | 100% escenarios PAS (12/12) | Sprint A |
| Snapshot/Restore operativo | <5s por snapshot, 0 data loss | Sprint B |
| Developer Context completo | 6/6 contextos activos | Sprint B |
| Motor de memoria persistente | <100ms latencia lectura | Sprint C |
| Plataforma enterprise GA | 0 bugs críticos, 99.9% uptime | Sprint D |
| Plataforma autónoma | <30s tiempo a productivo | Post-GA |

**Inversión estimada total:** ~2,400 horas-hombre / ~480 story points distribuidos en 4 sprints mayores y múltiples menores.

---

## 2. Estado Actual del Framework

### 2.1 Estructura del Proyecto

```
D:\HERMES-ENTERPRISE\
├── motor/                          # Motor principal (engine)
│   ├── bootstrap/                  # Inicialización del framework
│   ├── configuracion/              # Sistema de configuración
│   ├── context/                    # Contexto de ejecución
│   ├── contracts/                  # Contratos/Interfaces
│   ├── dependencias/               # Gestión de dependencias
│   ├── dependencygraph/            # Grafo de dependencias
│   ├── discovery/                  # Descubrimiento de módulos
│   ├── eventos/                    # Bus de eventos internos
│   ├── kernel/                     # Núcleo del motor
│   ├── lifecycle/                  # Ciclo de vida de componentes
│   ├── logging/                    # Sistema de logging
│   ├── manifest/                   # Manifests de capacidades
│   ├── plugins/                    # Sistema de plugins
│   ├── providers/                  # Proveedores de servicios
│   ├── registro/                   # Registro de servicios
│   ├── runtime/                    # Runtime de ejecución
│   ├── sandbox/                    # Motor de sandbox (principal)
│   ├── security/                   # Seguridad y políticas
│   ├── session/                    # Gestión de sesiones
│   ├── validation/                 # Validación de entrada
│   └── wizards/                    # Asistentes interactivos
├── scripts/                        # Scripts de soporte (9 sandbox)
│   ├── sandbox-runner.ps1
│   ├── sandbox-validator.ps1
│   ├── sandbox-isolation.ps1
│   ├── sandbox-cleanup.ps1
│   ├── sandbox-report.ps1
│   ├── sandbox-snapshot.ps1
│   ├── sandbox-restore.ps1
│   ├── sandbox-audit.ps1
│   └── sandbox-teardown.ps1
├── pruebas/                        # Suite de tests unitarios
│   ├── unit/
│   ├── integration/
│   └── e2e/
├── documentacion/
│   └── roadmap/                    # Documentación de planificación
└── ORR.md                          # Operational Readiness Report
```

### 2.2 Submódulos: Estado por Módulo

| Módulo | Estado | Descripción | Readiness |
|--------|--------|-------------|-----------|
| `bootstrap` | ✅ Estable | Inicialización del motor | 100% |
| `configuracion` | ✅ Estable | Carga y validación de config | 95% |
| `context` | ⚠️ Parcial | Contexto de ejecución básico | 45% |
| `contracts` | ✅ Estable | Interfaces/contratos base | 85% |
| `dependencias` | ✅ Estable | Resolución de dependencias | 90% |
| `dependencygraph` | ✅ Estable | DAG de dependencias | 88% |
| `discovery` | ✅ Estable | Auto-descubrimiento de módulos | 85% |
| `eventos` | ⚠️ Parcial | Bus de eventos interno | 60% |
| `kernel` | ✅ Estable | Núcleo del motor | 92% |
| `lifecycle` | ✅ Estable | Ciclo de vida de componentes | 88% |
| `logging` | ✅ Estable | Logging estructurado | 90% |
| `manifest` | ✅ Estable | Manifests de capacidades | 85% |
| `plugins` | ⚠️ Parcial | Sistema de plugins extensible | 55% |
| `providers` | ⚠️ Parcial | Proveedores de servicios | 60% |
| `registro` | ✅ Estable | Registro de servicios | 87% |
| `runtime` | ✅ Estable | Runtime de ejecución | 90% |
| `sandbox` | ⚠️ Parcial | Motor de sandbox (7/12 escenarios) | 70% |
| `security` | ⚠️ Parcial | Políticas y aislamiento | 55% |
| `session` | ⚠️ Parcial | Gestión de sesiones | 50% |
| `validation` | ✅ Estable | Validación de entrada | 85% |
| `wizards` | ⚠️ Parcial | Asistentes interactivos | 40% |

**Resumen:** 13 módulos estables, 8 en estado parcial. Promedio general: **64%**.

### 2.3 Capacidades Actuales

| Capacidad | Estado | Cobertura |
|-----------|--------|-----------|
| Sandbox Engine | ✅ Funcional | 7 escenarios de 12 |
| Execution Supervisor | ✅ Funcional | Supervisión básica |
| Developer Context (básico) | ⚠️ Parcial | 2/6 contextos |
| Project Wizard (parcial) | ⚠️ Parcial | Flujo básico |
| VS Code Integration (parcial) | ⚠️ Parcial | Sin auto-config |
| Git Workflow (básico) | ⚠️ Parcial | Sin auto-first-commit |
| Reports | ✅ Completo | Reportes funcionales |
| Snapshot/Restore/Rollback | ❌ No implementado | 0% |
| Memory Engine | ❌ No implementado | 0% |
| Autonomous Platform | ❌ No implementado | 0% |

---

## 3. Evaluación de Madurez

### 3.1 ORR Score: 64% Readiness

```
┌─────────────────────────────────────────────────────────────────┐
│          OPERATIONAL READINESS REPORT (ORR)                     │
├─────────────────────────────────────────────────────────────────┤
│  Score: ████████████████░░░░░░░░░░░░░░░░░░░░░░  64%           │
│                                                                 │
│  Nivel: ALPHA AVANZADO                                          │
│  Target inmediato: 80% (Beta)                                   │
│  Target GA: 95% (General Availability)                         │
├─────────────────────────────────────────────────────────────────┤
│  Descomposición por dimensión:                                  │
│                                                                 │
│  ████████████████████████████████  Funcionalidad    68%        │
│  ████████████████████████████░░░░  Calidad          62%        │
│  ████████████████████████░░░░░░░░  Estabilidad      58%        │
│  ██████████████████████████████░░  Seguridad        66%        │
│  ████████████████████████████████  Documentación    70%        │
│  ████████████████████░░░░░░░░░░░░  Operabilidad     52%        │
│  ██████████████████████████████░░  Testing          68%        │
│  ██████████████████████████░░░░░░  Performance      62%        │
└─────────────────────────────────────────────────────────────────┘
```

### 3.2 Criterios por Nivel de Madurez

```
┌─────────────────────────────────────────────────────────────────┐
│  MATURITY MODEL                                                 │
├───────────┬───────────┬─────────────────────────────────────────┤
│  Nivel    │  Score    │  Criterios                              │
├───────────┼───────────┼─────────────────────────────────────────┤
│  Alpha    │  40-65%   │  Funcionalidad básica, tests parciales │
│  Beta     │  65-80%   │  Features completas, integración       │
│  RC       │  80-90%   │  Estable, seguros, documentados        │
│  GA (1.0) │  90-98%   │  Production-ready, observabil. total   │
│  Mature   │  98-100%  │  Autónomo, auto-healing, optimizado    │
└───────────┴───────────┴─────────────────────────────────────────┘
```

### 3.3 Brechas Críticas para GA

| Gap | Impacto | Esfuerzo | Prioridad |
|-----|---------|----------|-----------|
| No Snapshot/Restore | Alto — imposibilita rollback | 120h | P0 |
| Developer Context incompleto | Alto — UX deficiente | 80h | P0 |
| VS Code auto-config ausente | Medio — onboarding lento | 40h | P1 |
| Git auto-first-commit ausente | Medio — workflow manual | 20h | P1 |
| Memory engine ausente | Alto — sin persistencia estado | 160h | P1 |
| Project generator incompleto | Alto — onboarding manual | 100h | P1 |
| Event bus limitado | Medio — acoplamiento alto | 60h | P2 |
| Plugin system parcial | Medio — extensibilidad limitada | 80h | P2 |

### 3.4 Roadmap de Madurez

```
    100% ┤
         │
     95% ┤                                          ╭───── GA (v1.0)
     90% ┤                                    ╭─────╯
     85% ┤                              ╭─────╯
     80% ┤                        ╭─────╯  ─ ─ ─ ─ ─ ─ Beta threshold
     75% ┤                  ╭─────╯
     70% ┤            ╭─────╯
     65% ┤      ╭─────╯  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ Alpha→Beta transition
  ★ 64% ┤──────○─────────────────────────────────────────── TODAY
     60% ┤
     55% ┤
     50% ┤
         │
         └──────┬──────┬──────┬──────┬──────┬──────┬──────┬──
               v0.18  v0.19  v0.20  v0.21  v1.0   v1.x   v2.0
```

---

## 4. Arquitectura Actual

### 4.1 Diagrama de Arquitectura Actual

```
┌─────────────────────────────────────────────────────────────────────┐
│                    HERMES ENTERPRISE — ARQUITECTURA ACTUAL          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                   PRESENTATION LAYER                        │   │
│  │  ┌──────────┐  ┌──────────┐  ┌───────────────────────┐    │   │
│  │  │  Wizards │  │  VS Code │  │  CLI Interface (WIP)  │    │   │
│  │  │ (parcial)│  │ (parcial)│  │                       │    │   │
│  │  └────┬─────┘  └────┬─────┘  └───────────┬───────────┘    │   │
│  └───────┼───────────────┼────────────────────┼───────────────┘   │
│          │               │                    │                    │
│  ┌───────┼───────────────┼────────────────────┼───────────────┐   │
│  │       ▼               ▼                    ▼               │   │
│  │                   APPLICATION LAYER                          │   │
│  │  ┌──────────────────────────────────────────────────────┐  │   │
│  │  │              MOTOR / KERNEL                          │  │   │
│  │  │  ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │  │   │
│  │  │  │ Bootstrap│ │Lifecycle │ │  Dependency Graph  │   │  │   │
│  │  │  └──────────┘ └──────────┘ └───────────────────┘   │  │   │
│  │  │  ┌──────────┐ ┌──────────┐ ┌───────────────────┐   │  │   │
│  │  │  │ Discovery│ │ Contracts│ │   Manifest        │   │  │   │
│  │  │  └──────────┘ └──────────┘ └───────────────────┘   │  │   │
│  │  └──────────────────────────────────────────────────────┘  │   │
│  │                                                             │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │   │
│  │  │ Sandbox  │ │ Session  │ │ Plugins  │ │  Providers   │  │   │
│  │  │ Engine   │ │ Manager  │ │ Manager  │ │  Registry    │  │   │
│  │  │ (7/12)   │ │ (parcial)│ │ (parcial)│ │              │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                    DOMAIN LAYER                              │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │   │
│  │  │ Context  │ │ Events   │ │ Security │ │  Validation  │  │   │
│  │  │ Manager  │ │ Bus      │ │ Layer    │ │  Engine      │  │   │
│  │  │ (partial)│ │(partial) │ │(partial) │ │              │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                 INFRASTRUCTURE LAYER                         │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │   │
│  │  │ Runtime  │ │ Logging  │ │ Config   │ │  Registro    │  │   │
│  │  │ Engine   │ │ System   │ │ Store    │ │  (internal)  │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │               CROSS-CUTTING CONCERNS                         │   │
│  │  ┌───────────────────────────────────────────────────────┐  │   │
│  │  │  ❌ Snapshot/Restore  ❌ Memory Engine                 │  │   │
│  │  │  ❌ Auto-Configuration   ❌ Telemetry                 │  │   │
│  │  │  ❌ Health Checks        ❌ Circuit Breakers          │  │   │
│  │  └───────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

LEGENDA:
  ✅ = Estable/Completo    ⚠️ = Parcial    ❌ = No implementado
```

### 4.2 Diagrama de Flujo de Datos Actual

```
┌──────────┐     ┌──────────┐     ┌──────────┐     ┌──────────┐
│  Usuario │────▶│  Wizard  │────▶│  Kernel  │────▶│ Sandbox  │
│          │     │  (WIP)   │     │  (vía    │     │  Engine  │
└──────────┘     └──────────┘     │ bootstrap│     │  (7/12)  │
                                   └────┬─────┘     └────┬─────┘
                                        │                │
                                        ▼                ▼
                                   ┌──────────┐    ┌──────────┐
                                   │ Context  │    │ Output/  │
                                   │ Manager  │    │ Reports  │
                                   │ (partial)│    └──────────┘
                                   └──────────┘

NOTA: No hay flujo de Snapshot/Restore. No hay memoria persistente.
      El contexto se pierde al cerrar sesión.
```

### 4.3 Limitaciones Identificadas

| # | Limitación | Impacto | Severidad |
|---|-----------|---------|-----------|
| 1 | No persistence between sessions | Pérdida de estado/estado del desarrollador | 🔴 Crítico |
| 2 | No snapshot/rollback | No hay forma de revertir operaciones destructivas | 🔴 Crítico |
| 3 | Context incompleto | El motor no conoce arquitectura, tareas ni objetivos | 🟠 Alto |
| 4 | Event bus síncrono | Acoplamiento temporal entre componentes | 🟠 Alto |
| 5 | Sin auto-config VS Code | Onboarding manual del IDE | 🟡 Medio |
| 6 | Sin auto-first-commit | Workflow git inicial manual | 🟡 Medio |
| 7 | Plugin system rígido | Dificulta extensión | 🟡 Medio |
| 8 | Observability básica | No hay métricas/telemetría en runtime | 🟡 Medio |

---

## 5. Arquitectura Objetivo

> **Referencia completa:** [06_ARCHITECTURE_TARGET.md](06_ARCHITECTURE_TARGET.md)

### 5.1 Principios Rectores

| Principio | Descripción | Aplicación |
|-----------|-------------|------------|
| **Separation of Concerns** | Cada capa tiene una responsabilidad única | 5 capas claramente definidas |
| **Dependency Inversion** | Depender de abstracciones, no de implementaciones | Contrato + Inyección |
| **Event-Driven** | Comunicación asíncrona entre dominios | Bus de eventos pub/sub |
| **Plugin Architecture** | Extensibilidad sin modificación del core | SPI points |
| **Persistence-First** | Estado persistente por defecto | Memory Engine + CQRS |
| **Observable** | Telemetría y health checks en todo el stack | OpenTelemetry + custom |
| **Idempotent Operations** | Operaciones repetibles sin efectos secundarios | Snapshot/Restore |

### 5.2 Capas Objetivo

```
┌─────────────────────────────────────────────────────────────────┐
│                    ARQUITECTURA OBJETIVO                         │
│                   (Ver 06_ARCHITECTURE_TARGET.md)                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  PRESENTATION (Presentation Layer)                       │  │
│  │  • VS Code Extension (auto-configurada)                  │  │
│  │  • Interactive CLI                                       │  │
│  │  • Web Dashboard (v2.0)                                  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  APPLICATION (Application Services)                      │  │
│  │  • Sandbox Orchestrator                                  │  │
│  │  • Project Generator                                     │  │
│  │  • Session Manager                                       │  │
│  │  • Memory Engine                                         │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  DOMAIN (Domain Layer)                                   │  │
│  │  • Snapshot/Restore/Rollback                             │  │
│  │  • Developer Context (6/6 contexts)                      │  │
│  │  • Event Bus (async pub/sub)                             │  │
│  │  • Security Policies                                     │  │
│  │  • Validation Engine                                     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  INFRASTRUCTURE (Infrastructure Layer)                   │  │
│  │  • Runtime Engine                                        │  │
│  │  • Persistence (SQLite/JSON file store)                  │  │
│  │  • Logging & Telemetry (OpenTelemetry)                   │  │
│  │  • Configuration Store                                   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │  CROSS-CUTTING (Transversal)                             │  │
│  │  • Health Checks & Circuit Breakers                      │  │
│  │  • Auto-Configuration (VS Code, Git)                     │  │
│  │  • Observability & Metrics                               │  │
│  │  • Plugin SPI                                            │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Análisis de Brechas (Gap Analysis)

### 6.1 Tabla de Brechas Completa

| # | Capacidad Requerida | Estado Actual | Gap | Esfuerzo | Sprint | Prioridad |
|---|---------------------|---------------|-----|----------|--------|-----------|
| GAP-001 | Snapshot Engine | ❌ No existe | Completo | 80h | A | P0 |
| GAP-002 | Restore Engine | ❌ No existe | Completo | 40h | A | P0 |
| GAP-003 | Rollback Mechanism | ❌ No existe | Completo | 30h | B | P1 |
| GAP-004 | Context: Architecture | ❌ No existe | Completa | 20h | B | P0 |
| GAP-005 | Context: Tasks | ❌ No existe | Completo | 15h | B | P0 |
| GAP-006 | Context: Objectives | ❌ No existe | Completo | 15h | B | P0 |
| GAP-007 | Context: CodingStandards | ❌ No existe | Completo | 15h | B | P0 |
| GAP-008 | Context: Environment | ⚠️ Parcial | Completar | 15h | B | P1 |
| GAP-009 | VS Code Auto-Config | ❌ No existe | Completo | 40h | C | P1 |
| GAP-010 | Git Auto-First-Commit | ❌ No existe | Completo | 20h | A | P1 |
| GAP-011 | Memory Engine | ❌ No existe | Completo | 160h | C | P1 |
| GAP-012 | Project Generator | ⚠️ Parcial | Completar | 100h | C | P1 |
| GAP-013 | Event Bus Async | ⚠️ Síncrono | Reescribir | 60h | D | P2 |
| GAP-014 | Plugin System Completo | ⚠️ Parcial | Completar | 80h | D | P2 |
| GAP-015 | Telemetry & Observability | ❌ No existe | Completo | 60h | D | P2 |
| GAP-016 | Health Checks | ❌ No existe | Completo | 30h | D | P2 |
| GAP-017 | Circuit Breakers | ❌ No existe | Completo | 20h | D | P2 |
| GAP-018 | Security Hardening | ⚠️ Parcial | Completar | 50h | D | P1 |
| GAP-019 | Performance Optimization | ⚠️ No sistemático | Completo | 40h | D | P2 |
| GAP-020 | Documentation Complete | ⚠️ Parcial | Completar | 30h | B | P1 |
| GAP-021 | Scenario Tests 8-12 | ❌ Faltan 5 | Completo | 60h | A | P0 |
| GAP-022 | Integration Tests | ⚠️ Básicos | Completar | 50h | C | P1 |
| GAP-023 | E2E Tests | ⚠️ Básicos | Completar | 40h | D | P2 |

### 6.2 Resumen Visual de Brechas

```
                    Estado Actual vs. Objetivo
                    
Código          Estado              Estado
actual          esperado            gap
─────────────────────────────────────────────────
Snapshot/Restore      ───────╸    ██████████████  85%
Developer Context     ████░░──    ██████████████  35%
VS Code Config        ───────╸    ██████████████  95%
Git Auto-Commit       ───────╸    ██████████████  90%
Memory Engine         ───────╸    ██████████████ 100%
Project Generator     ██░░░░──    ██████████████  55%
Event Bus Async       ██░░░░──    ██████████████  50%
Plugin System         ████░░──    ██████████████  40%
Telemetry             ───────╸    ██████████████ 100%
Security              █████░──    ██████████████  15%

Leyenda: ████ = Completado    ░░░░ = Parcial    ──── = Ausente
```

### 6.3 Costo Total de Brechas

| Categoría | Total Horas | Total Story Points |
|-----------|-------------|-------------------|
| P0 (Crítico) | 195h | 39 SP |
| P1 (Alto) | 345h | 69 SP |
| P2 (Medio) | 280h | 56 SP |
| P3 (Low/Future) | 120h | 24 SP |
| **TOTAL** | **940h** | **188 SP** |

---

## 7. Roadmap Completo

### 7.1 Visión General de Sprints

```
┌─────────────────────────────────────────────────────────────────────┐
│                     ROADMAP — SPRINTS                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  Sprint A ──────── Sprint B ──────── Sprint C ──────── Sprint D   │
│  "Foundation"     "Context"        "Intelligence"   "Platform"     │
│                                                                     │
│  4 semanas        4 semanas        5 semanas        5 semanas      │
│  v0.18 → v0.18.5  v0.18.5 → v0.19  v0.19 → v0.20   v0.20 → v1.0 │
│                                                                     │
│  ─────────────────────────────────────────────────────────────────  │
│                                                                     │
│  Post-GA ──────────────────────────────────────────────────────     │
│  v1.x (incremental) → v2.0 (Autonomous Platform)                  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 7.2 Sprint A — "Foundation & Stabilization"

**Duración:** 4 semanas (semanas 1-4)  
**Versión objetivo:** v0.18.5  
**Objetivo principal:** Estabilizar el Sandbox Engine y completar los escenarios de prueba faltantes (8-12). Implementar Git auto-first-commit como quick win.

#### Historias del Sprint A

| ID | Historia | Story Points | Esfuerzo (h) | Prioridad |
|----|----------|-------------|--------------|-----------|
| SA-001 | Implementar Scenario 8: Isolated Build Environment | 8 | 16h | P0 |
| SA-002 | Implementar Scenario 9: Network-Restricted Sandbox | 8 | 16h | P0 |
| SA-003 | Implementar Scenario 10: Multi-Tenant Sandbox | 13 | 24h | P0 |
| SA-004 | Implementar Scenario 11: Resource-Limited Sandbox | 8 | 16h | P0 |
| SA-005 | Implementar Scenario 12: Full Integration Scenario | 13 | 24h | P0 |
| SA-006 | Git auto-first-commit (hook post-init) | 5 | 8h | P1 |
| SA-007 | Snapshot Engine — Phase 1 (state capture) | 8 | 16h | P0 |
| SA-008 | Snapshot Engine — Phase 2 (storage/serialization) | 5 | 12h | P0 |
| SA-009 | Sandbox stabilization & hardening (bug fixes) | 5 | 10h | P1 |
| SA-010 | Test coverage improvement (unit + integration) | 5 | 10h | P1 |
| **TOTAL** | | **78 SP** | **152h** | |

#### Criterios de Éxito Sprint A

- [ ] 12/12 Sandbox scenarios passing
- [ ] Test coverage > 70%
- [ ] Git auto-first-commit funcional
- [ ] Snapshot Engine captura estado sin corrupción
- [ ] 0 bugs críticos abiertos
- [ ] Performance baseline establecido

---

### 7.3 Sprint B — "Context & Completeness"

**Duración:** 4 semanas (semanas 5-8)  
**Versión objetivo:** v0.19  
**Objetivo principal:** Completar el Developer Context (6/6 contextos activos), implementar Snapshot/Restore/Rollback completo, y documentación funcional.

#### Historias del Sprint B

| ID | Historia | Story Points | Esfuerzo (h) | Prioridad |
|----|----------|-------------|--------------|-----------|
| SB-001 | Restore Engine implementado | 8 | 16h | P0 |
| SB-002 | Rollback Mechanism (punto en el tiempo) | 8 | 16h | P1 |
| SB-003 | Context: Architecture provider | 5 | 10h | P0 |
| SB-004 | Context: Tasks provider | 5 | 10h | P0 |
| SB-005 | Context: Objectives provider | 5 | 10h | P0 |
| SB-006 | Context: CodingStandards provider | 5 | 10h | P0 |
| SB-007 | Context: Environment completion | 3 | 6h | P1 |
| SB-008 | Context integration & lifecycle | 8 | 16h | P1 |
| SB-009 | Snapshot/Restore integration tests | 5 | 10h | P0 |
| SB-010 | Documentation completion (ORR → 80%) | 5 | 10h | P1 |
| SB-011 | Error handling & recovery hardening | 5 | 8h | P1 |
| **TOTAL** | | **67 SP** | **122h** | |

#### Criterios de Éxito Sprint B

- [ ] Snapshot/Restore/Rollback 100% funcional
- [ ] Developer Context 6/6 implementado
- [ ] Restauración en < 5 segundos
- [ ] Rollback a cualquier punto guardado
- [ ] ORR score ≥ 75%
- [ ] Documentación completa de APIs internas

---

### 7.4 Sprint C — "Intelligence & Generation"

**Duración:** 5 semanas (semanas 9-13)  
**Versión objetivo:** v0.20  
**Objetivo principal:** Motor de memoria persistente y generador de proyectos completo. Capacidades de "inteligencia empresarial".

#### Historias del Sprint C

| ID | Historia | Story Points | Esfuerzo (h) | Prioridad |
|----|----------|-------------|--------------|-----------|
| SC-001 | Memory Engine — Architecture (storage) | 13 | 24h | P1 |
| SC-002 | Memory Engine — Query/Retrieve API | 8 | 16h | P1 |
| SC-003 | Memory Engine — Lifecycle (eviction/compaction) | 8 | 16h | P1 |
| SC-004 | Memory Engine — Persistence (SQLite backend) | 8 | 16h | P1 |
| SC-005 | VS Code Extension — Auto-Configuration | 8 | 16h | P1 |
| SC-006 | VS Code Integration — Status Bar/Indicators | 5 | 10h | P1 |
| SC-007 | Project Generator — Templates Engine | 13 | 24h | P1 |
| SC-008 | Project Generator — Multi-framework Support | 8 | 16h | P1 |
| SC-009 | Project Generator — Best Practices Scaffold | 8 | 16h | P1 |
| SC-010 | Integration test suite completion | 5 | 12h | P1 |
| SC-011 | Performance benchmarks & optimization | 5 | 10h | P2 |
| **TOTAL** | | **89 SP** | **170h** | |

#### Criterios de Éxito Sprint C

- [ ] Memory Engine operativo (< 100ms latencia de lectura)
- [ ] Estado persistente entre sesiones
- [ ] VS Code auto-config funcional
- [ ] Project Generator con ≥ 5 templates
- [ ] ORR score ≥ 82%
- [ ] Latencia de respuesta general < 500ms

---

### 7.5 Sprint D — "Enterprise Platform (GA Preparation)"

**Duración:** 5 semanas (semanas 14-18)  
**Versión objetivo:** v1.0 (GA)  
**Objetivo principal:** Preparar la plataforma para producción. Completar event bus async, plugin system robusto, observabilidad completa, security hardening.

#### Historias del Sprint D

| ID | Historia | Story Points | Esfuerzo (h) | Prioridad |
|----|----------|-------------|--------------|-----------|
| SD-001 | Event Bus refactor to async pub/sub | 13 | 24h | P2 |
| SD-002 | Plugin System — SPI completion | 13 | 24h | P2 |
| SD-003 | Plugin System — Hot-reload capability | 8 | 16h | P2 |
| SD-004 | Telemetry & Observability (OpenTelemetry) | 13 | 24h | P2 |
| SD-005 | Health Checks (all components) | 8 | 12h | P2 |
| SD-006 | Circuit Breakers implementation | 5 | 8h | P2 |
| SD-007 | Security Hardening (policies, audit) | 13 | 24h | P1 |
| SD-008 | Performance optimization (hot paths) | 8 | 16h | P2 |
| SD-009 | E2E test suite completion | 8 | 16h | P2 |
| SD-010 | Production documentation & runbooks | 8 | 16h | P1 |
| SD-011 | Load testing & stress scenarios | 5 | 12h | P2 |
| SD-012 | Release candidate validation | 5 | 8h | P0 |
| **TOTAL** | | **107 SP** | **200h** | |

#### Criterios de Éxito Sprint D

- [ ] Event bus 100% asíncrono
- [ ] Plugin system con hot-reload
- [ ] Observabilidad completa (métricas, traces, logs)
- [ ] 0 bugs de severidad crítica
- [ ] Stress test: 1000 operaciones/min sin degradación
- [ ] ORR score ≥ 95%
- [ ] Documentación de producción completa
- [ ] Runbooks operativos para todos los escenarios de fallo

---

### 7.6 Post-GA — v1.x Incremental / v2.0 Autonomous Platform

| Versión | Época | Temas |
|---------|-------|-------|
| v1.1 | Sprint Post-GA +4sem | Multi-language support, Web Dashboard MVP |
| v1.2 | Sprint Post-GA +8sem | Distributed execution, Cloud providers |
| v2.0 | Sprint Post-GA +16sem | Autonomous Platform (self-healing, AI-assisted, predictive) |

---

## 8. Timeline

### 8.1 Gantt ASCII

```
2026
Jul         Ago         Sep         Oct         Nov         Dic         Ene 2027
W27-30      W31-34      W35-39      W40-44      W45-49      W50-52      W01-04
├───────────┼───────────┼───────────┼───────────┼───────────┼───────────┤
│           │           │           │           │           │           │
│◄──Sprint A─────────►  │           │           │           │           │
│  Foundation           │           │           │           │           │
│  (4 semanas)          │           │           │           │           │
│  v0.18 → v0.18.5     │           │           │           │           │
│           │           │           │           │           │           │
│           │◄──Sprint B───────────►│           │           │           │
│           │  Context              │           │           │           │
│           │  (4 semanas)          │           │           │           │
│           │  v0.18.5 → v0.19     │           │           │           │
│           │           │           │           │           │           │
│           │           │◄──Sprint C────────────►│           │           │
│           │           │  Intelligence         │           │           │
│           │           │  (5 semanas)          │           │           │
│           │           │  v0.19 → v0.20       │           │           │
│           │           │           │           │           │           │
│           │           │           │◄──Sprint D────────────►│           │
│           │           │           │  Platform/GA           │           │
│           │           │           │  (5 semanas)           │           │
│           │           │           │  v0.20 → v1.0        │           │
│           │           │           │           │           │           │
│           │           │           │           │◄──v1.x───────────────►│
│           │           │           │           │  Incremental           │
│           │           │           │           │           │           │
│           │           │           │           │           │◄──v2.0───►│
│           │           │           │           │           │ Autonomous │
│           │           │           │           │           │ Platform   │
└───────────┴───────────┴───────────┴───────────┴───────────┴───────────┘

Milestones:
  ★ M1: Fin Sprint A — Sandbox Stabilized (Fin Semana 4)
  ★ M2: Fin Sprint B — Context Complete (Fin Semana 8)
  ★ M3: Fin Sprint C — Intelligence Ready (Fin Semana 13)
  ★ M4: Fin Sprint D — GA Release v1.0 (Fin Semana 18)
  ★ M5: v2.0 Autonomous Platform (Semana 34 aprox.)
```

### 8.2 Hitos Detallados

| Milestone | Fecha Target | Versión | Descripción |
|-----------|-------------|---------|-------------|
| M1 | 2026-08-03 | v0.18.5 | Sandbox Engine 12/12 scenarios + Snapshot Phase 2 |
| M2 | 2026-08-31 | v0.19 | Snapshot/Restore completo + Developer Context 6/6 |
| M3 | 2026-10-05 | v0.20 | Memory Engine + Project Generator + VS Code Auto-Config |
| M4 | 2026-11-09 | v1.0 | GA — Plataforma Enterprise completa |
| M5 | 2027-03-01 | v2.0 | Plataforma Autónoma |

---

## 9. Prioridades

### 9.1 Matriz de Prioridades (MoSCoW)

```
┌─────────────────────────────────────────────────────────────────────┐
│                    MATRIZ DE PRIORIDADES (MoSCoW)                   │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  P0 — MUST HAVE (Imprescindible para GA)                           │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  • Snapshot Engine (captura de estado)                      │   │
│  │  • Restore Engine (restauración de estado)                  │   │
│  │  • Scenarios 8-12 (Sandbox completa)                        │   │
│  │  • Developer Context completo (Architecture, Tasks,         │   │
│  │    Objectives, CodingStandards)                             │   │
│  │  • Memory Engine (persistencia)                             │   │
│  │  • Security Hardening                                       │   │
│  │  • Release Candidate Validation                             │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  P1 — SHOULD HAVE (Esperado para GA, tolerable sin él 1 release)  │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  • Rollback Mechanism                                       │   │
│  │  • VS Code Auto-Config                                      │   │
│  │  • Git Auto-First-Commit                                    │   │
│  │  • Project Generator                                        │   │
│  │  • Integration Tests                                        │   │
│  │  • Documentation Completion                                 │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  P2 — COULD HAVE (Nice-to-have, post-GA acceptable)               │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  • Event Bus Async Refactor                                 │   │
│  │  • Plugin Hot-Reload                                        │   │
│  │  • Telemetry & Observability                                │   │
│  │  • Health Checks & Circuit Breakers                         │   │
│  │  • E2E Test Suite                                           │   │
│  │  • Performance Optimization                                 │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
│  P3 — WON'T HAVE (este release, but future)                       │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │  • Web Dashboard                                            │   │
│  │  • Cloud Provider Integration                               │   │
│  │  • Distributed Execution                                    │   │
│  │  • AI-Assisted Development                                  │   │
│  │  • Self-Healing Capabilities                                │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 9.2 Priorización por Valor vs. Esfuerzo

```
     VALO
R ↑       ALTO
  │
  │  SA-007    SC-007      SC-001
  │  Snapshot  Proj.Gen    Memory Eng
  │
  │  SA-006    SB-003      SD-007
  │  Git-Auto  Context:A   Security
  │
  │  SA-009    SD-006      SD-004
  │  Fixups    CircuitBr   Telemetry
  │
  │  BAJO                          ALTO
  └──────────────────────────────────▶ ESFUERZO (Horas)
```

---

## 10. Riesgos

> **Referencia completa:** [08_RISK_REGISTER.md](08_RISK_REGISTER.md)

### 10.1 Top Risks

| ID | Riesgo | Prob. | Impacto | Score | Mitigación |
|----|--------|-------|---------|-------|------------|
| R-001 | Scope creep en Sprint A atrasa Snapshot Engine | Media | Alto | 8/10 | Timeboxing estricto, criterios de done claros |
| R-002 | Performance regression en Memory Engine | Alta | Alto | 9/10 | Benchmarks tempranos, profiling continuo |
| R-003 | Complejidad de Rollback con dependencias cruzadas | Alta | Alto | 9/10 | Diseño incremental, tests de restauración |
| R-004 | Incompatibilidad Windows (PS7 constraints) | Media | Medio | 6/10 | Testing multi-plataforma continuo |
| R-005 | Developer burnout (640h en 18 semanas = 35.5h/sem) | Media | Medio | 6/10 | Ritmo sostenible, buffer en estimaciones |
| R-006 | Breaking changes no detectadas | Baja | Alto | 5/10 | SemVer estricto, changelog, migration scripts |

### 10.2 Risk Heat Map

```
IMPACTO
Alto   │ R-002  R-003 │ R-001
       │               │
Medio  │         R-005 │ R-004
       │               │
Bajo   │         R-006 │
       └───────────────┴────────
        Baja    Media   Alta   PROBABILIDAD
```

---

## 11. Dependencias

### 11.1 Dependencias Internas entre Sprints

```
Sprint A ──────▶ Sprint B ──────▶ Sprint C ──────▶ Sprint D
    │                │                │                │
    │ Snapshot       │ Rollback       │ Memory Eng    │ Event Bus
    │ Engine         │ + Context      │ + Proj Gen    │ + Plugins
    │ Scenarios      │ Completion     │ + VS Code     │ + Telemetry
    │                │                │               │
    ▼                ▼                ▼               ▼
  Foundation ◀──── Context     ◀─── Intelligence ◀─ Platform
```

### 11.2 Dependencias Externas

| Dependencia | Tipo | Criticalidad | Plan B |
|-------------|------|--------------|--------|
| PowerShell 7.x | Plataforma | Crítica | Soporte PS 5.1 fallback |
| .NET Runtime (6+) | Runtime | Crítica | Bundle portable |
| VS Code Marketplace | Distribución | Media | VSIX sideload |
| SQLite (memory backend) | Librería | Media | JSON file fallback |
| Git (CLI) | Herramienta | Alta | Optional feature |

### 11.3 Matriz de Dependencias Cruzadas

| Componente A | Depende de | Impacto si A falla |
|--------------|-----------|---------------------|
| Memory Engine | Persistence Layer | Bloquea toda persistencia |
| Snapshot/Restore | Kernel + Runtime | Bloquea rollback |
| Project Generator | Context + Wizard | Bloquea onboarding |
| VS Code Extension | Memory + Context | Degrada UX significativamente |
| Event Bus Async | Kernel contracts | Degrada rendimiento |
| Plugin System | Discovery + Contracts | Limita extensibilidad |

---

## 12. KPIs

### 12.1 KPIs Técnicos

| KPI | Baseline (actual) | Target Sprint B | Target Sprint C | Target GA (v1.0) |
|-----|-------------------|-----------------|-----------------|-------------------|
| ORR Score | 64% | 75% | 82% | 95% |
| Sandbox Scenarios | 7/12 | 12/12 | 12/12 | 12/12 |
| Developer Contexts | 2/6 | 6/6 | 6/6 | 6/6 |
| Test Coverage | ~55% | 70% | 78% | 85% |
| Latencia (p99) | N/A | < 500ms | < 500ms | < 200ms |
| Snapshot Time | N/A | < 5s | < 3s | < 3s |
| Restore Time | N/A | < 5s | < 3s | < 3s |
| Bugs Críticos | 0 | 0 | 0 | 0 |
| Bugs Mayores | ~15 | < 5 | < 2 | 0 |

### 12.2 KPIs de Proceso

| KPI | Baseline | Target | Medición |
|-----|----------|--------|----------|
| Velocity (SP/sprint) | N/A | 75 SP | Sprint review |
| Lead Time (idea→deploy) | N/A | < 14 días | Kanban board |
| Cycle Time (start→done) | N/A | < 5 días | Kanban board |
| Rework Rate | N/A | < 15% | Sprint retrospective |
| Story Predictability | N/A | > 85% | Planned vs. Done |
| Deploy Frequency | N/A | 2x/semana | Release pipeline |

### 12.3 KPIs de Negocio/Producto

| KPI | Baseline | Target | Medición |
|-----|----------|--------|----------|
| Time-to-Productive (new session) | N/A | < 60s | Benchmark |
| Developer Satisfaction | N/A | > 4.0/5.0 | Encuesta interna |
| Plugin Ecosystem Size | 0 | > 10 plugins | Registry |
| Community Contributors | 0 | > 5 | GitHub |
| Documentation Coverage | 70% | 95% | Docs audit |

---

## 13. Definition of Done

### 13.1 DoD para Historias de Usuario

```
┌─────────────────────────────────────────────────────────────────┐
│  DEFINITION OF DONE — HISTORIA DE USUARIO                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  □ Código implementado y revisado (peer review)                 │
│  □ Tests unitarios creados (cobertura ≥ 80% del nuevo código)  │
│  □ Tests de integración actualizados si corresponden            │
│  □ Documentación de API actualizada (comentarios XML/docs)      │
│  □ Changelog actualizado (entrada descriptiva)                  │
│  □ Sin warnings de compilación                                  │
│  □ Sin vulnerabilidades conocidas (scan estático)               │
│  □ Manual de operación actualizado si impacta ops               │
│  □ Aceptado por Product Owner en Sprint Review                  │
│  □ Integrado en rama main (merge limpio, sin conflictos)        │
│  □ Performance baseline no degradado                            │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 13.2 DoD para Release

| Criterio | Requisito |
|----------|-----------|
| Estabilidad | 0 bugs críticos, 0 bugs mayores sin workaround |
| Tests | 100% tests de regresión pasando. Coverage ≥ 80% |
| Performance | No degradation vs. release anterior |
| Security | Scan estático limpio. 0 vulnerabilidades known/CVEs |
| Documentation | Runbooks, API docs, changelog completo |
| Migration | Scripts de migración probados en staging |
| Rollback | Procedimiento de rollback validado |
| Observability | Métricas clave expuestas. Alertas configuradas |
| Sign-OFF | Aprobación de Architecture Board + Ops Lead |

### 13.3 DoD por Nivel de Release

```
┌────────────────────────────────────────────────────────────────────┐
│  DoD POR NIVEL DE RELEASE                                         │
├────────────────┬──────────────────────────────────────────────────┤
│  Nivel         │  Criterios Adicionales                           │
├────────────────┼──────────────────────────────────────────────────┤
│  Alpha (0.x)   │  Tests unitarios pasando, documentación básica  │
│  Beta (0.x.y)  │  + Integration tests, API estable, changelog    │
│  RC (0.9.x)    │  + E2E tests, security scan, performance report │
│  GA (1.0)      │  + Production runbooks, rollback validated,     │
│                │    ORR ≥ 95%, sign-off architecture board       │
└────────────────┴──────────────────────────────────────────────────┘
```

---

## 14. Definition of Ready

### 14.1 DoR para Historias

```
┌─────────────────────────────────────────────────────────────────┐
│  DEFINITION OF READY — HISTORIA DE USUARIO                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  □ Descripción clara del feature (What & Why)                   │
│  □ Criterios de aceptación explícitos (Given/When/Then)         │
│  □ Dependencias identificadas y resueltas o planificadas        │
│  □ Estimación completada (Story Points)                         │
│  □ Diseñado/aprobado en refinamiento técnico                    │
│  □ No bloqueada por otra historia en progreso                   │
│  □ Recursos/skills disponibles en el equipo                     │
│  □ Tests automatizables definidos                               │
│  □ Impacto en performance estimado                              │
│  □ Risk assessment realizado (si aplica)                        │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 14.2 DoR para Sprint (Sprint Ready)

| Criterio | Estado |
|----------|--------|
| Backlog refinado y priorizado | ✅ Requerido |
| Capacidades del equipo asignadas | ✅ Requerido |
| Ambiente de desarrollo funcional | ✅ Requerido |
| Dependencias externas resueltas | ⚠️ Intentar resolver |
| Criterios de éxito del sprint definidos | ✅ Requerido |
| Plan de mitigación de riesgos conocidos | ✅ Requerido |
| Capacity planning (SP disponibles ≥ SP planificados × 0.9) | ✅ Requerido |

---

## 15. Estrategia de Release

### 15.1 Roadmap de Releases

```
┌─────────────────────────────────────────────────────────────────────┐
│                    RELEASE STRATEGY                                  │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  v0.18 (current)  ────  Sandbox Stabilization                     │
│  ├── v0.18.1  ────      Scenarios 8-9 (+ bug fixes)               │
│  ├── v0.18.2  ────      Scenarios 10-11 (+ hardening)             │
│  ├── v0.18.3  ────      Scenario 12 + Snapshot Phase 1            │
│  └── v0.18.5  ────      Snapshot Phase 2 + Git Auto-Commit (M1)   │
│                                                                     │
│  v0.19            ────  Snapshot/Restore + Developer Context       │
│  ├── v0.19.1  ────      Rollback Mechanism                        │
│  ├── v0.19.2  ────      Context completion                        │
│  └── v0.19.5  ────      (Beta) All features integration tested    │
│                                                                     │
│  v0.20            ────  Memory Engine + Project Generator          │
│  ├── v0.20.1  ────      VS Code Auto-Config                       │
│  ├── v0.20.2  ────      Plugin enhancements                       │
│  └── v0.20.5  ────      (RC) Full integration validated           │
│                                                                     │
│  v1.0             ────  GA: Enterprise Platform Complete           │
│  ├── v1.0.1  ────       Patch (critical fixes only)               │
│  ├── v1.0.2  ────       Patch (security, performance)             │
│  └── v1.0.x  ────       LTS track (12 months)                    │
│                                                                     │
│  v2.0             ────  Autonomous Platform (next-gen)             │
│  ├── Web Dashboard, AI-assisted, self-healing                      │
│  ├── Distributed execution, cloud providers                        │
│  └── Predictive analytics, autonomous optimization                 │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

> **Referencia completa:** [09_RELEASE_PLAN.md](09_RELEASE_PLAN.md)

### 15.2 Branching Strategy

```
main ──────────────────────────────────────────────────────────────►
  │        │       │       │       │       │       │
  │        │       │       │       │       │       └── v2.0
  │        │       │       │       │       └── v1.0.2 (patch)
  │        │       │       │       └── v1.0.1 (patch)
  │        │       │       └── v1.0 (GA tag)
  │        │       └── v0.20 (release tag)
  │        └── v0.19 (release tag)
  └── v0.18 (release tag, current)

release/v0.19 ──── feature/SB-001-restore-engine
                   feature/SB-003-context-architecture
                   feature/SB-007-snapshot-restore-integration
```

### 15.3 Promotion Path

```
Development → Feature Branch → Sprint Integration → Release Branch → Staging → Production
```

---

## 16. Versioning (SemVer)

### 16.1 SemVer Applied to HERMES

```
┌─────────────────────────────────────────────────────────────────┐
│  SEMANTIC VERSIONING — HERMES ENTERPRISE                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  MAJOR.MINOR.PATCH                                               │
│                                                                 │
│  MAJOR  → Breaking changes en APIs públicas                     │
│           (motor/kernel contracts, plugin SPI, manifest format) │
│           Ejemplo: 0.x.y → 1.0.0 (GA)                         │
│           Ejemplo: 1.x.y → 2.0.0 (Autonomous)                 │
│                                                                 │
│  MINOR  → Nuevas features backward-compatible                   │
│           (nuevos contextos, nuevos scenarios, nuevos plugins)  │
│           Ejemplo: 0.18.x → 0.19.0                            │
│           Ejemplo: 1.0.0 → 1.1.0                              │
│                                                                 │
│  PATCH  → Bug fixes, security patches, performance fixes       │
│           Sin cambios en APIs públicas                          │
│           Ejemplo: 0.18.0 → 0.18.1                            │
│           Ejemplo: 1.0.0 → 1.0.1                              │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 16.2 Contract Stability Rules

| Tipo de cambio | Impacto en versión | Notificación |
|----------------|-------------------|--------------|
| Cambio en firma de método público | MAJOR bump | Migration guide requerido |
| Nuevo método en interface existente | MINOR bump | Changelog entry |
| Deprecación de método | MINOR (con @Deprecated) | Deprecation notice |
| Eliminación de método deprecated | MAJOR bump | Migration guide requerido |
| Cambio en formato de manifest | MAJOR bump | Migration tool + guide |
| Nuevo provider/plugin | MINOR bump | Discovery automático |
| Bug fix, performance fix | PATCH bump | Changelog entry |

### 16.3 Pre-Release Tags

| Tag | Uso | Ejemplo |
|-----|-----|---------|
| `-alpha` | Inestable, API puede cambiar | `0.18.1-alpha.3` |
| `-beta` | Funcionalmente completo, puede haber bugs | `0.19.0-beta.2` |
| `-rc` | Release candidate, no cambia salvo critical bugs | `0.20.0-rc.1` |
| (sin tag) | Estable | `1.0.0` |

---

## 17. Métricas

### 17.1 Métricas de Calidad de Código

| Métrica | Herramienta | Frecuencia | Threshold |
|---------|------------|------------|-----------|
| Code coverage (>80%) | Pester + Coverlet | Per-commit | 80% minimum |
| Code complexity (< 15) | PSScriptAnalyzer | Per-commit | Max 15 cyclomatic |
| Duplication (< 5%) | PMD/jscpd | Nightly | Max 5% duplicado |
| Static analysis (0 issues) | PSScriptAnalyzer | Per-commit | 0 critical issues |
| Dependency freshness | custom script | Weekly | < 30 days outdated |

### 17.2 Métricas de Operaciones

| Métrica | Instrument | Dashboard | Alert |
|---------|-----------|-----------|-------|
| Uptime | Health checks | Custom | < 99.9% |
| Error rate | Logging subsystem | Custom | > 1% |
| Response time (p50, p95, p99) | Telemetry | Custom | p99 > 500ms |
| Memory usage | Runtime metrics | Custom | > 500MB |
| CPU usage | Runtime metrics | Custom | > 80% sustained |
| Disk I/O | Runtime metrics | Custom | > 10MB/s sustained |

### 17.3 Métricas de Producto

| Métrica | Cómo se mide | Target GA |
|---------|-------------|-----------|
| Feature adoption | Uso de cada módulo | > 80% de módulos activos en una sesión |
| Time-to-value | Tiempo hasta primera operación exitosa | < 5 min |
| Error recovery rate | % de errores auto-resueltos | > 90% |
| User retention | Sesiones repetidas por usuario | > 70% |

---

## 18. Estimaciones

### 18.1 Estimación por Sprint

| Sprint | Historia | SP | Horas | Equipo | Semanas |
|--------|----------|-----|-------|--------|---------|
| A | SA-001 al SA-010 | 78 | 152h | 1 dev | 4 |
| B | SB-001 al SB-011 | 67 | 122h | 1 dev | 4 |
| C | SC-001 al SC-011 | 89 | 170h | 1 dev | 5 |
| D | SD-001 al SD-012 | 107 | 200h | 1 dev | 5 |
| **TOTAL** | | **341 SP** | **644h** | | **18 sem** |

### 18.2 Estimación con Buffer (Risk Contingency)

| Sprint | Horas base | Buffer (25%) | Horas con buffer |
|--------|-----------|--------------|------------------|
| A | 152h | 38h | 190h |
| B | 122h | 31h | 153h |
| C | 170h | 43h | 213h |
| D | 200h | 50h | 250h |
| **TOTAL** | **644h** | **161h** | **805h** |

### 18.3 Estimación por Categoría de Trabajo

| Categoría | % del total | Horas | SP |
|-----------|-------------|-------|----|
| Desarrollo (coding) | 55% | 354h | 188 |
| Testing & QA | 20% | 129h | 68 |
| Documentation | 10% | 64h | 34 |
| Review & Planning | 10% | 64h | 34 |
| Deployment/Infra | 5% | 32h | 17 |
| **TOTAL** | **100%** | **644h** | **341** |

### 18.4 Velocity Assumptions

```
Assumptions:
  • 1 Story Point = ~2 horas de trabajo (ideal)
  • Capacidad del equipo: 1 desarrollador full-time
  • Velocity esperado: 18-25 SP por sprint de 2 semanas
  • Con 4 semanas por sprint: 36-50 SP por sprint
  • Buffer de riesgo: 25% sobre horas base
  
Sprint capacity check:
  Sprint A: 78 SP / 4 semanas = 19.5 SP/week → ~39 SP capacity needed
            Capacity: 25 SP/week × 4 = 100 SP → ✅ VIABLE (con buffer)
  
  Sprint B: 67 SP / 4 semanas = 16.75 SP/week → ~33 SP capacity needed
            Capacity: 100 SP → ✅ VIABLE
  
  Sprint C: 89 SP / 5 semanas = 17.8 SP/week → ~89 SP capacity needed
            Capacity: 125 SP → ✅ VIABLE
  
  Sprint D: 107 SP / 5 semanas = 21.4 SP/week → ~107 SP capacity needed
            Capacity: 125 SP → ✅ VIABLE
```

---

## 19. Backlog Completo

> **Referencia completa:** [07_BACKLOG.md](07_BACKLOG.md)

### 19.1 Epic Overview

| Epic | Sprint Target | SP | Prioridad | Estado |
|------|--------------|-----|-----------|--------|
| EPIC-1: Sandbox Engine Completion | A | 50 | P0 | 🔴 Pendiente |
| EPIC-2: Snapshot/Restore/Rollback | A-B | 50 | P0 | 🔴 Pendiente |
| EPIC-3: Developer Context Completion | B | 40 | P0 | 🔴 Pendiente |
| EPIC-4: Memory Engine | C | 37 | P1 | 🔴 Pendiente |
| EPIC-5: Project Generator | C | 29 | P1 | 🔴 Pendiente |
| EPIC-6: VS Code Integration | C | 13 | P1 | 🔴 Pendiente |
| EPIC-7: Enterprise Platform Hardening | D | 70 | P2 | 🔴 Pendiente |
| EPIC-8: Autonomous Platform (v2.0) | Post-GA | 150+ | P3 | 🔴 Pendiente |

### 19.2 Desglose Rápido de Épicas

```
EPIC-1: Sandbox Engine Completion (50 SP)
├── SA-001: Scenario 8 (8 SP) — 16h
├── SA-002: Scenario 9 (8 SP) — 16h
├── SA-003: Scenario 10 (13 SP) — 24h
├── SA-004: Scenario 11 (8 SP) — 16h
├── SA-005: Scenario 12 (13 SP) — 24h
└── SA-009: Hardening (5 SP) — 10h

EPIC-2: Snapshot/Restore/Rollback (50 SP)
├── SA-007: Snapshot Phase 1 (8 SP) — 16h
├── SA-008: Snapshot Phase 2 (5 SP) — 12h
├── SB-001: Restore Engine (8 SP) — 16h
├── SB-002: Rollback Mechanism (8 SP) — 16h
└── SB-009: Integration tests (5 SP) — 10h

EPIC-3: Developer Context Completion (40 SP)
├── SB-003: Context: Architecture (5 SP) — 10h
├── SB-004: Context: Tasks (5 SP) — 10h
├── SB-005: Context: Objectives (5 SP) — 10h
├── SB-006: Context: CodingStandards (5 SP) — 10h
├── SB-007: Context: Environment (3 SP) — 6h
└── SB-008: Context integration (8 SP) — 16h

EPIC-4: Memory Engine (37 SP)
├── SC-001: Architecture/Storage (13 SP) — 24h
├── SC-002: Query API (8 SP) — 16h
├── SC-003: Lifecycle (8 SP) — 16h
└── SC-004: Persistence (8 SP) — 16h

EPIC-5: Project Generator (29 SP)
├── SC-007: Templates Engine (13 SP) — 24h
├── SC-008: Multi-framework (8 SP) — 16h
└── SC-009: Best Practices (8 SP) — 16h

EPIC-6: VS Code Integration (13 SP)
├── SC-005: Auto-Config (8 SP) — 16h
└── SC-006: Status Bar (5 SP) — 10h

EPIC-7: Enterprise Platform Hardening (70 SP)
├── SD-001: Event Bus (13 SP) — 24h
├── SD-002: Plugin SPI (13 SP) — 24h
├── SD-003: Hot-reload (8 SP) — 16h
├── SD-004: Telemetry (13 SP) — 24h
├── SD-005: Health Checks (8 SP) — 12h
├── SD-006: Circuit Breakers (5 SP) — 8h
├── SD-007: Security (13 SP) — 24h
└── SD-008: Performance (8 SP) — 16h
```

### 19.3 Quick Wins (Implementación temprana)

| Quick Win | SP | Esfuerzo | Impacto | Sprint |
|-----------|-----|----------|---------|--------|
| Git Auto-First-Commit | 5 | 8h | Onboarding +15% | A |
| Error messages mejorados | 3 | 5h | DX +10% | A |
| Configuration validation en boot | 3 | 6h | Reliability +10% | A |

---

## 20. Navegación Final

| Documento | Enlace | Propósito |
|-----------|--------|-----------|
| Master Plan | [01_MASTER_ROADMAP.md](01_MASTER_ROADMAP.md) | **Este documento** |
| Sandbox Engine | [02_SANDBOX_ENGINE.md](02_SANDBOX_ENGINE.md) | Detalle del motor de sandbox |
| Developer Context | [03_DEVELOPER_CONTEXT.md](03_DEVELOPER_CONTEXT.md) | Detalle del contexto del desarrollador |
| Project Wizard | [04_PROJECT_WIZARD.md](04_PROJECT_WIZARD.md) | Detalle del asistente de proyectos |
| Session Memory | [05_SESSION_MEMORY.md](05_SESSION_MEMORY.md) | Detalle del motor de memoria |
| Architecture Target | [06_ARCHITECTURE_TARGET.md](06_ARCHITECTURE_TARGET.md) | Arquitectura objetivo detallada |
| Full Backlog | [07_BACKLOG.md](07_BACKLOG.md) | Todas las historias por sprint |
| Risk Register | [08_RISK_REGISTER.md](08_RISK_REGISTER.md) | Registro de riesgos y mitigaciones |
| Release Plan | [09_RELEASE_PLAN.md](09_RELEASE_PLAN.md) | Plan de releases detallado |
| Metrics & KPIs | [10_METRICS_KPI.md](10_METRICS_KPI.md) | Métricas e indicadores |

---

## Anexos

### Anexo A: Glosario

| Término | Definición |
|---------|-----------|
| **ORR** | Operational Readiness Report — reporte de nivel de preparación operación |
| **Sandbox** | Entorno aislado y controlado para ejecución de código |
| **Context** | Información estructural que describe el entorno del desarrollador/sesión |
| **Memory Engine** | Componente que persiste estado entre sesiones |
| **Snapshot** | Captura del estado del sistema en un punto en el tiempo |
| **Restore** | Operación de volver el sistema a un snapshot previo |
| **Rollback** | Operación de deshacer cambios realizados después de un punto |
| **GA** | General Availability — versión lista para producción |
| **SPI** | Service Provider Interface — punto de extensión para plugins |
| **SP** | Story Points — unidad de estimación relativa (1 SP ≈ 2h) |
| **SemVer** | Semantic Versioning (MAJOR.MINOR.PATCH) |

### Anexo B: Aprobaciones

| Rol | Nombre | Fecha | Estado |
|-----|--------|-------|--------|
| Architecture Board Lead | Por designar | Pendiente | 🔴 Pendiente |
| Engineering Manager | Por designar | Pendiente | 🔴 Pendiente |
| Product Owner | Por designar | Pendiente | 🔴 Pendiente |
| Operations Lead | Por designar | Pendiente | 🔴 Pendiente |

### Anexo C: Historial de Cambios del Documento

| Fecha | Versión | Autor | Cambios |
|-------|---------|-------|---------|
| 2026-07-07 | 1.0.0 | HERMES Enterprise Architecture Board | Versión inicial DRAFT |

---

> **Next:** Continuar con [06_ARCHITECTURE_TARGET.md](06_ARCHITECTURE_TARGET.md) para el detalle de la arquitectura objetivo.
