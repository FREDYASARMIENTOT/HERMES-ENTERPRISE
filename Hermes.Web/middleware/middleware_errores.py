"""
====================================================================
middleware_errores.py — Error Handling Middleware para Hermes.Web
====================================================================

Este middleware captura excepciones no manejadas y devuelve
respuestas JSON consistentes en lugar de errores HTML por defecto.
"""

import logging
import traceback
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import JSONResponse
from typing import Callable, Awaitable

logger = logging.getLogger("Hermes.Web.Middleware.Errores")


class ErrorHandlingMiddleware(BaseHTTPMiddleware):
    """
    Middleware que captura excepciones y devuelve JSON estructurado.
    """

    def __init__(self, app):
        super().__init__(app)
        logger.info("ErrorHandlingMiddleware inicializado.")

    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[JSONResponse]]
    ) -> JSONResponse:
        try:
            return await call_next(request)
        except Exception as error:
            correlation_id = getattr(request.state, "correlation_id", "no-asignado")
            logger.error(
                f"[{correlation_id}] Excepción no manejada: {str(error)}\n"
                f"{traceback.format_exc()}"
            )
            return JSONResponse(
                status_code=500,
                content={
                    "error": "Error interno del servidor",
                    "detalle": str(error),
                    "correlation_id": correlation_id,
                    "ruta": request.url.path,
                    "metodo": request.method
                }
            )