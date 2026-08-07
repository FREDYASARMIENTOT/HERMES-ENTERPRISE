"""
main.py — Punto de entrada del Backend FastAPI de Hermes Enterprise

Este archivo inicializa la aplicacion FastAPI, configura el Middleware,
registra los routers de la API Publica y expone el servidor web.

Modo de ejecucion directa:
    python -c "import Hermes.Web.backend.main"
    
    # O desde uvicorn:
    # uvicorn Hermes.Web.backend.main:app --host 0.0.0.0 --port 8000
"""

import os
import sys
import json
import uuid
import time
import logging
import subprocess
import platform
import importlib.util
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Dict, Any, List

# ──────────────────────────────────────────────────────────────
# Resolver Hermes.Web como paquete importable
# ──────────────────────────────────────────────────────────────
# Python no puede importar "Hermes.Web" como submodulo de "Hermes"
# porque Hermes.Web/ tiene punto en el nombre del directorio.
# 
# Solucion: Agregamos la raiz del proyecto a sys.path para que
# "Hermes.Web" sea detectable como paquete de nivel superior.
# Ademas, registramos un loader personalizado que resuelve
# Hermes.Web.xxx -> ./Hermes.Web/xxx
# ──────────────────────────────────────────────────────────────

_ACTUAL_DIR = Path(__file__).resolve().parent       # Hermes.Web/backend/
_HERMES_WEB_DIR = _ACTUAL_DIR.parent                # Hermes.Web/
_PROJECT_ROOT = _HERMES_WEB_DIR.parent              # d:\HERMES-ENTERPRISE

# Agregar raiz del proyecto a sys.path
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))


class HermesWebPackageLoader(importlib.abc.Loader):
    """
    Loader personalizado que permite importar Hermes.Web.xxx
    resolviendo ./Hermes.Web/xxx como modulo.
    """
    def __init__(self, fullname: str, path: Path):
        self.fullname = fullname
        self.path = path
    
    def create_module(self, spec):
        return None  # Usar semantica default
    
    def exec_module(self, module):
        spec = importlib.util.spec_from_file_location(self.fullname, str(self.path))
        if spec and spec.loader:
            spec.loader.exec_module(module)


class HermesWebFinder(importlib.abc.MetaPathFinder):
    """
    Finder que permite importar Hermes.Web.xxx usando archivos
    dentro del directorio ./Hermes.Web/
    """
    def __init__(self, hermes_web_dir: Path):
        self._hermes_web_dir = hermes_web_dir
        self._hermes_web_str = "Hermes.Web"
    
    def find_spec(self, fullname, path=None, target=None):
        # Solo procesar fullnames que comiencen con Hermes.Web
        if fullname == self._hermes_web_str:
            # El paquete raiz Hermes.Web
            init_path = self._hermes_web_dir / "__init__.py"
            if init_path.exists():
                loader = importlib.machinery.SourceFileLoader(fullname, str(init_path))
                spec = importlib.machinery.ModuleSpec(
                    fullname, 
                    loader, 
                    origin=str(init_path),
                    is_package=True
                )
                spec.submodule_search_locations = [str(self._hermes_web_dir)]
                return spec
            return None
        
        if fullname.startswith(self._hermes_web_str + "."):
            # Submodulo: Hermes.Web.backend.main -> Hermes.Web/backend/main.py
            relative = fullname[len(self._hermes_web_str) + 1:]  # "backend.main"
            parts = relative.split(".")
            
            # Construir la ruta del archivo
            sub_path = self._hermes_web_dir.joinpath(*parts)
            
            # Probar como archivo .py
            py_file = sub_path.with_suffix(".py")
            if py_file.exists():
                loader = importlib.machinery.SourceFileLoader(fullname, str(py_file))
                return importlib.machinery.ModuleSpec(
                    fullname, loader, origin=str(py_file)
                )
            
            # Probar como paquete (directorio con __init__.py)
            init_file = sub_path / "__init__.py"
            if init_file.exists():
                loader = importlib.machinery.SourceFileLoader(fullname, str(init_file))
                spec = importlib.machinery.ModuleSpec(
                    fullname, loader, origin=str(init_file), is_package=True
                )
                spec.submodule_search_locations = [str(sub_path)]
                return spec
        
        return None


