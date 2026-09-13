#!/bin/bash
# ====================================================================
# startup.sh — Script de inicio para Azure App Service (Linux)
# ====================================================================
# ESTRATEGIA DEFINITIVA (RC93):
#   - ZIP root = contenido de Hermes.Web/
#   - Entrypoint directo: backend.main:app
#   - Sin bootstrap_portal, sin --app-dir, sin --workers
#   - Igual patrón que los proyectos hijos funcionales
# ====================================================================
# RC94.27: Dependencias preinstaladas en __deps/ (paquete autocontenido)
# Activamos PYTHONPATH para que Python encuentre los paquetes locales
# SIN ejecutar pip install, SIN modificar el runtime del sistema.
export PYTHONPATH="/home/site/wwwroot/__deps__:$PYTHONPATH"

# ====================================================================
# RC94.16-DIAG — INICIO BLOQUE DIAGNÓSTICO
# Propósito: Identificar exactamente qué comando produce EXIT 127.
# Para revertir: reemplazar todo entre "RC94.16-DIAG-BEGIN" y
# "RC94.16-DIAG-END" por "set -e" (una línea).
# ====================================================================

# ─── RC94.16-DIAG-BEGIN ──────────────────────────────────────────────
# En lugar de `set -e` global, cada comando captura su exit code
# y aborta explícitamente si es != 0. Esto preserva exactamente el
# mismo comportamiento que set -e, pero registra qué comando falló.

echo "========================================="
echo "=== RC94.16 STARTUP DIAGNOSTIC ==="
echo "========================================="

echo "=== STARTUP_DIAGNOSTIC_BEGIN ==="
echo "FECHA=$(date -u '+%Y-%m-%dT%H:%M:%SZ' 2>&1)"
echo "HOSTNAME=$(hostname 2>&1)"
echo "SHELL=$SHELL"
echo "BASH_VERSION=$BASH_VERSION"
echo "PWD=$(pwd 2>&1)"
echo "WHOAMI=$(whoami 2>&1)"
echo "UID=$UID"
echo "PATH=$PATH"

# Contador de comandos de diagnóstico
_DC=0

# Helper: ejecuta un comando, captura su exit code, lo registra,
# y aborta con el mismo exit code si falla (como set -e).
_diag() {
    _DC=$((_DC + 1))
    local _tag=$(printf 'CMD_%02d' $_DC)
    echo "${_tag}=$*"
    "$@"
    local _rc=$?
    echo "${_tag}_EXIT=${_rc}"
    if [ $_rc -ne 0 ]; then
        echo "=== STARTUP_DIAGNOSTIC_FAILED at ${_tag} (EXIT=${_rc}) ==="
        exit $_rc
    fi
}

# Helper para comandos que NO deben abortar (ej: test de archivos)
_diag_info() {
    _DC=$((_DC + 1))
    local _tag=$(printf 'CMD_%02d' $_DC)
    echo "${_tag}=$*"
    if "$@"; then
        echo "${_tag}_EXIT=0 (OK)"
    else
        local _rc=$?
        echo "${_tag}_EXIT=${_rc} (not fatal)"
    fi
}

# ─── [1] PYTHON DISCOVERY ──────────────────────────────────────────
echo "--- [1] PYTHON DISCOVERY ---"
_diag command -v python3
_diag_info command -v python
_diag_info command -v pip3
_diag_info command -v pip

# ─── [2] PYTHON VERSIONS ──────────────────────────────────────────
echo "--- [2] PYTHON VERSIONS ---"
_diag python3 --version
_diag_info python --version

# ─── [3] ANTENV FILESYSTEM ────────────────────────────────────────
echo "--- [3] ANTENV FILESYSTEM ---"
_diag_info test -d /antenv
_diag_info test -f /antenv/bin/python
_diag_info test -f /antenv/bin/python3
_diag_info test -f /antenv/bin/activate
_diag_info test -d /opt/antenv
_diag_info test -f /opt/antenv/bin/python
_diag_info test -f /opt/antenv/bin/python3
_diag_info test -f /opt/antenv/bin/activate
_diag_info ls -la /antenv 2>/dev/null
_diag_info ls -la /opt/antenv 2>/dev/null
_diag_info ls -la /home/site/wwwroot/antenv 2>/dev/null
# ─── [4] WORKING DIRECTORY ────────────────────────────────────────
echo "--- [4] WORKING DIRECTORY ---"
_diag cd /home/site/wwwroot
_diag pwd
_diag ls -la
_diag ls -la backend/
_diag ls -la deployment/
_diag ls -la templates/ 2>/dev/null
_diag_info ls -la static/ 2>/dev/null
_diag_info find . -maxdepth 2 -type f -name '*.py' 2>/dev/null | head -20

