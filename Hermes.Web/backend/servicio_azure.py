"""
====================================================================
servicio_azure.py — Servicio Azure para el Portal Hermes
====================================================================

Responsabilidades:
    1. Listar App Service Plans en RG-Hermes-Proyectos via Azure REST API
    2. Validar que un App Service Plan está en el resource group autorizado
    3. NO modificar recursos Azure — solo consultas (read-only)

Autenticación:
    Usa DefaultAzureCredential (Managed Identity en Azure App Service).

Seguridad:
    - Sin secretos en código
    - Sin tokens en logs
    - Sin az login
    - Sin operaciones destructivas
====================================================================
"""

import os
import json
import logging
from typing import Optional, Dict, Any, List

logger = logging.getLogger("Hermes.Web.ServicioAzure")

# Constantes autorizadas (server-side, no modificables por el navegador)
SUBSCRIPTION_AUTORIZADA = "01bfad48-c092-4712-bc72-f141eb01a8d4"
RESOURCE_GROUP_AUTORIZADO = "RG-Hermes-Proyectos"
TIPO_RECURSO = "Microsoft.Web/serverfarms"
API_VERSION = "2023-01-01"
ARM_ENDPOINT = "https://management.azure.com"
class ServicioAzure:
    """Servicio de consulta a Azure ARM REST API."""

    def __init__(self):
        self._credential_disponible = False
        self._credential = None
        self._httpx_disponible = False
        try:
            import httpx
            self._httpx = httpx
            self._httpx_disponible = True
        except ImportError:
            logger.error("httpx no instalado")

    def _obtener_credential(self):
        """Obtiene DefaultAzureCredential (lazy)."""
        if self._credential_disponible:
            return True
        try:
            from azure.identity import DefaultAzureCredential
            self._credential = DefaultAzureCredential(
                exclude_visual_studio_code_credential=True,
                exclude_shared_token_cache_credential=True,
                logging_enable=False
            )
            self._credential_disponible = True
            logger.info("DefaultAzureCredential inicializado")
            return True
        except ImportError:
            logger.error("azure-identity no instalado")
            return False
        except Exception as e:
            logger.error(f"Error inicializando DefaultAzureCredential: {e}")
            return False

    def _obtener_token(self) -> Optional[str]:
        """Obtiene token de acceso para ARM."""
        if not self._obtener_credential():
            return None
        try:
            token = self._credential.get_token(f"{ARM_ENDPOINT}/.default")
            return token.token
        except Exception as e:
            logger.error(f"Error obteniendo token Azure: {e}")
            return None

    # ─── Listar App Service Plans ───

    def listar_app_service_plans(self) -> Dict[str, Any]:
        """
        Lista los App Service Plans en RG-Hermes-Proyectos.

        Returns:
            Dict con:
                - exito: bool
                - planes: List[Dict] con name, id, resource_group, location, sku
                - error: str (si exito=False)
        """
        resultado: Dict[str, Any] = {
            "exito": False,
            "planes": [],
            "error": "",
        }

        if not self._httpx_disponible:
            resultado["error"] = "httpx no disponible"
            return resultado

        token = self._obtener_token()
        if not token:
            resultado["error"] = "No se pudo autenticar con Azure"
            return resultado

        url = (
            f"{ARM_ENDPOINT}/subscriptions/{SUBSCRIPTION_AUTORIZADA}"
            f"/resourceGroups/{RESOURCE_GROUP_AUTORIZADO}"
            f"/providers/{TIPO_RECURSO}"
            f"?api-version={API_VERSION}"
        )

        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        try:
            respuesta = self._httpx.get(url, headers=headers, timeout=30.0)
            if respuesta.status_code != 200:
                logger.error(f"Azure ARM error {respuesta.status_code}")
                resultado["error"] = f"Azure ARM respondió {respuesta.status_code}"
                return resultado

            data = respuesta.json()
            planes_raw = data.get("value", [])

            planes = []
            for plan in planes_raw:
                sku = plan.get("sku", {})
                planes.append({
                    "name": plan.get("name", ""),
                    "id": plan.get("id", ""),
                    "resource_group": RESOURCE_GROUP_AUTORIZADO,
                    "location": plan.get("location", ""),
                    "sku": f"{sku.get('tier', '')} {sku.get('name', '')}".strip(),
                })

            resultado["exito"] = True
            resultado["planes"] = planes
            logger.info(f"Planes listados: {len(planes)} en {RESOURCE_GROUP_AUTORIZADO}")
            return resultado

        except self._httpx.TimeoutException:
            resultado["error"] = "Timeout conectando a Azure ARM (30s)"
        except self._httpx.ConnectError as e:
            resultado["error"] = f"Error de conexión a Azure ARM: {str(e)[:200]}"
        except Exception as e:
            resultado["error"] = f"Error interno: {str(e)[:300]}"
            logger.error(f"Error ServicioAzure: {str(e)[:300]}")

        return resultado

    # ─── Validar que un plan pertenece al RG autorizado ───

    def validar_plan_elegible(self, resource_id: str) -> Dict[str, Any]:
        """
        Valida que un resource_id corresponde a un App Service Plan
        elegible (RG-Hermes-Proyectos, subscription autorizada).

        Returns:
            Dict con:
                - valido: bool
                - error: str (si valido=False)
        """
        resultado = {"valido": False, "error": ""}

        # Validar formato del resource ID
        pattern = (
            f"/subscriptions/{SUBSCRIPTION_AUTORIZADA}"
            f"/resourceGroups/{RESOURCE_GROUP_AUTORIZADO}"
            f"/providers/{TIPO_RECURSO}/"
        )
        if not resource_id.startswith(pattern):
            resultado["error"] = (
                f"El plan no pertenece a {RESOURCE_GROUP_AUTORIZADO}. "
                "Solo se aceptan planes del resource group autorizado."
            )
            return resultado

        if not self._httpx_disponible:
            resultado["error"] = "httpx no disponible"
            return resultado

        token = self._obtener_token()
        if not token:
            resultado["error"] = "No se pudo autenticar con Azure"
            return resultado

        url = f"{ARM_ENDPOINT}{resource_id}?api-version={API_VERSION}"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        try:
            respuesta = self._httpx.get(url, headers=headers, timeout=15.0)
            if respuesta.status_code == 200:
                resultado["valido"] = True
                logger.info(f"Plan validado: {resource_id}")
            elif respuesta.status_code == 404:
                resultado["error"] = "El recurso no existe en Azure"
            else:
                resultado["error"] = f"Azure ARM respondió {respuesta.status_code}"
        except self._httpx.TimeoutException:
            resultado["error"] = "Timeout validando plan en Azure"
        except self._httpx.ConnectError as e:
            resultado["error"] = f"Error de conexión: {str(e)[:200]}"
        except Exception as e:
            resultado["error"] = f"Error interno: {str(e)[:300]}"

        return resultado


# ─── Singleton ───

_instancia_servicio_azure: Optional[ServicioAzure] = None


def obtener_servicio_azure() -> ServicioAzure:
    """Devuelve la instancia singleton del servicio Azure."""
    global _instancia_servicio_azure
    if _instancia_servicio_azure is None:
        _instancia_servicio_azure = ServicioAzure()
    return _instancia_servicio_azure
