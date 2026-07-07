---
title: "Backlog Priorizado"
document: "HERMES Enterprise - Product Backlog"
date: 2026-07-07
status: DRAFT
version: "1.0"
author: "Equipo HERMES Enterprise"
total_items: 88
total_story_points: 462
total_hours: 1848
cross_references:
  - "01_PROJECT_CHARTER.md"
  - "02_VISION_SCOPE.md"
  - "03_ARCHITECTURE.md"
  - "04_ROADMAP.md"
  - "05_SPRINT_D.md"
  - "06_SPRINT_C.md"
  - "08_RISK_REGISTER.md"
  - "10_ACCEPTANCE_PLAN.md"
---

# Backlog Priorizado - HERMES Enterprise

## Navegación

| Documento Anterior | Índice General | Documento Siguiente |
|---|---|---|
| [05_SPRINT_D.md](05_SPRINT_D.md) | [04_ROADMAP.md](04_ROADMAP.md) | [08_RISK_REGISTER.md](08_RISK_REGISTER.md) |

---

## 1. Resumen Ejecutivo del Backlog

### 1.1 Visión General

Este documento contiene el **Product Backlog completo y priorizado** del proyecto HERMES Enterprise. Cada item ha sido descompuesto en unidades de trabajo estimables, con dependencias claras y asignación a sprints específicos del roadmap.

El backlog refleja la priorización acordada por el equipo de producto y stakeholders, considerando:
- Valor de negocio entregado
- Dependencias técnicas entre items
- Riesgos y complejidad
- Feedback de usuarios y clientes
- Objetivos estratégicos del proyecto

### 1.2 Métricas del Backlog

| Métrica | Valor |
|---|---|
| **Total de Items** | 88 items |
| **Total Story Points** | 462 SP |
| **Total Horas Estimadas** | 1,848h |
| **Items P0 (Críticos)** | 10 items (92 SP) |
| **Items P1 (Altos)** | 20 items (152 SP) |
| **Items P2 (Medios)** | 30 items (181 SP) |
| **Items P3 (Bajos)** | 28 items (137 SP) |
| **Velocidad del Equipo** | 40 SP / sprint (2 semanas) |
| **Sprints Estimados Total** | 12 sprints (~24 semanas) |

### 1.3 Distribución por Sprint

| Sprint | Nombre | SP Asignados | # Items | Fecha Objetivo |
|---|---|---|---|---|
| Sprint A | Safe Sandbox (Recovery) | 92 SP | 10 | Semana 4 |
| Sprint B | Project Generator | 52 SP | 12 | Semana 10 |
| Sprint C | Memory & Learning | 78 SP | 20 | Semana 18 |
| Sprint D | Autonomous Platform | 162 SP | 21 | Semana 24+ |
| Backlog | Futuro / Extendido | 78 SP | 25 | TBD |
| **Total** | | **462 SP** | **88** | |

### 1.4 Leyenda de Estados

| Status | Descripción |
|---|---|
| **New** | Item identificado, no refinado |
| **Ready** | Refinado, estimado, listo para sprint |
| **Planned** | Asignado a sprint específico |
| **In Progress** | En desarrollo activo |
| **Done** | Completado y verificado |

### 1.5 Leyenda de Complejidad

| Nivel | Nombre | Rango Hours | Rango SP |
|---|---|---|---|
| **S** | Small | 4-12h | 1-3 SP |
| **M** | Medium | 13-24h | 4-5 SP |
| **L** | Large | 25-40h | 8 SP |
| **XL** | Extra Large | 40-60h | 13 SP |

---

## 2. P0 - Prioridad Crítica (Must Do Now)

> **Descripción:** Estos son los items fundamentales del proyecto. Sin ellos, el sistema no funciona, el roadmap se bloquea completamente, o se incumplen compromisos con stakeholders. Representan la base sobre la cual se construye todo lo demás.
>
> **Compromiso:** Completar TODOS los items P0 en Sprint A y B. Son 10 items que totalizan 92 SP.

### 2.1 Tabla de Items P0

| ID | Nombre | Descripción | Prioridad | Deps | Compl | SP | Hrs | Status | Sprint |
|---|---|---|---|---|---|---|---|---|---|
| HERM-0001 | Sandbox System Core | Sistema de sandbox aislado para ejecución segura. Implementar contenedores con restricciones de recursos y permisos limitados. | P0 | - | XL | 13 | 52h | Planned | A |
| HERM-0002 | Command Validation Engine | Motor de validación y clasificación de comandos por nivel de riesgo. Define políticas de qué comandos son seguros, sensibles o peligrosos. | P0 | HERM-0001 | L | 8 | 32h | Planned | A |
| HERM-0003 | Supervisor Process | Proceso supervisor que monitorea y controla todas las acciones de Hermes en tiempo real. Actúa como guardián del sistema. | P0 | HERM-0001, HERM-0002 | XL | 13 | 52h | Planned | A |
| HERM-0004 | Safe Execution Pipeline | Pipeline de ejecución con gates de approval para comandos clasificados como sensibles. Implementa workflow de aprobación. | P0 | HERM-0003 | L | 8 | 32h | Planned | A |
| HERM-0005 | Context Manager | Gestión de contexto de proyecto: detecta archivos, dependencias, estructura y tecnología del proyecto actual. | P0 | HERM-0001 | L | 8 | 32h | Planned | A |
| HERM-0006 | Session Persistence | Persistencia de estado entre sesiones de trabajo. Permite retomar trabajo donde se dejó sin pérdida de contexto. | P0 | HERM-0005 | M | 5 | 20h | Planned | A |
| HERM-0007 | Recovery System | Sistema de recuperación ante fallos. Implementa rollback automático y restauración de estado consistente. | P0 | HERM-0004 | L | 8 | 32h | Ready | A |
| HERM-0008 | Project Template Engine V1 | Motor base de templates para generación de proyectos. Soporta placeholders, condicionales y herencia de templates. | P0 | HERM-0005 | L | 13 | 52h | Ready | B |
| HERM-0009 | Multi-Language Support | Soporte para generar proyectos en C#, Java, Node.js, Python y Go. Incluye templates específicos por lenguaje. | P0 | HERM-0008 | L | 8 | 32h | Ready | B |
| HERM-0010 | Core CLI Framework | Framework CLI base del sistema. Autocompletado, ayuda contextual, parseo de argumentos, manejo de errores. | P0 | - | L | 8 | 32h | Ready | A |

### 2.2 Criterios de Done para P0

Cada item P0 debe cumplir al menos:

- [ ] Funcionalidad core implementada y funcional
- [ ] Tests unitarios con cobertura ≥ 80%
- [ ] Tests de integración pasando
- [ ] Documentación técnica actualizada (ADR + README)
- [ ] Code review aprobado por ≥2 desarrolladores
- [ ] Sin vulnerabilidades críticas (scan de seguridad pasado)
- [ ] Demo funcional ante stakeholders
- [ ] Performance dentro de SLA acordado

### 2.3 Orden de Implementación P0

