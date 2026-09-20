"""
api_telemetria.py — Router de /api/telemetria para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Telemetria")
router = APIRouter()


@router.get("/telemetria", summary="Obtiene métricas de telemetría")
async def obtener_telemetria(request: Request):
    """Obtiene métricas reales desde la base de datos."""
    try:
        from pathlib import Path
        import os
        import sqlite3

        db_path = Path(__file__).resolve().parent.parent / "data" / "fabrica.db"
        metrics = {
            "solicitudes": 0,
            "completados": 0,
            "fallidos": 0,
            "en_progreso": 0,
            "total_eventos": 0,
        }

        if db_path.exists() and db_path.stat().st_size > 0:
            conn = sqlite3.connect(str(db_path))
            c = conn.cursor()
            c.execute("SELECT COUNT(*) FROM solicitudes_proyecto")
            metrics["solicitudes"] = c.fetchone()[0]
            c.execute("SELECT COUNT(*) FROM solicitudes_proyecto WHERE estado='COMPLETADO'")
            metrics["completados"] = c.fetchone()[0]
            c.execute("SELECT COUNT(*) FROM solicitudes_proyecto WHERE estado='FALLIDO'")
            metrics["fallidos"] = c.fetchone()[0]
            c.execute("SELECT COUNT(*) FROM solicitudes_proyecto WHERE estado NOT IN ('COMPLETADO','FALLIDO')")
            metrics["en_progreso"] = c.fetchone()[0]
            c.execute("SELECT COUNT(*) FROM event_logs")
            metrics["total_eventos"] = c.fetchone()[0]
            conn.close()

        return {
            "estado": "telemetria_activa",
            "metricas": metrics,
            "db_size_kb": round(db_path.stat().st_size / 1024, 1) if db_path.exists() else 0,
        }
    except Exception as e:
        return {"estado": "error", "metricas": {}, "error": str(e)[:200]}