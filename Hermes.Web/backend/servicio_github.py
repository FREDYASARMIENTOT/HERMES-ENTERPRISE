"""
====================================================================
servicio_github.py - Servicio de integracion con GitHub API
====================================================================

Capa de integracion para disparar workflows de GitHub Actions
desde el Portal Hermes.

Arquitectura:
    ServicioFabrica -> ServicioGitHub -> GitHub REST API
                                        (workflow_dispatch)

Principios:
    - Sin dependencia de gh CLI
    - Sin dependencia de az CLI
    - Sin dependencia de PowerShell
    - Sin secretos en frontend
    - Sin tokens en logs
    - Sin polling infinito
    - Funciona en Azure App Service Linux (Python 3.12)
====================================================================
"""

import os
import json
import logging
import re
from typing import Optional, Dict, Any

logger = logging.getLogger("Hermes.Web.ServicioGitHub")

# Constantes

PROPIETARIO_POR_DEFECTO = "FREDYASARMIENTOT"
REPOSITORIO_CONTROL_PLANE = "HERMES-ENTERPRISE"
WORKFLOW_CONTROL_PLANE = "deploy-child.yml"
WORKFLOW_FACTORY_RUNNER = "factory-run.yml"
RAMA_POR_DEFECTO = "main"
# NOTA: No usar COMMIT_SHA_PLACEHOLDER. El SHA debe ser REAL.
# deploy-child.yml valida estrictamente: ^[0-9a-f]{40}$
URL_BASE_API = "https://api.github.com"
ENV_TOKEN_GITHUB = "HERMES_GITHUB_TOKEN"

# UUID para cuando no se provee correlation_id / deployment_id
_FACTORY_DEFAULT_PLACEHOLDER = "gha-auto-0000000000"


def _obtener_token() -> Optional[str]:
    """
    Obtiene el token de GitHub desde variable de entorno.
    Retorna: Token o None si no esta configurado.
    Seguridad: Nunca imprime el token en logs ni respuestas.

    Busca en múltiples nombres de variable de entorno para
    compatibilidad con diferentes entornos de Azure App Service:
      1. HERMES_GITHUB_TOKEN (nombre canónico)
      2. GH_PORTAL_HERMES_REPO_WRITE_TOKEN (nombre original del secreto)
      3. APPSETTING_HERMES_GITHUB_TOKEN (prefijo Azure App Service legacy)
    """
    nombres_variables = [
        ENV_TOKEN_GITHUB,
        "GH_PORTAL_HERMES_REPO_WRITE_TOKEN",
        f"APPSETTING_{ENV_TOKEN_GITHUB}",
    ]
    for var_name in nombres_variables:
        token = os.environ.get(var_name, "")
        if token:
            return token
    logger.warning(
        f"Variable de entorno {ENV_TOKEN_GITHUB} no configurada. "
        f"El dispatch a GitHub no estara disponible."
    )
    return None


