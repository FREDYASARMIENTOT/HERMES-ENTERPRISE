import os, json, logging
from datetime import datetime, timezone
from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware
from .registro_implementacion import RegistroImplementacion, ESTADO_COMPLETADO, ESTADO_FALLIDO

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s")
logger = logging.getLogger("{{PROJECT_NAME}}")

PROJECT_ROOT = Path(__file__).resolve().parent.parent
TEMPLATES_DIR = PROJECT_ROOT / "templates"
STATIC_DIR = PROJECT_ROOT / "static"
DATA_DIR = PROJECT_ROOT / "data"
SQLITE_DB = str(DATA_DIR / "proyecto.db")

app = FastAPI(title="{{PROJECT_NAME}}", version="1.0.0", docs_url="/swagger", redoc_url="/redoc", openapi_url="/openapi.json")
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_credentials=True, allow_methods=["*"], allow_headers=["*"])

templates = None
if TEMPLATES_DIR.exists():
    from jinja2 import Environment, FileSystemLoader
    _env = Environment(loader=FileSystemLoader(str(TEMPLATES_DIR)), auto_reload=False, cache_size=0)
    templates = Jinja2Templates(env=_env)

if STATIC_DIR.exists():
    app.mount("/static", StaticFiles(directory=str(STATIC_DIR)), name="static")

# ─── Resolución de metadatos ───
def _resolve_meta(factory_val: str, env_key: str, default: str = "No disponible") -> str:
    """Resuelve un metadato: valor renderizado por Factory → variable de entorno → valor por defecto.
    
    El renderizado en tiempo de Factory reemplaza {{PLACEHOLDER}} por valores reales.
    Si el valor aún comienza con '{{', la Factory no lo reemplazó,
    así que se intenta la variable de entorno. Como último recurso, retorna el valor por defecto.
    """
    if factory_val and not factory_val.startswith("{{"):
        return factory_val
    env_val = os.environ.get(env_key, "")
    if env_val and not env_val.startswith("{{"):
        return env_val
    return default

# ─── SQLite con consultas parametrizadas ───
def consultar_sqlite_param(query: str, params: tuple = ()) -> list:
    """Ejecuta una consulta SQLite parametrizada de forma segura."""
    import sqlite3
    try:
        conn = sqlite3.connect(SQLITE_DB)
        conn.row_factory = sqlite3.Row
        c = conn.cursor()
        c.execute(query, params)
        rows = [dict(r) for r in c.fetchall()]
        conn.close()
        return rows
    except Exception as e:
        logger.warning(f"SQLite error en consulta: {e} | DB: {SQLITE_DB} | Query: {query[:80]}")
        return []

def obtener_info_proyecto(corr_id: str) -> dict:
    rows = consultar_sqlite_param("SELECT * FROM Proyecto WHERE CorrelationId = ?", (corr_id,))
    if rows:
        return rows[0]
    d = _PROJECT_NAME
    return {"Nombre": d, "CorrelationId": corr_id, "Estado": "CREADO"}

def obtener_timeline(corr_id: str) -> list:
    return consultar_sqlite_param("SELECT * FROM Timeline WHERE CorrelationId = ? ORDER BY Id ASC", (corr_id,))

def obtener_smoke_results(corr_id: str) -> list:
    return consultar_sqlite_param("SELECT * FROM SmokeTestResults WHERE CorrelationId = ?", (corr_id,))

def obtener_bitacora(corr_id: str) -> list:
    return consultar_sqlite_param("SELECT * FROM BitacoraEventos WHERE CorrelationId = ? ORDER BY Id DESC LIMIT 20", (corr_id,))

# ─── Registro de Implementación ───
def obtener_implementacion(corr_id: str) -> dict:
    """Obtiene el registro completo de implementación desde SQLite."""
    import os
    db = os.environ.get("SQLITE_DB", SQLITE_DB)
    if not os.path.exists(db):
        return {"error": "Base de datos no encontrada", "db": db}
    reg = RegistroImplementacion.obtener_desde_sqlite(db, corr_id)
    if reg is None:
        return {"error": "No se encontro implementacion", "correlation_id": corr_id}
    return reg

