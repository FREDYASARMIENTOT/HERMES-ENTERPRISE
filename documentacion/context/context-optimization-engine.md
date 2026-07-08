---
title: "Context Optimization Engine - Diseño Técnico"
project: "HERMES Enterprise"
component: "Context Subsystem"
phase: "3.5"
status: "Implementado"
version: "1.0.0"
created: "2026-07-08"
author: "Hermes Architect"
tags:
  - context
  - optimization
  - workers
  - tokens
---

# Context Optimization Engine - Fase 3.5

## Índice

1. [Objetivo](#objetivo)
2. [Arquitectura](#arquitectura)
3. [Módulos](#módulos)
4. [Formato de Archivos Generados](#formato-de-archivos-generados)
5. [Flujo de Ejecución](#flujo-de-ejecución)
6. [Integración](#integración)
7. [Casos de Uso](#casos-de-uso)
8. [Buenas Prácticas](#buenas-prácticas)

---

## Objetivo

Eliminar la dependencia del historial conversacional largo. Permitir que cualquier Worker de Hermes CLI inicie una nueva conversación utilizando únicamente archivos de contexto mínimo (200–500 tokens efectivos por archivo), manteniendo la misma calidad arquitectónica.

Este motor es la base para:

- Workers especializados
- Desarrollo distribuido
- Reanudación de proyectos
- Cambio de máquina/sesión
- Ejecución paralela
- Optimización de costos y tokens

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                   ContextOptimizationEngine                   │
│                    (Orquestador Principal)                    │
└──────────────────────────┬──────────────────────────────────┘
                           │
        ┌──────────────────┼───────────────────┐
        │                  │                   │
        ▼                  ▼                   ▼
┌─────────────┐  ┌──────────────┐  ┌────────────────┐
│CurrentState  │  │ NextTask     │  │ WorkerContext  │
│Builder       │  │ Builder      │  │ Builder        │
└──────┬───────┘  └──────┬───────┘  └──────┬─────────┘
       │                 │                  │
       ▼                 ▼                  ▼
┌─────────────┐  ┌──────────────┐  ┌────────────────┐
│CURRENT_STATE│  │ NEXT_TASK.md │  │WORKER_CONTEXT  │
│    .md      │  │              │  │    .json       │
└─────────────┘  └──────────────┘  └────────────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │ContextValidator  │
                  └────────┬─────────┘
                           │
                           ▼
                  ┌──────────────────┐
                  │  SUMMARY.md      │
                  │  (post-ejecución)│
                  └──────────────────┘
```

---

## Módulos

### ContextOptimizationEngine.ps1 (Orquestador)

**Responsabilidad:** Coordina la generación de todos los artefactos de contexto.

**API:**
```powershell
Build-OptimizedContext -BootstrapState $state -OutputPath $path [-ExecutionData $data]
```

**Principios:**
- Atomicidad: todo-o-nada
- Rollback automático en caso de fallo
- Validación post-generación
- Eventos al EventBus (iniciado/completado/fallido)

### CurrentStateBuilder.ps1

**Responsabilidad:** Genera CURRENT_STATE.md con snapshot del estado actual del proyecto.

**API:**
```powershell
Build-CurrentState -BootstrapState $state -OutputPath $path
```

**Contenido generado:**
- Frontmatter YAML con metadata
- Información de proyecto, fase y paso
- Environment (Python, venv)
- Componentes implementados y pendientes
- Restricciones
- Last Commit y Verification

### NextTaskBuilder.ps1

**Responsabilidad:** Genera NEXT_TASK.md con la siguiente tarea a ejecutar.

**API:**
```powershell
Build-NextTask -ContextState $ctxState -OutputPath $path
```

**Contenido generado:**
- Objetivo inmediato
- Entradas y salidas esperadas
- Archivos permitidos/prohibidos
- Pruebas requeridas
- Condiciones de aceptación
- Plan de rollback

### WorkerContextBuilder.ps1

**Responsabilidad:** Genera WORKER_CONTEXT.json como contrato estructurado para workers.

**API:**
```powershell
Build-WorkerContext -ContextState $ctxState -OutputPath $path
```

**Schema del JSON:**
```json
{
  "project": "string",
  "version": "string",
  "branch": "string",
  "commit": "string",
  "phase": number,
  "step": number,
  "completed_modules": ["string"],
  "pending_modules": ["string"],
  "environment": {},
  "working_directory": "string",
  "generated_at": "ISO-8601"
}
```

### SummaryBuilder.ps1

**Responsabilidad:** Genera SUMMARY.md post-ejecución de un worker.

**API:**
```powershell
Build-WorkerSummary -ExecutionData $data -OutputPath $path
```

**Contenido generado:**
- Tipo de worker, inicio y duración
- Archivos modificados
- Pruebas ejecutadas
- Resultado y commit
- Problemas encontrados
- Próximo paso recomendado

### ContextValidator.ps1

**Responsabilidad:** Valida integridad y coherencia de archivos generados.

**API:**
```powershell
Invoke-ContextValidation -OutputPath $path
```

**Validaciones:**
- Archivos existen y tienen contenido
- JSON es parseable
- Secciones requeridas presentes
- Coherencia entre archivos (mismo commit, rama)
- Schema esperado cumplido

---

## Formato de Archivos Generados

### CURRENT_STATE.md

```markdown
---
project: HERMES-ENTERPRISE
version: 1.0.0
phase: 3.5
step: 3.5
git_branch: main
git_commit: abc123
generated_at: 2026-07-08T12:00:00Z
---

# Current State

## Project
[Información del proyecto]

## Current Step
[Fase y paso actual]

## Environment
[Python, venv, paths]

## Components Implemented
[Tabla de módulos completados]

## Components Pending
[Tabla de módulos pendientes]

## Restrictions
[Qué no modificar]

## Last Verification
[Fecha, script, resultado]

## Last Commit
[Hash, rama, fecha]

## Next Objective
[Siguiente paso]
```

### NEXT_TASK.md

```markdown
---
project: HERMES-ENTERPRISE
version: 1.0.0
phase: 4
step: 4
git_branch: main
git_commit: abc123
---

# Next Task

## Objective
[Descripción de la tarea]

## Inputs
[Qué necesita]

## Expected Outputs
[Qué debe producir]

## Allowed Files / Forbidden Files
[Paths]

## Required Tests
[Lista de pruebas]

## Acceptance Criteria
[Checklist]

## Rollback Plan
[Qué hacer si falla]
```

### WORKER_CONTEXT.json

```json
{
  "project": "HERMES-ENTERPRISE",
  "version": "1.0.0",
  "branch": "main",
  "commit": "abc123def456",
  "phase": 3.5,
  "step": 3.5,
  "completed_modules": [
    "BootstrapState",
    "BootstrapWizard",
    "EnvironmentManager",
    "ContextOptimizationEngine"
  ],
  "pending_modules": [
    "BootstrapOrchestrator",
    "StartHermesProject"
  ],
  "environment": {
    "python_path": "C:\\Python311\\python.exe",
    "venv_path": "D:\\Environments\\TestProject",
    "python_version": "3.11.0"
  },
  "working_directory": "D:\\HERMES-ENTERPRISE",
  "generated_at": "2026-07-08T12:00:00Z"
}
```

### SUMMARY.md

```markdown
# Worker Execution Summary

## Execution
**Worker Type:** IntegrationWorker
**Start Time:** 2026-07-08T12:00:00Z
**Duration:** 00:15:30

## Files Modified
- motor/bootstrap/Orchestrator.ps1

## Tests
**Tests Executed:** 12
**Tests Passed:** 12

## Result
**Status:** SUCCESS
**Commit:** abc123

## Next Step
Implementar Paso 4.1
```

---

## Flujo de Ejecución

### Flujo Principal: Build-OptimizedContext

```
BootstrapState (entrada)
      │
      ▼
ContextOptimizationEngine
      │
      ├──► CurrentStateBuilder ──► CURRENT_STATE.md
      │
      ├──► NextTaskBuilder ──► NEXT_TASK.md
      │
      ├──► WorkerContextBuilder ──► WORKER_CONTEXT.json
      │
      ├──► ContextValidator ──► Validación
      │
      └──► [Si todo OK] Retornar resultados
           [Si falla] Rollback + excepcion
```

### Flujo Secundario: Build-WorkerSummary

```
WorkerResult (entrada)
      │
      ▼
SummaryBuilder
      │
      └──► SUMMARY.md
```

---

## Integración

### Dependencias de entrada

| Módulo | Uso |
|--------|-----|
| BootstrapState (Fase 1) | Estado del proyecto |
| BootstrapWizard (Fase 2) | Metadata de wizard |
| EnvironmentManager (Fase 3) | Estado del environment |
| Git | Commit, rama, status |

### Dependencias de salida

| Componente | Uso |
|------------|-----|
| EventBus | Eventos Started/Completed/Failed |
| Logger | Registro de operaciones |

### Integración futura

BootstrapOrchestrator (Paso 4+) consumirá este motor para:
- Generar contexto antes de delegar tareas
- Validar estado entre fases
- Coordinar workers paralelos

---

## Casos de Uso

### Caso 1: Inicio de Worker nuevo

```powershell
# Worker recibe archivos de contexto
$context = Build-OptimizedContext -BootstrapState $state -OutputPath "./context"

# Worker lee solo lo necesario
$currentState = Get-Content "./context/CURRENT_STATE.md" -Raw
$nextTask = Get-Content "./context/NEXT_TASK.md" -Raw
$workerCtx = Get-Content "./context/WORKER_CONTEXT.json" -Raw | ConvertFrom-Json
```

### Caso 2: Resumen post-ejecución

```powershell
$executionData = [PSCustomObject]@{
    WorkerType = 'BootstrapOrchestrator'
    StartTime = '2026-07-08T10:00:00Z'
    Duration = '00:15:00'
    FilesModified = @('motor/bootstrap/Orchestrator.ps1')
    TestsExecuted = 14
    TestsPassed = 14
    Status = 'SUCCESS'
    CommitHash = 'abc123'
    NextStep = 'Implementar Paso 4.1'
}

Build-WorkerSummary -ExecutionData $executionData -OutputPath "./context"
```

### Caso 3: Validación de integridad

```powershell
$validation = Invoke-ContextValidation -OutputPath "./context"
if (-not $validation.IsAllValid) {
    Write-Error "Contexto inválido"
}
```

---

## Buenas Prácticas

### Generación de contexto

1. **Siempre validar BootstrapState antes** de generar contexto
2. **Usar rutas absolutas** para evitar ambigüedades
3. **Limpiar recursos temporales** después de cada ejecución
4. **Verificar coherencia** entre archivos generados
5. **Mantener budget de tokens** - no exceder 500 por archivo

### Consumo de contexto

1. **Leer solo los archivos necesarios** - no cargar todos si no se necesitan
2. **Validar JSON antes de procesar** - WORKER_CONTEXT.json puede estar corrupto
3. **No modificar archivos generados** - regenerar si se necesita cambio
4. **Verificar timestamps** - asegurar contexto fresco
5. **No incluir en conversaciones** - referenciar, no copiar

### Archivos prohibidos en contexto

- ❌ Historial de conversaciones
- ❌ Reasoning intermedio
- ❌ Logs de debug
- ❌ Información sensible (secrets, tokens)
- ❌ Datos de versiones anteriores

---

## Navegación Cruzada

- [← Environment Manager (Fase 3)](../bootstrap/environment-design.md)
- [← Bootstrap Engine (general)](../bootstrap-engine/bootstrap-engine-design.md)
- [→ Bootstrap Orchestrator (Fase 4)]() *(pendiente)*
