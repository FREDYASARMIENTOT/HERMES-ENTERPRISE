"""
====================================================================
middleware_timing.py — Timing Middleware para Hermes.Web
====================================================================

Este middleware mide el tiempo de procesamiento de cada solicitud
y lo agrega al header de respuesta X-Processing-Time.

Headers de respuesta:
    - X-Processing-Time: Tiempo de procesamiento en milisegundos
"""

import time
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from typing import Callable, Awaitable

logger = logging.getLogger("Hermes.Web.Middleware.Timing")


class TimingMiddleware(BaseHTTPMiddleware):
    """
    Middleware que mide y registra el tiempo de procesamiento.
    Agrega el header X-Processing-Time a todas las respuestas.
    """
    
    def __init__(self, app):
        super().__init__(app)
        logger.info("TimingMiddleware inicializado.")
    
    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        """
        Mide el tiempo de procesamiento y lo agrega a la respuesta.
        """
        tiempo_inicio = time.time()
        
        # Pasar al siguiente middleware/handler
        respuesta: Response = await call_next(request)
        
        # Calcular tiempo de procesamiento
        duracion_ms = round((time.time() - tiempo_inicio) * 1000, 2)
        
        # Agregar header con el tiempo de procesamiento
        respuesta.headers["X-Processing-Time"] = str(duracion_ms)
        
        return respuesta