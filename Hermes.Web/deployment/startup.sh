#!/bin/bash
# ====================================================================
# startup.sh ? Script de inicio para Azure App Service (Linux)
# ====================================================================
# CORRECCION E2E: Se usa bootstrap_portal:app en lugar de
#   Hermes.Web.backend.main:app para evitar el problema de
#   resolucion de modulos con punto en el nombre del directorio.
#
#   bootstrap_portal.py carga main.py via importlib.util.spec_from_file_location,
#   sorteando la resolucion dotted-path de Python que no puede encontrar
#   "Hermes.Web" como paquete cuando el directorio se llama literalmente
#   "Hermes.Web/" (con punto).
# ====================================================================

set -e

HERMES_WEB_DIR="/home/site/wwwroot/Hermes.Web"
echo "========================================="
echo "HERMES PORTAL ? Inicio en Azure App Service"
echo "========================================="
echo "Fecha: $(date)"
echo "Python: $(python3 --version 2>&1)"
echo "Directorio base: /home/site/wwwroot"
echo "Bootstrap: bootstrap_portal.py"
echo "Hermes.Web: $HERMES_WEB_DIR"
echo "Contenido: $(ls -la /home/site/wwwroot/)"
echo "========================================="

# 1. Dependencias instaladas por SCM build (SCM_DO_BUILD_DURING_DEPLOYMENT=true)
#    No ejecutar pip install aqui - B1 es lento y excede timeout de 10 min

# 2. Verificar dependencias criticas
echo "[1/2] Verificando dependencias criticas..."
python3 -c "
import fastapi
import uvicorn
import jinja2
print(f'FastAPI: {fastapi.__version__}')
print(f'Uvicorn: OK')
print(f'Jinja2: {jinja2.__version__}')
print('Dependencias OK')
" 2>&1

# 3. PYTHONPATH hereda el App Setting + agregamos wwwroot explicitamente
echo "[2/2] Configurando PYTHONPATH y directorio..."
PROJECT_ROOT="/home/site/wwwroot"
echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "PYTHONPATH actual: $PYTHONPATH"
export PYTHONPATH="${PROJECT_ROOT}:${PYTHONPATH}"
echo "PYTHONPATH final: $PYTHONPATH"

# 4. Listar contenido para debug
echo "Contenido de wwwroot:"
ls -la "$PROJECT_ROOT"/
echo "Contenido de Hermes.Web/backend:"
ls -la "$PROJECT_ROOT/Hermes.Web/backend/" 2>/dev/null || echo "(no existe o no accesible)"

# 5. Iniciar servidor Uvicorn (modo proceso unico — sin --workers)
#    B1 es single-core; un solo worker evita subprocesos multiprocessing
#    que no heredan sys.path[0] (CWD) correctamente.
#    --app-dir fuerza la ruta del modulo bootstrap para workers futuros.
echo "Iniciando servidor Uvicorn..."
echo "Host: 0.0.0.0"
echo "Puerto: ${PORT:-8000}"
echo "Workers: 1 (proceso unico, sin fork)"
echo "Module: bootstrap_portal:app (bootstrap -> Hermes.Web.backend.main)"
echo "========================================="

cd "$PROJECT_ROOT"
python3 -m uvicorn \
    bootstrap_portal:app \
    --host 0.0.0.0 \
    --port ${PORT:-8000} \
    --app-dir "$PROJECT_ROOT" \
    --log-level info \
    --access-log
