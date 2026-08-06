"""
====================================================================
middleware_logging.py — Logging Middleware para Hermes.Web
====================================================================

Este middleware registra todas las solicitudes y respuestas HTTP
que pasan por el sistema. Incluye información del método, ruta,
código de estado, duración y CorrelationId.

Headers incluidos en el log:
    - X-Correlation-ID
    - User-Agent
    - Content-Type
    - Content-Length
"""

import time
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from typing import Callable, Awaitable

logger = logging.getLogger("Hermes.Web.Middleware.Logging")


class LoggingMiddleware(BaseHTTPMiddleware):
    """
    Middleware que registra todas las solicitudes y respuestas HTTP.
    Proporciona logs detallados para depuración y monitoreo.
    """
    
    def __init__(self, app):
        super().__init__(app)
        logger.info("LoggingMiddleware inicializado.")
    
    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        """
        Registra una solicitud entrante y la respuesta correspondiente.
        """
        # Obtener CorrelationId (asignado por CorrelationIdMiddleware)
        correlation_id = getattr(request.state, "correlation_id", "no-asignado")
        
        # Información de la solicitud
        metodo = request.method
        ruta = request.url.path
        query_params = str(request.url.query)
        client_host = request.client.host if request.client else "desconocido"
        user_agent = request.headers.get("user-agent", "desconocido")
        content_type = request.headers.get("content-type", "desconocido")
        
        # Registrar solicitud entrante
        logger.info(
            f"[{correlation_id}] → {metodo} {ruta} "
            f"(desde: {client_host}, UA: {user_agent[:60]})"
        )
        
        # Medir tiempo de procesamiento
        tiempo_inicio = time.time()
        
        try:
            # Pasar al siguiente middleware/handler
            respuesta: Response = await call_next(request)
            
            # Calcular duración
            duracion_ms = round((time.time() - tiempo_inicio) * 1000, 2)
            
            # Registrar respuesta
            logger.info(
                f"[{correlation_id}] ← {respuesta.status_code} {metodo} {ruta} "
                f"({duracion_ms}ms)"
            )
            
            return respuesta
            
        except Exception as error:
            # Registrar excepción
            duracion_ms = round((time.time() - tiempo_inicio) * 1000, 2)
            logger.error(
                f"[{correlation_id}] ✗ {metodo} {ruta} "
                f"ERROR: {str(error)} ({duracion_ms}ms)"
            )
            raise