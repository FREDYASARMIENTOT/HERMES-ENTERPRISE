"""
api_bootstrap.py — Router de /api/bootstrap para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Bootstrap")
router = APIRouter()


@router.get("/bootstrap", summary="Obtiene el estado del proceso Bootstrap")
async def obtener_bootstrap(request: Request):
    """Obtiene información del proceso Bootstrap de Hermes."""
    return {"estado": "bootstrap_completado", "sistema": "HERMES-ENTERPRISE"}