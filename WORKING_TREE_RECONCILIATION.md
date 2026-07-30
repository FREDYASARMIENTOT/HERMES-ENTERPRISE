# WORKING TREE RECONCILIATION

> **PRE-COMMIT 000 — Reconciliación del Working Tree**
>
> Objetivo: Clasificar, analizar y planificar todos los cambios no commiteados antes del Commit 001.
>
> Fecha: 2026-07-29
> Base: `rc13-pre-refactor-v2` (futuro tag snapshot)

---

## 1. Resumen Ejecutivo

| Métrica | Valor |
|---------|-------|
| Total archivos afectados | ~189 |
| Deleted (D) | 84 |
| Modified (M) | 7 |
| Untracked (??) | ~98 |
| Activos funcionales identificados | 18 |
| Activos en riesgo | 0 |
| Commits propuestos | 14 |

---

## 2. Inventario Completo por Grupo

### GRUPO A — Documentación (10 archivos)

| Archivo | Estado | Tipo |
|---------|--------|------|
| `AUDIT_REPORT.md` | ?? | Nuevo |
| `BOOTSTRAP_IMPLEMENTATION_PLAN.md` | ?? | Nuevo |
| `CLINE.md` | ?? | Nuevo |
| `GOLDEN_REFACTORING_SEQUENCE.md` | ?? | Nuevo |
| `GOLDEN_REFACTORING_SEQUENCE_V2.md` | ?? | Nuevo |
| `MASTER_REFACTORING_ROADMAP.md` | ?? | Nuevo |
| `CHANGELOG.md` | M | Modificado |
| `docs/DEPENDENCY_MATRIX.md` | ?? | Nuevo |
| `docs/MIGRATION_PLAN.md` | ?? | Nuevo |
| `docs/RISKS.md` | ?? | Nuevo |
| `docs/ROADMAP.md` | ?? | Nuevo |

**Total: 10 archivos** (9 nuevos, 1 modificado)
**Impacto:** Bajo. Documentos de planificación, sin código funcional.
**Riesgo:** Nulo. No hay dependencias de código hacia estos archivos.
**Acción propuesta:** Commit único de documentación.

---

### GRUPO B — Arquitectura (11 archivos)

| Archivo | Estado | Tipo |
|---------|--------|------|
| `motor/kernel/Kernel.ps1` | M | Modificado |
| `motor/config/Configuration.psm1` | ?? | Nuevo |
| `motor/eventos/EventBus.ps1` | D | Eliminado |
| `motor/dependencias/DependencyInjection.ps1` | D | Eliminado |
| `motor/dependencias/ServiceLocator.ps1` | D | Eliminado |
| `motor/runtime/Runtime.ps1` | D | Eliminado |
| `motor/registro/ModuleRegistry.ps1` | D | Eliminado |
| `motor/contracts/PluginContracts.ps1` | D | Eliminado |
| `motor/contracts/ProviderContracts.ps1` | D | Eliminado |
| `motor/dependencygraph/DependencyResolver.ps1` | D | Eliminado |
| `motor/configuracion/ConfigurationManager.ps1` | D | Eliminado |

**Total: 11 archivos** (1 modificado, 1 nuevo, 9 eliminados)
**Impacto:** ALTO. Los archivos D son componentes de la arquitectura anterior (kernel anterior, event bus, DI, runtime). El Kernel.ps1 modificado probablemente ya no referencia estos componentes.
**Riesgo:** ALTO. Verificar que Kernel.ps1 modificado cargue sin los D.
**Activos funcionales preservados:** Kernel.ps1 (modificado), Configuration.psm1 (nuevo).
**Dependencias:** Kernel.ps1 no debe referenciar EventBus.ps1, DI, ServiceLocator, Runtime, ModuleRegistry.
**Rollback:** `git checkout HEAD -- motor/kernel/ motor/config/ motor/eventos/ motor/dependencias/ motor/runtime/ motor/registro/ motor/contracts/ motor/dependencygraph/ motor/configuracion/`
**Acción propuesta:** Separar en 2 commits: (1) eliminación de módulos obsoletos, (2) nuevo Configuration.psm1.

---

### GRUPO C — Bootstrap (18 archivos)

| Archivo | Estado | Tipo | 
|---------|--------|------|
| `motor/bootstrap/Start-HermesProject.ps1` | M | Modificado |
| `motor/bootstrap/engine/BootstrapOrchestrator.ps1` | M | Modificado |
| `motor/bootstrap/engine/BootstrapWizard.ps1` | — | Preservado en HEAD |
| `motor/bootstrap/engine/BootstrapState.ps1` | — | Preservado en HEAD |
| `motor/bootstrap/request/BootstrapRequest.ps1` | — | Preservado en HEAD |
| `motor/bootstrap/functions/Git.ps1` | M | Modificado |
| `motor/bootstrap/functions/GitHub.ps1` | ?? | Nuevo |
| `motor/bootstrap/functions/Python.ps1` | ?? | Nuevo |
| `motor/bootstrap/functions/VSCode.ps1` | ?? | Nuevo |
| `motor/bootstrap/functions/GitHubProvision.ps1` | ?? | Nuevo |
| `motor/bootstrap/functions/README.md` | ?? | Nuevo |
| `motor/bootstrap/BootstrapOrchestrator.ps1` | ?? | Nuevo |
| `motor/bootstrap/Git.ps1` | ?? | Nuevo |
| `motor/bootstrap/GitHub.ps1` | ?? | Nuevo |
| `motor/bootstrap/Python.ps1` | ?? | Nuevo |
| `motor/bootstrap/Reporting.ps1` | ?? | Nuevo |
| `motor/bootstrap/Security.ps1` | ?? | Nuevo |
| `motor/bootstrap/Synchronization.ps1` | ?? | Nuevo |
| `motor/bootstrap/Templates.ps1` | ?? | Nuevo |
| `motor/bootstrap/Tests.ps1` | ?? | Nuevo |
| `motor/bootstrap/Validation.ps1` | ?? | Nuevo |
| `Start-HermesProject.ps1` | ?? | Nuevo (raíz) |
| `bootstrap.json` | ?? | Nuevo |
| `bootstrap.yaml` | ?? | Nuevo |
| `.env` | ?? | Nuevo |
| `Hermes.config.json` | ?? | Nuevo |

