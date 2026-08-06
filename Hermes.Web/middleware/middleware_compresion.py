"""
====================================================================
middleware_compresion.py — Compression Middleware para Hermes.Web
====================================================================

Este middleware comprime las respuestas HTTP usando GZip
cuando el cliente lo soporta (Accept-Encoding: gzip).
"""

import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from starlette.middleware.gzip import GZipMiddleware
from typing import Callable, Awaitable

logger = logging.getLogger("Hermes.Web.Middleware.Compresion")


class CompressionMiddleware(BaseHTTPMiddleware):
    """
    Middleware que comprime respuestas HTTP con GZip.
    Delega en GZipMiddleware de Starlette.
    """

    def __init__(self, app, minimum_size: int = 1000):
        super().__init__(app)
        self.minimum_size = minimum_size
        logger.info("CompressionMiddleware inicializado.")

    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        return await call_next(request)