---
title: HERMES Enterprise - Arquitectura Objetivo
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
  - 07_BACKLOG.md
  - 08_RISK_REGISTER.md
  - 09_RELEASE_PLAN.md
  - 10_METRICS_KPI.md
---

# HERMES Enterprise — Arquitectura Objetivo

> Definición completa de la arquitectura target del framework HERMES Enterprise  
> **Versión del framework objetivo:** v1.0 (GA) y v2.0 (Autonomous Platform)  
> **Fecha de emisión:** 2026-07-07  
> **Referencia principal:** [01_MASTER_ROADMAP.md](01_MASTER_ROADMAP.md) §5

---

## Navegación

| Documento | Descripción |
|-----------|-------------|
| → [01_MASTER_ROADMAP.md](01_MASTER_ROADMAP.md) | Roadmap maestro |
| → [02_SANDBOX_ENGINE.md](02_SANDBOX_ENGINE.md) | Motor de Sandbox |
| → [03_DEVELOPER_CONTEXT.md](03_DEVELOPER_CONTEXT.md) | Contexto de desarrollador |
| → [04_PROJECT_WIZARD.md](04_PROJECT_WIZARD.md) | Asistente de proyectos |
| → [05_SESSION_MEMORY.md](05_SESSION_MEMORY.md) | Motor de memoria y sesión |
| → [07_BACKLOG.md](07_BACKLOG.md) | Backlog completo |
| → [08_RISK_REGISTER.md](08_RISK_REGISTER.md) | Registro de riesgos |
| → [09_RELEASE_PLAN.md](09_RELEASE_PLAN.md) | Plan de releases |
| → [10_METRICS_KPI.md](10_METRICS_KPI.md) | Métricas e indicadores |

---

## Tabla de Contenidos