**Total: 24 archivos** (4 modificados, 20 nuevos)
**Impacto:** ALTO. Es el motor de bootstrap reestructurado. Incluye nuevos orquestadores, funciones Git/GitHub/Python/VSCode, y scripts de pipeline.
**Riesgo:** ALTO. Los archivos en `motor/bootstrap/` (raíz) son la nueva estructura que reemplaza los módulos anteriores. Verificar que no haya colisión con `motor/bootstrap/engine/` existente.
**Activos funcionales preservados:**
- `motor/bootstrap/engine/BootstrapWizard.ps1` (PRESERVAR)
- `motor/bootstrap/engine/BootstrapState.ps1` (PRESERVAR)
- `motor/bootstrap/request/BootstrapRequest.ps1` (PRESERVAR)
- `motor/bootstrap/functions/GitHub.ps1` nuevo (PRESERVAR, 31 líneas funcionales)
- `motor/bootstrap/functions/Python.ps1` nuevo (PRESERVAR, 8 líneas funcionales)
**Dependencias:** Todos los nuevos scripts `motor/bootstrap/*.ps1` dependen entre sí.
**Rollback:** Complejo. Requiere revertir todo el directorio `motor/bootstrap/`.
**Acción propuesta:** Múltiples commits: (1) funciones independientes, (2) orquestadores, (3) entrypoint.

---

### GRUPO D — Kernel (1 archivo)

| Archivo | Estado | Tipo |
|---------|--------|------|
| `motor/kernel/Kernel.ps1` | M | Modificado |

Ya clasificado en Grupo B. Es el único archivo del kernel actual.
**Estado:** Modificado, no eliminado.
**Riesgo:** Crítico. Cualquier error en Kernel.ps1 rompe todo el sistema.

---

### GRUPO E — Motores (1 archivo)

| Archivo | Estado | Tipo |
|---------|--------|------|
| `motor/bootstrap/engine/BootstrapOrchestrator.ps1` | M | Modificado |
| `motor/bootstrap/engine/BootstrapWizard.ps1` | — | Preservado |
| `motor/bootstrap/engine/BootstrapState.ps1` | — | Preservado |

**Total: 3 archivos** (1 modificado, 2 preservados sin cambios)
**Nota:** El plan V2 (Commit 030-037) propone crear 7 nuevos motores + pipeline. Estos AÚN NO EXISTEN en el working tree. Los archivos existentes son los originales del motor de bootstrap.
**Riesgo:** Bajo.
**Acción propuesta:** Commit 001 del plan V2 ya captura este estado.

---

### GRUPO F — Providers (26 archivos)

| Archivo | Estado |
|---------|--------|
| `motor/providers/AzureFoundryChat.ps1` | D |
| `motor/providers/AzureFoundryDeployment.ps1` | D |
| `motor/providers/AzureFoundryHealth.ps1` | D |
| `motor/providers/AzureFoundryProvider.ps1` | D |
| `motor/providers/AzureFoundryRest.ps1` | D |
| `motor/providers/AzureFoundryTelemetry.ps1` | D |
| `motor/providers/GitHubManagers.ps1` | D |
| `motor/providers/GitHubProvider.ps1` | D |
| `motor/providers/GitManager.ps1` | D |
| `motor/providers/MockProvider.ps1` | D |
| `motor/providers/ProjectDescriptor.ps1` | D |
| `motor/providers/ProjectManager.ps1` | D |
| `motor/providers/ProviderAdapter.ps1` | D |
| `motor/providers/ProviderCapabilityDescriptor.ps1` | D |
| `motor/providers/ProviderConfigurationManager.ps1` | D |
| `motor/providers/ProviderContext.ps1` | D |
| `motor/providers/ProviderDescriptor.ps1` | D |
| `motor/providers/ProviderDiagnostics.ps1` | D |
| `motor/providers/ProviderManager.ps1` | D |
| `motor/providers/ProviderRegistry.ps1` | D |
| `motor/providers/VSCodeManager.ps1` | D |
| `motor/providers/WorkspaceProvider.ps1` | D |
| `motor/providers/azure/AzureProviderAuthentication.ps1` | D |
| `motor/providers/azure/AzureResourceDiscovery.ps1` | D |

**Total: 26 archivos** (todos eliminados)
**Impacto:** ALTO. Todo el subsistema de providers fue eliminado.
**Riesgo:** ALTO. Verificar que ningún componente restante referencia estos providers.
**Activos funcionales:** NINGUNO. Todos eran stubs o implementaciones no funcionales.
**Dependencias:** Kernel.ps1 debe haber sido modificado para no referenciar providers.
**Rollback:** `git checkout HEAD -- motor/providers/`
**Acción propuesta:** Commit único de eliminación de providers.

