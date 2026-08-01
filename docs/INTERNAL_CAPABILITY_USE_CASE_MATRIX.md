# HERMES ENTERPRISE — Internal Capability × Use Case Matrix

**Versión:** 1.0  
**Fecha:** 2026-08-01  
**Autor:** Architecture Review Board  
**Propósito:**  
Mapear exhaustivamente cada Use Case y cada Capacidad definidos en los contratos contra su estado real de implementación en el código. Identificar brechas exactas.

---

## Tabla de Contenidos

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Filosofía de la Matriz](#2-filosofía-de-la-matriz)
3. [Matriz Capability × Use Case (Core)](#3-matriz-capability--use-case-core)
4. [Catálogo de Casos de Uso](#4-catálogo-de-casos-de-uso)
5. [Catálogo de Capacidades](#5-catálogo-de-capacidades)
6. [Mapa de Implementación (Contrato → Código)](#6-mapa-de-implementación-contrato--código)
7. [Matriz de Brechas (Gap Analysis)](#7-matriz-de-brechas-gap-analysis)
8. [Recomendaciones por Sprint](#8-recomendaciones-por-sprint)

---

## 1. Resumen Ejecutivo

| Métrica | Valor |
|---------|-------|
| **Use Cases definidos en contratos (KERNEL_CONTRACT_SPECIFICATION.md)** | **47 contratos** (IKernel, IRuntime, IContext, IEventBus, etc.) |
| **Capacidades mapeadas en CAPABILITY_MAP.md** | **86 capacidades** (55 implementadas, 12 parciales, 19 faltantes) |
| **Capacidades registradas en CapabilityRegistry.ps1** | **0** (registro vacío — no se ha llamado a Register-Capability) |
| **UseCaseContexts en código** | **1** (New-UseCaseContext function) — genérico, ningún caso registrado |
| **Engines registrados en EngineRegistry.ps1** | **0** (registro vacío — solo estructura de datos) |
| **Providers registrados en ProviderRegistry.ps1** | **0** (registro vacío) |
| **PipelineOrchestrator en código** | **1** (Invoke-UseCasePipeline) — genérico, sin pipelines registrados |
| **ExecutionBroker** | **1** (Invoke-ExecutionBroker) — stub que resuelve capacidades pero no ejecuta |
| **Gap general (contrato vs implementación)** | **~85%** (45/47 contratos sin implementación ejecutable) |

### Conclusión

El sistema tiene una **arquitectura de contratos madura** (47 contratos definidos, congelados en KERNEL_CONTRACT_SPECIFICATION.md) y una **infraestructura de ejecución diseñada** (CapabilityRegistry, PipelineOrchestrator, UseCaseContext, EngineRegistry, ProviderRegistry), pero **ninguna capacidad ha sido registrada**, **ningún engine ha sido implementado**, y **ningún provider ha sido instanciado**. La brecha entre el diseño y la implementación es del ~85%.

Las únicas capacidades que **realmente funcionan** son las implementadas directamente en `motor/bootstrap/` y `motor/kernel/Kernel.ps1`, que **no pasan por el sistema de capacidades**.

---

## 2. Filosofía de la Matriz

### 2.1 Relaciones fundamentales

```
┌────────────────────────────────────────────────────────────┐
│                     USE CASE                                │
│  "Inicializar el Kernel"                                    │
│                                                             │
│  RequiredCapabilities: [                                    │
│    "context.create",                                        │
│    "config.load",                                           │
│    "logging.initialize",                                    │
│    "eventbus.create"                                        │
│  ]                                                          │
│                                                             │
│  ┌───────────────┐     ┌──────────────────┐                 │
│  │   ENGINE      │     │    PROVIDER      │                 │
│  │  Resuelve     │     │   Implementa     │                 │
│  │  la lógica    │     │   la conexión    │                 │
│  │  de negocio   │     │   externa        │                 │
│  └───────────────┘     └──────────────────┘                 │
└────────────────────────────────────────────────────────────┘
```

### 2.2 Niveles de madurez en esta matriz

| Nivel | Etiqueta | Significado |
|-------|----------|-------------|
| 🟢 **IMPLEMENTADO** | Código ejecutable existe y está en producción | `Invoke-UseCasePipeline` funciona con capacidades registradas |
| 🟡 **PARCIAL** | Código existe pero incompleto | Función definida pero no integrada al pipeline |
| 🔵 **DISEÑADO** | Contrato definido, estructura lista | CapabilityRegistry, EngineRegistry existen pero vacíos |
| ⚪ **ESBOZADO** | Solo interfaz/firma definida | Contrato en KERNEL_CONTRACT.md sin implementación |
| 🔴 **AUSENTE** | No existe ni contrato ni código | Capacidad listada en CAPABILITY_MAP.md como futura |

---

## 3. Matriz Capability × Use Case (Core)

### 3.1 Matriz 47 Contratos vs Implementación

| # | Contrato (KERNEL_CONTRACT.md) | Estado Contrato | Capability asociada | Implementación en código | Madurez |
|---|-------------------------------|-----------------|---------------------|--------------------------|---------|
| 1 | **IKernel** | Congelado v1.0.0 | `kernel.initialize` | `motor/kernel/Kernel.ps1` — 103 líneas funcionales | 🟢 IMPLEMENTADO |
| 2 | **IRuntime** | Congelado v1.0.0 | `runtime.start` | `motor/runtime/Runtime.ps1` — existe pero vacío | ⚪ ESBOZADO |
| 3 | **IContext** | Congelado v1.0.0 | `context.create` | `motor/kernel/Context.ps1`, `motor/kernel/KernelContext.ps1` — implementación real | 🟢 IMPLEMENTADO |
| 4 | **IServiceContainer** | Congelado v1.0.0 | `di.register` | `motor/dependencias/DependencyInjection.ps1` (47 líneas) | 🟡 PARCIAL |
| 5 | **IEventBus** | Congelado v1.0.0 | `eventbus.publish` | `motor/eventos/EventBus.ps1` (64 líneas funcional) | 🟢 IMPLEMENTADO |
| 6 | **IConfigurationManager** | Congelado v1.0.0 | `config.load` | `motor/configuracion/ConfigurationManager.ps1` + `motor/config/Configuration.psm1` | 🟡 PARCIAL |
| 7 | **IConfigurationSource** | Congelado v1.0.0 | `config.source.add` | No implementado como interfaz — solo carga directa de JSON | 🔵 DISEÑADO |
| 8 | **ILogger** | Congelado v1.0.0 | `logging.initialize` | `motor/logging/` — directorio existe, sin implementación completa | ⚪ ESBOZADO |
| 9 | **IObservabilityProvider** | Aprobado v1.0.0 | `observability.track` | No implementado | 🔴 AUSENTE |
| 10 | **IMetricsCollector** | Aprobado v1.0.0 | `metrics.collect` | No implementado | 🔴 AUSENTE |
| 11 | **IHealthMonitor** | Aprobado v1.0.0 | `health.check` | `motor/kernel/KernelHealth.ps1` — existe | 🟡 PARCIAL |
| 12 | **ITracer** | Aprobado v1.0.0 | `tracing.start` | No implementado | 🔴 AUSENTE |
| 13 | **IRegistry** | Aprobado v1.0.0 | `registry.register` | `motor/registro/ModuleRegistry.ps1` — existe | 🟡 PARCIAL |
| 14 | **ISecurityManager** | Aprobado v1.0.0 | `security.validate` | No implementado | 🔴 AUSENTE |
| 15 | **IIdentityProvider** | Propuesto v0.5.0 | `identity.authenticate` | No implementado | 🔴 AUSENTE |
| 16 | **ISessionManager** | Aprobado v1.0.0 | `session.start` | `motor/session/` — directorio existe, sin implementación | ⚪ ESBOZADO |
| 17 | **IPipeline** | Aprobado v1.0.0 | `pipeline.execute` | `motor/kernel/Pipeline/PipelineOrchestrator.ps1` — ORQUESTADOR diseñado, SIN pipelines registrados | 🔵 DISEÑADO |
| 18 | **IEngine** | Propuesto v0.5.0 | `engine.execute` | `motor/kernel/Engine/EngineBase.ps1`, `EngineFactory.ps1`, `EngineRegistry.ps1` — infraestructura lista, SIN engines | 🔵 DISEÑADO |
| 19 | **IProvider** | Propuesto v0.5.0 | `provider.invoke` | `motor/kernel/Providers/ProviderBase.ps1`, `ProviderFactory.ps1`, `ProviderRegistry.ps1` — infraestructura lista, SIN providers | 🔵 DISEÑADO |
| 20 | **IBootstrap** | Congelado v1.0.0 | `bootstrap.execute` | `motor/bootstrap/Start-HermesProject.ps1` (~400 líneas), `BootstrapOrchestrator.ps1` (~200), `BootstrapWizard.ps1` (~300) | 🟢 IMPLEMENTADO |
| 21 | **IWorkspace** | Aprobado v1.0.0 | `workspace.inspect` | `tools/WorkspaceResolver.psm1` — existe pero vestigial | 🟡 PARCIAL |
| 22 | **IEnvironment** | Aprobado v1.0.0 | `environment.detect` | `tools/VerifyEnvironment.ps1` — existe | 🟢 IMPLEMENTADO |
| 23 | **ITemplate** | Propuesto v0.5.0 | `template.render` | No implementado | 🔴 AUSENTE |
| 24 | **IValidation** | Aprobado v1.0.0 | `validation.run` | `motor/bootstrap/functions/Validation.ps1` — existe | 🟡 PARCIAL |
| 25 | **IDocumentation** | Propuesto v0.5.0 | `documentation.generate` | `builders/DocumentBuilder.ps1` — existe pero es código muerto | 🔴 AUSENTE |
| 26 | **IReporting** | Propuesto v0.5.0 | `reporting.generate` | `tools/GenerateIntegrityReport.ps1` — código muerto | 🔴 AUSENTE |
| 27 | **ITesting** | Propuesto v0.5.0 | `testing.execute` | `pruebas/unitarias/` — tests incompletos | 🟡 PARCIAL |
| 28 | **IRecovery** | Propuesto v0.5.0 | `recovery.restore` | No implementado | 🔴 AUSENTE |
| 29 | **IPublishing** | Propuesto v0.5.0 | `publishing.publish` | `tools/Publish.ps1` — existe pero vestigial | ⚪ ESBOZADO |
| 30 | **IDeployment** | Propuesto v0.5.0 | `deployment.deploy` | No implementado | 🔴 AUSENTE |
| 31 | **ICloud** | Propuesto v0.5.0 | `cloud.provision` | No implementado | 🔴 AUSENTE |
| 32 | **IAzure** | Propuesto v0.5.0 | `azure.authenticate` | `motor/providers/azure/AzureProviderAuthentication.ps1` — código muerto | 🔴 AUSENTE |
| 33 | **IGit** | Propuesto v0.5.0 | `git.operations` | `motor/bootstrap/functions/Git.ps1` (35 líneas) | 🟡 PARCIAL |
| 34 | **IGitHub** | Propuesto v0.5.0 | `github.api` | `motor/bootstrap/GitHub.ps1` — código muerto | 🔴 AUSENTE |
| 35 | **IStorage** | Propuesto v0.5.0 | `storage.provision` | No implementado | 🔴 AUSENTE |
| 36 | **IDataLake** | Propuesto v0.5.0 | `datalake.query` | No implementado | 🔴 AUSENTE |
| 37 | **IBlob** | Propuesto v0.5.0 | `blob.upload` | No implementado | 🔴 AUSENTE |
| 38 | **IDatabase** | Propuesto v0.5.0 | `database.connect` | No implementado | 🔴 AUSENTE |
| 39 | **IAI** | Propuesto v0.5.0 | `ai.inference` | No implementado | 🔴 AUSENTE |
| 40 | **IMessaging** | Propuesto v0.5.0 | `messaging.send` | No implementado | 🔴 AUSENTE |
| 41 | **IPluginManager** | Aprobado v1.0.0 | `plugin.manage` | `motor/plugins/PluginManager.ps1` — existe pero vestigial | ⚪ ESBOZADO |
| 42 | **ICapabilityRegistry** | Propuesto v0.5.0 | `capability.register` | `motor/kernel/Capabilities/CapabilityRegistry.ps1` — DISEÑADO pero vacío | 🔵 DISEÑADO |
| 43 | **IDiscovery** | Propuesto v0.5.0 | `discovery.scan` | `motor/kernel/Discovery/EngineDiscovery.ps1`, `ProviderDiscovery.ps1` — estructura vacía | 🔵 DISEÑADO |
| 44 | **IScheduler** | Propuesto v0.5.0 | `scheduler.schedule` | `tools/Scheduler.ps1` — existe pero vestigial | ⚪ ESBOZADO |
| 45 | **IManifest** | Propuesto v0.5.0 | `manifest.load` | `motor/manifest/` — directorio vacío | 🔴 AUSENTE |
| 46 | **ICapabilityProvider** | — | `capability.resolve` | `motor/kernel/CapabilityProvider.ps1` — existe, Resolve-ExecutionRequest | 🟢 IMPLEMENTADO |
| 47 | **IExecutionBroker** | — | `execution.broker` | `motor/kernel/ExecutionBroker.ps1` — Invoke-ExecutionBroker | 🟢 IMPLEMENTADO |

### 3.2 Resumen de la Matriz

| Estado | Cantidad | % |
|--------|----------|---|
| 🟢 IMPLEMENTADO | 7 | 14.9% |
| 🟡 PARCIAL | 9 | 19.1% |
| 🔵 DISEÑADO | 5 | 10.6% |
| ⚪ ESBOZADO | 5 | 10.6% |
| 🔴 AUSENTE | 21 | 44.7% |

---

## 4. Catálogo de Casos de Uso

Cada caso de uso se define como: **qué operación de alto nivel realiza el sistema**, qué capacidades requiere, qué contrato implementa, y cuál es su estado real.

### 4.1 Casos de Uso del Núcleo (Core — Sprint Actual)

| ID | Caso de Uso | Capacidades Requeridas | Contrato | Estado Código | Pipeline Registrado |
|----|-------------|----------------------|----------|---------------|-------------------|
| UC-01 | **Inicializar Kernel Enterprise** | `kernel.initialize`, `context.create`, `config.load` | IKernel | 🟢 Kernel.ps1 ejecuta | ❌ No pasa por PipelineOrchestrator |
| UC-02 | **Iniciar Runtime** | `runtime.start`, `di.resolve`, `eventbus.publish` | IRuntime | ⚪ Runtime.ps1 existe pero vacío | ❌ No |
| UC-03 | **Crear Contexto de Proyecto** | `context.create`, `workspace.inspect` | IContext | 🟢 Context.ps1 funcional | ❌ No |
| UC-04 | **Publicar Evento en Bus** | `eventbus.publish`, `eventbus.subscribe` | IEventBus | 🟢 EventBus.ps1 funcional | ❌ No |
| UC-05 | **Cargar Configuración** | `config.load`, `config.source.add` | IConfigurationManager | 🟡 Parcial — 2 implementaciones | ❌ No |
| UC-06 | **Registrar Servicio en DI** | `di.register`, `di.resolve` | IServiceContainer | 🟡 Parcial — 3 implementaciones | ❌ No |
| UC-07 | **Ejecutar Pipeline de Use Case** | `pipeline.execute`, `capability.resolve` | IPipeline | 🔵 PipelineOrchestrator.ps1 diseñado pero sin pipelines | 🔵 Estructura lista |
| UC-08 | **Ejecutar Bootstrap de Proyecto** | `bootstrap.execute`, `git.operations` | IBootstrap | 🟢 Start-HermesProject.ps1 funcional | ❌ No |
| UC-09 | **Registrar Capacidad** | `capability.register`, `discovery.scan` | ICapabilityRegistry | 🔵 CapabilityRegistry.ps1 diseñado pero vacío | ❌ No |
| UC-10 | **Ejecutar Engine** | `engine.execute`, `di.resolve` | IEngine | 🔵 EngineBase.ps1 + Factory + Registry diseñados pero SIN engines | ❌ No |
| UC-11 | **Invocar Provider** | `provider.invoke`, `di.resolve` | IProvider | 🔵 ProviderBase.ps1 + Factory + Registry diseñados pero SIN providers | ❌ No |

### 4.2 Casos de Uso de Infraestructura (Sprint A — Safe Sandbox)

| ID | Caso de Uso | Capacidades Requeridas | Contrato | Estado Código |
|----|-------------|----------------------|----------|---------------|
| UC-12 | **Crear Snapshot de Sandbox** | `sandbox.snapshot`, `storage.provision` | IRecovery | 🔴 No implementado |
| UC-13 | **Restaurar Sandbox** | `sandbox.restore`, `storage.read` | IRecovery | 🔴 No implementado |
| UC-14 | **Rollback de Operación** | `sandbox.rollback`, `transaction.log` | IRecovery | 🔴 No implementado |
| UC-15 | **Recuperar Sandbox Fallido** | `sandbox.recover`, `health.check` | IRecovery | 🔴 No implementado |
| UC-16 | **Registrar Transacción** | `transaction.log`, `eventbus.publish` | IEventBus | 🔴 No implementado |

### 4.3 Casos de Uso de Generación (Sprint B — Project Generator)

| ID | Caso de Uso | Capacidades Requeridas | Contrato | Estado Código |
|----|-------------|----------------------|----------|---------------|
| UC-17 | **Generar Proyecto** | `project.generate`, `template.render` | ITemplate | 🔴 No implementado |
| UC-18 | **Renderizar Plantilla** | `template.render`, `file.write` | ITemplate | 🔴 No implementado |
| UC-19 | **Generar Estructura VS Code** | `vscode.configure`, `file.write` | — | 🟡 Parcial — VS Code settings.json existe |
| UC-20 | **Inicializar Git** | `git.init`, `git.commit` | IGit | 🟡 Parcial — Git.ps1 existe |
| UC-21 | **Generar Docker** | `docker.compose`, `file.write` | — | 🔴 No implementado |
| UC-22 | **Generar CI/CD** | `cicd.generate`, `file.write` | — | 🔴 No implementado |
| UC-23 | **Generar Documentación** | `documentation.generate`, `template.render` | IDocumentation | 🔴 Código muerto en builders/ |

### 4.4 Casos de Uso de Memoria y Aprendizaje (Sprint C)

| ID | Caso de Uso | Capacidades Requeridas | Contrato | Estado Código |
|----|-------------|----------------------|----------|---------------|
| UC-24 | **Registrar Decisión** | `memory.store`, `decision.log` | — | 🔴 No implementado |
| UC-25 | **Consultar Knowledge Base** | `knowledge.query`, `ai.inference` | IAI | 🔴 No implementado |
| UC-26 | **Reconocer Patrón** | `pattern.match`, `ai.inference` | IAI | 🔴 No implementado |
| UC-27 | **Registrar Lección Aprendida** | `lesson.store`, `memory.persist` | — | 🔴 No implementado |
| UC-28 | **Generar Métricas de Éxito** | `metrics.collect`, `reporting.generate` | IMetricsCollector | 🔴 No implementado |
| UC-29 | **Analizar Falla** | `failure.analyze`, `ai.inference` | IAI | 🔴 No implementado |

### 4.5 Casos de Uso de Plataforma Autónoma (Sprint D)

| ID | Caso de Uso | Capacidades Requeridas | Contrato | Estado Código |
|----|-------------|----------------------|----------|---------------|
| UC-30 | **Generar Repositorio Enterprise** | `repo.generate`, `github.api` | IGitHub | 🔴 No implementado |
| UC-31 | **Generar Organización** | `org.generate`, `github.api` | IGitHub | 🔴 No implementado |
| UC-32 | **Generar Microservicio** | `microservice.generate`, `template.render` | ITemplate | 🔴 No implementado |
| UC-33 | **Generar Dominio** | `domain.generate`, `template.render` | ITemplate | 🔴 No implementado |
| UC-34 | **Explorar Plugin Marketplace** | `marketplace.browse`, `plugin.manage` | IPluginManager | 🔴 No implementado |
| UC-35 | **Explorar Provider Marketplace** | `marketplace.browse`, `provider.invoke` | IProvider | 🔴 No implementado |

---

## 5. Catálogo de Capacidades

### 5.1 Capacidades Implementadas (existen en código, no en CapabilityRegistry)

| Capacidad | Archivo(s) | Tipo | ¿Registrada en CapabilityRegistry? |
|-----------|-----------|------|-----------------------------------|
| `kernel.initialize` | `motor/kernel/Kernel.ps1` | Función directa | ❌ No |
| `context.create` | `motor/kernel/Context.ps1` | Clase Context | ❌ No |
| `eventbus.publish` | `motor/eventos/EventBus.ps1` | Funciones modulares | ❌ No |
| `eventbus.subscribe` | `motor/eventos/EventBus.ps1` | Funciones modulares | ❌ No |
| `config.load` | `motor/configuracion/ConfigurationManager.ps1` | Script module | ❌ No |
| `bootstrap.execute` | `motor/bootstrap/Start-HermesProject.ps1` | Entrypoint monolítico | ❌ No |
| `environment.detect` | `tools/VerifyEnvironment.ps1` | Script de diagnóstico | ❌ No |
| `execution.broker` | `motor/kernel/ExecutionBroker.ps1` | Función de resolución | ❌ No |
| `capability.resolve` | `motor/kernel/CapabilityProvider.ps1` | Función de resolución | ❌ No |

### 5.2 Capacidades con Infraestructura pero sin Instancias

| Capacidad | Infraestructura | Estado |
|-----------|----------------|--------|
| `engine.execute` | EngineBase.ps1, EngineFactory.ps1, EngineRegistry.ps1 (vacíos) | 🔵 Sin engines registrados |
| `provider.invoke` | ProviderBase.ps1, ProviderFactory.ps1, ProviderRegistry.ps1 (vacíos) | 🔵 Sin providers registrados |
| `pipeline.execute` | PipelineOrchestrator.ps1 (orquestador genérico listo) | 🔵 Sin pipelines registrados |
| `capability.register` | CapabilityRegistry.ps1 (registro listo) | 🔵 Sin capacidades registradas |
| `discovery.scan` | EngineDiscovery.ps1, ProviderDiscovery.ps1 (estructuras vacías) | 🔵 Sin discovery activo |
| `di.register` | DependencyInjection.ps1 (funcional pero con 3 implementaciones) | 🟡 No unificado |

### 5.3 Capacidades de CAPABILITY_MAP.md sin Implementación Alguna

| Capacidad | Dominio | Prioridad CAPABILITY_MAP |
|-----------|---------|------------------------|
| `sandbox.snapshot` | Sandbox | P0 |
| `sandbox.restore` | Sandbox | P0 |
| `sandbox.rollback` | Sandbox | P0 |
| `sandbox.recover` | Sandbox | P0 |
| `transaction.log` | Sandbox | P0 |
| `project.generate` | Generator | P0 |
| `template.render` | Generator | P0 |
| `telemetry.collect` | Observability | P2 |
| `health.monitor` | Observability | P2 |
| `learning.record` | Memory | P1 |
| `knowledge.query` | Memory | P1 |
| `pattern.match` | Memory | P1 |
| `marketplace.browse` | Plugins/Providers | P3 |
| `vscode.configure` | UX | P1 |
| `cicd.generate` | Generator | P1 |
| `docker.generate` | Generator | P1 |
| `documentation.generate` | Generator | P1 |
| `architecture.inspect` | Developer Context | P0 |
| `session.persist` | Sessions | P0 |

---

## 6. Mapa de Implementación (Contrato → Código)

### 6.1 Mapa de Archivos Reales vs Contratos

```
CONTRATO                    ARCHIVO(S)                         LÍNEAS    ESTADO
────────────────────────────────────────────────────────────────────────────────────
IKernel                     motor/kernel/Kernel.ps1             103       🟢
                            motor/kernel/KernelContext.ps1       80        🟢
                            
IRuntime                    motor/runtime/Runtime.ps1            ~50       ⚪ (stub)
                            
IContext                    motor/kernel/Context.ps1             180       🟢
                            
IServiceContainer           motor/dependencias/DependencyInjection.ps1  47  🟡
                            motor/kernel/Core/ServiceContainer.ps1     10  🟡 (a eliminar)
                            motor/dependencias/ServiceLocator.ps1      31  🟡 (a eliminar)
                            
IEventBus                   motor/eventos/EventBus.ps1          64        🟢
                            motor/kernel/Core/EventBus.ps1      14        🟡 (a eliminar)
                            
IConfigurationManager       motor/configuracion/ConfigurationManager.ps1  120  🟡
                            motor/config/Configuration.psm1              60    🟡
                            
ILogger                     motor/logging/                      (vacío)   🔴
                            
IPipeline                   motor/kernel/Pipeline/PipelineOrchestrator.ps1  187  🔵
                            
IEngine                     motor/kernel/Engine/EngineBase.ps1             ~50  🔵
                            motor/kernel/Engine/EngineFactory.ps1          ~50  🔵
                            motor/kernel/Engine/EngineRegistry.ps1         174  🔵
                            motor/kernel/Engine/EngineResolver.ps1         159  🔵
                            
IProvider                   motor/kernel/Providers/ProviderBase.ps1        ~50  🔵
                            motor/kernel/Providers/ProviderFactory.ps1     ~50  🔵
                            motor/kernel/Providers/ProviderRegistry.ps1    ~100 🔵
                            motor/kernel/Providers/ProviderResolver.ps1    ~100 🔵
                            
ICapabilityRegistry         motor/kernel/Capabilities/CapabilityRegistry.ps1  212  🔵
                            motor/kernel/Capabilities/UseCaseContext.ps1      129  🔵
                            
ICapabilityProvider         motor/kernel/CapabilityProvider.ps1            ~30  🟢
                            motor/kernel/Capabilities/                      (varios)
                            
IExecutionBroker            motor/kernel/ExecutionBroker.ps1              23   🟢
                            
IBootstrap                  motor/bootstrap/Start-HermesProject.ps1       400  🟢
                            motor/bootstrap/engine/BootstrapOrchestrator.ps1  200  🟢
                            motor/bootstrap/engine/BootstrapWizard.ps1       300  🟢
                            
IGit                        motor/bootstrap/functions/Git.ps1             35   🟡
                            motor/bootstrap/Git.ps1                       10   🟡 (a eliminar)
```

### 6.2 Estado del Pipeline de Ejecución Real

```
┌─────────────────────────────────────────────────────────────────────┐
│                      FLUJO ACTUAL                                    │
│                                                                       │
│  1. Start-HermesProject.ps1                                           │
│     ↓                                                                 │
│  2. BootstrapOrchestrator.ps1 + BootstrapWizard.ps1 (UI)              │
│     ↓                                                                 │
│  3. Kernel.ps1 (Start-HermesEnterpriseKernel) — carga directa         │
│     ├── Context.ps1                                                    │
│     ├── ConfigurationManager.ps1                                       │
│     ├── EventBus.ps1                                                   │
│     ├── DependencyInjection.ps1                                        │
│     └── Runtime.ps1 (stub)                                             │
│     ↓                                                                 │
│  4. Funciones helper sueltas (no pasan por el pipeline)               │
│                                                                       │
│                      FLUJO DISEÑADO (NO OPERATIVO)                    │
│                                                                       │
│  1. UseCaseContext creado con New-UseCaseContext                       │
│     ↓                                                                 │
│  2. Invoke-UseCasePipeline en PipelineOrchestrator                    │
│     ↓                                                                 │
│  3. Resolve-Capabilities en CapabilityRegistry (VACÍO)                │
│     ↓                                                                 │
│  4. ❌ EngineResolvers — NO HAY                                       │
│     ↓                                                                 │
│  5. ❌ ProviderResolvers — NO HAY                                     │
│     ↓                                                                 │
│  6. ❌ Pipeline falla o no ejecuta nada                               │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 7. Matriz de Brechas (Gap Analysis)

### 7.1 Brechas Críticas (Impiden el funcionamiento del sistema de capacidades)

| Gap ID | Descripción | Impacto | Solución |
|--------|-------------|---------|----------|
| **G-01** | **CapabilityRegistry vacío** — `Register-Capability` nunca fue llamado. El pipeline de capacidades no puede resolver nada. | 🔴 BLOQUEANTE — el sistema de capacidades es inoperable | Registrar las 9 capacidades implementadas (sección 5.1) en CapabilityRegistry |
| **G-02** | **EngineRegistry vacío** — `Register-EngineInRegistry` nunca fue llamado. No hay engines registrados. | 🔴 BLOQUEANTE — no se puede ejecutar Invoke-UseCasePipeline | Implementar y registrar engines mínimos para cada capacidad core |
| **G-03** | **ProviderRegistry vacío** — `Register-ProviderInRegistry` nunca fue llamado. No hay providers registrados. | 🔴 BLOQUEANTE — no se puede resolver providers | Implementar y registrar providers mínimos |
| **G-04** | **PipelineOrchestrator no está conectado al Kernel** — Kernel.ps1 no usa Invoke-UseCasePipeline. | 🔴 BLOQUEANTE — el flujo real no pasa por el pipeline | Integrar PipelineOrchestrator en el startup del Kernel |
| **G-05** | **Sin test unitarios que validen el pipeline** — 0% cobertura. | 🔴 BLOQUEANTE — no se puede refactorizar sin riesgo | M-002 del roadmap (Pester) |

### 7.2 Brechas Altas (Requieren atención en Sprint A/B)

| Gap ID | Descripción | Impacto | Solución |
|--------|-------------|---------|----------|
| **G-06** | **Sin engines implementados** — EngineBase.ps1 existe pero no hay engines concretos (BootstrapEngine, etc.) | 🟠 ALTO — M-006 del roadmap | Refactorizar Start-HermesProject.ps1 → BootstrapEngine.ps1 |
| **G-07** | **Sin providers implementados** — ProviderBase.ps1 existe pero no hay providers concretos (GitProvider, VSCodeProvider, etc.) | 🟠 ALTO — no hay abstracción de integraciones | Migrar Git.ps1 a IGitProvider |
| **G-08** | **EventBus no integrado al pipeline** — EventBus.ps1 es independiente, no se usa desde Invoke-UseCasePipeline | 🟠 ALTO — eventos no fluyen | Agregar logging de eventos en el PipelineOrchestrator |
| **G-09** | **ILogger sin implementación real** — `motor/logging/` está vacío | 🟠 ALTO — sin logging estructurado | Implementar ILogger mínimo que escriba a archivo JSONL |

### 7.3 Brechas Medias (Pueden diferirse a Sprint C/D)

| Gap ID | Descripción | Impacto | Solución |
|--------|-------------|---------|----------|
| **G-10** | **Múltiples archivos de configuración** — 5 archivos compitiendo | 🟡 MEDIO — M-008 del roadmap | Unificar en Hermes.config.json |
| **G-11** | **DI Container duplicado** — 3 implementaciones | 🟡 MEDIO — M-005 del roadmap | Unificar en DependencyInjection.ps1 |
| **G-12** | **Código muerto (13+ archivos)** — distrae y confunde | 🟡 MEDIO — M-015 del roadmap | Eliminar en batch |
| **G-13** | **Módulos stub sin implementación (16 directorios)** — prometen funcionalidad inexistente | 🟡 MEDIO — M-011 del roadmap | Eliminar stubs, mantener solo directorios con código real |

### 7.4 Mapa de Brechas vs Roadmap de Refactorización

```
MASTER_REFACTORING_ROADMAP      →    Gaps que resuelve
──────────────────────────────────────────────────────
M-001: Consolidar kernel único   →    (Precondición estructural)
M-002: Framework pruebas Pester  →    G-05 🔴
M-003: CI/CD pipeline            →    (Calidad)
M-004: Fusionar EventBuses       →    G-08 🟠
M-005: Fusionar DI containers    →    G-11 🟡
M-006: Refactor Start-HermesProj →    G-06 🟠
M-007: Separar Orchestrator/UI   →    (Arquitectura bootstrap)
M-008: Unificar configuración    →    G-10 🟡
M-009: Manejo errores kernel     →    (Resiliencia)
M-010: Eliminar paths hardcoded  →    (Portabilidad)
M-011: Eliminar módulos stub     →    G-13 🟡
M-015: Eliminar código muerto    →    G-12 🟡
```

### 7.5 Costo de Cierre por Gap

| Gap | Esfuerzo estimado | Archivos a crear | Archivos a modificar | Dependencias |
|-----|-------------------|-----------------|---------------------|--------------|
| G-01 | 2 horas | 0 | 1 (CapabilityRegistry.ps1 — agregar registros) | Ninguna |
| G-02 | 4 horas | 3 (engines mínimos) | 1 (EngineRegistry.ps1) | G-01 |
| G-03 | 4 horas | 3 (providers mínimos) | 1 (ProviderRegistry.ps1) | G-01 |
| G-04 | 2 horas | 0 | 1 (Kernel.ps1 — integrar PipelineOrchestrator) | G-01, G-02, G-03 |
| G-05 | 2 días | 5 (tests Pester) | 0 | Ninguna |
| G-06 | 2 días | 2 (BootstrapEngine, VSCodeIntegration) | 1 (Start-HermesProject.ps1) | G-05 |
| G-07 | 4 horas | 2 (GitProvider, VSCodeProvider) | 2 (Git.ps1, ProviderRegistry.ps1) | G-03 |
| G-08 | 2 horas | 0 | 1 (PipelineOrchestrator.ps1) | Ninguna |
| G-09 | 4 horas | 2 (LoggerEngine, FileLogOutput) | 0 | Ninguna |
| G-10 | 1 día | 0 | 5 (archivos config) | Ninguna |
| G-11 | 2 horas | 0 | 3 (DI files) | Ninguna |
| G-12 | 1 hora | 0 | 0 (solo eliminar) | Ninguna |
| G-13 | 2 horas | 0 | 0 (solo eliminar directorios) | Ninguna |

---

## 8. Recomendaciones por Sprint

### 8.1 Sprint Actual (Inmediato) — Cerrar G-01 a G-05

**Objetivo:** Hacer que el sistema de capacidades sea operativo.

| Paso | Acción | Gap |
|------|--------|-----|
| 1 | Registrar las 9 capacidades existentes en `CapabilityRegistry.ps1` | G-01 |
| 2 | Crear 3 engines base (ContextEngine, ConfigEngine, EventBusEngine) | G-02 |
| 3 | Crear 2 providers base (FileProvider, GitProvider) | G-03 |
| 4 | Integrar PipelineOrchestrator en Kernel.ps1 | G-04 |
| 5 | Escribir tests Pester para el flujo completo | G-05 |

### 8.2 Sprint A — Safe Sandbox

**Objetivo:** Sandbox con snapshot/restore/rollback.

| Paso | Acción | Gap |
|------|--------|-----|
| 1 | Implementar SandboxEngine con snapshot/restore | — |
| 2 | Implementar RecoveryProvider | — |
| 3 | Implementar TransactionLogProvider | — |
| 4 | Registrar capacidades de sandbox en CapabilityRegistry | G-01 extendido |

### 8.3 Sprint B — Project Generator

**Objetivo:** Generador de proyectos profesional.

| Paso | Acción | Gap |
|------|--------|-----|
| 1 | Refactorizar Start-HermesProject.ps1 → BootstrapEngine | G-06 |
| 2 | Implementar TemplateEngine | — |
| 3 | Implementar VSCodeProvider, GitProvider, DockerProvider | G-07 |
| 4 | Conectar BootstrapEngine al PipelineOrchestrator | G-04 |

### 8.4 Sprint C — Memory & Learning

**Objetivo:** Motor de memoria y aprendizaje continuo.

| Paso | Acción | Gap |
|------|--------|-----|
| 1 | Implementar LearningEngine | — |
| 2 | Implementar KnowledgeProvider (file-based) | — |
| 3 | Implementar DecisionMemoryProvider | — |
| 4 | Registrar todas las capacidades de memoria | G-01 extendido |

### 8.5 Estrategia de Cierre Total de Brechas

```
FASE INMEDIATA (días 1-3)
├── Registrar capacidades existentes en CapabilityRegistry (G-01) ─── 2h
├── Crear engines base core (G-02) ─── 4h
├── Crear providers base (G-03) ─── 4h
├── Integrar PipelineOrchestrator en Kernel (G-04) ─── 2h
└── Tests Pester para flujo core (G-05) ─── 2d

FASE CORTA (días 4-7)
├── Refactorizar BootstrapEngine (G-06) ─── 2d
├── Implementar GitProvider + VSCodeProvider (G-07) ─── 4h
├── Integrar EventBus en Pipeline (G-08) ─── 2h
├── Implementar ILogger mínimo (G-09) ─── 4h
├── Unificar configuración (G-10) ─── 1d
├── Unificar DI containers (G-11) ─── 2h
├── Eliminar código muerto (G-12) ─── 1h
└── Eliminar módulos stub (G-13) ─── 2h

FASE DE SPRINTS (A-B-C-D)
├── Sprint A: Sandbox (snapshot/restore/rollback)
├── Sprint B: Project Generator (14 generators)
├── Sprint C: Memory & Learning (10 capacidades)
└── Sprint D: Autonomous Platform (12 capacidades)
```

---

## Apéndice A: Leyenda de la Matriz

```
🟢 IMPLEMENTADO  = El código existe, es funcional, y está en uso real
🟡 PARCIAL       = El código existe pero está incompleto, duplicado, o no integrado
🔵 DISEÑADO      = La infraestructura/contrato existe pero no hay instancias concretas
⚪ ESBOZADO      = Solo existe la firma del contrato o un stub mínimo
🔴 AUSENTE       = No existe ni contrato ni código (capacidad futura)
```

## Apéndice B: Datos de Referencia

- **KERNEL_CONTRACT_SPECIFICATION.md**: 47 contratos, 3376 líneas
- **CAPABILITY_MAP.md**: 86 capacidades, 293 líneas
- **MASTER_REFACTORING_ROADMAP.md**: 19 mejoras catalogadas, 1572 líneas
- **Archivos .ps1 reales en motor/kernel/**: 22 archivos (CapabilityRegistry, Engine*, Provider*, Pipeline*, etc.)
- **Líneas de infraestructura de capacidades**: ~1200 líneas de código diseñado, 0 líneas de capacidades registradas

---

*Documento generado con base en análisis estático del código fuente y los contratos definidos. Próxima revisión: post-implementación de G-01 a G-05.*