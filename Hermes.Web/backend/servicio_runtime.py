import logging
from typing import Optional, Dict, Any
from datetime import datetime, timezone

logger = logging.getLogger("Hermes.Web.ServicioRuntime")

def _ahora_runtime() -> str:
    return datetime.now(timezone.utc).isoformat()

class ServicioRuntime:
    """
    Servicio de verificacion de runtime/venv de proyectos Child.
    Verifica el health endpoint del App Service.
    Estados: EXISTE, NO_EXISTE, ERROR_CONEXION, NO_VERIFICADO
    """
    def __init__(self):
        self._httpx_disponible = False
        try:
            import httpx
            self._httpx = httpx
            self._httpx_disponible = True
        except ImportError:
            logger.error("httpx no instalado")

    def verificar_runtime(self, hostname: str, timeout: float = 10.0) -> Dict[str, Any]:
        resultado = {
            "exists": False, "status": "NO_VERIFICADO",
            "status_code": 0, "hostname": hostname,
            "error": "", "checked_at": _ahora_runtime(),
        }
        if not hostname:
            resultado["error"] = "hostname requerido"
            return resultado
        if not self._httpx_disponible:
            resultado["error"] = "httpx no disponible"
            return resultado
        health_urls = [
            f"https://{hostname}/health",
            f"http://{hostname}/health",
            f"https://{hostname}/api/health",
        ]
        for url in health_urls:
            try:
                resp = self._httpx.get(url, timeout=timeout, follow_redirects=True)
                resultado["status_code"] = resp.status_code
                if resp.status_code == 200:
                    resultado["exists"] = True; resultado["status"] = "EXISTE"
                    logger.info(f"Runtime EXISTE en {hostname} (200 en {url})")
                    break
                elif resp.status_code in (401, 403):
                    resultado["exists"] = True; resultado["status"] = "EXISTE"
                    logger.info(f"Runtime EXISTE en {hostname} ({resp.status_code} en {url})")
                    break
                elif resp.status_code == 404:
                    resultado["exists"] = False; resultado["status"] = "NO_EXISTE"
                    resultado["error"] = f"Health endpoint 404 en {url}"
                    logger.info(resultado["error"])
                    continue
                else:
                    resultado["exists"] = False; resultado["status"] = "ERROR_CONEXION"
                    resultado["error"] = f"Health respondio {resp.status_code} en {url}"
                    logger.warning(resultado["error"])
                    continue
            except self._httpx.TimeoutException:
                resultado["status"] = "ERROR_CONEXION"
                resultado["error"] = f"Timeout verificando {hostname} ({timeout}s)"
                logger.error(resultado["error"]); break
            except self._httpx.ConnectError as e:
                resultado["status"] = "ERROR_CONEXION"
                resultado["error"] = f"Error conexion {hostname}: {str(e)[:200]}"
                logger.warning(resultado["error"]); continue
            except Exception as e:
                resultado["status"] = "ERROR_CONEXION"
                resultado["error"] = f"Error interno: {str(e)[:300]}"
                logger.error(resultado["error"]); break
        resultado["checked_at"] = _ahora_runtime()
        return resultado

_instancia_servicio_runtime = None
def obtener_servicio_runtime():
    global _instancia_servicio_runtime
    if _instancia_servicio_runtime is None:
        _instancia_servicio_runtime = ServicioRuntime()
    return _instancia_servicio_runtime