---

### GRUPO G — Sandbox (7 archivos)

| Archivo | Estado |
|---------|--------|
| `sandbox/ProyectoTest001` | D |
| `sandbox/ProyectoTest002` | D |
| `sandbox/ProyectoTest003` | D |
| `sandbox/ProyectoTest004` | D |
| `sandbox/ProyectoTest005` | D |
| `sandbox/ProyectoTest006` | D |
| `sandbox/ProyectoTest007` | D |
| `sandbox/ProyectoTest011` | D |
| `sandbox/ProyectoTest012` | D |
| `sandbox/ProyectoTest014` | D |
| `sandbox/ProyectoTest016` | D |
| `sandbox/ProyectoTest018` | D |
| `sandbox/ProyectoTest019` | D |
| `sandbox/ProyectoTest021` | D |
| `sandbox/ProyectoTest022` | D |
| `sandbox/artifacts/consumirFoundry.md` | D |
| `sandbox/artifacts/guia.md` | D |
| `sandbox/artifacts/infra/00-Variables.ps1` | D |
| `sandbox/artifacts/infra/05-Validate.ps1` | D |
| `sandbox/artifacts/test_foundry.py` | D |
| `sandbox/Local/` | ?? | Nuevo |

**Total: 21 archivos** (20 eliminados, 1 nuevo)
**Impacto:** BAJO. Los sandboxes eliminados son proyectos de prueba obsoletos. `sandbox/Local/` es el único preservado.
**Activos funcionales preservados:** `sandbox/Local/` (nuevo, vacío o con contenido de prueba).
**Riesgo:** BAJO. Ningún componente funcional depende de estos sandboxes.
**Nota:** El plan V2 Commit 003 define exactamente esta limpieza.
**Acción propuesta:** Coincide con Commit 003 del plan V2.

---

### GRUPO H — Pruebas (7 archivos)

| Archivo | Estado | Tipo |
|---------|--------|------|
| `tests/bootstrap/Test-StartHermesProject.ps1` | M | Modificado |
| `tests/Test-StartHermesProject.ps1` | ?? | Nuevo |
| `tests/security/Test-GitSynchronization.ps1` | ?? | Nuevo |
| `pruebas/bootstrap/Test-StartHermesProject.ps1` | ?? | Nuevo |
| `pruebas/diagnostico/script_minimo.ps1` | ?? | Nuevo |
| `pruebas/salida-temporal/kernel-config-test.json` | ?? | Nuevo |
| `pruebas/salida-temporal/kernel-logger-test.jsonl` | ?? | Nuevo |
| `pruebas/salida-temporal/plugin-fault-policy/` (4 archivos) | ?? | Nuevo |
| `pruebas/salida-temporal/plugin-observability/` (4 archivos) | ?? | Nuevo |
| `pruebas/salida-temporal/plugin-sandbox/` (4 archivos) | ?? | Nuevo |

**Total: 18 archivos** (1 modificado, 17 nuevos)
**Impacto:** MEDIO. Pruebas Pester y artefactos de pruebas temporales.
**Riesgo:** BAJO. Archivos de prueba no afectan código de producción.
**Activos funcionales:** Los tests de bootstrap son activos que deben preservarse.
**Nota:** Los archivos en `pruebas/salida-temporal/` son artefactos de ejecuciones de pruebas. Deben ser excluidos del commit (gitignore) o eliminados.
**Recomendación:** Excluir `pruebas/salida-temporal/` del tracking. Commitear solo los tests.
**Acción propuesta:** Commit único de tests.

---

### GRUPO I — Herramientas (23 archivos)

| Archivo | Estado | Tipo |
|---------|--------|------|
| `tools/EnterprisePipeline.ps1` | M | Modificado |
| `tools/BootstrapContext.ps1` | ?? | Nuevo |
| `tools/DryRun.ps1` | ?? | Nuevo |
| `tools/ExecutionReportEngine.psm1` | ?? | Nuevo |
| `tools/GenerateIntegrityReport.ps1` | ?? | Nuevo |
| `tools/HermesPathResolver.psm1` | ?? | Nuevo |
| `tools/Integration.ps1` | ?? | Nuevo |
| `tools/Invoke-EnterprisePipeline.ps1` | ?? | Nuevo |
| `tools/LoadConfiguration.ps1` | ?? | Nuevo |
| `tools/Observabilidad.ps1` | ?? | Nuevo |
| `tools/ProjectFactory.psm1` | ?? | Nuevo |
| `tools/ProjectFactoryV2.psm1` | ?? | Nuevo |
| `tools/Publish.ps1` | ?? | Nuevo |
| `tools/Registry.psm1` | ?? | Nuevo |
| `tools/Scheduler.ps1` | ?? | Nuevo |
| `tools/ValidateConfiguration.ps1` | ?? | Nuevo |
| `tools/ValidateModules.ps1` | ?? | Nuevo |
| `tools/Validation.psm1` | ?? | Nuevo |
| `tools/VerifyEnvironment.ps1` | ?? | Nuevo |
| `tools/VerifyGitHub.ps1` | ?? | Nuevo |
| `tools/VerifyVSCode.ps1` | ?? | Nuevo |
| `tools/WorkspaceResolver.psm1` | ?? | Nuevo |
| `tools/Write-HermesLog.ps1` | ?? | Nuevo |