class ServicioGitHub:
    """
    Servicio para interactuar con la GitHub REST API.

    Responsabilidades:
        - disparar_workflow(): Dispara workflow via workflow_dispatch
        - disparar_factory_runner(): Dispara factory-run.yml para crear proyecto
        - validar_configuracion(): Verifica token y httpx
        - construir_payload(): Construye payload para deploy-child.yml
        - construir_payload_factory_runner(): Construye payload para factory-run.yml

    No usa gh CLI, az CLI ni PowerShell.
    Usa httpx como cliente HTTP (Async).
    """

    def __init__(self, token=None, propietario=None, repositorio=None,
                 workflow=None, rama=None):
        self.token = token
        self.propietario = propietario or PROPIETARIO_POR_DEFECTO
        self.repositorio = repositorio or REPOSITORIO_CONTROL_PLANE
        self.workflow = workflow or WORKFLOW_CONTROL_PLANE
        self.rama = rama or RAMA_POR_DEFECTO
        self._httpx_disponible = False
        try:
            import httpx
            self._httpx = httpx
            self._httpx_disponible = True
        except ImportError:
            logger.error("httpx no instalado")

    def validar_configuracion(self):
        resultado = {
            "valido": True, "errores": [], "advertencias": [],
            "configuracion": {
                "propietario": self.propietario,
                "repositorio": self.repositorio,
                "workflow": self.workflow,
                "rama": self.rama,
                "token_configurado": False,
                "httpx_disponible": False,
            }
        }
        if not self._httpx_disponible:
            resultado["valido"] = False
            resultado["errores"].append("httpx no instalado")
        tv = self.token or _obtener_token()
        if not tv:
            resultado["valido"] = False
            resultado["errores"].append("Token no configurado")
        else:
            resultado["configuracion"]["token_configurado"] = True
        resultado["configuracion"]["httpx_disponible"] = self._httpx_disponible
        return resultado

    def construir_payload(self, nombre_proyecto, repositorio, commit_sha):
        # Validar SHA: debe ser exactamente 40 caracteres hex
        if not commit_sha or len(commit_sha) != 40:
            raise ValueError(
                f"SHA invalido: se requieren exactamente 40 caracteres hex, "
                f"recibidos {len(commit_sha) if commit_sha else 0}"
            )
        if not re.match(r'^[0-9a-f]{40}$', commit_sha):
            raise ValueError(
                f"SHA no es hexadecimal valido: '{commit_sha}'"
            )
        sha = commit_sha
        return {
            "ref": self.rama,
            "inputs": {
                "project_name": nombre_proyecto,
                "repository": repositorio,
                "commit_sha": sha,
            }
        }

    @staticmethod
    def construir_payload_factory_runner(
        project_name: str,
        correlation_id: str = "",
        deployment_id: str = ""
    ) -> Dict[str, Any]:
        """
        Construye el payload para disparar factory-run.yml.
        Args:
            project_name: Nombre del proyecto (ej: hermes-fabrica-04)
            correlation_id: Correlation ID del tracking (opcional)
            deployment_id: Deployment ID del tracking (opcional)
        Returns:
            Dict con ref e inputs para workflow_dispatch
        """
        inputs: Dict[str, str] = {"project_name": project_name}
        if correlation_id:
            inputs["correlation_id"] = correlation_id
        if deployment_id:
            inputs["deployment_id"] = deployment_id
        return {"ref": RAMA_POR_DEFECTO, "inputs": inputs}

    async def disparar_factory_runner(
        self,
        project_name: str,
        correlation_id: str = "",
        deployment_id: str = "",
        token_sobreescribe: Optional[str] = None
    ) -> Dict[str, Any]:
        """
        Dispara factory-run.yml en HERMES-ENTERPRISE.
        Args:
            project_name: Nombre del proyecto a crear
            correlation_id: Correlation ID opcional
            deployment_id: Deployment ID opcional
            token_sobreescribe: Token opcional
        Returns:
            Dict con resultado del dispatch
        """
        resultado = {
            "exito": False, "status_code": None, "mensaje": "",
            "payload_enviado": {}, "respuesta_cuerpo": "",
            "error_tecnico": "",
        }
        config = self.validar_configuracion()
        if not config["valido"]:
            resultado["mensaje"] = "Configuracion incompleta"
            resultado["error_tecnico"] = "; ".join(config["errores"])
            return resultado
        tv = token_sobreescribe or self.token or _obtener_token()
        if not tv:
            resultado["mensaje"] = "Token no disponible"
            resultado["error_tecnico"] = resultado["mensaje"]
            return resultado
        payload = self.construir_payload_factory_runner(
            project_name=project_name,
            correlation_id=correlation_id,
            deployment_id=deployment_id
        )
        resultado["payload_enviado"] = payload
        workflow = WORKFLOW_FACTORY_RUNNER
        url = (
            f"{URL_BASE_API}/repos/{self.propietario}/{self.repositorio}"
            f"/actions/workflows/{workflow}/dispatches"
        )
        headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {tv}",
            "User-Agent": "Hermes-Enterprise-Portal/2.0",
        }
        logger.info(
            f"Factory dispatch: {self.propietario}/{self.repositorio}"
            f"/{workflow} -> {project_name}"
        )
        try:
            async with self._httpx.AsyncClient(timeout=30.0) as cliente:
                respuesta = await cliente.post(url, json=payload, headers=headers)
            resultado["status_code"] = respuesta.status_code
            cuerpo = respuesta.text[:2000] if respuesta.text else ""
            resultado["respuesta_cuerpo"] = cuerpo
            if respuesta.status_code == 204:
                resultado["exito"] = True
                resultado["mensaje"] = f"Factory Runner {workflow} disparado para {project_name}."
                logger.info(f"Factory dispatch EXITOSO: {project_name}")
            elif respuesta.status_code == 401:
                resultado["mensaje"] = "Error 401: Token invalido"
                resultado["error_tecnico"] = "GitHub 401"
                logger.error(f"Factory GitHub 401: {project_name}")
            elif respuesta.status_code == 403:
                resultado["mensaje"] = "Error 403: Sin permisos"
                resultado["error_tecnico"] = f"GitHub 403: {cuerpo[:500]}"
                logger.error(f"Factory GitHub 403: {project_name}")
            elif respuesta.status_code == 404:
                resultado["mensaje"] = "Error 404: Workflow no encontrado"
                resultado["error_tecnico"] = f"GitHub 404: {workflow}"
                logger.error(f"Factory GitHub 404: {workflow}")
            elif respuesta.status_code == 422:
                resultado["mensaje"] = "Error 422: Inputs invalidos"
                resultado["error_tecnico"] = f"GitHub 422: {cuerpo[:500]}"
                logger.error(f"Factory GitHub 422: {cuerpo[:300]}")
            else:
                resultado["mensaje"] = f"Error HTTP {respuesta.status_code}"
                resultado["error_tecnico"] = f"GitHub {respuesta.status_code}: {cuerpo[:500]}"
                logger.error(f"Factory GitHub {respuesta.status_code} inesperado")
        except self._httpx.TimeoutException:
            resultado["status_code"] = None
            resultado["mensaje"] = "Timeout conectando a GitHub (30s)"
            resultado["error_tecnico"] = "TimeoutException"
            logger.error(f"Factory Timeout GitHub: {project_name}")
        except self._httpx.ConnectError as e:
            resultado["status_code"] = None
            resultado["mensaje"] = "Error de conexion a GitHub API"
            resultado["error_tecnico"] = f"ConnectError: {str(e)[:300]}"
            logger.error(f"Factory ConnectError: {str(e)[:200]}")
        except Exception as e:
            resultado["status_code"] = None
            resultado["mensaje"] = "Error interno al conectar con GitHub"
            resultado["error_tecnico"] = f"Exception: {str(e)[:500]}"
            logger.error(f"Factory Error ServicioGitHub: {str(e)[:300]}")
        return resultado

    async def disparar_workflow(self, nombre_proyecto, repositorio_repo,
                                  commit_sha, token_sobreescribe=None):
        resultado = {
            "exito": False,
            "status_code": None,
            "mensaje": "",
            "payload_enviado": {},
            "respuesta_cuerpo": "",
            "error_tecnico": "",
        }
        config = self.validar_configuracion()
        if not config["valido"]:
            resultado["mensaje"] = "Configuracion incompleta"
            resultado["error_tecnico"] = "; ".join(config["errores"])
            return resultado
        tv = token_sobreescribe or self.token or _obtener_token()
        if not tv:
            resultado["mensaje"] = "Token no disponible"
            resultado["error_tecnico"] = resultado["mensaje"]
            return resultado
        payload = self.construir_payload(nombre_proyecto, repositorio_repo, commit_sha)
        resultado["payload_enviado"] = payload
        url = f"{URL_BASE_API}/repos/{self.propietario}/{self.repositorio}/actions/workflows/{self.workflow}/dispatches"
        headers = {
            "Accept": "application/vnd.github+json",
            "Authorization": f"Bearer {tv}",
            "User-Agent": "Hermes-Enterprise-Portal/2.0",
        }
        logger.info(f"Dispatch: {self.propietario}/{self.repositorio}/{self.workflow} -> {nombre_proyecto}")
        try:
            async with self._httpx.AsyncClient(timeout=30.0) as cliente:
                respuesta = await cliente.post(url, json=payload, headers=headers)
            resultado["status_code"] = respuesta.status_code
            cuerpo = respuesta.text[:2000] if respuesta.text else ""
            resultado["respuesta_cuerpo"] = cuerpo
            if respuesta.status_code == 204:
                resultado["exito"] = True
                resultado["mensaje"] = f"Workflow {self.workflow} disparado."
                logger.info(f"Dispatch EXITOSO: {nombre_proyecto}")
            elif respuesta.status_code == 401:
                resultado["mensaje"] = "Error 401: Token invalido"
                resultado["error_tecnico"] = "GitHub 401"
                logger.error(f"GitHub 401: {nombre_proyecto}")
            elif respuesta.status_code == 403:
                resultado["mensaje"] = "Error 403: Sin permisos"
                resultado["error_tecnico"] = f"GitHub 403: {cuerpo[:500]}"
                logger.error(f"GitHub 403: {nombre_proyecto}")
            elif respuesta.status_code == 404:
                resultado["mensaje"] = "Error 404: Workflow no encontrado"
                resultado["error_tecnico"] = f"GitHub 404: {self.workflow}"
                logger.error(f"GitHub 404: {self.workflow}")
            elif respuesta.status_code == 422:
                resultado["mensaje"] = "Error 422: Inputs invalidos"
                resultado["error_tecnico"] = f"GitHub 422: {cuerpo[:500]}"
                logger.error(f"GitHub 422: {cuerpo[:300]}")
            else:
                resultado["mensaje"] = f"Error HTTP {respuesta.status_code}"
                resultado["error_tecnico"] = f"GitHub {respuesta.status_code}: {cuerpo[:500]}"
                logger.error(f"GitHub {respuesta.status_code} inesperado")
        except self._httpx.TimeoutException:
            resultado["status_code"] = None
            resultado["mensaje"] = "Timeout conectando a GitHub (30s)"
            resultado["error_tecnico"] = "TimeoutException"
            logger.error(f"Timeout GitHub API: {nombre_proyecto}")
        except self._httpx.ConnectError as e:
            resultado["status_code"] = None
            resultado["mensaje"] = "Error de conexion a GitHub API"
            resultado["error_tecnico"] = f"ConnectError: {str(e)[:300]}"
            logger.error(f"ConnectError GitHub: {str(e)[:200]}")
        except Exception as e:
            resultado["status_code"] = None
            resultado["mensaje"] = "Error interno al conectar con GitHub"
            resultado["error_tecnico"] = f"Exception: {str(e)[:500]}"
            logger.error(f"Error ServicioGitHub: {str(e)[:300]}")
        return resultado

    @staticmethod
    def resumen_seguro(resultado):
        return {
            "exito": resultado.get("exito", False),
            "status_code": resultado.get("status_code"),
            "mensaje": resultado.get("mensaje", ""),
            "payload_enviado": resultado.get("payload_enviado", {}),
        }


# Singleton
_instancia_servicio_github = None


def obtener_servicio_github():
    global _instancia_servicio_github
    if _instancia_servicio_github is None:
        _instancia_servicio_github = ServicioGitHub()
    return _instancia_servicio_github

