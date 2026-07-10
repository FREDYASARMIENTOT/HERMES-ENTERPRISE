---
NombreDocumento       : Bootstrap Engine v1.0
Proyecto              : HERMES-ENTERPRISE
Version               : 1.0.0
AutorPrincipal        : Fredy Alejandro Sarmiento Torres
Licencia              : MIT
RepositorioOficial    : https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE
ArquitecturaBase      : Hermes Agent + Azure AI Foundry + MCP + A2A
Estado                : Diseño Aprobado (pendiente de implementación)
FechaAprobacion       : 2026-07-07
AgenciasParticipantes : [Arquitecto Enterprise, Arquitecto DevOps, Auditor Calidad, Revisor Adversarial]
EstadoRevisorAdversarial : APROBADO
FechaGeneracion       : 2026-07-07
---

# Bootstrap Engine v1.0

## Tabla de contenido

- [Navegación](#navegación)
- [Propósito](#propósito)
- [Alcance y fuera de alcance](#alcance-y-fuera-de-alcance)
- [Decisiones del Revisor Adversarial](#decisiones-del-revisor-adversarial)
- [Principios rectores](#principios-rectores)
- [Arquitectura — Diagrama C4 Nivel 1 (Contexto)](#arquitectura--diagrama-c4-nivel-1-contexto)
- [Arquitectura — Diagrama C4 Nivel 2 (Contenedores)](#arquitectura--diagrama-c4-nivel-2-contenedores)
- [Contratos centrales](#contratos-centrales)
- [Mapa de las 13 fases](#mapa-de-las-13-fases)
- [Mapa de archivos nuevos](#mapa-de-archivos-nuevos)
- [Reutilización de módulos existentes](#reutilización-de-módulos-existentes)
- [Gestión de riesgos](#gestión-de-riesgos)
- [Checklist de auditoría de calidad (27 ítems)](#checklist-de-auditoría-de-calidad-27-ítems)
- [Plan de implementación](#plan-de-implementación)
- [Referencias cruzadas](#referencias-cruzadas)

---

## Navegación

- [Índice maestro de documentación](../README.md)
- [Bootstrap Enterprise (legacy — fase de nacimiento inicial del kernel)](../BOOTSTRAP.md)
- [Kernel](../KERNEL.md)
- [Configuración](../CONFIGURATION.md)
- [Runtime](../RUNTIME.md)
- [Logger](../LOGGER.md)
- [EventBus](../EVENT_BUS.md)
- [ProjectWizard (motor/wizards)](../../motor/wizards/ProjectWizard.ps1)

---

## Propósito

Bootstrap Engine v1.0 es el **único punto de entrada oficial para iniciar nuevos proyectos profesionales** dentro de HERMES-ENTERPRISE. No arranca el Kernel; arranca un *nuevo proyecto de software* de arriba a abajo: valida entorno, levanta wizard interactivo, provisiona entorno aislado, genera estructura de proyecto, Git, VS Code, prompt para Hermes CLI, reportes y auditoría final, con rollback compensatorio ante cualquier fallo.

Este documento define el diseño aprobado por las cuatro agencias (Enterprise, DevOps, Calidad, Adversarial) y **constriñe la implementación**. No se permite modificar el diseño sin re-aprobación formal.

---

## Alcance y fuera de alcance

### Incluido

| Área | Detalle |
|---|---|
| Pre-flight (Fase 0) | `hermes doctor` implementado como función interna del Bootstrap |
| Configuración global (Fase 1) | Verificación y creación de `D:\Proyectos_VSCode` y `D:\Environments`, rutas configurables |
| Wizard interactivo (Fase 2) | 11 preguntas con validación regex estricta |
| Environment Manager (Fase 3) | Entorno aislado por proyecto con 11 subcarpetas |
| Project Generator (Fase 4) | Estructura condicional del código fuente |
| README Generator (Fase 5) | Markdown profesional con navegación, arquitectura, roadmap |
| Environment file (Fase 6) | `.env` con comentarios, cero secretos |
| Gitignore generator (Fase 7) | `.gitignore` adaptado al stack |
| Git Manager (Fase 8) | `git init`, branch `main`, commit inicial opcional con switch explícito |
| VS Code opener (Fase 9) | Apertura del proyecto recién creado |
| Prompt Generator (Fase 10) | Archivo `.hermes/bootstrap-prompt.hai` y apertura de CLI |
| Report Engine (Fase 11) | 6 reportes como proyecciones de un único `BootstrapState` |
| Rollback Engine (Fase 12) | Compensator pattern con marcador `.hermes-bootstrap-token` |
| Audit Engine (Fase 13) | Checklist binaria de 27 ítems, score < 27 → rechazo |

### Fuera de alcance

| Ítem | Justificación |
|---|---|
| Modificar el Kernel | Prohibido por restricciones explícitas |
| Modificar EventBus | Prohibido |
| Modificar Logger | Prohibido |
| Modificar ExecutionSupervisor | Prohibido |
| Lógica duplicada con modules existentes | Prohibido: reutilizar, no copiar |
| Push automático a GitHub | No se ejecuta `git push` sin aprobación explícita posterior |

---

## Decisiones del Revisor Adversarial

El RA tiene autoridad de rechazo sobre cualquier decisión de diseño. Antes de aprobar la implementación, **levantó 9 hallazgos críticos** y los cuatro agentes los resolvieron como sigue. Estas son decisiones normativas inmutables para la fase de implementación:

| # | Hallazgo RA | Decisión normativa adoptada |
|---|---|---|
| H1 | Colisión con `Start-HermesEnterprise.ps1` existente | El archivo se convierte en **router multipropósito**. Switch `-Modo` con valores `Bootstrap` (default) y `KernelSession`. API legacy (`-DevolverKernel`, `-DevolverSesion`, `-DevolverContexto`) sigue funcionando intacta. |
| H2 | `hermes doctor` no existe como comando | Se implementa como función interna `Invoke-HermesDoctor` dentro de `motor/bootstrap/engine/phases/Phase00-Doctor.ps1`. No hay dependencia mágica. |
| H3 | Environments fuera del workspace controlado | Rutas configurables vía `configuracion/bootstrap.enterprise.json`. Marcador `.hermes-bootstrap-token` con ACLs por usuario para rollback seguro. |
| H4 | Rollback ambiguo en Fase 12 | Patrón "clean-slate": solo elimina recursos marcados con `.hermes-bootstrap-token` creados en la ejecución actual. |
| H5 | Prompt Generator sin destinatario claro | Genera archivo `.hermes/bootstrap-prompt.hai` dentro del nuevo proyecto; apertura del CLI delegada en `Open-HermesEnterpriseProject` existente. |
| H6 | Validación regex incompleta | Regex normativa: `^[A-Za-z][A-Za-z0-9_-]{2,63}$` (inicio con letra, 3 a 64 caracteres totales). Case-sensitive preservada. |
| H7 | Reports duplican DeveloperContext | Los 6 reportes son **proyecciones** (`Get-HermesBootstrapReport`) de un único `BootstrapState` en memoria. No hay fuentes independientes. |
| H8 | Commit inicial "opcional" ambiguo | Switch `-CrearCommitInicial` explícito con default `$true`. Documentado en wizard. |
| H9 | Auditoría sin criterios medibles | Checklist binaria de 27 ítems ejecutable vía `Test-HermesBootstrapAudit`. Score < 27 → rechazo automático + rollback. |

---

## Principios rectores

1. **Single Responsibility** — cada fase = una función pública `Invoke-HermesPhaseXX`.
2. **No duplicación** — toda lógica reutilizable se importa desde módulos existentes.
3. **Desacoplamiento** — las fases se comunican por un único `BootstrapState` inmutable-factory.
4. **Observabilidad** — cada fase publica eventos al EventBus (`Bootstrap.PhaseXX.Started|Completed|Failed`).
5. **Testabilidad** — cada fase acepta `BootstrapState` y retorna `BootstrapState`; fácil de mockear.
6. **Rollback seguro** — compensator por fase, solo sobre recursos marcados con token.
7. **Backward compatibility** — router multipropósito preserva API legacy del Kernel.
8. **Minimalismo arquitectónico (REGLA 8)** — cada Sprint implementa únicamente las abstracciones estrictamente necesarias para cumplir su Definition of Done. Ningún Sprint puede introducir estructuras, modelos, configuraciones, snapshots, reportes o lógica pertenecientes a Sprints posteriores. Toda clase, función, configuración o archivo debe justificar explícitamente su existencia dentro del Sprint actual. Si un componente puede implementarse en un Sprint posterior sin afectar el Sprint actual, debe posponerse.

### Reglas del contrato de Sprint

Para garantizar minimalismo incrementable, cada Sprint tiene presupuestos de código:

| Sprint | Entregables | Presupuesto líneas |
|---|---|---|
| **Paso 1 (contratos)** | Enums + BootstrapState mínimo + ToJson/FromJson/Clone/Test + JSON config básico | **BootstrapState.ps1 ≤ 220 · bootstrap.enterprise.json ≤ 35 · Test ≤ 180** |
| Paso 2 | Wizard interactivo + suite regex | +350 líneas máx |
| Paso 3 | Phase runners (Fase03–Fase07) con snapshots mínimos | +450 líneas máx |
| Paso 4+ | Snapshots especializados, reports, rollback, audit | por fase según necesidad |

**Reglas de cumplimiento:**

- Si un archivo supera el presupuesto, el PR se rechaza.
- Ningún snapshot (`EnvironmentSnapshot`, `ProjectSnapshot`, `GitSnapshot`, `ReportPaths`, `AuditResult`, `RollbackEntry`) se introduce antes del Sprint correspondiente.
- `bootstrap.enterprise.json` contiene solo lo necesario para el Sprint actual: `meta`, `rutas`, `defaults`, `validacion.regex`. Nada más.
- `Test-BootstrapState.ps1` cubre únicamente: creación, serialización, clonación, igualdad, validaciones. Nada de tests de dominio de Sprints futuros.

---

## Arquitectura — Diagrama C4 Nivel 1 (Contexto)

```
                    ┌──────────────────────────────────┐
                    │       Usuario Hermes Enterprise  │
                    └──────────────────┬───────────────┘
                                       │ invoca
                                       ▼
                    ┌──────────────────────────────────┐
                    │  Start-HermesEnterprise.ps1      │
                    │            (Router)              │
                    └──────────────────┬───────────────┘
                                       │ -Modo Bootstrap
                                       ▼
                    ┌──────────────────────────────────┐
                    │       Bootstrap Engine v1.0      │
                    │       (orquestador Phase 0..13)  │
                    └──────────────────┬───────────────┘
                                       │
      ┌────────────────────────────────┼────────────────────────────────┐
      │                                │                                │
      ▼                                ▼                                ▼
┌─────────────────────┐   ┌─────────────────────┐   ┌─────────────────────┐
│     KERNEL          │   │     Event Bus       │   │       Logger        │
│  (no modificar)     │   │    (no modificar)   │   │   (no modificar)    │
└─────────────────────┘   └─────────────────────┘   └─────────────────────┘
      │                                │                                │
      └────────────────────────────────┼────────────────────────────────┘
                                       ▼
                    ┌──────────────────────────────────┐
                    │      Sistema externo             │
                    │  Git · Node · Python · VS Code   │
                    │  OpenRouter · GitHub             │
                    └──────────────────────────────────┘
```

---

## Arquitectura — Diagrama C4 Nivel 2 (Contenedores)

```
Bootstrap Engine v1.0
│
├─ Orchestrator.ps1                    → Invoke-HermesBootstrapOrchestrator
│
├─ BootstrapState.ps1                  → Contrato central (inmutable-factory)
├─ BootstrapConfig.ps1                 → Carga bootstrap.enterprise.json
│
├─ fases\
│  ├─ Phase00-Doctor.ps1              → Invoke-HermesDoctor
│  ├─ Phase01-GlobalConfig.ps1        → Invoke-HermesGlobalConfig
│  ├─ Phase02-Wizard.ps1              → Invoke-HermesBootstrapWizard
│  ├─ Phase03-EnvironmentManager.ps1  → New-HermesBootstrapEnvironment
│  ├─ Phase04-ProjectGenerator.ps1    → New-HermesBootstrapProject
│  ├─ Phase05-ReadmeGenerator.ps1     → New-HermesBootstrapReadme
│  ├─ Phase06-EnvGenerator.ps1        → New-HermesBootstrapEnvFile
│  ├─ Phase07-GitignoreGenerator.ps1  → New-HermesBootstrapGitignore
│  ├─ Phase08-GitManager.ps1          → Initialize-HermesBootstrapGit
│  ├─ Phase09-VSCodeOpener.ps1        → Open-HermesBootstrapVSCode
│  ├─ Phase10-PromptGenerator.ps1     → New-HermesBootstrapPrompt
│  ├─ Phase11-ReportEngine.ps1        → New-HermesBootstrapReports
│  ├─ Phase12-RollbackEngine.ps1      → Invoke-HermesBootstrapRollback
│  └─ Phase13-AuditEngine.ps1         → Test-HermesBootstrapAudit
│
└─ undo\
   └─ (función Undo-PhaseXX por cada fase)
```

### Diagrama de secuencia — Flujo principal

```
Usuario                Orchestrator      Doctor       Wizard       EnvMgr     ProjGen
   │                        │               │            │            │           │
   │─ Start -Modo Bootstrap─▶               │            │            │           │
   │                        │─Invoke────────▶            │            │           │
   │                        │       ◀──Report─────────── │            │           │
   │                        │                            │            │           │
   │                        │─Invoke────────────────────▶            │           │
   │   ◀───Wizard─────────────────────────────────         │           │           │
   │                        │                            │            │           │
   │                        │─Invoke──────────────────────────────▶  │           │
   │                        │                            │            │           │
   │                        │─Invoke────────────────────────────────────────▶ │
   │                        │                            │            │           │
   │    (si falla Fase N)   │─Rollback(N..0)───────────────────────────────▶ │
   │                        │                            │            │           │
```

---

## Contratos centrales

### BootstrapState

Única fuente de verdad. Todas las fases reciben un `BootstrapState` y retornan un `BootstrapState`. Los reportes son proyecciones, no fuentes.

```
BootstrapState
├─ Id                : [guid] CorrelationId
├─ Phase             : [enum BootstrapPhase]   Fase0 … Fase13
├─ Status            : [enum PhaseStatus]      Pending | Running | Completed | Failed | RolledBack
├─ Config            : BootstrapConfig
├─ WizardInput       : WizardInput
├─ EnvironmentResult : EnvironmentSnapshot
├─ ProjectResult     : ProjectSnapshot
├─ GitResult         : GitSnapshot
├─ ReportPaths       : ReportPaths
├─ AuditResult       : AuditResult
├─ RollbackLog       : [RollbackEntry]
├─ StartedAt         : [datetime]
└─ FinishedAt        : [datetime]
```

### BootstrapConfig

Cargado desde `configuracion/bootstrap.enterprise.json`:

```
BootstrapConfig
├─ Rutas
│  ├─ Proyectos      : "D:\\Proyectos_VSCode"
│  ├─ Environments   : "D:\\Environments"
│  └─ TempRoot       : "$env:TEMP\\hermes-bootstrap"
├─ Defaults
│  ├─ GitHubOwner    : "FREDYASARMIENTOT"
│  ├─ CrearCommitInicial : $true
│  └─ AbrirVSCode    : $true
└─ Validacion
   └─ NombreProyectoRegex : "^[A-Za-z][A-Za-z0-9_-]{2,63}$"
```

### WizardInput

```
WizardInput
├─ NombreProyecto         : [string] (regex estricta, case-sensitive)
├─ Descripcion            : [string]
├─ Objetivo               : [string]
├─ RepositorioGitHub      : [string] (ej: https://github.com/FREDYASARMIENTOT/NombreProyecto)
├─ GitHubOwner            : [string]
├─ LenguajePrincipal      : [enum] Python | DotNet | Java | Node | Go | Rust | Otro
├─ Framework              : [string]
├─ BaseDeDatos            : [string]
├─ TieneFrontEnd          : [bool]
├─ TieneBackend           : [bool]
├─ UsaDocker              : [bool]
├─ UsaTests               : [bool]
├─ UsaDocumentacionAuto   : [bool]
└─ CrearCommitInicial     : [bool]
```

### EnvironmentSnapshot

```
EnvironmentSnapshot
├─ RutaRaiz              : [string]
├─ EsNuevo               : [bool]   ← true si fue creado por esta ejecución
├─ TieneMarcadorToken    : [bool]   ← true si tiene .hermes-bootstrap-token
├─ Subcarpetas           : [string[]]  (venv, cache, downloads, logs, temp, packages, scripts, pip, python, config, requirements)
└─ Error                 : [string?]
```

### ProjectSnapshot

```
ProjectSnapshot
├─ RutaRaiz              : [string]
├─ EsNuevo               : [bool]
├─ TieneMarcadorToken    : [bool]
├─ CarpetasCreadas       : [string[]]
├─ ArchivosCreados       : [string[]]
└─ Error                 : [string?]
```

### GitSnapshot

```
GitSnapshot
├─ Inicializado          : [bool]
├─ BranchPrincipal       : [string] "main"
├─ CommitInicial         : [string?] SHA si aplica
├─ Remote                : [string?] URL del remoto
└─ Error                 : [string?]
```

### AuditResult

```
AuditResult
├─ Score                 : [int]  (0..27)
├─ Aprobado              : [bool] (true si Score == 27)
├─ Hallazgos             : [AuditFinding]
└─ RequiereRollback      : [bool]
```

### RollbackEntry

```
RollbackEntry
├─ Phase                 : [enum BootstrapPhase]
├─ Accion                : [string] (ej: "EliminarCarpeta")
├─ Ruta                  : [string]
├─ Resultado             : [enum] Success | Failed | Skipped
└─ Timestamp             : [datetime]
```

---

## Mapa de las 13 fases

| Fase | Función pública | Entrada | Salida | Abort si |
|---:|---|---|---|---|
| 00 | `Invoke-HermesDoctor` | — | `DoctorReport` | `Critical.Count > 0` |
| 01 | `Invoke-HermesGlobalConfig` | Config | Carpetas base validadas/creadas | Fallo de escritura |
| 02 | `Invoke-HermesBootstrapWizard` | Config | `WizardInput` | Usuario cancela |
| 03 | `New-HermesBootstrapEnvironment` | WizardInput | `EnvironmentSnapshot` | Fallo I/O |
| 04 | `New-HermesBootstrapProject` | WizardInput | `ProjectSnapshot` | Fallo I/O |
| 05 | `New-HermesBootstrapReadme` | WizardInput | Path README | Fallo escritura |
| 06 | `New-HermesBootstrapEnvFile` | WizardInput | Path .env | Fallo escritura |
| 07 | `New-HermesBootstrapGitignore` | WizardInput | Path .gitignore | Fallo escritura |
| 08 | `Initialize-HermesBootstrapGit` | GitSnapshot | GitSnapshot actualizado | Fallo git |
| 09 | `Open-HermesBootstrapVSCode` | ProjectSnapshot | — | (warning only) |
| 10 | `New-HermesBootstrapPrompt` | WizardInput | Path .hai | Fallo escritura |
| 11 | `New-HermesBootstrapReports` | BootstrapState | `ReportPaths` | Fallo escritura |
| 12 | `Invoke-HermesBootstrapRollback` | BootstrapState | `RollbackLog` | Siempre ejecuta |
| 13 | `Test-HermesBootstrapAudit` | BootstrapState | `AuditResult` | Score < 27 → Rollback |

Orden normativo garantizado por `Orchestrator.ps1`. Si cualquier fase falla, se dispara `RollbackEngine` en orden inverso (N..0).

---

## Mapa de archivos nuevos

```
D:\HERMES-ENTERPRISE\
├─ scripts\
│  └─ Start-HermesEnterprise.ps1           [MODIFICA] router multipropósito
│
├─ motor\
│  └─ bootstrap\
│     └─ engine\
│        ├─ BootstrapEngine.psd1            [NUEVO] módulo auto-contenido
│        ├─ BootstrapState.ps1              [NUEVO] contrato central
│        ├─ BootstrapConfig.ps1             [NUEVO] loader de configuración
│        ├─ Orchestrator.ps1                [NUEVO] orquestador
│        ├─ undo\
│        │  └─ Undo-Phases.ps1              [NUEVO] compensators
│        └─ phases\
│           ├─ Phase00-Doctor.ps1           [NUEVO]
│           ├─ Phase01-GlobalConfig.ps1     [NUEVO]
│           ├─ Phase02-Wizard.ps1           [NUEVO]
│           ├─ Phase03-EnvironmentManager.ps1  [NUEVO]
│           ├─ Phase04-ProjectGenerator.ps1 [NUEVO]
│           ├─ Phase05-ReadmeGenerator.ps1  [NUEVO]
│           ├─ Phase06-EnvGenerator.ps1     [NUEVO]
│           ├─ Phase07-GitignoreGenerator.ps1  [NUEVO]
│           ├─ Phase08-GitManager.ps1       [NUEVO]
│           ├─ Phase09-VSCodeOpener.ps1     [NUEVO]
│           ├─ Phase10-PromptGenerator.ps1  [NUEVO]
│           ├─ Phase11-ReportEngine.ps1     [NUEVO]
│           ├─ Phase12-RollbackEngine.ps1   [NUEVO]
│           └─ Phase13-AuditEngine.ps1      [NUEVO]
│
├─ configuracion\
│  └─ bootstrap.enterprise.json             [NUEVO]
│
├─ documentacion\
│  └─ bootstrap-engine\
│     ├─ BOOTSTRAP_ENGINE.md                [NUEVO] (este documento)
│     ├─ ARCHITECTURE_DIAGRAM.md            [PENDIENTE post-impl.]
│     └─ PHASES_REFERENCE.md                [PENDIENTE post-impl.]
│
└─ pruebas\
   └─ unitarias\
      ├─ Test-BootstrapState.ps1            [NUEVO]
      ├─ Test-Phase00-Doctor.ps1            [NUEVO]
      ├─ … (una prueba por fase)
      ├─ Test-BootstrapIntegration.ps1      [NUEVO]
      └─ Test-BootstrapRollback.ps1         [NUEVO]
```

---

## Reutilización de módulos existentes

Todo módulo existente **NO se toca**. Se consume vía import (`. .\ruta\...`).

| Nuevo componente | Módulo del motor que consume |
|---|---|
| Git Manager (Fase 8) | `motor/providers/GitManager.ps1` → `Initialize-HermesEnterpriseProjectRepository`, `Test-HermesEnterpriseGitRepository` |
| VS Code opener (Fase 9) | `motor/providers/VSCodeManager.ps1` → `Open-HermesEnterpriseVSCodeWorkspace`, `Test-HermesEnterpriseVSCodeWorkspace` |
| GitHub remote (Fase 2 hint) | `motor/providers/GitHubManagers.ps1` → `New-HermesEnterpriseGitHubRepository` |
| Project scaffold parcial (Fase 4) | `motor/providers/ProjectManager.ps1` → `New-HermesEnterpriseProject` |
| Logging de eventos | `motor/logging/Logger.ps1` → `Write-HermesEnterpriseLog` (solo lectura) |
| EventBus | `motor/events/EventBus.ps1` → solo `Publish-HermesEnterpriseEvent`, nunca modifica |
| ProjectWizard | `motor/wizards/ProjectWizard.ps1` → reutilizado como capa superior |
| DeveloperContextManager | `motor/context/DeveloperContextManager.ps1` → fuente de verdad para reports |

---

## Gestión de riesgos

| ID | Riesgo | Impacto | Mitigación | Responsable |
|---|---|---|---|---|
| R1 | Colisión archivo existente | Alto → rompe scripts legacy | Router con `-Modo` (H1) | Arquitectura |
| R2 | `hermes doctor` no existía como comando | Alto → no reproducible | Implementación propia (H2) | Arquitectura |
| R3 | Longitud nombre sin acotar | Medio → nombres inválidos | Regex `^[A-Za-z][A-Za-z0-9_-]{2,63}$` (H6) | Calidad |
| R4 | Rollback elimina carpetas compartidas | Crítico → pérdida de datos | Marcador `.hermes-bootstrap-token` (H4) | DevOps |
| R5 | `.hai` sin destinatario claro | Medio → prompt inútil | Archivo + delegación a `Open-HermesEnterpriseProject` (H5) | Arquitectura |
| R6 | Reports duplican DeveloperContext | Alto → desincronización | Único `BootstrapState` (H7) | Calidad |
| R7 | Commit inicial ambiguo | Bajo → UX | Switch explícito (H8) | DevOps |
| R8 | Auditoría sin criterios | Alto → subjetiva | Checklist 27 ítems (H9) | Calidad |
| R9 | Environments fuera del repo | Medio → seguridad | ACLs + config externo (H3) | DevOps |

---

## Checklist de auditoría de calidad (27 ítems)

Ejecutada por `Test-HermesBootstrapAudit`. Criterio binario por ítem. Score < 27 → rechazo automático.

| ID | Ítem | Verificación |
|---:|---|---|
| A01 | Kernel no fue modificado | diff de `motor/kernel/` contra baseline |
| A02 | EventBus no fue modificado | diff de `motor/events/` contra baseline |
| A03 | Logger no fue modificado | diff de `motor/logging/Logger.ps1` contra baseline |
| A04 | ExecutionSupervisor no fue modificado | diff de `motor/sandbox/ExecutionSupervisor.ps1` contra baseline |
| A05 | Cada fase tiene su test unitario | 13 tests de fase + 1 integración + 1 rollback presentes |
| A06 | Cada archivo nuevo tiene frontmatter YAML | Validador automático |
| A07 | Cada archivo nuevo tiene tabla de contenido | Validador automático |
| A08 | Rollback produce filesystem idéntico al pre-bootstrap | Test idempotente con hash |
| A09 | `.env` sin secretos reales (solo placeholders) | Grep automático de patrones |
| A10 | Reports sin secretos reales | Grep automático |
| A11 | Validación regex de nombre tiene ≥10 casos positivos | Test suite de regex |
| A12 | Validación regex de nombre tiene ≥15 casos negativos | Test suite de regex |
| A13 | Reports son proyecciones de `BootstrapState` único | Revisión de fuentes de datos |
| A14 | API legacy de `Start-HermesEnterprise.ps1` funciona (regresión) | Test negativo |
| A15 | `Invoke-HermesDoctor` tiene implementación propia | Verificador de símbolo |
| A16 | Marcador `.hermes-bootstrap-token` se crea y se limpia | Test dedicado |
| A17 | Switch `-CrearCommitInicial` existe y default es `$true` | Test de firma |
| A18 | Switch `-Modo` del router existe | Test de firma |
| A19 | Checklist 27 ítems ejecutable como función | Test de firma |
| A20 | Rollback ejecuta compensators en orden inverso | Test de orden |
| A21 | Event Bus recibe eventos por cada fase | Verificación por subscribe de prueba |
| A22 | Todos los paths en `BootstrapConfig` son configurables | Test config override |
| A23 | Estructura de fases es estable entre ejecuciones | Test determinismo |
| A24 | FrontEnd/Backend/Docker/Tests se materializan condicionalmente | Test cases 2^4 = 16 combinaciones |
| A25 | CHANGELOG.md fue actualizado | diff de archivo |
| A26 | ROADmap fue actualizado | diff de archivo |
| A27 | Diagrama de arquitectura del Bootstrap Engine fue generado | Archivo `.md` con diagrama C4 |

---

## Plan de implementación

Ejecución secuencial. Ningún paso arranca sin que el anterior haya superado su test unitario.

| Paso | Entregable | Criterio de éxito |
|---:|---|---|
| 1 | `configuracion/bootstrap.enterprise.json` + `BootstrapState.ps1` | Contrato compila, tiene frontmatter, test unitario de estado pasa |
| 2 | `Phase00-Doctor.ps1` + test | `Invoke-HermesDoctor` devuelve `DoctorReport`; test pasa |
| 3 | `Phase02-Wizard.ps1` + suite regex (10+15 casos) | 100% casos pasan |
| 4 | Fases 1, 3, 4, 5, 6, 7 + tests | Carpetas y archivos creados como esperado |
| 5 | Fases 8, 9 reutilizando módulos existentes | `git init`; branch `main`; VS Code abre correctamente |
| 6 | Fases 10, 11 (Prompt + Reports como proyecciones) | `.hai` generado; 6 reportes coinciden con único `BootstrapState` |
| 7 | Fase 12 RollbackEngine + tests | Rollback idempotente, filesystem limpio |
| 8 | Fase 13 AuditEngine con 27 ítems | Score = 27 en proyecto válido; score < 27 en proyecto inválido |
| 9 | Router `Start-HermesEnterprise.ps1` | API legacy intacta + `-Modo Bootstrap` funcional |
| 10 | Integración end-to-end | Ejecución completa con dummy + rollback |
| 11 | CHANGELOG.md + ROADmap | Diff registrado |
| 12 | Documentación técnica + diagrama C4 | Archivo `ARCHITECTURE_DIAGRAM.md` con diagrama ejecutable |

### Limpieza

- Todo script temporal de verificación en `C:\Users\FREDYA~1.SAR\AppData\Local\Temp\hermes-verify-*` es auto-eliminado.
- Proyecto dummy `QA_Bootstrap_Audit` se elimina al cerrar la sesión de pruebas.

---

## Referencias cruzadas

- Bootstrap legacy (nacimiento del Kernel): [BOOTSTRAP.md](../BOOTSTRAP.md)
- Contrato del Kernel: [KERNEL.md](../KERNEL.md)
- Contrato del Runtime: [RUNTIME.md](../RUNTIME.md)
- Contrato del Logger: [LOGGER.md](../LOGGER.md)
- Contrato del EventBus: [EVENT_BUS.md](../EVENT_BUS.md)
- SRS del sistema: [SRS_HERMES_ENTERPRISE.md](../SRS_HERMES_ENTERPRISE.md)
- ProjectWizard: [motor/wizards/ProjectWizard.ps1](../../motor/wizards/ProjectWizard.ps1)
- WorkspaceProvider: [motor/providers/WorkspaceProvider.ps1](../../motor/providers/WorkspaceProvider.ps1)
- GitManager: [motor/providers/GitManager.ps1](../../motor/providers/GitManager.ps1)
- VSCodeManager: [motor/providers/VSCodeManager.ps1](../../motor/providers/VSCodeManager.ps1)
- GitHubManagers: [motor/providers/GitHubManagers.ps1](../../motor/providers/GitHubManagers.ps1)
- ROADMAP: [roadmap/01_MASTER_ROADMAP.md](../roadmap/01_MASTER_ROADMAP.md)
- CHANGELOG: [../../CHANGELOG.md](../../CHANGELOG.md)

---

> Documento generado como entrega oficial del diseño del Bootstrap Engine v1.0.
> Aprobado por las cuatro agencias: Enterprise, DevOps, Calidad, Revisor Adversarial.
> Pendiente de implementación. Ningún archivo de código ha sido escrito hasta la aprobación explícita del Paso 1.
