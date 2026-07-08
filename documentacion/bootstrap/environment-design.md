---
title: "Environment Manager - Diseño Técnico"
project: "HERMES Enterprise"
component: "Bootstrap Engine"
step: 3
status: "Implementado"
version: "1.0.0"
created: "2026-07-08"
author: "Hermes Architect"
tags:
  - bootstrap
  - environment
  - python
  - venv
---

# Environment Manager - Paso 3

## Índice

1. [Objetivo](#objetivo)
2. [Arquitectura](#arquitectura)
3. [API Pública](#api-pública)
4. [Flujo de Ejecución](#flujo-de-ejecución)
5. [Manejo de Errores](#manejo-de-errores)
6. [Pruebas Unitarias](#pruebas-unitarias)
7. [Restricciones y Consideraciones](#restricciones-y-consideraciones)
8. [Dependencias](#dependencias)

---

## Objetivo

Gestionar el ciclo de vida completo de entornos Python aislados para proyectos Hermes Enterprise:

- **Detección** de intérprete Python disponible
- **Creación atómica** de venvs con rollback automático
- **Instalación** de dependencias
- **Activación/desactivación** en la sesión activa
- **Registro** del estado en BootstrapState
- **Publicación** de eventos al EventBus

---

## Arquitectura

```
┌─────────────────────────────────────────────────────────────┐
│                    BootstrapState (Input)                    │
│                    (Inmutable entrada)                       │
└──────────────────────────┬──────────────────────────────────┘
                           │
                           ▼
        ┌──────────────────────────────────┐
        │   New-HermesEnvironment          │
        │   (Orquestador principal)        │
        └──────────────┬───────────────────┘
                       │
          ┌────────────┼────────────┐
          │            │            │
          ▼            ▼            ▼
    ┌─────────┐  ┌──────────┐  ┌──────────┐
    │ Detect  │  │  Create  │  │ Install  │
    │ Python  │  │   Venv   │  │   Deps   │
    └────┬────┘  └────┬─────┘  └────┬─────┘
         │            │             │
         └────────────┼─────────────┘
                      │
                      ▼
              ┌──────────────┐
              │ Test/Sanity  │
              │   Check      │
              └──────┬───────┘
                     │
                     ▼
        ┌────────────────────────┐
        │  BootstrapState.Set    │
        │   Environment()        │
        │   (Actualización)      │
        └────────────────────────┘
                     │
                     ▼
        ┌────────────────────────┐
        │  EventBus.Publish      │
        │  Bootstrap.Environment │
        │  {Started|Completed|   │
        │   Failed}              │
        └────────────────────────┘
```

---

## API Pública

### Funciones Principales

| Función | Descripción | Parámetros | Retorna |
|---------|-------------|------------|---------|
| `New-HermesEnvironment` | Orquestador de alto nivel | BootstrapState, EnvironmentsRoot, RequirementsPath, ExtraPackages | BootstrapState actualizado |
| `Initialize-HermesEnvironment` | Alias interno de New-HermesEnvironment | (mismos) | (mismo) |
| `Enter-HermesEnvironment` | Activa venv en sesión actual | VenvPath | void (modifica $env:PATH) |
| `Exit-HermesEnvironment` | Desactiva venv, restaura PATH | (ninguno) | void |
| `Get-HermesEnvironmentStatus` | Obtiene metadata del environment | ProjectName, EnvironmentsRoot | PSCustomObject |
| `Test-HermesEnvironment` | Sanity-check del venv | VenvPath | PSCustomObject con estado |

### Funciones Internas

| Función | Descripción |
|---------|-------------|
| `Detect-PythonInterpreter` | Detecta Python en sistema (HERMES_PYTHON → python → py → python3) |
| `Test-PythonVersion` | Valida versión semver contra mínimo |
| `New-IsolatedVenv` | Crea venv atómico con rollback |
| `Install-Dependencies` | Instala pip, requirements, paquetes extra |

---

## Flujo de Ejecución

### Secuencia Detallada

```powershell
1. Receive BootstrapState (lectura)
2. Publish-Event "Bootstrap.Environment.Started"
3. Detect-PythonInterpreter
   ├─ Check $env:HERMES_PYTHON
   ├─ Check python.exe en PATH
   ├─ Check py.exe launcher (Windows)
   └─ Check python3.exe en PATH
4. Validate version >= 3.8
5. New-IsolatedVenv
   ├─ Create EnvironmentsRoot si no existe
   ├─ Check idempotencia (venv ya existe y es válido)
   ├─ Ejecutar: python -m venv <path>
   ├─ Verificar creación exitosa
   └─ Rollback si falla
6. Install-Dependencies
   ├─ Upgrade pip
   ├─ Install requirements.txt (si existe)
   └─ Install extra packages
7. Test-HermesEnvironment
   ├─ Verificar pyvenv.cfg
   ├─ Verificar python.exe en venv
   ├─ Verificar pip.exe en venv
   └─ Obtener versión
8. BootstrapState.SetEnvironment(metadata)
9. Publish-Event "Bootstrap.Environment.Completed"
```

### Manejo de Errores

```
Cualquier fallo en pasos 5-8:
├─ Rollback automático del venv
├─ Publish-Event "Bootstrap.Environment.Failed"
├─ Mensaje de error con causa raíz
└─ Throw exception
```

---

## Manejo de Errores

### Escenarios Críticos

| Escenario | Estrategia |
|-----------|------------|
| Python no encontrado | Throw InvalidOperationException con instrucciones |
| Versión Python < 3.8 | Throw InvalidOperationException |
| Venv corrupto (sin pyvenv.cfg) | Throw InvalidOperationException |
| Fallo en creación venv | Rollback automático + throw |
| Fallo en pip install | Throw con código de salida |
| Venv inválido post-creación | Throw con detalle diagnóstico |

### Rutas con Espacios

Todas las rutas se manejan con:
- `Test-Path -LiteralPath` (no wildcard expansion)
- Comillas dobles implícitas en argumentos
- Join-Path en lugar de concatenación manual

---

## Pruebas Unitarias

### Suite de 14 Casos

| # | Test | Valida |
|---|------|--------|
| 1 | Detect-PythonInterpreter | Detección de intérprete |
| 2 | Test-PythonVersion (3.11.5 >= 3.8) | Validación versión válida |
| 3 | Test-PythonVersion (3.7.0 < 3.8) | Rechazo versión antigua |
| 4 | Test-PythonVersion ('abc') | Manejo versión inválida |
| 5 | New-IsolatedVenv | Creación exitosa |
| 6 | New-IsolatedVenv (idempotente) | Segunda llamada no falla |
| 7 | Install-Dependencies | Actualización pip |
| 8 | Test-HermesEnvironment (venv sano) | Validación completa |
| 9 | Test-HermesEnvironment (no existe) | Detección inexistencia |
| 10 | Enter-HermesEnvironment | Modificación PATH |
| 11 | Exit-HermesEnvironment | Restauración PATH |
| 12 | Get-HermesEnvironmentStatus | Metadata completa |
| 13 | Initialize-HermesEnvironment | Flujo completo |
| 14 | New-IsolatedVenv (corrupto) | Rechazo directorio inválido |

### Ejecución

```powershell
cd D:\HERMES-ENTERPRISE
.\pruebas\unitarias\environment\Test-EnvironmentManager.ps1
```

### Limpieza Automática

- Todos los venvs creados en `%TEMP%\hermes-env-tests-*`
- Eliminados al final del script
- PATH restaurado a estado original

---

## Restricciones y Consideraciones

### Presupuestos de Líneas

| Archivo | Máximo |
|---------|--------|
| `EnvironmentManager.ps1` | 350 líneas |
| `Test-EnvironmentManager.ps1` | 450 líneas |

### No Modifica

- ❌ BootstrapState (Paso 1)
- ❌ BootstrapWizard (Paso 2)
- ❌ Kernel
- ❌ Sandbox
- ❌ EventBus
- ❌ Logger
- ❌ Contratos públicos existentes

### Consideraciones de Plataforma

- **Windows**: Usa `Scripts\` para binarios en venv
- **Linux/Mac**: Usa `bin/` para binarios en venv
- **Detección condicional**: `$IsWindows` o `$env:OS -match 'Windows'`

---

## Dependencias

### Módulos Requeridos

- `BootstrapState.ps1` (Paso 1) - lectura de ProjectName
- `EventBus` existente (opcional, comentado por defecto)

### Dependencias Externas

- Python 3.8+ instalado en el sistema
- Acceso a red para pip install (si hay requirements)

### Integración Futura

Este módulo será consumido por:
- `Start-HermesProject.ps1` (Paso 4+) como fase del flujo principal
- Potencialmente por otros módulos que necesiten environments aislados

---

## Navegación Cruzada

- [← BootstrapState (Paso 1)](bootstrap-state-design.md)
- [← BootstrapWizard (Paso 2)](bootstrap-wizard-design.md)
- [→ Start-HermesProject (Paso 4)](start-hermes-project-design.md) *(pendiente)*

---

## Changelog

### v1.0.0 (2026-07-08)

- ✅ Implementación completa del Environment Manager
- ✅ 14 pruebas unitarias
- ✅ Script temporal de verificación con limpieza automática
- ✅ Documentación técnica completa