**Total: 23 archivos** (1 modificado, 22 nuevos)
**Impacto:** ALTO. Este es un conjunto completo de herramientas de soporte que no existían en HEAD. Incluye pipeline empresarial, resolución de workspace, validación, publicación, y logging.
**Riesgo:** MEDIO. Estos scripts dependen de la estructura del proyecto. Si la estructura cambia (grupo B, C, F), estos scripts pueden romperse.
**Dependencias:** `tools/LoadConfiguration.ps1` depende de `configuracion/kernel.enterprise.json`. `tools/WorkspaceResolver.psm1` depende de la estructura de directorios. `tools/Invoke-EnterprisePipeline.ps1` probablemente orquesta todo.
**Activos funcionales preservados:**
- `tools/Observabilidad.ps1` — instrumentación existente
- `tools/EnterprisePipeline.ps1` — pipeline empresarial modificado
- `tools/WorkspaceResolver.psm1` — resolución de workspace
**Rollback:** `git checkout HEAD -- tools/`
**Acción propuesta:** 2 commits: (1) herramientas core (pipeline, workspace, logging), (2) herramientas de validación y verificación.

---

### GRUPO J — Configuración (2 archivos)

| Archivo | Estado | Tipo |
|---------|--------|------|
| `configuracion/kernel.enterprise.json` | ?? | Nuevo |
| `configuracion/bootstrap.enterprise.json` | — | Preservado en HEAD |
| `bootstrap.json` | ?? | Nuevo |
| `bootstrap.yaml` | ?? | Nuevo |
| `Hermes.config.json` | ?? | Nuevo |
| `.env` | ?? | Nuevo |

**Total: 5 archivos** (4 nuevos, 1 preservado en HEAD)
**Impacto:** ALTO. `configuracion/kernel.enterprise.json` es la configuración del kernel enterprise. `bootstrap.json` y `bootstrap.yaml` son configuraciones de bootstrap adicionales.
**Activos funcionales preservados:**
- `configuracion/bootstrap.enterprise.json` (preservado en HEAD)
- `configuracion/kernel.enterprise.json` (nuevo)
**Riesgo:** MEDIO. Estos archivos son referenciados por `tools/LoadConfiguration.ps1` y posiblemente por `motor/config/Configuration.psm1`.
**Nota:** `bootstrap.yaml` está marcado en V2 Commit 014 para eliminación (formato redundante).
**Rollback:** Simple, son archivos independientes.
**Acción propuesta:** Commit único de configuración. Excluir `.env` del commit (debe ser `.env.example` en docs/).

---

### GRUPO K — Plugins (5 archivos)

| Archivo | Estado |
|---------|--------|
| `plugins/HelloPlugin/HelloPlugin.ps1` | D |
| `plugins/HelloPlugin/README.md` | D |
| `plugins/HelloPlugin/plugin.json` | D |
| `plugins/HelloPlugin/plugin.settings.json` | D |
| `plugins/HelloPlugin/.gitkeep` | — |

**Total: 5 archivos** (4 eliminados, 1 .gitkeep ya eliminado en el grupo L)
**Nota:** `plugins/.gitkeep` ya está en el grupo L como eliminado.
**Impacto:** BAJO. Plugin de ejemplo no funcional.
**Riesgo:** NULO. Ningún componente depende de HelloPlugin.
**Acción propuesta:** Coincide con V2 Commit 010.

---

### GRUPO L — Eliminaciones (archivos .gitkeep) (22 archivos)

| Archivo | Estado |
|---------|--------|
| `.github/.gitkeep` | D |
| `.github/ISSUE_TEMPLATE/.gitkeep` | D |
| `agentes/.gitkeep` | D |
| `arquitectura/.gitkeep` | D |
| `arquitectura/decisiones/.gitkeep` | D |
| `arquitectura/diagramas/.gitkeep` | D |
| `builders/.gitkeep` | D |
| `configuracion/.gitkeep` | D |
| `documentacion/.gitkeep` | D |
| `documentacion/arquitectura/.gitkeep` | D |
| `documentacion/manuales/.gitkeep` | D |
| `documentacion/requisitos/.gitkeep` | D |
| `herramientas/.gitkeep` | D |
| `memoria/.gitkeep` | D |
| `motor/.gitkeep` | D |
| `perfiles/.gitkeep` | D |
| `plantillas/.gitkeep` | D |
| `protocolos/.gitkeep` | D |
| `proveedores/.gitkeep` | D |
| `pruebas/.gitkeep` | D |
| `pruebas/integracion/.gitkeep` | D |
| `pruebas/unitarias/.gitkeep` | D |
| `scripts/.gitkeep` | D |
| `engine/.gitkeep` | — |
| `infra/.gitkeep` | — |

**Total: 25 archivos** (todos eliminados)
**Nota:** `engine/.gitkeep` e `infra/.gitkeep` no aparecen en git status porque esos directorios no existen en HEAD (nunca fueron trackeados).
**Impacto:** NULO. Placeholders sin valor funcional.
**Riesgo:** NULO.
**Acción propuesta:** Coincide con V2 Commit 002.

---

### GRUPO M — Otros (4 archivos)

