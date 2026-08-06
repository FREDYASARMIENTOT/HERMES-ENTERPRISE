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
    return {"estado": "no_verificado", "nota": "Usar comandos Hermes.Commands para consultas SQLite"}