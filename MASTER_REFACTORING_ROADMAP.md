# MASTER REFACTORING ROADMAP
## Hermes Enterprise — RC13

**Documento:** MASTER_REFACTORING_ROADMAP.md  
**Versión:** 1.0  
**Autor:** Principal Software Architect  
**Audiencia:** Architecture Review Board  
**Fuente de verdad:** AUDIT_REPORT.md (2026-07-29)

---

## Tabla de Contenidos

1. [Estado Actual](#1-estado-actual)
2. [Inventario Completo de Problemas](#2-inventario-completo-de-problemas)
3. [Análisis por Categoría](#3-análisis-por-categoría)
4. [Matriz de Priorización Completada](#4-matriz-de-priorización-completada)
5. [Catálogo Detallado de Mejoras](#5-catálogo-detallado-de-mejoras)
6. [DAG de Dependencias](#6-dag-de-dependencias)
7. [Análisis de Riesgo por Mejora](#7-análisis-de-riesgo-por-mejora)
8. [Roadmap por Fases](#8-roadmap-por-fases)
9. [Matriz Impacto vs Esfuerzo](#9-matriz-impacto-vs-esfuerzo)
10. [Matriz Riesgo vs Beneficio](#10-matriz-riesgo-vs-beneficio)
11. [Top 20 Tareas Inmediatas](#11-top-20-tareas-inmediatas)
12. [Criterios de Éxito por Fase](#12-criterios-de-éxito-por-fase)
13. [Estrategia de Rollback Global](#13-estrategia-de-rollback-global)

---

## 1. Estado Actual

Hermes Enterprise es un sistema de bootstrap y orquestación de proyectos PowerShell con dos kernels incompletos y paralelos, ~30 módulos de los cuales solo ~8 tienen implementación real, y 0% de cobertura de pruebas.

### Métricas clave

| Métrica | Valor |
|---|---|
| Líneas de código (estimado) | ~12,000 |
| Archivos PowerShell | ~60 |
| Archivos de configuración | 5+ |
| Kernels incompletos | 2 (funcional + clases) |
| Módulos con implementación real | ~8 |
| Módulos stub/vacíos | ~22 |
| Sandboxes de prueba | 10+ |
| Pruebas unitarias ejecutables | 0 |
| CI/CD | 0 |
| Directorios vacíos (solo .gitkeep) | 8 |
| Código muerto confirmado | 13+ archivos |

### Decisión arquitectónica fundamental

**El kernel funcional (`Kernel.ps1` + funciones helper) es el que debe sobrevivir.**

Justificación:
- `Kernel.ps1` tiene 103 líneas con lógica ejecutable real que se integra con `motor/bootstrap/`
- `KernelHost.ps1` (clases) tiene 35 líneas con paths hardcoded (`D:/HERMES-ENTERPRISE/...`) y no está referenciado por ningún entrypoint
- El kernel funcional ya tiene dependencias reales: ConfigurationManager, Logger, EventBus, Runtime
- Reescribir a clases implicaría rehacer toda la integración con bootstrap sin beneficio tangible

---

## 2. Inventario Completo de Problemas

### P-001: Dos kernels paralelos incompletos
- **Archivos:** `motor/kernel/Kernel.ps1` vs `motor/kernel/Core/KernelHost.ps1`
- **Impacto arquitectónico:** Crítico — dos implementaciones para el mismo rol, ninguna completa
- **Impacto operativo:** Alto — cualquier cambio debe considerar ambos
- **Deuda técnica:** Alta — duplicidad + código divergente
- **Complejidad:** Alta
- **Coste de mantenimiento:** Alto — doble esfuerzo
- **Frecuencia de uso:** Media (Kernel.ps1 se referencia, KernelHost.ps1 no)
- **Riesgo futuro:** Alto — puede llevar a inconsistencias

### P-002: Sin pruebas automatizadas
- **Impacto arquitectónico:** Alto — no hay red de seguridad para refactorizar
- **Impacto operativo:** Alto — cualquier cambio es riesgoso
- **Deuda técnica:** Crítica
- **Complejidad:** Media
- **Coste de mantenimiento:** Alto — cada bug se descubre en producción
- **Frecuencia de uso:** N/A
- **Riesgo futuro:** Crítico

### P-003: EventBus duplicado (funcional vs clases)
- **Archivos:** `motor/eventos/EventBus.ps1` (64 líneas) vs `motor/kernel/Core/EventBus.ps1` (14 líneas)
- **Impacto arquitectónico:** Alto — compiten por el mismo rol
- **Deuda técnica:** Media
- **Complejidad:** Baja
- **Coste de mantenimiento:** Bajo
- **Riesgo futuro:** Medio — confusión al extender

### P-004: DI triplicado (DependencyInjection + ServiceContainer + ServiceLocator)
- **Archivos:** 3 implementaciones para un patrón de 10 líneas
- **Impacto arquitectónico:** Medio
- **Deuda técnica:** Media
- **Complejidad:** Baja
- **Coste de mantenimiento:** Bajo
- **Riesgo futuro:** Bajo

### P-005: Módulos Git duplicados
- **Archivos:** `motor/bootstrap/Git.ps1` (10 líneas) + `motor/bootstrap/functions/Git.ps1` (35 líneas)
- **Impacto arquitectónico:** Bajo
- **Deuda técnica:** Baja
- **Complejidad:** Baja
- **Coste de mantenimiento:** Bajo
- **Riesgo futuro:** Bajo

### P-006: Observabilidad duplicada
- **Archivos:** `tools/Observabilidad.ps1` (26 líneas, vestigial) vs `motor/tools/Observabilidad.ps1` (68 líneas, activa)
- **Impacto arquitectónico:** Bajo
- **Deuda técnica:** Baja
- **Complejidad:** Baja
- **Riesgo futuro:** Bajo

### P-007: 5+ archivos de configuración compitiendo
- **Archivos:** `bootstrap.json`, `bootstrap.yaml`, `Hermes.config.json`, `configuracion/bootstrap.enterprise.json`, `configuracion/kernel.enterprise.json`
- **Impacto arquitectónico:** Alto — valores inconsistentes entre archivos
- **Impacto operativo:** Medio — confusión sobre cuál es la fuente de verdad
- **Deuda técnica:** Alta
- **Complejidad:** Media
- **Coste de mantenimiento:** Medio
- **Riesgo futuro:** Medio

### P-008: Código muerto (13+ archivos)
- **Archivos:** `tools/LoadConfiguration.ps1`, `tools/GenerateIntegrityReport.ps1`, `hello.ps1`, `Patch-Hermes-AzureTrace.ps1`, `tools/EnterprisePipeline.ps1`, `builders/` (3 archivos), `motor/bootstrap/GitHub.ps1`, etc.
- **Impacto arquitectónico:** Medio — ruido que dificulta entender la arquitectura real
- **Deuda técnica:** Media
- **Complejidad:** Baja
- **Coste de mantenimiento:** Bajo (archivos pequeños)
- **Riesgo futuro:** Bajo

### P-009: 8 directorios vacíos con .gitkeep
- **Impacto arquitectónico:** Bajo
- **Deuda técnica:** Baja
- **Complejidad:** Mínima
- **Riesgo futuro:** Nulo

### P-010: 10+ sandboxes sin limpiar
- **Archivos:** `sandbox/ProyectoTest*`, `sandbox/ProyectoPrueba*`, `ProyectoTest025/`
- **Impacto arquitectónico:** Nulo
- **Impacto operativo:** Bajo — consumo de espacio
- **Deuda técnica:** Baja
- **Complejidad:** Mínima
- **Riesgo futuro:** Nulo

### P-011: Start-HermesProject.ps1 monolítico
- **Archivos:** `motor/bootstrap/Start-HermesProject.ps1` (~400 líneas)
- **Impacto arquitectónico:** Alto — viola SRP
- **Impacto operativo:** Medio — difícil de modificar sin romper
- **Deuda técnica:** Alta
- **Complejidad:** Alta
- **Coste de mantenimiento:** Alto
- **Riesgo futuro:** Alto

### P-012: BootstrapOrchestrator + BootstrapWizard acoplados a UI
- **Archivos:** `motor/bootstrap/engine/BootstrapOrchestrator.ps1` (~200 líneas), `motor/bootstrap/engine/BootstrapWizard.ps1` (~300 líneas)
- **Impacto arquitectónico:** Alto — lógica de dominio mezclada con presentación
- **Deuda técnica:** Alta
- **Complejidad:** Alta
- **Coste de mantenimiento:** Alto
- **Riesgo futuro:** Alto

### P-013: Módulos stub sin implementación real
- **Archivos:** `motor/security/`, `motor/validation/`, `motor/scheduler/`, `motor/dependencygraph/`, `motor/discovery/`, `motor/providers/`, `motor/plugins/`, `motor/registro/`, `motor/lifecycle/`, `motor/contracts/`, `motor/capabilities/`, `motor/observability/`, `motor/manifest/`, `motor/wizards/`, `motor/sandbox/`, `motor/session/`
- **Impacto arquitectónico:** Medio — prometen funcionalidad que no existe
- **Deuda técnica:** Media
- **Complejidad:** Baja (eliminar) a Alta (implementar)
- **Coste de mantenimiento:** Bajo
- **Riesgo futuro:** Medio — expectativas falsas

### P-014: Azure vestigial
- **Archivos:** `motor/providers/azure/` (2 archivos), `Patch-Hermes-AzureTrace.ps1`
- **Impacto arquitectónico:** Bajo
- **Deuda técnica:** Baja
- **Complejidad:** Baja
- **Riesgo futuro:** Bajo

### P-015: Sin CI/CD pipeline
- **Impacto arquitectónico:** Alto — no hay validación automática
- **Impacto operativo:** Alto — cada release es manual
- **Deuda técnica:** Alta
- **Complejidad:** Media
- **Riesgo futuro:** Alto

### P-016: Nombres inconsistentes (español/inglés)
- **Impacto arquitectónico:** Bajo
- **Deuda técnica:** Media — dificulta la legibilidad
- **Complejidad:** Baja
- **Riesgo futuro:** Bajo

### P-017: Sin manejo de errores en kernel startup
- **Archivos:** `motor/kernel/Kernel.ps1` — `Start-HermesEnterpriseKernel` sin try/catch
- **Impacto arquitectónico:** Alto — fallo silencioso
- **Impacto operativo:** Alto — difícil de diagnosticar
- **Deuda técnica:** Alta
- **Complejidad:** Baja
- **Riesgo futuro:** Alto

### P-018: Paths hardcoded en KernelHost.ps1
- **Archivos:** `motor/kernel/Core/KernelHost.ps1` — usa `D:/HERMES-ENTERPRISE/...`
- **Impacto arquitectónico:** Alto — no portable
- **Deuda técnica:** Alta
- **Complejidad:** Baja
- **Riesgo futuro:** Alto

### P-019: Reports de diagnóstico no limpiados
- **Archivos:** 13+ JSON/MD en `reports/` generados por scripts únicos
- **Impacto arquitectónico:** Nulo
- **Deuda técnica:** Baja
- **Complejidad:** Mínima
- **Riesgo futuro:** Nulo

---

## 3. Análisis por Categoría

### 3.1 Categoría: Duplicación de código

| Problema | Archivos | Líneas totales | Líneas necesarias | Desperdicio |
|---|---|---|---|---|
| EventBus | 2 | 78 | 64 | 18% |
| DI Container | 3 | 88 | 47 | 47% |
| Git | 2 | 45 | 35 | 22% |
| Observabilidad | 2 | 94 | 68 | 28% |
| Configuración | 2 | 60 | 48 | 20% |

**Decisión:** Eliminar siempre la versión vestigial. Quedarse con la implementación más completa en cada caso.

### 3.2 Categoría: Código muerto

| Tipo | Cantidad | Acción |
|---|---|---|
| Scripts no referenciados | 8 | Eliminar |
| Directorios vacíos | 8 | Eliminar .gitkeep, eliminar dir si está vacío |
| Sandboxes | 10+ | Eliminar, conservar solo sandbox/actual |
| Backups huérfanos | 1 | Eliminar |
| Plugins demo | 1 | Eliminar |
| Reports generados | 13+ | Limpiar, conservar solo los activos |

### 3.3 Categoría: Deuda técnica arquitectónica

| Problema | Prioridad |
|---|---|
| Dos kernels | CRÍTICA |
| Sin pruebas | CRÍTICA |
| Monolito Start-HermesProject.ps1 | ALTA |
| BootstrapOrchestrator + UI | ALTA |
| Sin manejo de errores kernel | ALTA |
| Paths hardcoded | ALTA |
| 5 configs compitiendo | ALTA |
| Módulos stub | MEDIA |
| Nombres inconsistentes | BAJA |

### 3.4 Categoría: Riesgo operativo

| Riesgo | Impacto | Mitigación inmediata |
|---|---|---|
| Sin CI/CD | Alto | Fase 4 |
| Sin pruebas | Alto | Fase 2-3 |
| Sin error handling | Alto | Fase 2 |
| Múltiples configs | Medio | Fase 1 |
| Kernel duplicado | Alto | Fase 2 |

---

## 4. Matriz de Priorización Completada

### CRÍTICA (debe hacerse antes de cualquier cambio funcional)

| # | ID | Mejora |
|---|---|---|
| 1 | P-001 | Elegir y consolidar un solo kernel |
| 2 | P-002 | Establecer framework de pruebas Pester |
| 3 | P-015 | Establecer CI/CD pipeline mínimo |

### ALTA (debe hacerse antes de agregar nueva funcionalidad)

| # | ID | Mejora |
|---|---|---|
| 4 | P-011 | Refactorizar Start-HermesProject.ps1 (separar UI de lógica) |
| 5 | P-012 | Separar BootstrapOrchestrator de UI (BootstrapWizard) |
| 6 | P-007 | Unificar archivos de configuración |
| 7 | P-017 | Agregar manejo de errores en kernel startup |
| 8 | P-018 | Eliminar paths hardcoded |
| 9 | P-003 | Fusionar EventBuses |

### MEDIA (debe hacerse antes de release estable)

| # | ID | Mejora |
|---|---|---|
| 10 | P-004 | Fusionar DI containers + eliminar ServiceLocator |
| 11 | P-013 | Eliminar módulos stub sin implementación real |
| 12 | P-008 | Eliminar código muerto |
| 13 | P-014 | Eliminar Azure vestigial |
| 14 | P-005 | Fusionar módulos Git |
| 15 | P-006 | Fusionar Observabilidad |
| 16 | P-016 | Unificar nomenclatura español/inglés |

### BAJA (puede diferirse)

| # | ID | Mejora |
|---|---|---|
| 17 | P-009 | Eliminar directorios vacíos y .gitkeep |
| 18 | P-010 | Limpiar sandboxes |
| 19 | P-019 | Limpiar reports de diagnóstico |
| 20 | — | Mover archivos de raíz a docs/ (CHANGELOG.md, LICENSE, .env) |

---

## 5. Catálogo Detallado de Mejoras

Cada mejora incluye los 18 campos solicitados.

---

### M-001: Consolidar kernel único

| Campo | Valor |
|---|---|
| **Título** | Consolidar kernel único (eliminar kernel de clases) |
| **Descripción** | Elegir el kernel funcional (`Kernel.ps1` + funciones helper) como el único kernel. Eliminar `motor/kernel/Core/` completamente. Antes de eliminar, extraer cualquier lógica valiosa de KernelHost.ps1, ServiceContainer.ps1, EventBus.ps1 (clases) y ComponentRegistry.ps1 — específicamente el patrón de componentes con ciclo de vida (Initialize → Validate → Start) que está bien diseñado en KernelHost.ps1. |
| **Problema que resuelve** | Dos implementaciones paralelas para el mismo rol. |
| **Motivo técnico** | Kernel.ps1 ya está integrado con el bootstrap. KernelHost.ps1 tiene paths hardcoded y no es referenciado. Mantener ambos duplica el esfuerzo de mantenimiento. |
| **Beneficio esperado** | Reducción del 50% del código kernel; claridad arquitectónica inmediata. |
| **Impacto en rendimiento** | Ninguno (ambos son PowerShell). |
| **Impacto en mantenibilidad** | Alto — un solo kernel que mantener. |
| **Impacto en arquitectura** | Crítico — elimina la ambigüedad. |
| **Impacto en pruebas** | Reduce el scope de pruebas a la mitad. |
| **Impacto en observabilidad** | Ninguno. |
| **Impacto en CI/CD** | Simplifica el pipeline (menos archivos que validar). |
| **Riesgo** | Medio — Kernel.ps1 depende de funciones que pueden no estar referenciadas correctamente. |
| **Complejidad** | Media. |
| **Tiempo estimado** | 1 día. |
| **Archivos afectados** | `motor/kernel/Kernel.ps1`, `motor/kernel/Core/KernelHost.ps1`, `motor/kernel/Core/ServiceContainer.ps1`, `motor/kernel/Core/EventBus.ps1`, `motor/kernel/Core/ComponentRegistry.ps1`, `motor/kernel/Core/BootLoader.ps1`, `motor/kernel/Core/run_mission_bootstrap.ps1`, `motor/kernel/Core/descriptors/DummyComponent.json` |
| **Directorios afectados** | `motor/kernel/Core/` (eliminar completo) |
| **Dependencias** | Ninguna — operación atómica de eliminación. |
| **Orden recomendado** | 1 (primera mejora crítica). |
| **Precondiciones** | Validar que Kernel.ps1 funciona standalone. |
| **¿Rompe compatibilidad?** | **NO** — KernelHost.ps1 nunca fue referenciado desde ningún entrypoint real. |

Si rompe compatibilidad: N/A.

---

### M-002: Framework de pruebas Pester básico

| Campo | Valor |
|---|---|
| **Título** | Establecer framework de pruebas Pester |
| **Descripción** | Crear estructura de pruebas unitarias con Pester 5.x. Configurar `pruebas/unitarias/` con un test por módulo core. Primeros tests: Kernel.ps1, EventBus, Logger, ConfigurationManager. Usar `BeforeAll`/`Mock`/`Assert-MockCalled`. Los tests deben ser ejecutables de forma aislada (sin dependencias externas). |
| **Problema que resuelve** | 0% cobertura de pruebas. Sin red de seguridad para refactorizar. |
| **Motivo técnico** | No se puede refactorizar sin pruebas. Es la precondición para cualquier cambio arquitectónico. |
| **Beneficio esperado** | Red de seguridad inmediata para las ~12,000 líneas de código. |
| **Impacto en rendimiento** | Ninguno (solo en CI). |
| **Impacto en mantenibilidad** | Alto — cada cambio puede validarse. |
| **Impacto en arquitectura** | Medio — fuerza a escribir código testeable (inyección de dependencias). |
| **Impacto en pruebas** | De 0 a cobertura básica en módulos core. |
| **Impacto en observabilidad** | Ninguno. |
| **Impacto en CI/CD** | Precondición para CI/CD. |
| **Riesgo** | Bajo — los tests no modifican código de producción. |
| **Complejidad** | Media (aprender Pester 5.x si no se conoce). |
| **Tiempo estimado** | 2 días. |
| **Archivos afectados** | Nuevos: `pruebas/unitarias/Test-Kernel.ps1`, `Test-EventBus.ps1`, `Test-Logger.ps1`, `Test-ConfigurationManager.ps1`, `Test-DependencyInjection.ps1` |
| **Directorios afectados** | `pruebas/unitarias/` (poblarlo) |
| **Dependencias** | Ninguna. |
| **Orden recomendado** | 2 (segunda mejora crítica). |
| **Precondiciones** | PowerShell 7+, Pester 5.x instalado. |
| **¿Rompe compatibilidad?** | **NO** — solo agrega archivos nuevos. |

---

### M-003: CI/CD pipeline GitHub Actions

| Campo | Valor |
|---|---|
| **Título** | Establecer CI/CD pipeline mínimo |
| **Descripción** | Crear `.github/workflows/ci.yml` con: (1) checkout, (2) instalar PowerShell 7+, (3) instalar Pester, (4) ejecutar tests unitarios, (5) PSScriptAnalyzer lint, (6) validar que los scripts principales cargan sin errores. No incluir deploy. |
| **Problema que resuelve** | Sin validación automática. Cada release es manual. |
| **Motivo técnico** | CI/CD es la única forma de garantizar que la refactorización no rompe nada. |
| **Beneficio esperado** | Validación automática en cada push. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Alto — detección temprana de regresiones. |
| **Impacto en arquitectura** | Medio — fuerza consistencia. |
| **Impacto en pruebas** | Ejecución automática. |
| **Impacto en observabilidad** | Logs de CI disponibles. |
| **Impacto en CI/CD** | De 0 a pipeline funcional. |
| **Riesgo** | Bajo — no afecta código de producción. |
| **Complejidad** | Media. |
| **Tiempo estimado** | 1 día. |
| **Archivos afectados** | Nuevo: `.github/workflows/ci.yml` |
| **Directorios afectados** | `.github/workflows/` |
| **Dependencias** | M-002 (pruebas deben existir primero). |
| **Orden recomendado** | 3 (tercera mejora crítica). |
| **Precondiciones** | M-002 completado, repositorio en GitHub. |
| **¿Rompe compatibilidad?** | **NO** — solo agrega archivos nuevos. |

---

### M-004: Fusionar EventBuses (elegir funcional)

| Campo | Valor |
|---|---|
| **Título** | Fusionar EventBuses en una sola implementación |
| **Descripción** | Eliminar `motor/kernel/Core/EventBus.ps1` (clase de 14 líneas). La implementación funcional en `motor/eventos/EventBus.ps1` (64 líneas) es la que se queda. Tiene más features (lista de eventos publicados, logging, validación). Si hay algún consumidor de la clase EventBus (verificar con grep), migrarlo a la API funcional. |
| **Problema que resuelve** | Dos EventBuses haciendo lo mismo. |
| **Motivo técnico** | El funcional es más completo y es el que usa Kernel.ps1. |
| **Beneficio esperado** | Un solo EventBus, ~14 líneas menos de código duplicado. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Medio. |
| **Impacto en arquitectura** | Medio — elimina ambigüedad. |
| **Impacto en pruebas** | Un solo componente que testear. |
| **Impacto en observabilidad** | El funcional ya incluye `EventosPublicados` (lista histórica). |
| **Impacto en CI/CD** | Ninguno. |
| **Riesgo** | Bajo — verificar que ningún script usa la clase EventBus directamente. |
| **Complejidad** | Baja. |
| **Tiempo estimado** | 2 horas. |
| **Archivos afectados** | Eliminar: `motor/kernel/Core/EventBus.ps1`. Verificar: `motor/kernel/Core/KernelHost.ps1` (se eliminará en M-001). |
| **Directorios afectados** | Ninguno. |
| **Dependencias** | M-001 (Core se elimina, esto es consecuencia directa). |
| **Orden recomendado** | 4. |
| **Precondiciones** | M-001 completado. |
| **¿Rompe compatibilidad?** | **NO** — la clase EventBus solo es usada por KernelHost, que se elimina. |

---

### M-005: Fusionar DI containers + eliminar ServiceLocator

| Campo | Valor |
|---|---|
| **Título** | Unificar DI containers y eliminar ServiceLocator |
| **Descripción** | Eliminar `motor/kernel/Core/ServiceContainer.ps1` (clase de 10 líneas). Eliminar `motor/dependencias/ServiceLocator.ps1` (fachada innecesaria de 31 líneas). La implementación en `motor/dependencias/DependencyInjection.ps1` (47 líneas) es la que se queda. Migrar cualquier consumidor de ServiceLocator a DependencyInjection directamente. |
| **Problema que resuelve** | 3 implementaciones para un patrón de 10 líneas. |
| **Motivo técnico** | ServiceLocator es un anti-patrón (Service Locator) que oculta dependencias. La DI directa es preferible. |
| **Beneficio esperado** | Reducción de 3 archivos a 1. Eliminación de anti-patrón. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Medio — menos archivos que mantener. |
| **Impacto en arquitectura** | Medio — elimina capa de indirección innecesaria. |
| **Impacto en pruebas** | Un solo componente que mockear. |
| **Impacto en observabilidad** | Ninguno. |
| **Impacto en CI/CD** | Ninguno. |
| **Riesgo** | Bajo — verificar que ningún script usa `Get-HermesEnterpriseService` (ServiceLocator) o la clase `ServiceContainer`. |
| **Complejidad** | Baja. |
| **Tiempo estimado** | 2 horas. |
| **Archivos afectados** | Eliminar: `motor/kernel/Core/ServiceContainer.ps1`, `motor/dependencias/ServiceLocator.ps1`. Modificar: referencias a `Get-HermesEnterpriseService` → `Resolve-HermesEnterpriseService`. |
| **Directorios afectados** | Ninguno. |
| **Dependencias** | M-001 (Core se elimina). |
| **Orden recomendado** | 5. |
| **Precondiciones** | M-001 completado. |
| **¿Rompe compatibilidad?** | **NO** — si no hay consumidores de ServiceLocator. Verificar con grep. |

---

### M-006: Refactorizar Start-HermesProject.ps1

| Campo | Valor |
|---|---|
| **Título** | Separar UI de lógica de bootstrap en Start-HermesProject.ps1 |
| **Descripción** | Extraer la lógica de bootstrap actual (~400 líneas) en: (1) `motor/bootstrap/engine/BootstrapEngine.ps1` — lógica pura (crear proyecto, configurar git, ejecutar pruebas, provisionar), (2) `motor/bootstrap/integrations/VSCodeIntegration.ps1` — integración con VSCode, (3) mantener `motor/bootstrap/Start-HermesProject.ps1` como entrypoint que delega. El entrypoint solo debe manejar parámetros, validar inputs y llamar al engine. |
| **Problema que resuelve** | Monolito que mezcla UI, lógica de negocio e integraciones. |
| **Motivo técnico** | Viola SRP. No se puede testear la lógica de bootstrap sin ejecutar la UI. |
| **Beneficio esperado** | Código testeable, modular y mantenible. |
| **Impacto en rendimiento** | Ninguno (es PowerShell, la separación no afecta). |
| **Impacto en mantenibilidad** | Alto — cada capa se puede modificar independientemente. |
| **Impacto en arquitectura** | Alto — establece separación de concerns. |
| **Impacto en pruebas** | Alto — la lógica de bootstrap ahora es testeable con Pester. |
| **Impacto en observabilidad** | Puede agregarse logging en cada capa. |
| **Impacto en CI/CD** | Pueden testearse los componentes aislados. |
| **Riesgo** | Medio — refactorización significativa. Requiere pruebas primero (M-002). |
| **Complejidad** | Alta. |
| **Tiempo estimado** | 2 días. |
| **Archivos afectados** | `motor/bootstrap/Start-HermesProject.ps1`, nuevos: `motor/bootstrap/engine/BootstrapEngine.ps1`, `motor/bootstrap/integrations/VSCodeIntegration.ps1` |
| **Directorios afectados** | `motor/bootstrap/engine/`, `motor/bootstrap/integrations/` |
| **Dependencias** | M-002 (pruebas deben existir primero para validar que no se rompe nada). |
| **Orden recomendado** | 6. |
| **Precondiciones** | M-002, M-003 completados. |
| **¿Rompe compatibilidad?** | **SI** — los nombres de funciones internas cambian. Estrategia de migración: mantener funciones antiguas como obsoletas (con `[Obsolete]` attribute) por 1 sprint, luego eliminar. Rollback: restaurar archivo original desde git. |

---

### M-007: Separar BootstrapOrchestrator de BootstrapWizard

| Campo | Valor |
|---|---|
| **Título** | Separar orquestación de bootstrap de la UI del wizard |
| **Descripción** | `BootstrapOrchestrator.ps1` contiene lógica de orquestación MEZCLADA con UI del wizard (`BootstrapWizard.ps1`). Extraer toda la lógica de estado y transiciones de bootstrap a `BootstrapOrchestrator.ps1` (puro). Dejar solo la presentación (menús, colores, inputs) en `BootstrapWizard.ps1`. El wizard debe llamar al orchestrator, no contener lógica. |
| **Problema que resuelve** | UI y lógica de negocio acopladas. |
| **Motivo técnico** | Viola SRP. La lógica de bootstrap no puede testearse sin simular la UI. |
| **Beneficio esperado** | Orquestación testeable, UI reemplazable. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Alto. |
| **Impacto en arquitectura** | Alto. |
| **Impacto en pruebas** | Alto — la orquestación ahora es testeable. |
| **Impacto en observabilidad** | Puede agregarse logging en la orquestación. |
| **Impacto en CI/CD** | Testeable en pipeline. |
| **Riesgo** | Medio — refactorización grande. |
| **Complejidad** | Alta. |
| **Tiempo estimado** | 2 días. |
| **Archivos afectados** | `motor/bootstrap/engine/BootstrapOrchestrator.ps1`, `motor/bootstrap/engine/BootstrapWizard.ps1` |
| **Directorios afectados** | `motor/bootstrap/engine/` |
| **Dependencias** | M-002, M-006. |
| **Orden recomendado** | 7. |
| **Precondiciones** | M-006 completado. |
| **¿Rompe compatibilidad?** | **SI** — las funciones internas cambian. Estrategia de migración: mantener wrappers por 1 sprint. Rollback: git revert. |

---

### M-008: Unificar archivos de configuración

| Campo | Valor |
|---|---|
| **Título** | Unificar 5 archivos de configuración en 1 |
| **Descripción** | Consolidar toda la configuración en `Hermes.config.json`. Eliminar `bootstrap.yaml`, `configuracion/bootstrap.enterprise.json`, `configuracion/kernel.enterprise.json`. `bootstrap.json` puede mantenerse como alias de compatibilidad o eliminarse también. Migrar todas las referencias a las rutas nuevas. |
| **Problema que resuelve** | 5 archivos compitiendo, valores inconsistentes. |
| **Motivo técnico** | Viola DRY. No hay una fuente de verdad única. |
| **Beneficio esperado** | Una sola fuente de verdad. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Alto — un archivo que modificar. |
| **Impacto en arquitectura** | Medio — claridad en la gestión de configuración. |
| **Impacto en pruebas** | Un solo fixture de configuración. |
| **Impacto en observabilidad** | Ninguno. |
| **Impacto en CI/CD** | Un solo archivo que validar. |
| **Riesgo** | Medio — requiere migrar todas las referencias. |
| **Complejidad** | Media. |
| **Tiempo estimado** | 1 día. |
| **Archivos afectados** | `Hermes.config.json`, `bootstrap.json`, `bootstrap.yaml`, `configuracion/bootstrap.enterprise.json`, `configuracion/kernel.enterprise.json`, `motor/configuracion/ConfigurationManager.ps1`, `motor/config/Configuration.psm1` |
| **Directorios afectados** | `configuracion/` (eliminar), `motor/configuracion/` (unificar con `motor/config/`) |
| **Dependencias** | M-002 (pruebas para validar que la configuración se carga correctamente). |
| **Orden recomendado** | 8. |
| **Precondiciones** | M-002 completado. |
| **¿Rompe compatibilidad?** | **SI** — las rutas de configuración cambian. Estrategia de migración: mantener un shim que lea de la ubicación antigua y redirija a la nueva por 1 sprint. Rollback: restaurar archivos originales. |

---

### M-009: Agregar manejo de errores en kernel startup

| Campo | Valor |
|---|---|
| **Título** | Agregar try/catch y logging estructurado en Start-HermesEnterpriseKernel |
| **Descripción** | Envolver toda la función `Start-HermesEnterpriseKernel` en try/catch. Cada creación de subsistema (EventBus, Logger, Runtime, etc.) debe tener su propio try/catch con mensaje de error claro. Si un subsistema falla, el kernel debe registrarlo y continuar o detenerse gracefulmente según criticidad. |
| **Problema que resuelve** | Si falla `New-HermesEnterpriseEventBus`, todo el kernel falla sin mensaje. |
| **Motivo técnico** | Sin manejo de errores, los fallos son silenciosos y difíciles de diagnosticar. |
| **Beneficio esperado** | Diagnóstico inmediato de fallos en startup. |
| **Impacto en rendimiento** | Mínimo (solo en startup). |
| **Impacto en mantenibilidad** | Alto — errores claros. |
| **Impacto en arquitectura** | Medio — establece patrón de error handling. |
| **Impacto en pruebas** | Pueden testearse escenarios de fallo. |
| **Impacto en observabilidad** | Alto — errores registrados en log. |
| **Impacto en CI/CD** | Puede validarse que el kernel startup no falla. |
| **Riesgo** | Bajo — solo agrega try/catch, no modifica lógica. |
| **Complejidad** | Baja. |
| **Tiempo estimado** | 4 horas. |
| **Archivos afectados** | `motor/kernel/Kernel.ps1` |
| **Directorios afectados** | Ninguno. |
| **Dependencias** | Ninguna. |
| **Orden recomendado** | 9. |
| **Precondiciones** | Kernel.ps1 existe (no se requiere M-001, se puede hacer en paralelo). |
| **¿Rompe compatibilidad?** | **NO** — solo agrega try/catch, no cambia la API. |

---

### M-010: Eliminar paths hardcoded

| Campo | Valor |
|---|---|
| **Título** | Reemplazar paths absolutos con $PSScriptRoot y Join-Path |
| **Descripción** | Buscar y reemplazar todos los paths hardcoded (`D:/HERMES-ENTERPRISE/...`, `C:\...`) con `$PSScriptRoot`, `Split-Path -Parent $MyInvocation.MyCommand.Definition`, `Join-Path`. Priorizar `KernelHost.ps1` (que se elimina en M-001) y cualquier otro archivo que los tenga. |
| **Problema que resuelve** | Código no portable. |
| **Motivo técnico** | Viola el principio de portabilidad. El proyecto debe funcionar desde cualquier directorio. |
| **Beneficio esperado** | Código portable, funciona desde cualquier ubicación. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Alto. |
| **Impacto en arquitectura** | Medio. |
| **Impacto en pruebas** | Pueden ejecutarse tests desde cualquier directorio. |
| **Impacto en observabilidad** | Ninguno. |
| **Impacto en CI/CD** | Necesario para CI/CD (los paths relativos funcionan en cualquier runner). |
| **Riesgo** | Medio — un path mal reemplazado puede romper la carga de módulos. |
| **Complejidad** | Baja (búsqueda sistemática). |
| **Tiempo estimado** | 4 horas. |
| **Archivos afectados** | Todos los archivos .ps1 con paths hardcoded. Búsqueda: `grep -r "D:/\|C:/\|D:\\|C:\\" --include="*.ps1"` |
| **Directorios afectados** | Todo el proyecto. |
| **Dependencias** | M-001 (KernelHost.ps1 se elimina, reduciendo el scope). |
| **Orden recomendado** | 10. |
| **Precondiciones** | M-001 completado. |
| **¿Rompe compatibilidad?** | **NO** — los paths relativos son equivalentes si se ejecuta desde el mismo contexto. |

---

### M-011: Eliminar módulos stub sin implementación real

| Campo | Valor |
|---|---|
| **Título** | Eliminar módulos stub vacíos o sin implementación real |
| **Descripción** | Revisar cada subdirectorio de `motor/` que contenga solo stubs o archivos placeholder. Eliminar los que no tengan implementación real. Conservar solo: `motor/kernel/`, `motor/bootstrap/`, `motor/tools/`, `motor/config/` (o `motor/configuracion/` unificado), `motor/eventos/`, `motor/dependencias/`, `motor/logging/`, `motor/runtime/`. Eliminar: `motor/security/`, `motor/validation/`, `motor/scheduler/`, `motor/dependencygraph/`, `motor/discovery/`, `motor/providers/`, `motor/plugins/`, `motor/registro/`, `motor/lifecycle/`, `motor/contracts/`, `motor/capabilities/`, `motor/observability/`, `motor/manifest/`, `motor/wizards/`, `motor/sandbox/`, `motor/session/`, `motor/context/`. |
| **Problema que resuelve** | 22 módulos prometen funcionalidad que no existe. |
| **Motivo técnico** | Viola YAGNI. El código que no existe no necesita mantenimiento. |
| **Beneficio esperado** | Reducción del 70% de los directorios de motor/. Claridad arquitectónica. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Alto — menos directorios que explorar. |
| **Impacto en arquitectura** | Alto — la arquitectura real se vuelve visible. |
| **Impacto en pruebas** | Menos código que mockear. |
| **Impacto en observabilidad** | Ninguno. |
| **Impacto en CI/CD** | Menos archivos que validar. |
| **Riesgo** | Bajo — los stubs no tienen consumidores reales. Verificar con grep antes de eliminar. |
| **Complejidad** | Baja. |
| **Tiempo estimado** | 2 horas. |
| **Archivos afectados** | Archivos dentro de los directorios a eliminar. |
| **Directorios afectados** | 16 subdirectorios de `motor/` a eliminar. |
| **Dependencias** | Ninguna. |
| **Orden recomendado** | 11. |
| **Precondiciones** | Verificar con grep que ningún script referencia estos módulos. |
| **¿Rompe compatibilidad?** | **NO** — los stubs no tienen consumidores (verificar con grep). Si hay referencias, migrar antes de eliminar. |

---

### M-012: Eliminar Azure vestigial

| Campo | Valor |
|---|---|
| **Título** | Eliminar código Azure no utilizado |
| **Descripción** | Eliminar `motor/providers/azure/` (2 archivos), y `Patch-Hermes-AzureTrace.ps1`. Verificar que ningún script referencia AzureProviderAuthentication o AzureResourceDiscovery. |
| **Problema que resuelve** | Código muerto de integración Azure que nunca se completó. |
| **Motivo técnico** | Viola YAGNI. |
| **Beneficio esperado** | ~2 archivos menos que mantener. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Bajo. |
| **Impacto en arquitectura** | Bajo. |
| **Impacto en pruebas** | Ninguno. |
| **Impacto en CI/CD** | Ninguno. |
| **Riesgo** | Bajo. |
| **Complejidad** | Mínima. |
| **Tiempo estimado** | 30 minutos. |
| **Archivos afectados** | `motor/providers/azure/AzureProviderAuthentication.ps1`, `motor/providers/azure/AzureResourceDiscovery.ps1`, `Patch-Hermes-AzureTrace.ps1` |
| **Directorios afectados** | `motor/providers/` (puede eliminarse si queda vacío) |
| **Dependencias** | M-011 (eliminación de módulos stub). |
| **Orden recomendado** | 12. |
| **Precondiciones** | Verificar con grep que nadie usa estas funciones. |
| **¿Rompe compatibilidad?** | **NO** — código no referenciado. |

---

### M-013: Fusionar módulos Git

| Campo | Valor |
|---|---|
| **Título** | Fusionar los dos módulos Git en uno solo |
| **Descripción** | Combinar `motor/bootstrap/Git.ps1` y `motor/bootstrap/functions/Git.ps1` en un solo archivo `motor/bootstrap/functions/Git.ps1`. Incluir todas las funciones: `Test-GitInstallation`, `Get-GitStatusPorcelain`, `Get-CurrentBranch`, `Get-LocalHead`, `Fetch-Origin`, `Get-RemoteHead`, `Get-AheadBehind`. Eliminar `motor/bootstrap/Git.ps1`. |
| **Problema que resuelve** | 5 funciones duplicadas entre dos archivos. |
| **Motivo técnico** | Viola DRY. |
| **Beneficio esperado** | Un solo módulo Git, 10 líneas menos. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Bajo. |
| **Impacto en arquitectura** | Bajo. |
| **Impacto en pruebas** | Un solo archivo que testear. |
| **Impacto en CI/CD** | Ninguno. |
| **Riesgo** | Bajo — verificar que ningún script referencia `motor/bootstrap/Git.ps1` directamente. |
| **Complejidad** | Baja. |
| **Tiempo estimado** | 30 minutos. |
| **Archivos afectados** | Eliminar: `motor/bootstrap/Git.ps1`. Modificar: `motor/bootstrap/functions/Git.ps1` (agregar funciones de Git.ps1 que no estén ya). |
| **Directorios afectados** | Ninguno. |
| **Dependencias** | Ninguna. |
| **Orden recomendado** | 13. |
| **Precondiciones** | Verificar referencias. |
| **¿Rompe compatibilidad?** | **NO** — las funciones se mantienen con los mismos nombres. |

---

### M-014: Fusionar Observabilidad

| Campo | Valor |
|---|---|
| **Título** | Fusionar Observabilidad en motor/tools/ y eliminar vestigio en tools/ |
| **Descripción** | Eliminar `tools/Observabilidad.ps1` (vestigial). La versión en `motor/tools/Observabilidad.ps1` es más completa y es la que debe sobrevivir. Verificar que ningún script referencia la versión de tools/. |
| **Problema que resuelve** | Dos archivos con el mismo propósito. |
| **Motivo técnico** | Viola DRY. |
| **Beneficio esperado** | Un solo archivo de observabilidad. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Bajo. |
| **Impacto en arquitectura** | Bajo. |
| **Impacto en pruebas** | Un solo archivo que testear. |
| **Impacto en observabilidad** | La versión que sobrevive es más completa. |
| **Impacto en CI/CD** | Ninguno. |
| **Riesgo** | Bajo — verificar referencias. |
| **Complejidad** | Baja. |
| **Tiempo estimado** | 30 minutos. |
| **Archivos afectados** | Eliminar: `tools/Observabilidad.ps1` |
| **Directorios afectados** | `tools/` |
| **Dependencias** | Ninguna. |
| **Orden recomendado** | 14. |
| **Precondiciones** | Verificar que ningún dot-source apunta a la versión de tools/. |
| **¿Rompe compatibilidad?** | **NO** — la versión que sobrevive tiene las mismas funciones y más. |

---

### M-015: Eliminar código muerto (batch)

| Campo | Valor |
|---|---|
| **Título** | Eliminar 13+ archivos de código muerto |
| **Descripción** | Eliminar los siguientes archivos en un solo commit: `tools/LoadConfiguration.ps1`, `tools/GenerateIntegrityReport.ps1`, `hello.ps1`, `Patch-Hermes-AzureTrace.ps1`, `tools/EnterprisePipeline.ps1`, `builders/DocumentBuilder.ps1`, `builders/DocumentMetadata.ps1`, `builders/MarkdownUtilities.ps1`, `motor/bootstrap/GitHub.ps1`, `reports/backups/WorkspaceResolver.psm1.bak`, `plugins/HelloPlugin/` (directorio completo), `motor/kernel/Core/run_mission_bootstrap.ps1`, `motor/kernel/Core/descriptors/DummyComponent.json`. |
| **Problema que resuelve** | 13+ archivos que nadie usa pero todos ven. |
| **Motivo técnico** | Viola YAGNI y DRY. |
| **Beneficio esperado** | ~13 archivos menos. Reducción de ruido. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Medio — menos archivos que considerar. |
| **Impacto en arquitectura** | Medio — la arquitectura real se vuelve visible. |
| **Impacto en pruebas** | Menos código que cubrir. |
| **Impacto en observabilidad** | Ninguno. |
| **Impacto en CI/CD** | Menos archivos que validar. |
| **Riesgo** | Bajo — verificar que ningún script referencia estos archivos. |
| **Complejidad** | Baja. |
| **Tiempo estimado** | 1 hora. |
| **Archivos afectados** | 13+ archivos y 2 directorios. |
| **Directorios afectados** | `plugins/HelloPlugin/`, `reports/backups/`, `builders/` |
| **Dependencias** | M-001 (algunos archivos de Core/ se eliminan allí). |
| **Orden recomendado** | 15. |
| **Precondiciones** | Verificar referencias con grep. |
| **¿Rompe compatibilidad?** | **NO** — código no referenciado. |

---

### M-016: Eliminar directorios vacíos y .gitkeep

| Campo | Valor |
|---|---|
| **Título** | Eliminar directorios vacíos y archivos .gitkeep |
| **Descripción** | Eliminar todos los `.gitkeep` de los directorios vacíos. Eliminar los directorios que queden vacíos (a menos que sean necesarios como estructura futura). Directorios afectados: `agentes/`, `arquitectura/`, `herramientas/`, `memoria/`, `perfiles/`, `plantillas/`, `protocolos/`, `proveedores/`, `builders/` (si M-015 lo deja vacío), `pruebas/aceptacion/`, `pruebas/integracion/`. |
| **Problema que resuelve** | Ruido visual en el proyecto. |
| **Motivo técnico** | Viola el principio de claridad. Los directorios vacíos confunden. |
| **Beneficio esperado** | ~8 directorios menos. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Bajo. |
| **Impacto en arquitectura** | Bajo. |
| **Impacto en pruebas** | Ninguno. |
| **Impacto en CI/CD** | Ninguno. |
| **Riesgo** | Mínimo. |
| **Complejidad** | Mínima. |
| **Tiempo estimado** | 15 minutos. |
| **Archivos afectados** | ~8 archivos .gitkeep |
| **Directorios afectados** | ~10 directorios |
| **Dependencias** | M-015 (builders/ puede eliminarse allí). |
| **Orden recomendado** | 16. |
| **Precondiciones** | Ninguna. |
| **¿Rompe compatibilidad?** | **NO** — los .gitkeep no tienen funcionalidad. |

---

### M-017: Limpiar sandboxes

| Campo | Valor |
|---|---|
| **Título** | Limpiar sandboxes de prueba |
| **Descripción** | Eliminar todos los sandboxes excepto `sandbox/` (el directorio raíz) y opcionalmente mantener 1 activo (ej. `sandbox/current/`). Eliminar: todos los `sandbox/ProyectoTest*`, `sandbox/ProyectoPrueba*`, y `ProyectoTest025/` en la raíz. |
| **Problema que resuelve** | 10+ proyectos de prueba que nunca se limpiaron. |
| **Motivo técnico** | Ruido. Consumen espacio. |
| **Beneficio esperado** | ~10 directorios menos. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Bajo. |
| **Impacto en arquitectura** | Nulo. |
| **Impacto en pruebas** | Ninguno (no son pruebas). |
| **Impacto en CI/CD** | Ninguno. |
| **Riesgo** | Mínimo. |
| **Complejidad** | Mínima. |
| **Tiempo estimado** | 15 minutos. |
| **Archivos afectados** | Archivos dentro de los sandboxes. |
| **Directorios afectados** | ~10 directorios sandbox + `ProyectoTest025/` |
| **Dependencias** | Ninguna. |
| **Orden recomendado** | 17. |
| **Precondiciones** | Confirmar que ningún sandbox contiene datos necesarios. |
| **¿Rompe compatibilidad?** | **NO** — son proyectos de prueba. |

---

### M-018: Limpiar reports de diagnóstico

| Campo | Valor |
|---|---|
| **Título** | Limpiar reports generados por scripts de diagnóstico |
| **Descripción** | Eliminar los reports que son producto de una sola ejecución de diagnóstico. Conservar solo los que son útiles o generados activamente. Eliminar: `ArchitectureInventory.json`, `BootstrapDiagnostic.md`, `CreateProjectResult.json`, `DeudaTecnica.json`, `ExecutionTrace.json`, `ExecutionTrace.md`, `FilesystemTest.json`, `FilesystemTest.md`, `GitRepository.json`, `ImportForensics.json`, `ImportForensics.md`, `ImportTrace.json`, `ImportTrace.txt`, `JsonList.json`, `ModuleInventoryDetailed.json`, `ModulesList.json`, `ModuleStructure.json`, `ModuleStructure.md`, `ModuleValidation.json`, `ModuleValidation.txt`, `ProvisionReport.md`, `PythonList.json`, `ReporteForenseWorkspace.json`, `ReporteIntegridad.json`, `RepositoryCounts.json`, `RepositoryTree.json`, `ResolveWorkspace_output.txt`, `ResolveWorkspace.json`, `ScriptsList.json`, `SyntaxAudit.csv`, `YamlList.json`. Conservar: `BASELINE_GOLDEN_PATH.md`, `FileIndex.json`, `pester_result.xml`, `Test-ModuleValidation.ps1`, `ValidateCoreLoad.ps1`, `generate_forensic.ps1`. |
| **Problema que resuelve** | 30+ archivos de diagnóstico que confunden con el proyecto real. |
| **Motivo técnico** | Ruido. Los reports deben generarse bajo demanda, no almacenarse. |
| **Beneficio esperado** | ~30 archivos menos en reports/. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Bajo. |
| **Impacto en arquitectura** | Nulo. |
| **Impacto en pruebas** | Ninguno. |
| **Impacto en CI/CD** | Ninguno. |
| **Riesgo** | Mínimo. |
| **Complejidad** | Mínima. |
| **Tiempo estimado** | 15 minutos. |
| **Archivos afectados** | ~30 archivos en `reports/` |
| **Directorios afectados** | `reports/` |
| **Dependencias** | Ninguna. |
| **Orden recomendado** | 18. |
| **Precondiciones** | Verificar que ningún script referencia estos reports. |
| **¿Rompe compatibilidad?** | **NO** — son archivos de salida, no de entrada. |

---

### M-019: Unificar nomenclatura español/inglés

| Campo | Valor |
|---|---|
| **Título** | Unificar nomenclatura a español |
| **Descripción** | Estandarizar todos los nombres de funciones, variables y parámetros a español (consistente con el naming actual de la mayoría del proyecto). Ejemplos: `EventBus` → `BusEventos`, `Runtime` → `Runtime` (se mantiene si es nombre propio), `PluginManager` → `AdministradorPlugins`. Priorizar solo las funciones públicas y parámetros principales. No cambiar nombres internos de 3 líneas. |
| **Problema que resuelve** | Inconsistencia naming. |
| **Motivo técnico** | Consistencia = mantenibilidad. |
| **Beneficio esperado** | Código más legible y consistente. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Medio. |
| **Impacto en arquitectura** | Bajo. |
| **Impacto en pruebas** | Actualizar nombres en tests. |
| **Impacto en CI/CD** | Ninguno. |
| **Riesgo** | Medio — los cambios de nombre pueden romper referencias. |
| **Complejidad** | Media. |
| **Tiempo estimado** | 1 día. |
| **Archivos afectados** | Todos los .ps1 del proyecto. |
| **Directorios afectados** | Todo el proyecto. |
| **Dependencias** | M-001 a M-018 (hacer al final para evitar retrabajo). |
| **Orden recomendado** | 19. |
| **Precondiciones** | Toda la refactorización estructural completada. |
| **¿Rompe compatibilidad?** | **SI** — los nombres de funciones cambian. Estrategia de migración: agregar aliases (Set-Alias) para nombres antiguos por 1 sprint. Rollback: revertir commit de renombrado. |

---

### M-020: Mover archivos de raíz a docs/

| Campo | Valor |
|---|---|
| **Título** | Mover CHANGELOG.md, LICENSE, .env a docs/ |
| **Descripción** | Mover `CHANGELOG.md`, `LICENSE`, `.env` de la raíz a `docs/`. Actualizar referencias si es necesario. Mantener symlinks o README que indique la nueva ubicación. |
| **Problema que resuelve** | Saturación de la raíz del proyecto. |
| **Motivo técnico** | La raíz debe contener solo el entrypoint y el directorio motor/. |
| **Beneficio esperado** | Raíz más limpia. |
| **Impacto en rendimiento** | Ninguno. |
| **Impacto en mantenibilidad** | Bajo. |
| **Impacto en arquitectura** | Bajo. |
| **Impacto en pruebas** | Ninguno. |
| **Impacto en CI/CD** | Actualizar paths si es necesario. |
| **Riesgo** | Bajo. |
| **Complejidad** | Baja. |
| **Tiempo estimado** | 30 minutos. |
| **Archivos afectados** | `CHANGELOG.md`, `LICENSE`, `.env`, `README.md` (actualizar referencias) |
| **Directorios afectados** | `docs/` |
| **Dependencias** | Ninguna. |
| **Orden recomendado** | 20. |
| **Precondiciones** | Ninguna. |
| **¿Rompe compatibilidad?** | **NO** — mover archivos de documentación no afecta la ejecución. |

---

## 6. DAG de Dependencias

```
FASE 0 (Preparación)
├── M-009: Manejo de errores kernel ───┐
├── M-016: Eliminar .gitkeep ──────────┤
└── M-017: Limpiar sandboxes ──────────┤
                                        ▼
FASE 1 (Limpieza)
├── M-001: Consolidar kernel único ────┐
├── M-008: Unificar configuración ─────┤
├── M-011: Eliminar módulos stub ──────┤
├── M-012: Eliminar Azure vestigial ───┤
├── M-015: Eliminar código muerto ─────┤
├── M-018: Limpiar reports ────────────┤
└── M-020: Mover archivos a docs/ ─────┤
                                        ▼
FASE 2 (Consolidación)
├── M-002: Framework pruebas Pester ───┐ (bloqueante para Fase 3)
├── M-003: CI/CD pipeline ─────────────┤ (depende de M-002)
├── M-004: Fusionar EventBuses ────────┤ (depende de M-001)
├── M-005: Fusionar DI containers ─────┤ (depende de M-001)
├── M-013: Fusionar módulos Git ───────┤
├── M-014: Fusionar Observabilidad ────┤
                                        ▼
FASE 3 (Arquitectura)
├── M-006: Refactor Start-HermesProject ┐ (depende de M-002, M-003)
├── M-007: Separar Orchestrator de UI ──┤ (depende de M-006)
├── M-010: Eliminar paths hardcoded ────┤ (depende de M-001)
                                        ▼
FASE 4 (Optimización)
└── M-019: Unificar nomenclatura ───────┤ (depende de todo lo anterior)

FASE 5 (Hardening)
├── (Fase futura: hardening de seguridad, performance profiling)
└── (Depende de todo lo anterior)
```

### Tareas en paralelo permitidas

| Grupo | Tareas | Precondiciones |
|---|---|---|
| Grupo A | M-009, M-016, M-017 | Ninguna |
| Grupo B | M-001, M-008, M-011, M-012, M-015, M-018, M-020 | Grupo A |
| Grupo C | M-002, M-013, M-014 | Grupo B |
| Grupo D | M-003 | M-002 |
| Grupo E | M-004, M-005, M-010 | M-001 |
| Grupo F | M-006 | M-002, M-003 |
| Grupo G | M-007 | M-006 |
| Grupo H | M-019 | Todos los anteriores |

### Tareas bloqueantes

| Tarea | Bloquea |
|---|---|
| M-001 (kernel único) | M-004, M-005, M-010 |
| M-002 (pruebas Pester) | M-003, M-006 |
| M-003 (CI/CD) | M-006 |
| M-006 (refactor Start-HermesProject) | M-007 |

---

## 7. Análisis de Riesgo por Mejora

| ID | Mejora | Probabilidad fallo | Impacto | Criticidad | Esfuerzo (días) | Valor generado | ROI técnico | Quick Win | Debt Reduction | Maintenance Gain |
|---|---|---|---|---|---|---|---|---|---|---|
| M-001 | Consolidar kernel único | 20% | Alto | Crítica | 1 | 9/10 | 9.0 | No | 50% | Alto |
| M-002 | Framework pruebas Pester | 10% | Alto | Crítica | 2 | 10/10 | 5.0 | Sí | 80% | Crítico |
| M-003 | CI/CD pipeline | 10% | Alto | Crítica | 1 | 9/10 | 9.0 | Sí | 70% | Crítico |
| M-004 | Fusionar EventBuses | 5% | Bajo | Alta | 0.25 | 3/10 | 12.0 | Sí | 18% | Bajo |
| M-005 | Fusionar DI containers | 5% | Bajo | Alta | 0.25 | 4/10 | 16.0 | Sí | 47% | Medio |
| M-006 | Refactor Start-HermesProject | 30% | Alto | Alta | 2 | 8/10 | 4.0 | No | 60% | Alto |
| M-007 | Separar Orchestrator de UI | 30% | Alto | Alta | 2 | 7/10 | 3.5 | No | 50% | Alto |
| M-008 | Unificar configuración | 15% | Medio | Alta | 1 | 6/10 | 6.0 | Sí | 40% | Medio |
| M-009 | Manejo errores kernel | 5% | Alto | Alta | 0.5 | 7/10 | 14.0 | Sí | 30% | Alto |
| M-010 | Eliminar paths hardcoded | 15% | Medio | Alta | 0.5 | 5/10 | 10.0 | Sí | 25% | Medio |
| M-011 | Eliminar módulos stub | 5% | Bajo | Media | 0.25 | 6/10 | 24.0 | Sí | 70% | Alto |
| M-012 | Eliminar Azure vestigial | 2% | Bajo | Media | 0.1 | 2/10 | 20.0 | Sí | 5% | Bajo |
| M-013 | Fusionar módulos Git | 5% | Bajo | Media | 0.1 | 2/10 | 20.0 | Sí | 22% | Bajo |
| M-014 | Fusionar Observabilidad | 5% | Bajo | Media | 0.1 | 2/10 | 20.0 | Sí | 28% | Bajo |
| M-015 | Eliminar código muerto | 5% | Bajo | Media | 0.25 | 5/10 | 20.0 | Sí | 30% | Medio |
| M-016 | Eliminar .gitkeep y dirs vacíos | 2% | Bajo | Baja | 0.1 | 2/10 | 20.0 | Sí | 5% | Bajo |
| M-017 | Limpiar sandboxes | 2% | Bajo | Baja | 0.1 | 1/10 | 10.0 | Sí | 5% | Bajo |
| M-018 | Limpiar reports | 2% | Bajo | Baja | 0.1 | 1/10 | 10.0 | Sí | 5% | Bajo |
| M-019 | Unificar nomenclatura | 20% | Medio | Baja | 1 | 4/10 | 4.0 | No | 15% | Medio |
| M-020 | Mover archivos a docs/ | 5% | Bajo | Baja | 0.25 | 1/10 | 4.0 | Sí | 5% | Bajo |

### Leyenda

| Término | Escala |
|---|---|
| Probabilidad fallo | 0-100% |
| Valor generado | 1-10 (10 = máximo) |
| ROI técnico | Valor / Esfuerzo (días) |
| Quick Win | Sí si ROI > 5 y esfuerzo < 1 día |
| Debt Reduction | % estimado de deuda técnica reducida |

---

## 8. Roadmap por Fases

---

### Fase 0 — Preparación

**Objetivo:** Estabilizar el entorno de desarrollo antes de cualquier cambio, eliminando ruido inmediato.

**Duración:** 0.5 días

**Tareas:**
- M-009: Manejo de errores en kernel startup (4h)
- M-016: Eliminar directorios vacíos y .gitkeep (15min)
- M-017: Limpiar sandboxes (15min)

**Entregables:**
- Kernel.ps1 con try/catch en startup
- Proyecto sin directorios vacíos
- Un solo sandbox activo

**Riesgos:**
- Mínimo — tareas de bajo riesgo y bajo impacto

**Criterios de éxito:**
- `Start-HermesEnterpriseKernel` reporta errores claros si falla
- No hay directorios vacíos con .gitkeep en el proyecto
- Solo 1 sandbox en el directorio sandbox/

---

### Fase 1 — Limpieza

**Objetivo:** Eliminar todo el código muerto, duplicaciones obvias y módulos stub. Reducir el proyecto a su esencia.

**Duración:** 2 días

**Tareas:**
- M-001: Consolidar kernel único (1 día)
- M-008: Unificar archivos de configuración (1 día)
- M-011: Eliminar módulos stub (2h)
- M-012: Eliminar Azure vestigial (30min)
- M-015: Eliminar código muerto batch (1h)
- M-018: Limpiar reports de diagnóstico (15min)
- M-020: Mover archivos de raíz a docs/ (30min)

**Entregables:**
- Un solo kernel (Kernel.ps1 funcional)
- Un solo archivo de configuración (Hermes.config.json)
- 16 módulos stub eliminados de motor/
- 13+ archivos de código muerto eliminados
- ~30 reports de diagnóstico eliminados
- CHANGELOG.md, LICENSE, .env movidos a docs/
- Azure vestigial eliminado

**Riesgos:**
- M-001 (kernel): medio — validar que Kernel.ps1 funciona standalone antes de eliminar Core/
- M-008 (config): medio — migrar referencias correctamente

**Criterios de éxito:**
- `motor/kernel/Core/` eliminado
- `Kernel.ps1` carga sin errores con `New-HermesEnterpriseKernel` + `Start-HermesEnterpriseKernel`
- Solo existe `Hermes.config.json` como archivo de configuración
- `motor/` contiene solo: `kernel/`, `bootstrap/`, `tools/`, `config/`, `eventos/`, `dependencias/`, `logging/`, `runtime/`
- Raíz del proyecto contiene solo: `motor/`, `pruebas/`, `reports/`, `docs/`, `sandbox/`, `plugins/`, `.github/`, `CLINE.md`, `AUDIT_REPORT.md`, `MASTER_REFACTORING_ROADMAP.md`, `Hermes.config.json`, `README.md`, `Start-HermesProject.ps1`, `.gitignore`

---

### Fase 2 — Consolidación

**Objetivo:** Establecer la base técnica para toda la refactorización futura: pruebas, CI/CD, y eliminación de duplicaciones internas.

**Duración:** 4 días

**Tareas:**
- M-002: Framework de pruebas Pester básico (2 días)
- M-003: CI/CD pipeline GitHub Actions (1 día)
- M-004: Fusionar EventBuses (2h)
- M-005: Fusionar DI containers + eliminar ServiceLocator (2h)
- M-013: Fusionar módulos Git (30min)
- M-014: Fusionar Observabilidad (30min)

**Entregables:**
- 5+ tests Pester ejecutables para módulos core
- Pipeline CI que ejecuta tests en cada push
- Un solo EventBus
- Un solo DI container
- Un solo módulo Git
- Un solo archivo de Observabilidad
- ServiceLocator eliminado

**Riesgos:**
- M-002: medio — requiere conocimiento de Pester 5.x
- M-003: bajo — es solo agregar archivos YAML

**Criterios de éxito:**
- `Invoke-Pester` en `pruebas/unitarias/` pasa con 100%
- CI pipeline en GitHub Actions corre automáticamente en cada push
- No existe más de 1 EventBus, 1 DI container, 1 módulo Git, 1 Observabilidad
- ServiceLocator eliminado, todas las referencias migradas a DI directo

---

### Fase 3 — Arquitectura

**Objetivo:** Refactorizar los componentes arquitectónicamente más importantes: el entrypoint principal y los orquestadores de bootstrap.

**Duración:** 5 días

**Tareas:**
- M-006: Refactorizar Start-HermesProject.ps1 (2 días)
- M-007: Separar BootstrapOrchestrator de BootstrapWizard (2 días)
- M-010: Eliminar paths hardcoded (4h)
- M-019: Unificar nomenclatura español/inglés (1 día) — puede posponerse a Fase 4 si el tiempo es limitado

**Entregables:**
- Start-HermesProject.ps1 como entrypoint delgado que delega en BootstrapEngine
- BootstrapEngine.ps1 con lógica de bootstrap pura y testeable
- VSCodeIntegration.ps1 separado
- BootstrapOrchestrator.ps1 sin UI, solo lógica de orquestación
- BootstrapWizard.ps1 solo con presentación
- Cero paths hardcoded en el proyecto
- Nomenclatura consistente (español)

**Riesgos:**
- M-006: alto — refactorización grande de ~400 líneas
- M-007: alto — refactorización grande de ~500 líneas combinadas
- M-010: medio — un path mal reemplazado rompe carga de módulos

**Criterios de éxito:**
- `Start-HermesProject.ps1` funciona idéntico antes y después (probado con tests)
- `BootstrapEngine.ps1` puede testearse sin UI
- `BootstrapWizard.ps1` no contiene lógica de negocio
- `grep -r "D:/\|C:/\|D:\\|C:\\" --include="*.ps1"` no encuentra paths absolutos
- Todas las funciones públicas tienen nombres en español consistentes

---

### Fase 4 — Optimización

**Objetivo:** Pulir el código, mejorar la calidad y preparar para producción.

**Duración:** 2 días

**Tareas:**
- M-019 (si no se hizo en Fase 3): Unificar nomenclatura
- Agregar PSScriptAnalyzer al pipeline CI
- Revisar y mejorar logging en todos los componentes
- Escribir tests de integración para el flujo completo de bootstrap

**Entregables:**
- Nomenclatura consistente en todo el proyecto
- CI con lint automatizado
- Logging estructurado en todos los componentes core
- Tests de integración para bootstrap

**Riesgos:**
- Bajo — son mejoras incrementales sobre una base ya limpia

**Criterios de éxito:**
- PSScriptAnalyzer pasa sin errores
- Cobertura de tests > 50% en módulos core
- Todos los componentes tienen logging de entrada/salida/error

---

### Fase 5 — Hardening

**Objetivo:** Endurecer el sistema para producción.

**Duración:** 3 días

**Tareas:**
- Agregar validación de parámetros en todas las funciones públicas
- Agregar timeouts en operaciones de red (git, GitHub)
- Agregar telemetría básica (métricas de ejecución)
- Escribir documentación técnica de la nueva arquitectura
- Agregar badges de CI/CD al README.md
- Crear script de diagnóstico rápido (`verify.ps1`) que valide la integridad del proyecto

**Entregables:**
- Sistema listo para producción
- Documentación técnica actualizada
- Script verify.ps1
- README.md con badges de CI/CD

**Riesgos:**
- Bajo — sobre una base ya refactorizada y testeada

**Criterios de éxito:**
- `verify.ps1` corre sin errores
- Todos los parámetros tienen validación `[ValidateNotNullOrEmpty()]`, etc.
- README.md con badges de CI (pass/fail)
- Documentación actualizada refleja la nueva estructura

---

## 9. Matriz Impacto vs Esfuerzo

```
ALTO IMPACTO
    │
    │  M-002 (pruebas) ●
    │  M-003 (CI/CD)   ●
    │  M-001 (kernel)  ●
    │                    ● M-006 (refactor Start-HermesProject)
    │                    ● M-007 (separar UI)
    │  M-009 (errors) ●
    │  M-008 (config) ●
    │  M-011 (stubs)  ●
    │  M-010 (paths)  ●
    │  M-015 (dead)   ●
    │  M-005 (DI)     ●
    │  M-004 (EventBus) ●
    │  M-013 (Git)    ●
    │  M-014 (Observ) ●
    │  M-012 (Azure)  ●
    │  M-019 (naming)   ●
    │  M-020 (docs)   ●
    │  M-016 (gitkeep) ●
    │  M-017 (sandbox) ●
    │  M-018 (reports) ●
    │
BAJO IMPACTO
    BAJO ESFUERZO ────────────────────────── ALTO ESFUERZO
                        (días)
```

### Priorización por cuadrante

| Cuadrante | Tareas |
|---|---|
| **Alto impacto, bajo esfuerzo** (hacer primero) | M-002, M-003, M-009, M-011, M-015, M-005, M-004, M-013, M-014, M-012, M-008, M-010 |
| **Alto impacto, alto esfuerzo** (planificar) | M-001, M-006, M-007 |
| **Bajo impacto, bajo esfuerzo** (hacer cuando se pueda) | M-016, M-017, M-018, M-020 |
| **Bajo impacto, alto esfuerzo** (evitar o posponer) | M-019 (nomenclatura) — hacer solo si hay tiempo |

---

## 10. Matriz Riesgo vs Beneficio

```
ALTO BENEFICIO
    │
    │  M-002 (pruebas) ● Bajo riesgo
    │  M-003 (CI/CD)   ● Bajo riesgo
    │  M-001 (kernel)  ● Riesgo medio
    │  M-009 (errors)  ● Bajo riesgo
    │  M-008 (config)  ● Riesgo medio
    │  M-011 (stubs)   ● Bajo riesgo
    │  M-015 (dead)    ● Bajo riesgo
    │  M-010 (paths)   ● Riesgo medio
    │  M-005 (DI)      ● Bajo riesgo
    │  M-004 (EventBus)● Bajo riesgo
    │  M-006 (refactor)  ● Riesgo alto
    │  M-007 (separar)   ● Riesgo alto
    │  M-013 (Git)     ● Bajo riesgo
    │  M-014 (Observ)  ● Bajo riesgo
    │  M-012 (Azure)   ● Bajo riesgo
    │  M-019 (naming)  ● Riesgo medio
    │
BAJO BENEFICIO
    BAJO RIESGO ─────────────────────────── ALTO RIESGO
```

### Tareas por perfil de riesgo

| Perfil | Tareas |
|---|---|
| **Bajo riesgo, alto beneficio** (prioridad máxima) | M-002, M-003, M-009, M-011, M-015, M-005, M-004, M-013, M-014, M-012 |
| **Riesgo medio, alto beneficio** (ejecutar con precaución) | M-001, M-008, M-010 |
| **Alto riesgo, alto beneficio** (requiere pruebas primero) | M-006, M-007 |
| **Bajo riesgo, bajo beneficio** (baja prioridad) | M-016, M-017, M-018, M-020 |

---

## 11. Top 20 Tareas Inmediatas

Estas son las primeras 20 tareas que deben ejecutarse en orden, priorizadas por ROI técnico, riesgo y dependencias.

| # | ID | Tarea | Esfuerzo | ROI | Fase |
|---|---|---|---|---|---|
| 1 | M-011 | Eliminar 16 módulos stub de motor/ | 2h | 24.0 | F1 |
| 2 | M-012 | Eliminar Azure vestigial | 30min | 20.0 | F1 |
| 3 | M-013 | Fusionar módulos Git | 30min | 20.0 | F2 |
| 4 | M-014 | Fusionar Observabilidad | 30min | 20.0 | F2 |
| 5 | M-015 | Eliminar código muerto batch | 1h | 20.0 | F1 |
| 6 | M-016 | Eliminar .gitkeep y directorios vacíos | 15min | 20.0 | F0 |
| 7 | M-005 | Fusionar DI + eliminar ServiceLocator | 2h | 16.0 | F2 |
| 8 | M-009 | Manejo de errores en kernel startup | 4h | 14.0 | F0 |
| 9 | M-004 | Fusionar EventBuses | 2h | 12.0 | F2 |
| 10 | M-010 | Eliminar paths hardcoded | 4h | 10.0 | F3 |
| 11 | M-017 | Limpiar sandboxes | 15min | 10.0 | F0 |
| 12 | M-018 | Limpiar reports de diagnóstico | 15min | 10.0 | F1 |
| 13 | M-001 | Consolidar kernel único | 1d | 9.0 | F1 |
| 14 | M-003 | CI/CD pipeline | 1d | 9.0 | F2 |
| 15 | M-008 | Unificar configuración | 1d | 6.0 | F1 |
| 16 | M-002 | Framework pruebas Pester | 2d | 5.0 | F2 |
| 17 | M-020 | Mover archivos a docs/ | 30min | 4.0 | F1 |
| 18 | M-019 | Unificar nomenclatura | 1d | 4.0 | F4 |
| 19 | M-006 | Refactor Start-HermesProject | 2d | 4.0 | F3 |
| 20 | M-007 | Separar Orchestrator de UI | 2d | 3.5 | F3 |

### Orden de ejecución recomendado (top 10)

```
Día 1:
  M-016 (15min): Eliminar .gitkeep
  M-017 (15min): Limpiar sandboxes
  M-011 (2h):    Eliminar módulos stub
  M-012 (30min): Eliminar Azure vestigial
  M-015 (1h):    Eliminar código muerto batch
  M-018 (15min): Limpiar reports
  M-020 (30min): Mover archivos a docs/
  ─────────────────────────────────
  Total: ~5h

Día 2:
  M-009 (4h):    Manejo de errores kernel
  M-013 (30min): Fusionar módulos Git
  M-014 (30min): Fusionar Observabilidad
  M-005 (2h):    Fusionar DI + eliminar ServiceLocator
  M-004 (2h):    Fusionar EventBuses
  ─────────────────────────────────
  Total: ~9h

Días 3-4:
  M-001 (1d):    Consolidar kernel único

Días 5-6:
  M-008 (1d):    Unificar configuración

Días 7-8:
  M-010 (4h):    Eliminar paths hardcoded

Días 9-10:
  M-002 (2d):    Framework pruebas Pester

Días 11:
  M-003 (1d):    CI/CD pipeline

Días 12-13:
  M-006 (2d):    Refactor Start-HermesProject

Días 14-15:
  M-007 (2d):    Separar Orchestrator de UI

Día 16:
  M-019 (1d):    Unificar nomenclatura
```

---

## 12. Criterios de Éxito por Fase

### Fase 0 — Preparación

- [ ] `grep -r "\.gitkeep" .` no encuentra resultados
- [ ] `ls -d sandbox/*/` muestra solo 1 directorio (o 0)
- [ ] `Start-HermesEnterpriseKernel` tiene try/catch en todas las operaciones

### Fase 1 — Limpieza

- [ ] `ls -d motor/*/` muestra solo estos directorios: `kernel/`, `bootstrap/`, `tools/`, `config/`, `eventos/`, `dependencias/`, `logging/`, `runtime/`
- [ ] `ls configuracion/ 2>&1` muestra "No such file or directory"
- [ ] `ls bootstrap.yaml 2>&1` muestra "No such file or directory"
- [ ] `motor/kernel/Core/` no existe
- [ ] `tools/LoadConfiguration.ps1` no existe
- [ ] `tools/GenerateIntegrityReport.ps1` no existe
- [ ] `hello.ps1` no existe
- [ ] `Patch-Hermes-AzureTrace.ps1` no existe
- [ ] `reports/backups/` no existe
- [ ] `plugins/HelloPlugin/` no existe
- [ ] `builders/` no existe
- [ ] `ProyectoTest025/` no existe
- [ ] `CHANGELOG.md`, `LICENSE`, `.env` están en `docs/`
- [ ] Solo existe `Hermes.config.json` como configuración

### Fase 2 — Consolidación

- [ ] `Invoke-Pester pruebas/unitarias/` pasa con 100%
- [ ] `.github/workflows/ci.yml` existe
- [ ] `motor/eventos/EventBus.ps1` es el único EventBus
- [ ] `motor/dependencias/DependencyInjection.ps1` es el único DI container
- [ ] `motor/dependencias/ServiceLocator.ps1` no existe
- [ ] `motor/kernel/Core/ServiceContainer.ps1` no existe
- [ ] `motor/kernel/Core/EventBus.ps1` no existe
- [ ] `motor/bootstrap/Git.ps1` no existe
- [ ] `motor/bootstrap/functions/Git.ps1` existe con todas las funciones
- [ ] `tools/Observabilidad.ps1` no existe
- [ ] `motor/tools/Observabilidad.ps1` es el único

### Fase 3 — Arquitectura

- [ ] `Start-HermesProject.ps1` tiene < 50 líneas (entrypoint delgado)
- [ ] `motor/bootstrap/engine/BootstrapEngine.ps1` existe
- [ ] `BootstrapWizard.ps1` no contiene lógica de bootstrap (solo UI)
- [ ] `grep -r "D:/\|C:/\|D:\\|C:\\" --include="*.ps1"` no encuentra resultados
- [ ] Todas las funciones públicas tienen nombres consistentes

### Fase 4 — Optimización

- [ ] PSScriptAnalyzer pasa sin errores
- [ ] CI pipeline incluye lint
- [ ] Cobertura de tests > 50%

### Fase 5 — Hardening

- [ ] `verify.ps1` corre sin errores
- [ ] README.md con badges de CI/CD
- [ ] Documentación actualizada

---

## 13. Estrategia de Rollback Global

### Principio general

Cada mejora debe hacerse en un commit independiente. Esto permite revertir mejoras individuales sin afectar las demás.

### Estrategia por nivel de riesgo

| Riesgo | Estrategia |
|---|---|
| Bajo (M-011 a M-018, M-020) | Commit directo. Rollback: `git revert <commit>` |
| Medio (M-001, M-008, M-010, M-019) | Commit con validación manual antes. Rollback: `git revert <commit>` |
| Alto (M-006, M-007) | Branch feature + PR + code review + tests pasando antes de mergear. Rollback: `git revert <merge-commit>` |

### Procedimiento de rollback estándar

```powershell
# 1. Identificar el commit a revertir
git log --oneline

# 2. Revertir (crea un nuevo commit que deshace los cambios)
git revert <commit-hash>

# 3. Verificar que el proyecto sigue funcionando
git status
Invoke-Pester pruebas/unitarias/
```

### Para cambios que rompen compatibilidad (M-006, M-007, M-008, M-019)

1. Mantener funciones antiguas como obsoletas por 1 sprint (`[Obsolete("Use NuevaFuncion instead")]`)
2. En el siguiente sprint, eliminar las funciones obsoletas
3. Si hay consumidores externos, notificar con 1 sprint de antelación

### Snapshot de seguridad

Antes de comenzar la Fase 0, crear un tag de git con el estado actual:

```powershell
git tag -a rc13-pre-refactor -m "Estado antes del Master Refactoring Roadmap"
git push origin rc13-pre-refactor
```

Este tag permite restaurar el estado exacto anterior en cualquier momento.

---

## Apéndice A: Resumen de Archivos y Directorios a Eliminar

### Archivos a eliminar (31+)

| Archivo | Mejora |
|---|---|
| `motor/kernel/Core/KernelHost.ps1` | M-001 |
| `motor/kernel/Core/ServiceContainer.ps1` | M-001 |
| `motor/kernel/Core/EventBus.ps1` | M-001 |
| `motor/kernel/Core/ComponentRegistry.ps1` | M-001 |
| `motor/kernel/Core/BootLoader.ps1` | M-001 |
| `motor/kernel/Core/run_mission_bootstrap.ps1` | M-001 |
| `motor/kernel/Core/descriptors/DummyComponent.json` | M-001 |
| `bootstrap.yaml` | M-008 |
| `configuracion/bootstrap.enterprise.json` | M-008 |
| `configuracion/kernel.enterprise.json` | M-008 |
| `motor/config/Configuration.psm1` | M-008 |
| `motor/dependencias/ServiceLocator.ps1` | M-005 |
| `tools/LoadConfiguration.ps1` | M-015 |
| `tools/GenerateIntegrityReport.ps1` | M-015 |
| `hello.ps1` | M-015 |
| `Patch-Hermes-AzureTrace.ps1` | M-015 |
| `tools/EnterprisePipeline.ps1` | M-015 |
| `builders/DocumentBuilder.ps1` | M-015 |
| `builders/DocumentMetadata.ps1` | M-015 |
| `builders/MarkdownUtilities.ps1` | M-015 |
| `motor/bootstrap/GitHub.ps1` | M-015 |
| `reports/backups/WorkspaceResolver.psm1.bak` | M-015 |
| `motor/kernel/Core/run_mission_bootstrap.ps1` | M-015 |
| `motor/kernel/Core/descriptors/DummyComponent.json` | M-015 |
| `tools/Observabilidad.ps1` | M-014 |
| `motor/bootstrap/Git.ps1` | M-013 |
| `motor/providers/azure/AzureProviderAuthentication.ps1` | M-012 |
| `motor/providers/azure/AzureResourceDiscovery.ps1` | M-012 |
| `agentes/.gitkeep` | M-016 |
| `arquitectura/.gitkeep` | M-016 |
| `herramientas/.gitkeep` | M-016 |
| `memoria/.gitkeep` | M-016 |
| `perfiles/.gitkeep` | M-016 |
| `plantillas/.gitkeep` | M-016 |
| `protocolos/.gitkeep` | M-016 |
| `proveedores/.gitkeep` | M-016 |
| `pruebas/.gitkeep` | M-016 |
| ~30 reports en `reports/` | M-018 |

### Directorios a eliminar (21+)

| Directorio | Mejora |
|---|---|
| `motor/kernel/Core/` | M-001 |
| `configuracion/` | M-008 |
| `motor/config/` | M-008 (unificar con motor/configuracion/) |
| `motor/security/` | M-011 |
| `motor/validation/` | M-011 |
| `motor/scheduler/` | M-011 |
| `motor/dependencygraph/` | M-011 |
| `motor/discovery/` | M-011 |
| `motor/providers/` | M-011 |
| `motor/plugins/` | M-011 |
| `motor/registro/` | M-011 |
| `motor/lifecycle/` | M-011 |
| `motor/contracts/` | M-011 |
| `motor/capabilities/` | M-011 |
| `motor/observability/` | M-011 |
| `motor/manifest/` | M-011 |
| `motor/wizards/` | M-011 |
| `motor/sandbox/` | M-011 |
| `motor/session/` | M-011 |
| `motor/context/` | M-011 |
| `plugins/HelloPlugin/` | M-015 |
| `reports/backups/` | M-015 |
| `builders/` | M-015 |
| `agentes/` | M-016 (si queda vacío) |
| `herramientas/` | M-016 (si queda vacío) |
| `memoria/` | M-016 (si queda vacío) |
| ~10 sandboxes | M-017 |
| `ProyectoTest025/` | M-017 |

---

## Apéndice B: Arquitectura Objetivo

```
HERMES-ENTERPRISE/
├── Hermes.config.json              # Única fuente de verdad de configuración
├── Start-HermesProject.ps1         # Entrypoint delgado (< 50 líneas)
├── README.md                       # Documentación principal
├── CLINE.md                        # Reglas de trabajo
├── AUDIT_REPORT.md                 # Auditoría técnica
├── MASTER_REFACTORING_ROADMAP.md   # Este documento
│
├── motor/
│   ├── kernel/
│   │   └── Kernel.ps1              # Único kernel enterprise
│   ├── bootstrap/
│   │   ├── Start-HermesProject.ps1 # Entrypoint bootstrap (delgado)
│   │   ├── engine/
│   │   │   ├── BootstrapEngine.ps1        # Lógica pura de bootstrap
│   │   │   ├── BootstrapOrchestrator.ps1  # Orquestación (sin UI)
│   │   │   └── BootstrapState.ps1         # Máquina de estados
│   │   ├── wizard/
│   │   │   └── BootstrapWizard.ps1        # Solo UI/presentación
│   │   ├── integrations/
│   │   │   └── VSCodeIntegration.ps1      # Integración VSCode
│   │   └── functions/
│   │       └── Git.ps1                    # Único módulo Git
│   ├── config/
│   │   └── ConfigurationManager.ps1       # Único gestor de configuración
│   ├── eventos/
│   │   └── EventBus.ps1                   # Único EventBus
│   ├── dependencias/
│   │   └── DependencyInjection.ps1        # Único DI container
│   ├── logging/
│   │   └── Logger.ps1                     # Logger estructurado
│   ├── runtime/
│   │   └── Runtime.ps1                    # Ciclo de vida runtime
│   └── tools/
│       └── Observabilidad.ps1             # Única observabilidad
│
├── pruebas/
│   ├── unitarias/                         # Tests Pester 5.x
│   ├── integracion/                       # Tests de integración
│   └── aceptacion/                        # Tests E2E
│
├── reports/                               # Reports generados activamente
├── docs/
│   ├── adr/                               # Architecture Decision Records
│   ├── CHANGELOG.md
│   ├── LICENSE
│   └── .env (template)
│
├── sandbox/                               # Sandbox temporal (se limpia al empezar)
├── plugins/                               # Plugins futuros
│
└── .github/
    └── workflows/
        └── ci.yml                         # CI/CD pipeline
```

### Comparativa: antes vs después

| Métrica | Antes | Después |
|---|---|---|
| Directorios en motor/ | 22 | 8 |
| Archivos .ps1 principales | ~60 | ~20 |
| Archivos de configuración | 5+ | 1 |
| Kernels | 2 | 1 |
| EventBuses | 2 | 1 |
| DI containers | 3 | 1 |
| Módulos Git | 2 | 1 |
| Observabilidad | 2 | 1 |
| Sandboxes | 10+ | 1 |
| Reports estáticos | 30+ | solo activos |
| Cobertura de tests | 0% | >50% (core) |
| CI/CD | No | Sí |
| Paths hardcoded | 1+ | 0 |
| Manejo de errores kernel | No | Sí |
| Código muerto | 13+ archivos | 0 |

---

*Fin del documento MASTER_REFACTORING_ROADMAP.md*

*Versión 1.0 — Aprobado para Architecture Review Board*