```
Fase 1: Foundation (Semana 1-2)
├── HERM-0010 (CLI Framework) → Independiente
├── HERM-0001 (Sandbox) → Independiente
└── HERM-0002 (Validation) → Depende de HERM-0001

Fase 2: Control (Semana 3-4)
├── HERM-0003 (Supervisor) → Depende de HERM-0001 + HERM-0002
├── HERM-0004 (Safe Pipeline) → Depende de HERM-0003
└── HERM-0005 (Context Manager) → Depende de HERM-0001

Fase 3: Persistence & Recovery (Semana 5-6)
├── HERM-0006 (Session Persistence) → Depende de HERM-0005
├── HERM-0007 (Recovery) → Depende de HERM-0004
└── HERM-0008 (Template Engine) → Depende de HERM-0005

Fase 4: Multi-Language (Semana 7-8)
└── HERM-0009 (Multi-Language) → Depende de HERM-0008
```

---

## 3. P1 - Prioridad Alta (Next Release)

> **Descripción:** Items que habilitan funcionalidades clave del roadmap. Aunque existen workarounds temporales, sin estos items la experiencia de usuario es significativamente inferior y el producto no alcanza su propuesta de valor completa.
>
> **Compromiso:** Completar al menos 80% de items P1 en Sprint B y C. Son 20 items que totalizan 152 SP.

### 3.1 Tabla de Items P1

| ID | Nombre | Descripción | Prioridad | Deps | Compl | SP | Hrs | Status | Sprint |
|---|---|---|---|---|---|---|---|---|---|
| HERM-0011 | VS Code Extension Base | Extensión base para VS Code que permite integración directa del IDE con Hermes. Sidebar, comandos y status bar. | P1 | HERM-0010 | L | 8 | 32h | Planned | B |
| HERM-0012 | Git Integration Layer | Abstracción de Git para soportar GitHub, GitLab y Azure DevOps con interfaz unificada. | P1 | HERM-0010 | L | 8 | 32h | Planned | B |
| HERM-0013 | Project Wizard CLI | Wizard interactivo paso a paso para creación de proyectos con preguntas contextuales. | P1 | HERM-0008 | L | 8 | 32h | Planned | B |
| HERM-0014 | Dependency Analyzer | Análisis automático de dependencias con detección de vulnerabilidades y versiones desactualizadas. | P1 | HERM-0005 | M | 5 | 20h | Planned | B |
| HERM-0015 | Test Runner Integration | Integración con ejecutores de tests (xUnit, NUnit, Jest, pytest, Go test) con output unificado. | P1 | HERM-0014 | M | 5 | 20h | Planned | B |
| HERM-0016 | Memory System Core | Sistema de memoria persistente basado en vector embeddings. Permite a Hermes recordar contexto acumulado. | P1 | HERM-0006 | XL | 13 | 52h | Planned | C |
| HERM-0017 | Learning Engine | Motor de aprendizaje que identifica patrones de uso y ajusta comportamiento de Hermes automáticamente. | P1 | HERM-0016 | XL | 13 | 52h | Planned | C |
| HERM-0018 | Knowledge Base | Base de conocimiento estructurada con búsqueda semántica. Indexa documentación, código y decisiones. | P1 | HERM-0016 | L | 8 | 32h | Planned | C |
| HERM-0019 | Report Generator | Generador de reportes de actividad, métricas y health del proyecto en múltiples formatos. | P1 | HERM-0006 | M | 5 | 20h | Planned | B |
| HERM-0020 | Dashboard Web V1 | Dashboard web para monitoring en tiempo real del estado de Hermes y proyectos gestionados. | P1 | HERM-0019 | L | 8 | 32h | Planned | C |
| HERM-0021 | Plugin Architecture | Arquitectura extensible de plugins con ciclo de vida definido, hooks y API de extensión. | P1 | HERM-0010 | XL | 13 | 52h | Planned | A |
| HERM-0022 | CI/CD Integration | Generación y configuración de pipelines CI/CD para GitHub Actions y Azure DevOps. | P1 | HERM-0012 | M | 5 | 20h | Planned | B |
| HERM-0023 | Linting & Formatting | Integración automática de linters y formatters por lenguaje (ESLint, Prettier, dotnet-format, etc.) | P1 | HERM-0014 | M | 5 | 20h | Planned | B |
| HERM-0024 | Code Review Assistant | Asistente de code review automatizado que analiza diffs y sugiere mejoras. | P1 | HERM-0017 | L | 8 | 32h | Planned | C |
| HERM-0025 | Multi-Provider AI | Soporte para múltiples providers de AI con failover automático: OpenAI, Anthropic, local (Ollama). | P1 | HERM-0010 | L | 8 | 32h | Planned | A |
| HERM-0026 | Security Scanner | Escáner de seguridad básico integrado en el pipeline (SAST simplificado). | P1 | HERM-0014 | M | 5 | 20h | Planned | B |
| HERM-0027 | Documentation Generator | Generador de documentación técnica a partir del código (API docs, README, arquitectura). | P1 | HERM-0005 | M | 5 | 20h | Planned | C |
| HERM-0028 | Error Recovery Patterns | Implementación de patrones de recuperación automática para errores comunes. | P1 | HERM-0007, HERM-0017 | M | 5 | 20h | Planned | C |
| HERM-0029 | Performance Profiler | Perfilador de performance para acciones de Hermes con métricas y visualización. | P1 | HERM-0019 | M | 5 | 20h | Planned | C |
| HERM-0030 | Notification System | Sistema de notificaciones multi-canal: email, Slack, Teams, webhook genérico. | P1 | HERM-0006 | S | 3 | 12h | Planned | C |

### 3.2 Agrupación Temática P1

| Grupo | Items | SP Total | Descripción |
|---|---|---|---|
| IDE & Developer Experience | HERM-0011, HERM-0013, HERM-0024 | 24 SP | Integración con herramientas de desarrollo |
| Source Control & CI/CD | HERM-0012, HERM-0022, HERM-0026 | 18 SP | Integración con Git y pipelines |
| Quality & Code Analysis | HERM-0014, HERM-0015, HERM-0023 | 15 SP | Análisis y mejora de calidad de código |
| Intelligence & Memory | HERM-0016, HERM-0017, HERM-0018, HERM-0028 | 39 SP | Sistema de aprendizaje y memoria |
| Monitoring & Reporting | HERM-0019, HERM-0020, HERM-0029, HERM-0030 | 21 SP | Visibilidad y alertas |
| Extensibility | HERM-0021, HERM-0025, HERM-0027 | 26 SP | Arquitectura de extensión |

### 3.3 Orden de Implementación P1

