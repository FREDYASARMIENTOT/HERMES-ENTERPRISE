"""
Hermes.Web — Paquete principal del Portal Web de Hermes Enterprise.

Este paquete contiene la aplicación FastAPI, la API REST, el middleware,
el frontend Bootstrap y los archivos de despliegue para Azure App Service.

Estructura:
    Hermes.Web/
        ├── __init__.py         # Este archivo
        ├── backend/            # Aplicación FastAPI principal
        ├── api/                # Routers de la API REST
        ├── middleware/         # Middleware personalizado
        ├── frontend/           # Recursos del frontend
        ├── templates/          # Plantillas HTML (Jinja2)
        ├── static/             # Archivos estáticos (CSS, JS, etc.)
        ├── deployment/         # Configuración de despliegue
        └── requirements.txt    # Dependencias Python

Versión: 2.0.0
"""
__version__ = "2.0.0"
__all__ = []