| Archivo | Estado | Tipo |
|---------|--------|------|
| `Patch-Hermes-AzureTrace.ps1` | D | Eliminado |
| `motor/sandbox/ExecutionDashboard.ps1` | D | Eliminado |
| `motor/sandbox/ExecutionLogger.ps1` | D | Eliminado |
| `motor/sandbox/ExecutionSupervisor.ps1` | D | Eliminado |
| `motor/security/AzureAdResolver.ps1` | D | Eliminado |
| `motor/security/CredentialResolver.ps1` | D | Eliminado |
| `motor/security/KeyVaultResolver.ps1` | D | Eliminado |
| `motor/validation/VersionValidator.ps1` | D | Eliminado |
| `motor/lifecycle/LifecycleManager.ps1` | D | Eliminado |
| `motor/lifecycle/PluginFaultPolicy.ps1` | D | Eliminado |
| `motor/plugins/PluginLoader.ps1` | D | Eliminado |
| `motor/plugins/PluginManager.ps1` | D | Eliminado |
| `motor/discovery/PluginDiscovery.ps1` | D | Eliminado |
| `motor/manifest/` (posible) | D | Eliminado |
| `motor/capabilities/` (posible) | D | Eliminado |
| `motor/wizards/FirstRunWizard.ps1` | D | Eliminado |
| `motor/wizards/ProjectWizard.ps1` | D | Eliminado |
| `motor/wizards/SandboxWizard.ps1` | D | Eliminado |
| `motor/context/` (posible) | D | Eliminado |
| `motor/observability/` (posible) | D | Eliminado |
| `.hermes/sessions/671235882e47.json` | ?? | Nuevo |
| `engine/Scripts/CaptureGitRepo.ps1` | ?? | Nuevo |
| `engine/Scripts/CreateExternalProject.ps1` | ?? | Nuevo |
| `engine/Scripts/CreateProject.ps1` | ?? | Nuevo |
| `engine/Scripts/CreateProjectWrapper.ps1` | ?? | Nuevo |
| `engine/Scripts/FixWorkspaceResolver.ps1` | ?? | Nuevo |
| `engine/Scripts/ProduceArchitectureInventory.ps1` | ?? | Nuevo |
| `engine/Scripts/ProduceInventory.ps1` | ?? | Nuevo |
| `engine/Scripts/ProduceModuleInventoryDetailed.ps1` | ?? | Nuevo |
| `engine/Scripts/ProduceModuleStructure.ps1` | ?? | Nuevo |
| `engine/Scripts/ResolveWorkspace.ps1` | ?? | Nuevo |
| `engine/Scripts/RunFilesystemTests.ps1` | ?? | Nuevo |
| `engine/Scripts/RunImportDiagnostics.ps1` | ?? | Nuevo |
| `engine/Scripts/RunImportForensics.ps1` | ?? | Nuevo |
| `engine/Scripts/ValidateAndCreate_Direct.ps1` | ?? | Nuevo |
| `logs/kernel.enterprise.jsonl` | ?? | Nuevo |
| `motor/.hermes/BOOTSTRAP_CONTEXT.json` | ?? | Nuevo |
| `motor/.hermes/LAST_INVOCATION.json` | ?? | Nuevo |
| `reports/BASELINE_GOLDEN_PATH.md` | ?? | Nuevo |
| `reports/FileIndex.json` | ?? | Nuevo |
| `reports/Test-ModuleValidation.ps1` | ?? | Nuevo |
| `reports/ValidateCoreLoad.ps1` | ?? | Nuevo |
| `reports/generate_forensic.ps1` | ?? | Nuevo |
| `reports/pester_result.xml` | ?? | Nuevo |

**Total: 44 archivos** (19 eliminados, 25 nuevos)
**Archivos eliminados:** Stubs de motor/sandbox, motor/security, motor/validation, motor/lifecycle, motor/plugins, motor/discovery, motor/wizards, Patch-Hermes-AzureTrace.ps1.
**Archivos nuevos:** engine/Scripts/ (13 scripts de engine), logs/, motor/.hermes/ (contexto de bootstrap), reports/ (6 archivos de reporte y diagnóstico).
**Impacto:** MEDIO. Los archivos eliminados son stubs sin funcionalidad. Los archivos nuevos son scripts de engine, reports generados, y artefactos de ejecución.
**Riesgo:** MEDIO. Los scripts de engine/ parecen ser una nueva capa de funcionalidad. Verificar dependencias.
**Activos funcionales preservados:** Reports activos (FileIndex.json, BASELINE_GOLDEN_PATH.md, generate_forensic.ps1).
**Recomendación:** Separar en múltiples commits: (1) eliminación stubs motor, (2) engine/Scripts, (3) reports, (4) motor/.hermes/ + logs/.

---

## 3. Matriz de Riesgos

| Grupo | Riesgo | Impacto | Dependencias | Rollback |
|-------|--------|---------|--------------|----------|
| **A** — Documentación | Nulo | Bajo | Ninguna | Inmediato |
| **B** — Arquitectura | **ALTO** | **Crítico** | Kernel.ps1 debe cargar sin EventBus, DI, Runtime | Complejo |
| **C** — Bootstrap | **ALTO** | **Crítico** | Todos los scripts dependen entre sí | Complejo |
| **F** — Providers | **ALTO** | **Crítico** | Kernel.ps1 debe estar modificado para no referenciarlos | Simple |
| **I** — Herramientas | MEDIO | Alto | Dependen de estructura de proyecto | Simple |
| **J** — Configuración | MEDIO | Alto | Referenciado por LoadConfiguration.ps1 | Simple |
| **G** — Sandbox | Bajo | Bajo | Ninguna | Simple |
| **H** — Pruebas | Bajo | Medio | Ninguna | Simple |
| **K** — Plugins | Nulo | Bajo | Ninguna | Simple |
| **L** — .gitkeep | Nulo | Nulo | Ninguna | Simple |
| **M** — Otros | Medio | Medio | engine/ puede depender de tools/ | Variable |

