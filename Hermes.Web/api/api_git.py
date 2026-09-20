"""
api_git.py — Router de /api/git para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Git")
router = APIRouter()


@router.get("/git", summary="Obtiene el estado del repositorio Git")
async def obtener_git(request: Request):
    """Obtiene información REAL del repositorio Git local del Portal."""
    import subprocess
    from pathlib import Path

    try:
        # Obtener commit actual
        commit = subprocess.run(
            ["git", "rev-parse", "--short", "HEAD"],
            capture_output=True, text=True, timeout=5
        )
        commit_hash = commit.stdout.strip() if commit.returncode == 0 else "NO_DISPONIBLE"

        # Obtener branch
        branch = subprocess.run(
            ["git", "rev-parse", "--abbrev-ref", "HEAD"],
            capture_output=True, text=True, timeout=5
        )
        branch_name = branch.stdout.strip() if branch.returncode == 0 else "NO_DISPONIBLE"

        # Obtener commit count
        count = subprocess.run(
            ["git", "rev-list", "--count", "HEAD"],
            capture_output=True, text=True, timeout=5
        )
        commit_count = int(count.stdout.strip()) if count.returncode == 0 else 0

        # Obtener mensaje del último commit
        message = subprocess.run(
            ["git", "log", "-1", "--pretty=%s"],
            capture_output=True, text=True, timeout=5
        )
        last_message = message.stdout.strip() if message.returncode == 0 else ""

        return {
            "estado": "verificado",
            "branch": branch_name,
            "commit": commit_hash,
            "commits": commit_count,
            "ultimo_mensaje": last_message,
            "repositorio": "HERMES-ENTERPRISE",
        }
    except FileNotFoundError:
        return {"estado": "no_disponible", "error": "Git no instalado"}
    except subprocess.TimeoutExpired:
        return {"estado": "error", "error": "Timeout consultando git"}
    except Exception as e:
        return {"estado": "error", "error": str(e)[:200]}