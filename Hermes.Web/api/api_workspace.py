"""
====================================================================
api_workspace.py — Router de /api/workspace para Hermes.Web
====================================================================

Endpoints:
    GET /api/workspace → Estado del workspace
"""

import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Workspace")
router = APIRouter()


@router.get("/workspace", summary="Obtiene el estado del workspace")
async def obtener_workspace(request: Request):
    """Obtiene información del workspace actual."""
    return {"estado": "workspace_no_configurado", "nota": "Usar Get-HermesWorkspace desde PowerShell"}