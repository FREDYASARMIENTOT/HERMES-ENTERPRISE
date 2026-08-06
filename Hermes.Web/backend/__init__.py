"""
Módulo Backend de Hermes.Web.

Este módulo contiene toda la lógica de servidor para el Portal Web Canónico
de Hermes Enterprise. Utiliza FastAPI como framework web principal.

Arquitectura:
    FastAPI (Backend) → Middleware → API Pública → ServicioDatosProyecto → Hermes.Commands → Providers → SQLite

Flujo de una solicitud:
    1. El cliente (Frontend Bootstrap 5) realiza una solicitud HTTP al Backend FastAPI
    2. El Middleware intercepta la solicitud y añade: CorrelationId, Logging, Timing, Auditoría
    3. La solicitud llega al router de la API Pública correspondiente
    4. El router invoca al ServicioDatosProyecto
    5. El ServicioDatosProyecto ejecuta comandos Hermes.Commands vía subprocess/PowerShell
    6. Los comandos Hermes se comunican con los Providers
    7. Los Providers interactúan con SQLite (únicamente a través de Persistencia)
    8. La respuesta viaja de vuelta por la misma cadena en orden inverso

Principios:
    - Nunca acceder directamente a SQLite desde FastAPI
    - Nunca acceder directamente a Providers desde FastAPI
    - Toda comunicación debe pasar por Hermes.Commands
    - Respetar Canonical Source Policy
    - Código completamente documentado en español
"""

# Versión del backend (sincronizada con la versión de Hermes Enterprise)
__version__ = "2.0.0"