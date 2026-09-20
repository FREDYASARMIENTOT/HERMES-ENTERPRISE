"""
api_azure.py — Router de /api/azure para Hermes.Web
"""
import logging
from fastapi import APIRouter, Request

logger = logging.getLogger("Hermes.Web.API.Azure")
router = APIRouter()


@router.get("/azure", summary="Obtiene el estado de la configuracion Azure")
async def obtener_azure(request: Request):
    """Obtiene información real de Azure via Managed Identity/DefaultAzureCredential."""
    try:
        from Hermes.Web.backend.servicio_azure import obtener_servicio_azure
        servicio_azure = obtener_servicio_azure()

        # Listar planes para verificar conectividad
        planes_result = servicio_azure.listar_app_service_plans()

        # Verificar Web App del Portal
        portal_hostname = request.url.hostname or ""
        portal_app_name = portal_hostname.split(".")[0] if portal_hostname else ""

        portal_info = {}
        if portal_app_name:
            portal_info = servicio_azure.verificar_existencia_web_app(
                web_app_name=portal_app_name,
                resource_group="RG-Hermes-Proyectos",
                subscription_id="01bfad48-c092-4712-bc72-f141eb01a8d4",
            )

        return {
            "estado": "verificado" if planes_result.get("exito") else "error",
            "subscription": "01bfad48-c092-4712-bc72-f141eb01a8d4",
            "resource_group": "RG-Hermes-Proyectos",
            "portal_web_app": portal_app_name,
            "portal_hostname": portal_hostname,
            "portal_state": portal_info.get("status", "NO_VERIFICADO"),
            "planes_disponibles": len(planes_result.get("planes", [])),
            "planes": [
                {
                    "name": p.get("name"),
                    "sku": p.get("sku", {}).get("name"),
                    "location": p.get("location"),
                }
                for p in planes_result.get("planes", [])
            ],
            "error": planes_result.get("error", ""),
        }
    except ImportError:
        logger.error("servicio_azure no disponible")
        return {
            "estado": "error",
            "error": "Módulo Azure no disponible (azure-identity/httpx)",
        }
    except Exception as e:
        logger.error(f"Error consultando Azure: {e}")
        return {
            "estado": "error",
            "error": str(e)[:200],
        }