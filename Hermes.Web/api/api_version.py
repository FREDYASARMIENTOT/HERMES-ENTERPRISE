"""
====================================================================
api_version.py — Router de /api/version para Hermes.Web
====================================================================

Este router expone endpoints para consultar la versión de
Hermes Enterprise y sus componentes.

Endpoints:
    GET /api/version → Versión completa del sistema
"""

import platform
import logging
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Version")
router = APIRouter()


@router.get("/version", summary="Obtiene la versión de Hermes Enterprise")
async def obtener_version(request: Request):
    """
    Obtiene la versión completa de Hermes Enterprise.
    
    Returns:
        Dict con versiones de todos los componentes del sistema
    """
    correlation_id = getattr(request.state, "correlation_id", "no-asignado")
    
    # Obtener versión de Git
    commit_hash = "desconocido"
    branch = "desconocido"
    try:
        commit = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5
        )
        if commit.returncode == 0:
            commit_hash = commit.stdout.strip()
        
        b = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True, text=True, timeout=5
        )
        if b.returncode == 0:
            branch = b.stdout.strip()
    except Exception:
        pass
    
    return {
        "aplicacion": "Hermes Enterprise",
        "version": "2.0.0",
        "version_api": "2.0.0",
        "commit": commit_hash,
        "branch": branch,
        "python_version": platform.python_version(),
        "plataforma": platform.platform(),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "correlation_id": correlation_id
    }