---
# ============================================================================
# HERMES-ENTERPRISE
# Sprint B: Professional Project Generator
# ============================================================================
titulo: "Sprint B — Generador Profesional de Proyectos"
proyecto: "HERMES-ENTERPRISE"
version_doc: "1.0.0"
estado: "Propuesta de Diseño"
autor: "Fredy Alejandro Sarmiento Torres"
fecha_creacion: "2026-07-07"
sprint_id: "SB-001"
duracion_semanas: 6
story_points_totales: 45
equipo: "3-5 Ingenieros Senior"
dependencias: "02_SPRINT_A.md (Safe Sandbox)"
bloquea: "04_SPRINT_C.md"
clasificacion: "Diseño Estratégico"
criterio_exito: "Hermes puede generar proyectos profesionales completos con un solo comando"
# ============================================================================
---

# Sprint B — Generador Profesional de Proyectos

## Navegación

| Documento | Estado |
|---|---|
| [← Sprint A: Safe Sandbox](02_SPRINT_A.md) | Prerequisito |
| [← ROADMAP_EVOLUTIVO_INCREMENTAL.md](../ROADMAP_EVOLUTIVO_INCREMENTAL.md) | Línea base |
| [→ Sprint C: Memory & Learning](04_SPRINT_C.md) | Siguiente sprint |

---

## 1. Visión General

### 1.1 Objetivo del Sprint

Transformar Hermes en un generador profesional de proyectos con capacidad de crear estructuras completas, configurables y listas para producción en múltiples lenguajes y frameworks.

### 1.2 Alcance

**Incluye:** 16 motores/generadores especializados.
**Fuera de alcance:** IDE custom, deployment en cloud, compilación de código.

### 1.3 Motivación

Actualmente, crear un nuevo proyecto profesional requiere conocimientos en: estructura de directorios, CI/CD, Docker, testing, documentación, licensiamiento. Hermes debe automatizar estas decisiones siguiendo best practices.

### 1.4 Métricas de éxito

| Métrica | Objetivo |
|---|---|
| Proyectos generados correctamente | 100% funcional out-of-the-box |
| Lenguajes soportados (mínimo) | 6 (PS, Python, Node, Go, Rust, .NET) |
| Frameworks soportados (mínimo) | 6 (ASP.NET, FastAPI, Express, Gin, Actix, etc.) |
| Tiempo de generación de proyecto | < 2 minutos |
| Calidad de DeveloperContext generado | 100% coherente |

---

## 2. Arquitectura del Generador

```
┌──────────────────────────────────────────────────────────────┐
│                  PROJECT GENERATOR CORE                      │
│            (Orchestestrador Principal)                        │
└────────────────────────────┬─────────────────────────────────┘
                             │
        ┌────────────────────┼────────────────────┐
        │                    │                    │
        ▼                    ▼                    ▼
┌──────────────┐    ┌────────────────┐    ┌──────────────┐
│ TEMPLATE     │    │ BOOTSTRAP      │    │ VALIDATION   │
│ ENGINE       │    │ ENGINE         │    │ ENGINE       │
└──────┬───────┘    └───────┬────────┘    └──────────────┘
       │                    │
       ▼                    ▼
┌──────────────────────────────────────────────┐
│          LANGUAGE & FRAMEWORK PACKS          │
│  PS │ Python │ Node │ Go │ Rust │ .NET Core  │
│     │ FastAPI│Express│ Gin│Actix│ ASP.NET    │
└──────────────────────┬───────────────────────┘
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
┌────────────┐  ┌────────────┐  ┌────────────┐
│ VS Code    │  │ Git Gen    │  │ Docker Gen │
│ Generator  │  │            │  │            │
└────────────┘  └────────────┘  └────────────┘
┌────────────┐  ┌────────────┐  ┌────────────┐
│ README     │  │ License    │  │ CI/CD Gen  │
│ Generator  │  │ Generator  │  │            │
└────────────┘  └────────────┘  └────────────┘
┌────────────┐  ┌────────────┐  ┌────────────┐
│ Arch Gen   │  │ DevContext │  │ Roadmap    │
│ (C4)       │  │ Generator  │  │ Generator  │
└────────────┘  └────────────┘  └────────────┘
┌────────────┐  ┌────────────┐
│ Accept Gen │  │ Valid Gen  │
└────────────┘  └────────────┘
```

### 2.1 Flujo de Generación

```
Usuario: New-HermesEnterpriseProject -Name "MiAPI" -Language Go -Framework Gin -WithDocker -WithCI
    │
    ▼
[1. Parsear parámetros + validar prerequisitos]
    │
    ▼
[2. Crear estructura de directorios base (bootstrap)]
    │
    ▼
[3. Aplicar Language Pack específico]
    │
    ▼
[4. Aplicar Framework Pack específico]
    │
    ▼
[5. Generar VS Code workspace + settings]
    │
    ▼
[6. Inicializar Git (init, branch, first commit)]
    │
    ▼
[7. Generar Dockerfile + compose]
    │
    ▼
[8. Generar README + LICENSE]
    │
    ▼
[9. Generar CI/CD pipelines]
    │
    ▼
[10. Generar diagramas de arquitectura (C4)]
    │
    ▼
[11. Generar DeveloperContext completo]
    │
    ▼
[12. Generar acceptance tests + validation]
    │
    ▼
[13. Generar roadmap evolutivo del proyecto]
    │
    ▼
[14. Validar coherencia global]
    │
    ▼
[15. Reporte final al usuario]
```

---

## 3. Épicas

### SB-E1: Core del Generador (8 SP / 16h)

Motor central que orquesta todos los demás. Recibe parámetros, valida, y ejecuta la cadena de generación.

### SB-E2: Template Engine (6 SP / 12h)

Motor de plantillas que procesa templates con tokens {{variable}}, condicionales, loops. Base para todos los generadores.

### SB-E3: Language Packs (8 SP / 16h)

Packs por lenguaje: PowerShell, Python, Node.js, Go, Rust, .NET. Cada pack define estructura, convenciones, configuraciones.

### SB-E4: Framework Packs (6 SP / 12h)

Packs por framework: ASP.NET Core, FastAPI, Express, Gin, Actix, etc. Cada pack añade estructura específica del framework.

### SB-E5: Infraestructura Generators (8 SP / 16h)

VS Code, Git, Docker, CI/CD, Bootstrap engine.

### SB-E6: Documentation Generators (5 SP / 10h)

README, LICENSE, Architecture (C4), DeveloperContext.

### SB-E7: Quality Generators (4 SP / 8h)

Acceptance tests, Validation engine, Roadmap generator.

**Total: 45 SP / 90h**

---

## 4. Historias de Usuario

### SB-US-01: Generador Core
**Como** desarrollador, **quiero** un comando para crear un proyecto profesional **para** no configurar manualmente la estructura.
**Aceptación:**
1. `New-HermesEnterpriseProject -Name X -Language Y` crea proyecto válido
2. Parámetros opcionales: `-Framework`, `-WithDocker`, `-WithCI`, `-WithIDE`
3. Falla limpio si prerequisitos no existen (Go no instalado)
4. Genera reporte final con lista de archivos creados

**SP: 5 / Horas: 10h / Prioridad: Crítica**

---

### SB-US-02: Template Engine
**Como** maintainer, **quiero** un motor de plantillas reutilizable **para** que los generadores usen el mismo sistema.
**Aceptación:**
1. Soporta tokens `{{nombre}}`, condicionales `{{#si condicion}}...{{/si}}`, loops `{{#cada items}}`
2. Templates almacenados en `/templates/` con estructura predecible
3. Soporta includes: `{{> partial}}`
4. Permite templates por lenguaje/framework en directorios específicos

**SP: 6 / Horas: 12h / Prioridad: Crítica**

---

### SB-US-03: Language Pack — PowerShell
**Como** ingeniero .NET/Windows, **quiero** un pack de PowerShell **para** generar módulos profesionales.
**Aceptación:**
1. Estructura: `/src/`, `/tests/`, `/docs/`, `/config/`, `/*.psd1`, `/*.psm1`
2. Incluye `Build.ps1`, `Invoke-Tests.ps1`, `README.md`
3. Pester tests boilerplate
4. Convención de nombres: objetos en español, descriptivos

