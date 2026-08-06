"""
api_entorno.py — Router de /api/entorno para Hermes.Web
"""
import platform
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Entorno")
router = APIRouter()


@router.get("/entorno", summary="Obtiene el estado del entorno Python")
async def obtener_entorno(request: Request):
    """Obtiene información del entorno Python actual."""
    return {
        "python_version": platform.python_version(),
        "plataforma": platform.platform(),
        "sistema": platform.system(),
        "procesador": platform.processor()
    }