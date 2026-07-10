# Builder Contract - Fase 3.5C

## 1. Reglas del Contrato

### 1.1 Firmas Inmutables
Todos los builders deben mantener sus firmas públicas **congeladas**. No se pueden:
- Agregar/eliminar parámetros obligatorios
- Cambiar nombres de parámetros
- Modificar tipos esperados

### 1.2 Parámetros Comunes

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `OutputPath` | `[string]` | Ruta donde se genera el artefacto |
| `ProjectPath` | `[string]` | Ruta del proyecto (para Builders que requieren Git) |
| `BootstrapState` | `[PSCustomObject]` | Estado actual del proyecto (para Builders que lo consumen) |
| `ExecutionData` | `[PSCustomObject]` | Datos de ejecución del Worker (SummaryBuilder) |

### 1.3 Dependencias de Helpers

**NINGÚN builder debe redefinir funciones auxiliares**:
- ❌ No `function Estimate-Tokens` en builders
- ❌ No `function Get-GitCommitHash` en builders
- ❌ No `function Calculate-Duration` en builders
- ✅ Usar helpers centralizados en `motor/context/helpers/`

### 1.4 Formato del Artefacto Generado

| Artefacto | Tipo | Encabezado |
|-----------|------|-----------|
| `CURRENT_STATE.md` | Markdown | YAML con `contextVersion: 1` |
| `NEXT_TASK.md` | Markdown | YAML con `contextVersion: 1` |
| `PROJECT_INDEX.json` | JSON | Sin comentarios, válido |
| `WORKER_CONTEXT.json` | JSON | Sin comentarios, válido |
| `CONTEXT_MANIFEST.json` | JSON | Sin comentarios, válido |
| `SUMMARY.md` | Markdown | YAML con `contextVersion: 1` |
| `PROJECT_MEMORY.md` | Markdown | Sin encabezado |

### 1.5 Tokens por Artefacto

| Artefacto | Budget Máximo |
|-----------|---------------|
| `CURRENT_STATE.md` | 500 tokens |
| `NEXT_TASK.md` | 500 tokens |
| `PROJECT_INDEX.json` | 500 tokens |
| `WORKER_CONTEXT.json` | 500 tokens |
| `CONTEXT_MANIFEST.json` | 300 tokens |
| `SUMMARY.md` | 500 tokens |

## 2. Estructura de BootstrapState

```powershell
@{
    ProjectName           = [string]          # Requerido
    BootstrapVersion      = [string]          # Requerido
    CurrentPhase          = [int]             # Opcional
    CurrentStep           = [string]          # Opcional
    StepStatus            = [string]          # Opcional
    ProximoObjetivo       = [string]          # Requerido para NextTaskBuilder
    ComponentesCompletados = [string[]]       # Opcional
    ComponentesPendientes  = [string[]]       # Opcional
}
```

## 3. Estructura de ExecutionData

```powershell
@{
    WorkerName      = [string]     # Requerido
    StartTime       = [datetime]   # Requerido
    EndTime         = [datetime]   # Requerido
    FilesCreated    = [string[]]   # Opcional
    FilesModified   = [string[]]   # Opcional
    FilesDeleted    = [string[]]   # Opcional
    TestsPassed     = [int]        # Opcional
    TestsFailed     = [int]        # Opcional
    TestCoverage    = [int]        # Opcional (0-100)
    ExitCode        = [int]        # Opcional
    CommitHash      = [string]     # Opcional
    CommitMessage   = [string]     # Opcional
    IssuesFound     = [string[]]   # Opcional
    NextStep        = [string]     # Opcional
}
```

## 4. Validaciones Requeridas

### 4.1 Pre-Generación
- Verificar que helpers están cargados
- Validar parámetros obligatorios
- Validar tipos de parámetros

### 4.2 Post-Generación
- Verificar que archivo fue creado
- Validar formato (JSON válido o YAML presente)
- Validar que no hay contenido vacío
- Validar que tokens están dentro del budget

### 4.3 Coherencia
- Hash de commit debe ser igual en todos los artefactos del mismo ciclo
- Nombre del proyecto debe ser consistente