```
Fase 1: Developer Experience (Sprint B inicio)
├── HERM-0011 (VS Code Extension)
├── HERM-0013 (Project Wizard)
├── HERM-0014 (Dependency Analyzer)
└── HERM-0023 (Linting & Formatting)

Fase 2: Integration Layer (Sprint B medio)
├── HERM-0012 (Git Integration)
├── HERM-0015 (Test Runner)
├── HERM-0022 (CI/CD Integration)
└── HERM-0026 (Security Scanner)

Fase 3: Intelligence Foundation (Sprint C inicio)
├── HERM-0016 (Memory System) → Base para HERM-0017, HERM-0018
├── HERM-0017 (Learning Engine) → Depende de Memory
└── HERM-0018 (Knowledge Base) → Depende de Memory

Fase 4: Visibility & Automation (Sprint C medio)
├── HERM-0019 (Report Generator)
├── HERM-0020 (Dashboard Web)
├── HERM-0024 (Code Review)
└── HERM-0028 (Error Recovery)

Fase 5: Polish (Sprint C final)
├── HERM-0029 (Performance Profiler)
├── HERM-0030 (Notification System)
└── HERM-0027 (Documentation Generator)
```

---

## 4. P2 - Prioridad Media (Backlog)

> **Descripción:** Items que agregan valor significativo pero no bloquean funcionalidad core. Se implementan cuando la capacidad del equipo lo permite, típicamente en Sprint D o después. Representan la profundidad y robustez del producto.
>
> **Compromiso:** Completar ~60% de items P2 en Sprint D. Los restantes van al backlog extendido. Son 30 items que totalizan 181 SP.

### 4.1 Tabla de Items P2 - Generadores Empresarial

| ID | Nombre | Descripción | Prioridad | Deps | Compl | SP | Hrs | Status | Sprint |
|---|---|---|---|---|---|---|---|---|---|
| HERM-0031 | Enterprise Template Library v1 | Biblioteca inicial de 10+ templates empresariales versionados y probados. | P2 | HERM-0008 | M | 5 | 20h | New | C |
| HERM-0032 | Monorepo Support | Soporte para monorepositorios con workspaces compartidos y dependencias cruzadas. | P2 | HERM-0012 | L | 8 | 32h | New | C |
| HERM-0033 | Database Schema Generator | Generador de schemas de bases de datos (SQL Server, PostgreSQL, MySQL) con migrations. | P2 | HERM-0008 | L | 8 | 32h | New | D |
| HERM-0034 | API Contract Testing | Herramientas de testing de contratos API (OpenAPI validation, contract tests). | P2 | HERM-0015 | M | 5 | 20h | New | C |
| HERM-0035 | Docker Compose Generator | Generador de Docker Compose files para desarrollo local con servicios dependientes. | P2 | HERM-0012 | M | 5 | 20h | New | D |
| HERM-0036 | Kubernetes Manifest Generator | Generador de manifests de Kubernetes (Deployments, Services, Ingress, HPA). | P2 | HERM-0035 | L | 8 | 32h | New | D |
| HERM-0037 | Terraform Module Generator | Generador de módulos Terraform reutilizables para infraestructura como código. | P2 | HERM-0050 | L | 8 | 32h | New | D |
| HERM-0038 | Helm Chart Generator | Generador de Helm Charts para empaquetar aplicaciones Kubernetes. | P2 | HERM-0036 | M | 5 | 20h | New | D |
| HERM-0039 | Microservice Scaffold | Scaffolding completo de microservicios con patrones de comunicación (REST, gRPC, events). | P2 | HERM-0008 | L | 8 | 32h | New | D |
| HERM-0040 | Domain Bounded Context Gen | Generador de bounded contexts con estructura DDD completa (entities, value objects, aggregates). | P2 | HERM-0039 | L | 8 | 32h | New | D |

### 4.2 Tabla de Items P2 - Arquitectura y Patrones

| ID | Nombre | Descripción | Prioridad | Deps | Compl | SP | Hrs | Status | Sprint |
|---|---|---|---|---|---|---|---|---|---|
| HERM-0041 | Event-Driven Architecture | Generador de arquitectura basada en eventos con brokers (RabbitMQ, Kafka, Service Bus). | P2 | HERM-0039 | L | 8 | 32h | New | D |
| HERM-0042 | GraphQL Schema Generator | Generador de schemas GraphQL con resolvers, types y mutations. | P2 | HERM-0008 | M | 5 | 20h | New | D |
| HERM-0043 | REST API Generator | Generador de REST APIs completas con CRUD, pagination, filtering y versionado. | P2 | HERM-0008 | M | 5 | 20h | New | D |
| HERM-0044 | gRPC Service Generator | Generador de servicios gRPC con protobuf definitions y client stubs. | P2 | HERM-0008 | L | 8 | 32h | New | D |
| HERM-0045 | Message Queue Integration | Integración con colas de mensajes (RabbitMQ, Azure Service Bus, AWS SQS). | P2 | HERM-0039 | M | 5 | 20h | New | D |
| HERM-0046 | Cache Strategy Generator | Generador de estrategias de caché (Redis, Memcached) con invalidation patterns. | P2 | HERM-0039 | M | 5 | 20h | New | D |
| HERM-0047 | Auth Module Generator | Generador de módulos de autenticación/autorización (OIDC, JWT, OAuth2). | P2 | HERM-0008 | M | 5 | 20h | New | D |

### 4.3 Tabla de Items P2 - Infraestructura y Operaciones

| ID | Nombre | Descripción | Prioridad | Deps | Compl | SP | Hrs | Status | Sprint |
|---|---|---|---|---|---|---|---|---|---|
| HERM-0048 | Logging Framework Integration | Integración de frameworks de logging estructurados (Serilog, Winston, loguru). | P2 | HERM-0010 | S | 3 | 12h | New | C |
| HERM-0049 | Metrics Exporter | Exportador de métricas a sistemas de monitoring (Prometheus, DataDog, App Insights). | P2 | HERM-0029 | M | 5 | 20h | New | D |
| HERM-0050 | Cloud Deploy Templates | Templates de deployment para Azure, AWS y GCP con IaC incluido. | P2 | HERM-0012 | L | 8 | 32h | New | D |
| HERM-0051 | Secrets Management | Integración con gestores de secrets (Azure Key Vault, AWS Secrets Manager, HashiCorp Vault). | P2 | HERM-0010 | M | 5 | 20h | New | C |
| HERM-0052 | Config Management | Gestión de configuración multi-ambiente con override jerárquico. | P2 | HERM-0051 | M | 5 | 20h | New | C |

### 4.4 Tabla de Items P2 - Herramientas de Análisis

