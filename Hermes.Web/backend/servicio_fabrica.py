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
        # Timing
        self.fecha_fin: str = ""
        self.duracion_total_segundos: int = 0
        self._inicializar_pasos()

    def _inicializar_pasos(self) -> None:
        """Inicializa los 13 pasos canónicos con estado PENDIENTE."""
        self.pasos = []
        for paso in PASOS_CANONICOS:
            self.pasos.append({
                "numero": paso["numero"], "nombre": paso["nombre"],
                "descripcion": paso["descripcion"], "estado": "PENDIENTE",
                "fecha_inicio": None, "fecha_fin": None,
                "duracion_segundos": None, "detalle": "", "evidencia": ""
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
                    duracion_total_segundos INTEGER DEFAULT 0
                )
            """)
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_solicitudes_estado ON solicitudes_proyecto(estado)")
            cursor.execute("CREATE INDEX IF NOT EXISTS idx_solicitudes_nombre ON solicitudes_proyecto(nombre_proyecto)")

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

    def _guardar(self, solicitud: SolicitudProyecto) -> None:
        """Guarda o actualiza una solicitud en SQLite."""
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
                 fecha_fin, duracion_total_segundos)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?,
                 ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
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
                datos.get("duracion_total_segundos", 0)
            ))
            conn.commit()
            conn.close()
        except Exception as e:
            logger.error(f"Error guardando solicitud: {e}")
            raise

    # ──────────────────────────────────────────────────────────
    # Actualización de estado
    # ──────────────────────────────────────────────────────────

    def actualizar_estado(
        self, solicitud: SolicitudProyecto, nuevo_estado: str,
        numero_paso: Optional[int] = None, detalle: str = "", evidencia: str = ""
    ) -> SolicitudProyecto:
        """Actualiza el estado de una solicitud y opcionalmente un paso."""
        solicitud.estado = nuevo_estado
        solicitud.fecha_actualizacion = _ahora()
        if numero_paso:
            if nuevo_estado == "FALLIDO":
                solicitud.finalizar_paso(numero_paso, "FALLIDO", detalle, evidencia)
            else:
                solicitud.finalizar_paso(numero_paso, "COMPLETADO", detalle, evidencia)
            siguiente = numero_paso + 1
            if siguiente <= 13 and nuevo_estado != "FALLIDO":
                solicitud.iniciar_paso(siguiente, f"Iniciando paso {siguiente}")
        if nuevo_estado == "COMPLETADO":
            solicitud.resultado = "PASS"
        elif nuevo_estado == "FALLIDO":
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
        estado_paso: str, detalle: str = "", evidencia: str = ""
    ) -> Optional[SolicitudProyecto]:
        """Actualiza el estado desde el Control Plane."""
        solicitud = self.obtener_solicitud(deployment_id)
        if not solicitud:
            logger.warning(f"Solicitud no encontrada: {deployment_id}")
            return None
        if estado_paso == "EN_PROCESO":
            solicitud.iniciar_paso(numero_paso, detalle)
        else:
            if estado_paso == "FALLIDO":
                return self.actualizar_estado(
                    solicitud, "FALLIDO", numero_paso=numero_paso,
                    detalle=detalle, evidencia=evidencia
                )
            solicitud.finalizar_paso(numero_paso, estado_paso, detalle, evidencia)
            if numero_paso == 13 and estado_paso == "COMPLETADO":
                solicitud.estado = "COMPLETADO"
                solicitud.resultado = "PASS"
            solicitud.fecha_actualizacion = _ahora()
        self._guardar(solicitud)
        return solicitud

    def finalizar_solicitud(self, deployment_id: str, resultado: str = "PASS", error: str = "") -> Optional[SolicitudProyecto]:
        """Finaliza una solicitud con resultado PASS o FAIL."""
        solicitud = self.obtener_solicitud(deployment_id)
        if not solicitud:
            return None
        solicitud.estado = "COMPLETADO" if resultado == "PASS" else "FALLIDO"
        solicitud.resultado = resultado
        solicitud.error = error
        solicitud.fecha_actualizacion = _ahora()
        for paso in solicitud.pasos:
            if paso["numero"] == 13 and paso["estado"] in ("PENDIENTE", "EN_PROCESO"):
                solicitud.finalizar_paso(
                    13, "COMPLETADO" if resultado == "PASS" else "FALLIDO",
                    error or "Implementación completada", resultado
                )
                break
        self._guardar(solicitud)
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
