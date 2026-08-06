#!/bin/bash
# ====================================================================
# startup.sh — Script de inicio para Azure App Service (Linux)
# ====================================================================
# RC70-D: Usa python -m pip / python -m gunicorn para garantizar
# que se utiliza el mismo interprete configurado en el Runtime.
# ====================================================================

set -e

echo "========================================="
echo "Hermes.Web — Inicio en Azure App Service"
echo "========================================="
echo "Fecha: $(date)"
echo "Python: $(python3 --version 2>&1)"
echo "Directorio: $(pwd)"
echo "========================================="

# 1. Instalar dependencias (RC70-D: usar python -m pip)
echo "[1/3] Instalando dependencias desde Hermes.Web/requirements.txt..."
python3 -m pip install -r Hermes.Web/requirements.txt --no-cache-dir 2>&1

# 2. Verificar dependencias críticas (RC70-D: usar python -c)
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

# 3. Iniciar servidor con Gunicorn + Uvicorn (RC70-D: usar python -m gunicorn)
echo "[3/3] Iniciando servidor Gunicorn + Uvicorn (python -m)..."
echo "Host: 0.0.0.0"
echo "Puerto: ${PORT:-8000}"
echo "Workers: ${WEB_CONCURRENCY:-4}"
echo "========================================="

python3 -m gunicorn Hermes.Web.backend.main:app \
    --worker-class uvicorn.workers.UvicornWorker \
    --bind 0.0.0.0:${PORT:-8000} \
    --workers ${WEB_CONCURRENCY:-4} \
    --timeout 120 \
    --access-logfile - \
    --error-logfile - \
    --log-level info