**SP: 1.5 / Horas: 3h / Prioridad: Alta**

---

### SB-US-04: Language Pack — Python
**Como** desarrollador Python, **quiero** generar estructura profesional **para** seguir PEP standards.
**Aceptación:**
1. Estructura: `/src/<pkg>/`, `/tests/`, `/docs/`, `pyproject.toml`, `requirements-dev.txt`
2. `__init__.py`, `README.md`, `LICENSE` placeholder
3. pytest + coverage config preconfigurado
4. Soporta pyenv/venv detection

**SP: 1.5 / Horas: 3h**

---

### SB-US-05: Language Pack — Node.js / Go / Rust / .NET
**Como** desarrollador en otros lenguajes, **quiero** estructura profesional para cada uno.
**Aceptación:** Cada pack genera estructura idiomática con tooling moderno (npm/yarn, go modules, cargo, dotnet).

**SP: 5 / Horas: 10h** (combinado para los 4 lenguajes restantes)

---

### SB-US-06: Framework Packs
**Como** desarrollador de APIs, **quiero** que el generador agregue estructura del framework elegido.
**Aceptación:**
1. ASP.NET Core: Controllers, Services, DI, Program.cs con minimal API option
2. FastAPI: Routers, Services, Pydantic models, Alembic setup
3. Express: Routes, Controllers, Services, middleware patterns
4. Gin: Handlers, Services, GORM setup
5. Actix: Handlers, Actors, actix-web routes
6. Each pack is additive to its language pack

**SP: 6 / Horas: 12h**

---

### SB-US-07: VS Code Generator
**Como** desarrollador, **quiero** configuración VS Code lista **para** empezar a desarrollar inmediatamente.
**Aceptación:**
1. Genera `<name>.code-workspace` con folders, tasks, launch
2. `settings.json` con extensiones recomendadas por lenguaje
3. `tasks.json` con build/test/lint tasks
4. `launch.json` con debug config por lenguaje
5. Extensions recommendations list

**SP: 3 / Horas: 6h / Prioridad: Alta**

---

### SB-US-08: Git Generator
**Como** desarrollador, **quiero** repo git inicializado **para** empezar con best practices.
**Aceptación:**
1. `git init` con main branch
2. `.gitignore` específico por lenguaje (conocido)
3. `.gitattributes` configurado
4. First commit con mensaje descriptivo
5. Opcional: `-RemoteUrl https://github.com/...` configura origin

**SP: 2 / Horas: 4h**

---

### SB-US-09: Docker Generator
**Como** DevOps, **quiero** Dockerfile profesional **para** deployear sin manual setup.
**Aceptación:**
1. Dockerfile multi-stage por lenguaje (alpine, slim, etc.)
2. `.dockerignore` completo
3. `docker-compose.yml` con dev overrides
4. `docker-compose.prod.yml` para producción
5. Best practices: non-root user, layer caching, minimal image size

**SP: 3 / Horas: 6h**

---

### SB-US-10: README Generator
**Como** maintainer, **quiero** README profesional **para** que el proyecto sea entendible.
**Aceptación:**
1. Secciones: Header, Badges, Descripción, Instalación, Uso, Arquitectura, Contribución, Licencia
2. Contenido específico por tipo de proyecto (API, CLI, librería)
3.placeholders para screenshots, ejemplos, etc.
4. Genera TOC automático si > 5 secciones

**SP: 2 / Horas: 4h**

---

### SB-US-11: LICENSE Generator
**Como** maintainer, **quiero** elegir licencia apropiada **para** proteger mi código correctamente.
**Aceptación:**
1. Soporta MIT, Apache 2.0, GPL-3.0, BSD-3, ISC
2. Parametro `-License MIT -Author "Nombre"`
3. Inserta año y nombre automáticamente
4. Genera archivo `LICENSE` en raíz

**SP: 1 / Horas: 2h**

---

