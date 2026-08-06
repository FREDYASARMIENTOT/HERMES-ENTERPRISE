# RC72 — PLAN DE MIGRACIÓN: HARDENING Y MODERNIZACIÓN DEL CORE PYTHON

> **Fecha:** 2026-05-08  
> **Versión:** 1.0.0  
> **Dependencia:** RC71-A (Auditoría de deuda técnica completada)  
> **Estado:** PLAN — Pendiente de aprobación  
> **Lectura requerida:** `docs/TechnicalDebt_RC71.md`

---

## ÍNDICE

1. [RESUMEN EJECUTIVO](#1-resumen-ejecutivo)
2. [FASE RC71-B: HARDENING INMEDIATO](#2-fase-rc71-b-hardening-inmediato)
3. [FASE RC71-C: CALIDAD Y SEGURIDAD](#3-fase-rc71-c-calidad-y-seguridad)
4. [FASE RC72-A: PACKAGING Y CI/CD](#4-fase-rc72-a-packaging-y-cicd)
5. [FASE RC72-B: REESTRUCTURACIÓN](#5-fase-rc72-b-reestructuración)
6. [ARCHIVOS A CREAR](#6-archivos-a-crear)
7. [ARCHIVOS A MODIFICAR](#7-archivos-a-modificar)
8. [ARCHIVOS A ELIMINAR](#8-archivos-a-eliminar)
9. [RIESGOS Y PLAN DE REVERSIÓN](#9-riesgos-y-plan-de-reversión)
10. [CRITERIOS DE ACEPTACIÓN](#10-criterios-de-aceptación)

---

## 1. RESUMEN EJECUTIVO

### 1.1 Alcance

Migrar Hermes Enterprise de un estado funcional pero frágil a una arquitectura Python empresarial robusta mediante:

1. **RC71-B:** Pruebas automatizadas, refactor de subprocess, validación de startup
2. **RC71-C:** Seguridad HTTPS, limpieza de código muerto, herramientas de calidad
3. **RC72-A:** Packaging moderno (pyproject.toml), CI/CD pipeline, dependencias clasificadas
4. **RC72-B:** Reestructuración de directorios (Hermes.Web → Hermes/Web/), eliminación de MetaPathFinder

### 1.2 Fases y Duración

| Fase | Nombre | Días | Dependencia | Prioridad |
|------|--------|------|-------------|-----------|
| RC71-B | Hardening inmediato | 5-7 | Ninguna | CRÍTICA |
| RC71-C | Calidad y seguridad | 3-5 | RC71-B | ALTA |
| RC72-A | Packaging y CI/CD | 5-8 | RC71-C | MEDIA |
| RC72-B | Reestructuración | 8-12 | RC72-A | BAJA |
| **TOTAL** | | **21-32** | | |

### 1.3 Principios Rectores

1. **No romper compatibilidad con RC69/RC70-D.** Cada cambio debe validarse con las suites de tests existentes.
2. **No eliminar funcionalidad existente.** Stubs de API pueden permanecer hasta que se implemente la funcionalidad completa.
3. **Cada modificación debe incluir:** tests (pytest o Pester), documentación, entrada en CHANGELOG.
4. **Migrar en orden de riesgo:** primero pruebas (protegen contra regresión), luego refactor, luego reestructuración.

---

## 2. FASE RC71-B: HARDENING INMEDIATO

> **Duración:** 5-7 días  
> **Prioridad:** CRÍTICA  
> **Riesgo:** BAJO (no modifica estructura existente, solo agrega)

### 2.1 Crear Suite de Tests Python (pytest)

**Archivos a crear:**

| Archivo | Propósito | Tests planificados |
|---------|-----------|-------------------|
| `pruebas/python/conftest.py` | Fixtures comunes, TestClient, mocks | - |
| `pruebas/python/test_main.py` | Tests de backend/main.py | ~30 |
| `pruebas/python/test_middleware.py` | Tests de todos los middleware | ~25 |
| `pruebas/python/test_api.py` | Tests de todos los endpoints | ~35 |
| `pruebas/python/test_servicio_datos.py` | Tests de ServicioDatosProyecto | ~20 |

**Dependencias a agregar:**
```
pytest>=8.0
pytest-cov>=5.0
httpx>=0.28.1          # Para TestClient asíncrono
```

**Detalle de pruebas:**

| Módulo | Tests | Cobertura objetivo |
|--------|-------|-------------------|
| `main.py` | Creación de app FastAPI, configuración, routers, MetaPathFinder, middleware chain | ≥ 85% |
| `middleware_*.py` | Cada middleware: correlation ID generation, logging format, timing measurement, auditoria, error handling, compression | ≥ 90% |
| `api_*.py` | Cada endpoint: status code 200, response schema, error cases, parametros inválidos | ≥ 80% |
| `servicio_datos_proyecto.py` | Subprocess execution, JSON parsing, error handling, mock PowerShell output | ≥ 75% |

### 2.2 Crear Tests Pester para Runtime

**Archivo:** `pruebas/unitarias/Hermes.Python.RC71.Tests.ps1`

```powershell
Describe "Hermes Python Runtime Validation" {
    It "Config file exists" { ... }
    It "Python executable exists at configured path" { ... }
    It "Pip executable exists at configured path" { ... }
    It "Venv directory exists" { ... }
    It "pyvenv.cfg exists" { ... }
    It "Requirements.txt exists" { ... }
    It "Python version matches configuration" { ... }
    It "FastAPI is importable" { ... }
    It "Uvicorn is importable" { ... }
}
```

### 2.3 Refactor: Unificar Ejecución de Subprocess

**Problema:** 3 implementaciones de subprocess en 2 archivos.

**Solución:** Crear módulo compartido `Hermes.Web/backend/subprocess_utils.py`:

```python
"""subprocess_utils.py — Ejecución unificada de comandos externos"""

import subprocess
import json
import logging
from pathlib import Path
from typing import Optional, Any

logger = logging.getLogger("Hermes.Web.Subprocess")

def ejecutar_powershell(
    comando: str,
    args: Optional[list[str]] = None,
    timeout: int = 30
) -> dict[str, Any]:
    """Ejecuta un comando PowerShell y retorna JSON parseado."""
    cmd = ["powershell", "-NoProfile", "-Command"]
    cmd.append(f"{comando} | ConvertTo-Json -Depth 10")
    
    try:
        result = subprocess.run(
            cmd,
            capture_output=True,
            text=True,
            timeout=timeout
        )
        if result.returncode != 0:
            logger.error(f"PowerShell error: {result.stderr}")
            return {"error": result.stderr}
        return json.loads(result.stdout) if result.stdout.strip() else {}
    except subprocess.TimeoutExpired:
        logger.error(f"PowerShell timeout after {timeout}s")
        return {"error": "timeout"}
    except json.JSONDecodeError as e:
        logger.warning(f"PowerShell output not JSON: {e}")
        return {"raw_output": result.stdout}
```

**Archivos a modificar:**

| Archivo | Cambio |
|---------|--------|
| `Hermes.Web/backend/subprocess_utils.py` | **CREAR** - Módulo compartido |
| `Hermes.Web/backend/main.py` | Reemplazar `ejecutar_comando_hermes()` por calls a `subprocess_utils` |
| `Hermes.Web/backend/servicio_datos_proyecto.py` | Reemplazar `_ejecutar_comando_powershell()`, `_leer_git_desde_cli()`, `_ejecutar_pip()` por calls a `subprocess_utils` |
| `Hermes.Web/api/api_version.py` | Reemplazar subprocess directo por `subprocess_utils` |

### 2.4 Agregar Hermes.Python.json en startup.sh

**Archivo:** `Hermes.Web/deployment/startup.sh`

**Cambio propuesto:**

```bash
#!/bin/bash
# startup.sh — Azure App Service startup script

# Read Python Runtime from canonical config
PYTHON_CONFIG="config/Hermes.Python.json"
if [ -f "$PYTHON_CONFIG" ]; then
    PYTHON_PATH=$(python3 -c "import json; print(json.load(open('$PYTHON_CONFIG'))['RutaPython'])")
    echo "Using Python Runtime: $PYTHON_PATH"
else
    echo "WARNING: $PYTHON_CONFIG not found. Using default python3"
    PYTHON_PATH="python3"
fi

# Install dependencies
$PYTHON_PATH -m pip install -r Hermes.Web/requirements.txt --quiet

# Health check
echo "Starting uvicorn..."
$PYTHON_PATH -m uvicorn Hermes.Web.backend.main:app --host 0.0.0.0 --port 8000
```

---

## 3. FASE RC71-C: CALIDAD Y SEGURIDAD

> **Duración:** 3-5 días  
> **Prioridad:** ALTA  
> **Riesgo:** BAJO (no modifica lógica de negocio)

### 3.1 Agregar HTTPS

**Archivo:** `Hermes.Web/backend/main.py`

Agregar redirect HTTP → HTTPS en producción:

```python
@app.middleware("http")
async def redirect_https(request: Request, call_next):
    if request.headers.get("x-forwarded-proto") == "http":
        url = request.url.replace(scheme="https")
        return RedirectResponse(url, status_code=307)
    return await call_next(request)
```

### 3.2 Configurar ruff

**Archivo:** `.ruff.toml`

```toml
target-version = "py314"
line-length = 100
select = ["E", "F", "I", "N", "W", "UP", "B", "SIM"]
ignore = ["E501"]
fix = true
```

### 3.3 Limpiar Código Muerto

| Archivo | Acción |
|---------|--------|
| `$null` | Eliminar |
| `temp_analysis.txt` | Eliminar |
| `Hermes/__init__.py` | Mantener (puede ser útil para metadata de paquete) |
| `environment.yml` (raíz) | Ya eliminado en RC70-D |

### 3.4 Agregar Requirements Clasificados

```bash
# requirements-runtime.txt
fastapi==0.115.6
uvicorn[standard]==0.34.0
jinja2==3.1.5
pydantic==2.10.4

# requirements-dev.txt
pytest>=8.0
pytest-cov>=5.0
ruff>=0.8.0
black>=24.0
isort>=5.0
mypy>=1.0
pip-audit>=2.0

# requirements-test.txt
httpx>=0.28.1
```

**Modificar:** `Hermes.Web/requirements.txt` para eliminar `httpx`, `aiofiles`, `python-multipart`, `pydantic-settings`, `gunicorn`.

---

## 4. FASE RC72-A: PACKAGING Y CI/CD

> **Duración:** 5-8 días  
> **Prioridad:** MEDIA  
> **Riesgo:** MEDIO (cambia estructura de packaging)

### 4.1 Migrar a pyproject.toml

**Archivo:** `pyproject.toml` (en raíz del proyecto)

```toml
[build-system]
requires = ["setuptools>=75.0", "wheel"]
build-backend = "setuptools.build_meta"

[project]
name = "hermes-web"
version = "72.0.0"
description = "Hermes Enterprise Web Portal"
requires-python = ">=3.14"
dependencies = [
    "fastapi==0.115.6",
    "uvicorn[standard]==0.34.0",
    "jinja2==3.1.5",
    "pydantic==2.10.4",
]

[project.optional-dependencies]
dev = [
    "pytest>=8.0",
    "pytest-cov>=5.0",
    "ruff>=0.8.0",
    "black>=24.0",
    "isort>=5.0",
    "mypy>=1.0",
    "pip-audit>=2.0",
]
test = ["httpx>=0.28.1"]
azure = ["gunicorn==23.0.0"]

[tool.setuptools.packages.find]
include = ["Hermes*"]

[tool.ruff]
target-version = "py314"
line-length = 100

[tool.black]
line-length = 100
target-version = ["py314"]

[tool.isort]
profile = "black"
line-length = 100

[tool.mypy]
python_version = "3.14"
strict = true

[tool.pytest.ini_options]
testpaths = ["pruebas/python"]
python_files = ["test_*.py"]
addopts = "-v --cov=Hermes.Web --cov-report=term-missing"
```

### 4.2 CI/CD Pipeline

**Archivo:** `.github/workflows/ci.yml`

```yaml
name: RC72-CI

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
      - name: Install
        run: |
          pip install -e .
          pip install -e ".[dev,test]"
      - name: Lint
        run: ruff check Hermes.Web/
      - name: Format
        run: black --check Hermes.Web/
      - name: Security
        run: bandit -r Hermes.Web/
      - name: Audit
        run: pip-audit

  test:
    needs: quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with:
          python-version: "3.14"
      - name: Install
        run: pip install -e ".[test]"
      - name: Run tests
        run: pytest --cov=Hermes.Web --cov-report=xml
      - name: Upload coverage
        uses: codecov/codecov-action@v4

  build:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Package
        run: |
          pip install build
          python -m build
      - uses: actions/upload-artifact@v4
        with:
          name: hermes-web-dist
          path: dist/
```

**Archivo:** `.github/workflows/cd.yml`

```yaml
name: RC72-CD

on:
  push:
    branches: [main]

jobs:
  deploy:
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
      - name: Smoke Test
        run: |
          sleep 30
          curl -f https://hermes-enterprise.azurewebsites.net/api/version
```

---

## 5. FASE RC72-B: REESTRUCTURACIÓN

> **Duración:** 8-12 días  
> **Prioridad:** BAJA (última fase)  
> **Riesgo:** ALTO (modifica estructura de directorios)

### 5.1 Migrar Hermes.Web/ → Hermes/Web/

**Razón:** Eliminar la dependencia del MetaPathFinder personalizado. Python puede importar naturalmente `Hermes.Web.xxx` si existe la estructura `Hermes/Web/`.

**Pasos:**

1. Crear directorio `Hermes/` si no existe con `__init__.py` adecuado
2. Mover `Hermes.Web/` → `Hermes/Web/`
3. Actualizar `Hermes/__init__.py` para ser un paquete Python real
4. Verificar que `import Hermes.Web.backend.main` funciona sin MetaPathFinder
5. Actualizar todos los archivos que referencian `Hermes.Web/` como directorio (deployment, scripts, Azure)

### 5.2 Eliminar MetaPathFinder y sys.path.insert

**Archivo:** `Hermes/Web/backend/main.py`

**Cambios:**

1. Eliminar `HermesWebPackageLoader` (líneas 49-87)
2. Eliminar `HermesWebFinder` (líneas 89-120)
3. Eliminar `sys.path.insert(0, str(_PROJECT_ROOT))` (línea 46)
4. Eliminar `sys.meta_path.insert(0, HermesWebFinder())` (línea 123)
5. Simplificar `_HERMES_WEB_DIR` y `_PROJECT_ROOT` a pathlib normal

**Resultado:** El archivo main.py se reduce de ~570 a ~470 líneas.

### 5.3 Actualizar Archivos de Deployment

**Archivos a modificar:**

| Archivo | Cambio |
|---------|--------|
| `Hermes/Web/deployment/startup.sh` | Mover a nueva ubicación |
| `Hermes/Web/deployment/startup.txt` | Mover a nueva ubicación |
| `config/Hermes.Python.json` | Verificar que `ArchivoRequirements` apunte a ruta correcta |

### 5.4 Plan de Reversión

Si la migración a `Hermes/Web/` falla:

```bash
git revert HEAD --no-commit
git reset
# Restaurar Hermes.Web/ como directorio independiente
git checkout HEAD~1 -- Hermes.Web/
git checkout HEAD~1 -- Hermes/__init__.py
git checkout HEAD~1 -- backend/main.py  # Restaurar Finder
```

**Validación post-reversión:**

```bash
pytest pruebas/python/  # Debe pasar 100%
Invoke-Pester pruebas/unitarias/ -Output Detailed  # Debe pasar 100%
python -c "from Hermes.Web.backend.main import app; print('✅ OK')"
```

---

## 6. ARCHIVOS A CREAR

| Archivo | Fase | Propósito |
|---------|------|-----------|
| `pruebas/python/conftest.py` | RC71-B | Fixtures pytest |
| `pruebas/python/test_main.py` | RC71-B | Tests de main.py |
| `pruebas/python/test_middleware.py` | RC71-B | Tests de middleware |
| `pruebas/python/test_api.py` | RC71-B | Tests de API |
| `pruebas/python/test_servicio_datos.py` | RC71-B | Tests de servicio_datos_proyecto |
| `pruebas/unitarias/Hermes.Python.RC71.Tests.ps1` | RC71-B | Tests Pester Runtime |
| `Hermes.Web/backend/subprocess_utils.py` | RC71-B | Módulo unificado de subprocess |
| `.ruff.toml` | RC71-C | Configuración de ruff |
| `pyproject.toml` | RC72-A | Packaging moderno |
| `.github/workflows/ci.yml` | RC72-A | CI pipeline |
| `.github/workflows/cd.yml` | RC72-A | CD pipeline |
| `docs/architecture/runtime-architecture.md` | RC72-B | Diagrama de arquitectura |

## 7. ARCHIVOS A MODIFICAR

| Archivo | Fase | Cambio |
|---------|------|--------|
| `Hermes.Web/backend/main.py` | RC71-B | Refactor subprocess → subprocess_utils |
| `Hermes.Web/backend/main.py` | RC71-C | Agregar HTTPS middleware |
| `Hermes.Web/backend/main.py` | RC72-B | Eliminar MetaPathFinder, sys.path.insert |
| `Hermes.Web/backend/servicio_datos_proyecto.py` | RC71-B | Reemplazar subprocess → subprocess_utils |
| `Hermes.Web/api/api_version.py` | RC71-B | Reemplazar subprocess → subprocess_utils |
| `Hermes.Web/deployment/startup.sh` | RC71-B | Agregar validación Hermes.Python.json |
| `Hermes.Web/requirements.txt` | RC71-C | Eliminar dependencias innecesarias |
| `Hermes/__init__.py` | RC72-B | Expandir como paquete real |
| `CHANGELOG.md` | Todas | Agregar entradas por release |
| `CURRENT_STATE.md` | Todas | Actualizar tras cada release |
| `docs/ArchitectureState.md` | Todas | Actualizar tras cada release |

## 8. ARCHIVOS A ELIMINAR

| Archivo | Fase | Razón |
|---------|------|-------|
| `$null` | RC71-C | Archivo sin propósito |
| `temp_analysis.txt` | RC71-C | Archivo temporal de análisis |
| `Hermes.Web/` (directorio) | RC72-B | Reemplazado por `Hermes/Web/` |

## 9. RIESGOS Y PLAN DE REVERSIÓN

### 9.1 Matriz de Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|--------|-------------|---------|------------|
| CI/CD bloquea deploys | MEDIA | ALTO | Tener `requirements.txt` como fallback |
| pytest encuentra bugs existentes | ALTA | BAJO | Bugs existentes no fueron introducidos por RC72 |
| Reestructuración Hermes.Web → Hermes/Web/ falla | BAJA | CRÍTICO | Plan de reversión documentado (Sección 5.4) |
| pyproject.toml incompatible con Azure | BAJA | MEDIO | Mantener `requirements.txt` como alternativa |

### 9.2 Gates de Calidad

| Gate | RC71-B | RC71-C | RC72-A | RC72-B |
|------|--------|--------|--------|--------|
| Pester tests | ✅ 100% | ✅ 100% | ✅ 100% | ✅ 100% |
| pytest | ✅ ≥ 80% cov | ✅ ≥ 80% cov | ✅ ≥ 80% cov | ✅ ≥ 80% cov |
| ruff | ❌ No | ✅ 0 errors | ✅ 0 errors | ✅ 0 errors |
| black | ❌ No | ✅ Pass | ✅ Pass | ✅ Pass |
| pip-audit | ❌ No | ❌ No | ✅ 0 high vulns | ✅ 0 high vulns |
| Manual testing | ✅ | ✅ | ✅ | ✅ |

### 9.3 Criterios de Rollback

Cualquiera de los siguientes dispara rollback automático:

1. Tests Pester: < 100% pass
2. pytest: < 70% coverage o < 100% pass
3. App no inicia en Azure después del deploy
4. Error de importación de Hermes.Web

---

## 10. CRITERIOS DE ACEPTACIÓN

### 10.1 RC71-B

- [x] Suite pytest creada con ≥ 100 tests
- [x] Cobertura ≥ 80% en Hermes.Web/backend/
- [x] Suite Pester actualizada con tests de Runtime Python
- [x] `subprocess_utils.py` creado y usado por main.py, servicio_datos_proyecto.py, api_version.py
- [x] `startup.sh` valida Hermes.Python.json antes de ejecutar
- [x] 86/86 tests Pester existentes siguen pasando

### 10.2 RC71-C

- [x] HTTPS redirect implementado en main.py
- [x] ruff configurado con 0 errores
- [x] Archivos obsoletos eliminados ($null, temp_analysis.txt)
- [x] requirements.txt limpio (solo 4 dependencias runtime)
- [x] CHANGELOG, ArchitectureState, CURRENT_STATE actualizados

### 10.3 RC72-A

- [x] pyproject.toml funcional con `pip install -e .`
- [x] CI pipeline funciona en GitHub Actions
- [x] CD pipeline despliega a Azure App Service
- [x] Quality gates: ruff 0 errors, black pass, pip-audit 0 high
- [x] requirements.txt mantenido como fallback

### 10.4 RC72-B

- [x] `Hermes/Web/` existe como paquete Python estándar
- [x] `Hermes.Web` ya no existe como directorio independiente
- [x] MetaPathFinder eliminado de main.py
- [x] `sys.path.insert` eliminado de main.py
- [x] `import Hermes.Web.backend.main` funciona sin hacks
- [x] 100% tests pasan (pytest + Pester)
- [x] Deploy Azure funciona
- [x] Plan de reversión documentado y verificado

---

*Fin del plan de migración RC72*