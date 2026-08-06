"""
====================================================================
middleware_correlation.py — CorrelationId Middleware para Hermes.Web
====================================================================

Este middleware asigna un CorrelationId único a cada solicitud HTTP
entrante. El CorrelationId se propaga a través de toda la cadena de
procesamiento y se incluye en los logs y respuestas para permitir
la trazabilidad completa de cada solicitud.

Flujo:
    1. Recibe una solicitud HTTP entrante
    2. Busca un CorrelationId en el header X-Correlation-ID
    3. Si no existe, genera uno nuevo (UUID v4)
    4. Lo asigna al objeto Request.state
    5. Lo agrega al header de la respuesta
    6. Pasa la solicitud al siguiente middleware o handler

Headers:
    Request:  X-Correlation-ID (opcional, entrada)
    Response: X-Correlation-ID (siempre, salida)
"""

import uuid
import logging
from starlette.middleware.base import BaseHTTPMiddleware
from starlette.requests import Request
from starlette.responses import Response
from typing import Callable, Awaitable

# Logger específico para este middleware
logger = logging.getLogger("Hermes.Web.Middleware.Correlation")


class CorrelationIdMiddleware(BaseHTTPMiddleware):
    """
    Middleware que asigna un CorrelationId único a cada solicitud.
    
    Este middleware es el PRIMERO en ejecutarse para asegurar que
    todas las capas posteriores tengan acceso al CorrelationId.
    """
    
    def __init__(self, app):
        """
        Inicializa el CorrelationIdMiddleware.
        
        Args:
            app: La aplicación FastAPI o el siguiente middleware
        """
        super().__init__(app)
        logger.info("CorrelationIdMiddleware inicializado.")
    
    async def dispatch(
        self,
        request: Request,
        call_next: Callable[[Request], Awaitable[Response]]
    ) -> Response:
        """
        Procesa cada solicitud asignando un CorrelationId.
        
        Args:
            request: La solicitud HTTP entrante
            call_next: Función para pasar al siguiente middleware/handler
        
        Returns:
            Response con el CorrelationId en el header
        """
        # ─── Obtener o generar el CorrelationId ───────────────
        correlation_id = request.headers.get("X-Correlation-ID")
        
        if correlation_id:
            # Si el cliente proporcionó un CorrelationId, lo usamos
            logger.debug(f"CorrelationId recibido del cliente: {correlation_id}")
        else:
            # Si no, generamos uno nuevo (UUID v4)
            correlation_id = str(uuid.uuid4())
            logger.debug(f"CorrelationId generado: {correlation_id}")
        
        # ─── Asignar el CorrelationId al estado de la solicitud ─
        # Esto permite que cualquier parte del código acceda al CorrelationId
        # mediante: request.state.correlation_id
        request.state.correlation_id = correlation_id
        
        # ─── Pasar al siguiente middleware/handler ─────────────
        respuesta: Response = await call_next(request)
        
        # ─── Agregar el CorrelationId al header de respuesta ───
        respuesta.headers["X-Correlation-ID"] = correlation_id
        
        return respuesta