### SB-US-12: CI/CD Generator
**Como** DevOps, **quiero** pipelines CI/CD **para** automatizar calidad desde el día uno.
**Aceptación:**
1. GitHub Actions: `build-test.yml` con matrix por OS
2. GitLab CI: `.gitlab-ci.yml` equivalente
3. Azure DevOps: `azure-pipelines.yml`
4. Parámetro `-CITool github` selecciona cuál generar
5. Steps: checkout, install deps, lint, test, build, artifact

**SP: 3 / Horas: 6h**

---

### SB-US-13: Architecture Generator (C4)
**Como** architect, **quiero** diagramas C4 generados **para** documentación visual inmediata.
**Aceptación:**
1. Genera System Context, Container, Component diagrams
2. Formato: Mermaid + PlantUML (dual)
3. Detecta automáticamente capas por framework elegido
4. Diagramas editables y regenerables con `Update-HermesProjectArchitecture`

**SP: 3 / Horas: 6h**

---

### SB-US-14: DeveloperContext Generator
**Como** desarrollador, **quiero** DeveloperContext completo **para** que cualquier AI entienda el proyecto.
**Aceptación:**
1. Genera `DeveloperContext.md` con: propósito, arquitectura, convenciones, comandos, estructura
2. Inyecta información específica del lenguaje/framework
3. Incluye decisiones de diseño tomadas
4. Es el documento maestro para AI assistants

**SP: 3 / Horas: 6h**

---

### SB-US-15: Acceptance & Validation Generators
**Como** QA, **quiero** tests de aceptación pre-generados **para** validar el proyecto funcional.
**Aceptación:**
1. Aceptación: smoke tests por lenguaje (API health, endpoint response)
2. Validación: script que corre acceptance + lint + tests unitarios
3. `Invoke-HermesProjectValidation` genera reporte

**SP: 4 / Horas: 8h**

---

### SB-US-16: Roadmap Generator
**Como** maintainer, **quiero** roadmap evolutivo del nuevo proyecto **para** planear iterations futuras.
**Aceptación:**
1. Genera `ROADMAP.md` con: Fase 1 (MVP), Fase 2 (Hardening), Fase 3 (Scale)
2. Fase sugerida basada en tipo de proyecto
3. Estimaciones por fase (SP, semanas)
4. Editable y extensible por el usuario

**SP: 2 / Horas: 4h**

---

## 5. Tareas Detalladas

### SB-E1: Core del Generador (5 SP + 3 SP aux = 8 SP)

| ID | Tarea | SP | Horas | Dependencias |
|---|---|---|---|---|
| SB-T1.1 | Diseño de arquitectura del generador | 2 | 4h | - |
| SB-T1.2 | `New-HermesEnterpriseProject` función principal | 3 | 6h | T1.1 |
| SB-T1.3 | Pipeline de orquestación (15 pasos) | 2 | 4h | T1.2 |
| SB-T1.4 | Integración con SnapshotEngine (Sprint A) | 1 | 2h | T1.3, SA |

**Total: 8 SP / 16h**

### SB-E2: Template Engine (6 SP / 12h)

| ID | Tarea | SP | Horas | Dependencias |
|---|---|---|---|---|
| SB-T2.1 | Diseñar sintaxis de tokens | 1 | 2h | - |
| SB-T2.2 | Motor de tokens básicos ({{var}}) | 2 | 4h | T2.1 |
| SB-T2.3 | Condicionales y loops | 2 | 4h | T2.2 |
| SB-T2.4 | Includes/partials + cache | 1 | 2h | T2.3 |

**Total: 6 SP / 12h**

### SB-E3: Language Packs (8 SP / 16h)

| ID | Tarea | SP | Horas | Dependencias |
|---|---|---|---|---|
| SB-T3.1 | Pack: PowerShell | 1.5 | 3h | T2.2 |
| SB-T3.2 | Pack: Python | 1.5 | 3h | T2.2 |
| SB-T3.3 | Pack: Node.js | 1 | 2h | T2.2 |
| SB-T3.4 | Pack: Go | 1 | 2h | T2.2 |
| SB-T3.5 | Pack: Rust | 1.5 | 3h | T2.2 |
| SB-T3.6 | Pack: .NET Core | 1.5 | 3h | T2.2 |