| ID | Nombre | Descripción | Prioridad | Deps | Compl | SP | Hrs | Status | Sprint |
|---|---|---|---|---|---|---|---|---|---|
| HERM-0053 | Migration Tool Toolkit | Toolkit para migraciones entre tecnologías (ej: .NET Framework → .NET 8). | P2 | HERM-0008 | L | 8 | 32h | New | Backlog |
| HERM-0054 | Legacy Code Analysis | Analizador de código legacy para identificar oportunidades de modernización. | P2 | HERM-0014 | L | 8 | 32h | New | Backlog |
| HERM-0055 | Dependency Graph Visualizer | Visualizador interactivo del grafo de dependencias del proyecto. | P2 | HERM-0014 | M | 5 | 20h | New | C |
| HERM-0056 | Code Complexity Analyzer | Analizador de métricas de complejidad de código (cyclomatic, cognitive). | P2 | HERM-0014 | M | 5 | 20h | New | C |
| HERM-0057 | Test Coverage Reporter | Reporteador de cobertura de tests con tendencias históricas. | P2 | HERM-0015 | S | 3 | 12h | New | C |
| HERM-0058 | Performance Benchmark Suite | Suite automatizada de benchmarks para comparar versiones y detectar regresiones. | P2 | HERM-0029 | M | 5 | 20h | New | Backlog |
| HERM-0059 | Accessibility Checker | Verificador automatizado de accesibilidad web (WCAG 2.1 AA). | P2 | HERM-0011 | M | 5 | 20h | New | Backlog |
| HERM-0060 | i18n Support | Soporte de internacionalización con extracción de strings y generación de archivos de recursos. | P2 | HERM-0010 | M | 5 | 20h | New | Backlog |

### 4.5 Resumen P2 por Categoría

| Categoría | Items | SP Total | Horas | Principal Sprint |
|---|---|---|---|---|
| Generadores Empresarial | 10 | 68 SP | 272h | D |
| Arquitectura y Patrones | 7 | 41 SP | 164h | D |
| Infraestructura y Ops | 5 | 26 SP | 104h | C-D |
| Análisis y Herramientas | 8 | 36 SP | 144h | C/Backlog |
| **Total P2** | **30** | **181 SP** | **724h** | |

---

## 5. P3 - Prioridad Baja (Nice to Have)

> **Descripción:** Items deseables que mejoran la experiencia pero no son esenciales para el funcionamiento del producto. Se implementan cuando hay capacidad disponible después de completar P0, P1 y P2. Incluyen integraciones con canales de comunicación, mejoras de UX y funcionalidades avanzadas.
>
> **Compromiso:** Completar ~40% en Sprint D si hay capacidad. El resto va al backlog extendido. Son 28 items que totalizan 137 SP.

### 5.1 Tabla de Items P3 - UX y Personalización

| ID | Nombre | Descripción | Prioridad | Deps | Compl | SP | Hrs | Status | Sprint |
|---|---|---|---|---|---|---|---|---|---|
| HERM-0061 | Dark Mode Dashboard | Modo oscuro para el dashboard web con temas switchables. | P3 | HERM-0020 | S | 2 | 8h | New | Backlog |
| HERM-0062 | Theme Customization | Sistema de temas personalizables para dashboard y CLI output. | P3 | HERM-0020 | M | 3 | 12h | New | Backlog |
| HERM-0063 | Gamification Badges | Sistema de badges y logros para motivar uso de mejores prácticas. | P3 | HERM-0020 | M | 5 | 20h | New | Backlog |
| HERM-0078 | CLI Snippet Manager | Gestor de snippets de comandos CLI con búsqueda y categorías. | P3 | HERM-0010 | M | 3 | 12h | New | Backlog |
| HERM-0079 | Bookmark System | Sistema de bookmarks para guardar contextos y estados importantes. | P3 | HERM-0006 | S | 2 | 8h | New | Backlog |
| HERM-0080 | Time Tracking | Tracking de tiempo dedicado a diferentes tareas con reportes. | P3 | HERM-0019 | M | 3 | 12h | New | Backlog |
| HERM-0081 | Cost Estimator | Estimador de costos de infraestructura cloud basado en templates. | P3 | HERM-0050 | M | 5 | 20h | New | Backlog |

### 5.2 Tabla de Items P3 - Marketplace y Comunidad

| ID | Nombre | Descripción | Prioridad | Deps | Compl | SP | Hrs | Status | Sprint |
|---|---|---|---|---|---|---|---|---|---|
| HERM-0064 | Community Plugin Hub | Hub público de plugins mantenido por la comunidad con ratings. | P3 | HERM-0021 | L | 8 | 32h | New | D |
| HERM-0065 | Skill Marketplace Public | Marketplace público de skills reutilizables con sistema de review. | P3 | HERM-0100 | L | 8 | 32h | New | D |
| HERM-0066 | Agent Templates Gallery | Galería de templates de agentes especializados compartidos. | P3 | HERM-0095 | L | 8 | 32h | New | D |
| HERM-0082 | Team Collaboration | Funcionalidades de colaboración: compartir contexto, tareas asignadas, comentarios. | P3 | HERM-0020 | L | 8 | 32h | New | Backlog |
| HERM-0083 | Knowledge Wiki | Wiki interna de conocimiento compartido entre equipos y proyectos. | P3 | HERM-0018 | L | 8 | 32h | New | Backlog |

### 5.3 Tabla de Items P3 - Interfaces y Canales

| ID | Nombre | Descripción | Prioridad | Deps | Compl | SP | Hrs | Status | Sprint |
|---|---|---|---|---|---|---|---|---|---|
| HERM-0067 | Voice Interface | Interfaz de voz para comandos de Hermes (speech-to-text + text-to-speech). | P3 | HERM-0010 | L | 13 | 52h | New | Backlog |
| HERM-0068 | Chat Interface Web | Interfaz web de chat conversacional con Hermes. | P3 | HERM-0020 | L | 8 | 32h | New | Backlog |
| HERM-0069 | Mobile Companion App | App móvil para monitorización y notificaciones de Hermes. | P3 | HERM-0068 | XL | 13 | 52h | New | Backlog |
| HERM-0070 | Slack Bot Integration | Bot de Slack para interactuar con Hermes desde canales. | P3 | HERM-0030 | M | 5 | 20h | New | Backlog |
| HERM-0071 | Teams Bot Integration | Bot de Microsoft Teams para interactuar con Hermes. | P3 | HERM-0030 | M | 5 | 20h | New | Backlog |
| HERM-0072 | Discord Bot Integration | Bot de Discord para comunidad de usuarios de Hermes. | P3 | HERM-0030 | M | 5 | 20h | New | Backlog |
| HERM-0073 | Telegram Bot Integration | Bot de Telegram para notificaciones y comandos básicos. | P3 | HERM-0030 | M | 5 | 20h | New | Backlog |

### 5.4 Tabla de Items P3 - APIs y Documentación

