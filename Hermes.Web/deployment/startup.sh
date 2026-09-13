#!/bin/bash
# ====================================================================
# startup.sh ? Script de inicio para Azure App Service (Linux)
# ====================================================================
# RC72: Los archivos se despliegan con prefijo Hermes.Web/
# para mantener compatibilidad con imports como:
#   from Hermes.Web.api.api_version import router
# ====================================================================

set -e

HERMES_WEB_DIR="/home/site/wwwroot/Hermes.Web"
echo "========================================="
echo "Hermes.Web ? Inicio en Azure App Service"
echo "========================================="
echo "Fecha: $(date)"
echo "Python: $(python3 --version 2>&1)"
echo "Directorio base: /home/site/wwwroot"
echo "Hermes.Web: $HERMES_WEB_DIR"
echo "Contenido: $(ls -la /home/site/wwwroot/)"
echo "========================================="

# 1. Instalar dependencias
echo "[1/3] Instalando dependencias desde requirements.txt..."
if [ -f "/home/site/wwwroot/requirements.txt" ]; then
    python3 -m pip install -r /home/site/wwwroot/requirements.txt 2>&1
elif [ -f "$HERMES_WEB_DIR/requirements.txt" ]; then
    python3 -m pip install "$HERMES_WEB_DIR/requirements.txt" --no-cache-dir 2>&1
fi

# 2. Verificar dependencias cr?ticas
echo "[2/3] Verificando dependencias cr?ticas..."
python3 -c "
import fastapi
import uvicorn
import jinja2
print(f'FastAPI: {fastapi.__version__}')
print(f'Uvicorn: OK')
print(f'Jinja2: {jinja2.__version__}')
print('Dependencias OK')
" 2>&1

# 3. PYTHONPATH debe incluir /home/site/wwwroot (ra?z del proyecto)
#    para que main.py pueda importar Hermes.Web.backend.servicio_fabrica
#    ANTES de registrar el HermesWebFinder personalizado.
echo "[2b/3] Configurando PYTHONPATH..."
PROJECT_ROOT="/home/site/wwwroot"
echo "PROJECT_ROOT: $PROJECT_ROOT"
echo "PYTHONPATH: $PROJECT_ROOT"
export PYTHONPATH="$PROJECT_ROOT"

# 4. Iniciar servidor Uvicorn (1 worker para B1)
echo "[3/3] Iniciando servidor Uvicorn..."
echo "Host: 0.0.0.0"
echo "Puerto: ${PORT:-8000}"
echo "Workers: 1 (B1 single-core)"
echo "Module: Hermes.Web.backend.main:app"
echo "========================================="

cd "$PROJECT_ROOT"
python3 -m uvicorn \
    Hermes.Web.backend.main:app \
    --host 0.0.0.0 \
    --port ${PORT:-8000} \
    --workers 1 \
    --log-level info \
    --access-log