**Total: 8 SP / 16h**

### SB-E4: Framework Packs (6 SP / 12h)

| ID | Tarea | SP | Horas | Dependencias |
|---|---|---|---|---|
| SB-T4.1 | Pack: ASP.NET Core | 1 | 2h | T3.6 |
| SB-T4.2 | Pack: FastAPI | 1 | 2h | T3.2 |
| SB-T4.3 | Pack: Express.js | 1 | 2h | T3.3 |
| SB-T4.4 | Pack: Gin (Go) | 1 | 2h | T3.4 |
| SB-T4.5 | Pack: Actix (Rust) | 1 | 2h | T3.5 |
| SB-T4.6 | Pack: Minimal API (.NET) | 1 | 2h | T3.6 |

**Total: 6 SP / 12h**

### SB-E5: Infrastructure Generators (8 SP / 16h)

| ID | Tarea | SP | Horas | Dependencias |
|---|---|---|---|---|
| SB-T5.1 | Bootstrap Engine (dir structure) | 2 | 4h | T1.2 |
| SB-T5.2 | VS Code Generator (workspace, settings) | 3 | 6h | T2.2 |
| SB-T5.3 | Git Generator (init, gitignore, first commit) | 2 | 4h | T1.2 |
| SB-T5.4 | Docker Generator (multi-stage, compose) | 3 | 6h | T3.1-T3.6 |
| SB-T5.5 | CI/CD Generator (GH Actions, GitLab, ADO) | 3 | 6h | T5.4 |

**Total: 13 SP → Consolidado a: 8 SP / 16h**

### SB-E6: Documentation Generators (5 SP / 10h)

| ID | Tarea | SP | Horas | Dependencias |
|---|---|---|---|---|
| SB-T6.1 | README Generator | 2 | 4h | T2.2 |
| SB-T6.2 | LICENSE Generator | 1 | 2h | T2.2 |
| SB-T6.3 | Architecture Generator (C4 Mermaid) | 3 | 6h | T2.2, T3.1 |
| SB-T6.4 | DeveloperContext Generator | 3 | 6h | All generators |

**Total: 9 SP → Consolidado a: 5 SP / 10h**

### SB-E7: Quality Generators (4 SP / 8h)

| ID | Tarea | SP | Horas | Dependencias |
|---|---|---|---|---|
| SB-T7.1 | Acceptance Generator (smoke tests) | 2 | 4h | T3.x |
| SB-T7.2 | Validation Generator (run all) | 2 | 4h | T7.1 |
| SB-T7.3 | Roadmap Generator | 1 | 2h | T6.4 |

**Total: 4 SP / 8h** *(T7.3 fue reducido de 2 a 1 SP)*

---

## 6. Resumen de Story Points

| Épica | SP | Horas | % |
|---|---:|---:|---:|
| SB-E1: Core Generator | 8 | 16h | 18% |
| SB-E2: Template Engine | 6 | 12h | 13% |
| SB-E3: Language Packs | 8 | 16h | 18% |
| SB-E4: Framework Packs | 6 | 12h | 13% |
| SB-E5: Infrastructure Generators | 8 | 16h | 18% |
| SB-E6: Documentation Generators | 5 | 10h | 11% |
| SB-E7: Quality Generators | 4 | 8h | 9% |
| **TOTAL** | **45** | **90h** | **100%** |

---

## 7. Cronograma (6 Semanas)

### Semana 1-2: Foundation
- Diseño Template Engine (T2.1, T2.2, T2.3, T2.4)
- Core Generator (T1.1, T1.2)
- Bootstrap Engine (T5.1)
- Git Generator (T5.3)

### Semana 3: Language & Framework Packs
- Todos los Language Packs (T3.1-T3.6)
- Framework Packs básicos (T4.1-T4.3)

### Semana 4: Infrastructure
- VS Code Generator (T5.2)
- Docker Generator (T5.4)
- CI/CD Generator (T5.5)
- Framework Packs restantes (T4.4-T4.6)

### Semana 5: Documentation & Quality
- README/License/Architecture/DevContext (T6.1-T6.4)
- Acceptance/Validation (T7.1-T7.2)
- Roadmap Generator (T7.3)
- Integración con SnapshotEngine (T1.4)

