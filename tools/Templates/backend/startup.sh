#!/bin/bash
set -e

echo "[{{PROJECT_NAME}}] Starting deployment..."

cd /home/site/wwwroot

echo "[{{PROJECT_NAME}}] Installing dependencies..."
pip install -r requirements.txt -q

echo "[{{PROJECT_NAME}}] Creating data directory..."
mkdir -p data

echo "[{{PROJECT_NAME}}] Initializing database schema..."
python -c "
import sqlite3, os
db_path = os.path.join('data', 'proyecto.db')
schema_path = os.path.join('tools', 'Templates', 'database', 'schema.sql')
if os.path.exists(schema_path):
    conn = sqlite3.connect(db_path)
    with open(schema_path) as f:
        conn.executescript(f.read())
    conn.commit()
    conn.close()
    print('Database schema initialized')
elif not os.path.exists(db_path):
    conn = sqlite3.connect(db_path)
    conn.execute('CREATE TABLE IF NOT EXISTS Proyecto (Id INTEGER PRIMARY KEY AUTOINCREMENT, Nombre TEXT, Descripcion TEXT, Version TEXT, CorrelationId TEXT, Estado TEXT, Repositorio TEXT, Branch TEXT, CommitHash TEXT, UrlPublica TEXT, Region TEXT DEFAULT "", DeploymentId TEXT DEFAULT "", EstadoAzure TEXT, EstadoGitHub TEXT, EstadoCI TEXT, TiempoBuild REAL, TiempoDeploy REAL, TiempoSmokeTest REAL, FechaCreacion TEXT, FechaActualizacion TEXT)')
    conn.execute('CREATE TABLE IF NOT EXISTS Timeline (Id INTEGER PRIMARY KEY AUTOINCREMENT, CorrelationId TEXT, Evento TEXT, Estado TEXT, Fecha TEXT, Detalle TEXT, Duracion REAL)')
    conn.execute('CREATE TABLE IF NOT EXISTS SmokeTestResults (Id INTEGER PRIMARY KEY AUTOINCREMENT, CorrelationId TEXT, Endpoint TEXT, HTTPCode INTEGER, Estado TEXT, TiempoRespuesta REAL, Fecha TEXT, Detalle TEXT)')
    conn.execute('CREATE TABLE IF NOT EXISTS BitacoraEventos (Id INTEGER PRIMARY KEY AUTOINCREMENT, CorrelationId TEXT, Fecha TEXT, Hora TEXT, Usuario TEXT, Paso TEXT, Estado TEXT, Duracion REAL, Mensaje TEXT, Resultado TEXT)')
    conn.commit()
    conn.close()
    print('Database schema initialized (inline)')
" || true

echo "[{{PROJECT_NAME}}] Migrating database schema (add Region/DeploymentId if missing)..."
python -c "
import sqlite3, os
db_path = os.path.join('data', 'proyecto.db')
if not os.path.exists(db_path):
    print('No database yet, skipping migration')
    exit(0)
conn = sqlite3.connect(db_path)
c = conn.cursor()
# Add Region column if missing
try:
    c.execute('ALTER TABLE Proyecto ADD COLUMN Region TEXT DEFAULT \"\"')
    print('Added Region column')
except Exception:
    print('Region column already exists')
try:
    c.execute('ALTER TABLE Proyecto ADD COLUMN DeploymentId TEXT DEFAULT \"\"')
    print('Added DeploymentId column')
except Exception:
    print('DeploymentId column already exists')
conn.commit()
conn.close()
" || true

echo "[{{PROJECT_NAME}}] Setting runtime environment metadata..."
export HERMES_PROJECT_NAME="{{PROJECT_NAME}}"
export HERMES_CORRELATION_ID="{{CORRELATION_ID}}"
export HERMES_WEBAPP_NAME="{{WEBAPP_NAME}}"
export HERMES_REGION="${REGION:-${LOCATION:-eastus}}"
export HERMES_DEPLOYMENT_ID="${DEPLOYMENT_ID:-{{CORRELATION_ID}}}"

echo "[{{PROJECT_NAME}}] Starting application..."
python -m uvicorn backend.main:app --host 0.0.0.0 --port ${PORT:-8000}
