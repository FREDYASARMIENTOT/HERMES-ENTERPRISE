"""
Módulo Middleware de Hermes.Web.

Este módulo contiene todos los middlewares personalizados para el
Backend FastAPI de Hermes Enterprise. Cada middleware implementa
una funcionalidad transversal del sistema.

Middlewares disponibles:
    - CorrelationIdMiddleware: Asigna un CorrelationId único a cada solicitud
    - LoggingMiddleware: Registra todas las solicitudes y respuestas
    - TimingMiddleware: Mide el tiempo de procesamiento de cada solicitud
    - AuditoriaMiddleware: Registra eventos de auditoría
    - ErrorHandlingMiddleware: Captura y maneja excepciones globalmente
    - CompressionMiddleware: Comprime respuestas HTTP

Flujo de ejecución (orden):
    1. CorrelationIdMiddleware (primero, necesario para todo)
    2. LoggingMiddleware (segundo, registra la solicitud entrante)
    3. TimingMiddleware (tercero, inicia el temporizador)
    4. AuditoriaMiddleware (cuarto, registra el evento)
    5. ErrorHandlingMiddleware (quinto, captura errores)
    6. CompressionMiddleware (último, comprime la respuesta)

Uso en main.py:
    from middleware.middleware_correlation import CorrelationIdMiddleware
    from middleware.middleware_logging import LoggingMiddleware
    from middleware.middleware_timing import TimingMiddleware
    from middleware.middleware_auditoria import AuditoriaMiddleware
    from middleware.middleware_errores import ErrorHandlingMiddleware
    from middleware.middleware_compresion import CompressionMiddleware
    
    app.add_middleware(CorrelationIdMiddleware)   # 1º
    app.add_middleware(LoggingMiddleware)          # 2º
    app.add_middleware(TimingMiddleware)           # 3º
    app.add_middleware(AuditoriaMiddleware)        # 4º
    app.add_middleware(ErrorHandlingMiddleware)    # 5º
    app.add_middleware(CompressionMiddleware)      # 6º
"""

__version__ = "2.0.0"

# Exportar clases
from middleware.middleware_correlation import CorrelationIdMiddleware
from middleware.middleware_logging import LoggingMiddleware
from middleware.middleware_timing import TimingMiddleware
from middleware.middleware_auditoria import AuditoriaMiddleware
from middleware.middleware_errores import ErrorHandlingMiddleware
from middleware.middleware_compresion import CompressionMiddleware

__all__ = [
    "CorrelationIdMiddleware",
    "LoggingMiddleware",
    "TimingMiddleware",
    "AuditoriaMiddleware",
    "ErrorHandlingMiddleware",
    "CompressionMiddleware",
]