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
    """Obtiene información del workspace actual del Portal."""
    import os
    from pathlib import Path

    raiz = Path(__file__).resolve().parent.parent.parent  # HERMES-ENTERPRISE/
    return {
        "estado": "verificado",
        "raiz": str(raiz),
        "sistema": "HERMES-ENTERPRISE",
        "directorios": {
            "web": str(raiz / "Hermes.Web"),
            "templates": str(raiz / "Hermes.Web" / "templates"),
            "data": str(raiz / "Hermes.Web" / "data"),
            "tools": str(raiz / "tools"),
            "engine": str(raiz / "engine"),
            "docs": str(raiz / "docs"),
        },
        "modulos_principales": [
            d.name for d in raiz.iterdir()
            if d.is_dir() and not d.name.startswith((".", "_", "node_modules"))
        ],
    }