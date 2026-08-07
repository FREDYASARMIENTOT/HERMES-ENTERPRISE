#!/bin/bash
# ====================================================================
# startup.sh — Script de inicio para Azure App Service (Linux)
# ====================================================================
# RC72: Los archivos se despliegan con prefijo Hermes.Web/
# para mantener compatibilidad con imports como:
#   from Hermes.Web.api.api_version import router
# ====================================================================

set -e

HERMES_WEB_DIR="/home/site/wwwroot/Hermes.Web"
echo "========================================="
echo "Hermes.Web — Inicio en Azure App Service"
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
    python3 -m pip install -r /home/site/wwwroot/requirements.txt --no-cache-dir 2>&1
elif [ -f "$HERMES_WEB_DIR/requirements.txt" ]; then
    python3 -m pip install "$HERMES_WEB_DIR/requirements.txt" --no-cache-dir 2>&1
fi

# 2. Verificar dependencias críticas
echo "[2/3] Verificando dependencias críticas..."
python3 -c "
import fastapi
import uvicorn
import jinja2
print(f'FastAPI: {fastapi.__version__}')
print(f'Uvicorn: OK')
print(f'Jinja2: {jinja2.__version__}')
print('Dependencias OK')
" 2>&1

# 3. Cambiar al directorio Hermes.Web
echo "[2b/3] Cambiando a $HERMES_WEB_DIR..."
cd "$HERMES_WEB_DIR"
echo "Contenido de Hermes.Web: $(ls -la)"
echo "PYTHONPATH: $HERMES_WEB_DIR"

# 4. Iniciar servidor Gunicorn + Uvicorn
echo "[3/3] Iniciando servidor Gunicorn + Uvicorn..."
echo "Host: 0.0.0.0"
echo "Puerto: ${PORT:-8000}"
echo "Workers: ${WEB_CONCURRENCY:-4}"
echo "========================================="

PYTHONPATH="$HERMES_WEB_DIR" python3 -m gunicorn \
    backend.main:app \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:${PORT:-8000} \
    --workers ${WEB_CONCURRENCY:-4} \
    --timeout 120 \
    --access-logfile - \
    --error-logfile - \
    --log-level info