**Riesgo total del working tree: ALTO.** Existen 3 grupos con riesgo ALTO (B, C, F) que afectan componentes críticos del sistema.

---

## 4. Propuesta de Commits

Basado en el análisis anterior, propongo **14 commits** para reconciliar el working tree, alineados con la estrategia V2:

### Commit A01 — Documentación de planificación
| Campo | Valor |
|-------|-------|
| **Archivos** | `AUDIT_REPORT.md`, `BOOTSTRAP_IMPLEMENTATION_PLAN.md`, `CLINE.md`, `GOLDEN_REFACTORING_SEQUENCE.md`, `GOLDEN_REFACTORING_SEQUENCE_V2.md`, `MASTER_REFACTORING_ROADMAP.md`, `docs/DEPENDENCY_MATRIX.md`, `docs/MIGRATION_PLAN.md`, `docs/RISKS.md`, `docs/ROADMAP.md` |
| **Mensaje** | `docs(planning): add planning documents and architecture decisions` |
| **Riesgo** | Nulo |
| **Coincide V2** | Nuevo (no listado en V2) |

### Commit A02 — Acualizar CHANGELOG.md
| Campo | Valor |
|-------|-------|
| **Archivos** | `CHANGELOG.md` (modificado) |
| **Mensaje** | `docs(repo): update CHANGELOG.md` |
| **Riesgo** | Nulo |
| **Coincide V2** | V2 Commit 015 (mover a docs/) |

### Commit A03 — Eliminar .gitkeep (V2 Commit 002)
| Campo | Valor |
|-------|-------|
| **Archivos** | 22 archivos .gitkeep |
| **Mensaje** | `chore(repo): remove all .gitkeep placeholder files` |
| **Riesgo** | Nulo |
| **Coincide V2** | Commit 002 |

### Commit A04 — Limpiar sandboxes obsoletos (V2 Commit 003)
| Campo | Valor |
|-------|-------|
| **Archivos** | 20 archivos sandbox eliminados, `sandbox/Local/` (nuevo) |
| **Mensaje** | `chore(sandbox): remove obsolete test projects, keep only Local/` |
| **Riesgo** | Bajo |
| **Coincide V2** | Commit 003 |

### Commit A05 — Eliminar módulos stub de motor/ (V2 Commits 006-011, 013)
| Campo | Valor |
|-------|-------|
| **Archivos** | `motor/configuracion/`, `motor/contracts/`, `motor/dependencias/`, `motor/dependencygraph/`, `motor/discovery/`, `motor/eventos/`, `motor/lifecycle/`, `motor/plugins/`, `motor/providers/`, `motor/registro/`, `motor/runtime/`, `motor/sandbox/`, `motor/security/`, `motor/validation/`, `motor/wizards/`, `Patch-Hermes-AzureTrace.ps1` |
| **Mensaje** | `refactor(motor): remove stub modules and vestigial components` |
| **Riesgo** | **ALTO** — Verificar Kernel.ps1 carga sin estos archivos |
| **Coincide V2** | Commits 005-011, 013 |

### Commit A06 — Agregar nuevo motor bootstrap (V2 Commits 030-037 parcial)
| Campo | Valor |
|-------|-------|
| **Archivos** | `motor/bootstrap/BootstrapOrchestrator.ps1`, `motor/bootstrap/Git.ps1`, `motor/bootstrap/GitHub.ps1`, `motor/bootstrap/Python.ps1`, `motor/bootstrap/Reporting.ps1`, `motor/bootstrap/Security.ps1`, `motor/bootstrap/Synchronization.ps1`, `motor/bootstrap/Templates.ps1`, `motor/bootstrap/Tests.ps1`, `motor/bootstrap/Validation.ps1`, `motor/bootstrap/functions/GitHub.ps1`, `motor/bootstrap/functions/GitHubProvision.ps1`, `motor/bootstrap/functions/README.md`, `motor/bootstrap/functions/VSCode.ps1`, `motor/bootstrap/functions/Python.ps1` |
| **Mensaje** | `feat(bootstrap): add new bootstrap engine modules and functions` |
| **Riesgo** | **ALTO** |
| **Coincide V2** | Commits 030-034, 037 (parcial) |

### Commit A07 — Agregar entrypoint y entrypoints públicos
| Campo | Valor |
|-------|-------|
| **Archivos** | `Start-HermesProject.ps1`, `bootstrap.json`, `bootstrap.yaml` |
| **Mensaje** | `feat(bootstrap): add public entrypoint and bootstrap config files` |
| **Riesgo** | Medio |
| **Coincide V2** | Commits 037, 042, 045 (parcial) |

### Commit A08 — Agregar configuración del kernel
| Campo | Valor |
|-------|-------|
| **Archivos** | `configuracion/kernel.enterprise.json`, `Hermes.config.json`, `motor/config/Configuration.psm1` |
| **Mensaje** | `feat(config): add kernel configuration and configuration manager` |
| **Riesgo** | Medio |
| **Coincide V2** | Nuevo |

### Commit A09 — Agregar herramientas core
| Campo | Valor |
|-------|-------|
| **Archivos** | `tools/EnterprisePipeline.ps1` (modificado), `tools/BootstrapContext.ps1`, `tools/WorkspaceResolver.psm1`, `tools/HermesPathResolver.psm1`, `tools/LoadConfiguration.ps1`, `tools/Write-HermesLog.ps1`, `tools/Invoke-EnterprisePipeline.ps1`, `tools/DryRun.ps1`, `tools/ExecutionReportEngine.psm1`, `tools/Observabilidad.ps1` |
| **Mensaje** | `feat(tools): add core tools: pipeline, workspace resolver, logging, observability` |
| **Riesgo** | Medio |
| **Coincide V2** | Parcial (algunas herramientas existentes, otras nuevas) |