| ID | Nombre | Descripción | Prioridad | Deps | Compl | SP | Hrs | Status | Sprint |
|---|---|---|---|---|---|---|---|---|---|
| HERM-0074 | Email Notifications Pro | Sistema avanzado de notificaciones por email con templates personalizables. | P3 | HERM-0030 | S | 3 | 12h | New | Backlog |
| HERM-0075 | Webhook System | Sistema de webhooks genérico para integración con cualquier servicio externo. | P3 | HERM-0030 | M | 5 | 20h | New | Backlog |
| HERM-0076 | REST API Public | API REST pública documentada con OpenAPI 3.0 para integración externa. | P3 | HERM-0010 | L | 8 | 32h | New | Backlog |
| HERM-0077 | GraphQL API Public | API GraphQL con schema público para queries flexibles. | P3 | HERM-0076 | L | 8 | 32h | New | Backlog |
| HERM-0084 | Auto-Documentation Updates | Actualización automática de documentación cuando cambia el código. | P3 | HERM-0027 | M | 5 | 20h | New | Backlog |
| HERM-0085 | Changelog Generator | Generador de changelogs automáticos desde commits y PRs. | P3 | HERM-0012 | S | 3 | 12h | New | Backlog |
| HERM-0086 | Release Notes Generator | Generador de release notes con resumen de cambios por versión. | P3 | HERM-0085 | S | 2 | 8h | New | Backlog |
| HERM-0087 | Presentation Generator | Generador de presentaciones técnicas para demos y reviews. | P3 | HERM-0027 | L | 8 | 32h | New | Backlog |
| HERM-0088 | Video Tutorial Generator | Generador de video tutoriales automatizados de features. | P3 | HERM-0068 | XL | 13 | 52h | New | Backlog |

### 5.5 Resumen P3 por Categoría

| Categoría | Items | SP Total | Horas | Principal Sprint |
|---|---|---|---|---|
| UX y Personalización | 7 | 23 SP | 92h | Backlog |
| Marketplace y Comunidad | 5 | 40 SP | 160h | D/Backlog |
| Interfaces y Canales | 7 | 54 SP | 216h | Backlog |
| APIs y Documentación | 9 | 30 SP | 120h | Backlog |
| **Total P3** | **28** | **137 SP** | **548h** | |

---

## 6. Análisis del Backlog

### 6.1 Distribución de Story Points por Prioridad

```
P0 ████████████████████████████████████  92 SP  (20%)
P1 ██████████████████████████████████████████████████████████████ 152 SP  (33%)
P2 █████████████████████████████████████████████████████████████████████ 181 SP  (39%)
P3 ████████████████████████████████████ 137 SP  (30%)
   └─────────────────────────────────────────────────────────┘
   0    50    100   150   200   250   300   350   400   462
```

### 6.2 Distribución de Complejidad

| Complejidad | # Items | SP Total | % del Total |
|---|---|---|---|
| S (Small) | 6 | 16 SP | 3.5% |
| M (Medium) | 30 | 136 SP | 29.4% |
| L (Large) | 36 | 256 SP | 55.4% |
| XL (Extra Large) | 6 | 54 SP | 11.7% |
| **Total** | **88** (notas: algunos items P3 tienen complejidad mixta) | **462 SP** | **100%** |

### 6.3 Items con Más Dependencias (Risk de Bloqueo)

| ID | Nombre | # Dependencias | Depende De |
|---|---|---|---|
| HERM-0003 | Supervisor Process | 2 | HERM-0001, HERM-0002 |
| HERM-0028 | Error Recovery | 2 | HERM-0007, HERM-0017 |
| HERM-0037 | Terraform Generator | 1 | HERM-0050 |
| HERM-0038 | Helm Chart Generator | 1 | HERM-0036 |
| HERM-0086 | Release Notes Gen | 1 | HERM-0085 |
| HERM-0088 | Video Tutorial Gen | 1 | HERM-0068 |

### 6.4 Items Sin Dependencias (Pueden Iniciar en Paralelo)

Items independientes que pueden iniciarse en cualquier sprint:

| ID | Nombre | SP |
|---|---|---|
| HERM-0001 | Sandbox System Core | 13 |
| HERM-0010 | Core CLI Framework | 8 |
| HERM-0021 | Plugin Architecture | 13 |
| HERM-0025 | Multi-Provider AI | 8 |

---

## 7. Proyección y Forecasting

### 7.1 Velocidad del Equipo

| Sprint | Capacidad (SP) | Items Planificados | SP Comprometidos | Buffer (10%) |
|---|---|---|---|---|
| A1 (Sem 1-2) | 40 | 5-6 | 38 | 2 |
| A2 (Sem 3-4) | 40 | 5-6 | 38 | 2 |
| B1 (Sem 5-6) | 40 | 5-7 | 38 | 2 |
| B2 (Sem 7-8) | 40 | 5-7 | 38 | 2 |
| C1 (Sem 9-10) | 40 | 6-8 | 38 | 2 |
| ... | ... | ... | ... | ... |
| **Total 12 sprints** | **480** | | **462** | **24** |

### 7.2 Cumulative Flow Projection

| Semana | SP Acumulados | % Completo | Milestone |
|---|---|---|---|
| 2 | 38 | 8% | |
| 4 | 76 | 16% | Sprint A Done ✓ |
| 6 | 114 | 25% | |
| 8 | 152 | 33% | Sprint B Done ✓ |
| 10 | 190 | 41% | |
| 12 | 228 | 49% | |
| 14 | 266 | 58% | |
| 16 | 304 | 66% | Sprint C Done ✓ |
| 18 | 342 | 74% | |
| 20 | 380 | 82% | |
| 22 | 418 | 90% | |
| 24 | 456 | 99% | Sprint D Done ✓ |
| 26+ | 462 | 100% | All Done ✓ |

### 7.3 Fechas Clave de Entrega

| Entrega | Contenido | Semana | Fecha Estimada |
|---|---|---|---|
| **Alpha Release** | Sandbox + Supervisor + CLI (P0 completo) | Semana 4 | 2026-08-04 |
| **Beta Release** | Generador de proyectos + VS Code + Git (P0+P1) | Semana 10 | 2026-09-15 |
| **RC Release** | Memory + Learning + Dashboard (P0+P1+60% P2) | Semana 18 | 2026-11-10 |
| **GA Release** | Platform completa (todos los sprints) | Semana 24 | 2026-12-22 |
| **Extended** | Items P3 remaining + backlog nuevo | Semana 30+ | 2027-Q1 |

### 7.4 Capacity Planning

| Rol | FTEs | SP/Sprint | Horas/Sprint |
|---|---|---|---|
| Senior Developer | 2 | 24 | 96h |
| Mid Developer | 2 | 16 | 64h |
| QA Engineer | 1 | - | 40h |
| Tech Lead | 0.5 | - | 20h |
| **Total Equipo** | **5.5** | **40 SP** | **220h/sprint** |

---

## 8. Gestión del Backlog

### 8.1 Ceremonias de Refinamiento

| Ceremonia | Frecuencia | Duración | Attendees |
|---|---|---|---|
| Backlog Refinement | Semanal | 1h | PO + Dev Team + QA |
| Sprint Planning | Quincenal | 2h | Todo el equipo |
| Sprint Review | Quincenal | 1h | Equipo + Stakeholders |
| Retrospective | Quincenal | 1h | Equipo técnico |
| Backlog Grooming | Mensual | 2h | PO + Stakeholders |

### 8.2 Criterios de Refinamiento

Para que un item pase de "New" a "Ready", debe cumplir:

- [ ] Descripción clara del "what" y "why"
- [ ] Criterios de aceptación definidos (Given/When/Then)
- [ ] Estimación por el equipo (Planning Poker)
- [ ] Dependencias identificadas
- [ ] Size definido (S/M/L/XL)
- [ ] Aceptado por Product Owner

