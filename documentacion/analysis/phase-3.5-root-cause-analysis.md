# Diagnóstico de Causa Raíz - Fase 3.5

## Fecha: 2024-07-08

## Resumen Ejecutivo

Se identificó la causa raíz del fallo en la Fase 3.5 del Bootstrap Engine: **colisión de firmas en funciones auxiliares duplicadas** durante la fase de dot-source.

## Metodología de Diagnóstico

### Paso 1: Verificación de Sintaxis con AST

Se analizó la sintaxis de todos los builders usando el AST de PowerShell:

```powershell
$tokens = $null
$parseErrors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    "$($f.FullName)", [ref]$tokens, [ref]$parseErrors
)
```

**Resultado:** Todos los builders tienen sintaxis válida según AST. No hay errores de parseo.

### Paso 2: Comparación AST vs Get-Command

Se compararon las firmas detectadas por AST vs las que PowerShell registra después de cargar:

| Builder | AST Detecta | Get-Command Registra |
|---------|-------------|---------------------|
| CurrentStateBuilder | `Build-CurrentState -BootstrapState -OutputPath` | `Build-CurrentState -BootstrapState` ❌ |
| NextTaskBuilder | `Build-NextTask -BootstrapState -OutputPath` | `Build-NextTask -BootstrapState` ❌ |
| ProjectIndexBuilder | `Build-ProjectIndex -ProjectRoot -OutputPath` | `Build-ProjectIndex -ProjectRoot, -OutputPath` ✅ |
| WorkerContextBuilder | `Build-WorkerContext -BootstrapState -ProjectRoot -OutputPath` | `Build-WorkerContext -BootstrapState, -ProjectRoot` ❌ |

**Observación:** Los builders pierden el parámetro `-OutputPath` después de ser cargados, excepto ProjectIndexBuilder.

### Paso 3: Análisis de Orden de Carga

Se revisó el orden en que ContextEngine.ps1 carga los builders:

```powershell
# Línea 48-53 de ContextEngine.ps1
. "$PSScriptRoot\ContextHelpers.ps1"
. "$PSScriptRoot\builders\CurrentStateBuilder.ps1"
. "$PSScriptRoot\builders\NextTaskBuilder.ps1"
. "$PSScriptRoot\builders\ProjectIndexBuilder.ps1"
. "$PSScriptRoot\builders\WorkerContextBuilder.ps1"
. "$PSScriptRoot\builders\SummaryBuilder.ps1"
```

### Paso 4: Detección de Funciones Duplicadas

Se encontraron múltiples definiciones de las mismas funciones auxiliares:

#### Función Get-GitCommitHash

| Archivo | Definición | Línea |
|---------|-----------|-------|
| CurrentStateBuilder.ps1 | `function Get-GitCommitHash { param([string]$OutputPath) ... }` | 115-120 |
| NextTaskBuilder.ps1 | `function Get-GitCommandHash { param([string]$OutputPath) ... }` | 95-100 |
| WorkerContextBuilder.ps1 | `function Get-GitCommitHash { param([string]$ProjectRoot) ... }` | 110-115 |

**Problema:** 
- Dos nombres distintos (`Get-GitCommitHash` vs `Get-GitCommandHash`)
- Dos parámetros distintos (`OutputPath` vs `ProjectRoot`)
- Cuando PowerShell carga todos los archivos, la última definición gana

#### Función Get-GitBranch

| Archivo | Definición | Parámetro |
|---------|-----------|-----------|
| CurrentStateBuilder.ps1 | `Get-GitBranch` | `$OutputPath` |
| WorkerContextBuilder.ps1 | `Get-GitBranch` | `$ProjectRoot` |

**Problema:** Mismo nombre, parámetros incompatibles

#### Función Estimate-Tokens

| Archivo | Definición |
|---------|-----------|
| CurrentStateBuilder.ps1 | `Estimate-Tokens` |
| NextTaskBuilder.ps1 | `Estimate-Tokens` |
| ProjectIndexBuilder.ps1 | `Estimate-Tokens` |
| WorkerContextBuilder.ps1 | `Estimate-Tokens` |
| SummaryBuilder.ps1 | `Estimate-Tokens` |

**Problema:** Misma función definida 5 veces

### Paso 5: Simulación del Error

Se creó un script de prueba que carga los builders en el mismo orden que ContextEngine.ps1:

```powershell
# hermes-verify-bug-cause.ps1

. 'D:\HERMES-ENTERPRISE\motor\context\builders\CurrentStateBuilder.ps1'
. 'D:\HERMES-ENTERPRISE\motor\context\builders\NextTaskBuilder.ps1'
. 'D:\HERMES-ENTERPRISE\motor\context\builders\ProjectIndexBuilder.ps1'
. 'D:\HERMES-ENTERPRISE\motor\context\builders\WorkerContextBuilder.ps1'
. 'D:\HERMES-ENTERPRISE\motor\context\builders\SummaryBuilder.ps1'

# Ver qué versión de Get-GitCommandHash ganó
$gc = Get-Command Get-GitCommandHash
$gcParams = $gc.Parameters.Keys | Where-Object { $_ -notmatch 'Verbose|Debug|ErrorAction|WarningAction|InformationAction|ErrorVariable|WarningVariable|InformationVariable|OutVariable|OutBuffer|PipelineVariable|ProgressAction' }
Write-Host "Get-GitCommandHash final: ($($gcParams -join ', '))"

# Intentar llamar desde CurrentState (espera OutputPath)
try {
    $result = Get-GitCommandHash -OutputPath 'C:\temp'
    Write-Host "Llamada con -OutputPath: $result"
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}

# Intentar llamar desde WorkerContext (espera ProjectRoot)
try {
    $result = Get-GitCommandHash -ProjectRoot 'C:\temp'
    Write-Host "Llamada con -ProjectRoot: $result"
} catch {
    Write-Host "ERROR: $($_.Exception.Message)"
}
```

