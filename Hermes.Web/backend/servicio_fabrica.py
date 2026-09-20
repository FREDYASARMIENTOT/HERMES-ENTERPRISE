"""
====================================================================
servicio_fabrica.py — Servicio de Fábrica de Proyectos Child
====================================================================

Capa de dominio para la creación y seguimiento de proyectos Child.

Arquitectura:
    Portal (FastAPI) → ServicioFabrica → SQLite
                                        → Factory (PowerShell subprocess local)
                                        → GitHub API (repository_dispatch remoto)

Principios:
    - Único punto de entrada para solicitudes de proyectos
    - Almacenamiento persistente en SQLite
    - Generación de correlation_id y deployment_id
    - Estados: SOLICITADO -> CREANDO -> PUBLICANDO -> CI_EN_PROGRESO
              -> DESPLEGANDO -> VALIDANDO -> COMPLETADO / FALLIDO
    - Trazabilidad completa con 13 pasos canónicos (RC87)
====================================================================
"""

import os
import sys
import json
import uuid
import time
import logging
import sqlite3
import subprocess
import asyncio
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional, Dict, Any, List, Union

from Hermes.Web.backend.event_broker import obtener_broker

logger = logging.getLogger("Hermes.Web.ServicioFabrica")

# ──────────────────────────────────────────────────────────────
# Constantes
# ──────────────────────────────────────────────────────────────

ESTADOS_PROYECTO = [
    "SOLICITADO", "CREANDO", "PUBLICANDO", "CI_EN_PROGRESO",
    "DESPLEGANDO", "VALIDANDO", "COMPLETADO", "FALLIDO"
]

# 13 pasos canónicos del flujo Factory -> GitHub -> Control Plane -> Azure
PASOS_CANONICOS = [
    {"numero": 1,  "nombre": "SOLICITUD",       "descripcion": "Registro de solicitud de proyecto"},
    {"numero": 2,  "nombre": "FACTORY",         "descripcion": "Disparo de Factory Runner remoto (GitHub Actions)"},
    {"numero": 3,  "nombre": "GITHUB",          "descripcion": "Creación de repositorio y push"},
    {"numero": 4,  "nombre": "CI CHILD",        "descripcion": "GitHub Actions CI del Child"},
    {"numero": 5,  "nombre": "CONTROL PLANE",   "descripcion": "Orquestación de despliegue"},
    {"numero": 6,  "nombre": "AUTENTICACIÓN",   "descripcion": "OIDC / FIC"},
    {"numero": 7,  "nombre": "AZURE",           "descripcion": "Aprovisionamiento en plan seleccionado por el usuario"},
    {"numero": 8,  "nombre": "DEPLOY",          "descripcion": "ZIP Deploy a Web App"},
    {"numero": 9,  "nombre": "READINESS",       "descripcion": "Health check del Child"},
    {"numero": 10, "nombre": "PRUEBAS FUNC.",   "descripcion": "Pruebas funcionales de endpoints"},
    {"numero": 11, "nombre": "EVIDENCIA",       "descripcion": "Generación de deployment-report"},
    {"numero": 12, "nombre": "PUBLICACIÓN",     "descripcion": "Publicación y notificación"},
    {"numero": 13, "nombre": "NAVEGADOR",       "descripcion": "Child accesible en navegador"}
]


def _generar_id() -> str:
    """Genera un UUID único para correlation_id o deployment_id."""
    return uuid.uuid4().hex[:16].upper()


def _ahora() -> str:
    """Devuelve timestamp ISO 8601 en UTC."""
    return datetime.now(timezone.utc).isoformat()


def _ruta_db_por_defecto() -> str:
    """Determina la ruta a la base de datos SQLite del Portal."""
    env_path = os.environ.get("HERMES_DB_PATH")
    if env_path:
        return env_path
    raiz = Path(__file__).resolve().parent.parent  # Hermes.Web/
    ruta_data = raiz / "data"
    if not ruta_data.exists():
        ruta_data.mkdir(parents=True, exist_ok=True)
    return str(ruta_data / "proyecto.db")


# ═══════════════════════════════════════════════════════════════
# Clase SolicitudProyecto
# ═══════════════════════════════════════════════════════════════

