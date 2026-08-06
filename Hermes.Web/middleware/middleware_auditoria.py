"""
===================================================================
middleware_auditoria.py — Auditoría Middleware para Hermes.Web
===================================================================

Este middleware registra eventos de auditoría para operaciones
críticas del sistema (creación, modificación, eliminación).
"""

import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from typing import Callable, Awaitable

logger = logging.getLogger("Hermes.Web.Middleware.Auditoria")

METODOS_CRITICOS = {"POST", "PUT", "PATCH", "DELETE"}


class AuditoriaMiddleware(BaseHTTPMiddleware):
    """
    Middleware que registra eventos de auditoría para métodos críticos.
    """

    def __init__(self, app):
        super().__init__(app)
        logger.info("AuditoriaMiddleware inicializado.")

    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        correlation_id = getattr(request.state, "correlation_id", "no-asignado")
        respuesta: Response = await call_next(request)

        if request.method in METODOS_CRITICOS and 200 <= respuesta.status_code < 300:
            logger.warning(
                f"[AUDITORIA][{correlation_id}] {request.method} {request.url.path} "
                f"→ {respuesta.status_code}"
            )

        return respuesta