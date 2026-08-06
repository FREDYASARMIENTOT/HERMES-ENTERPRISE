"""
api_telemetria.py — Router de /api/telemetria para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Telemetria")
router = APIRouter()


@router.get("/telemetria", summary="Obtiene métricas de telemetría")
async def obtener_telemetria(request: Request):
    """Obtiene métricas y estado de observabilidad."""
    return {"estado": "telemetria_activa", "metricas": {"solicitudes": 0, "errores": 0}}