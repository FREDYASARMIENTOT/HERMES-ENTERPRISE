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
    Obtiene información del proyecto Hermes Enterprise actual.
    """
    return {
        "proyecto": "Hermes Enterprise",
        "estado": "activo",
        "raiz": str(request.app.state.root_path) if hasattr(request.app.state, "root_path") else None
    }