# ─── [5] PYTHON RUNTIME INFO ──────────────────────────────────────
echo "--- [5] PYTHON RUNTIME ---"
_diag python3 -c "import sys; print('sys.executable=' + sys.executable)"
_diag python3 -c "import sys; print('sys.version=' + sys.version)"
_diag python3 -c "import sys; print('sys.platform=' + sys.platform)"
_diag python3 -c "
import sys
print('sys.path=')
for p in sys.path:
    print('  ' + p)
"
_diag python3 -c "
import os
print('CWD=' + os.getcwd())
print('USER=' + os.environ.get('USER', 'N/A'))
print('HOME=' + os.environ.get('HOME', 'N/A'))
print('WEBSITE_SITE_NAME=' + os.environ.get('WEBSITE_SITE_NAME', 'N/A'))
print('WEBSITE_ROLE_INSTANCE_ID=' + os.environ.get('WEBSITE_ROLE_INSTANCE_ID', 'N/A'))
"

# ─── [6] DEPENDENCY IMPORTS (individual) ──────────────────────────
echo "--- [6] DEPENDENCY IMPORTS ---"
_diag python3 -c "
import importlib.util
mods = ['fastapi', 'uvicorn', 'jinja2', 'pydantic', 'python_dotenv']
for m in mods:
    spec = importlib.util.find_spec(m)
    print(f'{m}={spec}')
"
_diag python3 -c "import fastapi; print('fastapi=' + fastapi.__version__ + ' at ' + fastapi.__file__)"
_diag python3 -c "import uvicorn; print('uvicorn=' + uvicorn.__version__ + ' at ' + uvicorn.__file__)"
_diag python3 -c "import jinja2; print('jinja2=' + jinja2.__version__ + ' at ' + jinja2.__file__)"
_diag python3 -c "import pydantic; print('pydantic=' + pydantic.__version__ + ' at ' + pydantic.__file__)"

# ─── [7] APPLICATION ENTRYPOINT ───────────────────────────────────
echo "--- [7] APPLICATION ENTRYPOINT ---"
_diag python3 -c "
import sys, os
sys.path.insert(0, os.getcwd())
import backend.main
print('backend.main=' + str(backend.main.__file__))
print('HermesWebFinder loaded=' + str(hasattr(backend.main, 'HermesWebFinder')))
"
_diag python3 -c "
import sys, os
sys.path.insert(0, os.getcwd())
from backend.main import app
print('app=' + str(type(app).__name__))
print('app.title=' + str(app.title))
print('routes=' + str(len(app.routes)))
"
_diag python3 -c "
import sys, os
sys.path.insert(0, os.getcwd())
import backend.main
print('HermesWebFinder registered: ', end='')
for f in sys.meta_path:
    if hasattr(f, '_hermes_web_str') or 'Hermes' in type(f).__name__:
        print(type(f).__name__, end=' ')
print()
"

# ─── [8] UVICORN CLI ──────────────────────────────────────────────
echo "--- [8] UVICORN CLI ---"
_diag python3 -m uvicorn --version

echo "=== STARTUP_DIAGNOSTIC_END ==="
echo "ALL_DIAGNOSTICS_PASSED: All ${_DC} commands completed successfully."
echo "=== PROCEEDING TO NORMAL STARTUP ==="
echo "========================================="
echo ""
# ─── RC94.16-DIAG-END ────────────────────────────────────────────────

# ====================================================================
# A partir de aquí: CÓDIGO ORIGINAL (sin modificar)
# ====================================================================

set -e

echo "========================================="
echo "HERMES PORTAL — Inicio en Azure App Service"
echo "========================================="
echo "Fecha: $(date)"
echo "Python: $(python3 --version 2>&1)"
echo "Entrypoint: backend.main:app"
echo "========================================="

# 1. Ir a /home/site/wwwroot (raíz de la app)
cd /home/site/wwwroot

# 2. Validaciones rápidas
echo "[1/3] Validando estructura..."
test -f backend/main.py && echo "  OK: backend/main.py" || echo "  FAIL: backend/main.py"
test -f requirements.txt && echo "  OK: requirements.txt" || echo "  FAIL: requirements.txt"
echo "pwd: $(pwd)"
echo "ls -la:"
ls -la
echo "backend/:"
ls -la backend/

# 3. Verificar dependencias (preinstaladas por Oryx durante build phase)
echo "[2/3] Verificando dependencias..."
python3 -c "
import fastapi; print(f'  FastAPI: {fastapi.__version__}')
import uvicorn; print(f'  Uvicorn: OK')
import jinja2; print(f'  Jinja2: {jinja2.__version__}')
print('  Dependencias OK')
" 2>&1

# 4. Iniciar Uvicorn (proceso único — sin --workers)
echo "[3/3] Iniciando servidor..."
echo "Host: 0.0.0.0 | Puerto: ${PORT:-8000}"
echo "Module: backend.main:app"
echo "========================================="

python3 -m uvicorn \
    backend.main:app \
    --host 0.0.0.0 \
    --port ${PORT:-8000} \
    --log-level info \
    --access-log
