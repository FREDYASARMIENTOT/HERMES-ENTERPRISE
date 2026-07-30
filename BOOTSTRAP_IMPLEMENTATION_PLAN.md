# BOOTSTRAP IMPLEMENTATION PLAN

> **Documento Técnico — Arquitectura del Bootstrap Definitivo**
>
> Proyecto: Hermes Enterprise
> Versión: 1.0.0
> Estado: Borrador para aprobación
> Fecha: 2026-07-29

---

## Tabla de Contenidos

1. [Resumen Ejecutivo](#1-resumen-ejecutivo)
2. [Filosofía Arquitectónica](#2-filosofía-arquitectónica)
3. [Mapa de Motores (7 Motores)](#3-mapa-de-motores)
4. [Motor 1: Workspace Engine](#4-motor-1-workspace-engine)
5. [Motor 2: Environment Engine](#5-motor-2-environment-engine)
6. [Motor 3: Project Generator](#6-motor-3-project-generator)
7. [Motor 4: Git Engine](#7-motor-4-git-engine)
8. [Motor 5: GitHub Engine](#8-motor-5-github-engine)
9. [Motor 6: Validation Engine](#9-motor-6-validation-engine)
10. [Motor 7: Recovery Engine](#10-motor-7-recovery-engine)
11. [Pipeline de Orquestación (BootstrapPipeline)](#11-pipeline-de-orquestación)
12. [Contratos y Estados](#12-contratos-y-estados)
13. [Archivos Implicados (Resumen)](#13-archivos-implicados)
14. [Estrategia de Pruebas](#14-estrategia-de-pruebas)
15. [Riesgos y Mitigaciones](#15-riesgos-y-mitigaciones)
16. [Criterios de Aceptación Globales](#16-criterios-de-aceptación-globales)
17. [Hoja de Ruta de Implementación](#17-hoja-de-ruta-de-implementación)

---

## 1. Resumen Ejecutivo

### Problema

Hermes Enterprise actualmente **no puede generar proyectos completos desde cero**. El BootstrapOrchestrator es un stub de 9 líneas, el Kernel referencia 18 funciones que no existen, y la configuración (`bootstrap.enterprise.json`) no es consumida por ningún script.

### Solución

Construir 7 motores independientes, cada uno con responsabilidad única, orquestados por un pipeline central (`Invoke-HermesBootstrapPipeline`). Cada motor:

- Puede ejecutarse de forma autónoma (útil para depuración)
- Puede ser invocado secuencialmente por el pipeline
- Publica su estado en `BootstrapState`
- Soporta rollback en caso de fallo
- Tiene pruebas unitarias y de integración independientes

### Inventario de Activos Existentes

| Activo | Estado | Ubicación |
|--------|--------|-----------|
| `BootstrapRequest` DTO | **Completo** (282 líneas) | `motor/bootstrap/request/BootstrapRequest.ps1` |
| `BootstrapState` contrato | **Completo** (170 líneas) | `motor/bootstrap/engine/BootstrapState.ps1` |
| `BootstrapWizard` | **Funcional** (recolecta nombre) | `motor/bootstrap/engine/BootstrapWizard.ps1` |
| `EnvironmentManager` | **Completo** (680 líneas) | `motor/bootstrap/engine/environment/EnvironmentManager.ps1` |
| `GitHub.ps1` | **Funcional** (31 líneas) | `motor/bootstrap/functions/GitHub.ps1` |
| `Python.ps1` | **Mínimo** (8 líneas) | `motor/bootstrap/functions/Python.ps1` |
| `Start-HermesProject.ps1` | **Funcional** (entrypoint) | `motor/bootstrap/Start-HermesProject.ps1` |
| `BootstrapOrchestrator.ps1` (kernel) | **Stub** | `motor/kernel/Core/components/BootstrapOrchestrator.ps1` |
| `BootstrapOrchestrator.ps1` (engine) | **Stub** (9 líneas) | `motor/bootstrap/engine/BootstrapOrchestrator.ps1` |
| `bootstrap.enterprise.json` | **No consumido** | `configuracion/bootstrap.enterprise.json` |
| `proveedores/` directorio | Vacío | `proveedores/` |

### Principio Rector

> **No reescribir. Conectar.**
>
> El código existente (EnvironmentManager, BootstrapRequest, BootstrapState, GitHub.ps1) es funcional.
> La prioridad es construir el **orquestador** que los conecte, no reescribir los módulos existentes.

---

## 2. Filosofía Arquitectónica

### Principios

1. **Responsabilidad Única**: Cada motor hace exactamente una cosa y la hace bien.
2. **Independencia**: Cada motor puede ejecutarse y probarse de forma aislada.
3. **Composición**: El pipeline orquesta motores secuencialmente, no los modifica.
4. **Estado Inmutable**: `BootstrapState` es un DTO inmutable — cada motor recibe una copia y retorna una nueva.
5. **Rollback por Defecto**: Si un motor falla, se ejecuta su rollback automáticamente.
6. **Resiliencia**: El pipeline puede reanudarse desde el punto de fallo.
7. **No Toquear lo que Funciona**: EnvironmentManager (680 líneas) y BootstrapRequest (282 líneas) no se modifican.
8. **Consumir Configuración**: `bootstrap.enterprise.json` debe ser la fuente de verdad para rutas, templates y defaults.

### Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Invoke-HermesBootstrapPipeline               │
│  (Orquestador central — motor/bootstrap/engine/)                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ FASE 1   │→│ FASE 2   │→│ FASE 3   │→│ FASE 4   │           │
│  │ Workspace│  │Environment│  │ Project  │  │ Git      │           │
│  │ Engine   │  │ Engine   │  │ Generator│  │ Engine   │           │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘           │
│       │              │              │              │               │
│       ↓              ↓              ↓              ↓               │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐           │
│  │ FASE 5   │→│ FASE 6   │→│ FASE 7   │    (Recovery)           │
│  │ GitHub   │  │Validation│  │ Recovery │    ┌─────────────┐      │
│  │ Engine   │  │ Engine   │  │ Engine   │    │ (transversal)│      │
│  └──────────┘  └──────────┘  └──────────┘    └─────────────┘      │
│       │              │              │                              │
│       ↓              ↓              ↓                              │
│  ┌──────────────────────────────────────────────────────────┐      │
│  │                    BootstrapReport                        │      │
│  │  (Resultado final con estado de cada fase)                │      │
│  └──────────────────────────────────────────────────────────┘      │
└─────────────────────────────────────────────────────────────────────┘
         │                      │                        │
         ↓                      ↓                        ↓
  ┌─────────────┐    ┌──────────────────┐    ┌──────────────────┐
  │ File System │    │ Python / pip     │    │ Git / gh CLI     │
  │ (IO real)   │    │ (proceso externo)│    │ (proceso externo)│
  └─────────────┘    └──────────────────┘    └──────────────────┘
```

---

## 3. Mapa de Motores

| # | Motor | Responsabilidad | Dependencias | Archivo Propuesto |
|---|-------|----------------|--------------|-------------------|
| 1 | **Workspace Engine** | Validar ruta, detectar colisiones, crear árbol de carpetas | `BootstrapState`, sistema de archivos | `motor/bootstrap/engine/WorkspaceEngine.ps1` |
| 2 | **Environment Engine** | Detectar Python, crear .venv, instalar dependencias | `BootstrapState`, `EnvironmentManager` existente, Python | `motor/bootstrap/engine/EnvironmentEngine.ps1` (wrapper de EnvironmentManager) |
| 3 | **Project Generator** | Crear README, LICENSE, CHANGELOG, .gitignore, src/ | `BootstrapState`, templates | `motor/bootstrap/engine/ProjectGenerator.ps1` |
| 4 | **Git Engine** | git init, commit inicial, configurar usuario | `BootstrapState`, Git CLI | `motor/bootstrap/engine/GitEngine.ps1` |
| 5 | **GitHub Engine** | gh auth, repo create, push | `BootstrapState`, `GitHub.ps1` existente, gh CLI | `motor/bootstrap/engine/GitHubEngine.ps1` |
| 6 | **Validation Engine** | Verificar proyecto, entorno, git, dependencias | Todos los motores anteriores | `motor/bootstrap/engine/ValidationEngine.ps1` |
| 7 | **Recovery Engine** | Reanudar, rollback, registro forense | `BootstrapState`, logs, sistema de archivos | `motor/bootstrap/engine/RecoveryEngine.ps1` |

---

## 4. Motor 1: Workspace Engine

### Responsabilidad Única

Validar la ruta destino y crear la estructura de directorios del proyecto.

### Entradas

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `BootstrapRequest` | PSCustomObject | Contiene `NombreProyecto`, `RutaProyecto`, `CrearFrontend`, `CrearBackend` |
| `BootstrapState` | PSCustomObject | Estado actual (Fase00 → Fase01) |

### Salidas

| Salida | Tipo | Descripción |
|--------|------|-------------|
| `BootstrapState` actualizado | PSCustomObject | Phase = Fase01, Status = Completed/Failed, Workspace con metadata |
| `BootstrapReport` parcial | Hashtable | Detalle de carpetas creadas, permisos, colisiones |

### Dependencias

- `BootstrapState.ps1` — contrato de estado
- Sistema de archivos (`Test-Path`, `New-Item`)
- `bootstrap.enterprise.json` — rutas base
- Módulo `Observabilidad.ps1` — logging

### Interfaces Públicas

```powershell
function Initialize-WorkspaceEngine {
    param(
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapRequest,
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapState
    )
    # Retorna: BootstrapState actualizado
}
```

### Flujo Interno

1. **Validar pre-condiciones**
   - `Test-Path -Path $RutaProyecto` → detectar colisión
   - Si existe y no `-Force` → error "El directorio ya existe"
   - `Test-Path -Path (Split-Path $RutaProyecto -Parent)` → padre existe
   - Permisos de escritura

2. **Crear árbol de directorios**
   ```
   {RutaProyecto}/
   ├── .hermes/
   ├── src/
   │   ├── __init__.py
   │   └── main.py
   ├── tests/
   │   ├── __init__.py
   │   └── test_main.py
   ├── docs/
   ├── scripts/
   ├── reports/
   ├── config/          (si aplica)
   ├── data/            (si aplica)
   └── notebooks/       (si aplica)
   ```

3. **Registrar metadata**
   ```powershell
   $BootstrapState.Workspace = @{
       RootPath       = $RutaProyecto
       FoldersCreated = $foldersCreated
       ExistedBefore  = $collisionDetected
       CreatedAt      = (Get-Date).ToString('o')
   }
   ```

4. **Actualizar estado** → `Fase01`, `PhaseStatus.Completed`

### Archivos Implicados

- **Crear**: `motor/bootstrap/engine/WorkspaceEngine.ps1` (~120 líneas)
- **Leer**: `configuracion/bootstrap.enterprise.json`
- **No modificar**: `BootstrapState.ps1`, `BootstrapRequest.ps1`

### Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Ruta padre no existe | Error inmediato | Validar antes de crear |
| Permisos insuficientes | Error en creación | `Test-Path` con verificación de escritura |
| Colisión con proyecto existente | Sobrescritura | `-Force` switch + backup automático |
| Nombre de proyecto inválido | Carpetas con caracteres no válidos | Validación via BootstrapRequest |

### Estrategia de Pruebas

| Tipo | Caso | Comando |
|------|------|---------|
| Unitaria | WorkspaceEngine crea carpetas correctamente | `Initialize-WorkspaceEngine -BootstrapRequest $req -BootstrapState $state` |
| Unitaria | WorkspaceEngine detecta colisión sin -Force | Debe retornar error |
| Unitaria | WorkspaceEngine con -Force sobrescribe | Debe continuar |
| Integración | Pipeline completo con WorkspaceEngine | `Invoke-HermesBootstrapPipeline` |

### Criterios de Aceptación

1. [ ] Crea todas las carpetas especificadas en la estructura
2. [ ] Retorna error claro si la ruta padre no existe
3. [ ] Retorna error claro si hay colisión sin `-Force`
4. [ ] Con `-Force`, continúa sin error
5. [ ] Registra metadata de creación en `BootstrapState.Workspace`
6. [ ] No modifica `BootstrapState.ps1` ni `BootstrapRequest.ps1`

---

## 5. Motor 2: Environment Engine

### Responsabilidad Única

Detectar Python, crear entorno virtual aislado, instalar dependencias base.

### Entradas

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `BootstrapRequest` | PSCustomObject | `RuntimePython`, `CrearEnv`, `RutaProyecto` |
| `BootstrapState` | PSCustomObject | Estado actual con `Workspace.RootPath` |

### Salidas

| Salida | Tipo | Descripción |
|--------|------|-------------|
| `BootstrapState` actualizado | PSCustomObject | Phase = Fase02, Environment con metadata |
| Entorno virtual | Directorio | `.venv` en `Workspace.RootPath` |

### Dependencias

- **EnvironmentManager existente** (`motor/bootstrap/engine/environment/EnvironmentManager.ps1`)
  - `Detect-PythonInterpreter` — detección de Python
  - `Test-PythonVersion` — validación de versión
  - `New-IsolatedVenv` — creación atómica de venv con rollback
  - `Install-Dependencies` — instalación de dependencias
  - `Test-HermesEnvironment` — validación de venv
- `Python.ps1` existente — función `Create-PythonEnvironment` (alternativa simple)
- `Observabilidad.ps1` — logging

### Interfaces Públicas

```powershell
function Initialize-EnvironmentEngine {
    param(
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapRequest,
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapState
    )
    # Retorna: BootstrapState actualizado
}
```

### Flujo Interno

1. **Detectar Python** → `Detect-PythonInterpreter` (del EnvironmentManager existente)
2. **Validar versión mínima** → `Test-PythonVersion -Version $info.Version -MinimumVersion $requerida`
3. **Instalar Python si no existe** (solo cuando la plataforma lo permita)
   - Windows: `winget install Python.Python.3.11` o descarga directa
   - Linux/macOS: `apt`, `brew` según corresponda
   - Si no es posible instalar → error claro con instrucciones
4. **Crear .venv** en `{Workspace.RootPath}/.venv` → `New-IsolatedVenv`
5. **Actualizar pip** → `python -m pip install --upgrade pip`
6. **Instalar wheel y setuptools** → `pip install wheel setuptools`
7. **Instalar dependencias base** → desde `requirements.txt` embedido o generado
8. **Generar requirements.txt** si no existe → con paquetes base mínimos
9. **Validar entorno** → `Test-HermesEnvironment`
10. **Registrar metadata** en `BootstrapState.Environment`

### Dependencias Base (requirements.txt embedido)

```
# Hermes Enterprise - Dependencias base
wheel>=0.40.0
setuptools>=68.0.0
pip>=23.0.0
```

### Archivos Implicados

- **Crear**: `motor/bootstrap/engine/EnvironmentEngine.ps1` (~80 líneas, wrapper del EnvironmentManager)
- **Reutilizar** (no modificar): `motor/bootstrap/engine/environment/EnvironmentManager.ps1` (680 líneas)
- **Reutilizar** (no modificar): `motor/bootstrap/functions/Python.ps1` (8 líneas)

### Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Python no instalado | Bloqueante | Instalación automática + instrucciones manuales |
| Versión de Python incompatible | Fallo en venv | Validación temprana con mensaje claro |
| pip desactualizado | Fallo en instalación | `--upgrade pip` siempre |
| Red corporativa | Timeout en instalación | `--timeout` configurable + proxy support |
| Espacio en disco insuficiente | Error silencioso | Verificar espacio antes de crear venv |

### Estrategia de Pruebas

| Tipo | Caso | Comando |
|------|------|---------|
| Unitaria | Detecta Python correctamente | Mock `Get-Command python` |
| Unitaria | Crea .venv en ruta correcta | `Initialize-EnvironmentEngine` con parámetros mock |
| Unitaria | Fallo con Python < 3.8 | Mock versión 3.7 debe fallar |
| Integración | EnvironmentEngine + WorkspaceEngine | Pipeline parcial Fase1+Fase2 |

### Criterios de Aceptación

1. [ ] Detecta Python con 4 estrategias de fallback (HERMES_PYTHON, PATH, py, python3)
2. [ ] Valida que la versión cumpla mínimo 3.8
3. [ ] Instala Python guiado si no existe
4. [ ] Crea .venv en `{Workspace.RootPath}/.venv`
5. [ ] Actualiza pip automáticamente
6. [ ] Instala wheel y setuptools
7. [ ] Genera `requirements.txt` con paquetes base
8. [ ] Instala dependencias desde requirements.txt
9. [ ] Valida el entorno creado con `Test-HermesEnvironment`
10. [ ] Rollback si falla la creación del venv

---

## 6. Motor 3: Project Generator

### Responsabilidad Única

Generar todos los archivos de proyecto (README, LICENSE, CHANGELOG, .gitignore, configuración inicial).

### Entradas

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `BootstrapRequest` | PSCustomObject | `NombreProyecto`, `DescripcionProyecto`, `CrearGitIgnore` |
| `BootstrapState` | PSCustomObject | Estado actual con `Workspace.RootPath` |

### Salidas

| Salida | Tipo | Descripción |
|--------|------|-------------|
| `BootstrapState` actualizado | PSCustomObject | Phase = Fase03, ProjectFiles con lista de archivos creados |
| Archivos generados | Archivos en disco | README.md, LICENSE, CHANGELOG.md, .gitignore, config inicial |

### Dependencias

- Sistema de archivos
- Plantillas (si existen en `plantillas/`)
- `bootstrap.enterprise.json` — configuraciones por defecto

### Interfaces Públicas

```powershell
function Initialize-ProjectGenerator {
    param(
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapRequest,
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapState
    )
    # Retorna: BootstrapState actualizado
}
```

### Archivos a Generar

| Archivo | Contenido Mínimo | Condición |
|---------|-----------------|-----------|
| `README.md` | Nombre del proyecto, descripción, badges, instrucciones de instalación | Siempre |
| `LICENSE` | MIT (por defecto), configurable en bootstrap.enterprise.json | Siempre |
| `CHANGELOG.md` | Versión 0.1.0, fecha, "Initial release" | Siempre |
| `.gitignore` | Python, venv, __pycache__, .env, IDE, OS | `CrearGitIgnore = $true` |
| `.env.example` | Variables de entorno base | Siempre |
| `pyproject.toml` | Configuración de proyecto Python | Siempre (proyecto Python) |
| `setup.cfg` | Metadata del paquete | Siempre (proyecto Python) |
| `src/__init__.py` | Paquete Python | Siempre |
| `src/main.py` | Entry point básico | Siempre |
| `tests/__init__.py` | Paquete de tests | Siempre |
| `tests/test_main.py` | Test básico | Siempre |

### Plantillas

Usar contenido generado por código (no archivos .tpl externos) para mantener independencia. El contenido debe ser profesional y seguir las mejores prácticas de cada tipo de archivo.

Ejemplo de README.md generado:

```markdown
# {NombreProyecto}

> Proyecto generado con Hermes Enterprise

## Descripción

{DescripcionProyecto o "Proyecto Python generado automáticamente"}

## Instalación

```bash
python -m venv .venv
.venv\Scripts\activate  # Windows
source .venv/bin/activate  # Linux/macOS
pip install -r requirements.txt
```

## Uso

```bash
python -m src.main
```

## Desarrollo

```bash
pip install -e .
pytest
```

## Licencia

MIT
```

### Archivos Implicados

- **Crear**: `motor/bootstrap/engine/ProjectGenerator.ps1` (~200 líneas)
- **Leer**: `configuracion/bootstrap.enterprise.json` (tipo de licencia, opciones por defecto)

### Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Archivos ya existen | Sobrescritura | `-Force` switch + backup |
| Nombre de proyecto inválido en README | Referencias rotas | Usar `NombreProyecto` validado del Request |
| Templates faltantes | Archivos genéricos | Generar inline, no depender de archivos .tpl |

### Estrategia de Pruebas

| Tipo | Caso | Comando |
|------|------|---------|
| Unitaria | README.md contiene nombre del proyecto | Verificar contenido del archivo |
| Unitaria | .gitignore excluye .venv y __pycache__ | Verificar contenido |
| Unitaria | LICENSE contiene MIT | Verificar contenido |
| Unitaria | pyproject.toml es TOML válido | `python -m tomllib` |
| Integración | Pipeline con ProjectGenerator | Ejecutar y verificar archivos en disco |

### Criterios de Aceptación

1. [ ] Genera README.md con nombre y descripción del proyecto
2. [ ] Genera LICENSE con MIT (o el configurado)
3. [ ] Genera CHANGELOG.md con versión 0.1.0
4. [ ] Genera .gitignore con exclusiones de Python, venv, IDE
5. [ ] Genera pyproject.toml con configuración básica
6. [ ] Genera src/main.py con entry point funcional
7. [ ] Genera tests/test_main.py con test básico
8. [ ] Genera .env.example con variables documentadas
9. [ ] No sobrescribe archivos existentes sin `-Force`

---

## 7. Motor 4: Git Engine

### Responsabilidad Única

Inicializar repositorio Git, configurar usuario, realizar primer commit.

### Entradas

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `BootstrapRequest` | PSCustomObject | `CrearNuevoRepositorio`, `ProveedorGit` |
| `BootstrapState` | PSCustomObject | Estado actual con `Workspace.RootPath` |

### Salidas

| Salida | Tipo | Descripción |
|--------|------|-------------|
| `BootstrapState` actualizado | PSCustomObject | Phase = Fase04, Git con metadata del repositorio |
| Repositorio Git | Directorio `.git` | Inicializado con commit inicial |

### Dependencias

- Git CLI (`git --version`)
- `Observabilidad.ps1` — logging
- `motor/bootstrap/functions/GitHub.ps1` existente (reutilizar funciones)

### Interfaces Públicas

```powershell
function Initialize-GitEngine {
    param(
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapRequest,
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapState
    )
    # Retorna: BootstrapState actualizado
}
```

### Flujo Interno

1. **Detectar Git** → `Get-Command git -ErrorAction SilentlyContinue`
2. **Si no existe** → error claro con instrucciones de instalación
3. **Configurar usuario si falta** → `git config user.name` y `user.email`
   - Si no hay configuración global → usar defaults de `bootstrap.enterprise.json`
4. **Ejecutar `git init`** en `Workspace.RootPath`
5. **Crear rama principal** → `git branch -M main`
6. **Realizar primer commit** → `git add . && git commit -m "Initial commit: {NombreProyecto}"`
7. **Validar repositorio** → `git rev-parse HEAD`
8. **Registrar metadata** en `BootstrapState.Git`

### Archivos Implicados

- **Crear**: `motor/bootstrap/engine/GitEngine.ps1` (~100 líneas)

### Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Git no instalado | Bloqueante | Error claro con instrucciones |
| Sin configuración de usuario | Commit sin autor | Configurar automáticamente |
| Archivos grandes en staging | Timeout en commit | Verificar tamaño antes de add |
| Rama diferente (master vs main) | Inconsistencia | Forzar `-M main` |

### Estrategia de Pruebas

| Tipo | Caso | Comando |
|------|------|---------|
| Unitaria | git init ejecutado correctamente | Mock `Start-Process git init` |
| Unitaria | Commit contiene mensaje esperado | Verificar `git log --oneline` |
| Unitaria | Rama es 'main' | `git branch --show-current` |
| Integración | Pipeline Fase1+Fase2+Fase3+Fase4 | Proyecto completo con git |

### Criterios de Aceptación

1. [ ] Detecta Git CLI y falla con mensaje claro si no existe
2. [ ] Configura usuario automáticamente si no hay global
3. [ ] Ejecuta `git init` en la ruta del proyecto
4. [ ] Crea rama `main` (no `master`)
5. [ ] Realiza `git add . && git commit` con mensaje descriptivo
6. [ ] Valida el repositorio con `git rev-parse HEAD`
7. [ ] Registra metadata en `BootstrapState.Git`

---

## 8. Motor 5: GitHub Engine

### Responsabilidad Única

Crear repositorio remoto en GitHub y sincronizar con el local.

### Entradas

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `BootstrapRequest` | PSCustomObject | `ProveedorGit`, `AccionRepositorio`, `URLRemoto` |
| `BootstrapState` | PSCustomObject | Estado actual con `Git` y `Workspace` |

### Salidas

| Salida | Tipo | Descripción |
|--------|------|-------------|
| `BootstrapState` actualizado | PSCustomObject | Phase = Fase05, GitHub con URL remota, estado de sincronización |
| Repositorio remoto | GitHub | Creado y sincronizado |

### Dependencias

- **`motor/bootstrap/functions/GitHub.ps1` existente** (no modificar)
  - `Test-GitHubAuthentication` — verifica autenticación
  - `New-GitHubRepository` — crea repo remoto
  - `Connect-GitHubRemote` — asocia origin
  - `Publish-Repository` — push inicial
  - `Verify-GitHubSynchronization` — valida sincronización
- GitHub CLI (`gh --version`)
- `Observabilidad.ps1` — logging

### Interfaces Públicas

```powershell
function Initialize-GitHubEngine {
    param(
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapRequest,
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapState
    )
    # Retorna: BootstrapState actualizado
}
```

### Flujo Interno

1. **Verificar que ProveedorGit sea 'GitHub'** → si no, skip (fase opcional)
2. **Detectar GitHub CLI** → `Get-Command gh -ErrorAction SilentlyContinue`
3. **Verificar autenticación** → `gh auth status`
4. **Si no autenticado** → error claro con instrucciones (`gh auth login`)
5. **Crear repositorio remoto** → `New-GitHubRepository -Name $NombreProyecto`
6. **Asociar origin** → `Connect-GitHubRemote -RepoUri $repoUri`
7. **Ejecutar primer push** → `Publish-Repository`
8. **Validar sincronización** → `Verify-GitHubSynchronization`
9. **Registrar metadata** en `BootstrapState.GitHub`

### Archivos Implicados

- **Crear**: `motor/bootstrap/engine/GitHubEngine.ps1` (~90 líneas)
- **Reutilizar** (no modificar): `motor/bootstrap/functions/GitHub.ps1` (31 líneas)
- **Reutilizar**: `motor/bootstrap/functions/GitHubProvision.ps1` (si existe)

### Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| gh no instalado | Bloqueante (si se requiere GitHub) | Error claro con instrucciones |
| No autenticado | No puede crear repo | Instrucciones para `gh auth login` |
| Nombre de repo ya existe en GitHub | Colisión | `gh repo create` ya maneja este caso |
| Push rechazado (protección de rama) | Push falla | Validar antes de push |
| Sin conectividad a internet | Timeout | Timeout configurable |

### Estrategia de Pruebas

| Tipo | Caso | Comando |
|------|------|---------|
| Unitaria | Detecta gh CLI | Mock `Get-Command gh` |
| Unitaria | Verifica autenticación | Mock `gh auth status` |
| Unitaria | Skip si ProveedorGit != 'GitHub' | Debe retornar sin cambios |
| Integración | Pipeline Fase1-Fase5 | Crear repo real en sandbox |

### Criterios de Aceptación

1. [ ] Skip si `ProveedorGit` no es 'GitHub' (no bloquea el pipeline)
2. [ ] Detecta gh CLI y falla con mensaje claro si no existe
3. [ ] Verifica autenticación y falla con instrucciones si no está autenticado
4. [ ] Crea repositorio remoto con `gh repo create`
5. [ ] Asocia `origin` correctamente
6. [ ] Ejecuta `git push -u origin main`
7. [ ] Valida que HEAD local == HEAD remoto
8. [ ] Registra URL remota en `BootstrapState.GitHub`

---

## 9. Motor 6: Validation Engine

### Responsabilidad Única

Verificar que el proyecto generado es funcional en todos los aspectos.

### Entradas

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `BootstrapState` | PSCustomObject | Estado final con metadata de todos los motores |

### Salidas

| Salida | Tipo | Descripción |
|--------|------|-------------|
| `BootstrapState` actualizado | PSCustomObject | Phase = Fase06, Validation con resultados |
| `ValidationReport` | PSCustomObject | Reporte detallado de validaciones |
| Archivo en disco | JSON | `reports/{NombreProyecto}/validation-report.json` |

### Dependencias

- Sistema de archivos (todas las verificaciones)
- Python (para validar entorno)
- Git CLI (para validar repositorio)
- Todos los motores anteriores deben haber completado

### Interfaces Públicas

```powershell
function Invoke-ValidationEngine {
    param(
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapState
    )
    # Retorna: PSCustomObject con ValidationReport
}
```

### Checks de Validación

| # | Check | Responsable | Comando/Técnica |
|---|-------|------------|-----------------|
| 1 | Estructura de carpetas | Workspace Engine | `Test-Path` para cada carpeta esperada |
| 2 | README.md existe y no está vacío | Project Generator | `Get-Content README.md \| Measure-Object` |
| 3 | LICENSE existe | Project Generator | `Test-Path LICENSE` |
| 4 | CHANGELOG.md existe | Project Generator | `Test-Path CHANGELOG.md` |
| 5 | .gitignore existe (si aplica) | Project Generator | `Test-Path .gitignore` |
| 6 | src/main.py existe y es Python válido | Project Generator | `python -m py_compile src/main.py` |
| 7 | .venv existe | Environment Engine | `Test-Path .venv/pyvenv.cfg` |
| 8 | Python funciona en .venv | Environment Engine | `.venv/Scripts/python --version` |
| 9 | pip funciona | Environment Engine | `.venv/Scripts/pip --version` |
| 10 | Dependencias base instaladas | Environment Engine | `.venv/Scripts/pip list` |
| 11 | .git existe | Git Engine | `Test-Path .git` |
| 12 | Rama es 'main' | Git Engine | `git branch --show-current` |
| 13 | Primer commit existe | Git Engine | `git rev-parse HEAD` |
| 14 | Repositorio sincronizado (si GitHub) | GitHub Engine | `Verify-GitHubSynchronization` |

### Archivos Implicados

- **Crear**: `motor/bootstrap/engine/ValidationEngine.ps1` (~150 líneas)

### Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| Validación muy lenta | Timeout | Timeout por check + paralelización |
| Falso positivo | Proyecto corrupto pero validado | Checks redundantes |
| Falso negativo | Proyecto bueno pero reportado malo | Log detallado para depuración |

### Estrategia de Pruebas

| Tipo | Caso | Comando |
|------|------|---------|
| Unitaria | Cada check individual con mock | Mock de sistema de archivos |
| Unitaria | Reporte contiene todos los checks | Verificar estructura del reporte |
| Integración | Validación contra proyecto real | Ejecutar contra sandbox |

### Criterios de Aceptación

1. [ ] Ejecuta los 14 checks definidos
2. [ ] Cada check retorna: Pass/Fail, Detalle, Tiempo
3. [ ] Genera reporte JSON en disco
4. [ ] Reporte incluye summary: PassCount, FailCount, TotalCount
5. [ ] No detiene el pipeline si falla (solo reporta)
6. [ ] Compatible con proyectos con y sin GitHub

---

## 10. Motor 7: Recovery Engine

### Responsabilidad Única

Detectar interrupciones, reanudar procesos incompletos, ejecutar rollback.

### Entradas

| Parámetro | Tipo | Descripción |
|-----------|------|-------------|
| `BootstrapState` (opcional) | PSCustomObject | Estado previo para reanudar |
| Contexto de sesión | Archivo JSON | `BOOTSTRAP_CONTEXT.json` persistido |

### Salidas

| Salida | Tipo | Descripción |
|--------|------|-------------|
| `BootstrapState` restaurado | PSCustomObject | Estado desde el punto de interrupción |
| Reporte de recuperación | JSON | Detalle de qué se recuperó/rollbackeó |

### Dependencias

- Sistema de archivos (lectura/escritura de contexto)
- `Observabilidad.ps1` — logs de sesiones anteriores
- `BootstrapState.ps1` — serialización/deserialización

### Interfaces Públicas

```powershell
function Resume-BootstrapPipeline {
    param(
        [Parameter(Mandatory)] [string] $BootstrapId
    )
    # Retorna: BootstrapState restaurado
}

function Invoke-BootstrapRollback {
    param(
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapState
    )
    # Retorna: Resultado del rollback
}
```

### Persistencia de Contexto

El estado se persiste en `BOOTSTRAP_CONTEXT.json` en la raíz del proyecto Hermes (no en el proyecto destino):

```json
{
    "BootstrapId": "guid",
    "ProjectName": "MiProyecto",
    "ProjectPath": "D:/Proyectos/MiProyecto",
    "CurrentPhase": "Fase03",
    "Status": "Running",
    "StartedAt": "2026-07-29T10:00:00Z",
    "LastUpdatedAt": "2026-07-29T10:05:00Z",
    "Phases": {
        "Fase01": { "Status": "Completed", "CompletedAt": "..." },
        "Fase02": { "Status": "Completed", "CompletedAt": "..." },
        "Fase03": { "Status": "Running", "StartedAt": "..." },
        "Fase04": { "Status": "Pending" },
        "Fase05": { "Status": "Pending" },
        "Fase06": { "Status": "Pending" },
        "Fase07": { "Status": "Pending" }
    }
}
```

### Estrategia de Rollback

| Fase | Acción de Rollback |
|------|-------------------|
| Fase01 (Workspace) | `Remove-Item -Recurse -Force $ProjectPath` |
| Fase02 (Environment) | `Remove-Item -Recurse -Force .venv` |
| Fase03 (Project Gen) | `Remove-Item` de archivos creados (lista en BootstrapState) |
| Fase04 (Git) | `Remove-Item -Recurse -Force .git` |
| Fase05 (GitHub) | `gh repo delete $NombreProyecto --confirm` (interactivo) |

### Archivos Implicados

- **Crear**: `motor/bootstrap/engine/RecoveryEngine.ps1` (~150 líneas)

### Riesgos

| Riesgo | Impacto | Mitigación |
|--------|---------|------------|
| No hay contexto previo | No se puede reanudar | Error claro, iniciar desde cero |
| Contexto corrupto | Recuperación inválida | Validación del JSON + checksum |
| Rollback de GitHub sin confirmación | Eliminación accidental | Confirmación explícita |
| Rollback incompleto | Estado inconsistente | Log detallado + cleanup manual sugerido |

### Estrategia de Pruebas

| Tipo | Caso | Comando |
|------|------|---------|
| Unitaria | Serializa y deserializa contexto | `ConvertTo-Json` + `ConvertFrom-Json` |
| Unitaria | Reanuda desde Fase03 | Mock de contexto con fases previas completas |
| Unitaria | Rollback de Workspace | Mock de `Remove-Item` |
| Unitaria | Rollback de .venv | Mock de `Remove-Item` |
| Integración | Pipeline completo con interrupción simulada | Matar proceso en medio |

### Criterios de Aceptación

1. [ ] Persiste `BOOTSTRAP_CONTEXT.json` después de cada fase
2. [ ] Puede reanudar desde cualquier fase completada
3. [ ] Rollback de Workspace elimina el directorio del proyecto
4. [ ] Rollback de Environment elimina .venv
5. [ ] Rollback de Project Generator elimina archivos creados
6. [ ] Rollback de Git elimina .git
7. [ ] Rollback de GitHub pide confirmación
8. [ ] Reporte de recuperación detalla cada acción tomada

---

## 11. Pipeline de Orquestación

### `Invoke-HermesBootstrapPipeline`

Es el componente central que orquesta los 7 motores.

### Responsabilidad Única

Ejecutar los motores en secuencia, manejando estado, errores, rollback y persistencia.

### Ubicación

`motor/bootstrap/engine/BootstrapPipeline.ps1` (reemplaza el stub actual en `BootstrapOrchestrator.ps1`)

### Interfaces Públicas

```powershell
function Invoke-HermesBootstrapPipeline {
    param(
        [Parameter(Mandatory)] [PSCustomObject] $BootstrapRequest,
        [PSCustomObject] $BootstrapState = $null,  # Para reanudación
        [switch] $Force
    )
    # Retorna: PSCustomObject con BootstrapReport
}

function Get-BootstrapPipelineStatus {
    param([string] $BootstrapId)
    # Retorna: estado actual de un pipeline en ejecución
}

function Stop-BootstrapPipeline {
    param([string] $BootstrapId)
    # Detiene el pipeline y ejecuta rollback
}
```

### Flujo de Orquestación

```
Invoke-HermesBootstrapPipeline
│
├─ 1. Pre-flight
│   ├─ Validar BootstrapRequest con Test-BootstrapRequest
│   ├─ Verificar si existe contexto previo (para reanudación)
│   ├─ Crear/restaurar BootstrapState
│   └─ Persistir contexto inicial (BOOTSTRAP_CONTEXT.json)
│
├─ 2. Fase 1: Workspace Engine
│   ├─ Initialize-WorkspaceEngine
│   ├─ ¿Éxito? → persistir contexto, continuar
│   └─ ¿Fallo? → RecoveryEngine.Resume o Rollback
│
├─ 3. Fase 2: Environment Engine
│   ├─ ¿CrearEnv? → Initialize-EnvironmentEngine
│   ├─ ¿No? → skip con estado "NotRequired"
│   ├─ ¿Éxito? → persistir contexto, continuar
│   └─ ¿Fallo? → RecoveryEngine.Resume o Rollback
│
├─ 4. Fase 3: Project Generator
│   ├─ Initialize-ProjectGenerator
│   ├─ ¿Éxito? → persistir contexto, continuar
│   └─ ¿Fallo? → RecoveryEngine.Resume o Rollback
│
├─ 5. Fase 4: Git Engine
│   ├─ ¿CrearNuevoRepositorio? → Initialize-GitEngine
│   ├─ ¿No? → skip con estado "NotRequired"
│   ├─ ¿Éxito? → persistir contexto, continuar
│   └─ ¿Fallo? → RecoveryEngine.Resume o Rollback
│
├─ 6. Fase 5: GitHub Engine
│   ├─ ¿ProveedorGit = 'GitHub'? → Initialize-GitHubEngine
│   ├─ ¿No? → skip con estado "NotRequired"
│   ├─ ¿Éxito? → persistir contexto, continuar
│   └─ ¿Fallo? → RecoveryEngine.Resume o Rollback
│
├─ 7. Fase 6: Validation Engine
│   ├─ Invoke-ValidationEngine
│   └─ Persistir reporte de validación
│
├─ 8. Post-flight
│   ├─ Generar BootstrapReport final
│   ├─ Limpiar contexto temporal (opcional)
│   ├─ Abrir VSCode (si AbrirVSCode)
│   └─ Retornar resultado
│
└─ Manejo global de errores
    ├─ Capturar cualquier excepción no manejada
    ├─ Persistir contexto con estado "Failed"
    └─ Retornar BootstrapReport con error
```

### Contrato de BootstrapReport

```powershell
$BootstrapReport = [PSCustomObject]@{
    PSTypeName    = 'Hermes.Bootstrap.Report'
    Success       = $true  # $false si alguna fase crítica falló
    BootstrapId   = $BootstrapState.Id
    ProjectName   = $BootstrapRequest.NombreProyecto
    ProjectPath   = $BootstrapRequest.RutaProyecto
    StartedAt     = $startedAt
    FinishedAt    = (Get-Date).ToString('o')
    TotalDuration = $totalDuration
    Phases = [PSCustomObject]@{
        Workspace   = @{ Status = 'Completed'; Duration = '...'; Details = @{} }
        Environment = @{ Status = 'Completed'; Duration = '...'; Details = @{} }
        ProjectGen  = @{ Status = 'Completed'; Duration = '...'; Details = @{} }
        Git         = @{ Status = 'Completed'; Duration = '...'; Details = @{} }
        GitHub      = @{ Status = 'Skipped'; Reason = 'NotRequired' }
        Validation  = @{ Status = 'Completed'; PassCount = 14; FailCount = 0 }
        Recovery    = @{ Status = 'NotRequired' }
    }
    ProximaAccion = 'Workspace abierto en VSCode'  # o 'Continuar en VSCode', etc.
    ValidationReport = $validationReport  # null si no se ejecutó validación
}
```

### Archivos Implicados

- **Crear**: `motor/bootstrap/engine/BootstrapPipeline.ps1` (~200 líneas)
- **Modificar** (mínimo): `motor/bootstrap/engine/BootstrapOrchestrator.ps1` — actualizar stub para delegar en el pipeline

### Manejo de Errores

```
┌─────────────────────────────────────────┐
│ Error en Fase N                         │
└─────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────┐
│ 1. Persistir contexto con               │
│    CurrentPhase = FaseN                 │
│    Status = Failed                      │
│    ErrorMessage = detalles              │
└─────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────┐
│ 2. ¿Force?                              │
│   ├─ Sí → continuar con siguiente fase  │
│   └─ No → detener pipeline              │
└─────────────────────────────────────────┘
         │
         ↓
┌─────────────────────────────────────────┐
│ 3. Retornar BootstrapReport             │
│    con Success = $false                 │
│    y fase fallida documentada           │
└─────────────────────────────────────────┘
```

---

## 12. Contratos y Estados

### Mapeo BootstrapPhase → Motor

| Fase | Motor | Archivo del Motor |
|------|-------|-------------------|
| `Fase00` | Inicialización | `BootstrapPipeline.ps1` |
| `Fase01` | Workspace Engine | `WorkspaceEngine.ps1` |
| `Fase02` | Environment Engine | `EnvironmentEngine.ps1` |
| `Fase03` | Project Generator | `ProjectGenerator.ps1` |
| `Fase04` | Git Engine | `GitEngine.ps1` |
| `Fase05` | GitHub Engine | `GitHubEngine.ps1` |
| `Fase06` | Validation Engine | `ValidationEngine.ps1` |
| `Fase07`–`Fase13` | Recovery / Futuro | `RecoveryEngine.ps1` + reserva |

### Flujo de Estado (BootstrapState)

```
New-HermesBootstrapState
    │ Id = guid, Phase = Fase00, Status = Pending
    │
    ├─ [Pipeline] → Phase = Fase01, Status = Running
    │   ↓
    ├─ [Workspace] → Phase = Fase01, Status = Completed
    │   └─ Workspace = { RootPath, FoldersCreated, ... }
    │   ↓
    ├─ [Pipeline] → Phase = Fase02, Status = Running
    │   ↓
    ├─ [Environment] → Phase = Fase02, Status = Completed
    │   └─ Environment = { VenvPath, PythonVersion, ... }
    │   ↓
    ├─ [Pipeline] → Phase = Fase03, Status = Running
    │   ↓
    ├─ [ProjectGen] → Phase = Fase03, Status = Completed
    │   └─ ProjectFiles = { FilesCreated, ... }
    │   ↓
    ├─ [Pipeline] → Phase = Fase04, Status = Running
    │   ↓
    ├─ [Git] → Phase = Fase04, Status = Completed
    │   └─ Git = { RepoPath, Branch, CommitHash, ... }
    │   ↓
    ├─ [Pipeline] → Phase = Fase05, Status = Running
    │   ↓
    ├─ [GitHub] → Phase = Fase05, Status = Completed/Skipped
    │   └─ GitHub = { RemoteUrl, SyncStatus, ... }
    │   ↓
    ├─ [Pipeline] → Phase = Fase06, Status = Running
    │   ↓
    ├─ [Validation] → Phase = Fase06, Status = Completed
    │   └─ Validation = { PassCount, FailCount, Checks, ... }
    │   ↓
    └─ [Pipeline] → Phase = Fase06, Status = Completed
        └─ FinishedAt = timestamp
```

---

## 13. Archivos Implicados

### Archivos a Crear (7 nuevos)

| # | Ruta | Líneas Est. | Depende de |
|---|------|-------------|------------|
| 1 | `motor/bootstrap/engine/WorkspaceEngine.ps1` | ~120 | BootstrapState |
| 2 | `motor/bootstrap/engine/EnvironmentEngine.ps1` | ~80 | EnvironmentManager existente |
| 3 | `motor/bootstrap/engine/ProjectGenerator.ps1` | ~200 | BootstrapState |
| 4 | `motor/bootstrap/engine/GitEngine.ps1` | ~100 | BootstrapState |
| 5 | `motor/bootstrap/engine/GitHubEngine.ps1` | ~90 | GitHub.ps1 existente |
| 6 | `motor/bootstrap/engine/ValidationEngine.ps1` | ~150 | Todos los anteriores |
| 7 | `motor/bootstrap/engine/RecoveryEngine.ps1` | ~150 | BootstrapState |
| 8 | `motor/bootstrap/engine/BootstrapPipeline.ps1` | ~200 | Todos los motores |

**Total estimado: ~1,090 líneas nuevas** de las cuales ~680 ya existen en EnvironmentManager (reutilizado), por lo que **el nuevo código neto es ~410 líneas**.

### Archivos a Modificar (mínimo)

| Ruta | Cambio |
|------|--------|
| `motor/bootstrap/engine/BootstrapOrchestrator.ps1` | Actualizar stub para delegar en `Invoke-HermesBootstrapPipeline` |

### Archivos a Reutilizar (sin modificar)

| Ruta | Líneas | Contenido |
|------|--------|-----------|
| `motor/bootstrap/engine/environment/EnvironmentManager.ps1` | 680 | Environment Engine completo (no tocar) |
| `motor/bootstrap/functions/GitHub.ps1` | 31 | Funciones de GitHub (no tocar) |
| `motor/bootstrap/functions/Python.ps1` | 8 | Función simple de Python (no tocar) |
| `motor/bootstrap/request/BootstrapRequest.ps1` | 282 | DTO de solicitud (no tocar) |
| `motor/bootstrap/engine/BootstrapState.ps1` | 170 | Contrato de estado (no tocar) |
| `motor/bootstrap/Start-HermesProject.ps1` | ~80 | Entry point público (no tocar) |
| `motor/tools/Observabilidad.ps1` | Variable | Logging (no tocar) |

### Archivos de Configuración a Consumir

| Ruta | Contenido | Se consume en |
|------|-----------|---------------|
| `configuracion/bootstrap.enterprise.json` | Rutas, entornos, githubOwner | BootstrapPipeline (carga inicial) |
| `configuracion/kernel.enterprise.json` | Versión, entorno | BootstrapPipeline (metadata) |

---

## 14. Estrategia de Pruebas

### Niveles de Prueba

#### 1. Pruebas Unitarias (por motor, aisladas con mocks)

| Motor | Archivo de Test | Framework |
|-------|-----------------|-----------|
| Workspace Engine | `pruebas/unitarias/Test-WorkspaceEngine.ps1` | Pester 5 |
| Environment Engine | `pruebas/unitarias/Test-EnvironmentEngine.ps1` | Pester 5 |
| Project Generator | `pruebas/unitarias/Test-ProjectGenerator.ps1` | Pester 5 |
| Git Engine | `pruebas/unitarias/Test-GitEngine.ps1` | Pester 5 |
| GitHub Engine | `pruebas/unitarias/Test-GitHubEngine.ps1` | Pester 5 |
| Validation Engine | `pruebas/unitarias/Test-ValidationEngine.ps1` | Pester 5 |
| Recovery Engine | `pruebas/unitarias/Test-RecoveryEngine.ps1` | Pester 5 |
| BootstrapPipeline | `pruebas/unitarias/Test-BootstrapPipeline.ps1` | Pester 5 |

#### 2. Pruebas de Integración

| Prueba | Descripción | Comando |
|--------|-------------|---------|
| Pipeline F1+F2 | Workspace + Environment | `Invoke-HermesBootstrapPipeline -Phases @('Workspace','Environment')` |
| Pipeline F1+F3 | Workspace + Project Gen | Mismo patrón |
| Pipeline F1+F4 | Workspace + Git | Mismo patrón |
| Pipeline F1+F5 | Workspace + GitHub | Mismo patrón (con mock de gh) |
| Pipeline Completo | Todas las fases | `Invoke-HermesBootstrapPipeline` completo |
| Reanudación | Interrumpir en F3, reanudar | Matar proceso, ejecutar con `-BootstrapState` previo |
| Rollback | Fallar en F4, verificar rollback | Forzar error en Git Engine |

#### 3. Pruebas End-to-End (Sandbox)

Ejecutar en `sandbox/` cada vez que se complete un motor:

```powershell
cd sandbox
Invoke-HermesBootstrapPipeline -BootstrapRequest $request -Force
# Verificar:
# - sandbox/ProyectoTestXXX/ existe con estructura completa
# - .venv/ existe y es funcional
# - src/main.py existe y ejecuta sin error
# - .git/ existe con commit
# - git log muestra "Initial commit"
```

### Sandbox como Entorno Oficial de Validación

El directorio `sandbox/` se convierte en el entorno oficial para pruebas E2E:

```
sandbox/
├── ProyectoTest001/    # Pruebas manuales previas
├── ProyectoTest002/    # Pruebas manuales previas
├── ...
├── ProyectoTestXXX/    # Último proyecto generado
└── Local/              # Entorno local compartido
```

**Regla**: Después de cada cambio significativo en el pipeline, ejecutar una generación completa en `sandbox/` y verificar los 14 checks de validación.

---

## 15. Riesgos y Mitigaciones

| # | Riesgo | Probabilidad | Impacto | Mitigación |
|---|--------|-------------|---------|------------|
| 1 | EnvironmentManager existente tiene bugs no detectados | Media | Alta | Pruebas unitarias antes de integrar |
| 2 | GitHub.ps1 existente tiene funciones frágiles | Media | Media | Wrapper con try/catch adicional |
| 3 | `bootstrap.enterprise.json` tiene rutas absolutas hardcodeadas | Alta | Media | Usar como defaults, permitir override |
| 4 | Python no está disponible en el sistema del usuario | Alta | Alta | Instalación guiada + error claro |
| 5 | gh CLI no instalado o desactualizado | Media | Baja | Fase opcional, no bloquea |
| 6 | Espacio en disco insuficiente | Baja | Alta | Verificar espacio antes de Fase01 |
| 7 | Permisos de escritura insuficientes en ruta destino | Media | Alta | Validar en pre-flight |
| 8 | Rollback de GitHub elimina repo por error | Baja | Alta | Confirmación explícita del usuario |
| 9 | Timeout en instalación de dependencias (red lenta) | Media | Media | Timeout configurable + progreso visible |
| 10 | El proyecto generado tiene 0 líneas de código real | Alta | Baja | Es esperado — el usuario agrega su código |

---

## 16. Criterios de Aceptación Globales

### Checklist Definitiva

- [ ] **1. Pipeline completo ejecuta 7 fases**
  - [ ] Fase 1: Crea estructura de carpetas
  - [ ] Fase 2: Crea .venv, instala dependencias
  - [ ] Fase 3: Crea README, LICENSE, CHANGELOG, .gitignore, src/, tests/
  - [ ] Fase 4: git init, commit inicial
  - [ ] Fase 5: gh repo create, push (opcional)
  - [ ] Fase 6: Valida los 14 checks
  - [ ] Fase 7: Persiste contexto para reanudación

- [ ] **2. Proyecto generado es funcional**
  - [ ] `python -m src.main` ejecuta sin error
  - [ ] `pytest` ejecuta sin error
  - [ ] `.venv/Scripts/python --version` retorna versión ≥ 3.8
  - [ ] `git log` muestra commit inicial
  - [ ] `git branch --show-current` retorna "main"

- [ ] **3. Pipeline es resiliente**
  - [ ] Error en Fase N → persiste contexto, permite reanudar
  - [ ] `-Force` salta fases fallidas no críticas
  - [ ] Rollback elimina artefactos parciales
  - [ ] Sin Python → error claro, no crash
  - [ ] Sin Git → error claro, no crash

- [ ] **4. Pipeline es extensible**
  - [ ] Agregar nuevo motor = crear archivo + agregar llamada en Pipeline
  - [ ] Cada motor puede probarse de forma aislada
  - [ ] BootstrapState no se modifica al agregar motores

- [ ] **5. Reporte de creación es completo**
  - [ ] Incluye estado de cada fase
  - [ ] Incluye duración total y por fase
  - [ ] Incluye URL de GitHub (si aplica)
  - [ ] Incluye reporte de validación

- [ ] **6. Sandbox validado**
  - [ ] `sandbox/ProyectoTestXXX/` existe
  - [ ] Estructura completa verificada
  - [ ] Entorno virtual funcional
  - [ ] Repositorio Git válido
  - [ ] Repositorio GitHub creado y sincronizado

---

## 17. Hoja de Ruta de Implementación

### Fase 1: Fundación (1 día)

| Orden | Archivo | Dependencias |
|-------|---------|--------------|
| 1 | `motor/bootstrap/engine/BootstrapPipeline.ps1` | BootstrapState, BootstrapRequest |
| 2 | `motor/bootstrap/engine/WorkspaceEngine.ps1` | BootstrapPipeline |
| 3 | Pruebas: WorkspaceEngine | — |
| 4 | Pruebas: Pipeline con Fase01 | — |

**Checkpoint 1**: `Invoke-HermesBootstrapPipeline -Phases @('Workspace')` crea carpetas correctamente.

### Fase 2: Environment (1 día)

| Orden | Archivo | Dependencias |
|-------|---------|--------------|
| 5 | `motor/bootstrap/engine/EnvironmentEngine.ps1` | EnvironmentManager existente |
| 6 | Pruebas: EnvironmentEngine | — |
| 7 | Integrar Fase02 en Pipeline | BootstrapPipeline |

**Checkpoint 2**: Pipeline F1+F2 crea proyecto con .venv funcional.

### Fase 3: Project Generator (1 día)

| Orden | Archivo | Dependencias |
|-------|---------|--------------|
| 8 | `motor/bootstrap/engine/ProjectGenerator.ps1` | BootstrapState |
| 9 | Pruebas: ProjectGenerator | — |
| 10 | Integrar Fase03 en Pipeline | BootstrapPipeline |

**Checkpoint 3**: Pipeline F1+F2+F3 crea proyecto completo con README, src/.

### Fase 4: Git + GitHub (1 día)

| Orden | Archivo | Dependencias |
|-------|---------|--------------|
| 11 | `motor/bootstrap/engine/GitEngine.ps1` | BootstrapState |
| 12 | Pruebas: GitEngine | — |
| 13 | `motor/bootstrap/engine/GitHubEngine.ps1` | GitHub.ps1 existente |
| 14 | Pruebas: GitHubEngine | — |
| 15 | Integrar Fase04+Fase05 en Pipeline | BootstrapPipeline |

**Checkpoint 4**: Pipeline F1-F5 crea proyecto con Git y GitHub sincronizado.

### Fase 5: Validation + Recovery (1 día)

| Orden | Archivo | Dependencias |
|-------|---------|--------------|
| 16 | `motor/bootstrap/engine/ValidationEngine.ps1` | Todos los motores |
| 17 | Pruebas: ValidationEngine | — |
| 18 | `motor/bootstrap/engine/RecoveryEngine.ps1` | BootstrapState |
| 19 | Pruebas: RecoveryEngine | — |
| 20 | Integrar Fase06+Fase07 en Pipeline | BootstrapPipeline |

**Checkpoint 5**: Pipeline completo con validación y reanudación.

### Fase 6: End-to-End + Sandbox Validation (1 día)

| Orden | Tarea |
|-------|-------|
| 21 | Ejecutar pipeline contra sandbox/ |
| 22 | Verificar 14 checks de validación |
| 23 | Probar reanudación (interrupción simulada) |
| 24 | Probar rollback en cada fase |
| 25 | Actualizar `BootstrapOrchestrator.ps1` para delegar en Pipeline |

**Checkpoint Final**: Hermes Enterprise genera proyectos completos desde cero.

---

> **Fin del Documento**
>
> Próximo paso: Revisión y aprobación antes de iniciar la implementación.