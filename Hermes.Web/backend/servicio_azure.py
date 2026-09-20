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


# ─── Verificar existencia de Web App ───

    def verificar_existencia_web_app(
        self,
        web_app_name: str,
        resource_group: str = RESOURCE_GROUP_AUTORIZADO,
        subscription_id: str = SUBSCRIPTION_AUTORIZADA
    ) -> Dict[str, Any]:
        """
        Verifica si un Web App (App Service) existe actualmente en Azure.

        Args:
            web_app_name: Nombre del App Service (ej: as-hermes-fabrica-02)
            resource_group: Resource Group (default: RG-Hermes-Proyectos)
            subscription_id: Subscription ID

        Returns:
            Dict con:
                - exists: bool
                - status_code: int (HTTP status)
                - status: str (EXISTE | NO_EXISTE | ERROR_PERMISOS |
                           ERROR_CONEXION | ERROR_AZURE | NO_VERIFICADO)
                - error: str
                - resource_id: str (ARM resource ID)
                - hostname: str (default hostname si existe)
                - checked_at: str (timestamp ISO 8601)
        """
        resultado: Dict[str, Any] = {
            "exists": False,
            "status_code": 0,
            "status": "NO_VERIFICADO",
            "error": "",
            "resource_id": "",
            "hostname": "",
            "checked_at": _ahora_azure(),
        }

        if not web_app_name:
            resultado["error"] = "web_app_name vacio"
            resultado["status"] = "NO_VERIFICADO"
            return resultado

        resource_id = (
            f"/subscriptions/{subscription_id}"
            f"/resourceGroups/{resource_group}"
            f"/providers/Microsoft.Web/sites/{web_app_name}"
        )
        resultado["resource_id"] = resource_id

        if not self._httpx_disponible:
            resultado["error"] = "httpx no disponible"
            return resultado

        token = self._obtener_token()
        if not token:
            resultado["error"] = "No se pudo autenticar con Azure"
            resultado["status"] = "ERROR"
            return resultado

        url = f"{ARM_ENDPOINT}{resource_id}?api-version={API_VERSION}"
        headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        }

        try:
            respuesta = self._httpx.get(url, headers=headers, timeout=15.0)
            resultado["status_code"] = respuesta.status_code

            if respuesta.status_code == 200:
                resultado["exists"] = True
                resultado["status"] = "EXISTE"
                data = respuesta.json()
                props = data.get("properties", {})
                resultado["hostname"] = props.get("defaultHostName", "")
                logger.info(
                    f"Web App {web_app_name} existe en Azure. "
                    f"Hostname: {resultado['hostname']}"
                )
            elif respuesta.status_code == 404:
                resultado["exists"] = False
                resultado["status"] = "NO_EXISTE"
                logger.info(f"Web App {web_app_name} NO existe en Azure (404)")
            elif respuesta.status_code == 403:
                resultado["exists"] = False
                resultado["status"] = "ERROR_PERMISOS"
                resultado["error"] = (
                    f"Azure ARM respondio 403 (permisos insuficientes) "
                    f"para {web_app_name}"
                )
                logger.warning(resultado["error"])
            elif respuesta.status_code == 401:
                resultado["exists"] = False
                resultado["status"] = "ERROR_PERMISOS"
                resultado["error"] = (
                    f"Azure ARM respondio 401 (no autenticado) "
                    f"para {web_app_name}"
                )
                logger.warning(resultado["error"])
            else:
                resultado["exists"] = False
                resultado["status"] = "ERROR_AZURE"
                resultado["error"] = (
                    f"Azure ARM respondio {respuesta.status_code} "
                    f"para {web_app_name}"
                )
                logger.error(resultado["error"])

        except self._httpx.TimeoutException:
            resultado["status"] = "ERROR_CONEXION"
            resultado["error"] = f"Timeout consultando Web App {web_app_name} (15s)"
            logger.error(resultado["error"])
        except self._httpx.ConnectError as e:
            resultado["status"] = "ERROR_CONEXION"
            resultado["error"] = (
                f"Error de conexion a Azure ARM para {web_app_name}: "
                f"{str(e)[:200]}"
            )
            logger.error(resultado["error"])
        except Exception as e:
            resultado["status"] = "ERROR_AZURE"
            resultado["error"] = (
                f"Error interno consultando Web App {web_app_name}: "
                f"{str(e)[:300]}"
            )
            logger.error(resultado["error"])

        return resultado


def _ahora_azure() -> str:
    """Timestamp ISO 8601 para Azure checks."""
    from datetime import datetime, timezone
    return datetime.now(timezone.utc).isoformat()


# ─── Singleton ───

_instancia_servicio_azure: Optional[ServicioAzure] = None


def obtener_servicio_azure() -> ServicioAzure:
    """Devuelve la instancia singleton del servicio Azure."""
    global _instancia_servicio_azure
    if _instancia_servicio_azure is None:
        _instancia_servicio_azure = ServicioAzure()
    return _instancia_servicio_azure