class SolicitudProyecto:
    """
    Representa una solicitud de creación de proyecto Child.

    Atributos:
        id, nombre_proyecto, descripcion, repositorio, web_app
        estado, correlation_id, deployment_id, commit_sha
        repo_url, web_app_url, pasos (13 pasos canónicos)
        fecha_solicitud, fecha_actualizacion, resultado, error
        app_service_plan_id, app_service_plan_name, app_service_plan_resource_group
        repository_url, commit_url, visibility (GitHub)
        factory_run_id, factory_run_url, factory_status, factory_duration
        control_plane_run_id, control_plane_run_url, control_plane_status, control_plane_duration
        readiness_result, functional_result, user_facing_result, evidence_result
        fecha_fin, duracion_total_segundos
    """

    def __init__(
        self,
        nombre_proyecto: str,
        descripcion: str = "",
        repositorio: str = "",
        web_app: str = "",
        correlation_id: str = "",
        deployment_id: str = "",
        estado: str = "SOLICITADO",
        app_service_plan_id: str = ""
    ):
        self.id: str = _generar_id()
        self.nombre_proyecto: str = nombre_proyecto
        self.descripcion: str = descripcion
        self.repositorio: str = repositorio or f"FREDYASARMIENTOT/hermes-{nombre_proyecto.replace('_', '-')}"
        self.web_app: str = web_app or f"as-{nombre_proyecto.replace('_', '-')}"
        self.estado: str = estado
        self.correlation_id: str = correlation_id or _generar_id()
        self.deployment_id: str = deployment_id or _generar_id()
        self.commit_sha: str = ""
        self.repo_url: str = ""
        self.web_app_url: str = ""
        self.pasos: List[Dict[str, Any]] = []
        self.fecha_solicitud: str = _ahora()
        self.fecha_actualizacion: str = self.fecha_solicitud
        self.resultado: str = ""
        self.error: str = ""
        self.app_service_plan_id: str = app_service_plan_id
        self.app_service_plan_name: str = ""
        self.app_service_plan_resource_group: str = ""
        self.app_service_plan_subscription: str = "01bfad48-c092-4712-bc72-f141eb01a8d4"
        self.web_app_resource_group: str = ""
        self.web_app_resource_id: str = ""
        # GitHub traceability
        self.repository_url: str = ""
        self.commit_url: str = ""
        self.visibility: str = ""
        # Factory traceability
        self.factory_run_id: str = ""
        self.factory_run_url: str = ""
        self.factory_status: str = ""
        self.factory_started_at: str = ""
        self.factory_finished_at: str = ""
        self.factory_duration: str = ""
        # Control Plane traceability
        self.control_plane_run_id: str = ""
        self.control_plane_run_url: str = ""
        self.control_plane_status: str = ""
        self.control_plane_started_at: str = ""
        self.control_plane_finished_at: str = ""
        self.control_plane_duration: str = ""
        # Validation results
        self.readiness_result: str = ""
        self.functional_result: str = ""
        self.functional_pass_count: int = 0
        self.functional_fail_count: int = 0
        self.user_facing_result: str = ""
        self.evidence_result: str = ""
        # Child CI traceability
        self.child_ci_run_id: str = ""
        self.child_ci_run_url: str = ""
        self.child_ci_status: str = ""
        self.child_ci_started_at: str = ""
        self.child_ci_finished_at: str = ""
        self.child_ci_duration: str = ""
        # Azure detailed info
        self.azure_hostname: str = ""
        self.azure_state: str = ""
        self.azure_location: str = ""
        self.azure_subscription_id: str = ""
        self.azure_web_app_name: str = ""
        # Readiness detailed info
        self.readiness_http_status: Optional[int] = None
        self.readiness_url: str = ""
        self.readiness_timestamp: str = ""
        # Evidence detailed info
        self.evidence_status: str = ""
        self.evidence_url: str = ""
        # Branch
        self.branch: str = "main"
        # Azure resource reconciliation
        self.azure_resource_exists: Optional[bool] = None
        self.azure_resource_check_status: str = "NO_VERIFICADO"
        self.azure_resource_checked_at: str = ""
        self.azure_resource_check_error: str = ""
        self.azure_hostname: str = ""
        # GitHub resource reconciliation
        self.github_resource_exists: Optional[bool] = None
        self.github_resource_check_status: str = "NO_VERIFICADO"
        self.github_resource_checked_at: str = ""
        self.github_resource_check_error: str = ""
        self.github_repository: str = ""
        # Runtime/VENV resource reconciliation
        self.runtime_resource_exists: Optional[bool] = None
        self.runtime_resource_check_status: str = "NO_VERIFICADO"
        self.runtime_resource_checked_at: str = ""
        self.runtime_resource_check_error: str = ""
        # Timing
        self.fecha_fin: str = ""
        self.duracion_total_segundos: int = 0
        self._inicializar_pasos()

    def _inicializar_pasos(self) -> None:
        """Inicializa los 13 pasos canónicos con estado PENDIENTE y subpasos vacíos."""
        self.pasos = []
        for paso in PASOS_CANONICOS:
            self.pasos.append({
                "numero": paso["numero"], "nombre": paso["nombre"],
                "descripcion": paso["descripcion"], "estado": "PENDIENTE",
                "fecha_inicio": None, "fecha_fin": None,
                "duracion_segundos": None, "detalle": "", "evidencia": "",
                "subpasos": []
            })

    def iniciar_paso(self, numero_paso: int, detalle: str = "") -> None:
        """Marca un paso como EN_PROCESO."""
        for paso in self.pasos:
            if paso["numero"] == numero_paso:
                paso["estado"] = "EN_PROCESO"
                paso["fecha_inicio"] = _ahora()
                paso["detalle"] = detalle or f"Iniciando paso {numero_paso}"
                self.fecha_actualizacion = _ahora()
                return
        logger.warning(f"Paso {numero_paso} no encontrado")

    def finalizar_paso(
        self, numero_paso: int, estado: str = "COMPLETADO",
        detalle: str = "", evidencia: str = ""
    ) -> None:
        """Finaliza un paso con un estado."""
        for paso in self.pasos:
            if paso["numero"] == numero_paso:
                paso["estado"] = estado
                paso["fecha_fin"] = _ahora()
                paso["detalle"] = detalle or paso["detalle"]
                paso["evidencia"] = evidencia
                if paso["fecha_inicio"]:
                    try:
                        inicio = datetime.fromisoformat(paso["fecha_inicio"])
                        fin = datetime.fromisoformat(paso["fecha_fin"])
                        paso["duracion_segundos"] = round((fin - inicio).total_seconds(), 2)
                    except (ValueError, TypeError):
                        paso["duracion_segundos"] = None
                self.fecha_actualizacion = _ahora()
                return
        logger.warning(f"Paso {numero_paso} no encontrado")

    def a_dict(self) -> Dict[str, Any]:
        """Convierte la solicitud a diccionario serializable."""
        # Compute total duration from solicitud->actualizacion if not set
        duracion = self.duracion_total_segundos
        if not duracion and self.fecha_solicitud and self.fecha_actualizacion:
            try:
                inicio = datetime.fromisoformat(self.fecha_solicitud)
                fin = datetime.fromisoformat(self.fecha_actualizacion)
                duracion = round((fin - inicio).total_seconds(), 2)
            except (ValueError, TypeError):
                duracion = 0

        return {
            "id": self.id, "nombre_proyecto": self.nombre_proyecto,
            "descripcion": self.descripcion, "repositorio": self.repositorio,
            "web_app": self.web_app, "web_app_url": self.web_app_url,
            "repo_url": self.repo_url, "estado": self.estado,
            "correlation_id": self.correlation_id,
            "deployment_id": self.deployment_id,
            "commit_sha": self.commit_sha, "pasos": self.pasos,
            "fecha_solicitud": self.fecha_solicitud,
            "fecha_actualizacion": self.fecha_actualizacion,
            "resultado": self.resultado, "error": self.error,
            "app_service_plan_id": self.app_service_plan_id,
            "app_service_plan_name": self.app_service_plan_name,
            "app_service_plan_resource_group": self.app_service_plan_resource_group,
            "app_service_plan_subscription": self.app_service_plan_subscription,
            "web_app_resource_group": self.web_app_resource_group,
            "web_app_resource_id": self.web_app_resource_id,
            "server_farm_id": self.app_service_plan_id,
            # GitHub traceability
            "repository_url": self.repository_url,
            "commit_url": self.commit_url,
            "visibility": self.visibility,
            # Factory traceability
            "factory_run_id": self.factory_run_id,
            "factory_run_url": self.factory_run_url,
            "factory_status": self.factory_status,
            "factory_started_at": self.factory_started_at,
            "factory_finished_at": self.factory_finished_at,
            "factory_duration": self.factory_duration,
            # Control Plane traceability
            "control_plane_run_id": self.control_plane_run_id,
            "control_plane_run_url": self.control_plane_run_url,
            "control_plane_status": self.control_plane_status,
            "control_plane_started_at": self.control_plane_started_at,
            "control_plane_finished_at": self.control_plane_finished_at,
            "control_plane_duration": self.control_plane_duration,
            # Validation results
            "readiness_result": self.readiness_result,
            "functional_result": self.functional_result,
            "functional_pass_count": self.functional_pass_count,
            "functional_fail_count": self.functional_fail_count,
            "user_facing_result": self.user_facing_result,
            "evidence_result": self.evidence_result,
            # Azure resource reconciliation
            "azure_resource_exists": self.azure_resource_exists,
            "azure_resource_check_status": self.azure_resource_check_status,
            "azure_resource_checked_at": self.azure_resource_checked_at,
            "azure_resource_check_error": self.azure_resource_check_error,
            # Child CI traceability
            "child_ci_run_id": self.child_ci_run_id,
            "child_ci_run_url": self.child_ci_run_url,
            "child_ci_status": self.child_ci_status,
            "child_ci_started_at": self.child_ci_started_at,
            "child_ci_finished_at": self.child_ci_finished_at,
            "child_ci_duration": self.child_ci_duration,
            # Azure detailed info
            "azure_hostname": self.azure_hostname,
            "azure_state": self.azure_state,
            "azure_location": self.azure_location,
            "azure_subscription_id": self.azure_subscription_id,
            "azure_web_app_name": self.azure_web_app_name,
            # Readiness detailed info
            "readiness_http_status": self.readiness_http_status,
            "readiness_url": self.readiness_url,
            "readiness_timestamp": self.readiness_timestamp,
            # Evidence detailed info
            "evidence_status": self.evidence_status,
            "evidence_url": self.evidence_url,
            # Branch
            "branch": self.branch,
            "azure_hostname": self.azure_hostname,
            # GitHub resource reconciliation
            "github_resource_exists": self.github_resource_exists,
            "github_resource_check_status": self.github_resource_check_status,
            "github_resource_checked_at": self.github_resource_checked_at,
            "github_resource_check_error": self.github_resource_check_error,
            "github_repository": self.github_repository,
            # Runtime/VENV resource reconciliation
            "runtime_resource_exists": self.runtime_resource_exists,
            "runtime_resource_check_status": self.runtime_resource_check_status,
            "runtime_resource_checked_at": self.runtime_resource_checked_at,
            "runtime_resource_check_error": self.runtime_resource_check_error,
            # Timing
            "fecha_fin": self.fecha_fin,
            "duracion_total_segundos": duracion
        }

    @classmethod
    def desde_dict(cls, datos: Dict[str, Any]) -> "SolicitudProyecto":
        """Crea una instancia desde un diccionario."""
        s = cls(
            nombre_proyecto=datos.get("nombre_proyecto", ""),
            descripcion=datos.get("descripcion", ""),
            repositorio=datos.get("repositorio", ""),
            web_app=datos.get("web_app", ""),
            correlation_id=datos.get("correlation_id", ""),
            deployment_id=datos.get("deployment_id", ""),
            estado=datos.get("estado", "SOLICITADO"),
            app_service_plan_id=datos.get("app_service_plan_id", "")
        )
        s.id = datos.get("id", s.id)
        s.commit_sha = datos.get("commit_sha", "")
        s.repo_url = datos.get("repo_url", "")
        s.web_app_url = datos.get("web_app_url", "")
        s.fecha_solicitud = datos.get("fecha_solicitud", s.fecha_solicitud)
        s.fecha_actualizacion = datos.get("fecha_actualizacion", s.fecha_solicitud)
        s.resultado = datos.get("resultado", "")
        s.error = datos.get("error", "")
        s.app_service_plan_name = datos.get("app_service_plan_name", "")
        s.app_service_plan_resource_group = datos.get("app_service_plan_resource_group", "")
        s.app_service_plan_subscription = datos.get("app_service_plan_subscription", "01bfad48-c092-4712-bc72-f141eb01a8d4")
        s.web_app_resource_group = datos.get("web_app_resource_group", "")
        s.web_app_resource_id = datos.get("web_app_resource_id", "")
        # GitHub traceability
        s.repository_url = datos.get("repository_url", "")
        s.commit_url = datos.get("commit_url", "")
        s.visibility = datos.get("visibility", "")
        # Factory traceability
        s.factory_run_id = datos.get("factory_run_id", "")
        s.factory_run_url = datos.get("factory_run_url", "")
        s.factory_status = datos.get("factory_status", "")
        s.factory_started_at = datos.get("factory_started_at", "")
        s.factory_finished_at = datos.get("factory_finished_at", "")
        s.factory_duration = datos.get("factory_duration", "")
        # Control Plane traceability
        s.control_plane_run_id = datos.get("control_plane_run_id", "")
        s.control_plane_run_url = datos.get("control_plane_run_url", "")
        s.control_plane_status = datos.get("control_plane_status", "")
        s.control_plane_started_at = datos.get("control_plane_started_at", "")
        s.control_plane_finished_at = datos.get("control_plane_finished_at", "")
        s.control_plane_duration = datos.get("control_plane_duration", "")
        # Validation results
        s.readiness_result = datos.get("readiness_result", "")
        s.functional_result = datos.get("functional_result", "")
        s.functional_pass_count = datos.get("functional_pass_count", 0)
        s.functional_fail_count = datos.get("functional_fail_count", 0)
        s.user_facing_result = datos.get("user_facing_result", "")
        s.evidence_result = datos.get("evidence_result", "")
        # Child CI traceability
        s.child_ci_run_id = datos.get("child_ci_run_id", "")
        s.child_ci_run_url = datos.get("child_ci_run_url", "")
        s.child_ci_status = datos.get("child_ci_status", "")
        s.child_ci_started_at = datos.get("child_ci_started_at", "")
        s.child_ci_finished_at = datos.get("child_ci_finished_at", "")
        s.child_ci_duration = datos.get("child_ci_duration", "")
        # Azure detailed info
        s.azure_hostname = datos.get("azure_hostname", "")
        s.azure_state = datos.get("azure_state", "")
        s.azure_location = datos.get("azure_location", "")
        s.azure_subscription_id = datos.get("azure_subscription_id", "")
        s.azure_web_app_name = datos.get("azure_web_app_name", "")
        # Readiness detailed info
        s.readiness_http_status = datos.get("readiness_http_status")
        s.readiness_url = datos.get("readiness_url", "")
        s.readiness_timestamp = datos.get("readiness_timestamp", "")
        # Evidence detailed info
        s.evidence_status = datos.get("evidence_status", "")
        s.evidence_url = datos.get("evidence_url", "")
        # Branch
        s.branch = datos.get("branch", "main")
        # Azure resource reconciliation
        s.azure_resource_exists = datos.get("azure_resource_exists")
        if s.azure_resource_exists is not None:
            if isinstance(s.azure_resource_exists, str):
                s.azure_resource_exists = s.azure_resource_exists.lower() in ("true", "1", "yes")
        s.azure_resource_check_status = datos.get("azure_resource_check_status", "NO_VERIFICADO")
        s.azure_resource_checked_at = datos.get("azure_resource_checked_at", "")
        s.azure_resource_check_error = datos.get("azure_resource_check_error", "")
        s.azure_hostname = datos.get("azure_hostname", "")
        # GitHub resource reconciliation
        s.github_resource_exists = datos.get("github_resource_exists")
        if s.github_resource_exists is not None:
            if isinstance(s.github_resource_exists, str):
                s.github_resource_exists = s.github_resource_exists.lower() in ("true", "1", "yes")
        s.github_resource_check_status = datos.get("github_resource_check_status", "NO_VERIFICADO")
        s.github_resource_checked_at = datos.get("github_resource_checked_at", "")
        s.github_resource_check_error = datos.get("github_resource_check_error", "")
        s.github_repository = datos.get("github_repository", "")
        # Runtime/VENV resource reconciliation
        s.runtime_resource_exists = datos.get("runtime_resource_exists")
        if s.runtime_resource_exists is not None:
            if isinstance(s.runtime_resource_exists, str):
                s.runtime_resource_exists = s.runtime_resource_exists.lower() in ("true", "1", "yes")
        s.runtime_resource_check_status = datos.get("runtime_resource_check_status", "NO_VERIFICADO")
        s.runtime_resource_checked_at = datos.get("runtime_resource_checked_at", "")
        s.runtime_resource_check_error = datos.get("runtime_resource_check_error", "")
        # Timing
        s.fecha_fin = datos.get("fecha_fin", "")
        s.duracion_total_segundos = datos.get("duracion_total_segundos", 0)
        pasos_json = datos.get("pasos_json")
        if pasos_json:
            try:
                s.pasos = json.loads(pasos_json)
            except (json.JSONDecodeError, TypeError):
                pass
        return s

# ═══════════════════════════════════════════════════════════════
# Clase ServicioFabrica
# ═══════════════════════════════════════════════════════════════