1. [Introducción](#1-introducción)
2. [Diagrama C4 — Contexto del Sistema](#2-diagrama-c4--contexto-del-sistema)
3. [Diagrama C4 — Contenedores](#3-diagrama-c4--contenedores)
4. [Diagrama de Capas (Layered Architecture)](#4-diagrama-de-capas)
5. [Componentes y Responsabilidades](#5-componentes-y-responsabilidades)
6. [Interfaces y Contratos](#6-interfaces-y-contratos)
7. [Análisis de Acoplamiento](#7-análisis-de-acoplamiento)
8. [Mecanismos de Desacoplamiento](#8-mecanismos-de-desacoplamiento)
9. [Flujos de Eventos](#9-flujos-de-eventos)
10. [Contextos Delimitados (Bounded Contexts)](#10-contextos-delimitados)
11. [Puntos de Extensión](#11-puntos-de-extensión)
12. [Estrategia de Versioning](#12-estrategia-de-versioning)
13. [Topología de Despliegue](#13-topología-de-despliegue)
14. [Diagramas de Flujo de Datos](#14-diagramas-de-flujo-de-datos)
15. [Referencias Cruzadas](#15-referencias-cruzadas)

---

## 1. Introducción

### 1.1 Propósito

Este documento define la **arquitectura objetivo** de HERMES Enterprise, describiendo la estructura deseada del sistema al alcanzar la versión 1.0 (GA) y las bases para la evolución hacia v2.0 (Plataforma Autónoma).

La arquitectura actual del framework (descrita en [01_MASTER_ROADMAP.md §4](01_MASTER_ROADMAP.md)) presenta limitaciones significativas: acoplamiento temporal en el bus de eventos, ausencia de persistencia, contexto de desarrollador incompleto, y observabilidad básica. La arquitectura objetivo resuelve todas estas limitaciones mediante un diseño por capas con inversión de dependencias, un bus de eventos asíncrono pub/sub, un motor de memoria persistente, y un sistema de observabilidad integral.

### 1.2 Principios Arquitectónicos

```
┌─────────────────────────────────────────────────────────────────────┐
│  PRINCIPIOS ARQUITECTÓNICOS FUNDAMENTALES                           │
├───────────┬─────────────────────────────────────────────────────────┤
│ Principio │ Descripción                                             │
├───────────┼─────────────────────────────────────────────────────────┤
│ P1        │ Separation of Concerns: cada capa/responsabilidad       │
│           │ está acotada y cohesiva                                 │
├───────────┼─────────────────────────────────────────────────────────┤
│ P2        │ Dependency Inversion: depender de abstracciones,        │
│           │ nunca de implementaciones concretas                     │
├───────────┼─────────────────────────────────────────────────────────┤
│ P3        │ Event-Driven: comunicación asíncrona entre dominios     │
│           │ mediante publicación/suscripción                        │
├───────────┼─────────────────────────────────────────────────────────┤
│ P4        │ Plugin Architecture: extensibilidad sin modificación    │
│           │ del core mediante SPIs                                  │
├───────────┼─────────────────────────────────────────────────────────┤
│ P5        │ Persistence-First: estado persistente por defecto       │
│           │ (memory engine)                                         │
├───────────┼─────────────────────────────────────────────────────────┤
│ P6        │ Observable: métricas, traces, logs en todo el stack     │
├───────────┼─────────────────────────────────────────────────────────┤
│ P7        │ Idempotent Operations: operaciones repetibles sin       │
│           │ efectos secundarios no deseados                         │
├───────────┼─────────────────────────────────────────────────────────┤
│ P8        │ Fail-Safe: circuit breakers, health checks, graceful    │
│           │ degradation                                             │
├───────────┼─────────────────────────────────────────────────────────┤
│ P9        │ Testability: diseñar para test en aislamiento           │
├───────────┼─────────────────────────────────────────────────────────┤
│ P10       │ Backward Compatibility: SemVer estricto, contracts      │
│           │ inmutables dentro de una major version                  │
└───────────┴─────────────────────────────────────────────────────────┘
```

### 1.3 Restricciones Técnicas

| Restricción | Detalles |
|-------------|----------|
| Plataforma | PowerShell 7+ / .NET 6+ |
| SO primario | Windows 10/11 |
| SO secundario | Linux (compatibilidad futura) |
| Tamaño máximo runtime | < 100MB memoria base |
| Latencia objetivo | < 200ms p99 para operaciones core |
| Dependencias externas | Solo cuando no hay alternativa .NET/PS nativa |
| Seguridad | Cumplir CIS Benchmarks para PowerShell |

---

## 2. Diagrama C4 — Contexto del Sistema

### 2.1 Nivel 1: Contexto del Sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│                    HERMES ENTERPRISE — SYSTEM CONTEXT               │
│                                                                     │
│   ┌─────────────────┐                                               │
│   │  Desarrollador  │                                               │
│   │  (Usuario)      │                                               │
│   └───────┬─────────┘                                               │
│           │                                                         │
│           │ usa vía                                                 │
│           ▼                                                         │
│   ┌───────────────────────────────────────────────┐                │
│   │         HERMES ENTERPRISE                      │                │
│   │         (Framework de Automatización)          │                │
│   │                                               │                │
│   │  • Provee entorno de desarrollo controlado    │                │
│   │  • Orquesta ejecución en sandbox             │                │
│   │  • Mantiene contexto del desarrollador        │                │
│   │  • Genera proyectos enterprise               │                │
│   │  • Persiste memoria/estado entre sesiones    │                │
│   │  • Integra con IDEs y herramientas           │                │
│   └──┬──────────┬──────────┬──────────┬──────────┘                │
│      │          │          │          │                            │
│      │          │          │          │                            │
│      ▼          ▼          ▼          ▼                            │
│ ┌─────────┐┌─────────┐┌─────────┐┌───────────┐                   │
│ │VS Code  ││Git      ││File     ││External   │                   │
│ │(IDE)    ││(VCS)    ││System   ││Services   │                   │
│ │         ││         ││         ││(future)   │                   │
│ └─────────┘└─────────┘└─────────┘└───────────┘                   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 2.2 Actores y Sistemas Externos

| Actor/Sistema | Tipo | Interacción | Protocolo |
|---------------|------|-------------|-----------|
| Desarrollador | Humano | Usa vía CLI / IDE / Wizard | Interactivo |
| VS Code | Software | Recibe auto-config, muestra status | JSON + Extension API |
| Git (local) | Software | Commits, branch management | CLI invocación |
| Sistema de archivos | Infraestructura | Lectura/escritura de archivos | FS API .NET |
| Process Runtime | Infraestructura | Creación de procesos aislados | Process API .NET |
| Plugin Registry | Software | Descubrimiento y carga de plugins | Manifest-based |

---

## 3. Diagrama C4 — Contenedores

### 3.1 Nivel 2: Contenedores del Sistema

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│                   HERMES ENTERPRISE — CONTAINERS                    │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                CLI PRESENTATION LAYER                        │   │
│  │  ┌──────────────┐  ┌──────────────┐  ┌───────────────────┐ │   │
│  │  │ Interactive  │  │ Script       │  │ Daemon/Service   │ │   │
│  │  │ Shell (PS)   │  │ Mode         │  │ Mode (future)    │ │   │
│  │  └──────┬───────┘  └──────┬───────┘  └────────┬──────────┘ │   │
│  └─────────┼──────────────────┼───────────────────┼────────────┘   │
│            │                  │                   │                │
│            ▼                  ▼                   ▼                │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                APPLICATION SERVICES                           │   │
│  │  ┌──────────────────────────────────────────────────────┐  │   │
│  │  │  HERMES MOTOR (Kernel + Orchestration)               │  │   │
│  │  │                                                      │  │   │
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │  │   │
│  │  │  │ Sandbox  │ │ Session  │ │ Memory   │ │ Project│ │  │   │
│  │  │  │ Orchestr.│ │ Manager  │ │ Engine   │ │ Gener. │ │  │   │
│  │  │  └──────────┘ └──────────┘ └──────────┘ └────────┘ │  │   │
│  │  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌────────┐ │  │   │
│  │  │  │ Context  │ │ Wizard   │ │ Event    │ │ Plugin │ │  │   │
│  │  │  │ Manager  │ │ Engine   │ │ Bus      │ │ Loader │ │  │   │
│  │  │  └──────────┘ └──────────┘ └──────────┘ └────────┘ │  │   │
│  │  └──────────────────────────────────────────────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│            │                                                        │
│            ▼                                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                DOMAIN COMPONENTS                              │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │   │
│  │  │ Snapshot/│ │ Security │ │ Validate │ │ Contracts/   │  │   │
│  │  │ Restore/ │ │ Policies │ │ Engine   │ │ Interfaces   │  │   │
│  │  │ Rollback │ │          │ │          │ │              │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│            │                                                        │
│            ▼                                                        │
│  ┌─────────────────────────────────────────────────────────────┐   │
│  │                INFRASTRUCTURE                                 │   │
│  │  ┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────────┐  │   │
│  │  │ SQLite / │ │ File     │ │ Log      │ │ Config       │  │   │
│  │  │ JSON     │ │ System   │ │ Provider │ │ Store        │  │   │
│  │  │ Storage  │ │ Adapter  │ │ (OTel)   │ │              │  │   │
│  │  └──────────┘ └──────────┘ └──────────┘ └──────────────┘  │   │
│  └─────────────────────────────────────────────────────────────┘   │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### 3.3 Descripción de Contenedores

| Contenedor | Tecnología | Responsabilidad |
|------------|-----------|-----------------|
| Interactive Shell | PowerShell 7 REPL | Interfaz humana interactiva |
| Script Mode | PowerShell 7 -File | Ejecución automatizada |
| Daemon Mode (v2.0) | .NET Worker Service | Background tasks, watch mode |
| HERMES Motor | PowerShell module + .NET | Orquestación de todos los servicios |
| Sandbox Orchestrator | PowerShell + Job API | Creación y gestión de sandbox |
| Session Manager | PowerShell + SQLite | Persistencia de sesión |
| Memory Engine | PowerShell + SQLite/JSON | Memoria persistente cross-session |
| Project Generator | PowerShell + Templates | Generación de proyectos |
| Context Manager | PowerShell | Información de contexto del dev |
| Event Bus | PowerShell event queues | Comunicación asíncrona pub/sub |
| Snapshot/Restore | PowerShell + File ops | Captura y restauración de estado |
| Security Policies | PowerShell + ACLs | Aplicación de políticas de seguridad |
| Validation Engine | PowerShell | Validación de entrada/contratos |
| Storage (SQLite/JSON) | .NET SQLite / JSON files | Persistencia de datos |
| Log Provider | PowerShell + .NET | Logging estructurado + telemetría |

---

## 4. Diagrama de Capas (Layered Architecture)

### 4.1 Vista Completa de Capas

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│              HERMES ENTERPRISE — LAYERED ARCHITECTURE               │
│                                                                     │
│  ╔═══════════════════════════════════════════════════════════════╗  │
│  ║  LAYER 5: CROSS-CUTTING CONCERNS (Transversal)               ║  │
│  ║  ┌─────────────────────────────────────────────────────────┐ ║  │
│  ║  │ Observability │ Telemetry │ Health Checks │ Audit      │ ║  │
│  ║  │ Security      │ Logging   │ Config        │ i18n       │ ║  │
│  ║  └─────────────────────────────────────────────────────────┘ ║  │
│  ╚═══════════════════════════════════════════════════════════════╝  │
│           ▲              ▲              ▲              ▲             │
│  ╔═══════════════════════════════════════════════════════════════╗  │
│  ║  LAYER 4: INFRASTRUCTURE (Infraestructura)                   ║  │
│  ║  ┌─────────────────────────────────────────────────────────┐ ║  │
│  ║  │ Runtime Engine │ Storage      │ FS Adapter │ Process   │ ║  │
│  ║  │ Config Store   │ Log Provider │ Crypto     │ Network   │ ║  │
│  ║  └─────────────────────────────────────────────────────────┘ ║  │
│  ╚═══════════════════════════════════════════════════════════════╝  │
│           ▲              ▲              ▲              ▲             │
│  ╔═══════════════════════════════════════════════════════════════╗  │
│  ║  LAYER 3: DOMAIN (Dominio del Negocio)                       ║  │
│  ║  ┌─────────────────────────────────────────────────────────┐ ║  │
│  ║  │ Snapshot/Restore │ Context Domain │ Security Domain    │ ║  │
│  ║  │ Session Lifecycle│ Event Domain   │ Validation Domain  │ ║  │
│  ║  └─────────────────────────────────────────────────────────┘ ║  │
│  ╚═══════════════════════════════════════════════════════════════╝  │
│           ▲              ▲              ▲              ▲             │
│  ╔═══════════════════════════════════════════════════════════════╗  │
│  ║  LAYER 2: APPLICATION (Servicios de Aplicación)              ║  │
│  ║  ┌─────────────────────────────────────────────────────────┐ ║  │
│  ║  │ Sandbox Orchestrator  │ Memory Engine Service          │ ║  │
│  ║  │ Project Generator     │ Session Manager Service        │ ║  │
│  ║  │ Context Aggregator    │ Plugin Management Service      │ ║  │
│  ║  └─────────────────────────────────────────────────────────┘ ║  │
│  ╚═══════════════════════════════════════════════════════════════╝  │
│           ▲              ▲              ▲              ▲             │
│  ╔═══════════════════════════════════════════════════════════════╗  │
│  ║  LAYER 1: PRESENTATION (Presentación)                        ║  │
│  ║  ┌─────────────────────────────────────────────────────────┐ ║  │
│  ║  │ Interactive CLI  │ VS Code Extension │ Wizard UI        │ ║  │
│  ║  │ Dashboard (v2.0) │ Web UI (v2.0)     │ Script Mode      │ ║  │
│  ║  └─────────────────────────────────────────────────────────┘ ║  │
│  ╚═══════════════════════════════════════════════════════════════╝  │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘

Dependencias: capa superior → capa inferior (nunca inversa)
Cross-cutting: se aplica ortogonalmente a todas las capas
```

### 4.2 Reglas de Dependencia entre Capas

```
    Presentación
         │
         │ usa
         ▼
    Aplicación
         │
         │ coordina
         ▼
      Dominio
         │
         │ requiere
         ▼
  Infraestructura
         │
         │ utiliza
         ▼
Cross-cutting (observa y mejora a todas)

REGLAS:
  ✓ La capa N puede depender SOLO de capa N-1 (o inferior)
  ✓ Cross-cutting puede observar cualquiera sin modificar
  ✗ La capa N NO puede depender de capa N+1 (superior)
  ✗ Capas del mismo nivel NO pueden depender entre sí directamente
     (deben comunicarse vía capa superior o eventos)
```

---

## 5. Componentes y Responsabilidades

### 5.1 Mapa de Componentes

```
┌─────────────────────────────────────────────────────────────────────┐
│                    COMPONENT MAP                                    │
├───────────────┬─────────────────────────────────────────────────────┤
│ Componente    │ Responsabilidad Principal                           │
├───────────────┼─────────────────────────────────────────────────────┤
│ KERNEL        │ Ciclo de vida del motor, inyección de dependencias, │
│               │ registro de servicios, resolución de contratos      │
├───────────────┼─────────────────────────────────────────────────────┤
│ BOOTSTRAP     │ Inicialización ordenada, detección de entorno,      │
│               │ carga de configuración inicial                      │
├───────────────┼─────────────────────────────────────────────────────┤
│ SANDBOX       │ Aislamiento de ejecución, supervisión, control de   │
│ ENGINE        │ recursos, gestión de escenarios                     │
├───────────────┼─────────────────────────────────────────────────────┤
│ CONTEXT       │ Agregación de información contextual (arquitectura, │
│ MANAGER       │ tareas, objetivos, estándares, entorno, sesión)     │
├───────────────┼─────────────────────────────────────────────────────┤
│ MEMORY        │ Persistencia de estado, almacenamiento de conocimiento│
│ ENGINE        │ adquirido, recuperación semántica, gestión de ciclo │
│               │ de vida del conocimiento                            │
├───────────────┼─────────────────────────────────────────────────────┤
│ SESSION       │ Gestión de sesiones de usuario, persistencia entre  │
│ MANAGER       │ ejecuciones, restauración de estado                 │
├───────────────┼─────────────────────────────────────────────────────┤
│ SNAPSHOT/     │ Captura de estado en punto temporal, restauración   │
│ RESTORE/      │ a punto guardado, rollback a puntos anteriores,     │
│ ROLLBACK      │ diff entre snapshots                                │
├───────────────┼─────────────────────────────────────────────────────┤
│ PROJECT       │ Generación de proyectos desde templates, scaffolding│
│ GENERATOR     │ personalizado, aplicación de best practices         │
├───────────────┼─────────────────────────────────────────────────────┤
│ EVENT BUS     │ Comunicación asíncrona pub/sub, cola de eventos,    │
│               │ despacho a suscriptores, dead-letter queue          │
├───────────────┼─────────────────────────────────────────────────────┤
│ PLUGIN        │ Descubrimiento, carga, validación, gestión de ciclo │
│ LOADER        │ de vida de plugins, hot-reload, compatibilidad      │
├───────────────┼─────────────────────────────────────────────────────┤
│ SECURITY      │ Políticas de seguridad, control de acceso,          │
│ POLICIES      │ auditoría, sandboxing de recursos sensibles         │
├───────────────┼─────────────────────────────────────────────────────┤
│ VALIDATION    │ Validación de entrada, cumplimiento de contratos,   │
│ ENGINE        │ sanitización, enforcement de esquemas               │
├───────────────┼─────────────────────────────────────────────────────┤
│ OBSERVABILITY │ Métricas, traces, logs, health checks, circuit      │
│               │ breakers, alerting                                  │
└───────────────┴─────────────────────────────────────────────────────┘
```

### 5.2 Desglose detallado: Kernel

```
┌─────────────────────────────────────────────────────────────────┐
│                    KERNEL COMPONENT                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌───────────────────────┐  ┌───────────────────────────────┐  │
│  │ Service Registry      │  │ Contract Registry             │  │
│  │ • Register(service)   │  │ • DefineContract(IFoo)        │  │
│  │ • Resolve<T>()        │  │ • GetContract(name)           │  │
│  │ • HasService(key)     │  │ • ValidateCompliance(impl)    │  │
│  │ • Enumerate<T>()      │  │                               │  │
│  └───────────────────────┘  └───────────────────────────────┘  │
│                                                                  │
│  ┌───────────────────────┐  ┌───────────────────────────────┐  │
│  │ Dependency Graph      │  │ Lifecycle Manager             │  │
│  │ • AddNode(component)  │  │ • Initialize(component)       │  │
│  │ • AddEdge(dep)        │  │ • Start(component)            │  │
│  │ • TopologicalSort()   │  │ • Stop(component)             │  │
│  │ • DetectCycles()      │  │ • Dispose(component)          │  │
│  └───────────────────────┘  └───────────────────────────────┘  │
│                                                                  │
│  Responsabilidades:                                              │
│  • Punto central de orquestación                                 │
│  • Garantía de orden de inicialización                           │
│  • Resolución de dependencias en graph acíclico                  │
│  • Registro y descubrimiento de servicios                        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.3 Desglose detallado: Sandbox Engine

```
┌─────────────────────────────────────────────────────────────────┐
│                    SANDBOX ENGINE COMPONENT                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ Scenario Registry│  │ Executor         │  │ Supervisor   │  │
│  │ (12 scenarios)   │  │ • CreateEnv()    │  │ • Monitor()  │  │
│  │ • Basic          │  │ • Run(code)      │  │ • TrackRes() │  │
│  │ • Isolated       │  │ • Stop()         │  │ • Alert()    │  │
│  │ • Network        │  │                  │  │              │  │
│  │ • Multi-Tenant   │  │                  │  │              │  │
│  │ • Resource-Limt  │  │                  │  │              │  │
│  │ • Full-Integr.   │  │                  │  │              │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────┐  │
│  │ Resource Manager │  │ Isolation Layer  │  │ Output       │  │
│  │ • CPU limits     │  │ • Process jail   │  │ Collector    │  │
│  │ • Memory caps    │  │ • FS sandbox     │  │ • stdout     │  │
│  │ • Disk quotas    │  │ • Network rules  │  │ • stderr     │  │
│  │ • Time limits    │  │ • Security ctx   │  │ • metrics    │  │
│  └──────────────────┘  └──────────────────┘  └──────────────┘  │
│                                                                  │
│  Referencia: [02_SANDBOX_ENGINE.md](02_SANDBOX_ENGINE.md)        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 5.4 Desglose detallado: Memory Engine

```
┌─────────────────────────────────────────────────────────────────┐
│                    MEMORY ENGINE COMPONENT                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────┐  ┌──────────────────────────────┐   │
│  │ Knowledge Store      │  │ Semantic Index               │   │
│  │ • Store(key,value)   │  │ • BuildIndex(corpus)         │   │
│  │ • Retrieve(key)      │  │ • Search(query)              │   │
│  │ • Delete(key)        │  │ • RelevanceScore(result)     │   │
│  │ • Enumerate()        │  │                              │   │
│  └──────────────────────┘  └──────────────────────────────┘   │
│                                                                  │
│  ┌──────────────────────┐  ┌──────────────────────────────┐   │
│  │ Lifecycle Manager    │  │ Persistence Backend          │   │
│  │ • Evict(stale)       │  │ • SQLite provider            │   │
│  │ • Compact()          │  │ • JSON file provider         │   │
│  │ • Archive(old)       │  │ • In-memory (test) provider  │   │
│  │ • Restore(from)      │  │                              │   │
│  └──────────────────────┘  └──────────────────────────────┘   │
│                                                                  │
│  Referencia: [05_SESSION_MEMORY.md](05_SESSION_MEMORY.md)        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 6. Interfaces y Contratos

### 6.1 Contrato de Componente (IComponent)

```
┌─────────────────────────────────────────────────────────────────┐
│  CONTRACT: IComponent                                            │
│  (Todo componente registrable en el kernel)                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  interface IComponent {                                          │
│    + Id: string                    // Identificador único       │
│    + Name: string                  // Nombre legible            │
│    + Version: string               // Versión (SemVer)          │
│    + Dependencies: string[]        // IDs de dependencias       │
│    + Initialize(context): void     // Inicialización            │
│    + Start(): void                 // Arranque                  │
│    + Stop(): void                  // Detención                 │
│    + Dispose(): void               // Liberación                │
│    + HealthCheck(): HealthStatus   // Estado de salud           │
│  }                                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.2 Contrato de Sandbox (ISandboxProvider)

```
┌─────────────────────────────────────────────────────────────────┐
│  CONTRACT: ISandboxProvider                                      │
│  (Proveedor de ejecución aislada)                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  interface ISandboxProvider {                                    │
│    + CreateEnvironment(config: SandboxConfig): Sandbox           │
│    + Execute(sandbox: Sandbox, code: string): ExecResult         │
│    + Stop(sandbox: Sandbox): void                                │
│    + GetMetrics(sandbox: Sandbox): ResourceMetrics               │
│    + Supports(scenario: ScenarioType): bool                      │
│  }                                                               │
│                                                                  │
│  interface SandboxConfig {                                       │
│    + ScenarioType: enum                                          │
│    + ResourceLimits: ResourceLimits                              │
│    + NetworkPolicy: NetworkPolicy                                │
│    + SecurityContext: SecurityContext                            │
│    + Timeout: TimeSpan                                           │
│  }                                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.3 Contrato de Contexto (IContextProvider)

```
┌─────────────────────────────────────────────────────────────────┐
│  CONTRACT: IContextProvider                                      │
│  (Proveedor de información contextual)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  interface IContextProvider {                                    │
│    + ContextType: string           // Tipo de contexto          │
│    + GetContext(): ContextData     // Obtener datos             │
│    + Refresh(): void               // Refrescar                 │
│    + Subscribe(handler): void      // Suscribirse a cambios     │
│    + IsAvailable(): bool           // Disponibilidad            │
│  }                                                               │
│                                                                  │
│  Tipos de contexto implementados:                                │
│  ┌────────────────────────────────────────────────────────┐     │
│  │ context:architecture    → Estructura del proyecto      │     │
│  │ context:tasks           → Tareas activas               │     │
│  │ context:objectives      → Objetivos del sprint         │     │
│  │ context:coding-standards│ Estándares de codificación   │     │
│  │ context:environment     → Variables de entorno         │     │
│  │ context:session         → Estado de sesión actual      │     │
│  └────────────────────────────────────────────────────────┘     │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.4 Contrato de Eventos (IEventBus)

```
┌─────────────────────────────────────────────────────────────────┐
│  CONTRACT: IEventBus                                             │
│  (Bus de eventos asíncrono pub/sub)                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  interface IEventBus {                                           │
│    + Publish(event: DomainEvent): void    // Publicar evento    │
│    + Subscribe<T>(handler): SubId         // Suscribirse       │
│    + Unsubscribe(subId: SubId): void      // Desuscribirse      │
│    + GetDeadLetterQueue(): Event[]        // DLQ                │
│    + Replay(fromTimestamp): void          // Replay             │
│  }                                                               │
│                                                                  │
│  interface DomainEvent {                                         │
│    + EventId: Guid              // ID único                     │
│    + EventType: string          // Tipo                         │
│    + Timestamp: DateTimeOffset  // Cuándo ocurrió              │
│    + Source: string             // Componente origen            │
│    + Payload: object            // Datos del evento             │
│    + CorrelationId: Guid        // Trazabilidad                 │
│  }                                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 6.5 Contrato de Memoria (IMemoryEngine)

```
┌─────────────────────────────────────────────────────────────────┐
│  CONTRACT: IMemoryEngine                                         │
│  (Motor de memoria persistente)                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  interface IMemoryEngine {                                       │
│    + Store(item: MemoryItem): void      // Almacenar           │
│    + Retrieve(query: Query): Result[]   // Buscar               │
│    + Delete(key: string): void          // Eliminar             │
│    + Compact(): void                    // Compactar            │
│    + Archive(before: DateTimeOffset): void  // Archivar         │
│    + GetStats(): MemoryStats            // Estadísticas         │
│  }                                                               │
│                                                                  │
│  interface MemoryItem {                                          │
│    + Key: string                  // Clave única                │
│    + Content: string              // Contenido                  │
│    + Metadata: Dictionary         // Metadatos                  │
│    + CreatedAt: DateTimeOffset    // Timestamp creación         │
│    + LastAccessedAt: DateTime     // Último acceso              │
│    + Relevance: float             // Score de relevancia        │
│  }                                                               │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 7. Análisis de Acoplamiento

### 7.1 Matriz de Acoplamiento

```
                    DEPENDS ON →
              Kernel Sandbox Context Memory Event Secur Valid Infra
┌────────────┬──────────────────────────────────────────────────────┐
│ Kernel     │   —      Low     Low    Low   Core   Low   Low   Low │
│ Sandbox    │  Core     —      Low    Low    Low   Med   Low   Med │
│ Context    │  Core    Low      —     Med    Low   Low   Low   Low │
│ Memory     │  Core    Low     Med     —     Med   Low   Low   Med │
│ Event Bus  │  Core    Low     Low    Low     —    Low   Low   Low │
│ Security   │  Core    Med     Low    Low    Low    —    Low   Low │
│ Validation │  Core    Low     Low    Low    Low   Low    —    Low │
│ Infra      │  Core    Low     Low    Low    Low   Low   Low    —  │
└────────────┴──────────────────────────────────────────────────────┘

Leyenda: Core (acople fuerte necesario) | Med (medio) | Low (bajo) | — (self)
```

### 7.2 Puntuación de Acoplamiento por Componente

| Componente | Acoplamiento Entrada | Acoplamiento Salida | Score Total | Clasificación |
|------------|---------------------|---------------------|-------------|---------------|
| Kernel | 8 conexiones | 0 dependencias externas | 8 | Base (necesario) |
| Sandbox Engine | 2 fuertes + 4 débiles | 3 débiles | Medio | ✅ Bajo (aceptable) |
| Context Manager | 1 fuerte (Kernel) | 3 proveedores | Medio-Bajo | ✅ Bajo |
| Memory Engine | 1 fuerte + 1 medio | 2 medios (Persistence) | Medio | ⚠️ Medio (revisar) |
| Event Bus | 1 fuerte (Kernel) | Todas suscripciones | Alto | ⚠️ Medio (mitigado por async) |
| Security | 1 fuerte | 2 medios | Medio | ✅ Bajo |
| Validation | 1 fuerte | 0 fuertes | Bajo | ✅ Bajo |

### 7.3 Áreas de Acoplamiento Crítico

```
┌─────────────────────────────────────────────────────────────────┐
│  ACOPAMIENTO CRÍTICO — ANÁLISIS                                  │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  🔴 Kernel → Todos                                                │
│     • Todo componente depende del Kernel (registrador central)  │
│     • Riesgo: Kernel como single point of failure              │
│     • Mitigación: Kernel minimalista, interfaces claras         │
│                                                                  │
│  🟡 Event Bus ↔ Todos (pub/sub)                                 │
│     • Todos publican/suscriben al bus                           │
│     • Riesgo: Acoplamiento temporal                             │
│     • Mitigación: Async, DLQ, idempotencia                     │
│                                                                  │
│  🟡 Memory → Persistence                                       │
│     • Memory Engine depende del backend de persistencia         │
│     • Riesgo: Cambio de backend requiere refactor              │
│     • Mitigación: IStorageProvider interface (Adapter Pattern)  │
│                                                                  │
│  🟢 Sandbox → Seguridad                                        │
│     • Sandbox usa Security policies                             │
│     • Riesgo: Bajo, es una dependencia legítima                │
│     • Mitigación: Inyección, no acoplamiento directo           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 8. Mecanismos de Desacoplamiento

### 8.1 Catálogo de Patrones

| Mecanismo | Tipo | Aplicación en HERMES |
|-----------|------|---------------------|
| **Dependency Injection** | Estructural | Kernel resuelve dependencias vía Service Registry |
| **Event-Driven (Pub/Sub)** | Temporal | Event Bus desacopla producers/consumers |
| **Adapter Pattern** | Estructural | IStorageProvider desacopla Memory del backend |
| **Strategy Pattern** | Comportamental | ISandboxProvider para múltiples implementaciones |
| **Observer Pattern** | Comportamental | IContextProvider.Subscribe para notificaciones |
| **Facade** | Estructural | Kernel como facade sobre todos los servicios |
| **Proxy** | Comportamental | Security proxy entre sandbox y recursos |
| **Message Queue** | Temporal | Event Bus con dead-letter queue |
| **Circuit Breaker** | Resiliencia | Health checks + fallbacks automáticos |

### 8.2 Jerarquía de Desacoplamiento

```
┌─────────────────────────────────────────────────────────────────┐
│                    DESCOPLAMIENTO — NIVELES                      │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Nivel 5: COMPLETELY INDEPENDENT                                 │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Plugins externos no conocen nada del core                │  │
│  │ Solo implementan SPIs y descubren vía manifest           │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Nivel 4: EVENT-DRIVEN DECOUPLING                               │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Componentes se comunican SOLO por eventos                │  │
│  │ No conocen la identidad del productor/consumidor         │  │
│  │ Ejemplo: Memory Engine no conoce Project Generator       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Nivel 3: CONTRACT DECOUPLING (Dependency Inversion)            │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Componentes dependen de interfaces, no implementaciones  │  │
│  │ Ejemplo: Sandbox depende de ISecurityPolicy              │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Nivel 2: STRUCTURAL DECOUPLING (Layer Separation)              │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Capas solo dependen de capas inferiores                  │  │
│  │ Presentation → Application → Domain → Infrastructure     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  Nivel 1: PROCESS DECOUPLING (Future/Advanced)                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │ Componentes como procesos separados (IPC)                │  │
│  │ Aplicado en v2.0 para distribución                       │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 8.3 Reglas de Desacoplamiento Implementadas

```
┌─────────────────────────────────────────────────────────────────┐
│  REGLAS DE DESACOPLAMIENTO                                       │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ✅ Los DOMINIOS nunca llaman directamente a otros dominios     │
│     → Comunicación vía Event Bus o Application Services         │
│                                                                  │
│  ✅ Las INFRASTRUCTURAS implementan interfaces de DOMINIO       │
│     → Dominio no conoce detalles técnicos de implementación     │
│                                                                  │
│  ✅ La PRESENTACIÓN no tiene lógica de negocio                   │
│     → Solo invoca Application Services                          │
│                                                                  │
│  ✅ Los PLUGINS no importan módulos del core                     │
│     → Solo implementan SPIs expuestos en contracts/             │
│                                                                  │
│  ✅ CROSS-CUTTING se aplica vía inyección/decorador             │
│     → No modifica comportamiento de componentes target          │
│                                                                  │
│  ✗ NO se permiten dependencias circulares                        │
│     → Detectado por DependencyGraph.DetectCycles()              │
│                                                                  │
│  ✗ NO se permiten dependencias hacia la capa superior           │
│     → Infraestructura nunca importa Application                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 9. Flujos de Eventos

### 9.1 Catálogo de Eventos del Dominio

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DOMAIN EVENT CATALOG                              │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  SANDBOX EVENTS                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ sandbox.created        │ ID, config, timestamp              │   │
│  │ sandbox.started        │ ID, scenario, pid                  │   │
│  │ sandbox.completed      │ ID, result, duration, metrics      │   │
│  │ sandbox.failed         │ ID, error, stacktrace               │   │
│  │ sandbox.stopped        │ ID, reason                          │   │
│  │ sandbox.resources.warn │ ID, resource, threshold             │   │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  CONTEXT EVENTS                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ context.loaded         │ context_type, data_hash            │   │
│  │ context.updated        │ context_type, changes              │   │
│  │ context.expired        │ context_type, ttl                  │   │
│  │ context.refreshed      │ context_type, new_data_hash        │   │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  SESSION EVENTS                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ session.started        │ session_id, user, config           │   │
│  │ session.restored       │ session_id, snapshot_id            │   │
│  │ session.saved          │ session_id, state_size              │   │
│  │ session.closed         │ session_id, duration                │   │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  MEMORY EVENTS                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ memory.stored          │ key, size, relevance              │   │
│  │ memory.retrieved       │ key, query_hash, latency_ms       │   │
│  │ memory.evicted         │ key, reason (ttl/stale/compact)   │   │
│  │ memory.compacted       │ old_size, new_size, freed_space    │   │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  PROJECT EVENTS                                                      │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ project.created        │ project_id, template, path         │   │
│  │ project.configured     │ project_id, config_hash            │   │
│  │ project.build_started  │ project_id, build_type             │   │
│  │ project.build_done     │ project_id, duration, result       │   │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
│  SYSTEM EVENTS                                                       │
│  ┌────────────────────────────────────────────────────────────┐    │
│  │ system.started         │ version, environment, uptime       │   │
│  │ system.stopping        │ reason, sessions_to_close          │   │
│  │ system.health.degraded │ component, health_status            │   │
│  │ system.health.healthy  │ component, recovery_info            │   │
│  │ config.reloaded        │ config_version, changes_count       │   │
│  └────────────────────────────────────────────────────────────┘    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

### 9.2 Diagrama de Flujo de Eventos

```
┌─────────────────────────────────────────────────────────────────┐
│                    EVENT FLOW DIAGRAM                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌──────────┐   sandbox.created   ┌────────────────┐          │
│   │ Sandbox  │ ──────────────────▶ │  Event Bus     │          │
│   │ Engine   │                     │  (pub/sub)     │          │
│   └──────────┘                     └───────┬────────┘          │
│                                            │                    │
│                    Publish                  │                    │
│                                            │                    │
│         ┌──────────────────────────────────┼──────────┐        │
│         │                                  │          │        │
│         ▼                                  ▼          ▼        │
│   ┌──────────┐                     ┌──────────┐ ┌─────────┐   │
│   │ Observer │                     │ Memory   │ │ Metrics │   │
│   │ Security │                     │ Engine   │ │ (OTel)  │   │
│   │ Monitor  │                     │ (store   │ │         │   │
│   │          │                     │  event   │ │         │   │
│   └──────────┘                     │  data)   │ └─────────┘   │
│                                    └──────────┘               │
│                                                                  │
│   Subscribe patterns:                                            │
│   • All events  → Metrics collector, Audit logger               │
│   • Sandbox.*   → Security monitor, Resource watcher            │
│   │ Memory.*   → Session manager (restore triggers)             │
│   │ Context.*  → Project generator (fresh context)              │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 9.3 Secuencia: Creación de Sandbox con Snapshot

```
┌─────────────────────────────────────────────────────────────────┐
│  SEQUENCE: Sandbox Creation + Snapshot                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  User      Wizard    Kernel    Sandbox   Snapshot   EventBus    │
│   │          │         │         │          │         │          │
│   │──create──▶│        │         │          │         │          │
│   │          │──init──▶│         │          │         │          │
│   │          │         │─resolve▶│          │         │          │
│   │          │         │         │──create─▶│         │          │
│   │          │         │         │          │─publish─▶│         │
│   │          │         │         │          │   sandbox.created  │
│   │          │         │         │◀─ack─────│         │          │
│   │          │         │         │──execute▶│         │          │
│   │          │         │         │          │─publish─▶│         │
│   │          │         │         │          │  sandbox.running  │
│   │          │         │         │◀─result──│         │          │
│   │          │         │         │──snapshot▶│         │          │
│   │          │         │         │          │──save──▶│         │
│   │          │         │         │          │─publish─▶│         │
│   │          │         │         │          │  snapshot.created │
│   │◀─result──│         │         │          │         │          │
│   │          │         │         │          │         │          │
└─────────────────────────────────────────────────────────────────┘
```

---

## 10. Contextos Delimitados (Bounded Contexts)

### 10.1 Identificación de Bounded Contexts

```
┌─────────────────────────────────────────────────────────────────┐
│                    BOUNDED CONTEXTS                               │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           EXECUTION CONTEXT (Sandbox)                     │  │
│  │  • Aislamiento de procesos                               │  │
│  │  • Control de recursos                                   │  │
│  │  • Supervisión                                           │  │
│  │  Lenguaje ubicuo: sandbox, scenario, isolation, limits   │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           KNOWLEDGE CONTEXT (Memory + Context)            │  │
│  │  • Conocimiento persistente                              │  │
│  │  • Información contextual                                │  │
│  │  • Búsqueda semántica                                    │  │
│  │  Lenguaje ubicuo: item, query, relevance, knowledge     │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           SESSION CONTEXT (Session + Snapshot)            │  │
│  │  • Gestión de sesiones                                   │  │
│  │  • Captura/restauración de estado                        │  │
│  │  • Puntos en el tiempo                                   │  │
│  │  Lenguaje ubicuo: session, snapshot, restore, rollback  │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           GENERATION CONTEXT (Project Generator)          │  │
│  │  • Creación de proyectos                                 │  │
│  │  • Templates                                             │  │
│  │  • Scaffolding                                           │  │
│  │  Lenguaje ubicuo: project, template, scaffold, boilerpl│  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           SECURITY CONTEXT (Security + Validation)        │  │
│  │  • Políticas                                             │  │
│  │  • Control de acceso                                     │  │
│  │  • Validación                                            │  │
│  │  Lenguaje ubicuo: policy, permission, rule, validate    │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
│  ┌──────────────────────────────────────────────────────────┐  │
│  │           EXTENSIBILITY CONTEXT (Plugin + Events)         │  │
│  │  • Descubrimiento de plugins                             │  │
│  │  • Comunicación pub/sub                                  │  │
│  │  • Puntos de extensión                                   │  │
│  │  Lenguaje ubicuo: plugin, event, subscription, SPI      │  │
│  └──────────────────────────────────────────────────────────┘  │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 10.2 Mapa de Contextos y Relaciones

```
                    ┌─────────────────────┐
                    │    SECURITY CONTEXT  │
                    │    (policies, rules) │
                    └──────────┬──────────┘
                               │ enforces en
                               │
        ┌──────────────────────┼──────────────────────┐
        │                      │                      │
        ▼                      ▼                      ▼
┌───────────────┐    ┌─────────────────┐    ┌─────────────────┐
│ EXECUTION CTXT│    │  KNOWLEDGE CTXT │    │ SESSION CTXT    │
│ (sandbox)     │◀──▶│ (memory+context)│◀──▶│ (session+snap)  │
└───────┬───────┘    └─────────────────┘    └─────────────────┘
        │                                           │
        │ feeds context                              │ uses snapshots
        ▼                                           ▼
┌───────────────┐                          ┌─────────────────┐
│ GENERATION    │                          │ EXTENSIBILITY   │
│ CTXT          │◀────────────────────────▶│ CTXT (plugins)  │
│ (projects)    │    event-driven sync     │                 │
└───────────────┘                          └─────────────────┘

Leyenda de relaciones:
  ◀──▶ = Partnership (bidireccional, ambos se benefician)
  ───▶ = Upstream/Downstream (uno provee al otro)
```

---

## 11. Puntos de Extensión

### 11.1 Service Provider Interfaces (SPIs)

```
┌─────────────────────────────────────────────────────────────────┐
│                    SPI MAP                                       │
├────────────────────────┬────────────────────────────────────────┤
│ SPI                    │ Descripción                            │
├────────────────────────┼────────────────────────────────────────┤
│ ISandboxProvider       │ Permiten implementar nuevos motores    │
│                        │ de sandbox (docker, VM, process-level) │
├────────────────────────┼────────────────────────────────────────┤
│ IContextProvider       │ Permiten añadir nuevos contextos       │
│                        │ (custom, external data sources, etc.)  │
├────────────────────────┼────────────────────────────────────────┤
│ IStorageProvider       │ Permiten añadir nuevos backends de     │
│                        │ persistencia (Redis, CosmosDB, etc.)   │
├────────────────────────┼────────────────────────────────────────┤
│ IPlugin                │ Punto principal de extensión: plugins  │
│                        │ externos con lifecycle management      │
├────────────────────────┼────────────────────────────────────────┤
│ ICommand               │ Permiten añadir comandos CLI custom    │
├────────────────────────┼────────────────────────────────────────┤
│ ITemplateProvider      │ Permiten registrar nuevos templates    │
│                        │ de proyecto                            │
├────────────────────────┼────────────────────────────────────────┤
│ IReportGenerator       │ Permiten generar nuevos tipos de       │
│                        │ reportes                               │
└────────────────────────┴────────────────────────────────────────┘
```

### 11.2 Extension Points en el Ciclo de Vida

```
┌─────────────────────────────────────────────────────────────────┐
│                    LIFECYCLE HOOKS                                │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  System Lifecycle                                                │
│  ├── onSystemStarting        // Pre-init hook                   │
│  ├── onSystemInitialized     // Post-init hook                  │
│  ├── onSystemReady           // All components ready            │
│  ├── onSystemStopping        // Graceful shutdown               │
│  └── onSystemStopped         // Cleanup complete                │
│                                                                  │
│  Sandbox Lifecycle                                               │
│  ├── onSandboxCreated        // Post-creation hook              │
│  ├── onSandboxStarting       // Pre-execution hook              │
│  ├── onSandboxExecuted       // Post-execution hook             │
│  ├── onSandboxFailed         // Error handler hook              │
│  └── onSandboxDestroyed      // Cleanup hook                    │
│                                                                  │
│  Session Lifecycle                                               │
│  ├── onSessionStarted        // Session initialization          │
│  ├── onSessionSaved          // Post-save hook                  │
│  ├── onSessionRestored       // Post-restore hook               │
│  └── onSessionClosed         // Session cleanup                 │
│                                                                  │
│  Memory Lifecycle                                                │
│  ├── onMemoryStored          // Post-store hook                 │
│  ├── onMemoryRetrieved       // Post-retrieval hook             │
│  ├── onMemoryEvicted         // Eviction hook                   │
│  └── onMemoryCompacted       // Compaction hook                 │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 11.3 Plugin Discovery y Carga

```
┌─────────────────────────────────────────────────────────────────┐
│                    PLUGIN DISCOVERY FLOW                          │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│    ┌──────────────┐                                              │
│    │ Plugin Dir   │────scan──┐                                   │
│    │ (search path)│          ▼                                   │
│    └──────────────┘    ┌──────────┐                              │
│                        │ Discovery│                              │
│                        │ Service  │                              │
│                        └────┬─────┘                              │
│                             │ manifests                           │
│                             ▼                                    │
│                        ┌──────────┐                              │
│                        │ Validation│                              │
│                        │ (compat) │                              │
│                        └────┬─────┘                              │
│                             │ valid plugins                       │
│                             ▼                                    │
│                        ┌──────────┐                              │
│                        │ Plugin   │                              │
│                        │ Loader   │                              │
│                        └────┬─────┘                              │
│                             │ registered                         │
│                             ▼                                    │
│                        ┌──────────┐                              │
│                        │ Registry │  (disponible para            │
│                        │ (active) │   resolución)                │
│                        └──────────┘                              │
│                                                                  │
│  Hot-Reload (v1.0+):                                             │
│    Watch dir changes → Validate → Load/Unload → Notify Event Bus │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 12. Estrategia de Versioning

### 12.1 Versioning de APIs y Contratos

```
┌─────────────────────────────────────────────────────────────────┐
│                    API VERSIONING STRATEGY                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Contracts (contracts/):                                         │
│  • Inmutables dentro de una major version                        │
│  • Solo adiciones en minor versions                              │
│  • Deprecación con 1 minor version de aviso                      │
│  • Eliminación solo en major bump                                │
│                                                                  │
│  Modules (motor/*):                                              │
│  • SemVer estricto                                                │
│  • Changelog obligatorio                                         │
│  • Breaking changes documentados en migration guide              │
│                                                                  │
│  Plugins:                                                        │
│  • Versionado independiente                                      │
│  • Contrato de compatibilidad con core mínimo (IPlugin)          │
│  • Version manifest declara "compatible con core X.Y-Z.W"        │
│                                                                  │
│  Manifests:                                                      │
│  • Versión en el propio manifest                                 │
│  • Reader debe manejar versiones anteriores (backward-read)      │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 12.2 Matriz de Compatibilidad

| Major Version | Compatible con... | Breaking Changes |
|---------------|-------------------|------------------|
| 0.x → 0.y | Contratos inmutables en 0.x | Solo adiciones |
| 0.x → 1.0 | Migración planificada | Sí, documentada |
| 1.x → 1.y | Contratos inmutables en 1.x | Solo adiciones |
| 1.0 → 2.0 | Migración planificada | Sí, documentada |
| 2.x → 2.y | Contratos inmutables en 2.x | Solo adiciones |

### 12.3 Contrato de Evolución

```
┌─────────────────────────────────────────────────────────────────┐
│  EVOLUTION CONTRACT                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  Para CUALQUIER cambio en API pública:                           │
│                                                                  │
│  1. ANTES del cambio:                                            │
│     • Marcar como @Deprecated en release N                       │
│     • Documentar alternativa en migration guide                  │
│     • Emitir warning visible al usar la API deprecated           │
│                                                                  │
│  2. EN el cambio:                                                │
│     • Eliminar solo en major bump                                │
│     • Migration script automático (si aplica)                    │
│     • Changelog detallado                                        │
│                                                                  │
│  3. DESPUÉS del cambio:                                          │
│     • Actualizar todos los docs                                  │
│     • Verificar que tests de regresión pasan                     │
│     • Notificar a comunidad de plugins                           │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 13. Topología de Despliegue

### 13.1 Despliegue v1.0 (Single Machine)

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT TOPOLOGY v1.0                      │
│                    (Single Workstation)                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌────────────────────────────────────────────────────────┐   │
│   │                WORKSTATION (Windows 10/11)              │   │
│   │                                                        │   │
│   │   ┌──────────────────────────────────────────────┐    │   │
│   │   │    HERMES INSTALLATION DIRECTORY              │    │   │
│   │   │    (C:\Program Files\HERMES-Enterprise\)     │    │   │
│   │   │                                              │    │   │
│   │   │    ┌─────────────────────────────┐          │    │   │
│   │   │    │ motor/      (core engine)   │          │    │   │
│   │   │    │ scripts/    (helpers)       │          │    │   │
│   │   │    │ plugins/    (extensions)    │          │    │   │
│   │   │    │ config/     (configuration) │          │    │   │
│   │   │    │ data/       (state storage) │          │    │   │
│   │   │    │ logs/       (observability) │          │    │   │
│   │   │    └─────────────────────────────┘          │    │   │
│   │   └──────────────────────────────────────────────┘    │   │
│   │                                                        │   │
│   │   Dependencies:                                        │   │
│   │   • PowerShell 7+ (required)                           │   │
│   │   • .NET 6+ Runtime (required)                         │   │
│   │   • Git CLI (optional)                                 │   │
│   │   • VS Code + Extension (optional IDE)                 │   │
│   │                                                        │   │
│   └────────────────────────────────────────────────────────┘   │
│                                                                  │
│   Storage Options:                                               │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│   │ SQLite DB    │  │ JSON files   │  │ Plain files  │        │
│   │ (memory,     │  │ (config,     │  │ (logs,       │        │
│   │  session,    │  │  templates)  │  │  snapshots)  │        │
│   │  knowledge)  │  │              │  │              │        │
│   └──────────────┘  └──────────────┘  └──────────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 13.2 Despliegue v2.0 (Distributed, Conceptual)

```
┌─────────────────────────────────────────────────────────────────┐
│                    DEPLOYMENT TOPOLOGY v2.0                      │
│                    (Distributed / Cloud-Ready)                    │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│   ┌────────────────────────────────────────────────────┐       │
│   │                 WORKSTATION                        │       │
│   │   ┌──────────────────────────────────┐            │       │
│   │   │ Client (thin CLI + VS Code)      │            │       │
│   │   └───────────────┬──────────────────┘            │       │
│   └───────────────────┼────────────────────────────────┘       │
│                       │ gRPC/REST                               │
│                       ▼                                          │
│   ┌────────────────────────────────────────────────────┐       │
│   │              ORCHESTRATOR (local or remote)         │       │
│   │   ┌──────────┐ ┌──────────┐ ┌──────────┐          │       │
│   │   │ Scheduler│ │ Router   │ │ Watchdog │          │       │
│   │   └──────────┘ └──────────┘ └──────────┘          │       │
│   └──────────────────┬─────────────────────────────────┘       │
│                       │                                          │
│        ┌──────────────┼───────────────┐                        │
│        ▼              ▼               ▼                         │
│   ┌─────────┐  ┌─────────┐  ┌─────────────┐                  │
│   │ Worker  │  │ Worker  │  │ Worker      │                  │
│   │ Node 1  │  │ Node 2  │  │ Node N      │  ← Cloud-ready    │
│   │ (Sandbx)│  │ (Sandbx)│  │ (Sandbx)    │                  │
│   └─────────┘  └─────────┘  └─────────────┘                  │
│                                                                  │
│   Shared Storage:                                                │
│   ┌──────────────┐  ┌──────────────┐  ┌──────────────┐        │
│   │ Distributed  │  │ Object Store │  │ Search Index │        │
│   │ DB (Memory)  │  │ (Snapshots)  │  │ (Knowledge)  │        │
│   └──────────────┘  └──────────────┘  └──────────────┘        │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 13.3 Requisitos de Infraestructura

| Ambiente | Requisitos mínimos | Recomendado |
|----------|-------------------|-------------|
| Desarrollo | PS 7+, 2GB RAM, 500MB disk | PS 7.3+, 4GB RAM, 1GB disk |
| Producción v1.0 | PS 7+, 4GB RAM, 1GB disk | PS 7.3+, 8GB RAM, 2GB disk |
| v2.0 Distribuido | Orquestador: 4GB/2vCPU. Workers: n×2GB | Cloud instances |

---

## 14. Diagramas de Flujo de Datos

### 14.1 Data Flow: Desarrollo Asistido por HERMES

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATA FLOW: DEVELOPER WORKFLOW                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│                                                                  │
│        Developer           HERMES               Sistema         │
│            │                  │                     │            │
│    ┌───────┘                  └──────┐              │            │
│    │  1. Inicia sesión               │              │            │
│    │────────▶                         │              │            │
│    │                                  │──load──▶     │            │
│    │                                  │   Session    │            │
│    │                                  │  Manager     │            │
│    │                                  │◀─state──     │            │
│    │                                  │              │            │
│    │  2. Consulta contexto            │              │            │
│    │────────▶                         │              │            │
│    │                                  │──query─▶     │            │
│    │                                  │  Context     │            │
│    │                                  │  Manager     │            │
│    │                                  │◀─context─    │            │
│    │                                  │              │            │
│    │  3. Ejecuta en sandbox           │              │            │
│    │────────▶                         │              │            │
│    │                                  │──execute─▶   │            │
│    │                                  │  Sandbox     │            │
│    │                                  │◀─result──    │            │
│    │                                  │              │            │
│    │  4. HERMES aprende               │              │            │
│    │                                  │──store──▶    │            │
│    │                                  │  Memory      │            │
│    │                                  │  Engine      │            │
│    │                                  │              │            │
│    │  5. Toma snapshot                │              │            │
│    │────────▶                         │              │            │
│    │                                  │──snapshot─▶  │            │
│    │                                  │  Snapshot    │            │
│    │                                  │  Engine      │            │
│    │                                  │              │            │
│    │  6. Cierra sesión                │              │            │
│    │────────▶                         │              │            │
│    │                                  │──save──▶     │            │
│    │                                  │  (todo)      │            │
│    │                                  │              │            │
└─────────────────────────────────────────────────────────────────┘
```

### 14.2 Data Flow: Generación de Proyecto

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATA FLOW: PROJECT GENERATION                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│    User Input                                                    │
│    (Wizard/CLI)                                                  │
│         │                                                        │
│         │  template + options                                    │
│         ▼                                                        │
│    ┌──────────────┐                                              │
│    │  Project      │                                              │
│    │  Generator    │                                              │
│    └──────┬───────┘                                              │
│           │                                                      │
│           │──query template registry                              │
│           ▼                                                      │
│    ┌──────────────┐    ┌──────────────┐                         │
│    │ Template     │───▶│ Template     │                         │
│    │ Registry     │    │ Render       │                         │
│    └──────────────┘    └──────┬───────┘                         │
│                               │                                  │
│                               │──query context──┐               │
│                               ▼                 ▼               │
│                        ┌──────────────┐  ┌──────────────┐      │
│                        │ Context      │  │ Memory       │      │
│                        │ Manager      │  │ Engine       │      │
│                        │ (best-pract) │  │ (learned     │      │
│                        │              │  │  patterns)   │      │
│                        └──────────────┘  └──────────────┘      │
│                               │                 │               │
│                               ▼                 ▼               │
│                        ┌──────────────────────────┐             │
│                        │  Final Rendered Project  │             │
│                        └──────────────┬───────────┘             │
│                                       │                         │
│                                       ▼                         │
│                        ┌──────────────────────────┐             │
│                        │  File System (target dir) │             │
│                        │  + Git init               │             │
│                        │  + VS Code config auto    │             │
│                        └──────────────────────────┘             │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

### 14.3 Data Flow: Snapshot/Restore

```
┌─────────────────────────────────────────────────────────────────┐
│                    DATA FLOW: SNAPSHOT & RESTORE                 │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  SNAPSHOT (Captura de Estado)                                    │
│  ──────────────────────────                                      │
│                                                                  │
│    Estado Actual                                                 │
│    ┌────────────┐  ┌────────────┐  ┌────────────┐              │
│    │ Session    │  │ Memory     │  │ Context    │              │
│    │ State      │  │ Items      │  │ Data       │              │
│    └──────┬─────┘  └──────┬─────┘  └──────┬─────┘              │
│           │               │               │                      │
│           └───────────────┼───────────────┘                      │
│                           │                                      │
│                           ▼                                      │
│                    ┌────────────┐                                │
│                    │ Snapshot   │                                │
│                    │ Collector  │                                │
│                    │ (agrega    │                                │
│                    │  estado)   │                                │
│                    └──────┬─────┘                                │
│                           │                                      │
│                           ▼                                      │
│                    ┌────────────┐                                │
│                    │ Serializer │                                │
│                    │ (JSON/Bin) │                                │
│                    └──────┬─────┘                                │
│                           │                                      │
│                           ▼                                      │
│                    ┌────────────┐                                │
│                    │ Storage    │  → Archivo de snapshot         │
│                    │ Adapter    │  → data/snapshots/<id>.hermes │
│                    └────────────┘                                │
│                                                                  │
│  RESTORE (Restauración)                                          │
│  ────────────────                                                │
│                                                                  │
│    Archivo de Snapshot                                           │
│    ┌────────────┐                                                │
│    │ .hermes    │                                                │
│    │ file       │                                                │
│    └──────┬─────┘                                                │
│           │                                                      │
│           ▼                                                      │
│    ┌────────────┐                                                │
│    │ Deserializer│                                               │
│    └──────┬─────┘                                                │
│           │                                                      │
│           ▼                                                      │
│    ┌────────────┐                                                │
│    │ Validator  │  (verifica consistencia, compatibilidad)       │
│    └──────┬─────┘                                                │
│           │                                                      │
│           ▼                                                      │
│    ┌────────────┐                                                │
│    │ Applier    │  (restaura state, memory, context)             │
│    └──────┬─────┘                                                │
│           │                                                      │
│           ▼                                                      │
│    Estado Restaurado (equivalente al momento del snapshot)       │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## 15. Referencias Cruzadas

### 15.1 Referencias a Documentos del Roadmap

| Sección en este documento | Documento relacionado | Ubicación específica |
|--------------------------|----------------------|---------------------|
| Principios (sección 1) | [01_MASTER_ROADMAP.md](01_MASTER_ROADMAP.md) | §5.1 Principios Rectores |
| Sandbox Engine (sección 5.3) | [02_SANDBOX_ENGINE.md](02_SANDBOX_ENGINE.md) | Documento completo |
| Context Manager (sección 5.x) | [03_DEVELOPER_CONTEXT.md](03_DEVELOPER_CONTEXT.md) | Documento completo |
| Project Generator (sección 5.x) | [04_PROJECT_WIZARD.md](04_PROJECT_WIZARD.md) | Documento completo |
| Memory Engine (sección 5.4) | [05_SESSION_MEMORY.md](05_SESSION_MEMORY.md) | Documento completo |
| Event Bus (sección 9) | [01_MASTER_ROADMAP.md](01_MASTER_ROADMAP.md) | §7 Sprint D, SD-001 |
| Versioning (sección 12) | [09_RELEASE_PLAN.md](09_RELEASE_PLAN.md) | Strategy section |
| Componentes (sección 5) | [07_BACKLOG.md](07_BACKLOG.md) | Épicas relacionadas |
| Topología (sección 13) | [08_RISK_REGISTER.md](08_RISK_REGISTER.md) | Risks de despliegue |
| KPIs (sección relacionada) | [10_METRICS_KPI.md](10_METRICS_KPI.md) | Métricas arquitectónicas |

### 15.2 Referencias a Épicas del Backlog

| Componente en este documento | Épica asociada | Sprint |
|------------------------------|----------------|--------|
| Sandbox Engine (sección 5.3) | EPIC-1: Sandbox Engine Completion | A |
| Snapshot/Restore (sección 14.3) | EPIC-2: Snapshot/Restore/Rollback | A-B |
| Context Manager (sección 5.x) | EPIC-3: Developer Context Completion | B |
| Memory Engine (sección 5.4) | EPIC-4: Memory Engine | C |
| Project Generator | EPIC-5: Project Generator | C |
| Event Bus (sección 9) | EPIC-7: Enterprise Platform Hardening | D |
| Plugin Loader (sección 11.3) | EPIC-7: Enterprise Platform Hardening | D |

### 15.3 Decisiones de Arquitectura Registradas (ADRs)

| ADR# | Tema | Decisión | Justificación |
|------|------|----------|---------------|
| ADR-001 | Backend de persistencia | SQLite primary, JSON fallback | Bajo overhead, sin dependencias externas |
| ADR-002 | Bus de eventos | Interno, en-memory con DLQ | Simple para single-machine, migrable a distributed |
| ADR-003 | Plugin loading | Manifest-based manifest.json | Discovery sin reflection costoso |
| ADR-004 | Snapshot format | JSON serializado + hash | Legible + verificación integridad |
| ADR-005 | API contracts | PowerShell classes (no .NET only) | Portabilidad, no requiere compile |
| ADR-006 | Observability | OpenTelemetry-compatible | Estandar abierto, portable |
| ADR-007 | Security model | Capability-based + ACL hybrid | Balance entre granularidad y simplicidad |
| ADR-008 | Configuration | YAML primary, env overrides | Legible + override friendly |

---

## Navegación Final

| Documento | Enlace | Propósito |
|-----------|--------|-----------|
| Master Roadmap | [01_MASTER_ROADMAP.md](01_MASTER_ROADMAP.md) | Plan maestro del proyecto |
| Sandbox Engine | [02_SANDBOX_ENGINE.md](02_SANDBOX_ENGINE.md) | Detalle del motor de sandbox |
| Developer Context | [03_DEVELOPER_CONTEXT.md](03_DEVELOPER_CONTEXT.md) | Detalle del contexto del desarrollador |
| Project Wizard | [04_PROJECT_WIZARD.md](04_PROJECT_WIZARD.md) | Detalle del asistente de proyectos |
| Session Memory | [05_SESSION_MEMORY.md](05_SESSION_MEMORY.md) | Detalle del motor de memoria |
| Architecture Target | [06_ARCHITECTURE_TARGET.md](06_ARCHITECTURE_TARGET.md) | **Este documento** |
| Full Backlog | [07_BACKLOG.md](07_BACKLOG.md) | Todas las historias por sprint |
| Risk Register | [08_RISK_REGISTER.md](08_RISK_REGISTER.md) | Registro de riesgos |
| Release Plan | [09_RELEASE_PLAN.md](09_RELEASE_PLAN.md) | Plan detallado de releases |
| Metrics & KPIs | [10_METRICS_KPI.md](10_METRICS_KPI.md) | Métricas e indicadores |

---

## Anexos

### Anexo A: Glosario de Términos Arquitectónicos

| Término | Definición |
|---------|-----------|
| **Bounded Context** | Región con modelo de dominio coherente y lenguaje ubicuo |
| **SPI** | Service Provider Interface — contrato para extensibilidad |
| **DLQ** | Dead Letter Queue — cola de eventos fallidos |
| **Adapter** | Patrón que abstrae una implementación concreta detrás de una interface |
| **Facade** | Patrón que simplifica una API compleja |
| **CQRS** | Command Query Responsibility Segregation (no implementado aún) |
| **Pub/Sub** | Publish/Subscribe — patrón de mensajería asíncrona |
| **Idempotente** | Operación que produce el mismo resultado independientemente de cuántas veces se ejecute |
| **Hot-Reload** | Capacidad de recargar componentes sin detener el sistema |

### Anexo B: Historial de Cambios

| Fecha | Versión | Autor | Cambios |
|-------|---------|-------|---------|
| 2026-07-07 | 1.0.0 | HERMES Enterprise Architecture Board | Versión inicial DRAFT |

---

> **Prev:** [01_MASTER_ROADMAP.md](01_MASTER_ROADMAP.md) | **Next:** [07_BACKLOG.md](07_BACKLOG.md)