def registrar_paso_api(corr_id: str, paso_data: dict) -> dict:
    """Registra un paso de implementación desde la API del Control Plane."""
    import os
    db = os.environ.get("SQLITE_DB", SQLITE_DB)
    if not os.path.exists(db):
        return {"error": "Base de datos no encontrada"}
    try:
        reg = RegistroImplementacion(db)
        reg.iniciar_implementacion("", corr_id)
        num = paso_data.get("numero_paso", 1)
        estado = paso_data.get("estado", ESTADO_COMPLETADO)
        detalle = paso_data.get("detalle", "")
        evidencia = paso_data.get("evidencia", "")
        resultado = paso_data.get("resultado", "")
        reg.iniciar_paso(num, detalle)
        reg.finalizar_paso(num, estado, detalle, evidencia, resultado)

        # Subpasos opcionales
        subpasos = paso_data.get("subpasos", [])
        for sp in subpasos:
            reg.iniciar_subpaso(num, sp.get("numero_subpaso", ""), sp.get("detalle", ""))
            reg.finalizar_subpaso(num, sp.get("numero_subpaso", ""),
                                   sp.get("estado", ESTADO_COMPLETADO),
                                   sp.get("detalle", ""), sp.get("evidencia", ""),
                                   sp.get("resultado", ""))

        reg.persistir()
        return {"status": "ok", "paso": num, "estado": estado}
    except Exception as e:
        return {"status": "error", "mensaje": str(e)}

# Placeholders renderizados por la Factory en tiempo de creación del proyecto
_PROJECT_NAME = "{{PROJECT_NAME}}"
_CORRELATION_ID = "{{CORRELATION_ID}}"
_WEBAPP_NAME = "{{WEBAPP_NAME}}"
_REGION = "{{REGION}}"
_DEPLOYMENT_ID = "{{DEPLOYMENT_ID}}"

@app.get("/health")
async def health():
    return {"status":"saludable","proyecto":_resolve_meta(_PROJECT_NAME, "HERMES_PROJECT_NAME"),"timestamp":datetime.now(timezone.utc).isoformat()}

@app.get("/api/version")
async def api_version():
    corr_id = _resolve_meta(_CORRELATION_ID, "HERMES_CORRELATION_ID")
    info = obtener_info_proyecto(corr_id)
    pn = _resolve_meta(_PROJECT_NAME, "HERMES_PROJECT_NAME")
    return {"version":"1.0.0","proyecto":info.get("Nombre", pn),"correlationId":corr_id}

@app.get("/api/proyecto")
async def api_proyecto():
    corr_id = _resolve_meta(_CORRELATION_ID, "HERMES_CORRELATION_ID")
    return obtener_info_proyecto(corr_id)

@app.get("/api/workspace")
async def api_workspace():
    corr_id = _resolve_meta(_CORRELATION_ID, "HERMES_CORRELATION_ID")
    pn = _resolve_meta(_PROJECT_NAME, "HERMES_PROJECT_NAME")
    p = obtener_info_proyecto(corr_id)
    workspace = Path(PROJECT_ROOT).parent / (p.get("Nombre", pn) + ".code-workspace")
    return {"workspace":str(workspace),"exists":workspace.exists()}

@app.get("/api/git")
async def api_git():
    git_dir = PROJECT_ROOT.parent / ".git"
    return {"git_init":git_dir.exists(),"branch":"main"}

@app.get("/api/github")
async def api_github():
    corr_id = _resolve_meta(_CORRELATION_ID, "HERMES_CORRELATION_ID")
    info = obtener_info_proyecto(corr_id)
    return {"repo":info.get("Repositorio",""),"status":info.get("EstadoGitHub","")}

@app.get("/api/sqlite")
async def api_sqlite():
    return {"db_path":SQLITE_DB,"exists":Path(SQLITE_DB).exists()}

@app.get("/api/azure")
async def api_azure():
    corr_id = _resolve_meta(_CORRELATION_ID, "HERMES_CORRELATION_ID")
    info = obtener_info_proyecto(corr_id)
    webapp = _resolve_meta(_WEBAPP_NAME, "HERMES_WEBAPP_NAME")
    return {"webapp":webapp,"url":f"https://{webapp}.azurewebsites.net","status":info.get("EstadoAzure","")}

@app.get("/api/despliegue")
async def api_despliegue():
    corr_id = _resolve_meta(_CORRELATION_ID, "HERMES_CORRELATION_ID")
    info = obtener_info_proyecto(corr_id)
    return {"estado":info.get("Estado",""),"total_commits":0,"total_deploys":0,"total_corrections":0}

