# Auditoría Técnica — Hermes Enterprise

**Fecha:** 2026-07-29  
**Propósito:** Identificar duplicaciones, dead code, violaciones arquitectónicas, deuda técnica y proponer una simplificación estructural.

---

## Índice

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Módulos Duplicados y Funcionalidades Solapadas](#2-módulos-duplicados-y-funcionalidades-solapadas)
3. [Scripts Obsoletos y Archivos No Utilizados](#3-scripts-obsoletos-y-archivos-no-utilizados)
4. [Pruebas Rotas y Dependencias Innecesarias](#4-pruebas-rotas-y-dependencias-innecesarias)
5. [Violaciones SOLID, Deuda Técnica y Código Muerto](#5-violaciones-solid-deuda-técnica-y-código-muerto)
6. [Configuraciones Repetidas, Clases Grandes, Módulos Fusionables](#6-configuraciones-repetidas-clases-grandes-módulos-fusionables)
7. [Riesgos de Mantenimiento](#7-riesgos-de-mantenimiento)
8. [Propuesta de Arquitectura Más Simple](#8-propuesta-de-arquitectura-más-simple)
9. [Hoja de Ruta de Refactorización](#9-hoja-de-ruta-de-refactorización)

---

## 1. Resumen Ejecutivo

Hermes Enterprise presenta **2 sistemas paralelos incompletos** dentro del mismo repositorio:

1. **`motor/kernel/Kernel.ps1` + funciones helper** (`motor/eventos/`, `motor/dependencias/`, `motor/logging/`, `motor/runtime/`, `motor/configuracion/`, `motor/plugins/`, `motor/registro/`) → API funcional basada en PowerShell `[pscustomobject]` y funciones con prefijo `New-/Get-/Write-/Register-HermesEnterprise*`. **Inacabado**: muchas funciones son stub (e.g. `motor/plugins/`, `motor/registro/`, `motor/security/`, `motor/validation/`, `motor/scheduler/`).
2. **`motor/kernel/Core/`** con clases `KernelHost`, `ServiceContainer`, `EventBus`, `ComponentRegistry`, `BootLoader` → API orientada a objetos con clases de PowerShell. **Inacabado**: solo 5 clases, sin integración real con el bootstrap.

Ambos sistemas **comptiten por el mismo rol** (arranque del kernel, DI, event bus) pero **ninguno está completo** ni integrado con `Start-HermesProject.ps1`.

**Hallazgos clave:**
- **2 EventBuses** que hacen lo mismo.
- **2 Service Containers / DI** que hacen lo mismo.
- **2 módulos Git** (`motor/bootstrap/Git.ps1` y `motor/bootstrap/functions/Git.ps1`).
- **2 Observabilidad.ps1** (raíz `tools/` y `motor/tools/`).
- **6+ subdirectorios vacíos** con solo `.gitkeep`.
- **10+ sandboxes/proyectos de prueba** que nunca se limpiaron.
- **13+ reportes JSON/MD** generados por scripts de diagnóstico, la mayoría de una sola ejecución.
- **1 backup** (`reports/backups/WorkspaceResolver.psm1.bak`) huérfano.
- **Código muerto:** `tools/LoadConfiguration.ps1`, `tools/GenerateIntegrityReport.ps1`, `herramientas/`, `builders/`, `Patch-Hermes-AzureTrace.ps1`.
- **Ninguna prueba unitaria real** ejecutable (solo scripts de diagnóstico en `reports/`).

---

## 2. Módulos Duplicados y Funcionalidades Solapadas

### 2.1 EventBus × 2

| Archivo | Líneas | Tipo |
|---|---|---|
| `motor/eventos/EventBus.ps1` | 64 | Funciones `New-`, `Subscribe-`, `Publish-HermesEnterpriseEvent` |
| `motor/kernel/Core/EventBus.ps1` | 14 | Clase `EventBus` con `Subscribe`, `Publish` |

**Problema:** El Kernel.ps1 (funcional) instancia `New-HermesEnterpriseEventBus` y usa `Publish-HermesEnterpriseEvent`. El `KernelHost.ps1` (clase) instancia el `EventBus` class e invoca `$this.eventBus.Publish()`. Nunca se cruzan.

### 2.2 Dependency Injection × 2

| Archivo | Líneas | Tipo |
|---|---|---|
| `motor/dependencias/DependencyInjection.ps1` | 47 | Funciones `New-`, `Register-`, `Resolve-HermesEnterpriseService` |
| `motor/kernel/Core/ServiceContainer.ps1` | 10 | Clase `ServiceContainer` con `Register`, `Resolve`, `Has` |
| `motor/dependencias/ServiceLocator.ps1` | 31 | Fachada sobre DependencyInjection.ps1 |

**Problema:** 3 implementaciones para un patrón singleton de 10 líneas. ServiceLocator es una capa de indirección innecesaria.

### 2.3 Módulos Git × 2

| Archivo | Líneas |
|---|---|
| `motor/bootstrap/Git.ps1` | 10 |
| `motor/bootstrap/functions/Git.ps1` | 35 |

**Problema:** El segundo es una versión extendida del primero (agrega `Test-GitInstallation`). Comparten 5 funciones con nombres idénticos.

### 2.4 Observabilidad × 2

| Archivo | Líneas |
|---|---|
| `tools/Observabilidad.ps1` | 26 |
| `motor/tools/Observabilidad.ps1` | 68 |

**Problema:** `motor/tools/Observabilidad.ps1` es una versión más completa (agrega `Stop-EventBus`, `Write-HermesLog`, `Write-HermesStatus` y usa `Get-RepoRootAndReportsDir`). La versión en `tools/` es vestigial y escribe a `hermes.log` en la raíz en vez de `reports/`.

### 2.5 Configuración × 2

| Archivo | Líneas |
|---|---|
| `motor/configuracion/ConfigurationManager.ps1` | 48 |
| `motor/config/Configuration.psm1` | 12 |

**Problema:** Configuration.psm1 es un stub de 12 líneas que nadie importa. ConfigurationManager.ps1 es la implementación real usada por `Kernel.ps1`.

---

## 3. Scripts Obsoletos y Archivos No Utilizados

### 3.1 Código Muerto Confirmado

| Archivo | Razón |
|---|---|
| `tools/LoadConfiguration.ps1` | No referenciado por ningún script. Función reemplazada por `ConfigurationManager.ps1`. |
| `tools/GenerateIntegrityReport.ps1` | Script de diagnóstico único. Los reportes ya existen en `reports/`. |
| `Patch-Hermes-AzureTrace.ps1` | Script de parche único en la raíz. Sin referencias. |
| `hello.ps1` | Script hello world en la raíz. |
| `tools/EnterprisePipeline.ps1` | No referenciado, probablemente experimental. |
| `tools/HermesPathResolver.psm1` | Solo referenciado por `Start-HermesProject.ps1`, pero hay un backup en `reports/backups/`. |
| `reports/backups/WorkspaceResolver.psm1.bak` | Backup huérfano. |
| `builders/DocumentBuilder.ps1` | Script de documentación, no referenciado. |
| `builders/DocumentMetadata.ps1` | Script de documentación, no referenciado. |
| `builders/MarkdownUtilities.ps1` | Script de documentación, no referenciado. |
| `motor/tools/Observabilidad.ps1` (tools/) | Versión vestigial, reemplazada por `motor/tools/Observabilidad.ps1`. |
| `configuracion/bootstrap.enterprise.json` | ¿Referenciado? vs `bootstrap.json` y `bootstrap.yaml`. |
| `configuracion/kernel.enterprise.json` | vs `configuracion/kernel.enterprise.json`. |

### 3.2 Directorios Vacíos o con solo .gitkeep

```
agentes/         → .gitkeep
arquitectura/    → .gitkeep (subdirs: decisiones/, diagramas/)
herramientas/    → .gitkeep
memoria/         → .gitkeep
perfiles/        → .gitkeep
plantillas/      → .gitkeep
protocolos/      → .gitkeep
proveedores/     → .gitkeep
```

### 3.3 Sandboxes/Proyectos de Prueba No Limpiados

```
sandbox/ProyectoPrueba001/
sandbox/ProyectoTest001/ ... sandbox/ProyectoTest018/  (10+ proyectos)
ProyectoTest025/   → proyecto de prueba en la raíz
```

---

## 4. Pruebas Rotas y Dependencias Innecesarias

### 4.1 Pruebas

| Archivo | Problema |
|---|---|
| `pruebas/bootstrap/Test-StartHermesProject.ps1` | Depende de `Start-HermesProject.ps1` que a su vez depende de `HermesPathResolver.psm1`. Sin mock isolation. |
| `pruebas/unitarias/Test-BootstrapOrchestrator.ps1` | Depende de `motor/bootstrap/engine/BootstrapOrchestrator.ps1`. No se puede ejecutar standalone. |
| `pruebas/unitarias/Test-StartHermesProject.ps1` | Similar. |
| `pruebas/diagnostico/` | Contiene scripts de diagnóstico, no pruebas unitarias. |
| `pruebas/aceptacion/` | Vacío. |
| `pruebas/integracion/` | Vacío. |
| `reports/Test-ModuleValidation.ps1` | Script de diagnóstico disfrazado de test. |
| `reports/ValidateCoreLoad.ps1` | Script de diagnóstico disfrazado de test. |

**Ninguna prueba usa Pester con `BeforeAll`/`Mock`/`Assert-MockCalled`.**
**Ninguna prueba es ejecutable de forma aislada.**

### 4.2 Dependencias Innecesarias

- `motor/dependencias/ServiceLocator.ps1`: Fachada que solo delega a `Resolve-HermesEnterpriseService`. No agrega valor.
- `motor/config/Configuration.psm1`: Stub de 12 líneas, exporta `Get-HermesConfiguration` que nadie importa.
- `motor/dependencygraph/` y `motor/discovery/` y `motor/scheduler/`: Directorios con archivos no implementados.
- `motor/providers/` y `motor/security/` y `motor/validation/` y `motor/eventos/`: Directorios con implementaciones mínimas o vacías.

---

## 5. Violaciones SOLID, Deuda Técnica y Código Muerto

### 5.1 Violaciones SOLID

| Principio | Violación |
|---|---|
| **SRP** | `Kernel.ps1` (103 líneas) mezcla: creación de objetos, registro de servicios, inicialización de plugins, métricas, logging, eventos — todo en una sola función `Start-HermesEnterpriseKernel`. |
| **OCP** | El Kernel no puede ser extendido sin modificar `Start-HermesEnterpriseKernel`. No hay un pipeline de plugins funcional. |
| **LSP** | `ServiceLocator` no puede sustituir a `DependencyContainer` limpiamente porque tiene una interfaz diferente. |
| **ISP** | `Start-HermesEnterpriseKernel` acepta un objeto `KernelEnterprise` completo cuando solo necesita propiedades sueltas. |
| **DIP** | `Kernel.ps1` depende directamente de implementaciones concretas (`New-HermesEnterpriseConfigurationManager`, `New-HermesEnterpriseLogger`, etc.) en vez de abstracciones/contratos. |

### 5.2 Deuda Técnica

1. **Nombres inconsistentes:** Mezcla de español (`KernelEnterprise`, `NombreServicio`, `RutaArchivoLog`) e inglés (`EventBus`, `Runtime`, `PluginManager`), con prefijos `HermesEnterprise` vs nombres sin prefijo.
2. **Sin manejo de errores:** `Start-HermesEnterpriseKernel` no tiene try/catch. Si falla `New-HermesEnterpriseEventBus`, todo el kernel falla sin mensaje claro.
3. **Hardcoded paths:** `KernelHost.ps1` usa `D:/HERMES-ENTERPRISE/...` hardcoded en lugar de `$PSScriptRoot`.
4. **Código inalcanzable:** `motor/bootstrap/GitHub.ps1` (6 funciones stub que solo hacen `Write-Host`).
5. **Sin pruebas:** Cobertura de pruebas = 0%.
6. **Azure vestigial:** `motor/providers/azure/` (2 archivos) y `Patch-Hermes-AzureTrace.ps1` para una integración Azure que nunca se completó.
7. **Múltiples formatos de bootstrap:** `bootstrap.json`, `bootstrap.yaml`, `Hermes.config.json`, `configuracion/bootstrap.enterprise.json`, `configuracion/kernel.enterprise.json` — 5 archivos de configuración compitiendo.

### 5.3 Código Muerto

- `motor/kernel/Core/run_mission_bootstrap.ps1` — script suelto en Core.
- `motor/kernel/Core/descriptors/DummyComponent.json` — archivo dummy.
- `plugins/HelloPlugin/` — plugin de ejemplo, probablemente no usado.
- `CHANGELOG.md`, `CURRENT_STATE.md`, `LICENSE`, `.env` — archivos en la raíz que deberían estar en `docs/`.

---

## 6. Configuraciones Repetidas, Clases Grandes, Módulos Fusionables

### 6.1 Archivos de Configuración Duplicados

| Archivo | Contenido |
|---|---|
| `bootstrap.json` | Configuración bootstrap (JSON) |
| `bootstrap.yaml` | Misma configuración en YAML |
| `Hermes.config.json` | Configuración principal de Hermes |
| `configuracion/bootstrap.enterprise.json` | Bootstrap en subdirectorio |
| `configuracion/kernel.enterprise.json` | Config kernel en subdirectorio |
| `motor/configuracion/` vs `motor/config/` | Dos módulos de configuración |

### 6.2 Clases Grandes Identificadas

| Archivo | Líneas | Problema |
|---|---|---|
| `motor/bootstrap/Start-HermesProject.ps1` | ~400+ | Orquestador monolítico con demasiadas responsabilidades. |
| `motor/bootstrap/engine/BootstrapOrchestrator.ps1` | ~200+ | Lógica de bootstrap mezclada con UI (wizard). |
| `motor/bootstrap/engine/BootstrapWizard.ps1` | ~300+ | UI del wizard + lógica de estado. |

### 6.3 Módulos Fusionables

| Módulos | Razón |
|---|---|
| `motor/dependencias/DependencyInjection.ps1` + `ServiceLocator.ps1` | El ServiceLocator es una fachada de 3 líneas. Fusionar en uno. |
| `motor/kernel/Core/EventBus.ps1` + `motor/eventos/EventBus.ps1` | Elegir uno (el funcional es más completo). |
| `motor/kernel/Core/ServiceContainer.ps1` + `motor/dependencias/` | Elegir uno (el funcional tiene más features). |
| `motor/bootstrap/Git.ps1` + `motor/bootstrap/functions/Git.ps1` | Fusionar en un solo módulo Git. |
| `tools/Observabilidad.ps1` + `motor/tools/Observabilidad.ps1` | Fusionar en motor/tools/. |
| `motor/configuracion/` + `motor/config/` | Unificar en motor/config/. |

---

## 7. Riesgos de Mantenimiento

| Riesgo | Impacto | Probabilidad |
|---|---|---|
| **Dos kernels paralelos (funcional vs clases)** | Alto — cualquier cambio rompe el otro | Alta |
| **Sin pruebas automatizadas** | Alto — no hay red de seguridad | Alta |
| **Código muerto no identificado** | Medio — confunde a nuevos desarrolladores | Alta |
| **Múltiples archivos de configuración** | Medio — config duplicada con valores inconsistentes | Media |
| **Directorios vacíos** | Bajo — ruido visual | Alta |
| **Sin CI/CD pipeline** | Alto — no hay validación automática | Alta |
| **Azure vestigial** | Bajo — código que nadie mantiene | Media |
| **Stubs de GitHub sin implementar** | Medio — funcionalidad prometida pero no entregada | Alta |

---

## 8. Propuesta de Arquitectura Más Simple

### Estructura Objetivo (simplificada ~60% menos carpetas)

```
HERMES-ENTERPRISE/
├── bootstrap.json                 # Único archivo de configuración
├── CLINE.md                       # Reglas de trabajo
├── AUDIT_REPORT.md                # Este informe
├── motor/
│   ├── kernel/
│   │   ├── Kernel.ps1             # Único kernel (elegir el funcional)
│   │   ├── Core/
│   │   │   ├── EventBus.ps1       # Solo UN EventBus
│   │   │   ├── ServiceContainer.ps1  # Solo UN DI
│   │   │   └── ComponentRegistry.ps1
│   │   └── logging/
│   │       └── Logger.ps1
│   ├── bootstrap/
│   │   ├── Start-HermesProject.ps1
│   │   ├── engine/
│   │   │   ├── BootstrapOrchestrator.ps1
│   │   │   └── BootstrapState.ps1
│   │   └── functions/
│   │       └── Git.ps1            # Único módulo Git
│   ├── tools/
│   │   └── Observabilidad.ps1     # Único archivo de observabilidad
│   └── config/
│       └── ConfigurationManager.ps1  # Único gestor de configuración
├── pruebas/
│   ├── unitarias/
│   ├── integracion/
│   └── aceptacion/
├── reports/                       # Solo reportes generados activamente
├── docs/
│   ├── adr/
│   ├── ARCHITECTURE_DECISIONS.md
│   ├── CHANGELOG.md
│   └── README.md
├── sandbox/                       # Un solo directorio de sandbox, limpio al empezar
└── plugins/
    └── HelloPlugin/
```

### Acciones Inmediatas (Prioridad)

| # | Acción | Dificultad |
|---|---|---|
| 1 | **Eliminar** todos los `.gitkeep` de directorios vacíos. | Baja |
| 2 | **Eliminar** `tools/LoadConfiguration.ps1`, `tools/GenerateIntegrityReport.ps1`, `hello.ps1`, `Patch-Hermes-AzureTrace.ps1`, `tools/EnterprisePipeline.ps1`. | Baja |
| 3 | **Fusionar** los 2 EventBus en 1 (elegir el funcional de `motor/eventos/`). | Media |
| 4 | **Fusionar** los 2 ServiceContainer/DI en 1 (elegir el funcional de `motor/dependencias/`). | Media |
| 5 | **Fusionar** los 2 módulos Git en 1. | Baja |
| 6 | **Fusionar** los 2 Observabilidad en 1 (quedarse con `motor/tools/`). | Baja |
| 7 | **Unificar** configuración: eliminar `configuracion/`, `motor/config/`, `bootstrap.yaml`, consolidar en `Hermes.config.json`. | Media |
| 8 | **Eliminar** `motor/kernel/Core/` si se elige el kernel funcional (o viceversa). | Alta |
| 9 | **Eliminar** `motor/providers/azure/`, `motor/security/`, `motor/validation/`, `motor/scheduler/`, `motor/dependencygraph/`, `motor/discovery/` si no tienen implementación real. | Media |
| 10 | **Eliminar** sandboxes de prueba (conservar solo 1 activo). | Baja |
| 11 | **Agregar** CI/CD con GitHub Actions + Pester. | Alta |
| 12 | **Refactorizar** `Start-HermesProject.ps1` para separar UI de lógica de bootstrap. | Alta |

---

## 9. Hoja de Ruta de Refactorización

### Fase 1 — Limpieza Rápida (1-2 días)
- [ ] Eliminar `.gitkeep` y directorios vacíos
- [ ] Eliminar scripts muertos (tools/, hello.ps1, Patch-Hermes-AzureTrace.ps1)
- [ ] Eliminar sandboxes no utilizados
- [ ] Eliminar backups huérfanos
- [ ] Unificar archivos de configuración

### Fase 2 — Unificación de Kernels (2-3 días)
- [ ] Decidir: kernel funcional (`Kernel.ps1`) vs kernel clases (`KernelHost.ps1`)
- [ ] Eliminar el kernel no seleccionado
- [ ] Fusionar EventBus, ServiceContainer, ComponentRegistry en el kernel elegido

### Fase 3 — Consolidación de Módulos (2-3 días)
- [ ] Fusionar módulos Git
- [ ] Fusionar Observabilidad
- [ ] Fusionar configuración
- [ ] Eliminar ServiceLocator (innecesario)

### Fase 4 — Pruebas y CI/CD (3-5 días)
- [ ] Escribir pruebas Pester para cada módulo core
- [ ] Configurar GitHub Actions para ejecutar pruebas en cada push
- [ ] Agregar análisis estático (PSScriptAnalyzer)

### Fase 5 — Documentación y Cierre (1 día)
- [ ] Actualizar README.md con nueva estructura
- [ ] Documentar decisiones arquitectónicas en ADR
- [ ] Cerrar issues de deuda técnica