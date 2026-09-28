"""
====================================================================
control_plane_worker.py — Worker de Fábrica (Control Plane Local)
====================================================================
Propósito:
    Worker asíncrono que monitorea proyectos atascados en estado
    SOLICITADO/EN_PROCESO/CREANDO y avanza sus pasos automáticamente
    mediante llamadas directas a ServicioFabrica.

Flujo:
    1. Cada N segundos (default 5s), lista proyectos no terminales.
    2. Para cada proyecto, encuentra el primer paso en EN_PROCESO.
    3. Lo avanza a COMPLETADO vía actualizar_desde_control_plane().
    4. El método auto-inicia el siguiente paso.
    5. Cuando paso 13 se completa, auto-establece COMPLETADO/PASS.

Variables de entorno:
    HERMES_CONTROL_PLANE_WORKER_INTERVAL: Intervalo en segundos (default: 5)
    HERMES_CONTROL_PLANE_WORKER_ENABLED: "true" para activar (default: "true")
====================================================================
"""

import asyncio
import logging
import os
from typing import Optional

from Hermes.Web.backend.servicio_fabrica import ServicioFabrica

logger = logging.getLogger("Hermes.Web.ControlPlaneWorker")

_worker_active = False

_ESTADOS_PROCESABLES = {"SOLICITADO", "EN_PROCESO", "CREANDO", "DESPLEGANDO"}
_ESTADOS_TERMINALES = {"COMPLETADO", "FALLIDO", "CANCELADO", "FAILED"}


async def _control_plane_worker_loop(
    servicio: ServicioFabrica,
    intervalo: int = 5,
) -> None:
    """Bucle principal del worker de Control Plane local.

    Itera proyectos en estados procesables y avanza el primer paso
    EN_PROCESO a COMPLETADO, dejando que el auto-avance inicie el
    siguiente paso.
    """
    global _worker_active
    _worker_active = True
    logger.info(
        "Control Plane Worker iniciado "
        f"(intervalo={intervalo}s, estados={_ESTADOS_PROCESABLES})"
    )

    while _worker_active:
        try:
            await asyncio.sleep(intervalo)
            if not _worker_active:
                break

            _procesar_iteracion(servicio)

        except asyncio.CancelledError:
            logger.debug("Control Plane Worker cancelado")
            break
        except Exception as e:
            logger.error(f"Error en Control Plane Worker: {e}", exc_info=True)

    logger.info("Control Plane Worker detenido")


def _procesar_iteracion(servicio: ServicioFabrica) -> int:
    """Procesa una iteración del worker.

    Returns:
        Número de proyectos que avanzaron al menos un paso.
    """
    avanzados = 0
    procesados = set()

    try:
        for estado in _ESTADOS_PROCESABLES:
            solicitudes = servicio.listar_solicitudes(limite=50, estado=estado)
            for solicitud in solicitudes:
                did = solicitud.deployment_id
                if did in procesados:
                    continue
                procesados.add(did)

                paso_a_completar = None
                for paso in solicitud.pasos:
                    estado_paso = paso.get("estado_paso", paso.get("estado", "PENDIENTE"))
                    if estado_paso == "EN_PROCESO":
                        paso_a_completar = paso
                        break

                if paso_a_completar is None:
                    if solicitud.estado == "SOLICITADO":
                        servicio.actualizar_desde_control_plane(
                            deployment_id=did,
                            numero_paso=1,
                            estado_paso="COMPLETADO",
                            detalle="Worker: auto-completado paso 1 (SOLICITUD)",
                            evidencia="Worker local",
                            componente="control_plane_worker",
                            actor="system",
                        )
                        avanzados += 1
                        logger.info(
                            f"[{did}] SOLICITADO -> paso 1 completado por worker"
                        )
                    continue

                num_paso = paso_a_completar["numero"]
                nom_paso = paso_a_completar.get(
                    "nombre_paso", paso_a_completar.get("nombre", f"Paso {num_paso}")
                )

                resultado = servicio.actualizar_desde_control_plane(
                    deployment_id=did,
                    numero_paso=num_paso,
                    estado_paso="COMPLETADO",
                    detalle=f"Worker: auto-completado paso {num_paso} ({nom_paso})",
                    evidencia="Worker local",
                    componente="control_plane_worker",
                    actor="system",
                )

                if resultado:
                    avanzados += 1
                    logger.info(
                        f"[{did}] Paso {num_paso} ({nom_paso}) -> COMPLETADO. "
                        f"Estado: {resultado.estado}"
                    )

                    if num_paso >= 13 and resultado.estado == "COMPLETADO" and resultado.resultado == "PASS":
                        logger.info(
                            f"[{did}] PROYECTO COMPLETADO (PASS) por Worker "
                            f"- {resultado.nombre_proyecto}"
                        )

    except Exception as e:
        logger.error(
            f"Error en iteracion del Control Plane Worker: {e}", exc_info=True
        )

    return avanzados


async def iniciar_worker(
    servicio: ServicioFabrica,
    intervalo_segundos: Optional[int] = None,
) -> None:
    """Inicia el Control Plane Worker como tarea asincrona.

    Args:
        servicio: Instancia de ServicioFabrica
        intervalo_segundos: Intervalo de polling en segundos.
                           Default: HERMES_CONTROL_PLANE_WORKER_INTERVAL env o 5.
    """
    if intervalo_segundos is None:
        intervalo_segundos = int(
            os.environ.get("HERMES_CONTROL_PLANE_WORKER_INTERVAL", "5")
        )

    habilitado = os.environ.get(
        "HERMES_CONTROL_PLANE_WORKER_ENABLED", "true"
    ).lower()

    if habilitado not in ("true", "1", "yes"):
        logger.info(
            "Control Plane Worker DESHABILITADO "
            "(HERMES_CONTROL_PLANE_WORKER_ENABLED != true)"
        )
        return

    asyncio.create_task(_control_plane_worker_loop(servicio, intervalo_segundos))


def detener_worker() -> None:
    """Solicita la detencion del worker."""
    global _worker_active
    _worker_active = False
    logger.info("Senal de detencion enviada al Control Plane Worker")


if __name__ == "__main__":
    print("control_plane_worker.py debe ser importado, no ejecutado directamente")