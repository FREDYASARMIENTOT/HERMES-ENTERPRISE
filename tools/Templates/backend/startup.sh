#!/bin/bash
set -e
_STARTUP_START=$(date +%s)

echo "[{{PROJECT_NAME}}] Starting deployment... (startup.sh)"

cd /home/site/wwwroot
export PYTHONPATH="/home/site/wwwroot/__deps__:/home/site/wwwroot${PYTHONPATH:+:$PYTHONPATH}"

echo "[{{PROJECT_NAME}}] Creating data directory..."
mkdir -p data

echo "[{{PROJECT_NAME}}] Initializing database schema + metadata + migration..."
python3 -c "
import sqlite3, os, datetime, sys, time
t0 = time.time()
db_path = os.path.join('data', 'proyecto.db')
fresh = not os.path.exists(db_path)
conn = sqlite3.connect(db_path)
c = conn.cursor()

# ── SCHEMA (inline — schema.sql never exists in child) ──
if fresh:
    c.execute('''CREATE TABLE IF NOT EXISTS Proyecto (
        Id INTEGER PRIMARY KEY AUTOINCREMENT, Nombre TEXT, Descripcion TEXT,
        Version TEXT, CorrelationId TEXT, Estado TEXT, Repositorio TEXT,
        Branch TEXT, CommitHash TEXT, UrlPublica TEXT, Region TEXT DEFAULT \"\",
        DeploymentId TEXT DEFAULT \"\", EstadoAzure TEXT, EstadoGitHub TEXT,
        EstadoCI TEXT, TiempoBuild REAL, TiempoDeploy REAL, TiempoSmokeTest REAL,
        FechaCreacion TEXT, FechaActualizacion TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS Timeline (
        Id INTEGER PRIMARY KEY AUTOINCREMENT, CorrelationId TEXT, Evento TEXT,
        Estado TEXT, Fecha TEXT, Detalle TEXT, Duracion REAL)''')
    c.execute('''CREATE TABLE IF NOT EXISTS SmokeTestResults (
        Id INTEGER PRIMARY KEY AUTOINCREMENT, CorrelationId TEXT, Endpoint TEXT,
        HTTPCode INTEGER, Estado TEXT, TiempoRespuesta REAL, Fecha TEXT, Detalle TEXT)''')
    c.execute('''CREATE TABLE IF NOT EXISTS BitacoraEventos (
        Id INTEGER PRIMARY KEY AUTOINCREMENT, CorrelationId TEXT, Fecha TEXT,
        Hora TEXT, Usuario TEXT, Paso TEXT, Estado TEXT, Duracion REAL,
        Mensaje TEXT, Resultado TEXT)''')
    conn.commit()
    print(f'schema_init: {time.time()-t0:.3f}s')

# ── MIGRATION (safe ALTER TABLE ADD COLUMN pattern) ──
t1 = time.time()
for col in ['Region', 'DeploymentId']:
    try:
        c.execute(f'ALTER TABLE Proyecto ADD COLUMN {col} TEXT DEFAULT \"\"')
        print(f'migration_add_{col}: OK')
    except Exception:
        pass
conn.commit()
print(f'migration: {time.time()-t1:.3f}s')

# ── METADATA INSERT ──
t2 = time.time()
corr_id = os.environ.get('HERMES_CORRELATION_ID', '')
name = os.environ.get('HERMES_PROJECT_NAME', '')
webapp = os.environ.get('HERMES_WEBAPP_NAME', '')
repo = os.environ.get('HERMES_REPOSITORY', '')
commit_sha = os.environ.get('HERMES_COMMIT_SHA', '')
region = os.environ.get('HERMES_REGION', '')
deploy_id = os.environ.get('HERMES_DEPLOYMENT_ID', corr_id)
url = f'https://{webapp}.azurewebsites.net' if webapp else ''
now = datetime.datetime.utcnow().isoformat()
if corr_id and name:
    c.execute('SELECT COUNT(*) FROM Proyecto WHERE CorrelationId = ?', (corr_id,))
    if c.fetchone()[0] == 0:
        c.execute('''INSERT INTO Proyecto (CorrelationId, Nombre, Repositorio,
            CommitHash, Estado, Region, DeploymentId, UrlPublica,
            FechaCreacion, FechaActualizacion) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
            (corr_id, name, repo, commit_sha, 'CREADO', region, deploy_id, url, now, now))
        conn.commit()
        print(f'metadata_insert: {name} ({corr_id})')
    else:
        print(f'metadata_exists: {corr_id}')
else:
    print(f'metadata_skip: corr_id={corr_id!r} name={name!r}')
conn.close()
print(f'metadata: {time.time()-t2:.3f}s')
print(f'db_total: {time.time()-t0:.3f}s')
" 2>&1

echo "[{{PROJECT_NAME}}] Setting runtime environment metadata..."
export HERMES_PROJECT_NAME="{{PROJECT_NAME}}"
export HERMES_CORRELATION_ID="{{CORRELATION_ID}}"
export HERMES_WEBAPP_NAME="{{WEBAPP_NAME}}"
export HERMES_REGION="${REGION:-${LOCATION:-eastus}}"
export HERMES_DEPLOYMENT_ID="${DEPLOYMENT_ID:-{{CORRELATION_ID}}}"

# NOTE: HERMES_REPOSITORY and HERMES_COMMIT_SHA are set as App Settings
# by deploy-child.yml. Do NOT override them here.
echo "[{{PROJECT_NAME}}] startup.sh completed in $(($(date +%s) - _STARTUP_START))s"
echo "[{{PROJECT_NAME}}] Starting uvicorn..."
python -m uvicorn backend.main:app --host 0.0.0.0 --port ${PORT:-8000}
