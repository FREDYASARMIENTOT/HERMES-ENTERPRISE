"""
api_github.py — Router de /api/github para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.GitHub")
router = APIRouter()


@router.get("/github", summary="Obtiene el estado del repositorio GitHub")
async def obtener_github(request: Request):
    """Obtiene información del repositorio GitHub remoto."""
    return {"estado": "repositorio_remoto_detectado", "url": "https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE"}