# Registrar el finder personalizado
sys.meta_path.insert(0, HermesWebFinder(_HERMES_WEB_DIR))
logger_init = logging.getLogger("Hermes.Web.setup")
logger_init.info(f"Finder registrado para Hermes.Web en: {_HERMES_WEB_DIR}")
logger_init.info(f"Raiz del proyecto en sys.path: {_PROJECT_ROOT}")

# ──────────────────────────────────────────────────────────────
# Configuracion de logging global para la aplicacion
# ──────────────────────────────────────────────────────────────
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)-8s | %(name)s | %(message)s",
    datefmt="%Y-%m-%dT%H:%M:%S%z"
)
logger = logging.getLogger("Hermes.Web")
logger.info("Inicializando Hermes.Web Backend...")

# ──────────────────────────────────────────────────────────────
# Importaciones de terceros (FastAPI y utilidades)
# ──────────────────────────────────────────────────────────────
try:
    from fastapi import FastAPI, Request, Response, HTTPException, Depends
    from fastapi.responses import JSONResponse, HTMLResponse
    from fastapi.staticfiles import StaticFiles
    from fastapi.templating import Jinja2Templates
    from fastapi.middleware.cors import CORSMiddleware
    from fastapi.middleware.gzip import GZipMiddleware
    from pydantic import BaseModel, Field
except ImportError as error_importacion:
    logger.error(
        "Error al importar dependencias de FastAPI. "
        "Ejecute: pip install fastapi uvicorn jinja2 pydantic httpx"
    )
    logger.error(f"Detalles del error: {error_importacion}")
    sys.exit(1)

# ──────────────────────────────────────────────────────────────
# Importaciones locales del modulo Hermes.Web
# ──────────────────────────────────────────────────────────────
try:
    from Hermes.Web.middleware.middleware_correlation import CorrelationIdMiddleware
    from Hermes.Web.middleware.middleware_logging import LoggingMiddleware
    from Hermes.Web.middleware.middleware_timing import TimingMiddleware
    from Hermes.Web.middleware.middleware_auditoria import AuditoriaMiddleware
    from Hermes.Web.middleware.middleware_errores import ErrorHandlingMiddleware
    from Hermes.Web.middleware.middleware_compresion import CompressionMiddleware
    MIDDLEWARE_DISPONIBLE = True
    logger.info("Middleware Hermes.Web cargado exitosamente.")
except ImportError as error_middleware:
    MIDDLEWARE_DISPONIBLE = False
    logger.warning(
        f"Middleware Hermes.Web no disponible: {error_middleware}. "
        "Se usara configuracion por defecto."
    )

try:
    from Hermes.Web.backend.servicio_datos_proyecto import ServicioDatosProyecto
    SERVICIO_DATOS_DISPONIBLE = True
    logger.info("ServicioDatosProyecto cargado exitosamente.")
except ImportError as error_servicio:
    SERVICIO_DATOS_DISPONIBLE = False
    logger.warning(
        f"ServicioDatosProyecto no disponible: {error_servicio}. "
        "Se usara implementacion por defecto."
    )

# ──────────────────────────────────────────────────────────────
# Determinacion de rutas base del proyecto Hermes Enterprise
# ──────────────────────────────────────────────────────────────

def obtener_ruta_raiz_hermes() -> Path:
    """
    Obtiene la ruta raiz del proyecto Hermes Enterprise.
    """
    ruta_actual = Path(__file__).resolve().parent.parent.parent  # Hermes.Web/
    # Buscar hacia arriba hasta encontrar raiz del proyecto
    for padre in [ruta_actual] + list(ruta_actual.parents):
        if (padre / "Hermes.config.json").exists() or (padre / "motor").is_dir():
            return padre
    # Si no se encuentra, usar el directorio actual
    return Path.cwd()

# Ruta base del proyecto Hermes Enterprise
RUTA_HERMES: Path = obtener_ruta_raiz_hermes()
RUTA_CONFIG: Path = RUTA_HERMES / "config"
RUTA_HERMES_WEB: Path = RUTA_HERMES / "Hermes.Web"
RUTA_TEMPLATES: Path = RUTA_HERMES_WEB / "templates"
RUTA_STATIC: Path = RUTA_HERMES_WEB / "static"
RUTA_MOTOR: Path = RUTA_HERMES / "motor"
RUTA_MODULO_COMMANDS: Path = RUTA_MOTOR / "kernel" / "Module" / "Hermes.Commands"

