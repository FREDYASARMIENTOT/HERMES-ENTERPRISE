function Invoke-Fase06CrearBackend {
    Write-Paso "Backend" "INICIANDO" "Creando backend FastAPI del proyecto"
    
    $mainPy = Join-Path (Join-Path (Join-Path $script:ProjRoot "src") "backend") "main.py"
    $htdocsDir = (Split-Path $mainPy -Parent)
    New-Item -ItemType Directory -Path $htdocsDir -Force | Out-Null
    
    $header = @"
import os, platform, json, uuid, time, logging
from datetime import datetime, timezone
from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import Optional, Dict, Any

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s")
logger = logging.getLogger("TestProject")

PROJECT_ROOT = Path(__file__).resolve().parent.parent
TEMPLATES_DIR = PROJECT_ROOT / "templates"
STATIC_DIR = PROJECT_ROOT / "static"
DATA_DIR = PROJECT_ROOT / "data"
SQLITE_DB = str(DATA_DIR / "proyecto.db")

app = FastAPI(title="TestProject", version="1.0.0", docs_url="/swagger", redoc_url="/redoc", openapi_url="/openapi.json")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

templates = None
if TEMPLATES_DIR.exists():
    from jinja2 import Environment, FileSystemLoader
    _env = Environment(loader=FileSystemLoader(str(TEMPLATES_DIR)), auto_reload=False, cache_size=0)
    templates = Jinja2Templates(env=_env)

if STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

def consultar_sqlite(query: str) -> list:
    import sqlite3
    try:
        conn = sqlite3.connect(SQLITE_DB)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        c.execute(query)
        rows = [dict(r) for r in c.fetchall()]
        conn.close()
        return rows
    except Exception as e:
        logger.warning(f"SQLite error: {e}")
        return []

def obtener_info_proyecto() -> dict:
    rows = consultar_sqlite("SELECT * FROM Proyecto WHERE CorrelationId='ABC123'")
    if rows: return rows[0]
    return {"Nombre":"TestProject","CorrelationId":"ABC123","Estado":"CREADO"}

def obtener_timeline() -> list:
    return consultar_sqlite("SELECT * FROM Timeline WHERE CorrelationId='ABC123' ORDER BY Id ASC")

def obtener_smoke_results() -> list:
    return consultar_sqlite("SELECT * FROM SmokeTestResults WHERE CorrelationId='ABC123'")

def obtener_bitacora() -> list:
    return consultar_sqlite("SELECT * FROM BitacoraEventos WHERE CorrelationId='ABC123' ORDER BY Id DESC LIMIT 20")
"@
    $header | Out-File $mainPy -Encoding utf8
}

Write-Host "Function defined successfully"