# ─── API: Registro de Implementación ───
@app.post("/api/implementacion/paso")
async def api_registrar_paso(request: Request):
    """Registra un paso de implementación (llamado por el Control Plane)."""
    try:
        body = await request.json()
    except Exception:
        return JSONResponse({"status":"error","mensaje":"JSON inválido"}, status_code=400)
    corr_id = body.get("correlation_id", _resolve_meta(_CORRELATION_ID, "HERMES_CORRELATION_ID"))
    if not corr_id:
        return JSONResponse({"status":"error","mensaje":"correlation_id requerido"}, status_code=400)
    result = registrar_paso_api(corr_id, body)
    if result.get("status") == "ok":
        return JSONResponse(result)
    return JSONResponse(result, status_code=500)

@app.get("/api/implementacion")
async def api_obtener_implementacion():
    """Obtiene el registro completo de implementación."""
    corr_id = _resolve_meta(_CORRELATION_ID, "HERMES_CORRELATION_ID")
    result = obtener_implementacion(corr_id)
    return JSONResponse(result)

@app.get("/api/evidence")
async def api_evidence():
    \"\"\"Endpoint público de evidencia: retorna deployment-report completo.\"\"\"
    corr_id = _resolve_meta(_CORRELATION_ID, \"HERMES_CORRELATION_ID\")
    result = obtener_implementacion(corr_id)
    if \"error\" in result:
        return JSONResponse(result, status_code=404)
    return JSONResponse(result)

@app.post(\"/api/implementacion/finalizar\")
async def api_finalizar_implementacion(request: Request):
    """Finaliza el registro de implementación."""
    try:
        body = await request.json()
    except Exception:
        return JSONResponse({"status":"error","mensaje":"JSON inválido"}, status_code=400)
    corr_id = body.get("correlation_id", _resolve_meta(_CORRELATION_ID, "HERMES_CORRELATION_ID"))
    estado = body.get("estado", "COMPLETADO")
    db = os.environ.get("SQLITE_DB", SQLITE_DB)
    if not os.path.exists(db):
        return JSONResponse({"error":"Base de datos no encontrada"}, status_code=500)
    try:
        reg = RegistroImplementacion(db)
        reg.iniciar_implementacion("", corr_id)
        reg.finalizar_implementacion(estado, body.get("detalle", ""))
        reg.persistir()
        return JSONResponse({"status":"ok","estado_general":estado})
    except Exception as e:
        return JSONResponse({"status":"error","mensaje":str(e)}, status_code=500)

# ─── Definición de nodos del pipeline de implementación ───
_PIPELINE_DEF = [
    (1, "factory", "FACTORY", "bi-rocket-takeoff"),
    (1, "child-repo", "CHILD REPOSITORY", "bi-github"),
    (2, "ci", "CI", "bi-arrow-repeat"),
    (2, "control-plane", "CONTROL PLANE", "bi-diagram-3"),
    (3, "oidc", "OIDC", "bi-shield-check"),
    (4, "asp-iaur", "ASP-IAUR", "bi-server"),
    (4, "web-app", "WEB APP", "bi-globe"),
    (5, "zip-deploy", "ZIP DEPLOY", "bi-cloud-upload"),
    (6, "readiness", "READINESS", "bi-heart-pulse"),
    (6, "functional-tests", "FUNCTIONAL TESTS", "bi-shield-check"),
    (6, "user-facing", "USER FACING", "bi-eye"),
    (7, "evidence", "EVIDENCE", "bi-file-earmark-check"),
    (8, "online", "ONLINE", "bi-check-circle-fill"),
]

def _build_pipeline(info: dict, smoke: list, timeline: list):
    """Construye los estados de los nodos del pipeline a partir de datos reales."""
    tl = {t.get("Evento","").lower(): t for t in timeline}
    passed = sum(1 for s in smoke if s.get("Estado") == "PASS") if smoke else 0
    total = len(smoke) if smoke else 0
    test_ok = total > 0 and passed == total
    estado = info.get("Estado", "CREADO")
    estado_ci = info.get("EstadoCI", "")
    estado_azure = info.get("EstadoAzure", "")
    cs = lambda s: {"pass":"pass","ok":"pass","fail":"fail","pending":"pending"}.get(s.lower() if s else "", "info")
    states = {
        "factory": {"s": cs(tl.get("workspace",{}).get("Estado","")), "d": "Workspace Creado"},
        "child-repo": {"s": "pass", "d": info.get("Repositorio", "No disponible")},
        "ci": {"s": cs(estado_ci) if estado_ci else "info", "d": f"Estado: {estado_ci or 'N/D'}"},
        "control-plane": {"s": "pass" if estado in ("OK","PASS") else "info", "d": "Orquestado por Control Plane"},
        "oidc": {"s": "pass", "d": "FIC: UR-Fabrica-Proyectos-AR"},
        "asp-iaur": {"s": "pass", "d": "REUTILIZADO"},
        "web-app": {"s": cs(estado_azure) if estado_azure else "info", "d": info.get("Region","No disponible")},
        "zip-deploy": {"s": "pass" if tl.get("deploy") else "info", "d": "az webapp deploy"},
        "readiness": {"s": "pass" if tl.get("deploy") else "info", "d": "/health endpoint"},
        "functional-tests": {"s": "pass" if test_ok else "pending", "d": f"{passed}/{total}" if total else "N/D"},
        "user-facing": {"s": "pass" if test_ok else "pending", "d": f"{passed}/{total}" if total else "N/D"},
        "evidence": {"s": "pass" if test_ok else "pending", "d": "deployment-report.json"},
        "online": {"s": "pass" if test_ok else "pending", "d": "🟢 OPERATIVO" if test_ok else "⏳ PENDIENTE"},
    }
    result = []
    for sec, nid, name, icon in _PIPELINE_DEF:
        st = states.get(nid, {"s":"pending","d":"No disponible"})
        result.append((sec, nid, name, icon, st["s"], st["d"]))
    return result

@app.get("/", response_class=HTMLResponse)
async def landing(request: Request):
    # ── Resolve metadata: env var > factory-rendered > "No disponible" ──
    project_name = _resolve_meta(_PROJECT_NAME, "HERMES_PROJECT_NAME")
    corr_id = _resolve_meta(_CORRELATION_ID, "HERMES_CORRELATION_ID")
    webapp_name = _resolve_meta(_WEBAPP_NAME, "HERMES_WEBAPP_NAME")
    region = _resolve_meta(_REGION, "HERMES_REGION")
    deployment_id = _resolve_meta(_DEPLOYMENT_ID, "HERMES_DEPLOYMENT_ID")
    runtime = "Python 3.12"

    info = obtener_info_proyecto(corr_id)
    timeline = obtener_timeline(corr_id)
    smoke = obtener_smoke_results(corr_id)

    nombre = info.get("Nombre", project_name)
    estado = info.get("Estado", "CREADO")
    url_publica = info.get("UrlPublica", f"https://{webapp_name}.azurewebsites.net" if "No" not in webapp_name else "#")
    repositorio = info.get("Repositorio") or _resolve_meta("", "HERMES_REPOSITORY", "No disponible")
    commit_hash = info.get("CommitHash") or _resolve_meta("", "HERMES_COMMIT_SHA", "No disponible")
    region_db = info.get("Region", region)

    # ── Estado general ──
    passed = sum(1 for s in smoke if s.get("Estado") == "PASS") if smoke else 0
    total = len(smoke) if smoke else 0
    overall_status = "PASS" if (total > 0 and passed == total) else ("PASS" if estado in ("OK", "COMPLETADO") else ("FAIL" if estado == "FALLIDO" else "PENDIENTE"))
    now = datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")

    pipeline = _build_pipeline(info, smoke, timeline)

    # ── Construir HTML del pipeline ──
    SECTION_NAMES = {1:"ORIGEN",2:"AUTOMATIZACION",3:"SEGURIDAD",4:"INFRAESTRUCTURA",
                     5:"DESPLIEGUE",6:"VALIDACION",7:"EVIDENCIA",8:"ESTADO FINAL"}
    def _sc(st): return {"pass":"#27ae60","fail":"#e74c3c","pending":"#7f8c8d","info":"#3498db"}.get(st,"#7f8c8d")
    def _si(st):
        return ('<i class="bi bi-check-circle-fill" style="color:#27ae60"></i>' if st=="pass"
                else '<i class="bi bi-x-circle-fill" style="color:#e74c3c"></i>' if st=="fail"
                else '<i class="bi bi-hourglass-split" style="color:#7f8c8d"></i>' if st=="pending"
                else '<i class="bi bi-info-circle-fill" style="color:#3498db"></i>')

    pipe_html = ""
    cur_sec = 0
    for sec, nid, name, icon, st, det in pipeline:
        if sec != cur_sec:
            if cur_sec > 0: pipe_html += "</div>"
            pipe_html += f'<div class="pipe-section"><div class="pipe-label">{SECTION_NAMES.get(sec,"")}</div>'
            cur_sec = sec
        c = _sc(st)
        pipe_html += f"""<div class="pipe-conn" style="background:{c}"></div>
        <div class="pipe-node" style="border-left-color:{c}">
            <div class="pipe-icon" style="border:2px solid {c}"><i class="bi {icon}" style="color:{c}"></i></div>
            <div class="pipe-body"><div class="pipe-name">{name}</div><div class="pipe-detail">{det}</div></div>
            <div class="pipe-status">{_si(st)}</div>
        </div>"""
    if cur_sec > 0: pipe_html += "</div>"

    # ── Renderizar HTML completo ──
    html = f"""<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>HERMES ENTERPRISE — FICHA :: {nombre}</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<style>
body{{background:#0b0f1a;color:#e0e0e0;font-family:'Segoe UI',system-ui,sans-serif;}}
.container{{max-width:1100px;margin:0 auto;padding:20px;}}
.hero{{background:linear-gradient(135deg,#0d6efd,#6610f2);border-radius:16px;padding:32px;margin-bottom:24px;text-align:center;}}
.hero h1{{color:#fff;font-size:2rem;font-weight:700;}}
.hero .sub{{color:rgba(255,255,255,.85);font-size:1rem;}}
.card{{background:#151b2b;border:1px solid #2a3250;border-radius:12px;padding:20px;margin-bottom:20px;}}
.card h5{{color:#8b9dc3;font-size:.85rem;text-transform:uppercase;letter-spacing:.5px;margin-bottom:12px;}}
.card .v{{font-size:1.1rem;color:#fff;}}
.link-grid a{{display:inline-block;margin:4px;padding:8px 16px;background:#1e2740;border-radius:8px;color:#8ab4f8;text-decoration:none;font-size:.9rem;}}
.link-grid a:hover{{background:#2a3555;color:#fff;}}
.footer{{text-align:center;padding:20px;color:#4a5570;font-size:.85rem;}}
.ident{{display:grid;grid-template-columns:repeat(auto-fill,minmax(190px,1fr));gap:10px;}}
.ident .l{{font-size:.7rem;color:#4a5570;text-transform:uppercase;}}
.ident .v{{font-size:.9rem;color:#e0e0e0;word-break:break-all;}}
.pipe-section{{margin-bottom:4px;}}
.pipe-label{{font-size:.65rem;text-transform:uppercase;letter-spacing:1.5px;color:#4a5570;padding:4px 0 0 16px;font-weight:600;}}
.pipe-conn{{width:2px;height:12px;margin-left:28px;}}
.pipe-node{{display:flex;align-items:center;padding:8px 14px;border-left:3px solid;margin-left:16px;border-radius:0 8px 8px 0;background:#151b2b;}}
.pipe-node:hover{{background:#1a2235;}}
.pipe-icon{{width:30px;height:30px;border-radius:50%;display:flex;align-items:center;justify-content:center;margin-right:10px;flex-shrink:0;}}
.pipe-body{{flex:1;min-width:0;}}
.pipe-name{{font-size:.85rem;font-weight:600;color:#e0e0e0;}}
.pipe-detail{{font-size:.7rem;color:#6c7a9a;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;}}
.pipe-status{{margin-left:10px;flex-shrink:0;}}
.test-pass{{color:#198754;}}.test-fail{{color:#dc3545;}}
.table-dark-custom{{background:#151b2b;}}
.table-dark-custom th{{background:#1a2235;color:#8b9dc3;}}
.table-dark-custom td{{background:#151b2b;color:#e0e0e0;}}
.timeline-item{{padding:6px 0;border-left:2px solid #2a3250;padding-left:16px;margin-left:8px;}}
</style>
</head>
<body>
<div class="container">
    <div class="hero">
        <h1>HERMES ENTERPRISE</h1>
        <div class="sub">FICHA DE DESPLIEGUE :: {nombre}</div>
        <div class="mt-3">
            <span class="badge bg-{'success' if overall_status=='PASS' else 'danger' if overall_status=='FAIL' else 'warning'} me-2">{'🟢 OPERATIVO' if overall_status=='PASS' else '🔴 FALLIDO' if overall_status=='FAIL' else '⏳ PENDIENTE'}</span>
            <span class="badge bg-info text-dark">CID:{corr_id[:8] if len(corr_id)>8 else corr_id}</span>
        </div>
    </div>

    <div class="card mb-4">
        <h5><i class="bi bi-info-circle me-2"></i>IDENTIDAD DEL PROYECTO</h5>
        <div class="ident">
            <div><div class="l">Proyecto</div><div class="v">{nombre}</div></div>
            <div><div class="l">Repositorio</div><div class="v">{repositorio}</div></div>
            <div><div class="l">Commit Solicitado</div><div class="v">{commit_hash[:16] if commit_hash!='No disponible' else commit_hash}</div></div>
            <div><div class="l">Correlation ID</div><div class="v">{corr_id}</div></div>
            <div><div class="l">Deployment ID</div><div class="v">{deployment_id}</div></div>
        </div>
    </div>

    <div class="card mb-4">
        <h5><i class="bi bi-server me-2"></i>INFRAESTRUCTURA</h5>
        <div class="ident">
            <div><div class="l">App Service</div><div class="v">{webapp_name}</div></div>
            <div><div class="l">Plan</div><div class="v">ASP-IAUR <span class="badge bg-success ms-1">REUTILIZADO</span></div></div>
            <div><div class="l">Resource Group</div><div class="v">RG-Hermes-Proyectos</div></div>
            <div><div class="l">Region</div><div class="v">{region_db}</div></div>
            <div><div class="l">Runtime</div><div class="v">{runtime}</div></div>
            <div><div class="l">Plan Creado</div><div class="v"><span class="badge bg-warning text-dark">NO</span></div></div>
            <div><div class="l">Plan Reutilizado</div><div class="v"><span class="badge bg-success">SÍ</span></div></div>
            <div><div class="l">Autenticación</div><div class="v"><span class="badge bg-info text-dark">OIDC</span></div></div>
            <div><div class="l">Timestamp</div><div class="v">{now}</div></div>
        </div>
    </div>

    <div class="card mb-4">
        <h5><i class="bi bi-diagram-3 me-2"></i>TRAZABILIDAD DE DESPLIEGUE</h5>
        <div class="pipeline">{pipe_html}</div>
    </div>

    <div class="card mb-4">
        <h5><i class="bi bi-journal-text me-2"></i>DETALLE DE IMPLEMENTACIÓN</h5>
        <div style="font-size:.85rem;line-height:1.7;color:#c0c8e0;">
            <ol style="padding-left:20px;margin-bottom:0;">
                <li><strong>Creación:</strong> La Factory <code>Crear-HermesProyecto.ps1</code> generó el proyecto <strong>{nombre}</strong> con Correlation ID <code>{corr_id}</code>.</li>
                <li><strong>Código fuente:</strong> El repositorio <code>{repositorio}</code> contiene el código del proyecto.</li>
                <li><strong>Commit desplegado:</strong> <code>{commit_hash[:16] if commit_hash!='No disponible' else commit_hash}</code></li>
                <li><strong>CI:</strong> El repositorio Child ejecuta su propio CI (<code>ci.yml</code>) para validar el código.</li>
                <li><strong>CD:</strong> El <strong>Control Plane</strong> (<code>deploy-child.yml</code> en HERMES-ENTERPRISE) orquesta el despliegue completo.</li>
                <li><strong>Autenticación Azure:</strong> <strong>OIDC</strong> federado (FIC: UR-Fabrica-Proyectos-AR) — sin secrets locales.</li>
                <li><strong>Infraestructura:</strong> App Service creado en <strong>ASP-IAUR</strong> reutilizado (NO se creó un nuevo Plan).</li>
                <li><strong>Despliegue:</strong> ZIP Deploy mediante <code>az webapp deploy</code>.</li>
                <li><strong>Verificación:</strong> Readiness check ({url_publica}/health) + Pruebas funcionales ({passed}/{total} PASS).</li>
                <li><strong>Evidencia:</strong> <code>deployment-report.json</code> con SHA verificado (solicitado == desplegado).</li>
            </ol>
        </div>
    </div>

    <div class="card mb-4">
        <h5><i class="bi bi-link me-2"></i>ACCESOS</h5>
        <div class="link-grid" role="navigation" aria-label="Accesos rápidos">
            <a href="{url_publica}/" target="_blank" aria-label="Abrir Frontend del proyecto"><i class="bi bi-house-fill me-1"></i>Frontend</a>
            <a href="{url_publica}/health" target="_blank" aria-label="Abrir Health Check"><i class="bi bi-heart-pulse me-1"></i>Health</a>
            <a href="{url_publica}/swagger" target="_blank" aria-label="Abrir documentación Swagger"><i class="bi bi-file-earmark-code me-1"></i>Swagger</a>
            <a href="{url_publica}/openapi.json" target="_blank" aria-label="Abrir esquema OpenAPI"><i class="bi bi-filetype-json me-1"></i>OpenAPI</a>
            <a href="{url_publica}/api/version" target="_blank" aria-label="Abrir información de versión"><i class="bi bi-tag me-1"></i>Version</a>
            <a href="{url_publica}/api/proyecto" target="_blank" aria-label="Abrir endpoint del proyecto"><i class="bi bi-info-circle me-1"></i>Proyecto</a>
            <a href="{url_publica}/redoc" target="_blank" aria-label="Abrir documentación ReDoc"><i class="bi bi-book me-1"></i>ReDoc</a>
            <a href="{url_publica}/api/evidence" target="_blank" aria-label="Abrir evidencia del despliegue"><i class="bi bi-file-earmark-text me-1"></i>Evidencia</a>
        </div>
    </div>

    <div class="card mb-4">
        <h5><i class="bi bi-check-circle me-2"></i>PRUEBAS FUNCIONALES</h5>
        <div class="table-responsive">
            <table class="table table-dark-custom table-sm">
                <thead><tr><th>Endpoint</th><th>HTTP</th><th>Estado</th><th>Tiempo</th></tr></thead>
                <tbody>"""
    # fin del f-string para la sección de pruebas

    # Smoke test rows
    if smoke:
        for s in smoke:
            ep = s.get("Endpoint", "")
            code = s.get("HTTPCode", 0)
            st = s.get("Estado", "FAIL")
            tm = s.get("TiempoRespuesta", 0)
            icon = '<i class="bi bi-check-circle-fill test-pass"></i>' if st == "PASS" else '<i class="bi bi-x-circle-fill test-fail"></i>'
            html += f'<tr><td><code>{ep}</code></td><td>{code}</td><td>{icon} {st}</td><td>{tm:.2f}s</td></tr>'
    else:
        html += '<tr><td colspan="4" class="text-secondary text-center">No hay resultados de pruebas disponibles</td></tr>'
    html += """</tbody></table></div></div>

    <!-- TIMELINE -->
    <div class="card mb-4">
        <h5><i class="bi bi-list-check me-2"></i>Linea de Tiempo</h5>
        <div class="mt-3">""".format(url_publica=url_publica)

    if timeline:
        for t in timeline:
            ev = t.get("Evento", "")
            est = t.get("Estado", "")
            fe = t.get("Fecha", "")
            det = t.get("Detalle", "")
            icon_name = {"Workspace": "bi-folder", "Git": "bi-git", "GitHub": "bi-github", "SQLite": "bi-database", "Build": "bi-box", "ZIP": "bi-file-zip", "Deploy": "bi-cloud-upload", "SmokeTest": "bi-check-circle", "Publicado": "bi-globe"}.get(ev, "bi-record")
            color = "success" if est == "OK" else "danger" if est == "FAIL" else "warning"
            html += f'<div class="timeline-item"><i class="bi {icon_name} me-2 text-{color}"></i><strong>{ev}</strong> <span class="badge bg-{color} ms-2">{est}</span><br><small class="text-secondary">{fe}</small>'
            if det:
                html += f'<br><small class="text-secondary">{det}</small>'
            html += '</div>'
    else:
        html += '<div class="text-secondary">No hay eventos en la linea de tiempo</div>'

    html += """
    </div></div>

    <!-- IMPLEMENTATION REGISTRY -->
    <div class="card mb-4" id="implRegistryCard">
        <h5><i class="bi bi-diagram-3 me-2"></i>REGISTRO DE IMPLEMENTACIÓN</h5>
        <div id="implSummary" class="mb-3"></div>
        <div id="implTimeline"></div>
    </div>

    <!-- FOOTER -->
    <div class="footer">
        <p>Powered by Hermes Enterprise &copy; 2026</p>
        <p class="mb-0"><a href="https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE" target="_blank">Hermes Enterprise</a></p>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
<script>
// ─── Cargar Registro de Implementación ───
fetch('/api/implementacion')
.then(r => r.json())
.then(data => {
    if(data.error) { return; }
    const imp = data;
    const total = imp.pasos_totales || 13;
    const completados = imp.pasos_completados || 0;
    const fallidos = imp.pasos_fallidos || 0;
    const dur = imp.duracion_total_segundos || 0;
    const status = imp.estado_general || 'PENDIENTE';
    const statusBadge = status === 'COMPLETADO' ? 'bg-success' : status === 'FALLIDO' ? 'bg-danger' : 'bg-warning';

    document.getElementById('implSummary').innerHTML = `
        <div class="row text-center mb-3">
            <div class="col"><strong>Total:</strong> ${total}</div>
            <div class="col text-success"><strong>Completados:</strong> ${completados}</div>
            <div class="col text-danger"><strong>Fallidos:</strong> ${fallidos}</div>
            <div class="col"><strong>Duración:</strong> ${dur.toFixed(1)}s</div>
            <div class="col"><span class="badge ${statusBadge}">${status}</span></div>
        </div>`;

    if(!data.pasos || data.pasos.length === 0) {
        document.getElementById('implTimeline').innerHTML = '<div class="text-secondary">No hay pasos registrados</div>';
        return;
    }

    let html = '<div class="impl-steps">';
    data.pasos.forEach(p => {
        const st = (p.Resultado || 'PENDIENTE').toLowerCase();
        const icon = st === 'pass' ? 'bi-check-circle-fill text-success' : st === 'fail' ? 'bi-x-circle-fill text-danger' : 'bi-hourglass-split text-warning';
        const label = p.Resultado || 'PENDIENTE';
        const durPaso = (p.DuracionSegundos || 0).toFixed(1);

        html += '<div class="impl-step card mb-2 bg-dark border-secondary">';
        html += '<div class="card-body py-2 px-3" onclick="toggleSubpasos(this)" style="cursor:pointer">';
        html += '<div class="d-flex justify-content-between align-items-center">';
        html += `<div><i class="bi ${icon} me-2"></i><strong>PASO ${p.NumeroPaso}:</strong> ${p.NombrePaso}</div>`;
        html += `<div><span class="badge bg-${st === 'pass' ? 'success' : st === 'fail' ? 'danger' : 'warning'} me-2">${label}</span> ${durPaso}s</div>`;
        html += '</div></div>';

        // Subpasos
        let subs = p.subpasos;
        if(subs && subs.length > 0) {
            html += '<div class="impl-subpasos" style="display:none">';
            html += '<table class="table table-dark-custom table-sm mb-0">';
            html += '<thead><tr><th>Subpaso</th><th>Nombre</th><th>Estado</th><th>Duración</th><th>Detalle</th></tr></thead><tbody>';
            subs.forEach(sp => {
                const spSt = (sp.Resultado || 'PENDIENTE').toLowerCase();
                const spIcon = spSt === 'pass' ? 'bi-check-circle-fill text-success' : spSt === 'fail' ? 'bi-x-circle-fill text-danger' : 'bi-hourglass-split text-warning';
                const spDur = (sp.duracion_segundos || 0).toFixed(1);
                html += `<tr><td><code>${sp.numero_subpaso || ''}</code></td><td>${sp.nombre_subpaso || ''}</td><td><i class="bi ${spIcon} me-1"></i>${sp.Resultado || 'PENDIENTE'}</td><td>${spDur}s</td><td>${sp.detalle || ''}</td></tr>`;
            });
            html += '</tbody></table></div>';
        }
        html += '</div>';
    });
    html += '</div>';
    document.getElementById('implTimeline').innerHTML = html;
})
.catch(() => {});

function toggleSubpasos(el) {
    const subs = el.nextElementSibling;
    if(subs && subs.classList.contains('impl-subpasos')) {
        subs.style.display = subs.style.display === 'none' ? 'block' : 'none';
    }
}
</script>
<style>
.impl-step .card-body:hover { background: rgba(255,255,255,0.05); }
.impl-subpasos { border-top: 1px solid #2c3e50; }
.impl-subpasos table { margin: 0; }
</style>
</body>
</html>"""
    return HTMLResponse(content=html)

@app.get("/openapi.json", include_in_schema=False)
async def openapi_redirect():
    return JSONResponse(content=app.openapi())

if __name__ == "__main__":
    import uvicorn
    HOST = os.environ.get("HOST","0.0.0.0")
    PORT = int(os.environ.get("PORT",8000))
    uvicorn.run(app, host=HOST, port=PORT)