### 8.3 Política de Cambios de Prioridad

| Situación | Acción |
|---|---|
| Nuevo item urgente | Se agrega como P0 si bloquea roadmap |
| Cambio de prioridad | Requiere aprobación de PO + stakeholder |
| Item removido | Se mueve a "Cancelled" con justificación |
| Split de item grande | Se divide en sub-items menores |
| Dependency change | Se actualiza gráfico de deps y se re-planifica |

### 8.4 Definition of Ready

```
┌─────────────────────────────────────────────────────────────────────┐
│                    DEFINITION OF READY                               │
├─────────────────────────────────────────────────────────────────────┤
│ □ Historia de usuario escrita en formato estándar                     │
│ □ Criterios de aceptación claros y testables                         │
│ □ Dependencias identificadas y resueltas si es posible                │
│ □ Estimación por equipo (SP + horas)                                 │
│ □ Tamaño ≤ 13 SP (si es mayor, dividir)                              │
│ □ Aceptado por Product Owner                                         │
│ □ Equipo entiende el "qué" y "por qué"                               │
│ □ No hay bloqueadores identificados                                   │
└─────────────────────────────────────────────────────────────────────┘
```

### 8.5 Definition of Done

```
┌─────────────────────────────────────────────────────────────────────┐
│                     DEFINITION OF DONE                                │
├─────────────────────────────────────────────────────────────────────┤
│ □ Código implementado y funcional                                     │
│ □ Tests unitarios passing (cobertura ≥ 80%)                          │
│ □ Tests de integración passing                                       │
│ □ Code review aprobado por ≥2 desarrolladores                         │
│ □ Sin vulnerabilidades críticas (security scan)                       │
│ □ Documentación técnica actualizada                                   │
│ □ Performance dentro de SLA                                          │
│ □ Demo funcional ante stakeholders                                   │
│ □ Desplegado en ambiente de testing                                  │
│ □ Aceptado por PO                                                    │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 9. Dependencias Visuales

### 9.1 Cadena Crítica del Proyecto

```
HERM-0001 ──── HERM-0002 ──── HERM-0003 ──── HERM-0004 ──── HERM-0007
   │                │                │                │
   ├── HERM-0005 ──┤                │                │
   │    │          │                │                │
   │    ├── HERM-0006               │                │
   │    │                           │                │
   │    └── HERM-0008               │                │
   │         │                      │                │
   │         ├── HERM-0009          │                │
   │         ├── HERM-0013          │                │
   │         └── HERM-0039          │                │
   │              │                 │                │
   │              └── HERM-0040     │                │
   │                    │           │                │
   │                    └── HERM-0041                │
   │                                                 │
   └── HERM-0021 ──── HERM-0006 (Plugin Arch)       │
                                                        │
   HERM-0016 ◄──── HERM-0006 (Memory)                  │
      │                                                  │
      ├── HERM-0017 (Learning)                          │
      │      │                                          │
      │      └── HERM-0028 (Error Recovery) ◄── HERM-0007
      │
      └── HERM-0018 (Knowledge Base)
```

### 9.2 Parallel Workstreams

```
Stream 1: Platform Core
HERM-0001 ── HERM-0003 ── HERM-0007
                     │
                     └── HERM-0004

Stream 2: CLI & Extensibility
HERM-0010 ── HERM-0021 ── HERM-0025
                     │
                     └── HERM-0008

Stream 3: Integration
HERM-0012 ── HERM-0022 ── HERM-0050

Stream 4: Intelligence
HERM-0016 ── HERM-0017 ── HERM-0018
                │
                └── HERM-0024 ── HERM-0028
