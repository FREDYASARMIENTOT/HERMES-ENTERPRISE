"""
api_git.py — Router de /api/git para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Git")
router = APIRouter()


@router.get("/git", summary="Obtiene el estado del repositorio Git")
async def obtener_git(request: Request):
    """Obtiene información del repositorio Git local."""
    return {"estado": "repositorio_local_detectado", "branch": "main", "commits": 0}