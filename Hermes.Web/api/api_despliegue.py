"""
api_despliegue.py — Router de /api/despliegue para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Despliegue")
router = APIRouter()


@router.get("/despliegue", summary="Obtiene el estado del despliegue")
async def obtener_despliegue(request: Request):
    """Obtiene información del despliegue actual."""
    return {"estado": "produccion", "plataforma": "Azure App Service", "region": "East US"}