```

---

## 10. Desglose por Épica

### 10.1 Épicas del Proyecto

El backlog está organizado en **8 épicas principales** que representan áreas funcionales del producto:

| Épica | Descripción | Items | SP Total | Sprint Principal |
|---|---|---|---|---|
| **E1: Safe Foundation** | Sandbox, supervisor, seguridad base | 7 | 68 SP | A |
| **E2: Core CLI** | Framework CLI y comandos básicos | 8 | 52 SP | A-B |
| **E3: Project Generation** | Wizard, templates, generadores | 12 | 88 SP | B-C |
| **E4: Intelligence** | Memory, learning, knowledge base | 6 | 58 SP | C |
| **E5: Developer Experience** | VS Code, context, suggestions | 10 | 64 SP | B-C |
| **E6: Integration Layer** | Git, CI/CD, providers, plugins | 15 | 78 SP | B-D |
| **E7: Enterprise Platform** | Marketplace, factories, evolution | 18 | 42 SP | D |
| **E8: Visibility** | Reports, dashboard, alerts, ROI | 12 | 20 SP | C-D |
| **Total** | | **88** | **462 SP** | |

### 10.2 Épica E1: Safe Foundation

**Objetivo:** Establecer la base segura sobre la cual opera todo el sistema.

| ID | Item | SP | Sprint | Status |
|---|---|---|---|---|
| HERM-0001 | Sandbox System Core | 13 | A | Planned |
| HERM-0002 | Command Validation Engine | 8 | A | Planned |
| HERM-0003 | Supervisor Process | 13 | A | Planned |
| HERM-0004 | Safe Execution Pipeline | 8 | A | Planned |
| HERM-0007 | Recovery System | 8 | A | Ready |
| HERM-0021 | Plugin Architecture | 13 | A | Planned |
| HERM-0025 | Multi-Provider AI | 8 | A | Planned |
| **Subtotal E1** | **7 items** | **68 SP** | | |

**Criterios de Éxito de E1:**
- 100% de comandos ejecutados en sandbox aislado
- 0 ejecuciones de comandos prohibidos
- Supervisor con uptime > 99.5%
- Recovery automático < 30 segundos
- Plugin system funcional con ≥3 plugins base

### 10.3 Épica E2: Core CLI

**Objetivo:** Proveer una interfaz de línea de comandos robusta y amigable.

| ID | Item | SP | Sprint | Status |
|---|---|---|---|---|
| HERM-0010 | Core CLI Framework | 8 | A | Ready |
| HERM-0005 | Context Manager | 8 | A | Planned |
| HERM-0006 | Session Persistence | 5 | A | Planned |
| HERM-0030 | Notification System | 3 | C | Planned |
| HERM-0048 | Logging Framework | 3 | C | New |
| HERM-0051 | Secrets Management | 5 | C | New |
| HERM-0052 | Config Management | 5 | C | New |
| HERM-0060 | i18n Support | 5 | Backlog | New |
| **Subtotal E2** | **8 items** | **52 SP** | | |

**Criterios de Éxito de E2:**
- CLI responde en < 100ms para comandos simples
- Autocompletado funcional en bash/zsh/PowerShell
- Help contextual para todos los comandos
- Configuración persistida entre sesiones
- Soporte multi-idioma en UI

### 10.4 Épica E3: Project Generation

**Objetivo:** Generar proyectos completos con un commando siguiendo mejores prácticas.

| ID | Item | SP | Sprint | Status |
|---|---|---|---|---|
| HERM-0008 | Project Template Engine V1 | 13 | B | Ready |
| HERM-0009 | Multi-Language Support | 8 | B | Ready |
| HERM-0013 | Project Wizard CLI | 8 | B | Planned |
| HERM-0031 | Enterprise Template Library v1 | 5 | C | New |
| HERM-0033 | Database Schema Generator | 8 | D | New |
| HERM-0039 | Microservice Scaffold | 8 | D | New |
| HERM-0040 | Domain Bounded Context Gen | 8 | D | New |
| HERM-0042 | GraphQL Schema Generator | 5 | D | New |
| HERM-0043 | REST API Generator | 5 | D | New |
| HERM-0044 | gRPC Service Generator | 8 | D | New |
| HERM-0047 | Auth Module Generator | 5 | D | New |
| HERM-0053 | Migration Tool Toolkit | 8 | Backlog | New |
| **Subtotal E3** | **12 items** | **88 SP** | | |

**Criterios de Éxito de E3:**
- ≥5 lenguajes soportados con templates completos
- Generación de proyecto en < 30 segundos
- 100% de proyectos generados compilan y pasan tests básicos
- Templates empresariales versionados y compartibles
- Generadores de patrones arquitectónicos (REST, GraphQL, gRPC, DDD)

### 10.5 Épica E4: Intelligence

**Objetivo:** Hacer que Hermes aprenda y mejore con el uso.

| ID | Item | SP | Sprint | Status |
|---|---|---|---|---|
| HERM-0016 | Memory System Core | 13 | C | Planned |
| HERM-0017 | Learning Engine | 13 | C | Planned |
| HERM-0018 | Knowledge Base | 8 | C | Planned |
| HERM-0024 | Code Review Assistant | 8 | C | Planned |
| HERM-0028 | Error Recovery Patterns | 5 | C | Planned |
| HERM-0083 | Knowledge Wiki | 8 | Backlog | New |
| **Subtotal E4** | **6 items** | **58 SP** | | |

**Criterios de Éxito de E4:**
- Memory system persiste contexto entre sesiones
- Learning engine identifica patrones en > 80% de casos comunes
- Knowledge base indexa y recupera documentos en < 2s
- Code review assistant sugiere mejoras relevantes en > 70% de casos
- Error recovery automática en errores comunes

### 10.6 Épica E5: Developer Experience

**Objetivo:** Integración fluida con herramientas de desarrollo.

| ID | Item | SP | Sprint | Status |
|---|---|---|---|---|
| HERM-0011 | VS Code Extension Base | 8 | B | Planned |
| HERM-0022 | CI/CD Integration | 5 | B | Planned |
| HERM-0023 | Linting & Formatting | 5 | B | Planned |
| HERM-0027 | Documentation Generator | 5 | C | Planned |
| HERM-0055 | Dependency Graph Visualizer | 5 | C | New |
| HERM-0056 | Code Complexity Analyzer | 5 | C | New |
| HERM-0057 | Test Coverage Reporter | 3 | C | New |
| HERM-0059 | Accessibility Checker | 5 | Backlog | New |
| HERM-0084 | Auto-Documentation Updates | 5 | Backlog | New |
| HERM-0085 | Changelog Generator | 3 | Backlog | New |
| **Subtotal E5** | **10 items** | **64 SP** | | |

**Criterios de Éxito de E5:**
- VS Code extension con ≥10 comandos funcionales
- CI/CD pipelines generados automáticamente y funcionales
- Linting y formatting configurados por defecto
- Documentación generada automáticamente
- Visualizaciones de dependencias y complejidad operativas

### 10.7 Épica E6: Integration Layer

**Objetivo:** Conectar Hermes con herramientas externas del ecosistema.

| ID | Item | SP | Sprint | Status |
|---|---|---|---|---|
| HERM-0012 | Git Integration Layer | 8 | B | Planned |
| HERM-0014 | Dependency Analyzer | 5 | B | Planned |
| HERM-0015 | Test Runner Integration | 5 | B | Planned |
| HERM-0026 | Security Scanner | 5 | B | Planned |
| HERM-0032 | Monorepo Support | 8 | C | New |
| HERM-0034 | API Contract Testing | 5 | C | New |
| HERM-0035 | Docker Compose Generator | 5 | D | New |
| HERM-0036 | Kubernetes Manifest Generator | 8 | D | New |
| HERM-0037 | Terraform Module Generator | 8 | D | New |
| HERM-0038 | Helm Chart Generator | 5 | D | New |
| HERM-0041 | Event-Driven Architecture | 8 | D | New |
| HERM-0045 | Message Queue Integration | 5 | D | New |
| HERM-0046 | Cache Strategy Generator | 5 | D | New |
| HERM-0050 | Cloud Deploy Templates | 8 | D | New |
| HERM-0054 | Legacy Code Analysis | 8 | Backlog | New |
| **Subtotal E6** | **15 items** | **78 SP** | | |

**Criterios de Éxito de E6:**
- Soporte multi-provider (GitHub, GitLab, Azure DevOps)
- Análisis de dependencias con detección de vulnerabilidades
- Test runners integrados para al menos 5 frameworks
- Scanners de seguridad básicos operativos
- Generadores de infraestructura (Docker, K8s, Terraform, Helm)
- Integración con sistemas de mensajería y caché

### 10.8 Épica E7: Enterprise Platform

**Objetivo:** Convertir Hermes en una plataforma autónoma empresarial.

| ID | Item | SP | Sprint | Status |
|---|---|---|---|---|
| HERM-0064 | Community Plugin Hub | 8 | D | New |
| HERM-0065 | Skill Marketplace Public | 8 | D | New |
| HERM-0066 | Agent Templates Gallery | 8 | D | New |
| HERM-0049 | Metrics Exporter | 5 | D | New |
| HERM-0058 | Performance Benchmark Suite | 5 | Backlog | New |
| HERM-0067 | Voice Interface | 13 | Backlog | New |
| HERM-0076 | REST API Public | 8 | Backlog | New |
| HERM-0077 | GraphQL API Public | 8 | Backlog | New |
| HERM-0082 | Team Collaboration | 8 | Backlog | New |
| HERM-0086 | Release Notes Generator | 2 | Backlog | New |
| HERM-0087 | Presentation Generator | 8 | Backlog | New |
| HERM-0088 | Video Tutorial Generator | 13 | Backlog | New |
| **Subtotal E7 (visible items)** | **12 items** | **42 SP** | | |

*Nota: Los items HERM-0095 a HERM-0100 del Sprint D (Agent Factory, Architecture Factory, etc.) suman aproximadamente 120 SP adicionales que no están detallados en este backlog pero están planificados en 05_SPRINT_D.md*

**Criterios de Éxito de E7:**
- Marketplace de plugins operacional
- Galería de templates de agentes
- APIs públicas documentadas (REST + GraphQL)
- Métricas exportables a sistemas de monitoring
- Herramientas de colaboración en equipo

### 10.9 Épica E8: Visibility

**Objetivo:** Proveer visibilidad completa del sistema y su valor.

| ID | Item | SP | Sprint | Status |
|---|---|---|---|---|
| HERM-0019 | Report Generator | 5 | B | Planned |
| HERM-0020 | Dashboard Web V1 | 8 | C | Planned |
| HERM-0029 | Performance Profiler | 5 | C | Planned |
| HERM-0061 | Dark Mode Dashboard | 2 | Backlog | New |
| HERM-0062 | Theme Customization | 3 | Backlog | New |
| HERM-0063 | Gamification Badges | 5 | Backlog | New |
| HERM-0068 | Chat Interface Web | 8 | Backlog | New |
| HERM-0069 | Mobile Companion App | 13 | Backlog | New |
| HERM-0070 | Slack Bot Integration | 5 | Backlog | New |
| HERM-0071 | Teams Bot Integration | 5 | Backlog | New |
| HERM-0072 | Discord Bot Integration | 5 | Backlog | New |
| HERM-0073 | Telegram Bot Integration | 5 | Backlog | New |
| **Subtotal E8** | **12 items** | **20 SP** | | |

*Nota: Los items de reportes y dashboard del Sprint C suman 20 SP. Los items adicionales de channels y UI suman aproximadamente 69 SP en backlog extendido.*

**Criterios de Éxito de E8:**
- Dashboard web funcional con métricas en tiempo real
- Reportes de actividad y ROI generables
- Integración con canales de comunicación (Slack, Teams, etc.)
- Interfaces alternativas (chat web, mobile, voice)
- Gamificación opcional para engagement

---

## 11. Riesgos del Backlog

### 11.1 Riesgos de Planificación

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Velocity menor a 40 SP/sprint | Media | Alto | Buffer de 10%, reducir scope P3 primero |
| Nuevas urgencias desplazan items | Alta | Medio | Reservar 10% capacity para ad-hoc |
| Deuda técnica acumula velocidad | Media | Alto | Sprint de estabilización entre C y D |
| Team burnout por ritmo sostenido | Media | Alto | Rotación de tareas, celebration points |
| Scope creep en Sprint D | Alta | Alto | Freeze de scope al inicio de cada iteración |
| Dependencies externas no disponibles | Media | Alto | Mock services y fallbacks documentados |
| Cambio en requisitos de stakeholders | Baja | Alto | Change request process formalizado |

### 11.2 Matriz de Valor vs. Esfuerzo

```
         Alto Esfuerzo
              │
   Quick Wins │    Big Bets
   (P0, P1)  │    (Sprint D)
              │
