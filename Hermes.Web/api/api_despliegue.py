"""
api_despliegue.py — Router de /api/despliegue para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Despliegue")
router = APIRouter()


@router.get("/despliegue", summary="Obtiene el estado del despliegue")
async def obtener_despliegue(request: Request):
    """Obtiene información real del despliegue actual del Portal."""
    import os
    import platform
    from datetime import datetime, timezone

    # Detectar entorno
    environment = os.environ.get("HERMES_ENVIRONMENT", "")
    if not environment:
        environment = "azure" if "WEBSITE_SITE_NAME" in os.environ else "development"

    # Detectar versión
    version = os.environ.get("HERMES_BUILD_VERSION", "2.0.0")
    commit = os.environ.get("HERMES_BUILD_COMMIT", "")
    build_timestamp = os.environ.get("HERMES_BUILD_TIMESTAMP", "")

    # Hostname
    hostname = os.environ.get("WEBSITE_HOSTNAME", "")
    site_name = os.environ.get("WEBSITE_SITE_NAME", "")

    return {
        "estado": "desplegado" if site_name else "local",
        "environment": environment,
        "platform": f"Python {platform.python_version()} on {platform.system()}",
        "app": "Hermes Enterprise Portal",
        "version": version,
        "commit": commit,
        "build_timestamp": build_timestamp,
        "hostname": hostname,
        "site_name": site_name,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }