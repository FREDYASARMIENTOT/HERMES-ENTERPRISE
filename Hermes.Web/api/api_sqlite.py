"""
api_sqlite.py — Router de /api/sqlite para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.SQLite")
router = APIRouter()


@router.get("/sqlite", summary="Obtiene el estado de la base SQLite")
async def obtener_sqlite(request: Request):
    """Obtiene información de la base de datos SQLite."""
    try:
        # Ruta de la DB del Portal (solicitudes_proyecto)
        import os
        db_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), "data", "proyecto.db")
        if not os.path.exists(db_path):
            return {
                "estado": "no_verificado",
                "db_path": db_path,
                "nota": "Archivo DB no encontrado en data/"
            }
        import sqlite3
        conn = sqlite3.connect(db_path)
        c = conn.cursor()
        c.execute("SELECT COUNT(*) FROM solicitudes_proyecto")
        total_solicitudes = c.fetchone()[0]
        c.execute("SELECT COUNT(*) FROM solicitudes_proyecto WHERE estado = 'COMPLETADO'")
        completadas = c.fetchone()[0]
        c.execute("SELECT COUNT(*) FROM solicitudes_proyecto WHERE estado = 'FALLIDO'")
        fallidas = c.fetchone()[0]
        tamanio_kb = round(os.path.getsize(db_path) / 1024, 1)
        conn.close()
        return {
            "estado": "verificado",
            "db_path": db_path,
            "tamanio_kb": tamanio_kb,
            "total_solicitudes": total_solicitudes,
            "completadas": completadas,
            "fallidas": fallidas,
            "nota": "Base de datos SQLite operativa"
        }
    except Exception as e:
        logger.error(f"Error al verificar SQLite: {e}")
        return {
            "estado": "error",
            "error": str(e),
            "nota": "Error al consultar la base de datos"
        }