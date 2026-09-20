"""
api_bootstrap.py — Router de /api/bootstrap para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Bootstrap")
router = APIRouter()


@router.get("/bootstrap", summary="Obtiene el estado del proceso Bootstrap")
async def obtener_bootstrap(request: Request):
    """Obtiene información del proceso Bootstrap real del Portal."""
    import os
    from pathlib import Path

    raiz = Path(__file__).resolve().parent.parent.parent
    db_path = raiz / "Hermes.Web" / "data" / "proyecto.db"
    deployment_path = raiz / "Hermes.Web" / "deployment"

    return {
        "estado": "verificado",
        "sistema": "HERMES-ENTERPRISE",
        "bootstrap_version": os.environ.get("HERMES_BOOTSTRAP_VERSION", "2.0.0"),
        "db_exists": db_path.exists(),
        "db_path": str(db_path),
        "deployment_path_exists": deployment_path.exists(),
        "components": {
            "web_app": "AS-HermesPortal",
            "app_service_plan": "ASP-HERMES-PORTAL",
            "resource_group": "RG-Hermes-Proyectos",
            "subscription": "01bfad48-c092-4712-bc72-f141eb01a8d4",
        },
    }