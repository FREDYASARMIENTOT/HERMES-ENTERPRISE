"""
api_github.py — Router de /api/github para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.GitHub")
router = APIRouter()


@router.get("/github", summary="Obtiene el estado del repositorio GitHub")
async def obtener_github(request: Request):
    """Obtiene información REAL de la integración GitHub del Portal."""
    try:
        from Hermes.Web.backend.servicio_github import obtener_servicio_github
        servicio_github = obtener_servicio_github()
        config = servicio_github.validar_configuracion()

        # Verificar repositorio HERMES-ENTERPRISE
        repo_info = servicio_github.verificar_existencia_repositorio(
            owner="FREDYASARMIENTOT",
            repo="HERMES-ENTERPRISE",
        )

        return {
            "estado": "verificado" if config.get("valido") else "no_configurado",
            "token_configurado": config.get("configuracion", {}).get("token_configurado", False),
            "propietario": "FREDYASARMIENTOT",
            "repositorio": "HERMES-ENTERPRISE",
            "repo_existe": repo_info.get("exists", False),
            "repo_url": repo_info.get("html_url", ""),
            "repo_visibility": repo_info.get("visibility", ""),
            "repo_default_branch": repo_info.get("default_branch", ""),
            "httpx_disponible": servicio_github._httpx_disponible,
            "workflow_factory": "factory-run.yml",
            "workflow_control_plane": "deploy-child.yml",
            "errores": config.get("errores", []),
            "advertencias": config.get("advertencias", []),
        }
    except ImportError:
        return {"estado": "error", "error": "servicio_github no disponible"}
    except Exception as e:
        return {"estado": "error", "error": str(e)[:200]}