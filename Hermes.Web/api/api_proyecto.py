"""
====================================================================
api_proyecto.py — Router de /api/proyecto para Hermes.Web
====================================================================

Endpoints:
    GET /api/proyecto → Estado del proyecto Hermes
"""

import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Proyecto")
router = APIRouter()


@router.get("/proyecto", summary="Obtiene el estado del proyecto Hermes")
async def obtener_proyecto(request: Request):
    """
    Obtiene información del proyecto Hermes Enterprise actual desde DB real.
    """
    import os
    from pathlib import Path
    from datetime import datetime, timezone

    db_path = Path(__file__).resolve().parent.parent / "data" / "proyecto.db"
    stats = {
        "total": 0,
        "completados": 0,
        "fallidos": 0,
        "en_progreso": 0,
        "ultimo_proyecto": "",
    }

    if db_path.exists() and db_path.stat().st_size > 0:
        import sqlite3
        try:
            conn = sqlite3.connect(str(db_path))
            c = conn.cursor()
            c.execute("SELECT COUNT(*) FROM solicitudes_proyecto")
            stats["total"] = c.fetchone()[0]
            c.execute("SELECT COUNT(*) FROM solicitudes_proyecto WHERE estado='COMPLETADO'")
            stats["completados"] = c.fetchone()[0]
            c.execute("SELECT COUNT(*) FROM solicitudes_proyecto WHERE estado='FALLIDO'")
            stats["fallidos"] = c.fetchone()[0]
            c.execute("SELECT COUNT(*) FROM solicitudes_proyecto WHERE estado NOT IN ('COMPLETADO','FALLIDO')")
            stats["en_progreso"] = c.fetchone()[0]
            c.execute("SELECT nombre_proyecto FROM solicitudes_proyecto ORDER BY fecha_solicitud DESC LIMIT 1")
            row = c.fetchone()
            if row:
                stats["ultimo_proyecto"] = row[0]
            conn.close()
        except Exception:
            pass

    return {
        "proyecto": "Fábrica de Proyectos UR",
        "estado": "activo",
        "version": os.environ.get("HERMES_BUILD_VERSION", "2.0.0"),
        "portal": "AS-HermesPortal",
        "portal_url": "https://as-hermesportal.azurewebsites.net",
        "estadisticas": stats,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }