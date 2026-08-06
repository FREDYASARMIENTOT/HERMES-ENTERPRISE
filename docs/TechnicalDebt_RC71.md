# RC71-A — INFORME DE DEUDA TÉCNICA: HARDENING DEL CORE PYTHON

> **Fecha:** 2026-05-08  
> **Versión:** 1.0.0  
> **Estado:** Auditoría completa — Pendiente de implementación  
> **Pre-requisito:** RC70-D (Runtime Python estabilizado)

---

## ÍNDICE

1. [RESUMEN EJECUTIVO](#1-resumen-ejecutivo)
2. [FASE 1: HALLAZGOS DE AUDITORÍA](#2-fase-1-hallazgos-de-auditoría)
3. [FASE 2: CLASIFICACIÓN DE RIESGOS](#3-fase-2-clasificación-de-riesgos)
4. [FASE 3: ESTUDIO Hermes.Web](#4-fase-3-estudio-hermesweb)
5. [FASE 4: Python Packaging (pyproject.toml)](#5-fase-4-python-packaging)
6. [FASE 5: CLASIFICACIÓN DE DEPENDENCIAS](#6-fase-5-clasificación-de-dependencias)
7. [FASE 6: CALIDAD Y HERRAMIENTAS](#7-fase-6-calidad-y-herramientas)
8. [FASE 7: TESTING](#8-fase-7-testing)
9. [FASE 8: POWERSHELL](#9-fase-8-powershell)
10. [FASE 9: AZURE](#10-fase-9-azure)
11. [FASE 10: CI/CD](#11-fase-10-cicd)
12. [FASE 11: DOCUMENTACIÓN](#12-fase-11-documentación)
13. [PROPUESTA RC72](#13-propuesta-rc72)
14. [BACKLOG PRIORIZADO](#14-backlog-priorizado)
15. [ESTIMACIÓN DE ESFUERZO](#15-estimación-de-esfuerzo)

---

## 1. RESUMEN EJECUTIVO

### 1.1 Estado General

| Métrica | Valor |
|---------|-------|
| Archivos Python auditados | 23 |
| Archivos PowerShell auditados | ~80+ |
| Hallazgos críticos | 6 |
| Hallazgos altos | 12 |
| Hallazgos medios | 18 |
| Hallazgos bajos | 25 |
| Deuda técnica estimada (días-hombre) | 25-35 |
| Riesgo general | ALTO |

### 1.2 Problemas Estructurales Principales

1. **Dependencia de `sys.path.insert` + `MetaPathFinder`** para resolver Hermes.Web como paquete. Esto es un workaround arquitectónico frágil.
2. **Duplicación de lógica de subprocess** en 3 archivos distintos (main.py, servicio_datos_proyecto.py, api_version.py).
3. **Rutas Windows absolutas** hardcodeadas en múltiples archivos.
4. **Código muerto y archivos no utilizados** en el repositorio.
5. **Tests insuficientes**: solo 2 suites Pester para ~80+ cmdlets PowerShell, 0 tests Python.
6. **Imports circulares potenciales** y dependencias ocultas no registradas en requirements.txt.
7. **Mezcla de responsabilidades** en backend/main.py (~570 líneas) que combina: carga de paquetes, MetaPathFinder, configuración FastAPI, definición de rutas, ejecución de subprocess.

---

## 2. FASE 1: HALLAZGOS DE AUDITORÍA

### 2.1 sys.path.insert (HALLAZGO #1)

| Archivo | Línea | Código |
|---------|-------|--------|
| `Hermes.Web/backend/main.py` | 46 | `sys.path.insert(0, str(_PROJECT_ROOT))` |

**Problema:** Modifica `sys.path` globalmente. Si otro módulo depende del orden original de búsqueda, puede producir efectos colaterales.

**Severidad:** ALTO (afecta reproducibilidad)

---

### 2.2 MetaPathFinder y Loader Personalizados (HALLAZGO #2)

| Archivo | Líneas | Clase |
|---------|--------|-------|
| `Hermes.Web/backend/main.py` | 49-123 | `HermesWebPackageLoader`, `HermesWebFinder` |

**Problema:**
- `HermesWebFinder` se registra en `sys.meta_path` (línea 123).
- `HermesWebPackageLoader.create_module()` retorna `None` usando semántica default, pero `exec_module()` delega en otro loader — esto es potencialmente inestable.
- Si `_HERMES_WEB_DIR` cambia o no existe, el Finder falla silenciosamente.
- El logger se inicializa ANTES de que el Finder esté registrado, pero se usa DESPUÉS (línea 125).

**Severidad:** CRÍTICO (el mecanismo de importación depende de esto)

---

### 2.3 Subprocess Duplicado (HALLAZGO #3)

| Archivo | Líneas | Función/Método |
|---------|--------|---------------|
| `Hermes.Web/backend/main.py` | 402-466 | `ejecutar_comando_hermes()` |
| `Hermes.Web/backend/servicio_datos_proyecto.py` | 96-194 | `_ejecutar_comando_powershell()` |
| `Hermes.Web/backend/servicio_datos_proyecto.py` | 290-351 | `_leer_git_desde_cli()` |
| `Hermes.Web/backend/servicio_datos_proyecto.py` | 404-413 | `_ejecutar_pip()` |
| `Hermes.Web/api/api_version.py` | 38-52 | Ejecución directa de `git` |

**Problema:** 3 implementaciones diferentes de subprocess. `main.py` llama a PowerShell con `ConvertTo-Json`, mientras `servicio_datos_proyecto.py` hace lo mismo pero con `-Depth 10`. La lógica de error/parsing es inconsistente.

**Severidad:** ALTO (mantenibilidad y consistencia)

---

### 2.4 Rutas Windows Absolutas (HALLAZGO #4)

| Archivo | Línea | Código |
|---------|-------|--------|
| `Hermes.Web/backend/main.py` | 8 | `cd d:\\HERMES-ENTERPRISE` (en docstring) |

**Problema:** Aunque es solo documentación, refleja dependencia de una ruta específica de Windows. En Azure App Service, esta ruta no existe.

**Severidad:** MEDIO

---

### 2.5 Dependencia de Python Global (HALLAZGO #5)

| Archivo | Línea | Código |
|---------|-------|--------|
| `Hermes.Web/backend/servicio_datos_proyecto.py` | 408 | `[sys.executable, "-m", "pip", ...]` |

**Problema:** `sys.executable` apunta al intérprete actual, pero en producción debería usar la ruta desde `Hermes.Python.json`.

**Severidad:** ALTO

---

### 2.6 Código Muerto y Duplicación (HALLAZGO #6)

#### Archivos potencialmente no utilizados:

| Archivo | Problema |
|---------|----------|
| `Hermes/__init__.py` | Solo `__version__`. Ningún módulo lo importa. |
| `environment.yml` (raíz) | Obsoleto desde RC70-D (Conda eliminado) |
| `$null` (archivo en raíz) | Sin uso aparente |
| `temp_analysis.txt` | Archivo temporal de análisis, debe eliminarse |

#### Funciones/Clases no utilizadas desde el exterior:

| Función | Archivo | Estatus |
|---------|---------|---------|
| `HermesWebPackageLoader` | `backend/main.py` | Solo usada por `HermesWebFinder` |
| `obtener_ruta_raiz_hermes()` | `backend/main.py` | Solo usada 1 vez internamente |
| `ejecutar_comando_hermes()` | `backend/main.py` | Definida pero NO llamada desde ningún router |
| `_simular_resultado()` | `servicio_datos_proyecto.py` | Solo usada internamente como fallback |

---

### 2.7 Logger Inicializado Antes del Finder (HALLAZGO #7)

En `backend/main.py`, línea 124:
```python
logger_init = logging.getLogger("Hermes.Web.setup")
logger_init.info(f"Finder registrado para Hermes.Web en: {_HERMES_WEB_DIR}")
```

Pero `logging.basicConfig()` no se llama hasta la línea 131. Esto significa que los primeros logs pueden no tener formato o destino configurado.

**Severidad:** BAJO

---

### 2.8 Imports Relativos vs Absolutos

| Archivo | Import | Tipo |
|---------|--------|------|
| `main.py` | `from Hermes.Web.middleware.middleware_correlation import ...` | Absoluto (por necesidad) |
| `api_version.py` | `from fastapi import ...` | Absoluto (paquete externo) |
| `servicio_datos_proyecto.py` | Solo imports stdlib + externos | Correcto |

**Análisis:** Todos los imports usan el formato absoluto `Hermes.Web.xxx` porque el MetaPathFinder lo requiere. No hay imports relativos en ningún archivo. Esto es consistente con la arquitectura actual.

**Severidad:** BAJO (es la arquitectura actual)

---

### 2.9 Importlib Hacks (HALLAZGO #8)

```python
self.exec_module(module):
    spec = importlib.util.spec_from_file_location(self.fullname, str(self.path))
    if spec and spec.loader:
        spec.loader.exec_module(module)
```

**Problema:** `HermesWebPackageLoader.exec_module()` crea un nuevo `spec` para delegar en otro loader. Esto es atípico y potencialmente frágil. La documentación de Python indica que `exec_module` debería ejecutar el módulo, no delegar.

**Severidad:** CRÍTICO (punto de falla en producción)

---

### 2.10 Dependencias Ocultas

| Dependencia | Dónde se usa | ¿En requirements.txt? |
|-------------|-------------|----------------------|
| `httpx` | Mencionado en mensaje de error (main.py:153) | ❌ No |
| `pytest` | Testing (no implementado) | ❌ No |

**Severidad:** BAJO (son dependencias de mensaje/error, no de ejecución)

---

### 2.11 Imports Circulares Potenciales

El análisis de dependencias muestra:

```
backend/main.py
  → middleware/middleware_correlation.py
  → middleware/middleware_logging.py
  → middleware/middleware_timing.py
  → middleware/middleware_auditoria.py
  → middleware/middleware_errores.py
  → middleware/middleware_compresion.py
  → backend/servicio_datos_proyecto.py
  → api/api_version.py
  → api/api_proyecto.py
  ... etc
```

No se detectan ciclos directos. Sin embargo, el MetaPathFinder introduce una dependencia invisible: cualquier import de `Hermes.Web.xxx` ejecuta código en `main.py` (el módulo donde está registrado el Finder). Si algún middleware importara `main.py`, se crearía un ciclo.

**Severidad:** MEDIO

---

### 2.12 Archivos con Código Mínimo (Stubs)

| Archivo | Líneas | Contenido | Evaluación |
|---------|--------|-----------|------------|
| `api/git.py` | 14 | Endpoint mínimo con datos mock | Stub |
| `api/workspace.py` | 20 | Endpoint que redirige a PowerShell | Stub |
| `api/proyecto.py` | 26 | Endpoint mínimo | Stub |
| `api/entorno.py` | 20 | Endpoint mínimo | Stub |
| `api/telemetria.py` | ? | Por revisar | Stub |
| `api/despliegue.py` | ? | Por revisar | Stub |
| `backend/__init__.py` | 1 | `from . import main` | Minimal |
| `middleware/__init__.py` | ? | Por revisar | - |

**Severidad:** BAJO (funcional, pero son stubs que deben implementarse)

---

## 3. FASE 2: CLASIFICACIÓN DE RIESGOS

### 3.1 CRÍTICOS

| # | Hallazgo | Riesgo | Impacto | Probabilidad | Complejidad |
|---|----------|--------|---------|-------------|-------------|
| H1 | MetaPathFinder frágil | Fallo en importaciones en producción | ALTO: App no inicia | MEDIA | ALTA |
| H2 | HermesWebPackageLoader delega exec | Comportamiento indefinido en CPython | ALTO: Crash en import | BAJA | ALTA |
| H3 | Sin tests Python | No hay cobertura de regresión | ALTO: Bug no detectado | ALTA | ALTA |
| H4 | Dependencia de subprocess para datos | Fallo si PowerShell no está disponible | ALTO: API sin datos | ALTA | MEDIA |

### 3.2 ALTOS

| # | Hallazgo | Riesgo | Impacto | Probabilidad | Complejidad |
|---|----------|--------|---------|-------------|-------------|
| H5 | 3 implementaciones subprocess | Inconsistencia, bugs duplicados | MEDIO | ALTA | BAJA |
| H6 | `sys.path.insert` global | Contaminación de namespace | MEDIO | MEDIA | BAJA |
| H7 | sys.executable en lugar de Hermes.Python.json | Usa intérprete incorrecto | ALTO | BAJA | MEDIA |
| H8 | backend/main.py ~570 líneas (God Object) | Mantenibilidad, testing difícil | ALTO | ALTA | ALTA |
| H9 | Sin pruebas Pester para cmdlets nuevos | ~80 cmdlets sin cobertura | ALTO | ALTA | ALTA |

### 3.3 MEDIOS

| # | Hallazgo | Riesgo | Impacto | Probabilidad | Complejidad |
|---|----------|--------|---------|-------------|-------------|
| H10 | Logger sin basicConfig antes de usar | Logs perdidos en startup | BAJO | MEDIA | BAJA |
| H11 | Imports circulares potenciales | Stack overflow en runtime | ALTO | BAJA | MEDIA |
| H12 | Stubs de API (git, workspace, etc.) | Funcionalidad incompleta | MEDIO | MEDIA | BAJA |
| H13 | Sin HTTPS configurado | Tráfico no cifrado | ALTO | BAJA | BAJA |
| H14 | requirements.txt sin clasificar | Dependencias mezcladas | BAJO | ALTA | BAJA |

### 3.4 BAJOS

| # | Hallazgo | Riesgo | Impacto | Probabilidad | Complejidad |
|---|----------|--------|---------|-------------|-------------|
| H15 | Código muerto (Hermes/__init__.py, $null) | Confusión, desorden | BAJO | MEDIA | MUY BAJA |
| H16 | temp_analysis.txt, environment.yml obsoletos | Archivos huérfanos | BAJO | ALTA | MUY BAJA |
| H17 | Docstring con ruta absoluta Windows | Engañoso en otros OS | BAJO | BAJA | MUY BAJA |
| H18 | Sin ruff/isort/bandit configurados | Calidad de código no enforceable | BAJO | ALTA | BAJA |

---

## 4. FASE 3: ESTUDIO Hermes.Web

### 4.1 Arquitectura Actual

```
Hermes.Web/                          ← Paquete importable gracias a MetaPathFinder
├── __init__.py                      ← Solo __version__
├── backend/
│   ├── __init__.py                  ← from . import main
│   └── main.py                      ← FastAPI app, MetaPathFinder, middleware, routers
│   └── servicio_datos_proyecto.py   ← Servicio de dominio (única capa de datos)
├── api/
│   ├── __init__.py                  ← Documentación de routers
│   ├── api_version.py               ← GET /api/version
│   ├── api_proyecto.py              ← GET /api/proyecto
│   ├── api_workspace.py             ← GET /api/workspace
│   ├── api_git.py                   ← GET /api/git
│   ├── api_github.py                ← GET /api/github
│   ├── api_entorno.py               ← GET /api/entorno
│   ├── api_bootstrap.py             ← GET /api/bootstrap
│   ├── api_telemetria.py            ← GET /api/telemetria
│   ├── api_azure.py                 ← GET /api/azure
│   ├── api_sqlite.py                ← GET /api/sqlite
│   └── api_despliegue.py            ← GET /api/despliegue
├── middleware/
│   ├── __init__.py                  ← ?
│   ├── middleware_correlation.py    ← CorrelationIdMiddleware
│   ├── middleware_logging.py        ← LoggingMiddleware
│   ├── middleware_timing.py         ← TimingMiddleware
│   ├── middleware_auditoria.py      ← AuditoriaMiddleware
│   ├── middleware_errores.py        ← ErrorHandlingMiddleware
│   └── middleware_compresion.py     ← CompressionMiddleware
├── templates/
│   └── index.html                   ← Portal web Bootstrap
├── static/                          ← Archivos estáticos (CSS, JS)
├── deployment/
│   ├── startup.sh                   ← Script de arranque Azure
│   └── startup.txt                  ← Documentación startup
└── requirements.txt                 ← Dependencias
```

### 4.2 Mecanismo de Importación Actual

Python NO puede importar `Hermes.Web` como un subpaquete de `Hermes` porque:

1. El directorio se llama `Hermes.Web` (contiene un punto).
2. Python interpreta el punto como separador de paquetes.
3. No existe `Hermes/__init__.py` que referencie `Hermes.Web`.

**Solución actual (en main.py):**
1. Agregar `_PROJECT_ROOT` a `sys.path` para que `Hermes.Web` sea detectable como paquete de nivel superior.
2. Registrar `HermesWebFinder` en `sys.meta_path` que intercepta imports `Hermes.Web.xxx` y resuelve a `./Hermes.Web/xxx/yyy.py`.

### 4.3 Alternativa: Migrar a `Hermes/Web/`

| Aspecto | Hermes.Web/ (actual) | Hermes/Web/ (propuesta) |
|---------|---------------------|------------------------|
| **Import** | `Hermes.Web.xxx.yyy` | `Hermes.Web.xxx.yyy` (IDÉNTICO) |
| **Finder necesario** | ✅ Sí (MetaPathFinder) | ❌ No (Python estándar) |
| **sys.path hack** | ❌ Sí (sys.path.insert) | ✅ No |
| **Complejidad** | ALTA | BAJA |
| **Compatibilidad RC69** | ✅ Mantiene | ⚠️ Cambia estructura de directorios |
| **Riesgo** | Medio (fragilidad Finder) | Alto (reorganización física) |
| **Azure App Service** | ⚠️ Funciona | ✅ Funciona mejor |
| **Costo migración** | 0 (actual) | 2-3 días |
| **Pruebas necesarias** | 0 | ~50 tests de regresión |

**RECOMENDACIÓN:** Mantener `Hermes.Web/` con MetaPathFinder para RC71. Migrar a `Hermes/Web/` en RC72 cuando haya:
- Suite completa de tests Python
- CI/CD pipeline validando cada release
- Plan de reversión documentado

### 4.4 Justificación Técnica de Mantener MetaPathFinder

La decisión de mantener el Finder personalizado en RC71 se basa en:

1. **El punto en el nombre del directorio** (`Hermes.Web`) es incompatible con el sistema de importación estándar de Python.
2. **Renombrar el directorio** requeriría modificar todos los imports, archivos de despliegue, y scripts de Azure.
3. **El Finder está funcional y probado** desde RC69.
4. **No hay reportes de fallos** en el Finder desde su implementación.
5. **El riesgo de refactorización** supera el riesgo de mantenerlo.

**Conclusión:** Mantener. Documentar como deuda técnica para RC72.

---

## 5. FASE 4: PYTHON PACKAGING (pyproject.toml)

### 5.1 Estado Actual

- `requirements.txt` (raíz): dependencias genéricas
- `Hermes.Web/requirements.txt`: dependencias específicas de la web

### 5.2 Análisis de Migración a pyproject.toml

| Aspecto | requirements.txt | pyproject.toml |
|---------|-----------------|----------------|
| **Estándar** | PEP 508 | PEP 517/518/621 |
| **Editable install** | ❌ No | ✅ `pip install -e .` |
| **Metadatos** | ❌ No | ✅ Versión, author, license |
| **Entry points** | ❌ No | ✅ CLI scripts |
| **Build system** | ❌ No | ✅ setuptools, flit, hatch |
| **Optional deps** | ❌ manual | ✅ `[dev]`, `[test]`, `[azure]` |
| **Tool config** | ❌ No | ✅ ruff, mypy, pytest config |
| **Compatibilidad** | ✅ Universal | ✅ Universal (PEP 660) |
| **Azure App Service** | ✅ pip install -r | ✅ pip install . |
| **Complejidad** | BAJA | MEDIA |

### 5.3 Recomendación

**Migrar a pyproject.toml en RC72.** El beneficio es alto (instalación editable, metadatos, dependencias opcionales). No hay riesgo de compatibilidad porque `pip install -r requirements.txt` seguirá funcionando como alternativa.

**No implementar en RC71** porque:
- RC71 es solo auditoría.
- requirements.txt actual es funcional.
- pyproject.toml requiere probar con Azure App Service.

---

## 6. FASE 5: CLASIFICACIÓN DE DEPENDENCIAS

### 6.1 Estado Actual

**requirements.txt (raíz):**
```
fastapi==0.115.6
uvicorn[standard]==0.34.0
jinja2==3.1.5
pydantic==2.10.4
httpx==0.28.1
aiofiles==24.1.0
python-multipart==0.0.20
pydantic-settings==2.7.1
gunicorn==23.0.0
```

**Hermes.Web/requirements.txt:**
```
fastapi==0.115.6
uvicorn==0.34.0
jinja2==3.1.5
pydantic==2.10.4
httpx==0.28.1
aiofiles==24.1.0
python-multipart==0.0.20
pydantic-settings==2.7.1
gunicorn==23.0.0
```

### 6.2 Análisis de Uso Real

| Paquete | ¿Se importa? | ¿Dónde? | Clasificación |
|---------|-------------|---------|---------------|
| `fastapi` | ✅ Sí | main.py, todos los api_*.py | **Runtime** |
| `uvicorn` | ✅ Sí | main.py (línea 555) | **Runtime** |
| `jinja2` | ✅ Sí | main.py (línea 147, 291) | **Runtime** |
| `pydantic` | ✅ Sí | main.py (línea 149) | **Runtime** |
| `httpx` | ❌ No importado | Solo mencionado en error msg | **Innecesario** |
| `aiofiles` | ❌ No importado | En requirements pero no en código | **Innecesario** |
| `python-multipart` | ❌ No importado | No usado actualmente | **Innecesario** |
| `pydantic-settings` | ❌ No importado | No usado actualmente | **Innecesario** |
| `gunicorn` | ❌ No importado | No usado (uvicorn en su lugar) | **Innecesario** |

### 6.3 Dependencias Faltantes Detectadas

| Paquete | ¿Dónde se usa? | ¿Está en requirements? |
|---------|---------------|----------------------|
| `importlib` (stdlib) | main.py (línea 23) | ✅ No requiere (stdlib) |
| `subprocess` (stdlib) | main.py, servicio_datos_proyecto.py | ✅ No requiere (stdlib) |
| `pathlib` (stdlib) | Todos los archivos | ✅ No requiere (stdlib) |
| `logging` (stdlib) | Todos los archivos | ✅ No requiere (stdlib) |
| `platform` (stdlib) | main.py, api_version.py, api_entorno.py | ✅ No requiere (stdlib) |

### 6.4 Propuesta de requirements_clasificados

**requirements-runtime.txt** (mínimo necesario):
```
fastapi==0.115.6
uvicorn[standard]==0.34.0
jinja2==3.1.5
pydantic==2.10.4
```

**requirements-dev.txt** (desarrollo):
```
pytest>=8.0
pytest-cov>=5.0
ruff>=0.8.0
black>=24.0
isort>=5.0
mypy>=1.0
```

**requirements-azure.txt** (despliegue Azure):
```
gunicorn==23.0.0  # Solo si se usa WSGI, no ASGI
```

**requirements-test.txt** (testing):
```
httpx==0.28.1
pytest>=8.0
```

---

## 7. FASE 6: CALIDAD Y HERRAMIENTAS

### 7.1 Configuración Propuesta

| Herramienta | Propósito | Estado Actual | Acción |
|------------|-----------|---------------|--------|
| **ruff** | Linter ultra-rápido (reemplaza flake8) | ❌ No configurado | Agregar pyproject.toml config |
| **black** | Formateador automático | ❌ No configurado | Agregar a dev deps |
| **isort** | Ordenador de imports | ❌ No configurado | Agregar a dev deps |
| **mypy** | Type checker estático | ❌ No configurado | Agregar a dev deps |
| **bandit** | Seguridad en código | ❌ No configurado | Agregar a dev deps |
| **pip-audit** | Auditoría de dependencias | ❌ No configurado | Agregar a dev deps |

### 7.2 Configuración Recomendada (para RC72)

```toml
# pyproject.toml (futuro)
[tool.ruff]
target-version = "py314"
line-length = 100
select = ["E", "F", "I", "N", "W", "UP"]
ignore = ["E501"]

[tool.black]
line-length = 100
target-version = ["py314"]

[tool.isort]
profile = "black"
line-length = 100

[tool.mypy]
python_version = "3.14"
strict = true
```

---

## 8. FASE 7: TESTING

### 8.1 Estado Actual

| Tipo | Archivos | Estado |
|------|---------|--------|
| **Pester (PowerShell)** | `pruebas/unitarias/Hermes.Installer.RC63.Tests.ps1` | ✅ 9 pruebas |
| **Pester (PowerShell)** | `pruebas/unitarias/Hermes.Commands.RC63.Tests.ps1` | ✅ 76 pruebas |
| **Python (pytest)** | ❌ Ninguno | ❌ No existen |
| **Cobertura** | ❌ No configurada | ❌ No existen reports |

### 8.2 Análisis de Tests Pester Existentes

**Hermes.Commands.RC63.Tests.ps1 (76 pruebas):**
- Cubre cmdlets principales: Get/Set-HermesConfiguration, New/Get-HermesProject, etc.
- No cubre cmdlets nuevos de RC70: Azure, Bootstrap, Environment
- Mocking: Usa Pester Mock

**Hermes.Installer.RC63.Tests.ps1 (9 pruebas):**
- Cubre instalación básica
- No cubre nuevo Runtime Python (RC70-D)

### 8.3 Tests Rotos u Obsoletos

No se detectaron tests rotos porque no hay tests Python. Los tests Pester existentes son funcionales para RC63 pero no cubren funcionalidad de RC70+.

### 8.4 Propuesta de Testing para RC72

```
pruebas/
├── python/
│   ├── test_main.py              ← Tests de backend/main.py
│   ├── test_api_version.py       ← Tests de API
│   ├── test_middleware.py        ← Tests de middleware
│   ├── test_servicio_datos.py    ← Tests de servicios
│   └── conftest.py               ← Fixtures comunes
├── unitarias/
│   ├── Hermes.Commands.RC63.Tests.ps1    ← Actualizar
│   ├── Hermes.Installer.RC63.Tests.ps1   ← Actualizar
│   ├── Hermes.Python.RC71.Tests.ps1      ← NUEVO: Runtime Python
│   ├── Hermes.Azure.RC71.Tests.ps1       ← NUEVO: Azure
│   └── Hermes.Bootstrap.RC71.Tests.ps1   ← NUEVO: Bootstrap
└── integracion/
    └── test_integracion_python_ps.ps1    ← NUEVO: Python+PowerShell
```

---

## 9. FASE 8: POWERSHELL

### 9.1 Visión General

El módulo PowerShell `Hermes.Commands` contiene:
- ~80+ cmdlets públicos
- Providers para Azure, SQLite, etc.
- Use cases para Azure
- Bootstrap engine
- Scripts de instalación

### 9.2 Hallazgos PowerShell

| # | Hallazgo | Severidad | Detalle |
|---|----------|-----------|---------|
| PS1 | Verbos no estándar | MEDIO | `New-HermesDistribution` usa `New` pero la action no es crear un objeto estándar |
| PS2 | Sin PSScriptAnalyzer | BAJO | No hay configuración `.psd1` para analyzer rules |
| PS3 | Sin ayuda extensible | BAJO | Cmdlets sin `.DESCRIPTION` o `.PARAMETER` completa |
| PS4 | Manifests sin actualizar | MEDIO | `Hermes.Commands.psd1` puede no incluir todos los cmdlets nuevos |
| PS5 | Sin tests para ~40 cmdlets | ALTO | Solo 76 tests para ~80 cmdlets |
| PS6 | Sin compatibilidad PS7 verificada | MEDIO | Algunos cmdlets pueden depender de Windows-only features |

### 9.3 Get-Verb Compliance

Verbos utilizados actualmente:
- `Get-` ✅ (Get-HermesVersion, Get-HermesConfiguration, etc.)
- `Set-` ✅ (Set-HermesConfiguration)
- `New-` ✅ (New-HermesProject, New-HermesEnvironment)
- `Remove-` ✅ (Remove-HermesEnvironment)
- `Update-` ✅ (Update-HermesProject)
- `Enter-` ✅ (Enter-HermesEnvironment)
- `Close-` ✅ (Close-HermesWorkspace)
- `Open-` ✅ (Open-HermesWorkspace)
- `Import-` ✅ (Import-HermesProject)
- `Export-` ✅ (Export-HermesProject)
- `Rename-` ✅ (Rename-HermesProject)
- `Repair-` ✅ (Repair-HermesInstallation)
- `Publish-` ✅ (Publish-HermesProject)
- `Clone-` ✅ (Clone-HermesProject)
- `Resolve-` ✅ (Resolve-HermesAppServicePlanId)
- `Uninstall-` ✅ (Uninstall-Hermes)

Todos los verbos son aprobados por `Get-Verb`.

---

## 10. FASE 9: AZURE

### 10.1 Estado Actual

| Componente | Estado | Archivos |
|------------|--------|----------|
| App Service Plan | Configurado | `AzureAppServicePlanProvider.ps1` |
| Storage Account | Configurado | `AzureStorageProvider.ps1` |
| Application Insights | Configurado | `AzureApplicationInsightsProvider.ps1` |
| Log Analytics | Configurado | `AzureLogAnalyticsProvider.ps1` |
| Key Vault | Configurado | `AzureKeyVaultProvider.ps1` |
| Managed Identity | Configurado | `AzureManagedIdentityProvider.ps1` |
| **startup.sh** | ✅ Actualizado para python -m | `Hermes.Web/deployment/startup.sh` |
| **startup.txt** | Documentación | `Hermes.Web/deployment/startup.txt` |

### 10.2 Análisis de startup.sh

```bash
#!/bin/bash
# startup.sh — Azure App Service startup script
pip install -r requirements.txt
python -m uvicorn Hermes.Web.backend.main:app --host 0.0.0.0 --port 8000
```

**✅ Correcto:** Usa `python -m uvicorn` en lugar de `uvicorn` directo. Usa `pip install -r` desde el entorno del App Service.

**⚠️ Observaciones:**
- No hay validación de que `python` sea el del Runtime oficial.
- No hay health check después del startup.
- No hay logging estructurado de inicio.

### 10.3 Configuración de Variables de Entorno

Variables propuestas para Azure App Service:

| Variable | Valor | Propósito |
|----------|-------|-----------|
| `HERMES_WEB_HOST` | `0.0.0.0` | Host de uvicorn |
| `HERMES_WEB_PORT` | `8000` | Puerto de uvicorn |
| `HERMES_WEB_LOG_LEVEL` | `info` | Nivel de logging |
| `HERMES_PYTHON_RUNTIME` | `/home/HermesRuntime/Environments/HermesEnterprise` | Ruta Runtime en Azure |
| `PYTHONPATH` | `/home/site/wwwroot` | Para encontrar Hermes.Web |

---

## 11. FASE 10: CI/CD

### 11.1 Diseño Propuesto para GitHub Actions

```yaml
name: RC72-CI-CD

on:
  push:
    branches: [main, develop, rc/*]
  pull_request:
    branches: [main]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.14"
      - name: Install dependencies
        run: |
          pip install -r Hermes.Web/requirements.txt
          pip install ruff black isort mypy bandit pip-audit
      - name: Lint
        run: ruff check Hermes.Web/
      - name: Format check
        run: black --check Hermes.Web/
      - name: Import order
        run: isort --check Hermes.Web/
      - name: Security audit
        run: bandit -r Hermes.Web/
      - name: Dependency audit
        run: pip-audit

  test-python:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.14"
      - name: Install
        run: pip install -r Hermes.Web/requirements.txt -r requirements-test.txt
      - name: Run tests
        run: pytest pruebas/python/ --cov=Hermes.Web --cov-report=xml
      - name: Upload coverage
        uses: codecov/codecov-action@v4

  test-powershell:
    needs: quality
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Pester tests
        shell: pwsh
        run: |
          Install-Module Pester -Force
          Invoke-Pester pruebas/unitarias/ -Output Detailed

  build:
    needs: [test-python, test-powershell]
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Package
        run: |
          mkdir -p dist
          tar -czf dist/hermes-enterprise.tar.gz \
            Hermes.Web/ config/Hermes.Python.json requirements.txt
      - uses: actions/upload-artifact@v4
        with:
          name: hermes-enterprise-build
          path: dist/

  deploy-azure:
    needs: build
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: azure/login@v2
        with:
          creds: ${{ secrets.AZURE_CREDENTIALS }}
      - name: Deploy to App Service
        uses: azure/webapps-deploy@v3
        with:
          app-name: hermes-enterprise
          package: Hermes.Web/
      - name: Smoke test
        run: |
          sleep 30
          curl -f http://hermes-enterprise.azurewebsites.net/health
```

### 11.2 Quality Gates Propuestos

| Gate | Umbral | Acción |
|------|--------|--------|
| Cobertura Python | ≥ 80% | ❌ Bloquea PR |
| Ruff errors | 0 | ❌ Bloquea PR |
| Black check | Pass | ❌ Bloquea PR |
| Pester tests | 100% pass | ❌ Bloquea PR |
| pip-audit | 0 high vulns | ⚠️ Warning |
| Bandit | 0 high severity | ❌ Bloquea PR |

---

## 12. FASE 11: DOCUMENTACIÓN

### 12.1 Estado Actual

| Documento | Estado | Acción RC71 |
|-----------|--------|------------|
| `README.md` | ✅ Actualizado RC70-D | ✅ OK |
| `CURRENT_STATE.md` | ✅ Actualizado RC70-D | ✅ OK |
| `CHANGELOG.md` | ✅ Actualizado RC70-D | Agregar entrada RC71 |
| `docs/ArchitectureState.md` | ✅ Actualizado RC70-D | Agregar sección deuda técnica |
| `docs/TechnicalDebt.md` | ❌ No existe | **NUEVO** (este documento) |
| `docs/MigrationPlan_RC72.md` | ❌ No existe | **NUEVO** |
| `docs/DeveloperGuide.md` | ⚠️ Desactualizado | Revisar para RC72 |

### 12.2 Documentos a Crear en RC71

1. **`docs/TechnicalDebt_RC71.md`** ← Este documento (creado)
2. **`docs/MigrationPlan_RC72.md`** ← Pendiente para después de la auditoría

---

## 13. PROPUESTA RC72

### 13.1 Resumen de Migración Propuesta

| Componente | Cambio | Esfuerzo | Riesgo |
|-----------|--------|----------|--------|
| `Hermes.Web/` → `Hermes/Web/` | Mover directorio | 2-3 días | ALTO |
| MetaPathFinder → imports estándar | Eliminar Finder | 1 día | MEDIO |
| pyproject.toml | Migrar packaging | 1 día | BAJO |
| Tests Python | Crear suite pytest | 3-5 días | BAJO |
| Tests Pester | Actualizar + nuevos | 2-3 días | BAJO |
| CI/CD | Pipeline completa | 2-3 días | BAJO |
| Azure startup | Mejorar script | 0.5 día | BAJO |
| Refactor subprocess | Unificar | 1 día | BAJO |
| Eliminar dependencias innecesarias | Actualizar requirements | 0.5 día | BAJO |
| Configurar ruff/black/isort/mypy | 1 día | BAJO |
| Documentación | Actualizar | 1-2 días | BAJO |

**Total estimado RC72:** 15-22 días hombre

### 13.2 Plan de Reversión (RC72)

Si la migración a `Hermes/Web/` falla:

1. Revertir `git revert` del commit de migración.
2. Restaurar `Hermes.Web/__init__.py` original.
3. Restaurar `HermesWebFinder` en `backend/main.py`.
4. Los tests de regresión deben pasar antes/después.

---

## 14. BACKLOG PRIORIZADO

### Prioridad CRÍTICA (RC71-B)

| # | Tarea | Archivos | Justificación |
|---|-------|----------|--------------|
| 1 | Agregar tests Python para backend | Nuevos | Sin tests no hay confianza en refactor |
| 2 | Agregar tests Pester para Runtime | `pruebas/unitarias/Hermes.Python.RC71.Tests.ps1` | Validar Runtime |
| 3 | Unificar ejecución subprocess | `servicio_datos_proyecto.py`, `main.py` | Reducir duplicación |
| 4 | Validar Hermes.Python.json en startup.sh | `Hermes.Web/deployment/startup.sh` | Despliegue Azure |

### Prioridad ALTA (RC71-C)

| # | Tarea | Archivos | Justificación |
|---|-------|----------|--------------|
| 5 | Eliminar archivos obsoletos | `$null`, `temp_analysis.txt`, `environment.yml` | Limpieza |
| 6 | Verificar imports en todos los módulos | Todos los .py | Prevenir roturas |
| 7 | Agregar HTTPS config | `main.py` | Seguridad |
| 8 | Configurar ruff básico | `pyproject.toml` (o `.ruff.toml`) | Calidad |

### Prioridad MEDIA (RC72-A)

| # | Tarea | Archivos | Justificación |
|---|-------|----------|--------------|
| 9 | Migrar a pyproject.toml | Nuevo archivo | Packaging moderno |
| 10 | Clasificar requirements | requirements-*.txt | Mantenibilidad |
| 11 | Configurar mypy | pyproject.toml | Type safety |
| 12 | Pipeline CI/CD | `.github/workflows/` | Automatización |

### Prioridad BAJA (RC72-B)

| # | Tarea | Archivos | Justificación |
|---|-------|----------|--------------|
| 13 | Migrar Hermes.Web/ a Hermes/Web/ | Reestructuración | Eliminar Finder |
| 14 | Eliminar MetaPathFinder | `main.py` | Simplificación |
| 15 | Actualizar DeveloperGuide | `docs/DeveloperGuide.md` | Documentación |
| 16 | Agregar diagrama arquitectura | `docs/architecture/` | Documentación |

---

## 15. ESTIMACIÓN DE ESFUERZO

### 15.1 Por Prioridad

| Prioridad | Días | Personas | Costo estimado |
|-----------|------|----------|---------------|
| CRÍTICA | 5-7 | 1 | $500-$700 |
| ALTA | 3-5 | 1 | $300-$500 |
| MEDIA | 5-8 | 1 | $500-$800 |
| BAJA | 8-12 | 1 | $800-$1200 |
| **TOTAL** | **21-32** | **1** | **$2100-$3200** |

### 15.2 Por Fase

| Fase | Días | Dependencias |
|------|------|-------------|
| RC71-B (Hardening inmediato) | 5-7 | Ninguna |
| RC71-C (Calidad) | 3-5 | RC71-B |
| RC72-A (Packaging + CI/CD) | 5-8 | RC71-C |
| RC72-B (Reestructuración) | 8-12 | RC72-A |
| **TOTAL** | **21-32** | - |

---

## ANEXO A: Mapa Completo de Imports

### Hermes.Web/backend/main.py
```
stdlib:
  os, sys, json, uuid, time, logging, subprocess, platform
  importlib.util, importlib.abc, importlib.machinery
  datetime, pathlib, typing

externos:
  fastapi → FastAPI, Request, Response, HTTPException, Depends
  fastapi.responses → JSONResponse, HTMLResponse
  fastapi.staticfiles → StaticFiles
  fastapi.templating → Jinja2Templates
  fastapi.middleware.cors → CORSMiddleware
  fastapi.middleware.gzip → GZipMiddleware
  pydantic → BaseModel, Field

internos (Hermes.Web):
  Hermes.Web.middleware.middleware_correlation → CorrelationIdMiddleware
  Hermes.Web.middleware.middleware_logging → LoggingMiddleware
  Hermes.Web.middleware.middleware_timing → TimingMiddleware
  Hermes.Web.middleware.middleware_auditoria → AuditoriaMiddleware
  Hermes.Web.middleware.middleware_errores → ErrorHandlingMiddleware
  Hermes.Web.middleware.middleware_compresion → CompressionMiddleware
  Hermes.Web.backend.servicio_datos_proyecto → ServicioDatosProyecto
  Hermes.Web.api.api_version → router
  Hermes.Web.api.api_proyecto → router
  Hermes.Web.api.api_workspace → router
  Hermes.Web.api.api_git → router
  Hermes.Web.api.api_github → router
  Hermes.Web.api.api_entorno → router
  Hermes.Web.api.api_bootstrap → router
  Hermes.Web.api.api_telemetria → router
  Hermes.Web.api.api_azure → router
  Hermes.Web.api.api_sqlite → router
  Hermes.Web.api.api_despliegue → router
```

### Hermes.Web/backend/servicio_datos_proyecto.py
```
stdlib: os, sys, json, time, logging, subprocess, platform, datetime, pathlib, typing
internos: Ninguno (no importa Hermes.Web)
```

### Hermes.Web/api/api_*.py
```
Todos importan: logging, fastapi → APIRouter, Request
Algunos importan: platform, subprocess, datetime, pathlib
Ninguno importa otro módulo de Hermes.Web
```

---

## ANEXO B: Archivos a Crear/Eliminar

### Archivos a CREAR

| Archivo | Propósito | Prioridad |
|---------|-----------|-----------|
| `docs/TechnicalDebt_RC71.md` | Este informe | ✅ CREADO |
| `docs/MigrationPlan_RC72.md` | Plan de migración a RC72 | ALTA |
| `pruebas/unitarias/Hermes.Python.RC71.Tests.ps1` | Tests Runtime Python | CRÍTICA |
| `pruebas/unitarias/Hermes.Azure.RC71.Tests.ps1` | Tests Azure | MEDIA |
| `pruebas/python/conftest.py` | Fixtures pytest | CRÍTICA |
| `pruebas/python/test_main.py` | Tests de main.py | CRÍTICA |
| `pruebas/python/test_api.py` | Tests de API | ALTA |
| `.github/workflows/ci.yml` | CI pipeline | MEDIA |
| `.github/workflows/cd.yml` | CD pipeline | MEDIA |
| `docs/architecture/runtime-architecture.md` | Diagrama arquitectura | BAJA |

### Archivos a ELIMINAR

| Archivo | Razón | Prioridad |
|---------|-------|-----------|
| `$null` | Archivo sin propósito | BAJA |
| `temp_analysis.txt` | Archivo temporal | BAJA |
| `environment.yml` (raíz) | Obsoleto desde RC70-D | BAJA |

### Archivos a MODIFICAR

| Archivo | Cambio | Prioridad |
|---------|--------|-----------|
| `Hermes.Web/backend/main.py` | Refactor: extraer Finder a módulo separado | CRÍTICA |
| `Hermes.Web/backend/main.py` | Refactor: unificar subprocess | ALTA |
| `Hermes.Web/backend/servicio_datos_proyecto.py` | Usar Hermes.Python.json | ALTA |
| `Hermes.Web/deployment/startup.sh` | Validar Runtime en startup | ALTA |
| `Hermes.Web/requirements.txt` | Limpiar dependencias innecesarias | ALTA |
| `CHANGELOG.md` | Agregar entrada RC71 | ✅ |
| `docs/ArchitectureState.md` | Agregar sección deuda técnica | MEDIA |

---

*Fin del informe RC71-A — Technical Debt Audit*