# ──────────────────────────────────────────────────────────────
# Configuracion de la aplicacion FastAPI
# ──────────────────────────────────────────────────────────────

DESCRIPCION_API = """
# API Publica de Hermes Enterprise

Bienvenido a la API REST oficial de **Hermes Enterprise**.

Esta API proporciona acceso completo a todas las funcionalidades del sistema:

## Endpoints Disponibles

| Recurso | Descripcion |
|---------|-------------|
| `/api/version` | Version de Hermes Enterprise y sus componentes |
| `/api/proyecto` | Estado y creacion de proyectos Hermes |
| `/api/workspace` | Gestion de workspaces de VS Code |
| `/api/git` | Estado del repositorio Git |
| `/api/github` | Estado del repositorio GitHub remoto |
| `/api/entorno` | Estado del entorno Python |
| `/api/bootstrap` | Estado del proceso Bootstrap |
| `/api/telemetria` | Metricas de telemetria y observabilidad |
| `/api/azure` | Configuracion y estado de Azure |
| `/api/sqlite` | Estado de la base de datos SQLite |
| `/api/despliegue` | Estado del despliegue y release |
"""

# Creacion de la aplicacion FastAPI
app = FastAPI(
    title="Hermes Enterprise - API Publica",
    description=DESCRIPCION_API,
    version="2.0.0",
    docs_url="/swagger",
    redoc_url="/redoc",
    openapi_url="/openapi.json",
    contact={
        "name": "Equipo Hermes Enterprise",
        "url": "https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE",
    },
    license_info={
        "name": "MIT",
        "url": "https://opensource.org/licenses/MIT",
    },
)

# ──────────────────────────────────────────────────────────────
# Configuracion de CORS
# ──────────────────────────────────────────────────────────────
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ──────────────────────────────────────────────────────────────
# Configuracion de Middleware personalizado
# ──────────────────────────────────────────────────────────────

if MIDDLEWARE_DISPONIBLE:
    app.add_middleware(CorrelationIdMiddleware)
    app.add_middleware(LoggingMiddleware)
    app.add_middleware(TimingMiddleware)
    app.add_middleware(AuditoriaMiddleware)
    app.add_middleware(ErrorHandlingMiddleware)
    app.add_middleware(CompressionMiddleware)
    logger.info("Middleware Hermes.Web registrado en la aplicacion FastAPI.")
else:
    app.add_middleware(GZipMiddleware, minimum_size=1000)
    logger.info("Middleware por defecto (GZip) registrado.")

# ──────────────────────────────────────────────────────────────
# Configuracion de archivos estaticos y plantillas Jinja2
# ──────────────────────────────────────────────────────────────

if RUTA_TEMPLATES.exists():
    # Jinja2 3.1.x LRUCache bug: cache key (name, globals) where globals is a dict -> unhashable
    # Solucion: usar cache_size=0 para deshabilitar cache o usar Cache passthrough.
    # Usamos Environment con FileSystemLoader y cache_size=0 para evitar el bug.
    from jinja2 import Environment, FileSystemLoader
    _jinja_env = Environment(
        loader=FileSystemLoader(str(RUTA_TEMPLATES)),
        auto_reload=False,
        cache_size=0
    )
    templates = Jinja2Templates(env=_jinja_env)
    logger.info(f"Templates Jinja2 configurados desde: {RUTA_TEMPLATES}")
else:
    templates = None
    logger.warning(f"Directorio de templates no encontrado: {RUTA_TEMPLATES}")

if RUTA_STATIC.exists():
    app.mount("/static", StaticFiles(directory=str(RUTA_STATIC)), name="static")
    logger.info(f"Archivos estaticos servidos desde: {RUTA_STATIC}")
else:
    logger.warning(f"Directorio static no encontrado: {RUTA_STATIC}")

# ──────────────────────────────────────────────────────────────
# Inicializacion del ServicioDatosProyecto
# ──────────────────────────────────────────────────────────────

if SERVICIO_DATOS_DISPONIBLE:
    servicio_datos_proyecto = ServicioDatosProyecto(
        ruta_raiz_hermes=str(RUTA_HERMES),
        ruta_modulo_commands=str(RUTA_MODULO_COMMANDS)
    )
    logger.info("ServicioDatosProyecto inicializado correctamente.")
else:
    servicio_datos_proyecto = None
    logger.warning("ServicioDatosProyecto no disponible. Usando implementacion simulada.")

