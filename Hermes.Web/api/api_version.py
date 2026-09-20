"""
====================================================================
api_version.py — Router de /api/version para la Fábrica de Proyectos UR
====================================================================

Este router expone endpoints para consultar la versión de
Fábrica de Proyectos UR y sus componentes.

Endpoints:
    GET /api/version → Versión completa del sistema
"""

import os
import platform
import logging
import subprocess
from datetime import datetime, timezone
from pathlib import Path
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Version")
router = APIRouter()


@router.get("/version", summary="Obtiene la versión de la Fábrica de Proyectos UR")
async def obtener_version(request: Request):
    """
    Obtiene la versión completa de la Fábrica de Proyectos UR.
    
    Returns:
        Dict con versiones de todos los componentes del sistema
    """
    correlation_id = getattr(request.state, "correlation_id", "no-asignado")
    
    # Obtener versión de Git — priorizar env vars de CI/CD, fallback a git local
    commit_hash = os.environ.get("HERMES_BUILD_COMMIT", "desconocido")
    branch = os.environ.get("HERMES_BUILD_BRANCH", "desconocido")
    build_timestamp = os.environ.get("HERMES_BUILD_TIMESTAMP", "")

    # Si no hay env vars, intentar git local (desarrollo)
    if commit_hash == "desconocido":
        try:
            commit = subprocess.run(
                ["git", "rev-parse", "--short", "HEAD"],
                capture_output=True, text=True, timeout=5
            )
            if commit.returncode == 0:
                commit_hash = commit.stdout.strip()
        except Exception:
            pass

    if branch == "desconocido":
        try:
            b = subprocess.run(
                ["git", "rev-parse", "--abbrev-ref", "HEAD"],
                capture_output=True, text=True, timeout=5
            )
            if b.returncode == 0:
                branch = b.stdout.strip()
        except Exception:
            pass

    # Environment name from env var, fallback to auto-detect
    environment = os.environ.get("HERMES_ENVIRONMENT", "")
    if not environment:
        if "WEBSITE_SITE_NAME" in os.environ:
            environment = "azure"
        else:
            environment = "development"

    return {
        "aplicacion": "Fábrica de Proyectos UR",
        "version": os.environ.get("HERMES_BUILD_VERSION", "2.0.0"),
        "version_api": "2.0.0",
        "commit": commit_hash,
        "branch": branch,
        "build_timestamp": build_timestamp,
        "python_version": platform.python_version(),
        "plataforma": platform.platform(),
        "environment": environment,
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "correlation_id": correlation_id
    }