◄─────────────┼─────────────►
  Alto Valor   │   Bajo Valor
              │
   Fill-ins   │    Thankless
   (P2 early) │    Tasks (minimize)
              │
         Bajo Esfuerzo
```

**Interpretación:**
- **Quick Wins (Alto Valor, Bajo Esfuerzo):** P0 items - hacer primero
- **Big Bets (Alto Valor, Alto Esfuerzo):** Sprint D - inversión estratégica
- **Fill-ins (Bajo Valor, Bajo Esfuerzo):** P2 temprano - cuando hay tiempo
- **Thankless Tasks (Bajo Valor, Alto Esfuerzo):** Minimizar o eliminar

### 11.3 Matriz de Riesgo vs. Retorno

```
         Alto Riesgo
              │
   Avoid      │    Manage Actively
   (low ROR,  │    (high ROR,
    high risk)│     high risk)
              │
◄─────────────┼─────────────►
  Bajo Retorno │   Alto Retorno
              │
   Accept     │    Exploit
   (low ROR,  │    (high ROR,
    low risk) │     low risk)
              │
         Bajo Riesgo
```

**Items en cada cuadrante:**
- **Manage Actively:** HERM-0001, HERM-0003, HERM-0009, HERM-0016, HERM-0025
- **Exploit:** HERM-0010, HERM-0030, HERM-0057, HERM-0085, HERM-0086
- **Accept:** HERM-0061, HERM-0079, HERM-0080
- **Avoid:** HERM-0069 (mobile app - muy riesgoso para retorno incierto)

---

## 12. Governance del Backlog

### 12.1 Roles y Responsabilidades

| Rol | Responsabilidad en Backlog |
|---|---|
| **Product Owner** | Priorización final, aceptación de items, stakeholder management |
| **Scrum Master** | Facilitar refinement, remover impedimentos, tracking velocity |
| **Tech Lead** | Validación técnica, estimación, identificación de dependencias |
| **Development Team** | Estimación, ejecución, feedback de refinamiento |
| **QA Lead** | Definición de criterios de aceptación, testing strategy |
| **Stakeholders** | Input de negocio, validación de valor, priorización estratégica |

### 12.2 Decisiones de Priorización

**Framework de Decisión: WSJF (Weighted Shortest Job First)**

```
WSJF Score = Cost of Delay / Job Size

Donnde:
- Cost of Delay = Business Value + Time Criticality + Risk Reduction
- Job Size = Story Points estimados
```

**Ejemplo de cálculo:**

| Item | Business Value (1-10) | Time Criticality (1-10) | Risk Reduction (1-10) | Cost of Delay | Job Size (SP) | WSJF Score |
|---|---|---|---|---|---|---|
| HERM-0001 (Sandbox) | 10 | 10 | 8 | 28 | 13 | 2.15 |
| HERM-0008 (Template Engine) | 9 | 8 | 5 | 22 | 13 | 1.69 |
| HERM-0016 (Memory System) | 8 | 6 | 7 | 21 | 13 | 1.62 |
| HERM-0067 (Voice Interface) | 4 | 2 | 3 | 9 | 13 | 0.69 |

**Regla:** Items con WSJF > 1.5 van a P0/P1. Items 1.0-1.5 van a P2. Items < 1.0 van a P3 o backlog extendido.

### 12.3 Change Control

**Proceso para cambios al backlog:**

1. **Solicitud de cambio:** Cualquier stakeholder puede solicitar cambio via formulario
2. **Impact analysis:** PO + Tech Lead evalúan impacto en timeline, costos, dependencias
3. **Decisión:** PO decide aceptar/rechazar/modificar basado en análisis
4. **Comunicación:** Equipo notificado si cambio es aceptado
5. **Actualización:** Backlog actualizado con nueva prioridad/scope
6. **Tracking:** Cambio documentado en changelog de decisiones

**Criterios para aprobación de cambio:**
- Cambio alineado con objetivos estratégicos
- Impacto en timeline aceptable (≤1 sprint de desvío)
- ROI positivo o requisito regulatorio
- Stakeholder affected de acuerdo con trade-offs

---

## Navegación Inferior

| Documento Anterior | Índice General | Documento Siguiente |
|---|---|---|
| [05_SPRINT_D.md](05_SPRINT_D.md) | [04_ROADMAP.md](04_ROADMAP.md) | [08_RISK_REGISTER.md](08_RISK_REGISTER.md) |

---

*Documento generado como parte del roadmap HERMES Enterprise. Status: DRAFT. Última actualización: 2026-07-07.*