# ──────────────────────────────────────────────────────────────
# Importacion y registro de los routers de la API Publica
# ──────────────────────────────────────────────────────────────
# Estrategia: cargar modulos via importlib.util desde las rutas
# directas a los archivos. Esto evita depender del MetaPathFinder
# (HermesWebFinder) que falla en Azure Linux.
#
# Los modulos se almacenan en sys.modules para que las referencias
# internas entre modulos funcionen correctamente.
# ──────────────────────────────────────────────────────────────

_API_DIR = _HERMES_WEB_DIR / "api"

_router_modules = [
    ("version", "Version"),
    ("proyecto", "Proyecto"),
    ("workspace", "Workspace"),
    ("git", "Git"),
    ("github", "GitHub"),
    ("entorno", "Entorno"),
    ("bootstrap", "Bootstrap"),
    ("telemetria", "Telemetria"),
    ("azure", "Azure"),
    ("sqlite", "SQLite"),
    ("despliegue", "Despliegue"),
]

# Cargar __init__.py de api/ primero si existe
_api_init = _API_DIR / "__init__.py"
if _api_init.exists():
    _spec = importlib.util.spec_from_file_location("Hermes.Web.api", str(_api_init))
    if _spec and _spec.loader:
        _mod_api = importlib.util.module_from_spec(_spec)
        sys.modules["Hermes.Web.api"] = _mod_api
        _spec.loader.exec_module(_mod_api)

for _mod_name, _tag in _router_modules:
    _router_obj = None
    _module_fullname = f"Hermes.Web.api.api_{_mod_name}"
    _file_path = _API_DIR / f"api_{_mod_name}.py"
    
    if _file_path.exists():
        try:
            _spec = importlib.util.spec_from_file_location(_module_fullname, str(_file_path))
            if _spec and _spec.loader:
                _mod = importlib.util.module_from_spec(_spec)
                sys.modules[_module_fullname] = _mod
                _spec.loader.exec_module(_mod)
                _router_obj = getattr(_mod, "router", None)
        except Exception as _import_err:
            logger.warning(f"Router /api/{_mod_name} error: {_import_err}")
            _router_obj = None
    
    if _router_obj is not None:
        app.include_router(_router_obj, prefix="/api", tags=[_tag])
        logger.info(f"Router /api/{_mod_name} registrado.")
    else:
        logger.warning(f"Router /api/{_mod_name} no disponible.")

# ──────────────────────────────────────────────────────────────
# Funcion auxiliar para ejecutar comandos PowerShell
# ──────────────────────────────────────────────────────────────

def ejecutar_comando_hermes(
    nombre_comando: str,
    argumentos: Optional[Dict[str, Any]] = None,
    timeout_segundos: int = 60
) -> Dict[str, Any]:
    """Ejecuta un comando de Hermes.Commands a traves de PowerShell."""
    tiempo_inicio = time.time()
    resultado = {
        "exito": False,
        "datos": None,
        "error": None,
        "comando": nombre_comando,
        "duracion_ms": 0.0
    }

    try:
        ruta_modulo = RUTA_MODULO_COMMANDS
        comando_powershell = (
            f"Import-Module '{ruta_modulo}' -Force; "
            f"{nombre_comando}"
        )

        if argumentos:
            for clave, valor in argumentos.items():
                comando_powershell += f" -{clave} '{valor}'"

        comando_powershell += " | ConvertTo-Json -Compress"

        proceso = subprocess.run(
            ["powershell", "-NoProfile", "-Command", comando_powershell],
            capture_output=True,
            text=True,
            timeout=timeout_segundos,
            cwd=str(RUTA_HERMES)
        )

        if proceso.returncode == 0 and proceso.stdout.strip():
            try:
                datos_json = json.loads(proceso.stdout.strip())
                resultado["datos"] = datos_json
                resultado["exito"] = True
            except json.JSONDecodeError:
                resultado["datos"] = proceso.stdout.strip()
                resultado["exito"] = True
        else:
            error_stderr = proceso.stderr.strip() if proceso.stderr else ""
            error_stdout = proceso.stdout.strip() if proceso.stdout else ""
            resultado["error"] = error_stderr or error_stdout or "Comando sin salida"
            resultado["exito"] = False

    except subprocess.TimeoutExpired:
        resultado["error"] = (
            f"El comando '{nombre_comando}' excedio el tiempo limite "
            f"de {timeout_segundos} segundos."
        )
    except FileNotFoundError:
        resultado["error"] = (
            "PowerShell no esta disponible en el sistema. "
            "Hermes Enterprise requiere PowerShell para funcionar."
        )
    except Exception as error_general:
        resultado["error"] = f"Error inesperado: {str(error_general)}"

    resultado["duracion_ms"] = round((time.time() - tiempo_inicio) * 1000, 2)
    return resultado


