import os, json, logging
from datetime import datetime, timezone
from pathlib import Path
from fastapi import FastAPI, Request
from fastapi.responses import HTMLResponse, JSONResponse
from fastapi.staticfiles import StaticFiles
from fastapi.templating import Jinja2Templates
from fastapi.middleware.cors import CORSMiddleware

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

def obtener_info_proyecto(corr_id: str) -> dict:
    rows = consultar_sqlite(f"SELECT * FROM Proyecto WHERE CorrelationId='{corr_id}'")
    if rows: return rows[0]
    return {"Nombre":"{{PROJECT_NAME}}","CorrelationId":corr_id,"Estado":"CREADO"}

def obtener_timeline(corr_id: str) -> list:
    return consultar_sqlite(f"SELECT * FROM Timeline WHERE CorrelationId='{corr_id}' ORDER BY Id ASC")

def obtener_smoke_results(corr_id: str) -> list:
    return consultar_sqlite(f"SELECT * FROM SmokeTestResults WHERE CorrelationId='{corr_id}'")

def obtener_bitacora(corr_id: str) -> list:
    return consultar_sqlite(f"SELECT * FROM BitacoraEventos WHERE CorrelationId='{corr_id}' ORDER BY Id DESC LIMIT 20")

@app.get("/health")
async def health():
    return {"status":"saludable","timestamp":datetime.now(timezone.utc).isoformat()}

@app.get("/api/version")
async def api_version():
    info = obtener_info_proyecto("{{CORRELATION_ID}}")
    return {"version":"1.0.0","proyecto":info.get("Nombre","{{PROJECT_NAME}}"),"correlationId":"{{CORRELATION_ID}}"}

@app.get("/api/proyecto")
async def api_proyecto():
    return obtener_info_proyecto("{{CORRELATION_ID}}")

@app.get("/api/workspace")
async def api_workspace():
    p = obtener_info_proyecto("{{CORRELATION_ID}}")
    workspace = Path(PROJECT_ROOT).parent / (p.get("Nombre","{{PROJECT_NAME}}") + ".code-workspace")
    return {"workspace":str(workspace),"exists":workspace.exists()}

@app.get("/api/git")
async def api_git():
    git_dir = PROJECT_ROOT.parent / ".git"
    return {"git_init":git_dir.exists(),"branch":"main"}

@app.get("/api/github")
async def api_github():
    info = obtener_info_proyecto("{{CORRELATION_ID}}")
    return {"repo":info.get("Repositorio",""),"status":info.get("EstadoGitHub","")}

@app.get("/api/sqlite")
async def api_sqlite():
    return {"db_path":SQLITE_DB,"exists":Path(SQLITE_DB).exists()}

@app.get("/api/azure")
async def api_azure():
    info = obtener_info_proyecto("{{CORRELATION_ID}}")
    return {"webapp":"{{WEBAPP_NAME}}","url":"https://{{WEBAPP_NAME}}.azurewebsites.net","status":info.get("EstadoAzure","")}

@app.get("/api/despliegue")
async def api_despliegue():
    info = obtener_info_proyecto("{{CORRELATION_ID}}")
    return {"estado":info.get("Estado",""),"total_commits":0,"total_deploys":0,"total_corrections":0}