### Semana 6: Integration & Polish
- Pruebas end-to-end de toda la cadena
- Performance tuning
- Corriger bugs
- Documentación completa
- Demo + Sprint Review

---

## 8. Dependencias

| Tipo | Dependencia | Estado |
|---|---|---|
| Externa | Sprint A (Safe Sandbox) para recovery durante generación | Prerequisito |
| Externa | PowerShell 7.4+ | Existente |
| Externa | Git, Docker CLI (opcional) | Verificar en runtime |
| Interna | Template Engine es prerequisito de casi todo | Crítico path |
| Interna | Core Generator bloquea todos los demás generators | Crítico path |

**Critical Path:** T1.1 → T1.2 → T2.1-T2.4 → T3.x/T4.x → T5.x → T6.x → T7.x

---

## 9. Definición de Done

### Por Historia
- ✅ Feature implementada y funcional
- ✅ Templates validados con datos reales
- ✅ Pruebas unitarias pasan
- ✅ Documentación incluida

### Del Sprint
- ✅ `New-HermesEnterpriseProject` genera proyecto completo de 6 lenguajes
- ✅ Cada lenguaje tiene al menos 1 framework específico
- ✅ Proyecto generado compila/corre sin errores
- ✅ DeveloperContext generado es 100% coherente
- ✅ Docker build funciona si se solicitó
- ✅ CI/CD pipeline ejecuta sin errores (prueba real en GH)
- ✅ Suite de tests de aceptación del Sprint pasa 100%
- ✅ Documentación completa
- ✅ CHANGELOG + SRS actualizados
- ✅ Commit atómico con Conventional Commit

---

## 10. Riesgos

| Riesgo | Prob. | Impacto | Mitigación |
|---|---|---|---|
| Templates desactualizados por versiones nuevas | Alta | Medio | Versionado en templates + mecanismo de actualización |
| Sobrecarga de opciones en CLI | Media | Bajo | Defaults sensados + `--help` detallado |
| Lenguajes evolucionan rápido | Alta | Medio | Language Packs como módulos independientes |
| Performance con proyectos grandes | Media | Medio | Async + progress reporting |
| CI/CD templates no funcionan en todos los casos | Media | Alto | Pruebas en repos reales (verificación semanal) |

---

## 11. Decisiones de Diseño

### D-SB-01: Formato de Templates
**Decisión:** Sistema custom ligero (no Handlebars/Mustache dependencies)
**Justificación:** HERMES es PowerShell puro, sin dependencias externas de Node.js

### D-SB-02: Estructura de Language Packs
**Decisión:** Cada pack = directorio `/templates/<lang>/` con archivos template
**Justificación:** Extensibilidad fácil, usuario puede agregar su propio pack

### D-SB-03: Recovery durante generación
**Decisión:** Snapshot tras cada paso del pipeline (usa Sprint A)
**Justificación:** Si un paso falla a mitad, se puede reanudar sin perder trabajo

---

## 12. Equipo

| Rol | Responsabilidad | Carga |
|---|---|---|
| Chief Architect | Diseño Template Engine, arquitectura | 30% |
| Enterprise Engineer | Core Generator + integración | 100% |
| Senior Eng (x2) | Language/Framework Packs | 100% + 75% |
| QA Lead | Suite de tests | 50% |
| DevOps Lead | CI/CD templates, Docker | 50% |
| Product Owner | Priorización | 15% |

---

## 13. Criterios de Éxito

- [ ] Proyecto de cada lenguaje se genera en < 2 min
- [ ] Proyecto generado pasa lint/tests sin intervención manual
- [ ] DeveloperContext es coherente con la estructura real
- [ ] Zero false positives en validation engine
- [ ] Todos los generators son extensibles sin modificar core
- [ ] Tests de regresión del Sprint pasan 100%

---

→ Continuar con [Sprint C: Memory & Learning](04_SPRINT_C.md)

---

*Documento de Diseño — Sprint B: Generador Profesional de Proyectos*
*Versión 1.0.0 — 2026-07-07*