### Commit A10 — Agregar herramientas de validación
| Campo | Valor |
|-------|-------|
| **Archivos** | `tools/ValidateConfiguration.ps1`, `tools/ValidateModules.ps1`, `tools/Validation.psm1`, `tools/VerifyEnvironment.ps1`, `tools/VerifyGitHub.ps1`, `tools/VerifyVSCode.ps1`, `tools/GenerateIntegrityReport.ps1`, `tools/Integration.ps1` |
| **Mensaje** | `feat(tools): add validation and verification tools` |
| **Riesgo** | Bajo |
| **Coincide V2** | Nuevo |

### Commit A11 — Agregar herramientas de proyecto
| Campo | Valor |
|-------|-------|
| **Archivos** | `tools/ProjectFactory.psm1`, `tools/ProjectFactoryV2.psm1`, `tools/Publish.ps1`, `tools/Registry.psm1`, `tools/Scheduler.ps1` |
| **Mensaje** | `feat(tools): add project factory, publish, registry, and scheduler` |
| **Riesgo** | Bajo |
| **Coincide V2** | Nuevo |

### Commit A12 — Agregar engine scripts
| Campo | Valor |
|-------|-------|
| **Archivos** | Todos los `engine/Scripts/*.ps1` (13 archivos) |
| **Mensaje** | `feat(engine): add engine scripts for project management and diagnostics` |
| **Riesgo** | Medio |
| **Coincide V2** | Nuevo |

### Commit A13 — Agregar reports y artefactos de diagnóstico
| Campo | Valor |
|-------|-------|
| **Archivos** | `reports/BASELINE_GOLDEN_PATH.md`, `reports/FileIndex.json`, `reports/Test-ModuleValidation.ps1`, `reports/ValidateCoreLoad.ps1`, `reports/generate_forensic.ps1`, `reports/pester_result.xml` |
| **Mensaje** | `chore(reports): add diagnostic reports and validation scripts` |
| **Riesgo** | Bajo |
| **Coincide V2** | Nuevo |

### Commit A14 — Agregar tests
| Campo | Valor |
|-------|-------|
| **Archivos** | `tests/bootstrap/Test-StartHermesProject.ps1` (modificado), `tests/Test-StartHermesProject.ps1`, `tests/security/Test-GitSynchronization.ps1`, `pruebas/bootstrap/Test-StartHermesProject.ps1`, `pruebas/diagnostico/script_minimo.ps1` |
| **Mensaje** | `test(bootstrap): add and update Pester tests` |
| **Riesgo** | Bajo |
| **Coincide V2** | Commits 020-028 (parcial) |

**Nota:** Los archivos en `pruebas/salida-temporal/`, `.hermes/sessions/`, `logs/`, `motor/.hermes/` y `.env` deben ser incluidos en `.gitignore` y **NO** commiteados.

---

## 5. Orden de Ejecución

```
A01 → A02 → A03 → A04 → A05 → A06 → A07 → A08 → A09 → A10 → A11 → A12 → A13 → A14
 │      │      │      │      │      │      │      │      │      │      │      │      │      │
 │      │      │      │      │      │      │      │      │      │      │      │      │      └── Tests
 │      │      │      │      │      │      │      │      │      │      │      │      └── Reports
 │      │      │      │      │      │      │      │      │      │      │      └── Engine scripts
 │      │      │      │      │      │      │      │      │      │      └── Herramientas proyecto
 │      │      │      │      │      │      │      │      │      └── Herramientas validación
 │      │      │      │      │      │      │      │      └── Herramientas core
 │      │      │      │      │      │      │      └── Config kernel
 │      │      │      │      │      │      └── Entrypoint
 │      │      │      │      │      └── Bootstrap motores
 │      │      │      │      └── Eliminar stubs (ALTO RIESGO)
 │      │      │      └── Limpiar sandbox
 │      │      └── Eliminar .gitkeep
 │      └── CHANGELOG
 └── Documentos planificación
```

**Dependencias clave:**
- **A05** debe ejecutarse **antes** de validar que Kernel.ps1 funciona sin los módulos eliminados
- **A06-A07** dependen de A05 (el nuevo bootstrap no debe coexistir con los viejos stubs)
- **A09** depende de A08 (LoadConfiguration.ps1 necesita kernel.enterprise.json)
- **A12** no tiene dependencias fuertes (puede ejecutarse en cualquier orden después de A05)

---

## 6. Matriz de Dependencias

| Commit | Depende de | Dependientes | Bloqueante |
|--------|-----------|--------------|------------|
| A01 | Ninguna | Ninguno | No |
| A02 | Ninguna | Ninguno | No |
| A03 | Ninguna | A05 | No |
| A04 | Ninguna | Ninguno | No |
| A05 | A03 | A06, A07, A08, A09, A12 | **Sí** |
| A06 | A05 | A07 | No |
| A07 | A05, A06 | Ninguno | No |
| A08 | A05 | A09 | No |
| A09 | A05, A08 | A10, A11 | No |
| A10 | A09 | Ninguno | No |
| A11 | A09 | Ninguno | No |
| A12 | A05 | Ninguno | No |
| A13 | Ninguna | Ninguno | No |
| A14 | A05 | Ninguno | No |