class ServicioFabrica:
    """
    Servicio de fábrica para gestionar solicitudes de proyectos Child.

    Proporciona métodos para:
    - Crear solicitudes
    - Consultar estado
    - Iniciar ejecución de Factory local
    - Actualizar pasos
    - Persistir en SQLite
    """

    def __init__(self, ruta_db: Optional[str] = None):
        self.ruta_db: str = ruta_db or _ruta_db_por_defecto()
        self._inicializar_bd()
        logger.info(f"ServicioFabrica inicializado. DB: {self.ruta_db}")

    # ──────────────────────────────────────────────────────────
    # Inicialización de base de datos
    # ──────────────────────────────────────────────────────────

    def _inicializar_bd(self) -> None:
        """Crea la tabla de solicitudes si no existe."""
        try:
            conn = sqlite3.connect(self.ruta_db)
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS solicitudes_proyecto (
                    id TEXT PRIMARY KEY,
                    nombre_proyecto TEXT NOT NULL,
                    descripcion TEXT DEFAULT '',
                    repositorio TEXT DEFAULT '',
                    web_app TEXT DEFAULT '',
                    web_app_url TEXT DEFAULT '',
                    repo_url TEXT DEFAULT '',
                    estado TEXT DEFAULT 'SOLICITADO',
                    correlation_id TEXT DEFAULT '',
                    deployment_id TEXT DEFAULT '',
                    commit_sha TEXT DEFAULT '',
                    pasos_json TEXT DEFAULT '[]',
                    fecha_solicitud TEXT DEFAULT '',
                    fecha_actualizacion TEXT DEFAULT '',
                    resultado TEXT DEFAULT '',
                    error TEXT DEFAULT '',
                    app_service_plan_id TEXT DEFAULT '',
                    app_service_plan_name TEXT DEFAULT '',
                    app_service_plan_resource_group TEXT DEFAULT '',
                    app_service_plan_subscription TEXT DEFAULT '01bfad48-c092-4712-bc72-f141eb01a8d4',
                    web_app_resource_group TEXT DEFAULT '',
                    web_app_resource_id TEXT DEFAULT '',
                    repository_url TEXT DEFAULT '',
                    commit_url TEXT DEFAULT '',
                    visibility TEXT DEFAULT '',
                    factory_run_id TEXT DEFAULT '',
                    factory_run_url TEXT DEFAULT '',
                    factory_status TEXT DEFAULT '',
                    factory_started_at TEXT DEFAULT '',
                    factory_finished_at TEXT DEFAULT '',
                    factory_duration TEXT DEFAULT '',
                    control_plane_run_id TEXT DEFAULT '',
                    control_plane_run_url TEXT DEFAULT '',
                    control_plane_status TEXT DEFAULT '',
                    control_plane_started_at TEXT DEFAULT '',
                    control_plane_finished_at TEXT DEFAULT '',
                    control_plane_duration TEXT DEFAULT '',
                    readiness_result TEXT DEFAULT '',
                    functional_result TEXT DEFAULT '',
                    functional_pass_count INTEGER DEFAULT 0,
                    functional_fail_count INTEGER DEFAULT 0,
                    user_facing_result TEXT DEFAULT '',
                    evidence_result TEXT DEFAULT '',
                    fecha_fin TEXT DEFAULT '',
                    duracion_total_segundos INTEGER DEFAULT 0,
                    child_ci_run_id TEXT DEFAULT '',
                    child_ci_run_url TEXT DEFAULT '',
                    child_ci_status TEXT DEFAULT '',
                    child_ci_started_at TEXT DEFAULT '',
                    child_ci_finished_at TEXT DEFAULT '',
                    child_ci_duration TEXT DEFAULT '',
                    azure_hostname TEXT DEFAULT '',
                    azure_state TEXT DEFAULT '',
                    azure_location TEXT DEFAULT '',
                    azure_subscription_id TEXT DEFAULT '01bfad48-c092-4712-bc72-f141eb01a8d4',
                    azure_web_app_name TEXT DEFAULT '',
                    readiness_http_status INTEGER,
                    readiness_url TEXT DEFAULT '',
                    readiness_timestamp TEXT DEFAULT '',
                    evidence_status TEXT DEFAULT '',
                    evidence_url TEXT DEFAULT '',
                    branch TEXT DEFAULT 'main'
                )
            """)
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_solicitudes_estado ON solicitudes_proyecto(estado)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_solicitudes_nombre ON solicitudes_proyecto(nombre_proyecto)")

            # ── Event Log table: immutable audit trail ──
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS event_logs (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    deployment_id TEXT NOT NULL,
                    correlation_id TEXT DEFAULT '',
                    event_id TEXT NOT NULL UNIQUE,
                    timestamp TEXT NOT NULL,
                    fase TEXT DEFAULT '',
                    paso_numero INTEGER DEFAULT 0,
                    paso_nombre TEXT DEFAULT '',
                    subpaso_numero INTEGER,
                    subpaso_nombre TEXT DEFAULT '',
                    componente TEXT DEFAULT '',
                    actor TEXT DEFAULT '',
                    estado_anterior TEXT DEFAULT '',
                    estado_nuevo TEXT DEFAULT '',
                    tipo TEXT DEFAULT 'INFO',
                    mensaje TEXT DEFAULT '',
                    detalle TEXT DEFAULT '',
                    evidencia TEXT DEFAULT '',
                    http_method TEXT DEFAULT '',
                    http_url TEXT DEFAULT '',
                    http_status INTEGER,
                    error_code TEXT DEFAULT '',
                    error_message TEXT DEFAULT '',
                    run_id TEXT DEFAULT '',
                    run_url TEXT DEFAULT '',
                    duracion_segundos REAL,
                    created_at TEXT DEFAULT ''
                )
            """)
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_event_logs_did ON event_logs(deployment_id)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_event_logs_ts ON event_logs(timestamp)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_event_logs_tipo ON event_logs(tipo)")

            # ── Schema migration: add missing columns (existing DB without columns) ──
            for col_name, col_type in [
                ("app_service_plan_id", "TEXT DEFAULT ''"),
                ("app_service_plan_name", "TEXT DEFAULT ''"),
                ("app_service_plan_resource_group", "TEXT DEFAULT ''"),
                ("app_service_plan_subscription", "TEXT DEFAULT '01bfad48-c092-4712-bc72-f141eb01a8d4'"),
                ("web_app_resource_group", "TEXT DEFAULT ''"),
                ("web_app_resource_id", "TEXT DEFAULT ''"),
                ("repository_url", "TEXT DEFAULT ''"),
                ("commit_url", "TEXT DEFAULT ''"),
                ("visibility", "TEXT DEFAULT ''"),
                ("factory_run_id", "TEXT DEFAULT ''"),
                ("factory_run_url", "TEXT DEFAULT ''"),
                ("factory_status", "TEXT DEFAULT ''"),
                ("factory_started_at", "TEXT DEFAULT ''"),
                ("factory_finished_at", "TEXT DEFAULT ''"),
                ("factory_duration", "TEXT DEFAULT ''"),
                ("control_plane_run_id", "TEXT DEFAULT ''"),
                ("control_plane_run_url", "TEXT DEFAULT ''"),
                ("control_plane_status", "TEXT DEFAULT ''"),
                ("control_plane_started_at", "TEXT DEFAULT ''"),
                ("control_plane_finished_at", "TEXT DEFAULT ''"),
                ("control_plane_duration", "TEXT DEFAULT ''"),
                ("readiness_result", "TEXT DEFAULT ''"),
                ("functional_result", "TEXT DEFAULT ''"),
                ("functional_pass_count", "INTEGER DEFAULT 0"),
                ("functional_fail_count", "INTEGER DEFAULT 0"),
                ("user_facing_result", "TEXT DEFAULT ''"),
                ("evidence_result", "TEXT DEFAULT ''"),
                ("fecha_fin", "TEXT DEFAULT ''"),
                ("duracion_total_segundos", "INTEGER DEFAULT 0"),
                ("azure_resource_exists", "INTEGER"),
                ("azure_resource_check_status", "TEXT DEFAULT 'NO_VERIFICADO'"),
                ("azure_resource_checked_at", "TEXT DEFAULT ''"),
                ("azure_resource_check_error", "TEXT DEFAULT ''"),
                ("azure_hostname", "TEXT DEFAULT ''"),
                ("github_resource_exists", "INTEGER"),
                ("github_resource_check_status", "TEXT DEFAULT 'NO_VERIFICADO'"),
                ("github_resource_checked_at", "TEXT DEFAULT ''"),
                ("github_resource_check_error", "TEXT DEFAULT ''"),
                ("github_repository", "TEXT DEFAULT ''"),
                ("runtime_resource_exists", "INTEGER"),
                ("runtime_resource_check_status", "TEXT DEFAULT 'NO_VERIFICADO'"),
                ("runtime_resource_checked_at", "TEXT DEFAULT ''"),
                ("runtime_resource_check_error", "TEXT DEFAULT ''"),
                ("child_ci_run_id", "TEXT DEFAULT ''"),
                ("child_ci_run_url", "TEXT DEFAULT ''"),
                ("child_ci_status", "TEXT DEFAULT ''"),
                ("child_ci_started_at", "TEXT DEFAULT ''"),
                ("child_ci_finished_at", "TEXT DEFAULT ''"),
                ("child_ci_duration", "TEXT DEFAULT ''"),
                ("azure_state", "TEXT DEFAULT ''"),
                ("azure_location", "TEXT DEFAULT ''"),
                ("azure_subscription_id", "TEXT DEFAULT '01bfad48-c092-4712-bc72-f141eb01a8d4'"),
                ("azure_web_app_name", "TEXT DEFAULT ''"),
                ("readiness_http_status", "INTEGER"),
                ("readiness_url", "TEXT DEFAULT ''"),
                ("readiness_timestamp", "TEXT DEFAULT ''"),
                ("evidence_status", "TEXT DEFAULT ''"),
                ("evidence_url", "TEXT DEFAULT ''"),
                ("branch", "TEXT DEFAULT 'main'"),
            ]:
                try:
                    cursor.execute(f"ALTER TABLE solicitudes_proyecto ADD COLUMN {col_name} {col_type}")
                    logger.info(f"Columna {col_name} agregada a solicitudes_proyecto")
                except Exception:
                    pass  # Columna ya existe

            conn.commit()
            conn.close()
            logger.info("Tabla solicitudes_proyecto inicializada")
        except Exception as e:
            logger.error(f"Error inicializando BD: {e}")

    # ──────────────────────────────────────────────────────────
    # Operaciones CRUD
    # ──────────────────────────────────────────────────────────

    def crear_solicitud(
        self,
        nombre_proyecto: str,
        descripcion: str = "",
        app_service_plan_id: str = ""
    ) -> SolicitudProyecto:
        """Crea una nueva solicitud de proyecto."""
        if not nombre_proyecto or len(nombre_proyecto) < 3:
            raise ValueError("El nombre del proyecto debe tener al menos 3 caracteres")
        if not app_service_plan_id:
            raise ValueError(
                "app_service_plan_id es REQUERIDO. "
                "Debe seleccionar un App Service Plan de RG-Hermes-Proyectos."
            )
        # Validar formato del App Service Plan ID
        import re
        patron_plan = re.compile(
            r"^/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/"
            r"resourceGroups/RG-Hermes-Proyectos/"
            r"providers/Microsoft\.Web/serverfarms/[a-zA-Z0-9_-]+$"
        )
        if not patron_plan.match(app_service_plan_id):
            raise ValueError(
                f"app_service_plan_id inválido: '{app_service_plan_id}'. "
                "Debe ser un resource ID válido de un App Service Plan "
                "en RG-Hermes-Proyectos."
            )
        existente = self._buscar_por_nombre(nombre_proyecto)
        if existente and existente.estado not in ("FALLIDO", "COMPLETADO"):
            raise ValueError(
                f"Ya existe una solicitud activa para '{nombre_proyecto}' "
                f"(estado: {existente.estado})"
            )
        solicitud = SolicitudProyecto(
            nombre_proyecto=nombre_proyecto,
            descripcion=descripcion,
            app_service_plan_id=app_service_plan_id
        )
        solicitud.iniciar_paso(1, f"Solicitud registrada para {nombre_proyecto}")
        self._guardar(solicitud)
        self._registrar_evento(
            deployment_id=solicitud.deployment_id,
            correlation_id=solicitud.correlation_id,
            fase="SOLICITUD", paso_numero=1, paso_nombre="SOLICITUD",
            estado_anterior="PENDIENTE", estado_nuevo="EN_PROCESO",
            tipo="INFO", mensaje=f"Solicitud creada para {nombre_proyecto}",
            detalle=f"app_service_plan_id={app_service_plan_id}"
        )
        logger.info(f"Solicitud creada: {solicitud.id} / {solicitud.nombre_proyecto} "
                     f"(correlation: {solicitud.correlation_id}, "
                     f"deployment: {solicitud.deployment_id})")
        return solicitud

    def obtener_solicitud(self, deployment_id: str) -> Optional[SolicitudProyecto]:
        """Obtiene una solicitud por deployment_id."""
        try:
            conn = sqlite3.connect(self.ruta_db)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM solicitudes_proyecto WHERE deployment_id = ?", (deployment_id,))
            fila = cursor.fetchone()
            conn.close()
            return SolicitudProyecto.desde_dict(dict(fila)) if fila else None
        except Exception as e:
            logger.error(f"Error obteniendo solicitud {deployment_id}: {e}")
            return None

    def obtener_solicitud_por_id(self, solicitud_id: str) -> Optional[SolicitudProyecto]:
        """Obtiene una solicitud por su ID interno."""
        try:
            conn = sqlite3.connect(self.ruta_db)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM solicitudes_proyecto WHERE id = ?", (solicitud_id,))
            fila = cursor.fetchone()
            conn.close()
            return SolicitudProyecto.desde_dict(dict(fila)) if fila else None
        except Exception as e:
            logger.error(f"Error obteniendo solicitud {solicitud_id}: {e}")
            return None

    def _buscar_por_nombre(self, nombre_proyecto: str) -> Optional[SolicitudProyecto]:
        """Busca una solicitud por nombre de proyecto."""
        try:
            conn = sqlite3.connect(self.ruta_db)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute(
                "SELECT * FROM solicitudes_proyecto WHERE nombre_proyecto = ? ORDER BY fecha_solicitud DESC LIMIT 1",
                (nombre_proyecto,)
            )
            fila = cursor.fetchone()
            conn.close()
            return SolicitudProyecto.desde_dict(dict(fila)) if fila else None
        except Exception as e:
            logger.error(f"Error buscando por nombre {nombre_proyecto}: {e}")
            return None

    def listar_solicitudes(self, limite: int = 20, estado: Optional[str] = None) -> List[SolicitudProyecto]:
        """Lista las solicitudes de proyectos."""
        try:
            conn = sqlite3.connect(self.ruta_db)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            if estado:
                cursor.execute(
                    "SELECT * FROM solicitudes_proyecto WHERE estado = ? ORDER BY fecha_solicitud DESC LIMIT ?",
                    (estado, limite)
                )
            else:
                cursor.execute(
                    "SELECT * FROM solicitudes_proyecto ORDER BY fecha_solicitud DESC LIMIT ?",
                    (limite,)
                )
            filas = cursor.fetchall()
            conn.close()
            return [SolicitudProyecto.desde_dict(dict(f)) for f in filas]
        except Exception as e:
            logger.error(f"Error listando solicitudes: {e}")
            return []

    # ──────────────────────────────────────────────────────────
    # Azure resource reconciliation
    # ──────────────────────────────────────────────────────────

    def _actualizar_estado_azure_en_bd(
        self, deployment_id: str, resultado_azure: Dict[str, Any]
    ) -> bool:
        """Actualiza los campos de reconciliacion Azure en BD."""
        try:
            conn = sqlite3.connect(self.ruta_db)
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE solicitudes_proyecto SET
                    azure_resource_exists = ?,
                    azure_resource_check_status = ?,
                    azure_resource_checked_at = ?,
                    azure_resource_check_error = ?,
                    azure_hostname = ?
                WHERE deployment_id = ?
            """, (
                resultado_azure.get("exists"),
                resultado_azure.get("status", "NO_VERIFICADO"),
                resultado_azure.get("checked_at", ""),
                resultado_azure.get("error", ""),
                resultado_azure.get("hostname", ""),
                deployment_id
            ))
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            logger.error(f"Error actualizando estado Azure en BD para {deployment_id}: {e}")
            return False

    def _actualizar_estado_github_en_bd(
        self, deployment_id: str, resultado_github: Dict[str, Any]
    ) -> bool:
        """Actualiza los campos de reconciliacion GitHub en BD."""
        try:
            conn = sqlite3.connect(self.ruta_db)
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE solicitudes_proyecto SET
                    github_resource_exists = ?,
                    github_resource_check_status = ?,
                    github_resource_checked_at = ?,
                    github_resource_check_error = ?,
                    github_repository = ?
                WHERE deployment_id = ?
            """, (
                resultado_github.get("exists"),
                resultado_github.get("status", "NO_VERIFICADO"),
                resultado_github.get("checked_at", ""),
                resultado_github.get("error", ""),
                resultado_github.get("repository", ""),
                deployment_id
            ))
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            logger.error(f"Error actualizando estado GitHub en BD para {deployment_id}: {e}")
            return False

    def _actualizar_estado_runtime_en_bd(
        self, deployment_id: str, resultado_runtime: Dict[str, Any]
    ) -> bool:
        """Actualiza los campos de reconciliacion Runtime/VENV en BD."""
        try:
            conn = sqlite3.connect(self.ruta_db)
            cursor = conn.cursor()
            cursor.execute("""
                UPDATE solicitudes_proyecto SET
                    runtime_resource_exists = ?,
                    runtime_resource_check_status = ?,
                    runtime_resource_checked_at = ?,
                    runtime_resource_check_error = ?
                WHERE deployment_id = ?
            """, (
                resultado_runtime.get("exists"),
                resultado_runtime.get("status", "NO_VERIFICADO"),
                resultado_runtime.get("checked_at", ""),
                resultado_runtime.get("error", ""),
                deployment_id
            ))
            conn.commit()
            conn.close()
            return True
        except Exception as e:
            logger.error(f"Error actualizando estado Runtime en BD para {deployment_id}: {e}")
            return False

    def verificar_y_actualizar_estado_azure(
        self, deployment_id: str
    ) -> Dict[str, Any]:
        """
        Verifica si el Web App asociado a un deployment existe en Azure
        y actualiza los campos de reconciliacion.
        """
        solicitud = self.obtener_solicitud(deployment_id)
        if not solicitud:
            return {
                "deployment_id": deployment_id,
                "error": "Deployment no encontrado",
                "status": "NO_VERIFICADO",
            }

        web_app_name = solicitud.web_app
        resource_group = (
            solicitud.web_app_resource_group
            or "RG-Hermes-Proyectos"
        )
        subscription_id = (
            solicitud.app_service_plan_subscription
            or "01bfad48-c092-4712-bc72-f141eb01a8d4"
        )

        from Hermes.Web.backend.servicio_azure import obtener_servicio_azure
        servicio_azure = obtener_servicio_azure()

        resultado = servicio_azure.verificar_existencia_web_app(
            web_app_name=web_app_name,
            resource_group=resource_group,
            subscription_id=subscription_id,
        )

        resultado["deployment_id"] = deployment_id
        resultado["project_name"] = solicitud.nombre_proyecto
        resultado["web_app_name"] = web_app_name

        self._actualizar_estado_azure_en_bd(deployment_id, resultado)
        self._registrar_evento(
            deployment_id=deployment_id,
            correlation_id=solicitud.correlation_id,
            fase="RECONCILIACION",
            componente="AZURE",
            tipo="INFO",
            mensaje=f"Azure reconciliation: {resultado.get('status', 'NO_VERIFICADO')}",
            detalle=f"Web App: {web_app_name}, Status: {resultado.get('status', '?')}",
            evidencia=json.dumps({"azure_status": resultado.get("status", "?"), "web_app": web_app_name}),
        )

        return resultado

    def verificar_y_actualizar_estado_github(
        self, deployment_id: str
    ) -> Dict[str, Any]:
        """Verifica si el repositorio GitHub asociado existe."""
        solicitud = self.obtener_solicitud(deployment_id)
        if not solicitud:
            return {"deployment_id": deployment_id, "error": "Deployment no encontrado", "status": "NO_VERIFICADO"}

        repositorio = solicitud.repositorio or ""
        if "/" in repositorio:
            partes = repositorio.split("/")
            owner = partes[0]
            repo = "/".join(partes[1:])
        else:
            owner = "FREDYASARMIENTOT"
            repo = repositorio or solicitud.nombre_proyecto

        from Hermes.Web.backend.servicio_github import obtener_servicio_github
        servicio_github = obtener_servicio_github()
        resultado = servicio_github.verificar_existencia_repositorio(owner=owner, repo=repo)
        resultado["deployment_id"] = deployment_id
        resultado["project_name"] = solicitud.nombre_proyecto

        self._actualizar_estado_github_en_bd(deployment_id, resultado)
        self._registrar_evento(
            deployment_id=deployment_id, correlation_id=solicitud.correlation_id,
            fase="RECONCILIACION", componente="GITHUB", tipo="INFO",
            mensaje=f"GitHub reconciliation: {resultado.get('status', 'NO_VERIFICADO')}",
            detalle=f"Repo: {owner}/{repo}, Status: {resultado.get('status', '?')}",
            evidencia=json.dumps({"github_status": resultado.get("status", "?"), "repo": f"{owner}/{repo}"}),
        )
        return resultado

    def verificar_y_actualizar_estado_runtime(
        self, deployment_id: str
    ) -> Dict[str, Any]:
        """Verifica si el runtime/VENV esta operativo via health endpoint."""
        solicitud = self.obtener_solicitud(deployment_id)
        if not solicitud:
            return {"deployment_id": deployment_id, "error": "Deployment no encontrado", "status": "NO_VERIFICADO"}

        if solicitud.azure_resource_check_status != "EXISTE":
            resultado = {"exists": False, "status": "NO_VERIFICADO",
                "hostname": solicitud.azure_hostname or "",
                "error": "App Service no existe o no verificado", "checked_at": _ahora()}
            self._actualizar_estado_runtime_en_bd(deployment_id, resultado)
            return resultado

        hostname = solicitud.azure_hostname or f"{solicitud.web_app}.azurewebsites.net"
        from Hermes.Web.backend.servicio_runtime import obtener_servicio_runtime
        servicio_runtime = obtener_servicio_runtime()
        resultado = servicio_runtime.verificar_runtime(hostname=hostname)
        resultado["deployment_id"] = deployment_id
        resultado["project_name"] = solicitud.nombre_proyecto

        self._actualizar_estado_runtime_en_bd(deployment_id, resultado)
        self._registrar_evento(
            deployment_id=deployment_id, correlation_id=solicitud.correlation_id,
            fase="RECONCILIACION", componente="RUNTIME", tipo="INFO",
            mensaje=f"Runtime reconciliation: {resultado.get('status', 'NO_VERIFICADO')}",
            detalle=f"Hostname: {hostname}, Status: {resultado.get('status', '?')}",
            evidencia=json.dumps({"runtime_status": resultado.get("status", "?"), "hostname": hostname}),
        )
        return resultado

    def verificar_y_actualizar_estado_completo(
        self, deployment_id: str
    ) -> Dict[str, Any]:
        """Verifica estado completo de los 3 recursos: Azure + GitHub + Runtime."""
        resultado = {
            "deployment_id": deployment_id,
            "runtime": {}, "github": {}, "azure": {},
            "active": False, "checked_at": _ahora(),
        }
        solicitud = self.obtener_solicitud(deployment_id)
        if solicitud:
            resultado["project_name"] = solicitud.nombre_proyecto

        try:
            azure_res = self.verificar_y_actualizar_estado_azure(deployment_id)
            resultado["azure"] = {
                "status": azure_res.get("status", "NO_VERIFICADO"),
                "resource_id": azure_res.get("resource_id", ""),
                "web_app_name": azure_res.get("web_app_name", ""),
                "hostname": azure_res.get("hostname", ""),
                "checked_at": azure_res.get("checked_at", ""),
                "error": azure_res.get("error", ""),
            }
        except Exception as e:
            resultado["azure"] = {"status": "ERROR", "error": str(e)[:300]}

        try:
            github_res = self.verificar_y_actualizar_estado_github(deployment_id)
            resultado["github"] = {
                "status": github_res.get("status", "NO_VERIFICADO"),
                "repository": github_res.get("repository", ""),
                "html_url": github_res.get("html_url", ""),
                "checked_at": github_res.get("checked_at", ""),
                "error": github_res.get("error", ""),
            }
        except Exception as e:
            resultado["github"] = {"status": "ERROR", "error": str(e)[:300]}

        try:
            runtime_res = self.verificar_y_actualizar_estado_runtime(deployment_id)
            resultado["runtime"] = {
                "status": runtime_res.get("status", "NO_VERIFICADO"),
                "hostname": runtime_res.get("hostname", ""),
                "checked_at": runtime_res.get("checked_at", ""),
                "error": runtime_res.get("error", ""),
            }
        except Exception as e:
            resultado["runtime"] = {"status": "ERROR", "error": str(e)[:300]}

        resultado["active"] = resultado["azure"].get("status") == "EXISTE"

        self._registrar_evento(
            deployment_id=deployment_id, fase="RECONCILIACION",
            componente="RECONCILIACION_COMPLETA", tipo="INFO",
            mensaje="Reconciliacion completa ejecutada",
            detalle=(f"Azure: {resultado['azure'].get('status')}, "
                     f"GitHub: {resultado['github'].get('status')}, "
                     f"Runtime: {resultado['runtime'].get('status')}, "
                     f"Active: {resultado['active']}"),
            evidencia=json.dumps(resultado, ensure_ascii=False, default=str),
        )
        return resultado

    def reconciliar_todos_los_proyectos(self) -> Dict[str, Any]:
        """
        Revisa todos los deployments almacenados y verifica los 3 recursos:
        Azure App Service, GitHub Repositorio y Runtime/VENV.
        """
        solicitudes = self.listar_solicitudes(limite=1000)
        resultados = {
            "total": len(solicitudes),
            "azure_existentes": 0,
            "azure_eliminados": 0,
            "azure_errores": 0,
            "azure_no_verificados": 0,
            "github_existentes": 0,
            "github_eliminados": 0,
            "github_errores": 0,
            "github_no_verificados": 0,
            "runtime_existentes": 0,
            "runtime_eliminados": 0,
            "runtime_errores": 0,
            "runtime_no_verificados": 0,
            "activos": 0,
            "historicos": 0,
            "detalles": [],
            "timestamp": _ahora(),
        }

        for sol in solicitudes:
            detalle = {
                "deployment_id": sol.deployment_id,
                "project_name": sol.nombre_proyecto,
                "web_app": sol.web_app,
                "repositorio": sol.repositorio,
                "resultado_historico": sol.resultado,
                "azure": {"status": "NO_VERIFICADO", "error": ""},
                "github": {"status": "NO_VERIFICADO", "error": ""},
                "runtime": {"status": "NO_VERIFICADO", "error": ""},
                "active": False,
            }

            # 1. Verificar Azure
            try:
                if not sol.web_app:
                    resultados["azure_no_verificados"] += 1
                    detalle["azure"]["error"] = "Sin web_app"
                else:
                    res = self.verificar_y_actualizar_estado_azure(sol.deployment_id)
                    status = res.get("status", "ERROR")
                    detalle["azure"]["status"] = status
                    detalle["azure"]["error"] = res.get("error", "")
                    if status == "EXISTE":
                        resultados["azure_existentes"] += 1
                        detalle["active"] = True
                    elif status == "NO_EXISTE":
                        resultados["azure_eliminados"] += 1
                    elif "ERROR" in status:
                        resultados["azure_errores"] += 1
                    else:
                        resultados["azure_no_verificados"] += 1
            except Exception as e:
                resultados["azure_errores"] += 1
                detalle["azure"]["status"] = "ERROR"
                detalle["azure"]["error"] = str(e)[:200]

            # 2. Verificar GitHub
            try:
                github_res = self.verificar_y_actualizar_estado_github(sol.deployment_id)
                gh_status = github_res.get("status", "NO_VERIFICADO")
                detalle["github"]["status"] = gh_status
                detalle["github"]["error"] = github_res.get("error", "")
                if gh_status == "EXISTE":
                    resultados["github_existentes"] += 1
                elif gh_status == "NO_EXISTE":
                    resultados["github_eliminados"] += 1
                elif "ERROR" in gh_status:
                    resultados["github_errores"] += 1
                else:
                    resultados["github_no_verificados"] += 1
            except Exception as e:
                resultados["github_errores"] += 1
                detalle["github"]["status"] = "ERROR"
                detalle["github"]["error"] = str(e)[:200]

            # 3. Verificar Runtime
            try:
                runtime_res = self.verificar_y_actualizar_estado_runtime(sol.deployment_id)
                rt_status = runtime_res.get("status", "NO_VERIFICADO")
                detalle["runtime"]["status"] = rt_status
                detalle["runtime"]["error"] = runtime_res.get("error", "")
                if rt_status == "EXISTE":
                    resultados["runtime_existentes"] += 1
                elif rt_status == "NO_EXISTE":
                    resultados["runtime_eliminados"] += 1
                elif "ERROR" in rt_status:
                    resultados["runtime_errores"] += 1
                else:
                    resultados["runtime_no_verificados"] += 1
            except Exception as e:
                resultados["runtime_errores"] += 1
                detalle["runtime"]["status"] = "ERROR"
                detalle["runtime"]["error"] = str(e)[:200]

            # 4. Activo vs Histórico
            if detalle["active"]:
                resultados["activos"] += 1
            else:
                resultados["historicos"] += 1

            resultados["detalles"].append(detalle)

        self._registrar_evento(
            deployment_id="MASS_RECONCILIATION",
            fase="RECONCILIACION",
            componente="RECONCILIACION_MASIVA",
            tipo="INFO",
            mensaje=f"Reconciliacion masiva completada: {resultados['total']} proyectos",
            detalle=(
                f"Azure EXISTE: {resultados['azure_existentes']}, "
                f"NO_EXISTE: {resultados['azure_eliminados']}; "
                f"GitHub EXISTE: {resultados['github_existentes']}, "
                f"NO_EXISTE: {resultados['github_eliminados']}; "
                f"Runtime EXISTE: {resultados['runtime_existentes']}; "
                f"Activos: {resultados['activos']}, Historicos: {resultados['historicos']}"
            ),
        )

        return resultados

    def _guardar(self, solicitud: SolicitudProyecto) -> None:
        """Guarda o actualiza una solicitud en SQLite."""
        # FASE 24 — Recalcular estado global desde pasos antes de guardar
        # Esto garantiza que NUNCA persista un estado inconsistente.
        estado_calculado = self._calcular_estado_global(solicitud)
        if estado_calculado != solicitud.estado:
            logger.warning(
                f"FASE-24: Corrigiendo estado inconsistente: {solicitud.estado} -> {estado_calculado} "
                f"para deployment {solicitud.deployment_id}"
            )
            solicitud.estado = estado_calculado
        # FASE 24 — Verificar resultado SIEMPRE, no solo cuando cambia estado
        # Esto cubre el escenario donde alguien fuerza resultado=PASS
        # en una solicitud con estado correcto (EN_PROCESO) pero pasos pendientes.
        pasos_pend = self._pasos_pendientes(solicitud)
        if pasos_pend and solicitud.resultado == "PASS":
            logger.warning(
                f"FASE-24: Corrigiendo resultado inconsistente: PASS -> '' "
                f"para deployment {solicitud.deployment_id} "
                f"({len(pasos_pend)} paso(s) pendiente(s))"
            )
            solicitud.resultado = ""
        try:
            conn = sqlite3.connect(self.ruta_db)
            cursor = conn.cursor()
            datos = solicitud.a_dict()
            datos["pasos_json"] = json.dumps(datos.pop("pasos", []), ensure_ascii=False)
            cursor.execute("""
                INSERT OR REPLACE INTO solicitudes_proyecto
                (id, nombre_proyecto, descripcion, repositorio, web_app,
                 web_app_url, repo_url, estado, correlation_id, deployment_id,
                 commit_sha, pasos_json, fecha_solicitud, fecha_actualizacion,
                 resultado, error, app_service_plan_id, app_service_plan_name,
                 app_service_plan_resource_group, app_service_plan_subscription,
                 web_app_resource_group, web_app_resource_id,
                 repository_url, commit_url, visibility,
                 factory_run_id, factory_run_url, factory_status,
                 factory_started_at, factory_finished_at, factory_duration,
                 control_plane_run_id, control_plane_run_url, control_plane_status,
                 control_plane_started_at, control_plane_finished_at, control_plane_duration,
                 readiness_result, functional_result, functional_pass_count,
                 functional_fail_count, user_facing_result, evidence_result,
                 fecha_fin, duracion_total_segundos,
                 azure_resource_exists, azure_resource_check_status,
                 azure_resource_checked_at, azure_resource_check_error,
                 azure_hostname,
                 github_resource_exists, github_resource_check_status,
                 github_resource_checked_at, github_resource_check_error,
                 github_repository,
                 runtime_resource_exists, runtime_resource_check_status,
                 runtime_resource_checked_at, runtime_resource_check_error,
                 child_ci_run_id, child_ci_run_url, child_ci_status,
                 child_ci_started_at, child_ci_finished_at, child_ci_duration,
                 azure_state, azure_location, azure_subscription_id, azure_web_app_name,
                 readiness_http_status, readiness_url, readiness_timestamp,
                 evidence_status, evidence_url,
                 branch)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                 ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                 ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                 ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                datos["id"], datos["nombre_proyecto"], datos["descripcion"],
                datos["repositorio"], datos["web_app"], datos["web_app_url"],
                datos["repo_url"], datos["estado"], datos["correlation_id"],
                datos["deployment_id"], datos["commit_sha"], datos["pasos_json"],
                datos["fecha_solicitud"], datos["fecha_actualizacion"],
                datos["resultado"], datos["error"],
                datos["app_service_plan_id"], datos["app_service_plan_name"],
                datos["app_service_plan_resource_group"],
                datos["app_service_plan_subscription"],
                datos["web_app_resource_group"],
                datos["web_app_resource_id"],
                datos.get("repository_url", ""),
                datos.get("commit_url", ""),
                datos.get("visibility", ""),
                datos.get("factory_run_id", ""),
                datos.get("factory_run_url", ""),
                datos.get("factory_status", ""),
                datos.get("factory_started_at", ""),
                datos.get("factory_finished_at", ""),
                datos.get("factory_duration", ""),
                datos.get("control_plane_run_id", ""),
                datos.get("control_plane_run_url", ""),
                datos.get("control_plane_status", ""),
                datos.get("control_plane_started_at", ""),
                datos.get("control_plane_finished_at", ""),
                datos.get("control_plane_duration", ""),
                datos.get("readiness_result", ""),
                datos.get("functional_result", ""),
                datos.get("functional_pass_count", 0),
                datos.get("functional_fail_count", 0),
                datos.get("user_facing_result", ""),
                datos.get("evidence_result", ""),
                datos.get("fecha_fin", ""),
                datos.get("duracion_total_segundos", 0),
                datos.get("azure_resource_exists"),
                datos.get("azure_resource_check_status", "NO_VERIFICADO"),
                datos.get("azure_resource_checked_at", ""),
                datos.get("azure_resource_check_error", ""),
                datos.get("azure_hostname", ""),
                datos.get("github_resource_exists"),
                datos.get("github_resource_check_status", "NO_VERIFICADO"),
                datos.get("github_resource_checked_at", ""),
                datos.get("github_resource_check_error", ""),
                datos.get("github_repository", ""),
                datos.get("runtime_resource_exists"),
                datos.get("runtime_resource_check_status", "NO_VERIFICADO"),
                datos.get("runtime_resource_checked_at", ""),
                datos.get("runtime_resource_check_error", ""),
                datos.get("child_ci_run_id", ""),
                datos.get("child_ci_run_url", ""),
                datos.get("child_ci_status", ""),
                datos.get("child_ci_started_at", ""),
                datos.get("child_ci_finished_at", ""),
                datos.get("child_ci_duration", ""),
                datos.get("azure_state", ""),
                datos.get("azure_location", ""),
                datos.get("azure_subscription_id", ""),
                datos.get("azure_web_app_name", ""),
                datos.get("readiness_http_status"),
                datos.get("readiness_url", ""),
                datos.get("readiness_timestamp", ""),
                datos.get("evidence_status", ""),
                datos.get("evidence_url", ""),
                datos.get("branch", "main")
            ))
            conn.commit()
            conn.close()
        except Exception as e:
            logger.error(f"Error guardando solicitud: {e}")
            raise

    # ──────────────────────────────────────────────────────────
    # Event Log (Event Store inmutable)
    # ──────────────────────────────────────────────────────────

    def _registrar_evento(
        self, deployment_id: str, correlation_id: str = "",
        fase: str = "", paso_numero: int = 0, paso_nombre: str = "",
        subpaso_numero: int = None, subpaso_nombre: str = "",
        componente: str = "", actor: str = "",
        estado_anterior: str = "", estado_nuevo: str = "",
        tipo: str = "INFO", mensaje: str = "", detalle: str = "",
        evidencia: str = "",
        http_method: str = "", http_url: str = "", http_status: int = None,
        error_code: str = "", error_message: str = "",
        run_id: str = "", run_url: str = "",
        duracion_segundos: float = None
    ) -> Optional[str]:
        """Registra un evento inmutable en el Event Store."""
        import uuid
        event_id = f"evt-{uuid.uuid4().hex[:12]}"
        ts = _ahora()
        try:
            conn = sqlite3.connect(self.ruta_db)
            cursor = conn.cursor()
            cursor.execute("""
                INSERT INTO event_logs
                (deployment_id, correlation_id, event_id, timestamp,
                 fase, paso_numero, paso_nombre,
                 subpaso_numero, subpaso_nombre,
                 componente, actor,
                 estado_anterior, estado_nuevo, tipo,
                 mensaje, detalle, evidencia,
                 http_method, http_url, http_status,
                 error_code, error_message,
                 run_id, run_url,
                 duracion_segundos, created_at)
                VALUES (?, ?, ?, ?,
                        ?, ?, ?,
                        ?, ?,
                        ?, ?,
                        ?, ?, ?,
                        ?, ?, ?,
                        ?, ?, ?,
                        ?, ?,
                        ?, ?,
                        ?, ?)
            """, (
                deployment_id, correlation_id, event_id, ts,
                fase, paso_numero, paso_nombre,
                subpaso_numero, subpaso_nombre,
                componente, actor,
                estado_anterior, estado_nuevo, tipo,
                mensaje, detalle, evidencia,
                http_method, http_url, http_status,
                error_code, error_message,
                run_id, run_url,
                duracion_segundos, ts
            ))
            conn.commit()
            conn.close()
            logger.debug(f"Evento registrado: {event_id} [{tipo}] {mensaje}")

            # ── FASE 25: Publicar evento en EventBroker DESPUÉS de persistir ──
            # Regla: persistencia ANTES de SSE
            evento_dict = {
                "event_id": event_id,
                "deployment_id": deployment_id,
                "correlation_id": correlation_id,
                "timestamp": ts,
                "fase": fase,
                "paso_numero": paso_numero,
                "paso_nombre": paso_nombre,
                "subpaso_numero": subpaso_numero,
                "subpaso_nombre": subpaso_nombre,
                "componente": componente,
                "actor": actor,
                "estado_anterior": estado_anterior,
                "estado_nuevo": estado_nuevo,
                "tipo": tipo,
                "mensaje": mensaje,
                "detalle": detalle,
                "evidencia": evidencia,
                "http_method": http_method,
                "http_url": http_url,
                "http_status": http_status,
                "error_code": error_code,
                "error_message": error_message,
                "run_id": run_id,
                "run_url": run_url,
                "duracion_segundos": duracion_segundos,
            }
            try:
                broker = obtener_broker()
                broker.publish(deployment_id, evento_dict)
            except Exception as pub_err:
                # Si publish falla, el evento YA ESTÁ PERSISTIDO
                logger.warning(
                    f"Evento {event_id} persistido pero publicación SSE falló: {pub_err}"
                )
            return event_id
        except Exception as e:
            logger.error(f"Error registrando evento: {e}")
            return None

    def obtener_eventos(self, deployment_id: str) -> list:
        """Obtiene todos los eventos de un deployment ordenados cronológicamente."""
        try:
            conn = sqlite3.connect(self.ruta_db)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute(
                "SELECT * FROM event_logs WHERE deployment_id=? ORDER BY id ASC",
                (deployment_id,)
            )
            rows = [dict(r) for r in cursor.fetchall()]
            conn.close()
            return rows
        except Exception as e:
            logger.error(f"Error obteniendo eventos: {e}")
            return []

    def obtener_eventos_desde(self, deployment_id: str, last_event_id: str) -> list:
        """Obtiene eventos desde un event_id específico (para replay SSE / Last-Event-ID).

        Args:
            deployment_id: ID del deployment
            last_event_id: event_id exclusivo desde el cual recuperar

        Returns:
            Lista de eventos posteriores a last_event_id, ordenados por id ASC
        """
        try:
            conn = sqlite3.connect(self.ruta_db)
            conn.row_factory = sqlite3.Row
            cursor = conn.cursor()
            cursor.execute(
                """SELECT * FROM event_logs
                   WHERE deployment_id=?
                     AND event_id > ?
                   ORDER BY id ASC""",
                (deployment_id, last_event_id)
            )
            rows = [dict(r) for r in cursor.fetchall()]
            conn.close()
            return rows
        except Exception as e:
            logger.error(f"Error obteniendo eventos desde {last_event_id}: {e}")
            return []

    # ──────────────────────────────────────────────────────────
    # Actualización de estado
    # ──────────────────────────────────────────────────────────

    def actualizar_estado(
        self, solicitud: SolicitudProyecto, nuevo_estado: str,
        numero_paso: Optional[int] = None, detalle: str = "", evidencia: str = "",
        subpasos: Optional[list] = None,
        componente: str = "", actor: str = "",
        run_id: str = "", run_url: str = ""
    ) -> SolicitudProyecto:
        """Actualiza el estado de una solicitud y opcionalmente un paso.

        Args:
            subpasos: Lista opcional de dicts con subpasos.
                      Ej: [{"numero": 1, "nombre": "Inicio", "fecha_inicio": "...", "fecha_fin": "...", "duracion_segundos": 1.5, "estado": "COMPLETADO", "detalle": "...", "evidencia": "..."}]
        """
        estado_anterior = solicitud.estado
        solicitud.estado = nuevo_estado
        solicitud.fecha_actualizacion = _ahora()

        paso_nombre = ""
        if numero_paso:
            paso_info = next((p for p in solicitud.pasos if p["numero"] == numero_paso), None)
            paso_nombre = paso_info["nombre"] if paso_info else ""

            # Registrar subpasos si se proporcionan
            if subpasos:
                if paso_info:
                    paso_info["subpasos"] = subpasos

            if nuevo_estado == "FALLIDO":
                solicitud.finalizar_paso(numero_paso, "FALLIDO", detalle, evidencia)
                self._registrar_evento(
                    deployment_id=solicitud.deployment_id,
                    correlation_id=solicitud.correlation_id,
                    fase=paso_nombre, paso_numero=numero_paso, paso_nombre=paso_nombre,
                    componente=componente, actor=actor,
                    estado_anterior="EN_PROCESO", estado_nuevo="FALLIDO",
                    tipo="ERROR", mensaje=f"Paso {numero_paso} FALLIDO: {detalle}",
                    detalle=detalle, evidencia=evidencia,
                    run_id=run_id, run_url=run_url
                )
            else:
                solicitud.finalizar_paso(numero_paso, "COMPLETADO", detalle, evidencia)
                # Registrar evento de finalización de paso
                paso = next((p for p in solicitud.pasos if p["numero"] == numero_paso), None)
                self._registrar_evento(
                    deployment_id=solicitud.deployment_id,
                    correlation_id=solicitud.correlation_id,
                    fase=paso_nombre, paso_numero=numero_paso, paso_nombre=paso_nombre,
                    componente=componente, actor=actor,
                    estado_anterior="EN_PROCESO", estado_nuevo="COMPLETADO",
                    tipo="PASS", mensaje=f"Paso {numero_paso} COMPLETADO: {detalle}",
                    detalle=detalle, evidencia=evidencia,
                    duracion_segundos=paso["duracion_segundos"] if paso else None,
                    run_id=run_id, run_url=run_url
                )

            siguiente = numero_paso + 1
            if siguiente <= 13 and nuevo_estado != "FALLIDO":
                solicitud.iniciar_paso(siguiente, f"Iniciando paso {siguiente}")
                self._registrar_evento(
                    deployment_id=solicitud.deployment_id,
                    correlation_id=solicitud.correlation_id,
                    fase="", paso_numero=siguiente,
                    paso_nombre=next((p["nombre"] for p in solicitud.pasos if p["numero"] == siguiente), ""),
                    componente=componente, actor=actor,
                    estado_anterior="PENDIENTE", estado_nuevo="EN_PROCESO",
                    tipo="INFO", mensaje=f"Iniciando paso {siguiente}"
                )
        # NOTA: NO establecer resultado = "PASS" aquí.
        # El resultado solo debe establecerse por finalizar_solicitud(),
        # que verifica que TODOS los 13 pasos estén COMPLETADOS antes de permitir PASS.
        # (FASE 24 — anti-false-PASS)
        if nuevo_estado == "FALLIDO":
            solicitud.resultado = "FAIL"
            solicitud.error = detalle
        self._guardar(solicitud)
        return solicitud

    # ──────────────────────────────────────────────────────────
    # Ejecución de Factory (local)
    # ──────────────────────────────────────────────────────────

    def ejecutar_factory_local(self, solicitud: SolicitudProyecto) -> SolicitudProyecto:
        """Ejecuta la Factory localmente si PowerShell está disponible."""
        raiz_proyecto = Path(__file__).resolve().parent.parent.parent
        script_factory = raiz_proyecto / "tools" / "Crear-HermesProyecto.ps1"
        if not script_factory.exists():
            return self.actualizar_estado(
                solicitud, "FALLIDO", numero_paso=2,
                detalle=f"Script Factory no encontrado: {script_factory}", evidencia=""
            )
        # Verificar PowerShell
        try:
            subprocess.run(["powershell", "-Command", "Write-Host", "OK"],
                         capture_output=True, timeout=5)
        except (FileNotFoundError, subprocess.TimeoutExpired):
            return self.actualizar_estado(
                solicitud, "FALLIDO", numero_paso=2,
                detalle="PowerShell no disponible en este entorno", evidencia=""
            )
        # Iniciar Factory
        solicitud = self.actualizar_estado(
            solicitud, "CREANDO", numero_paso=1,
            detalle=f"Ejecutando Factory para {solicitud.nombre_proyecto}",
            evidencia=f"Script: {script_factory}"
        )
        try:
            comando = [
                "powershell", "-NoProfile", "-ExecutionPolicy", "Bypass",
                "-File", str(script_factory),
                "-NombreProyecto", solicitud.nombre_proyecto
            ]
            proceso = subprocess.Popen(
                comando, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                text=True, cwd=str(raiz_proyecto)
            )
            stdout, stderr = proceso.communicate(timeout=600)
            if proceso.returncode == 0:
                solicitud = self.actualizar_estado(
                    solicitud, "PUBLICANDO", numero_paso=2,
                    detalle="Factory completada exitosamente",
                    evidencia=stdout[-2000:] if stdout else "Factory OK"
                )
                for linea in (stdout or "").split("\n"):
                    if "repositorio remoto" in linea.lower():
                        solicitud.repo_url = linea.strip()
                    if "commit" in linea.lower() and len(linea) > 30:
                        solicitud.commit_sha = linea.strip().split()[-1]
                self._guardar(solicitud)
            else:
                error_msg = stderr[-1000:] if stderr else f"Exit code: {proceso.returncode}"
                solicitud = self.actualizar_estado(
                    solicitud, "FALLIDO", numero_paso=2,
                    detalle=f"Factory falló: {error_msg}",
                    evidencia=stdout[-2000:] if stdout else ""
                )
        except subprocess.TimeoutExpired:
            proceso.kill()
            solicitud = self.actualizar_estado(
                solicitud, "FALLIDO", numero_paso=2,
                detalle="Factory excedió el tiempo máximo (600s)", evidencia=""
            )
        except Exception as e:
            solicitud = self.actualizar_estado(
                solicitud, "FALLIDO", numero_paso=2,
                detalle=f"Error ejecutando Factory: {str(e)}", evidencia=""
            )
        return solicitud

    # ──────────────────────────────────────────────────────────
    # Métodos para Factory remota (GitHub Actions)
    # ──────────────────────────────────────────────────────────

    async def ejecutar_factory_remoto(
        self, solicitud: SolicitudProyecto
    ) -> Dict[str, Any]:
        """
        Dispara factory-run.yml en HERMES-ENTERPRISE via GitHub API
        (NO ejecuta PowerShell localmente).

        Args:
            solicitud: Solicitud de proyecto a procesar

        Returns:
            Dict con resultado del dispatch
        """
        from .servicio_github import ServicioGitHub

        solicitud = self.actualizar_estado(
            solicitud, "CREANDO", numero_paso=1,
            detalle=(
                f"Disparando Factory Runner (GitHub Actions) "
                f"para {solicitud.nombre_proyecto}"
            ),
            evidencia=(
                f"Modo: remoto (workflow_dispatch)"
            )
        )
        try:
            svc_gh = ServicioGitHub(workflow="factory-run.yml")
            resultado = await svc_gh.disparar_factory_runner(
                project_name=solicitud.nombre_proyecto,
                correlation_id=solicitud.correlation_id,
                deployment_id=solicitud.deployment_id,
                app_service_plan_id=solicitud.app_service_plan_id,
            )
            if resultado.get("exito"):
                solicitud = self.actualizar_estado(
                    solicitud, "CREANDO", numero_paso=2,
                    detalle=(
                        f"Factory Runner disparado exitosamente. "
                        f"Status: {resultado.get('status_code')}"
                    ),
                    evidencia=(
                        f"Dispatch: {resultado.get('payload_enviado', {})}"
                    )
                )
            else:
                solicitud = self.actualizar_estado(
                    solicitud, "FALLIDO", numero_paso=2,
                    detalle=(
                        f"Factory Runner fallo al disparar: "
                        f"{resultado.get('mensaje', 'Error desconocido')}"
                    ),
                    evidencia=(
                        f"Error: {resultado.get('error_tecnico', '')}"
                    )
                )
            self._guardar(solicitud)
            return resultado
        except Exception as e:
            solicitud = self.actualizar_estado(
                solicitud, "FALLIDO", numero_paso=2,
                detalle=f"Error disparando Factory Runner: {str(e)}",
                evidencia=""
            )
            self._guardar(solicitud)
            return {
                "exito": False,
                "mensaje": f"Error interno: {str(e)}",
                "error_tecnico": str(e),
            }

    # ──────────────────────────────────────────────────────────
    # Métodos para Control Plane (actualización remota)
    # ──────────────────────────────────────────────────────────

    def actualizar_desde_control_plane(
        self, deployment_id: str, numero_paso: int,
        estado_paso: str, detalle: str = "", evidencia: str = "",
        http_status: int = None, http_method: str = "POST",
        http_url: str = "",
        run_id: str = "", run_url: str = "",
        componente: str = "control_plane", actor: str = "github_actions",
        subpasos: Optional[list] = None,
        error_code: str = "", error_message: str = ""
    ) -> Optional[SolicitudProyecto]:
        """Actualiza el estado desde el Control Plane.

        Registra eventos de callback incluyendo fallos de comunicación.
        Si la solicitud no existe, registra evento de CALLBACK FAILED.
        """
        solicitud = self.obtener_solicitud(deployment_id)
        if not solicitud:
            logger.warning(f"SOLICITUD NO ENCONTRADA (callback fallido): {deployment_id}")
            self._registrar_evento(
                deployment_id=deployment_id,
                paso_numero=numero_paso, componente=componente, actor=actor,
                estado_nuevo="CALLBACK_FAILED", tipo="ERROR",
                mensaje=f"CALLBACK FALLIDO: deployment_id={deployment_id} no encontrado",
                detalle=detalle,
                http_method=http_method, http_url=http_url, http_status=http_status,
                error_code="NOT_FOUND", error_message=f"Solicitud {deployment_id} no existe",
                run_id=run_id, run_url=run_url
            )
            return None

        paso_nombre = next((p["nombre"] for p in solicitud.pasos if p["numero"] == numero_paso), "")
        if subpasos:
            paso_info = next((p for p in solicitud.pasos if p["numero"] == numero_paso), None)
            if paso_info:
                paso_info["subpasos"] = subpasos

        if estado_paso == "EN_PROCESO":
            solicitud.iniciar_paso(numero_paso, detalle)
            self._registrar_evento(
                deployment_id=solicitud.deployment_id,
                correlation_id=solicitud.correlation_id,
                fase=paso_nombre, paso_numero=numero_paso, paso_nombre=paso_nombre,
                componente=componente, actor=actor,
                estado_anterior="PENDIENTE", estado_nuevo="EN_PROCESO",
                tipo="INFO", mensaje=f"Callback: Paso {numero_paso} EN_PROCESO: {detalle}",
                detalle=detalle, evidencia=evidencia,
                http_method=http_method, http_url=http_url, http_status=http_status,
                run_id=run_id, run_url=run_url
            )
        elif estado_paso == "FALLIDO":
            solicitud.finalizar_paso(numero_paso, "FALLIDO", detalle, evidencia)
            self._registrar_evento(
                deployment_id=solicitud.deployment_id,
                correlation_id=solicitud.correlation_id,
                fase=paso_nombre, paso_numero=numero_paso, paso_nombre=paso_nombre,
                componente=componente, actor=actor,
                estado_anterior="EN_PROCESO", estado_nuevo="FALLIDO",
                tipo="ERROR", mensaje=f"Callback: Paso {numero_paso} FALLIDO: {detalle}",
                detalle=detalle, evidencia=evidencia,
                http_method=http_method, http_url=http_url, http_status=http_status,
                error_code=error_code, error_message=error_message,
                run_id=run_id, run_url=run_url
            )
        else:
            solicitud.finalizar_paso(numero_paso, estado_paso, detalle, evidencia)
            paso = next((p for p in solicitud.pasos if p["numero"] == numero_paso), None)
            self._registrar_evento(
                deployment_id=solicitud.deployment_id,
                correlation_id=solicitud.correlation_id,
                fase=paso_nombre, paso_numero=numero_paso, paso_nombre=paso_nombre,
                componente=componente, actor=actor,
                estado_anterior="EN_PROCESO", estado_nuevo="COMPLETADO",
                tipo="PASS", mensaje=f"Callback: Paso {numero_paso} COMPLETADO: {detalle}",
                detalle=detalle, evidencia=evidencia,
                http_method=http_method, http_url=http_url, http_status=http_status,
                duracion_segundos=paso["duracion_segundos"] if paso else None,
                run_id=run_id, run_url=run_url
            )
            if numero_paso == 13 and estado_paso == "COMPLETADO":
                # FASE 24 — anti-false-PASS: NO declarar COMPLETADO/PASS sin verificar
                # que TODOS los 13 pasos estén COMPLETADOS.
                pasos_pend = self._pasos_pendientes(solicitud)
                if not pasos_pend:
                    solicitud.estado = "COMPLETADO"
                    solicitud.resultado = "PASS"
                else:
                    # Hay pasos pendientes → NO establecer PASS
                    # El estado se recalculará desde _calcular_estado_global
                    logger.warning(
                        f"FASE-24: Callback paso 13 COMPLETADO pero {len(pasos_pend)} paso(s) "
                        f"pendiente(s): {[p['nombre'] for p in pasos_pend]}. "
                        f"NO se establece COMPLETADO/PASS."
                    )
            # Auto-iniciar siguiente paso tras callback exitoso
            if estado_paso == "COMPLETADO":
                siguiente = numero_paso + 1
                if siguiente <= 13:
                    sig_nombre = next((p["nombre"] for p in solicitud.pasos if p["numero"] == siguiente), "")
                    solicitud.iniciar_paso(siguiente, f"Callback auto-inicia paso {siguiente}")
                    self._registrar_evento(
                        deployment_id=solicitud.deployment_id,
                        correlation_id=solicitud.correlation_id,
                        paso_numero=siguiente, paso_nombre=sig_nombre,
                        componente=componente, actor=actor,
                        estado_anterior="PENDIENTE", estado_nuevo="EN_PROCESO",
                        tipo="INFO", mensaje=f"Auto-inicio paso {siguiente} tras callback paso {numero_paso}"
                    )
        solicitud.fecha_actualizacion = _ahora()
        self._guardar(solicitud)
        return solicitud

    def _calcular_estado_global(self, solicitud: SolicitudProyecto) -> str:
        """Calcula el estado global a partir de los 13 pasos canónicos.

        Reglas:
        - Si algún paso = FALLIDO  → FALLIDO
        - Si algún paso = EN_PROCESO → EN_PROCESO (o CREANDO)
        - Si algún paso = PENDIENTE  → PENDIENTE (o CREANDO)
        - Si todos = COMPLETADO → COMPLETADO

        Excepción: SOLICITADO se conserva cuando solo paso 1 (SOLICITUD)
        está EN_PROCESO y el resto están PENDIENTE, porque la solicitud
        aún no ha sido despachada al Factory Runner.
        """
        pendientes = 0
        en_proceso = 0
        fallidos = 0
        omitidos = 0
        completados = 0

        for paso in solicitud.pasos:
            estado = paso.get("estado", "PENDIENTE")
            if estado == "FALLIDO":
                fallidos += 1
            elif estado == "EN_PROCESO":
                en_proceso += 1
            elif estado == "PENDIENTE":
                pendientes += 1
            elif estado == "OMITIDO":
                omitidos += 1
            elif estado == "COMPLETADO":
                completados += 1

        if fallidos > 0:
            return "FALLIDO"
        # Preservar SOLICITADO si solo paso 1 está EN_PROCESO y el resto PENDIENTE
        if solicitud.estado == "SOLICITADO":
            if en_proceso == 1 and pendientes == len(solicitud.pasos) - 1:
                paso_uno = solicitud.pasos[0] if solicitud.pasos else {}
                if paso_uno.get("numero") == 1 and paso_uno.get("estado") == "EN_PROCESO":
                    return "SOLICITADO"
        if en_proceso > 0:
            return "EN_PROCESO"
        if pendientes > 0:
            return "CREANDO"
        if completados == len(solicitud.pasos):
            return "COMPLETADO"
        return solicitud.estado

    def _pasos_pendientes(self, solicitud: SolicitudProyecto) -> list:
        """Devuelve lista de pasos pendientes o en proceso."""
        return [
            {"numero": p["numero"], "nombre": p["nombre"], "estado": p["estado"]}
            for p in solicitud.pasos
            if p.get("estado") not in ("COMPLETADO", "FALLIDO", "OMITIDO")
        ]

    def validar_consistencia(self, deployment_id: str) -> dict:
        """Valida consistencia entre estado global y pasos.

        FASE 24 — Validación adversarial exhaustiva:
        - PASS no puede coexistir con pasos pendientes
        - COMPLETADO requiere todos los pasos COMPLETADOS
        - PASS requiere Control Plane existente y SUCCESS/COMPLETADO
        - PASS requiere readiness PASS
        - PASS requiere functional PASS
        - PASS requiere SHA no vacío
        - PASS requiere app_service_plan_id no vacío

        Returns:
            dict con: consistente (bool), estado_global,
                     pasos_pendientes, errores
        """
        solicitud = self.obtener_solicitud(deployment_id)
        if not solicitud:
            return {"consistente": False, "error": "Solicitud no encontrada"}

        estado_calculado = self._calcular_estado_global(solicitud)
        estado_actual = solicitud.estado
        resultado_actual = solicitud.resultado

        errores = []
        pasos_pend = self._pasos_pendientes(solicitud)

        # ════════════════════════════════════════════════════════════
        # REGLA 1: PASS no puede coexistir con pasos pendientes
        # ════════════════════════════════════════════════════════════
        if resultado_actual == "PASS" and pasos_pend:
            errores.append(
                f"INCONSISTENCIA: resultado=PASS pero {len(pasos_pend)} paso(s) pendiente(s): "
                f"{[p['nombre'] for p in pasos_pend]}"
            )

        # ════════════════════════════════════════════════════════════
        # REGLA 2: estado derivado debe coincidir con estado actual
        # ════════════════════════════════════════════════════════════
        if estado_calculado != estado_actual:
            if estado_actual == "COMPLETADO" and estado_calculado != "COMPLETADO":
                errores.append(
                    f"INCONSISTENCIA: estado={estado_actual} pero estado_calculado={estado_calculado}. "
                    f"Pasos pendientes: {[p['nombre'] for p in pasos_pend]}"
                )

        # ════════════════════════════════════════════════════════════
        # REGLA 3: Control Plane requerido para PASS (FASE 24)
        # ════════════════════════════════════════════════════════════
        if resultado_actual == "PASS":
            cp_id = solicitud.control_plane_run_id
            cp_status = solicitud.control_plane_status
            if not cp_id:
                errores.append(
                    "INCONSISTENCIA: resultado=PASS pero control_plane_run_id está vacío. "
                    "El Control Plane debe haberse ejecutado para declarar PASS."
                )
            elif cp_status not in ("COMPLETADO", "SUCCESS"):
                errores.append(
                    f"INCONSISTENCIA: resultado=PASS pero control_plane_status='{cp_status}' "
                    f"(se esperaba COMPLETADO o SUCCESS)."
                )

        # ════════════════════════════════════════════════════════════
        # REGLA 4: Readiness requerido para PASS (FASE 24)
        # ════════════════════════════════════════════════════════════
        if resultado_actual == "PASS":
            rdy = solicitud.readiness_result
            if not rdy:
                errores.append(
                    "INCONSISTENCIA: resultado=PASS pero readiness_result está vacío. "
                    "Readiness check debe haberse ejecutado y pasado."
                )

        # ════════════════════════════════════════════════════════════
        # REGLA 5: Functional requerido para PASS (FASE 24)
        # ════════════════════════════════════════════════════════════
        if resultado_actual == "PASS":
            func = solicitud.functional_result
            if not func:
                errores.append(
                    "INCONSISTENCIA: resultado=PASS pero functional_result está vacío. "
                    "Pruebas funcionales deben haberse ejecutado."
                )

        # ════════════════════════════════════════════════════════════
        # REGLA 6: SHA contract requerido (FASE 24)
        # ════════════════════════════════════════════════════════════
        if resultado_actual == "PASS" and not solicitud.commit_sha:
            errores.append(
                "INCONSISTENCIA: resultado=PASS pero commit_sha está vacío. "
                "SHA chain debe estar completa."
            )

        # ════════════════════════════════════════════════════════════
        # REGLA 7: App Service Plan requerido (FASE 24)
        # ════════════════════════════════════════════════════════════
        if resultado_actual == "PASS" and not solicitud.app_service_plan_id:
            errores.append(
                "INCONSISTENCIA: resultado=PASS pero app_service_plan_id está vacío. "
                "Plan contract debe estar completo."
            )

        return {
            "consistente": len(errores) == 0,
            "estado_global": estado_calculado,
            "estado_actual": estado_actual,
            "resultado": resultado_actual,
            "pasos_pendientes": pasos_pend,
            "errores": errores
        }

    def finalizar_solicitud(self, deployment_id: str, resultado: str = "PASS", error: str = "") -> Optional[SolicitudProyecto]:
        """Finaliza una solicitud con resultado PASS o FAIL.

        Validación adversarial:
        - Si resultado=PASS, TODOS los 13 pasos deben estar COMPLETADOS.
        - Si hay pasos pendientes → FAIL con HTTP 409 (raise ValueError).
        - Registra evento de finalización en Event Store.
        """
        solicitud = self.obtener_solicitud(deployment_id)
        if not solicitud:
            return None

        # Validación adversarial: PASS require todos los pasos COMPLETADOS
        if resultado == "PASS":
            pasos_pend = self._pasos_pendientes(solicitud)
            if pasos_pend:
                nombres_pend = [p["nombre"] for p in pasos_pend]
                raise ValueError(
                    f"No se puede finalizar con PASS: {len(pasos_pend)} paso(s) pendiente(s): "
                    f"{', '.join(nombres_pend)}. "
                    f"Finalice o complete todos los pasos antes de declarar PASS."
                )

        estado_anterior = solicitud.estado
        solicitud.estado = "COMPLETADO" if resultado == "PASS" else "FALLIDO"
        solicitud.resultado = resultado
        solicitud.error = error
        solicitud.fecha_fin = _ahora()
        solicitud.fecha_actualizacion = solicitud.fecha_fin

        # Calcular duración total
        try:
            from datetime import datetime
            inicio = datetime.fromisoformat(solicitud.fecha_solicitud.replace('Z', '+00:00'))
            fin = datetime.fromisoformat(solicitud.fecha_fin.replace('Z', '+00:00'))
            solicitud.duracion_total_segundos = int((fin - inicio).total_seconds())
        except Exception:
            pass

        for paso in solicitud.pasos:
            if paso["numero"] == 13 and paso["estado"] in ("PENDIENTE", "EN_PROCESO"):
                solicitud.finalizar_paso(
                    13, "COMPLETADO" if resultado == "PASS" else "FALLIDO",
                    error or "Implementación completada", resultado
                )
                break

        self._guardar(solicitud)

        # Registrar evento de finalización
        self._registrar_evento(
            deployment_id=solicitud.deployment_id,
            correlation_id=solicitud.correlation_id,
            estado_anterior=estado_anterior,
            estado_nuevo=solicitud.estado,
            tipo="PASS" if resultado == "PASS" else "FAIL",
            mensaje=f"Proyecto finalizado: resultado={resultado}, duración={solicitud.duracion_total_segundos}s",
            detalle=error or "Finalización exitosa",
            duracion_segundos=float(solicitud.duracion_total_segundos or 0)
        )

        return solicitud


# ═══════════════════════════════════════════════════════════════
# Instancia singleton para la aplicación
# ═══════════════════════════════════════════════════════════════

_instancia_servicio: Optional[ServicioFabrica] = None

def obtener_servicio_fabrica() -> ServicioFabrica:
    """Devuelve la instancia singleton del servicio."""
    global _instancia_servicio
    if _instancia_servicio is None:
        _instancia_servicio = ServicioFabrica()
    return _instancia_servicio