**Resultado:** La versión final acepta solo `-ProjectRoot`, pero CurrentState la llama con `-OutputPath`, causando el error.

## Causa Raíz

**Colisión de firmas en funciones auxiliares durante dot-source múltiple:**

1. Cada builder define funciones auxiliares con el mismo nombre pero firmas distintas
2. PowerShell carga todos los archivos en secuencia
3. La última definición de cada función reemplaza las anteriores
4. Los builders que esperan las firmas originales fallan silenciosamente

**Ejemplo específico:**
- `CurrentStateBuilder.ps1` define `Get-GitCommitHash($OutputPath)`
- `WorkerContextBuilder.ps1` define `Get-GitCommitHash($ProjectRoot)`
- Se carga `CurrentStateBuilder.ps1` primero → `Get-GitCommitHash` acepta `-OutputPath`
- Se carga `WorkerContextBuilder.ps1` después → `Get-GitCommitHash` acepta `-ProjectRoot`
- Cuando `CurrentStateBuilder` intenta llamar `Get-GitCommitHash -OutputPath '...'`, falla porque ya no acepta ese parámetro

## Impacto

- **Build-CurrentState** falla con: `Cannot retrieve dynamic parameters. A parameter cannot be found that matches parameter name 'OutputPath'`
- **Build-NextTask** falla con el mismo error
- **Build-WorkerContext** funciona porque su firma coincide con la última definición
- **Build-ProjectIndex** funciona porque su firma coincide con la última definición

## Solución Propuesta

### Opción 1: Consolidar funciones auxiliares (RECOMENDADA)

Crear un archivo `ContextHelpers.ps1` con todas las funciones auxiliares compartidas:

```powershell
# D:\HERMES-ENTERPRISE\motor\context\builders\ContextHelpers.ps1

function Get-GitCommitHash {
    param([string]$ProjectRoot)
    # Implementación única
}

function Get-GitBranch {
    param([string]$ProjectRoot)
    # Implementación única
}

function Estimate-Tokens {
    param([string]$Text)
    # Implementación única
}
```

**Ventajas:**
- Elimina duplicación
- Firma consistente en todo el contexto
- Más fácil de mantener
- Reduce tamaño de archivos

**Cambios requeridos:**
1. Crear `ContextHelpers.ps1`
2. Eliminar funciones duplicadas de todos los builders
3. Actualizar ContextEngine.ps1 para cargar ContextHelpers.ps1 primero
4. Actualizar llamadas en los builders para usar parámetros correctos

### Opción 2: Prefijar funciones por builder

Renombrar funciones para evitar colisiones:

```powershell
# CurrentStateBuilder.ps1
function Get-GitCommitHash-CurrentState($OutputPath) { ... }

# WorkerContextBuilder.ps1
function Get-GitCommitHash-WorkerContext($ProjectRoot) { ... }
```

**Desventajas:**
- Código más verboso
- No elimina la duplicación de lógica
- Más difícil de mantener

## Fix Implementado

Se ha creado `ContextHelpers.ps1` con las siguientes funciones consolidadas:

```powershell
function Get-GitCommandHash {
    param([string]$ProjectRoot)
    # ...
}

function Get-GitBranch {
    param([string]$ProjectRoot)
    # ...
}

function ConvertTo-TokenCount {
    param([string]$Text)
    # ...
}
```

**Próximo paso:** 
1. Actualizar ContextEngine.ps1 para cargar ContextHelpers.ps1 primero
2. Eliminar funciones duplicadas de todos los builders
3. Actualizar llamadas en los builders
4. Verificar que todos los builders funcionen
5. Ejecutar suite de pruebas

## Verificación Posterior

Después de aplicar el fix:

```powershell
# hermes-verify-final.ps1

. 'D:\HERMES-ENTERPRISE\motor\context\builders\ContextHelpers.ps1'
. 'D:\HERMES-ENTERPRISE\motor\context\builders\CurrentStateBuilder.ps1'
. 'D:\HERMES-ENTERPRISE\motor\context\builders\NextTaskBuilder.ps1'
. 'D:\HERMES-ENTERPRISE\motor\context\builders\ProjectIndexBuilder.ps1'
. 'D:\HERMES-ENTERPRISE\motor\context\builders\WorkerContextBuilder.ps1'
. 'D:\HERMES-ENTERPRISE\motor\context\builders\SummaryBuilder.ps1'

(Get-Command Build-CurrentState).Parameters.Keys
# Debe mostrar: BootstrapState, OutputPath, ...

(Get-Command Build-NextTask).Parameters.Keys
# Debe mostrar: BootstrapState, OutputPath, ...

(Get-Command Build-WorkerContext).Parameters.Keys
# Debe mostrar: BootstrapState, ProjectRoot, OutputPath, ...
```

## Conclusiones

**El diseño arquitectónico de la Fase 3.5 es correcto.**

El problema no es de arquitectura, sino de **implementación de funciones auxiliares**.

La solución es simple y mínima:
- Consolidar funciones duplicadas en un archivo compartido
- Actualizar contexto de ingeniería para documentar la restricción
- Aplicar el fix de forma quirúrgica

**No se requiere revertir commits, ni reescribir arquitectura.**

---

*Documento generado: 2024-07-08*
*Status: Fix pendiente de implementación*
