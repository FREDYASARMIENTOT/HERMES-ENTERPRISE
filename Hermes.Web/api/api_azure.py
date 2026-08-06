"""
api_azure.py — Router de /api/azure para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Azure")
router = APIRouter()


@router.get("/azure", summary="Obtiene el estado de la configuracion Azure")
async def obtener_azure(request: Request):
    """Obtiene información de la configuración Azure."""
    return {"estado": "no_configurado", "mensaje": "Usar Set-HermesAzureConfiguration desde PowerShell"}