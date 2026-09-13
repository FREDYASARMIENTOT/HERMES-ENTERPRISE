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

# 3. Verificar dependencias críticas
echo "[2/3] Verificando dependencias..."
python3 -c "
import fastapi; print(f'FastAPI: {fastapi.__version__}')
import uvicorn; print(f'Uvicorn: OK')
import jinja2; print(f'Jinja2: {jinja2.__version__}')
print('Dependencias OK')
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
