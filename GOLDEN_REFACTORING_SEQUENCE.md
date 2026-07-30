# GOLDEN REFACTORING SEQUENCE
## Hermes Enterprise — RC13.1
## Engineering Execution Blueprint

**Documento:** GOLDEN_REFACTORING_SEQUENCE.md  
**Versión:** 1.0  
**Autor:** Principal Software Architect  
**Audiencia:** Architecture Review Board / Engineering Team  
**Fuente de verdad:** CLINE.md + MASTER_REFACTORING_ROADMAP.md  
**Aprobación requerida:** Humana, antes del Commit 001

---

## Tabla de Contenidos

1. [Estrategia General](#1-estrategia-general)
2. [Plan por Sprint](#2-plan-por-sprint)
3. [Plan por Commit (001–078)](#3-plan-por-commit-001078)
4. [Orden Exacto de Ejecución](#4-orden-exacto-de-ejecución)
5. [Validaciones Post-Commit](#5-validaciones-post-commit)
6. [Compatibilidad por Etapa](#6-compatibilidad-por-etapa)
7. [Riesgos por Sprint](#7-riesgos-por-sprint)
8. [Automatización](#8-automatización)
9. [Puntos de Control por Sprint](#9-puntos-de-control-por-sprint)
10. [Criterio de Finalización](#10-criterio-de-finalización)

---

## 1. Estrategia General

### 1.1 Principio Rector

La refactorización sigue el principio de **"Superficie Estable, Interior Cambiante"** :

1. **Nunca** se rompe la interfaz externa del proyecto (`Start-HermesProject.ps1`, la raíz del repositorio)
2. **Siempre** se mantiene el proyecto funcional tras cada commit
3. **Primero** se limpia (eliminar lo que sobra), **luego** se consolida (unificar lo duplicado), **luego** se reestructura (refactorizar lo que queda)

### 1.2 Justificación del Orden

| Principio | Justificación |
|---|---|
| **Limpieza primero (F0-F1)** | Eliminar código muerto y módulos stub reduce el área de impacto de refactorizaciones posteriores. Si se refactoriza primero y luego se elimina, se desperdicia esfuerzo. |
| **Pruebas antes de refactorizar (F2)** | No se puede refactorizar sin red de seguridad. Las pruebas deben existir antes de tocar `Start-HermesProject.ps1`, `BootstrapOrchestrator.ps1`, etc. |
| **CI/CD antes de refactorizar (F2)** | La validación automática detecta regresiones al instante. Sin CI/CD, cada commit requiere validación manual, lo que ralentiza y aumenta el riesgo. |
| **Consolidación de kernels (F1) antes que todo** | Mantener dos kernels duplicados significa que cualquier cambio arquitectónico debe considerar ambos. Eliminar uno reduce el área de impacto a la mitad. |
| **Refactorización mayor al final (F3)** | `Start-HermesProject.ps1` y `BootstrapOrchestrator.ps1` son los archivos más grandes y riesgosos. Se refactorizan solo cuando ya hay pruebas y CI/CD. |
| **Nomenclatura al final (F4)** | Cambiar nombres después de toda la reestructuración evita tener que renombrar dos veces lo mismo. |

### 1.3 Minimización de Conflictos Git

| Estrategia | Explicación |
|---|---|
| **Commits atómicos** | Cada commit toca un solo archivo o un grupo lógico pequeño. Esto minimiza conflictos de merge. |
| **Eliminaciones antes que modificaciones** | Eliminar archivos primero evita que Git tenga que rastrear cambios en archivos que luego se eliminan. |
| **Un archivo por commit (cuando sea posible)** | Facilita revertir cambios individuales sin afectar otros. |
| **Branch por Sprint** | Cada Sprint tiene su propia rama. Los merges a `main` se hacen al final de cada Sprint con PR y revisión. |

### 1.4 Minimización de Regresiones

| Estrategia | Explicación |
|---|---|
| **Validación post-commit** | Después de cada commit se ejecuta la validación correspondiente (ver sección 5). |
| **Snapshot pre-cambio** | Antes de empezar la Fase 0, se crea el tag `rc13-pre-refactor`. |
| **Rollback inmediato** | Si una validación falla, se revierte el commit antes de continuar. |
| **Pruebas primero** | Los módulos core tienen pruebas antes de ser modificados. |

### 1.5 Mantener el Proyecto Funcional

| Período | Estado del proyecto |
|---|---|
| F0 (Prep) | Funcional — solo se eliminan .gitkeep y sandboxes |
| F1 (Limpieza) | Funcional — se elimina código muerto y módulos stub no referenciados. Kernel.ps1 sigue intacto. |
| F2 (Consolidación) | Funcional — se agregan pruebas, CI/CD, se fusionan duplicados. La API pública no cambia. |
| F3 (Arquitectura) | Puede tener inestabilidad temporal durante los refactors de Start-HermesProject. Se mitiga con ramas feature + PR. |
| F4 (Optimización) | Funcional — cambios cosméticos (nombres). |
| F5 (Hardening) | Funcional — solo se agregan validaciones. |

---

## 2. Plan por Sprint

### Sprint 0 — Preparación

| Campo | Valor |
|---|---|
| **ID** | S0 |
| **Objetivo** | Estabilizar el entorno y establecer líneas base. Crear snapshot de seguridad. |
| **Duración** | 0.5 días |
| **Entregables** | Tag `rc13-pre-refactor`, proyecto sin .gitkeep, proyecto sin sandboxes basura, kernel con try/catch |
| **Riesgos** | Mínimo |
| **Criterios de aceptación** | `git tag -l rc13-pre-refactor` existe; `grep -r "\.gitkeep" .` = 0; solo 1 sandbox activo |
| **Rollback** | `git checkout rc13-pre-refactor` (antes de empezar S1) |

### Sprint 1 — Limpieza Masiva

| Campo | Valor |
|---|---|
| **ID** | S1 |
| **Objetivo** | Eliminar todo el código muerto, módulos stub, Azure vestigial, configuración duplicada, reports obsoletos. Consolidar kernel único. |
| **Duración** | 2 días |
| **Entregables** | Proyecto reducido en ~50% de archivos. Un solo kernel. Un solo archivo de configuración. motor/ con solo 8 subdirectorios. |
| **Riesgos** | Medio — M-001 (kernel) y M-008 (config) pueden romper referencias |
| **Criterios de aceptación** | `Start-HermesProject.ps1` funciona; motor/ tiene solo 8 subdirectorios; Hermes.config.json es la única config |
| **Rollback** | `git revert <merge-commit>` de la rama S1 |

### Sprint 2 — Fundaciones de Calidad

| Campo | Valor |
|---|---|
| **ID** | S2 |
| **Objetivo** | Establecer pruebas Pester, CI/CD pipeline, fusionar todos los módulos duplicados (EventBus, DI, Git, Observabilidad). |
| **Duración** | 4 días |
| **Entregables** | 5+ tests Pester pasando; CI/CD pipeline en GitHub Actions; 1 EventBus; 1 DI; 1 Git; 1 Observabilidad; ServiceLocator eliminado |
| **Riesgos** | Medio — M-002 requiere conocimiento de Pester 5.x |
| **Criterios de aceptación** | `Invoke-Pester pruebas/unitarias/` = 100%; CI pipeline corre en cada push |
| **Rollback** | `git revert <merge-commit>` de la rama S2 |

### Sprint 3 — Arquitectura Core

| Campo | Valor |
|---|---|
| **ID** | S3 |
| **Objetivo** | Refactorizar Start-HermesProject.ps1, separar BootstrapOrchestrator de BootstrapWizard, eliminar paths hardcoded. |
| **Duración** | 5 días |
| **Entregables** | Entrypoint delgado (< 50 líneas); BootstrapEngine.ps1; VSCodeIntegration.ps1; Orchestrator sin UI; Wizard solo UI; 0 paths hardcoded |
| **Riesgos** | Alto — M-006 y M-007 son refactors grandes |
| **Criterios de aceptación** | `Start-HermesProject.ps1` funciona (mismo comportamiento); BootstrapEngine testeable sin UI; grep paths hardcoded = 0 |
| **Rollback** | `git revert <merge-commit>` + feature branch preservada |

### Sprint 4 — Optimización y Nomenclatura

| Campo | Valor |
|---|---|
| **ID** | S4 |
| **Objetivo** | Unificar nomenclatura español/inglés, mover archivos de raíz a docs/, pulir código. |
| **Duración** | 1 día |
| **Entregables** | Nomenclatura consistente en español; CHANGELOG.md/LICENSE/.env en docs/ |
| **Riesgos** | Medio — M-019 (nombres) rompe referencias temporalmente |
| **Criterios de aceptación** | Funciones con nombres consistentes; raíz limpia |
| **Rollback** | `git revert <commit>` |

### Sprint 5 — Hardening y Cierre

| Campo | Valor |
|---|---|
| **ID** | S5 |
| **Objetivo** | Agregar validaciones, timeouts, telemetría, PSScriptAnalyzer, verify.ps1, documentación. |
| **Duración** | 3 días |
| **Entregables** | verify.ps1; CI con lint; badges en README; documentación actualizada |
| **Riesgos** | Bajo |
| **Criterios de aceptación** | verify.ps1 pasa; PSScriptAnalyzer sin errores; README con badges |
| **Rollback** | `git revert <commit>` |

---

## 3. Plan por Commit (001–078)

Todos los commits siguen la convención:
```
refactor(módulo): descripción
fix(módulo): descripción  
test(módulo): descripción
docs(módulo): descripción
chore(módulo): descripción
```

---

### Fase 0 — Preparación (Commits 001–005)

#### Commit 001

| Campo | Valor |
|---|---|
| **ID** | 001 |
| **Nombre** | Crear tag de seguridad pre-refactor |
| **Descripción** | Crear tag git `rc13-pre-refactor` en el commit actual para poder revertir todo el proceso si es necesario. |
| **Archivos afectados** | Ninguno |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 1 minuto |
| **Complejidad** | Mínima |
| **Riesgo** | Nulo |
| **Rollback** | `git tag -d rc13-pre-refactor` |
| **Mensaje Git** | `chore(repo): tag rc13-pre-refactor snapshot before refactoring` |
| **Validación** | `git tag -l rc13-pre-refactor` |

#### Commit 002

| Campo | Valor |
|---|---|
| **ID** | 002 |
| **Nombre** | Eliminar todos los archivos .gitkeep |
| **Descripción** | Eliminar todos los archivos `.gitkeep` en directorios vacíos. Los directorios que queden vacíos se gestionan en commit posterior. |
| **Archivos afectados** | `agentes/.gitkeep`, `arquitectura/.gitkeep`, `herramientas/.gitkeep`, `memoria/.gitkeep`, `perfiles/.gitkeep`, `plantillas/.gitkeep`, `protocolos/.gitkeep`, `proveedores/.gitkeep`, `pruebas/.gitkeep`, `arquitectura/decisiones/.gitkeep`, `arquitectura/diagramas/.gitkeep`, `builders/.gitkeep`, `motor/.gitkeep`, `motor/bootstrap/engine/.gitkeep`, `motor/capabilities/.gitkeep`, `motor/config/.gitkeep`, `motor/configuracion/.gitkeep`, `motor/context/.gitkeep`, `motor/contracts/.gitkeep`, `motor/dependencias/.gitkeep`, `motor/dependencygraph/.gitkeep`, `motor/discovery/.gitkeep`, `motor/eventos/.gitkeep`, `motor/kernel/Core/descriptors/.gitkeep`, `motor/lifecycle/.gitkeep`, `motor/logging/.gitkeep`, `motor/manifest/.gitkeep`, `motor/observability/.gitkeep`, `motor/plugins/.gitkeep`, `motor/providers/.gitkeep`, `motor/providers/azure/.gitkeep`, `motor/registro/.gitkeep`, `motor/runtime/.gitkeep`, `motor/sandbox/.gitkeep`, `motor/scheduler/.gitkeep`, `motor/security/.gitkeep`, `motor/session/.gitkeep`, `motor/tools/.gitkeep`, `motor/validation/.gitkeep`, `motor/wizards/.gitkeep`, `pruebas/aceptacion/.gitkeep`, `pruebas/diagnostico/.gitkeep`, `pruebas/integracion/.gitkeep`, `pruebas/salida-temporal/.gitkeep`, `pruebas/unitarias/.gitkeep`, `reports/backups/.gitkeep`, `sandbox/artifacts/.gitkeep`, `sandbox/Local/.gitkeep` |
| **Directorios afectados** | ~20 directorios que pierden su .gitkeep |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 5 min |
| **Complejidad** | Mínima |
| **Riesgo** | Nulo |
| **Rollback** | `git revert 002` |
| **Mensaje Git** | `chore(repo): remove all .gitkeep files from empty directories` |
| **Validación** | `grep -r "\.gitkeep" .` devuelve vacío |

#### Commit 003

| Campo | Valor |
|---|---|
| **ID** | 003 |
| **Nombre** | Limpiar sandboxes de prueba |
| **Descripción** | Eliminar todos los sandboxes de prueba excepto `sandbox/` y mantener opcionalmente `sandbox/Local/` si tiene contenido útil. Eliminar `ProyectoTest025/` de la raíz. |
| **Archivos afectados** | Archivos dentro de `sandbox/ProyectoPrueba001/`, `sandbox/ProyectoTest001/` a `sandbox/ProyectoTest018/`, `sandbox/artifacts/`, `ProyectoTest025/` |
| **Directorios afectados** | `sandbox/ProyectoPrueba001/`, `sandbox/ProyectoTest001/` ... `sandbox/ProyectoTest018/` (~10 dirs), `ProyectoTest025/` |
| **Dependencias** | Commit 002 |
| **Tiempo estimado** | 10 min |
| **Complejidad** | Mínima |
| **Riesgo** | Nulo |
| **Rollback** | `git revert 003` |
| **Mensaje Git** | `chore(sandbox): remove all test sandbox projects` |
| **Validación** | `ls -d sandbox/*/` muestra solo sandbox/Local/; `ls ProyectoTest025/` falla |

#### Commit 004

| Campo | Valor |
|---|---|
| **ID** | 004 |
| **Nombre** | Limpiar reports de diagnóstico obsoletos |
| **Descripción** | Eliminar ~30 archivos de reports/ generados por scripts de diagnóstico único. Conservar solo: `BASELINE_GOLDEN_PATH.md`, `FileIndex.json`, `pester_result.xml`, `Test-ModuleValidation.ps1`, `ValidateCoreLoad.ps1`, `generate_forensic.ps1`. |
| **Archivos afectados** | ~30 archivos en `reports/` listados en M-018 del MASTER_REFACTORING_ROADMAP.md |
| **Directorios afectados** | `reports/` |
| **Dependencias** | Commit 002 |
| **Tiempo estimado** | 10 min |
| **Complejidad** | Mínima |
| **Riesgo** | Mínimo |
| **Rollback** | `git revert 004` |
| **Mensaje Git** | `chore(reports): remove stale diagnostic reports` |
| **Validación** | `ls reports/*.json` devuelve solo FileIndex.json |

#### Commit 005

| Campo | Valor |
|---|---|
| **ID** | 005 |
| **Nombre** | Agregar manejo de errores en kernel startup |
| **Descripción** | Agregar try/catch en `Start-HermesEnterpriseKernel` (Kernel.ps1). Cada creación de subsistema envuelta en try/catch individual. Logging de errores estructurado. |
| **Archivos afectados** | `motor/kernel/Kernel.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna (se puede hacer en paralelo a 001-004) |
| **Tiempo estimado** | 4h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 005` |
| **Mensaje Git** | `fix(kernel): add try-catch error handling in Start-HermesEnterpriseKernel` |
| **Validación** | Probar fallo forzado: pasar $null como KernelEnterprise, verificar que el error se registra y no es silencioso |

---

### Fase 1 — Limpieza (Commits 006–026)

#### Commit 006

| Campo | Valor |
|---|---|
| **ID** | 006 |
| **Nombre** | Eliminar Azure vestigial |
| **Descripción** | Eliminar `motor/providers/azure/` (2 archivos) y `Patch-Hermes-AzureTrace.ps1`. |
| **Archivos afectados** | `motor/providers/azure/AzureProviderAuthentication.ps1`, `motor/providers/azure/AzureResourceDiscovery.ps1`, `Patch-Hermes-AzureTrace.ps1` |
| **Directorios afectados** | `motor/providers/azure/`, `motor/providers/` (si queda vacío) |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 10 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo — verificar con `git grep -i "AzureProvider\|AzureResource\|Patch-Hermes-Azure"` que no hay referencias |
| **Rollback** | `git revert 006` |
| **Mensaje Git** | `chore(azure): remove vestigial Azure provider code` |
| **Validación** | `grep -r "AzureProviderAuthentication\|AzureResourceDiscovery\|Patch-Hermes-AzureTrace" .` = vacío |

#### Commit 007

| Campo | Valor |
|---|---|
| **ID** | 007 |
| **Nombre** | Eliminar módulos stub — parte 1: seguridad, validación, scheduler |
| **Descripción** | Eliminar directorios `motor/security/`, `motor/validation/`, `motor/scheduler/` con todo su contenido. |
| **Archivos afectados** | Archivos dentro de esos directorios |
| **Directorios afectados** | `motor/security/`, `motor/validation/`, `motor/scheduler/` |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 10 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo — verificar con `git grep` que ningún script referencia estos módulos |
| **Rollback** | `git revert 007` |
| **Mensaje Git** | `refactor(motor): remove stub modules: security, validation, scheduler` |
| **Validación** | `ls motor/security/ motor/validation/ motor/scheduler/` devuelve "No such file or directory" |

#### Commit 008

| Campo | Valor |
|---|---|
| **ID** | 008 |
| **Nombre** | Eliminar módulos stub — parte 2: dependencygraph, discovery, providers |
| **Descripción** | Eliminar `motor/dependencygraph/`, `motor/discovery/`, `motor/providers/`. |
| **Archivos afectados** | Archivos dentro de esos directorios |
| **Directorios afectados** | `motor/dependencygraph/`, `motor/discovery/`, `motor/providers/` |
| **Dependencias** | Commit 006 (Azure vestigial eliminado primero para evitar conflictos) |
| **Tiempo estimado** | 10 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 008` |
| **Mensaje Git** | `refactor(motor): remove stub modules: dependencygraph, discovery, providers` |
| **Validación** | `ls motor/dependencygraph/ motor/discovery/ motor/providers/` falla |

#### Commit 009

| Campo | Valor |
|---|---|
| **ID** | 009 |
| **Nombre** | Eliminar módulos stub — parte 3: plugins, registro, lifecycle |
| **Descripción** | Eliminar `motor/plugins/`, `motor/registro/`, `motor/lifecycle/`. |
| **Archivos afectados** | Archivos dentro de esos directorios |
| **Directorios afectados** | `motor/plugins/`, `motor/registro/`, `motor/lifecycle/` |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 5 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 009` |
| **Mensaje Git** | `refactor(motor): remove stub modules: plugins, registro, lifecycle` |
| **Validación** | Directorios no existen |

#### Commit 010

| Campo | Valor |
|---|---|
| **ID** | 010 |
| **Nombre** | Eliminar módulos stub — parte 4: contracts, capabilities, observability |
| **Descripción** | Eliminar `motor/contracts/`, `motor/capabilities/`, `motor/observability/`. |
| **Archivos afectados** | Archivos dentro de esos directorios |
| **Directorios afectados** | `motor/contracts/`, `motor/capabilities/`, `motor/observability/` |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 5 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 010` |
| **Mensaje Git** | `refactor(motor): remove stub modules: contracts, capabilities, observability` |
| **Validación** | Directorios no existen |

#### Commit 011

| Campo | Valor |
|---|---|
| **ID** | 011 |
| **Nombre** | Eliminar módulos stub — parte 5: manifest, wizards, sandbox, session, context |
| **Descripción** | Eliminar `motor/manifest/`, `motor/wizards/`, `motor/sandbox/`, `motor/session/`, `motor/context/`. |
| **Archivos afectados** | Archivos dentro de esos directorios |
| **Directorios afectados** | `motor/manifest/`, `motor/wizards/`, `motor/sandbox/`, `motor/session/`, `motor/context/` |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 5 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 011` |
| **Mensaje Git** | `refactor(motor): remove stub modules: manifest, wizards, sandbox, session, context` |
| **Validación** | Directorios no existen |

#### Commit 012

| Campo | Valor |
|---|---|
| **ID** | 012 |
| **Nombre** | Eliminar código muerto — scripts no referenciados |
| **Descripción** | Eliminar `tools/LoadConfiguration.ps1`, `tools/GenerateIntegrityReport.ps1`, `hello.ps1`, `tools/EnterprisePipeline.ps1`, `tools/HermesPathResolver.psm1`. |
| **Archivos afectados** | `tools/LoadConfiguration.ps1`, `tools/GenerateIntegrityReport.ps1`, `hello.ps1`, `tools/EnterprisePipeline.ps1`, `tools/HermesPathResolver.psm1` |
| **Directorios afectados** | `tools/` |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 10 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo — verificar referencias cruzadas con `git grep` |
| **Rollback** | `git revert 012` |
| **Mensaje Git** | `refactor(tools): remove unreferenced scripts` |
| **Validación** | `grep -r "LoadConfiguration\|GenerateIntegrityReport\|EnterprisePipeline\|HermesPathResolver" --include="*.ps1" .` = solo Start-HermesProject.ps1 (si referencia, actualizar antes) |

#### Commit 013

| Campo | Valor |
|---|---|
| **ID** | 013 |
| **Nombre** | Eliminar código muerto — builders y backup |
| **Descripción** | Eliminar `builders/` completo y `reports/backups/WorkspaceResolver.psm1.bak`. |
| **Archivos afectados** | `builders/DocumentBuilder.ps1`, `builders/DocumentMetadata.ps1`, `builders/MarkdownUtilities.ps1`, `reports/backups/WorkspaceResolver.psm1.bak` |
| **Directorios afectados** | `builders/`, `reports/backups/` |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 5 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 013` |
| **Mensaje Git** | `refactor(builders): remove unused builders and backup files` |
| **Validación** | `ls builders/ reports/backups/` falla |

#### Commit 014

| Campo | Valor |
|---|---|
| **ID** | 014 |
| **Nombre** | Eliminar código muerto — GitHub stub y HelloPlugin |
| **Descripción** | Eliminar `motor/bootstrap/GitHub.ps1`, `plugins/HelloPlugin/`. |
| **Archivos afectados** | `motor/bootstrap/GitHub.ps1`, archivos en `plugins/HelloPlugin/` |
| **Directorios afectados** | `plugins/HelloPlugin/` |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 5 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 014` |
| **Mensaje Git** | `refactor(plugins): remove GitHub stub and HelloPlugin demo` |
| **Validación** | `ls plugins/` vacío |

#### Commit 015

| Campo | Valor |
|---|---|
| **ID** | 015 |
| **Nombre** | Consolidar kernel único — eliminar Core/ |
| **Descripción** | Eliminar `motor/kernel/Core/` completo. El kernel funcional (`Kernel.ps1`) queda como único kernel. Antes de eliminar, extraer el patrón de ciclo de vida (Initialize→Validate→Start) de `KernelHost.ps1` si tiene valor e integrarlo en `Kernel.ps1`. |
| **Archivos afectados** | `motor/kernel/Core/KernelHost.ps1`, `motor/kernel/Core/ServiceContainer.ps1`, `motor/kernel/Core/EventBus.ps1`, `motor/kernel/Core/ComponentRegistry.ps1`, `motor/kernel/Core/BootLoader.ps1`, `motor/kernel/Core/run_mission_bootstrap.ps1`, `motor/kernel/Core/descriptors/DummyComponent.json` |
| **Directorios afectados** | `motor/kernel/Core/` (completo), `motor/kernel/Core/descriptors/` |
| **Dependencias** | Commits 002–014 |
| **Tiempo estimado** | 4h |
| **Complejidad** | Media |
| **Riesgo** | Medio — validar que Kernel.ps1 funciona standalone antes y después |
| **Rollback** | `git revert 015` |
| **Mensaje Git** | `refactor(kernel): remove KernelHost class-based kernel, keep functional Kernel.ps1` |
| **Validación** | `. motor/kernel/Kernel.ps1; $k = New-HermesEnterpriseKernel -ContextoKernel ([pscustomobject]@{...}); Start-HermesEnterpriseKernel -KernelEnterprise $k` funciona |

#### Commit 016

| Campo | Valor |
|---|---|
| **ID** | 016 |
| **Nombre** | Fusionar módulos Git |
| **Descripción** | Combinar `motor/bootstrap/Git.ps1` y `motor/bootstrap/functions/Git.ps1` en `motor/bootstrap/functions/Git.ps1`. Agregar funciones faltantes de Git.ps1 (10 líneas) a functions/Git.ps1. Eliminar `motor/bootstrap/Git.ps1`. |
| **Archivos afectados** | `motor/bootstrap/Git.ps1` (eliminar), `motor/bootstrap/functions/Git.ps1` (modificar) |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 30 min |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 016` |
| **Mensaje Git** | `refactor(git): merge duplicate Git modules into functions/Git.ps1` |
| **Validación** | `. motor/bootstrap/functions/Git.ps1; Get-GitStatusPorcelain; Test-GitInstallation` funcionan |

#### Commit 017

| Campo | Valor |
|---|---|
| **ID** | 017 |
| **Nombre** | Fusionar Observabilidad |
| **Descripción** | Eliminar `tools/Observabilidad.ps1` (vestigial). La versión en `motor/tools/Observabilidad.ps1` es la que sobrevive. |
| **Archivos afectados** | `tools/Observabilidad.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 10 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo — verificar que ningún dot-source referencia `tools/Observabilidad.ps1` |
| **Rollback** | `git revert 017` |
| **Mensaje Git** | `refactor(observability): remove vestigial Observabilidad from tools/` |
| **Validación** | `grep -r "tools/Observabilidad\|\.\..\\tools\\Observabilidad" --include="*.ps1" .` = vacío |

#### Commit 018

| Campo | Valor |
|---|---|
| **ID** | 018 |
| **Nombre** | Unificar configuración — eliminar bootstrap.yaml |
| **Descripción** | Eliminar `bootstrap.yaml`. La configuración YAML es redundante con `bootstrap.json`. |
| **Archivos afectados** | `bootstrap.yaml` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 5 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 018` |
| **Mensaje Git** | `refactor(config): remove duplicate bootstrap.yaml, keep JSON` |
| **Validación** | `ls bootstrap.yaml` falla |

#### Commit 019

| Campo | Valor |
|---|---|
| **ID** | 019 |
| **Nombre** | Unificar configuración — eliminar configuracion/ |
| **Descripción** | Eliminar `configuracion/` completo (`bootstrap.enterprise.json` y `kernel.enterprise.json`). Migrar cualquier contenido necesario a `Hermes.config.json`. |
| **Archivos afectados** | `configuracion/bootstrap.enterprise.json`, `configuracion/kernel.enterprise.json` |
| **Directorios afectados** | `configuracion/` |
| **Dependencias** | Commits 002–014 |
| **Tiempo estimado** | 30 min |
| **Complejidad** | Baja |
| **Riesgo** | Bajo — verificar que ningún script referencia estas rutas |
| **Rollback** | `git revert 019` |
| **Mensaje Git** | `refactor(config): remove configuracion/ directory, consolidate into Hermes.config.json` |
| **Validación** | `ls configuracion/` falla; `Get-Content Hermes.config.json` contiene la config correcta |

#### Commit 020

| Campo | Valor |
|---|---|
| **ID** | 020 |
| **Nombre** | Unificar configuración — eliminar motor/config/ |
| **Descripción** | Eliminar `motor/config/Configuration.psm1` (stub de 12 líneas). Unificar con `motor/configuracion/ConfigurationManager.ps1`. |
| **Archivos afectados** | `motor/config/Configuration.psm1`, `motor/configuracion/ConfigurationManager.ps1` (mover a motor/config/) |
| **Directorios afectados** | `motor/config/` (fusionar con motor/configuracion/) |
| **Dependencias** | Commit 019 |
| **Tiempo estimado** | 30 min |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 020` |
| **Mensaje Git** | `refactor(config): merge motor/config/ into motor/configuracion/` |
| **Validación** | `. motor/configuracion/ConfigurationManager.ps1` funciona |

#### Commit 021

| Campo | Valor |
|---|---|
| **ID** | 021 |
| **Nombre** | Mover CHANGELOG.md a docs/ |
| **Descripción** | Mover `CHANGELOG.md` de la raíz a `docs/CHANGELOG.md`. |
| **Archivos afectados** | `CHANGELOG.md` → `docs/CHANGELOG.md` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 5 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 021` |
| **Mensaje Git**** | `docs(repo): move CHANGELOG.md to docs/` |
| **Validación** | `ls CHANGELOG.md` falla; `ls docs/CHANGELOG.md` existe |

#### Commit 022

| Campo | Valor |
|---|---|
| **ID** | 022 |
| **Nombre** | Mover LICENSE a docs/ |
| **Descripción** | Mover `LICENSE` de la raíz a `docs/LICENSE`. |
| **Archivos afectados** | `LICENSE` → `docs/LICENSE` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 2 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 022` |
| **Mensaje Git** | `docs(repo): move LICENSE to docs/` |
| **Validación** | `ls LICENSE` falla; `ls docs/LICENSE` existe |

#### Commit 023

| Campo | Valor |
|---|---|
| **ID** | 023 |
| **Nombre** | Mover .env a docs/ |
| **Descripción** | Mover `.env` de la raíz a `docs/.env` (como template de ejemplo). |
| **Archivos afectados** | `.env` → `docs/.env.example` (renombrar para evitar que se cargue automáticamente) |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 2 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 023` |
| **Mensaje Git** | `docs(repo): move .env to docs/.env.example` |
| **Validación** | `ls .env` falla; `ls docs/.env.example` existe |

#### Commit 024

| Campo | Valor |
|---|---|
| **ID** | 024 |
| **Nombre** | Eliminar directorios vacíos post-limpieza |
| **Descripción** | Eliminar directorios que quedaron vacíos tras eliminar .gitkeep y código muerto: `agentes/`, `arquitectura/`, `herramientas/`, `memoria/`, `perfiles/`, `plantillas/`, `protocolos/`, `proveedores/`, `pruebas/aceptacion/`, `pruebas/integracion/`, `pruebas/diagnostico/`, `pruebas/salida-temporal/`. |
| **Archivos afectados** | Ninguno |
| **Directorios afectados** | ~12 directorios vacíos |
| **Dependencias** | Commits 002, 012, 013, 014 |
| **Tiempo estimado** | 5 min |
| **Complejidad** | Mínima |
| **Riesgo** | Nulo |
| **Rollback** | `git revert 024` |
| **Mensaje Git** | `chore(repo): remove empty directories after cleanup` |
| **Validación** | Verificar que los directorios no existen |

#### Commit 025

| Campo | Valor |
|---|---|
| **ID** | 025 |
| **Nombre** | Fusionar DI containers — eliminar ServiceContainer (clases) |
| **Descripción** | Eliminar `motor/kernel/Core/ServiceContainer.ps1` (ya debería haberse eliminado en 015, verificar). |
| **Archivos afectados** | Verificar que no existe |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 015 |
| **Tiempo estimado** | 5 min |
| **Complejidad** | Mínima |
| **Riesgo** | Nulo |
| **Rollback** | N/A (ya eliminado en 015) |
| **Mensaje Git** | `refactor(di): verify ServiceContainer removed in kernel cleanup` |
| **Validación** | `ls motor/kernel/Core/ServiceContainer.ps1` falla |

#### Commit 026

| Campo | Valor |
|---|---|
| **ID** | 026 |
| **Nombre** | Fusionar DI containers — eliminar ServiceLocator |
| **Descripción** | Eliminar `motor/dependencias/ServiceLocator.ps1`. Migrar cualquier referencia de `Get-HermesEnterpriseService` a `Resolve-HermesEnterpriseService`. |
| **Archivos afectados** | `motor/dependencias/ServiceLocator.ps1` (eliminar), archivos que usen `Get-HermesEnterpriseService` (modificar) |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commits 001–024 |
| **Tiempo estimado** | 30 min |
| **Complejidad** | Baja |
| **Riesgo** | Bajo — requiere grep y actualización de referencias |
| **Rollback** | `git revert 026` |
| **Mensaje Git** | `refactor(di): remove ServiceLocator anti-pattern, use DI directly` |
| **Validación** | `grep -r "Get-HermesEnterpriseService\|ServiceLocator" --include="*.ps1" .` = vacío |

---

### Fase 2 — Consolidación (Commits 027–042)

#### Commit 027

| Campo | Valor |
|---|---|
| **ID** | 027 |
| **Nombre** | Crear estructura de pruebas unitarias Pester |
| **Descripción** | Crear carpeta `pruebas/unitarias/` (si no existe) y agregar `pruebas/unitarias/Test-Kernel.ps1` con tests básicos para `New-HermesEnterpriseKernel` y `Start-HermesEnterpriseKernel`. Usar Pester 5.x con `BeforeAll`, `Mock`, `Assert-MockCalled`. |
| **Archivos afectados** | Nuevo: `pruebas/unitarias/Test-Kernel.ps1` |
| **Directorios afectados** | `pruebas/unitarias/` |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 4h |
| **Complejidad** | Media |
| **Riesgo** | Bajo — solo agrega archivos nuevos |
| **Rollback** | `git revert 027` |
| **Mensaje Git** | `test(kernel): add Pester tests for Kernel.ps1` |
| **Validación** | `Invoke-Pester pruebas/unitarias/Test-Kernel.ps1` pasa |

#### Commit 028

| Campo | Valor |
|---|---|
| **ID** | 028 |
| **Nombre** | Agregar tests para EventBus |
| **Descripción** | Crear `pruebas/unitarias/Test-EventBus.ps1` con tests para `Subscribe-HermesEnterpriseEvent`, `Publish-HermesEnterpriseEvent`, `New-HermesEnterpriseEventBus`. |
| **Archivos afectados** | Nuevo: `pruebas/unitarias/Test-EventBus.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 027 (estructura de pruebas) |
| **Tiempo estimado** | 2h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 028` |
| **Mensaje Git** | `test(eventbus): add Pester tests for EventBus` |
| **Validación** | `Invoke-Pester pruebas/unitarias/Test-EventBus.ps1` pasa |

#### Commit 029

| Campo | Valor |
|---|---|
| **ID** | 029 |
| **Nombre** | Agregar tests para Logger |
| **Descripción** | Crear `pruebas/unitarias/Test-Logger.ps1` con tests para `New-HermesEnterpriseLogger` y `Write-HermesEnterpriseLogEvent`. |
| **Archivos afectados** | Nuevo: `pruebas/unitarias/Test-Logger.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 027 |
| **Tiempo estimado** | 1h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 029` |
| **Mensaje Git** | `test(logger): add Pester tests for Logger` |
| **Validación** | `Invoke-Pester pruebas/unitarias/Test-Logger.ps1` pasa |

#### Commit 030

| Campo | Valor |
|---|---|
| **ID** | 030 |
| **Nombre** | Agregar tests para ConfigurationManager |
| **Descripción** | Crear `pruebas/unitarias/Test-ConfigurationManager.ps1` con tests para `New-HermesEnterpriseConfigurationManager` y `Get-HermesEnterpriseConfiguration`. |
| **Archivos afectados** | Nuevo: `pruebas/unitarias/Test-ConfigurationManager.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 027 |
| **Tiempo estimado** | 1h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 030` |
| **Mensaje Git** | `test(config): add Pester tests for ConfigurationManager` |
| **Validación** | `Invoke-Pester pruebas/unitarias/Test-ConfigurationManager.ps1` pasa |

#### Commit 031

| Campo | Valor |
|---|---|
| **ID** | 031 |
| **Nombre** | Agregar tests para DependencyInjection |
| **Descripción** | Crear `pruebas/unitarias/Test-DependencyInjection.ps1` con tests para `Register-HermesEnterpriseService` y `Resolve-HermesEnterpriseService`. |
| **Archivos afectados** | Nuevo: `pruebas/unitarias/Test-DependencyInjection.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 027 |
| **Tiempo estimado** | 1h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 031` |
| **Mensaje Git** | `test(di): add Pester tests for DependencyInjection` |
| **Validación** | `Invoke-Pester pruebas/unitarias/Test-DependencyInjection.ps1` pasa |

#### Commit 032

| Campo | Valor |
|---|---|
| **ID** | 032 |
| **Nombre** | Agregar tests para Git |
| **Descripción** | Crear `pruebas/unitarias/Test-Git.ps1` con tests para `Test-GitInstallation`, `Get-CurrentBranch`, etc. |
| **Archivos afectados** | Nuevo: `pruebas/unitarias/Test-Git.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 027 |
| **Tiempo estimado** | 2h |
| **Complejidad** | Media |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 032` |
| **Mensaje Git** | `test(git): add Pester tests for Git module` |
| **Validación** | `Invoke-Pester pruebas/unitarias/Test-Git.ps1` pasa |

#### Commit 033

| Campo | Valor |
|---|---|
| **ID** | 033 |
| **Nombre** | Agregar tests para Observabilidad |
| **Descripción** | Crear `pruebas/unitarias/Test-Observabilidad.ps1` con tests para `Start-EventBus`, `Write-HermesLog`, `Escribir-ProgresoHermes`. |
| **Archivos afectados** | Nuevo: `pruebas/unitarias/Test-Observabilidad.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 027 |
| **Tiempo estimado** | 1h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 033` |
| **Mensaje Git** | `test(observability): add Pester tests for Observabilidad` |
| **Validación** | `Invoke-Pester pruebas/unitarias/Test-Observabilidad.ps1` pasa |

#### Commit 034

| Campo | Valor |
|---|---|
| **ID** | 034 |
| **Nombre** | Agregar tests para Runtime |
| **Descripción** | Crear `pruebas/unitarias/Test-Runtime.ps1` con tests para `New-HermesEnterpriseRuntime`, `Start-HermesEnterpriseRuntime`, `Stop-HermesEnterpriseRuntime`. |
| **Archivos afectados** | Nuevo: `pruebas/unitarias/Test-Runtime.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 027 |
| **Tiempo estimado** | 2h |
| **Complejidad** | Media |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 034` |
| **Mensaje Git** | `test(runtime): add Pester tests for Runtime` |
| **Validación** | `Invoke-Pester pruebas/unitarias/Test-Runtime.ps1` pasa |

#### Commit 035

| Campo | Valor |
|---|---|
| **ID** | 035 |
| **Nombre** | Verificar que todos los tests pasan juntos |
| **Descripción** | Ejecutar `Invoke-Pester pruebas/unitarias/` completo. Ajustar cualquier test que falle. Este commit establece la línea base de pruebas. |
| **Archivos afectados** | Ajustes menores en tests si es necesario |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commits 027–034 |
| **Tiempo estimado** | 2h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 035` |
| **Mensaje Git** | `test(core): establish test baseline - all Pester tests passing` |
| **Validación** | `Invoke-Pester pruebas/unitarias/` = 100% |

#### Commit 036

| Campo | Valor |
|---|---|
| **ID** | 036 |
| **Nombre** | Crear CI/CD pipeline — GitHub Actions |
| **Descripción** | Crear `.github/workflows/ci.yml` con: checkout, instalar PowerShell 7+, instalar Pester, ejecutar tests unitarios, PSScriptAnalyzer lint, validar carga de scripts principales. |
| **Archivos afectados** | Nuevo: `.github/workflows/ci.yml` |
| **Directorios afectados** | `.github/workflows/` |
| **Dependencias** | Commit 035 (tests pasando) |
| **Tiempo estimado** | 1 día |
| **Complejidad** | Media |
| **Riesgo** | Bajo — solo agrega archivo YAML |
| **Rollback** | `git revert 036` |
| **Mensaje Git**** | `ci(github): add GitHub Actions CI pipeline with Pester tests` |
| **Validación** | Push a GitHub → CI pipeline corre automáticamente → pasa |

#### Commit 037

| Campo | Valor |
|---|---|
| **ID** | 037 |
| **Nombre** | Fusionar EventBus duplicado |
| **Descripción** | Verificar que `motor/kernel/Core/EventBus.ps1` ya no existe (eliminado en 015). Confirmar que `motor/eventos/EventBus.ps1` es el único. Si hay código que referencia la clase EventBus, migrarlo a la API funcional. |
| **Archivos afectados** | Verificar que no hay referencias a la clase EventBus |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 015 |
| **Tiempo estimado** | 1h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | N/A (ya eliminado) |
| **Mensaje Git** | `refactor(eventbus): verify single EventBus after kernel cleanup` |
| **Validación** | `grep -r "class EventBus\|EventBus::" --include="*.ps1" .` = vacío |

#### Commit 038

| Campo | Valor |
|---|---|
| **ID** | 038 |
| **Nombre** | Fusionar DI — verificar single container |
| **Descripción** | Verificar que solo existe `motor/dependencias/DependencyInjection.ps1` como implementación de DI. |
| **Archivos afectados** | Ninguno (verificación) |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commits 025, 026 |
| **Tiempo estimado** | 30 min |
| **Complejidad** | Mínima |
| **Riesgo** | Nulo |
| **Rollback** | N/A |
| **Mensaje Git** | `refactor(di): verify single DI implementation` |
| **Validación** | `ls motor/dependencias/` contiene solo `DependencyInjection.ps1` |

#### Commit 039

| Campo | Valor |
|---|---|
| **ID** | 039 |
| **Nombre** | Verificar estructura motor/post-limpieza |
| **Descripción** | Verificar que `motor/` contiene solo 8 subdirectorios: `kernel`, `bootstrap`, `configuracion`, `eventos`, `dependencias`, `logging`, `runtime`, `tools`. |
| **Archivos afectados** | Ninguno |
| **Directorios afectados** | `motor/` |
| **Dependencias** | Todos los commits de F1 |
| **Tiempo estimado** | 15 min |
| **Complejidad** | Mínima |
| **Riesgo** | Nulo |
| **Rollback** | N/A |
| **Mensaje Git** | `chore(motor): verify clean structure - 8 remaining modules` |
| **Validación** | `ls -d motor/*/` devuelve exactamente 8 directorios |

---

### Fase 3 — Arquitectura (Commits 040–062)

#### Commit 040

| Campo | Valor |
|---|---|
| **ID** | 040 |
| **Nombre** | Eliminar paths hardcoded — búsqueda y reemplazo |
| **Descripción** | Buscar todos los paths absolutos (`D:/HERMES-ENTERPRISE`, `C:\`, etc.) en archivos .ps1. Reemplazar con `$PSScriptRoot`, `Split-Path -Parent $MyInvocation.MyCommand.Definition`, `Join-Path`. |
| **Archivos afectados** | Todos los .ps1 con paths hardcoded |
| **Directorios afectados** | Todo el proyecto |
| **Dependencias** | M-001 (kernel consolidado) |
| **Tiempo estimado** | 4h |
| **Complejidad** | Baja |
| **Riesgo** | Medio — un path mal reemplazado rompe carga de módulos |
| **Rollback** | `git revert 040` |
| **Mensaje Git** | `fix(repo): replace hardcoded paths with relative PSScriptRoot paths` |
| **Validación** | `grep -r "D:/\|C:/\|D:\\|C:\\" --include="*.ps1" .` = vacío |

#### Commit 041

| Campo | Valor |
|---|---|
| **ID** | 041 |
| **Nombre** | Refactor Start-HermesProject — extraer BootstrapEngine |
| **Descripción** | Extraer la lógica de bootstrap de `Start-HermesProject.ps1` (~400 líneas) a un nuevo archivo `motor/bootstrap/engine/BootstrapEngine.ps1`. Crear funciones: `New-BootstrapProject`, `Set-BootstrapGit`, `Invoke-BootstrapTests`, `New-BootstrapContext`. El entrypoint `Start-HermesProject.ps1` debe quedar como un delgado orquestador que valida parámetros y llama al engine. |
| **Archivos afectados** | `motor/bootstrap/Start-HermesProject.ps1` (modificar), nuevo: `motor/bootstrap/engine/BootstrapEngine.ps1` |
| **Directorios afectados** | `motor/bootstrap/engine/` |
| **Dependencias** | Commits 035 (tests), 036 (CI/CD) |
| **Tiempo estimado** | 1 día |
| **Complejidad** | Alta |
| **Riesgo** | Alto — refactorización significativa |
| **Rollback** | `git revert 041` |
| **Mensaje Git** | `refactor(bootstrap): extract BootstrapEngine from Start-HermesProject` |
| **Validación** | `Start-HermesProject -NombreProyecto "Test" -ProvisionTarget Local` funciona exactamente igual que antes |

#### Commit 042

| Campo | Valor |
|---|---|
| **ID** | 042 |
| **Nombre** | Refactor Start-HermesProject — agregar tests BootstrapEngine |
| **Descripción** | Crear `pruebas/unitarias/Test-BootstrapEngine.ps1` con tests para las nuevas funciones del engine. Usar Pester Mock para simular Git y filesystem. |
| **Archivos afectados** | Nuevo: `pruebas/unitarias/Test-BootstrapEngine.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 041 |
| **Tiempo estimado** | 4h |
| **Complejidad** | Media |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 042` |
| **Mensaje Git** | `test(bootstrap): add Pester tests for BootstrapEngine` |
| **Validación** | `Invoke-Pester pruebas/unitarias/Test-BootstrapEngine.ps1` pasa |

#### Commit 043

| Campo | Valor |
|---|---|
| **ID** | 043 |
| **Nombre** | Refactor Start-HermesProject — extraer VSCodeIntegration |
| **Descripción** | Extraer la lógica de integración con VSCode a `motor/bootstrap/integrations/VSCodeIntegration.ps1`. |
| **Archivos afectados** | `motor/bootstrap/Start-HermesProject.ps1` (modificar), nuevo: `motor/bootstrap/integrations/VSCodeIntegration.ps1` |
| **Directorios afectados** | `motor/bootstrap/integrations/` |
| **Dependencias** | Commit 041 |
| **Tiempo estimado** | 2h |
| **Complejidad** | Media |
| **Riesgo** | Medio |
| **Rollback** | `git revert 043` |
| **Mensaje Git** | `refactor(bootstrap): extract VSCodeIntegration from Start-HermesProject` |
| **Validación** | `Start-HermesProject -NombreProyecto "Test" -AbrirVSCode` funciona |

#### Commit 044

| Campo | Valor |
|---|---|
| **ID** | 044 |
| **Nombre** | Refactor Start-HermesProject — adelgazar entrypoint |
| **Descripción** | Reducir `motor/bootstrap/Start-HermesProject.ps1` a <50 líneas. Solo debe validar parámetros, crear contexto, llamar a `BootstrapEngine`, y opcionalmente a `VSCodeIntegration`. Mover cualquier otra lógica a los módulos correspondientes. |
| **Archivos afectados** | `motor/bootstrap/Start-HermesProject.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commits 041, 043 |
| **Tiempo estimado** | 2h |
| **Complejidad** | Media |
| **Riesgo** | Medio |
| **Rollback** | `git revert 044` |
| **Mensaje Git** | `refactor(bootstrap): thin Start-HermesProject entrypoint to <50 lines` |
| **Validación** | `Start-HermesProject` funciona idéntico; entrypoint < 50 líneas |

#### Commit 045

| Campo | Valor |
|---|---|
| **ID** | 045 |
| **Nombre** | Separar BootstrapOrchestrator — extraer lógica de estado |
| **Descripción** | Extraer la lógica de estado y transiciones de `BootstrapOrchestrator.ps1` (~200 líneas) en funciones puras. Dejar solo la orquestación (sin UI) en `BootstrapOrchestrator.ps1`. |
| **Archivos afectados** | `motor/bootstrap/engine/BootstrapOrchestrator.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commits 035, 036 |
| **Tiempo estimado** | 1 día |
| **Complejidad** | Alta |
| **Riesgo** | Alto |
| **Rollback** | `git revert 045` |
| **Mensaje Git** | `refactor(bootstrap): separate state logic from BootstrapOrchestrator` |
| **Validación** | Las funciones de estado se pueden llamar sin UI |

#### Commit 046

| Campo | Valor |
|---|---|
| **ID** | 046 |
| **Nombre** | Separar BootstrapOrchestrator — agregar tests |
| **Descripción** | Crear `pruebas/unitarias/Test-BootstrapOrchestrator.ps1` con tests para la lógica de orquestación ahora aislada. |
| **Archivos afectados** | Nuevo: `pruebas/unitarias/Test-BootstrapOrchestrator.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 045 |
| **Tiempo estimado** | 4h |
| **Complejidad** | Media |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 046` |
| **Mensaje Git** | `test(bootstrap): add Pester tests for BootstrapOrchestrator` |
| **Validación** | `Invoke-Pester pruebas/unitarias/Test-BootstrapOrchestrator.ps1` pasa |

#### Commit 047

| Campo | Valor |
|---|---|
| **ID** | 047 |
| **Nombre** | Separar BootstrapWizard — extraer UI pura |
| **Descripción** | Refactorizar `BootstrapWizard.ps1` (~300 líneas) para que **solo** contenga lógica de presentación (menús, colores, inputs). Toda la lógica de negocio debe estar en `BootstrapOrchestrator.ps1`. |
| **Archivos afectados** | `motor/bootstrap/engine/BootstrapWizard.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 045 |
| **Tiempo estimado** | 1 día |
| **Complejidad** | Alta |
| **Riesgo** | Alto |
| **Rollback** | `git revert 047` |
| **Mensaje Git** | `refactor(bootstrap): strip UI logic from BootstrapWizard, keep only presentation` |
| **Validación** | `BootstrapWizard.ps1` no contiene lógica de bootstrap; solo invoca funciones de `BootstrapOrchestrator.ps1` |

#### Commit 048

| Campo | Valor |
|---|---|
| **ID** | 048 |
| **Nombre** | Verificar integración bootstrap post-refactor |
| **Descripción** | Ejecutar el flujo completo: `Start-HermesProject.ps1` → BootstrapEngine → BootstrapOrchestrator → BootstrapWizard. Verificar que no hay regresiones. |
| **Archivos afectados** | Ninguno (validación manual) |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commits 041–047 |
| **Tiempo estimado** | 2h |
| **Complejidad** | Baja |
| **Riesgo** | Medio |
| **Rollback** | N/A (validación, no código) |
| **Mensaje Git** | `chore(bootstrap): verify full integration flow after refactor` |
| **Validación** | `Start-HermesProject.ps1` funciona de principio a fin |

---

### Fase 4 — Optimización (Commits 049–057)

#### Commits 049–057: Unificar nomenclatura español/inglés

| Commit | ID | Descripción | Archivos |
|---|---|---|---|
| 049 | M-019a | Renombrar EventBus → BusEventos en kernel | `motor/kernel/Kernel.ps1` |
| 050 | M-019b | Renombrar EventBus → BusEventos en eventos | `motor/eventos/EventBus.ps1` |
| 051 | M-019c | Renombrar Runtime → TiempoEjecucion (o mantener Runtime) | `motor/runtime/Runtime.ps1`, `motor/kernel/Kernel.ps1` |
| 052 | M-019d | Renombrar PluginManager → AdministradorPlugins | `motor/kernel/Kernel.ps1` |
| 053 | M-019e | Renombrar Logger → Registrador | `motor/logging/Logger.ps1`, `motor/kernel/Kernel.ps1` |
| 054 | M-019f | Renombrar EventBus → BusEventos en Observabilidad | `motor/tools/Observabilidad.ps1` |
| 055 | M-019g | Renombrar parámetros y variables internas | Archivos varios |
| 056 | M-019h | Verificar que todas las referencias están actualizadas | `grep -r` completo |
| 057 | M-019i | Ejecutar tests para verificar que no se rompió nada | `Invoke-Pester pruebas/unitarias/` |

**Riesgo total:** Medio  
**Rollback total:** `git revert 056` (revertir el último commit de renombrado, que incluye todos los anteriores si están squasheados)

---

### Fase 5 — Hardening (Commits 058–078)

#### Commit 058

| Campo | Valor |
|---|---|
| **ID** | 058 |
| **Nombre** | Agregar PSScriptAnalyzer al pipeline CI |
| **Descripción** | Modificar `.github/workflows/ci.yml` para ejecutar `Invoke-ScriptAnalyzer` en todos los .ps1 del proyecto. |
| **Archivos afectados** | `.github/workflows/ci.yml` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 036 |
| **Tiempo estimado** | 1h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 058` |
| **Mensaje Git** | `ci(github): add PSScriptAnalyzer lint step to pipeline` |
| **Validación** | CI pipeline ejecuta lint automáticamente |

#### Commit 059

| Campo | Valor |
|---|---|
| **ID** | 059 |
| **Nombre** | Agregar validación de parámetros en Kernel.ps1 |
| **Descripción** | Agregar `[ValidateNotNullOrEmpty()]` y `[ValidateScript()]` en todas las funciones de `Kernel.ps1`. |
| **Archivos afectados** | `motor/kernel/Kernel.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 1h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 059` |
| **Mensaje Git** | `fix(kernel): add parameter validation to all kernel functions` |
| **Validación** | Pasar parámetros nulos a funciones debe fallar con mensaje claro |

#### Commits 060–064: Validación de parámetros en todos los módulos

| Commit | ID | Descripción |
|---|---|---|
| 060 | — | Validación en EventBus |
| 061 | — | Validación en DependencyInjection |
| 062 | — | Validación en Logger |
| 063 | — | Validación en ConfigurationManager |
| 064 | — | Validación en Runtime |

#### Commit 065

| Campo | Valor |
|---|---|
| **ID** | 065 |
| **Nombre** | Agregar timeouts en operaciones de red |
| **Descripción** | Agregar timeouts en funciones de Git que hacen operaciones de red (`Fetch-Origin`, `Get-RemoteHead`). Usar `$PSDefaultParameterValues['*-Git*:TimeoutSeconds'] = 30`. |
| **Archivos afectados** | `motor/bootstrap/functions/Git.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 1h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 065` |
| **Mensaje Git** | `fix(git): add network timeouts to Git operations` |
| **Validación** | Prueba con URL inválida: timeout en 30s, no cuelga infinito |

#### Commit 066

| Campo | Valor |
|---|---|
| **ID** | 066 |
| **Nombre** | Agregar telemetría básica |
| **Descripción** | Agregar métricas de ejecución en el kernel: tiempo de startup, número de servicios registrados, eventos publicados. Almacenar en `$KernelEnterprise.KernelMetrics`. |
| **Archivos afectados** | `motor/kernel/Kernel.ps1`, `motor/logging/Logger.ps1` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Ninguna |
| **Tiempo estimado** | 2h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 066` |
| **Mensaje Git** | `feat(kernel): add basic execution telemetry` |
| **Validación** | `$kernel.KernelMetrics` contiene datos tras startup |

#### Commit 067

| Campo | Valor |
|---|---|
| **ID** | 067 |
| **Nombre** | Crear verify.ps1 — script de integridad |
| **Descripción** | Crear `tools/verify.ps1` que valide: (1) estructura de directorios correcta, (2) todos los módulos core cargan sin errores, (3) tests pasan, (4) no hay paths hardcoded, (5) PSScriptAnalyzer pasa. |
| **Archivos afectados** | Nuevo: `tools/verify.ps1` |
| **Directorios afectados** | `tools/` |
| **Dependencias** | Todos los anteriores |
| **Tiempo estimado** | 4h |
| **Complejidad** | Media |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 067` |
| **Mensaje Git** | `chore(tools): create verify.ps1 integrity check script` |
| **Validación** | `.\tools\verify.ps1` corre y reporta "All checks passed" |

#### Commit 068

| Campo | Valor |
|---|---|
| **ID** | 068 |
| **Nombre** | Agregar badges CI/CD al README.md |
| **Descripción** | Agregar badges de GitHub Actions (status), Pester test coverage, PSScriptAnalyzer. |
| **Archivos afectados** | `README.md` |
| **Directorios afectados** | Ninguno |
| **Dependencias** | Commit 036, 058 |
| **Tiempo estimado** | 30 min |
| **Complejidad** | Mínima |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 068` |
| **Mensaje Git** | `docs(readme): add CI/CD status badges` |
| **Validación** | README.md muestra los badges correctamente |

#### Commit 069

| Campo | Valor |
|---|---|
| **ID** | 069 |
| **Nombre** | Actualizar documentación de arquitectura |
| **Descripción** | Actualizar `docs/adr/` con ADR-001 (decisión de kernel único), ADR-002 (eliminación de ServiceLocator), ADR-003 (estructura objetivo). Actualizar `docs/ARCHITECTURE_DECISIONS.md`. |
| **Archivos afectados** | Nuevos: `docs/adr/ADR-001-kernel-unico.md`, `docs/adr/ADR-002-service-locator-removal.md`, `docs/adr/ADR-003-target-structure.md`, modificar: `docs/ARCHITECTURE_DECISIONS.md` |
| **Directorios afectados** | `docs/adr/` |
| **Dependencias** | Todos los anteriores |
| **Tiempo estimado** | 4h |
| **Complejidad** | Baja |
| **Riesgo** | Bajo |
| **Rollback** | `git revert 069` |
| **Mensaje Git** | `docs(architecture): add ADRs for key refactoring decisions` |
| **Validación** | ADRs existen y son técnicamente precisos |

#### Commits 070–078: Tests de integración

| Commit | ID | Descripción |
|---|---|---|
| 070 | — | Test integración: Kernel → EventBus → Logger |
| 071 | — | Test integración: Kernel → DI → Runtime |
| 072 | — | Test integración: BootstrapEngine → Git |
| 073 | — | Test integración: BootstrapEngine → VSCodeIntegration |
| 074 | — | Test integración: ConfigurationManager → Hermes.config.json |
| 075 | — | Test integración: Start-HermesProject flujo completo (mocked) |
| 076 | — | Test integración: BootstrapOrchestrator → BootstrapWizard |
| 077 | — | Test E2E: Start-HermesProject completo (Local target, mocked) |
| 078 | — | Test E2E: verify.ps1 pasa en CI |

---

## 4. Orden Exacto de Ejecución

```
FASE 0 — Preparación
─────────────────────
  001: chore(repo): tag rc13-pre-refactor
  002: chore(repo): remove all .gitkeep
  003: chore(sandbox): remove test projects
  004: chore(reports): remove stale diagnostic reports
  005: fix(kernel): add try-catch error handling

FASE 1 — Limpieza
─────────────────
  006: chore(azure): remove vestigial Azure
  007: refactor(motor): remove stub modules (security, validation, scheduler)
  008: refactor(motor): remove stub modules (dependencygraph, discovery, providers)
  009: refactor(motor): remove stub modules (plugins, registro, lifecycle)
  010: refactor(motor): remove stub modules (contracts, capabilities, observability)
  011: refactor(motor): remove stub modules (manifest, wizards, sandbox, session, context)
  012: refactor(tools): remove unreferenced scripts
  013: refactor(builders): remove unused builders and backup
  014: refactor(plugins): remove GitHub stub and HelloPlugin
  015: refactor(kernel): remove KernelHost/Core, keep functional Kernel.ps1
  016: refactor(git): merge duplicate Git modules
  017: refactor(observability): remove vestigial Observabilidad
  018: refactor(config): remove bootstrap.yaml
  019: refactor(config): remove configuracion/
  020: refactor(config): merge motor/config/ into motor/configuracion/
  021: docs(repo): move CHANGELOG.md → docs/
  022: docs(repo): move LICENSE → docs/
  023: docs(repo): move .env → docs/.env.example
  024: chore(repo): remove empty directories
  025: refactor(di): verify ServiceContainer removed
  026: refactor(di): remove ServiceLocator

FASE 2 — Consolidación
───────────────────────
  027: test(kernel): add Pester tests
  028: test(eventbus): add Pester tests
  029: test(logger): add Pester tests
  030: test(config): add Pester tests
  031: test(di): add Pester tests
  032: test(git): add Pester tests
  033: test(observability): add Pester tests
  034: test(runtime): add Pester tests
  035: test(core): establish test baseline (all passing)
  036: ci(github): add GitHub Actions pipeline
  037: refactor(eventbus): verify single EventBus
  038: refactor(di): verify single DI
  039: chore(motor): verify clean structure (8 modules)

FASE 3 — Arquitectura
──────────────────────
  040: fix(repo): remove hardcoded paths
  041: refactor(bootstrap): extract BootstrapEngine
  042: test(bootstrap): add BootstrapEngine tests
  043: refactor(bootstrap): extract VSCodeIntegration
  044: refactor(bootstrap): thin entrypoint to <50 lines
  045: refactor(bootstrap): separate BootstrapOrchestrator state
  046: test(bootstrap): add BootstrapOrchestrator tests
  047: refactor(bootstrap): strip BootstrapWizard to pure UI
  048: chore(bootstrap): verify full integration

FASE 4 — Optimización
──────────────────────
  049: refactor(naming): EventBus → BusEventos (kernel)
  050: refactor(naming): EventBus → BusEventos (eventos)
  051: refactor(naming): Runtime naming decision
  052: refactor(naming): PluginManager → AdministradorPlugins
  053: refactor(naming): Logger → Registrador
  054: refactor(naming): EventBus in Observabilidad
  055: refactor(naming): internal parameters
  056: refactor(naming): verify all references updated
  057: test(naming): verify all tests pass after rename

FASE 5 — Hardening
───────────────────
  058: ci(github): add PSScriptAnalyzer
  059: fix(kernel): parameter validation
  060: fix(eventbus): parameter validation
  061: fix(di): parameter validation
  062: fix(logger): parameter validation
  063: fix(config): parameter validation
  064: fix(runtime): parameter validation
  065: fix(git): network timeouts
  066: feat(kernel): basic telemetry
  067: chore(tools): create verify.ps1
  068: docs(readme): add CI/CD badges
  069: docs(architecture): add ADRs
  070: test(int): Kernel→EventBus→Logger
  071: test(int): Kernel→DI→Runtime
  072: test(int): BootstrapEngine→Git
  073: test(int): BootstrapEngine→VSCodeIntegration
  074: test(int): ConfigurationManager→Hermes.config.json
  075: test(int): Start-HermesProject full flow (mocked)
  076: test(int): BootstrapOrchestrator→BootstrapWizard
  077: test(e2e): Start-HermesProject complete (mocked)
  078: test(e2e): verify.ps1 passes in CI

Total: 78 commits
```

---

## 5. Validaciones Post-Commit

### 5.1 Validaciones genéricas (aplican a TODOS los commits)

| # | Validación | Comando |
|---|---|---|
| V1 | Git status limpio | `git status` — sin cambios sin commit |
| V2 | No hay archivos huérfanos | `git clean -n` — vacío (o confirmar intencional) |
| V3 | Tests pasan (si existen) | `Invoke-Pester pruebas/unitarias/` |
| V4 | Carga de módulos core | `. motor/kernel/Kernel.ps1` sin errores |
| V5 | Entrypoint carga | `powershell -NoProfile -File Start-HermesProject.ps1 -NombreProyecto "Test" -ProvisionTarget Local` sin errores |

### 5.2 Validaciones específicas por commit

| Commit | Validaciones adicionales |
|---|---|
| 001 | `git tag -l rc13-pre-refactor` existe |
| 002 | `grep -r "\.gitkeep" .` = vacío |
| 003 | `ls ProyectoTest025/ 2>&1` falla; solo `sandbox/Local/` sobrevive |
| 004 | `ls reports/*.json` solo FileIndex.json |
| 005 | Probar `Start-HermesEnterpriseKernel -KernelEnterprise $null` → error claro |
| 006 | `grep -ri "azure" --include="*.ps1" motor/` = vacío |
| 007–011 | `ls motor/` solo 8 subdirectorios |
| 012 | `grep -r "LoadConfiguration\|EnterprisePipeline\|HermesPathResolver" --include="*.ps1" .` = vacío |
| 015 | `. motor/kernel/Kernel.ps1; $k = New-HermesEnterpriseKernel -ContextoKernel $ctx; Start-HermesEnterpriseKernel -KernelEnterprise $k` funciona |
| 016 | `. motor/bootstrap/functions/Git.ps1; Test-GitInstallation` funciona |
| 017 | `grep -r "tools/Observabilidad" --include="*.ps1" .` = vacío |
| 018–020 | `Get-Content Hermes.config.json` contiene config; `ls configuracion/` falla |
| 024 | `ls agentes/ arquitectura/ herramientas/ memoria/ perfiles/ plantillas/ protocolos/ proveedores/` todos fallan |
| 026 | `grep -r "Get-HermesEnterpriseService\|ServiceLocator" --include="*.ps1" .` = vacío |
| 035 | `Invoke-Pester pruebas/unitarias/` = 100% pass, 0% fail |
| 036 | Push a GitHub → Actions corre → green check |
| 040 | `grep -r "D:/\|C:/\|D:\\|C:\\" --include="*.ps1" .` = vacío |
| 044 | `(Get-Content motor/bootstrap/Start-HermesProject.ps1).Count -lt 50` = true |
| 048 | `Start-HermesProject -NombreProyecto "Test" -ProvisionTarget Local -AbrirVSCode:$false` funciona |
| 057 | `Invoke-Pester pruebas/unitarias/` = 100% (post-rename) |
| 067 | `.\tools\verify.ps1` reporta "All checks passed" |
| 078 | CI pipeline pasa con verify.ps1, PSScriptAnalyzer, y todos los tests |

### 5.3 Métricas a comprobar después de cada commit

| Métrica | Frecuencia | Objetivo |
|---|---|---|
| Número de archivos .ps1 | Después de cada commit de limpieza | Reducir de ~60 a ~20 |
| Número de directorios en motor/ | Después de cada commit de limpieza | Reducir de 22 a 8 |
| Archivos de configuración | Después de M-008 | Reducir de 5+ a 1 |
| Cobertura de tests | Después de cada commit de tests | > 50% en módulos core |
| Paths hardcoded | Después de commit 040 | 0 |
| Tests pasando | Después de cada commit | 100% |

---

## 6. Compatibilidad por Etapa

### Etapa: Fase 0 — Preparación

| Aspecto | Estado |
|---|---|
| **Qué puede romper** | Nada — solo se agrega try/catch (no cambia comportamiento) |
| **Qué permanece estable** | Todo — la API pública no cambia |
| **Interfaces públicas funcionales** | `Start-HermesProject.ps1`, `Kernel.ps1`, todas las funciones helper |
| **Cómo verificar compatibilidad** | Ejecutar `Start-HermesProject.ps1` con un proyecto de prueba |

### Etapa: Fase 1 — Limpieza

| Aspecto | Estado |
|---|---|
| **Qué puede romper** | M-001 (kernel): si Kernel.ps1 depende de algo en Core/ |
| **Qué permanece estable** | `Start-HermesProject.ps1`, `motor/bootstrap/`, todas las funciones públicas de los módulos conservados |
| **Interfaces públicas funcionales** | `Start-HermesProject.ps1`, `Kernel.ps1` (refs a funciones helper verificadas) |
| **Cómo verificar compatibilidad** | `. motor/kernel/Kernel.ps1` + `Start-HermesEnterpriseKernel` funciona antes y después |

### Etapa: Fase 2 — Consolidación

| Aspecto | Estado |
|---|---|
| **Qué puede romper** | M-005 (ServiceLocator): si algún script usa `Get-HermesEnterpriseService` |
| **Qué permanece estable** | Todas las APIs funcionales de EventBus, DI, Logger, Runtime, ConfigurationManager |
| **Interfaces públicas funcionales** | `New-/Subscribe-/Publish-HermesEnterpriseEvent`, `Register-/Resolve-HermesEnterpriseService`, etc. |
| **Cómo verificar compatibilidad** | `Invoke-Pester pruebas/unitarias/` = 100% |

### Etapa: Fase 3 — Arquitectura

| Aspecto | Estado |
|---|---|
| **Qué puede romper** | M-006, M-007: refactors grandes de Start-HermesProject y BootstrapOrchestrator |
| **Qué permanece estable** | La interfaz externa: `Start-HermesProject.ps1` acepta los mismos parámetros y produce el mismo resultado |
| **Interfaces públicas funcionales** | `Start-HermesProject.ps1` (entrypoint público), todas las funciones de kernel, eventbus, di, etc. |
| **Cómo verificar compatibilidad** | `Start-HermesProject.ps1` con los mismos parámetros produce el mismo resultado (verificado con tests) |

### Etapa: Fase 4 — Optimización

| Aspecto | Estado |
|---|---|
| **Qué puede romper** | M-019 (nombres): referencias a funciones renombradas |
| **Qué permanece estable** | La funcionalidad es idéntica, solo cambian los nombres |
| **Interfaces públicas funcionales** | Todas, pero con nuevos nombres. Se agregan aliases para compatibilidad temporal |
| **Cómo verificar compatibilidad** | `Invoke-Pester pruebas/unitarias/` = 100% |

### Etapa: Fase 5 — Hardening

| Aspecto | Estado |
|---|---|
| **Qué puede romper** | Nada — solo se agregan validaciones, timeouts, y scripts nuevos |
| **Qué permanece estable** | Todo |
| **Interfaces públicas funcionales** | Todas, sin cambios |
| **Cómo verificar compatibilidad** | `verify.ps1` pasa + `Invoke-Pester` pasa |

---

## 7. Riesgos por Sprint

### Sprint 0 — Preparación

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Técnico | 1% | Bajo | Commits de bajo riesgo |
| Funcional | 0% | Nulo | No se toca código funcional |
| Integración | 0% | Nulo | No hay integraciones |
| Git | 1% | Bajo | `git revert` simple |
| Pruebas | 0% | Nulo | No hay pruebas todavía |
| Despliegue | 0% | Nulo | No hay despliegue |

### Sprint 1 — Limpieza

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Técnico | 15% | Medio | Verificar referencias con `git grep` antes de eliminar |
| Funcional | 10% | Medio | M-001 (kernel) puede romper si Kernel.ps1 depende de Core/ |
| Integración | 5% | Medio | M-008 (config) puede romper carga de configuración |
| Git | 5% | Bajo | Commits independientes, `git revert` individual |
| Pruebas | 0% | Nulo | No hay pruebas |
| Despliegue | 0% | Nulo | No hay despliegue |

### Sprint 2 — Consolidación

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Técnico | 10% | Medio | M-002 requiere conocimiento de Pester 5.x |
| Funcional | 5% | Bajo | Los tests no modifican código de producción |
| Integración | 5% | Bajo | M-005 (ServiceLocator) puede romper referencias |
| Git | 5% | Bajo | Commits atómicos, `git revert` simple |
| Pruebas | 20% | Medio | Los tests nuevos pueden fallar inicialmente. Se iterará hasta 100% |
| Despliegue | 0% | Nulo | No hay despliegue |

### Sprint 3 — Arquitectura

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Técnico | 30% | Alto | M-006 y M-007 son refactors grandes. Feature branch + code review |
| Funcional | 20% | Alto | Start-HermesProject.ps1 es el entrypoint principal. Tests primero |
| Integración | 20% | Alto | BootstrapEngine→Orchestrator→Wizard pueden desincronizarse |
| Git | 15% | Medio | Feature branch con merge conflict potential. Rebase antes de merge |
| Pruebas | 10% | Medio | Tests de BootstrapEngine y Orchestrator capturan regresiones |
| Despliegue | 0% | Nulo | No hay despliegue |

### Sprint 4 — Optimización

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Técnico | 20% | Medio | M-019 (nombres) requiere actualizar todas las referencias |
| Funcional | 10% | Bajo | La funcionalidad no cambia, solo los nombres |
| Integración | 5% | Bajo | Aliases mantienen compatibilidad |
| Git | 5% | Bajo | Commits por módulo |
| Pruebas | 5% | Bajo | Tests actualizados con nuevos nombres |
| Despliegue | 0% | Nulo | No hay despliegue |

### Sprint 5 — Hardening

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| Técnico | 5% | Bajo | Solo se agregan validaciones |
| Funcional | 2% | Bajo | No se cambia lógica de negocio |
| Integración | 2% | Bajo | verify.ps1 valida integración |
| Git | 2% | Bajo | Commits pequeños |
| Pruebas | 2% | Bajo | Tests existentes validan que no hay regresiones |
| Despliegue | 0% | Nulo | No hay despliegue |

---

## 8. Automatización

### 8.1 Tareas que deben automatizarse

| Tarea | Script/Herramienta | Justificación |
|---|---|---|
| Validar estructura de directorios | `tools/verify.ps1` (Commit 067) | Verificación rápida de que la estructura objetivo se mantiene |
| Ejecutar tests | CI/CD pipeline (Commit 036) | Validación automática en cada push |
| Lint (PSScriptAnalyzer) | CI/CD pipeline (Commit 058) | Calidad de código consistente |
| Verificar paths relativos | `grep` en verify.ps1 | Prevención de regresiones de paths hardcoded |
| Verificar que no hay .gitkeep | `grep` en verify.ps1 | Prevención de regresiones |
| Verificar estructura motor/ | `ls` en verify.ps1 | Prevención de módulos stub reapareciendo |
| Snapshot pre-cambio | `git tag` (Commit 001) | Seguridad: poder revertir todo |

### 8.2 Tareas que deben permanecer manuales

| Tarea | Justificación |
|---|---|
| Decisión de qué kernel eliminar | Ya está decidido, pero requirió análisis humano |
| Decisión de qué módulos stub eliminar | Ya identificados en auditoría, pero verificación manual de referencias |
| Decisión de qué reports conservar | Juicio humano sobre utilidad |
| Decisión de nomenclatura | Requiere consistencia con el contexto del proyecto |
| Code review de cada PR | Validación humana de que la refactorización no introduce bugs sutiles |
| Aprobación de merge a main | Governance: evitar merge de código no revisado |

---

## 9. Puntos de Control por Sprint

### Checkpoint S0 — Preparación

| Campo | Resultado |
|---|---|
| **Estado** | [ ] Completado / [ ] Fallido |
| **Pruebas** | No hay pruebas todavía |
| **Cobertura** | 0% |
| **Incidentes** | [Listar si los hay] |
| **Archivos modificados** | ~45 archivos .gitkeep eliminados, ~10 sandboxes eliminados, ~30 reports eliminados, 1 archivo modificado (Kernel.ps1) |
| **Tiempo consumido** | [Horas reales] |
| **Próximo Sprint** | S1 — Limpieza Masiva |

### Checkpoint S1 — Limpieza

| Campo | Resultado |
|---|---|
| **Estado** | [ ] Completado / [ ] Fallido |
| **Pruebas** | No hay pruebas todavía |
| **Cobertura** | 0% |
| **Incidentes** | [Listar si los hay] |
| **Archivos modificados** | ~30 archivos eliminados, ~16 directorios eliminados, 1 kernel consolidado, 3 directorios de config fusionados |
| **Tiempo consumido** | [Horas reales] |
| **Próximo Sprint** | S2 — Fundaciones de Calidad |

### Checkpoint S2 — Consolidación

| Campo | Resultado |
|---|---|
| **Estado** | [ ] Completado / [ ] Fallido |
| **Pruebas** | `Invoke-Pester pruebas/unitarias/` = [%] |
| **Cobertura** | [%] en módulos core |
| **Incidentes** | [Listar si los hay] |
| **Archivos modificados** | ~8 tests nuevos, 1 archivo YAML (CI/CD), 2 archivos eliminados (ServiceLocator, EventBus clase) |
| **Tiempo consumido** | [Horas reales] |
| **Próximo Sprint** | S3 — Arquitectura Core |

### Checkpoint S3 — Arquitectura

| Campo | Resultado |
|---|---|
| **Estado** | [ ] Completado / [ ] Fallido |
| **Pruebas** | `Invoke-Pester pruebas/unitarias/` = [%] |
| **Cobertura** | [%] en módulos core + bootstrap |
| **Incidentes** | [Listar si los hay] |
| **Archivos modificados** | BootstrapEngine.ps1 (nuevo), VSCodeIntegration.ps1 (nuevo), Start-HermesProject.ps1 (modificado), BootstrapOrchestrator.ps1 (modificado), BootstrapWizard.ps1 (modificado), ~5 tests nuevos |
| **Tiempo consumido** | [Horas reales] |
| **Próximo Sprint** | S4 — Optimización |

### Checkpoint S4 — Optimización

| Campo | Resultado |
|---|---|
| **Estado** | [ ] Completado / [ ] Fallido |
| **Pruebas** | `Invoke-Pester pruebas/unitarias/` = [%] |
| **Cobertura** | [%] |
| **Incidentes** | [Listar si los hay] |
| **Archivos modificados** | ~20 archivos renombrados en todos los módulos |
| **Tiempo consumido** | [Horas reales] |
| **Próximo Sprint** | S5 — Hardening |

### Checkpoint S5 — Hardening

| Campo | Resultado |
|---|---|
| **Estado** | [ ] Completado / [ ] Fallido |
| **Pruebas** | `Invoke-Pester pruebas/` = 100% |
| **Cobertura** | [%] |
| **Incidentes** | [Listar si los hay] |
| **Archivos modificados** | verify.ps1 (nuevo), ~8 archivos con validación de parámetros, 1 archivo Git con timeouts, ~8 tests de integración, 3 ADRs nuevos, README modificado |
| **Tiempo consumido** | [Horas reales] |
| **Próximo Sprint** | Refactorización completa ✅ |

---

## 10. Criterio de Finalización

### 10.1 Lista de verificación completa

La refactorización se considerará finalizada **SOLO** cuando se cumplan TODAS las siguientes condiciones:

#### Estructurales

- [ ] `motor/` contiene exactamente 8 subdirectorios: `kernel`, `bootstrap`, `configuracion`, `eventos`, `dependencias`, `logging`, `runtime`, `tools`
- [ ] `motor/kernel/Core/` no existe
- [ ] `configuracion/` no existe
- [ ] `bootstrap.yaml` no existe
- [ ] `tools/LoadConfiguration.ps1`, `tools/GenerateIntegrityReport.ps1`, `tools/EnterprisePipeline.ps1`, `hello.ps1`, `Patch-Hermes-AzureTrace.ps1` no existen
- [ ] `builders/` no existe
- [ ] `plugins/HelloPlugin/` no existe
- [ ] `reports/backups/` no existe
- [ ] `agentes/`, `arquitectura/`, `herramientas/`, `memoria/`, `perfiles/`, `plantillas/`, `protocolos/`, `proveedores/` no existen
- [ ] `ProyectoTest025/` no existe
- [ ] `CHANGELOG.md`, `LICENSE`, `.env.example` están en `docs/`
- [ ] `Hermes.config.json` es el único archivo de configuración

#### Duplicaciones

- [ ] 1 solo kernel (Kernel.ps1 funcional)
- [ ] 1 solo EventBus (`motor/eventos/EventBus.ps1`)
- [ ] 1 solo DI container (`motor/dependencias/DependencyInjection.ps1`)
- [ ] 1 solo módulo Git (`motor/bootstrap/functions/Git.ps1`)
- [ ] 1 solo archivo de Observabilidad (`motor/tools/Observabilidad.ps1`)
- [ ] ServiceLocator eliminado

#### Pruebas

- [ ] `Invoke-Pester pruebas/unitarias/` pasa con 100%
- [ ] `Invoke-Pester pruebas/integracion/` (si existe) pasa con 100%
- [ ] Cobertura de tests > 50% en módulos core (Kernel, EventBus, DI, Logger, ConfigurationManager, Runtime)
- [ ] BootstrapEngine tiene tests unitarios
- [ ] BootstrapOrchestrator tiene tests unitarios (sin UI)

#### CI/CD

- [ ] `.github/workflows/ci.yml` existe
- [ ] CI pipeline corre automáticamente en cada push
- [ ] CI pipeline ejecuta: tests Pester + PSScriptAnalyzer + verify.ps1
- [ ] Badges de CI/CD visibles en README.md

#### Calidad

- [ ] `PSScriptAnalyzer` pasa sin errores en todos los scripts
- [ ] `grep -r "D:/\|C:/\|D:\\|C:\\" --include="*.ps1" .` = vacío (no hay paths hardcoded)
- [ ] `grep -r "\.gitkeep" .` = vacío
- [ ] No hay archivos .bak en el proyecto
- [ ] `Start-HermesProject.ps1` tiene < 50 líneas
- [ ] `Start-HermesEnterpriseKernel` tiene try/catch en todas las operaciones
- [ ] Todas las funciones públicas tienen validación de parámetros
- [ ] Las operaciones Git tienen timeouts de red

#### Documentación

- [ ] `docs/adr/` existe con ADR-001 (kernel único), ADR-002 (ServiceLocator), ADR-003 (estructura objetivo)
- [ ] `README.md` tiene badges de CI/CD
- [ ] `tools/verify.ps1` existe y pasa
- [ ] `CLINE.md` está actualizado con la nueva arquitectura
- [ ] `MASTER_REFACTORING_ROADMAP.md` refleja el estado final

#### Arquitectura

- [ ] `motor/bootstrap/Start-HermesProject.ps1` es entrypoint delgado que delega en BootstrapEngine
- [ ] `motor/bootstrap/engine/BootstrapEngine.ps1` existe con lógica pura de bootstrap
- [ ] `motor/bootstrap/integrations/VSCodeIntegration.ps1` existe
- [ ] `BootstrapWizard.ps1` no contiene lógica de bootstrap (solo presentación)
- [ ] `BootstrapOrchestrator.ps1` no contiene UI

#### Seguridad

- [ ] Tag `rc13-pre-refactor` existe en git
- [ ] Todos los commits siguen la convención `refactor/fix/test/docs/chore`
- [ ] El proyecto funciona exactamente igual que antes (verificado con tests funcionales)

### 10.2 Declaración de finalización

> **La refactorización de Hermes Enterprise RC13 se considera completa cuando la lista de verificación anterior (sección 10.1) tenga TODAS las casillas marcadas.**
>
> En ese momento:
> - El proyecto es **más pequeño** (~50% menos archivos)
> - El proyecto es **más simple** (8 módulos vs 22)
> - El proyecto es **más mantenible** (pruebas + CI/CD + documentación)
> - El proyecto es **más modular** (separación de concerns en bootstrap)
> - El proyecto es **más testeable** (cobertura > 50%)
> - El proyecto está **preparado para producción** (validaciones, timeouts, telemetría, CI/CD)
>
> Sin haber perdido **ninguna funcionalidad**.

---

*Fin del documento GOLDEN_REFACTORING_SEQUENCE.md*

*Versión 1.0 — Pendiente de aprobación humana para comenzar Commit 001*