# ──────────────────────────────────────────────────────────────
# Ruta principal: Portal Web (Frontend)
# ──────────────────────────────────────────────────────────────

@app.get("/", response_class=HTMLResponse, tags=["Portal"])
async def raiz_portal_web(request: Request):
    """Renderiza la pagina principal del Portal Web de Hermes Enterprise."""
    if templates:
        return templates.TemplateResponse(
            request,
            "index.html",
            {
                "request": request,
                "titulo": "Hermes Enterprise - Portal Web Canonico",
                "version": "2.0.0",
                "anio_actual": datetime.now().year
            }
        )
    else:
        return HTMLResponse(content="""
        <!DOCTYPE html>
        <html lang="es">
        <head>
            <meta charset="UTF-8">
            <title>Hermes Enterprise - Portal Web</title>
        </head>
        <body>
            <h1>Hermes Enterprise</h1>
            <p>Portal Web - Backend operativo</p>
            <p>API disponible en <a href="/swagger">/swagger</a></p>
        </body>
        </html>
        """)


# ──────────────────────────────────────────────────────────────
# Ruta de salud (health check)
# ──────────────────────────────────────────────────────────────

@app.get("/health", tags=["Salud"])
async def health_check():
    """Endpoint de verificacion de salud para Azure App Service."""
    return {
        "estado": "saludable",
        "aplicacion": "Hermes Enterprise Web",
        "version": "2.0.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "python_version": platform.python_version(),
        "plataforma": platform.platform(),
        "raiz_proyecto": str(RUTA_HERMES),
        "servicio_datos_disponible": SERVICIO_DATOS_DISPONIBLE,
        "middleware_disponible": MIDDLEWARE_DISPONIBLE
    }


# ──────────────────────────────────────────────────────────────
# Manejador de eventos de inicio y cierre
# ──────────────────────────────────────────────────────────────

@app.on_event("startup")
async def evento_inicio_aplicacion():
    """Evento que se ejecuta cuando la aplicacion FastAPI inicia."""
    logger.info("=" * 60)
    logger.info("Hermes Enterprise Web - Iniciando...")
    logger.info("=" * 60)
    logger.info(f"Python: {platform.python_version()}")
    logger.info(f"Plataforma: {platform.platform()}")
    logger.info(f"Raiz del proyecto: {RUTA_HERMES}")
    logger.info(f"Directorio de templates: {RUTA_TEMPLATES}")
    logger.info(f"Directorio static: {RUTA_STATIC}")
    logger.info(f"Directorio commands: {RUTA_MODULO_COMMANDS}")
    logger.info(f"ServicioDatos disponible: {SERVICIO_DATOS_DISPONIBLE}")
    logger.info(f"Middleware disponible: {MIDDLEWARE_DISPONIBLE}")
    logger.info("=" * 60)


@app.on_event("shutdown")
async def evento_cierre_aplicacion():
    """Evento que se ejecuta cuando la aplicacion FastAPI se detiene."""
    logger.info("Hermes Enterprise Web - Deteniendo servidor...")


# ──────────────────────────────────────────────────────────────
# Punto de entrada principal
# ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    import uvicorn

    HOST = os.environ.get("HERMES_WEB_HOST", "0.0.0.0")
    PORT = int(os.environ.get("HERMES_WEB_PORT", "8000"))
    LOG_LEVEL = os.environ.get("HERMES_WEB_LOG_LEVEL", "info")
    RELOAD = os.environ.get("HERMES_WEB_RELOAD", "false").lower() == "true"

    logger.info(f"Iniciando servidor uvicorn en {HOST}:{PORT}")
    logger.info(f"Documentacion API: http://{HOST}:{PORT}/swagger")
    logger.info(f"Portal Web: http://{HOST}:{PORT}/")

    uvicorn.run(
        "Hermes.Web.backend.main:app",
        host=HOST,
        port=PORT,
        log_level=LOG_LEVEL,
        reload=RELOAD
    )