**Ruta crítica:** A03 → **A05** → A06 → A07
**Punto único de fallo:** A05 (eliminación de stubs). Si algo sale mal aquí, el resto del plan se detiene.

---

## 7. Estrategia de Rollback

| Commit | Rollback |
|--------|----------|
| A01 | `git rm <files>` (son nuevos, no hay HEAD previo) |
| A02 | `git checkout HEAD -- CHANGELOG.md` |
| A03 | `git checkout HEAD -- <cada .gitkeep>` o restaurar desde stash |
| A04 | `git checkout HEAD -- sandbox/` |
| A05 | `git checkout HEAD -- motor/ Patch-Hermes-AzureTrace.ps1` |
| A06 | `git rm -r motor/bootstrap/BootstrapOrchestrator.ps1 motor/bootstrap/Git.ps1 ...` |
| A07 | `git rm Start-HermesProject.ps1 bootstrap.json bootstrap.yaml` |
| A08 | `git rm configuracion/kernel.enterprise.json Hermes.config.json motor/config/` |
| A09 | `git checkout HEAD -- tools/EnterprisePipeline.ps1 ...` |
| A10 | `git rm tools/ValidateConfiguration.ps1 ...` |
| A11 | `git rm tools/ProjectFactory.psm1 ...` |
| A12 | `git rm -r engine/` |
| A13 | `git rm reports/*` |
| A14 | `git rm tests/ pruebas/` |

**Rollback total:** `git reset --soft HEAD~14 && git stash` (vuelve al estado anterior a los 14 commits)

---

## 8. Confirmación de Activos Preservados

| Activo | Ruta | Estado en WT | Compromiso |
|--------|------|-------------|------------|
| EnvironmentManager | `motor/bootstrap/environment/EnvironmentManager.ps1` | **NO EXISTE** | No se elimina porque no existe |
| BootstrapRequest | `motor/bootstrap/request/BootstrapRequest.ps1` | Preservado en HEAD | ✅ No se toca |
| BootstrapState | `motor/bootstrap/engine/BootstrapState.ps1` | Preservado en HEAD | ✅ No se toca |
| BootstrapWizard | `motor/bootstrap/engine/BootstrapWizard.ps1` | Preservado en HEAD | ✅ No se toca |
| GitHub.ps1 (functions) | `motor/bootstrap/functions/GitHub.ps1` | **Nuevo (??)** | ✅ Se commitea como nuevo |
| Python.ps1 (functions) | `motor/bootstrap/functions/Python.ps1` | **Nuevo (??)** | ✅ Se commitea como nuevo |
| bootstrap.enterprise.json | `configuracion/bootstrap.enterprise.json` | Preservado en HEAD | ✅ No se toca |
| kernel.enterprise.json | `configuracion/kernel.enterprise.json` | **Nuevo (??)** | ✅ Se commitea como nuevo |
| Start-HermesProject.ps1 (entry) | `motor/bootstrap/Start-HermesProject.ps1` | Modificado (M) | ✅ Se preserva modificación |
| Kernel.ps1 | `motor/kernel/Kernel.ps1` | Modificado (M) | ✅ Se preserva modificación |

**Ningún activo funcional identificado será perdido en el proceso de reconciliación.**

---

## 9. Recomendaciones

1. **Ejecutar A05 primero que A06** — No tiene sentido agregar el nuevo bootstrap si los stubs viejos aún existen.
2. **Validar Kernel.ps1 después de A05** — Antes de continuar con A06, verificar que `motor/kernel/Kernel.ps1` cargue sin errores sin los módulos eliminados.
3. **Agregar `.gitignore` antes de cualquier commit** — Excluir: `pruebas/salida-temporal/`, `.hermes/sessions/`, `logs/`, `motor/.hermes/`, `.env`.
4. **NO commitear `bootstrap.yaml` ahora** — El plan V2 Commit 014 lo marca para eliminación. Si se commitea ahora, habrá que eliminarlo después.
5. **El tag rc13-pre-refactor-v2 debe ir DESPUÉS de A14** — Para que el tag capture el estado reconciliado completo.
6. **Los commits A01-A14 reemplazan el Commit 001 del V2** — El tag snapshot será el último paso, no el primero.
7. **Considerar mover `.env` a `docs/.env.example`** — Como especifica V2 Commit 017, no debe commitearse como `.env` en la raíz.

---

## 10. Resumen Final

| Grupo | Archivos | Commits | Riesgo | Prioridad |
|-------|----------|---------|--------|-----------|
| A — Documentación | 10 | A01, A02 | Nulo | Alta |
| L — .gitkeep | 22 | A03 | Nulo | Alta |
| G — Sandbox | 20 | A04 | Bajo | Alta |
| F+B — Providers + Stubs | 37 | A05 | **ALTO** | **Crítica** |
| C — Bootstrap | 15 | A06, A07 | **ALTO** | Alta |
| J — Configuración | 3 | A08 | Medio | Alta |
| I — Herramientas core | 10 | A09 | Medio | Alta |
| I — Herramientas validación | 8 | A10 | Bajo | Media |
| I — Herramientas proyecto | 5 | A11 | Bajo | Media |
| M — Engine scripts | 13 | A12 | Medio | Media |
| M — Reports | 6 | A13 | Bajo | Baja |
| H — Tests | 5 | A14 | Bajo | Media |

**Total: 14 commits, ~154 archivos, 0 activos funcionales perdidos.**

---

*Documento generado como parte del proceso PRE-COMMIT 000 — Working Tree Reconciliation.*
*Próximo paso: Esperar aprobación humana antes de ejecutar cualquier commit.*