@app.get("/", response_class=HTMLResponse)
async def landing(request: Request):
    info = obtener_info_proyecto("{{CORRELATION_ID}}")
    timeline = obtener_timeline("{{CORRELATION_ID}}")
    smoke = obtener_smoke_results("{{CORRELATION_ID}}")
    bitacora = obtener_bitacora("{{CORRELATION_ID}}")

    nombre = info.get("Nombre","{{PROJECT_NAME}}")
    estado = info.get("Estado","CREADO")
    repositorio = info.get("Repositorio","")
    commit = info.get("CommitHash","")
    branch = info.get("Branch","main")
    url_publica = info.get("UrlPublica","https://{{WEBAPP_NAME}}.azurewebsites.net")
    version = info.get("Version","1.0.0")
    correlation = info.get("CorrelationId","{{CORRELATION_ID}}")
    t_build = info.get("TiempoBuild",0)
    t_deploy = info.get("TiempoDeploy",0)
    t_smoke = info.get("TiempoSmokeTest",0)
    estado_azure = info.get("EstadoAzure","PENDIENTE")
    estado_github = info.get("EstadoGitHub","PENDIENTE")
    estado_ci = info.get("EstadoCI","PENDIENTE")

    html = f"""<!DOCTYPE html>
<html lang="es" data-bs-theme="dark">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width,initial-scale=1.0">
<title>{nombre}</title>
<link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/css/bootstrap.min.css" rel="stylesheet">
<link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css">
<style>
:root {{--proj-primary:#0d6efd;--proj-accent:#6f42c1;--proj-success:#198754;--proj-warning:#ffc107;--proj-danger:#dc3545}}
body {{background:#0a0e1a;color:#e0e0e0;font-family:'Segoe UI',sans-serif}}
.hero-section {{background:linear-gradient(135deg,#0d6efd 0%,#6f42c1 100%);padding:3rem 0;border-radius:0 0 2rem 2rem}}
.hero-title {{font-size:2.5rem;font-weight:800;letter-spacing:-1px}}
.stat-card {{background:rgba(255,255,255,0.05);border:1px solid rgba(255,255,255,0.1);border-radius:1rem;padding:1.5rem;backdrop-filter:blur(10px)}}
.timeline-item {{border-left:3px solid #0d6efd;padding-left:1.5rem;margin-bottom:1.5rem;position:relative}}
.timeline-item::before {{content:'';width:12px;height:12px;background:#0d6efd;border-radius:50%;position:absolute;left:-7px;top:4px}}
.footer {{text-align:center;padding:2rem;color:rgba(255,255,255,0.4);font-size:0.85rem}}
.badge-custom {{font-size:0.75rem;padding:0.35rem 0.7rem}}
</style>
</head>
<body>

<div class="hero-section text-white text-center">
    <div class="container">
        <h1 class="hero-title"><i class="bi bi-rocket-takeoff me-2"></i>{nombre}</h1>
        <p class="lead opacity-75">Proyecto generado automaticamente</p>
        <div class="mt-3">
            <span class="badge bg-light text-dark me-2">v{version}</span>
            <span class="badge bg-{'success' if estado=='PUBLICADO' else 'warning'} me-2">{estado}</span>
            <span class="badge bg-info text-dark me-2">CID:{correlation[:8]}</span>
        </div>
    </div>
</div>

<div class="container mt-4">
    <div class="row g-3 mb-4">
        <div class="col-md-3"><div class="stat-card text-center"><i class="bi bi-cloud-arrow-up fs-3 text-primary"></i><h5 class="mt-2 mb-0">{estado_azure}</h5><small class="text-secondary">Azure</small></div></div>
        <div class="col-md-3"><div class="stat-card text-center"><i class="bi bi-github fs-3 text-secondary"></i><h5 class="mt-2 mb-0">{estado_github}</h5><small class="text-secondary">GitHub</small></div></div>
        <div class="col-md-3"><div class="stat-card text-center"><i class="bi bi-arrow-repeat fs-3 text-success"></i><h5 class="mt-2 mb-0">{estado_ci}</h5><small class="text-secondary">CI/CD</small></div></div>
        <div class="col-md-3"><div class="stat-card text-center"><i class="bi bi-clock fs-3 text-warning"></i><h5 class="mt-2 mb-0">{t_build}s</h5><small class="text-secondary">Build</small></div></div>
    </div>

    <div class="row g-3 mb-4">
        <div class="col-md-6"><div class="stat-card"><h5><i class="bi bi-link-45deg me-2"></i>URL Publica</h5><a href="{url_publica}" target="_blank" class="text-decoration-none">{url_publica}</a></div></div>
        <div class="col-md-6"><div class="stat-card"><h5><i class="bi bi-diagram-3 me-2"></i>Repositorio</h5><span>{repositorio if repositorio else 'No configurado'}</span></div></div>
    </div>

    <div class="stat-card mb-4">
        <h5><i class="bi bi-list-check me-2"></i>Linea de Tiempo</h5>
        <div class="mt-3">
"""
    for t in timeline:
        ev = t.get("Evento","")
        est = t.get("Estado","")
        fe = t.get("Fecha","")
        det = t.get("Detalle","")
        icon = {"Workspace":"bi-folder","Git":"bi-git","GitHub":"bi-github","SQLite":"bi-database","Build":"bi-box","ZIP":"bi-file-zip","Deploy":"bi-cloud-upload","SmokeTest":"bi-check-circle","Publicado":"bi-globe"}.get(ev,"bi-record")
        color = "success" if est=="OK" else "danger" if est=="FAIL" else "warning"
        html += f'<div class="timeline-item"><i class="bi {icon} me-2 text-{color}"></i><strong>{ev}</strong><span class="badge bg-{color} ms-2 badge-custom">{est}</span><br><small class="text-secondary">{fe}</small>'
        if det: html += f'<br><small class="text-secondary">{det}</small>'
        html += '</div>'

    html += """
        </div>
    </div>

    <div class="stat-card mb-4">
        <h5><i class="bi bi-bar-chart me-2"></i>Metricas de Despliegue</h5>
        <div class="row mt-3">
            <div class="col-4 text-center"><h3 class="text-primary">{:.1f}s</h3><small class="text-secondary">Build</small></div>
            <div class="col-4 text-center"><h3 class="text-success">{:.1f}s</h3><small class="text-secondary">Deploy</small></div>
            <div class="col-4 text-center"><h3 class="text-info">{:.1f}s</h3><small class="text-secondary">Smoke Test</small></div>
        </div>
    </div>

""".format(t_build, t_deploy, t_smoke)

    if bitacora:
        html += '<div class="stat-card mb-4"><h5><i class="bi bi-journal-text me-2"></i>Bitacora de Eventos</h5><div class="table-responsive mt-2"><table class="table table-dark table-striped table-sm"><thead><tr><th>Fecha</th><th>Paso</th><th>Estado</th><th>Mensaje</th></tr></thead><tbody>'
        for b in bitacora[:10]:
            html += f'<tr><td>{b.get("Fecha","")} {b.get("Hora","")}</td><td>{b.get("Paso","")}</td><td><span class="badge bg-{"success" if b.get("Estado")=="OK" else "danger"}">{b.get("Estado","")}</span></td><td>{b.get("Mensaje","")}</td></tr>'
        html += '</tbody></table></div></div>'

    if smoke:
        html += '<div class="stat-card mb-4"><h5><i class="bi bi-shield-check me-2"></i>Smoke Test</h5><div class="table-responsive mt-2"><table class="table table-dark table-striped table-sm"><thead><tr><th>Endpoint</th><th>HTTP</th><th>Estado</th><th>Tiempo</th></tr></thead><tbody>'
        for s in smoke:
            color = "success" if s.get("Estado")=="PASS" else "danger"
            html += f'<tr><td>{s.get("Endpoint","")}</td><td>{s.get("HTTPCode","")}</td><td><span class="badge bg-{color}">{s.get("Estado","")}</span></td><td>{s.get("TiempoRespuesta",0):.2f}s</td></tr>'
        html += '</tbody></table></div></div>'

    html += """
    <div class="footer">
        <p>Powered by Hermes Enterprise &copy; {{YEAR}}</p>
    </div>
</div>
<script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.2/dist/js/bootstrap.bundle.min.js"></script>
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