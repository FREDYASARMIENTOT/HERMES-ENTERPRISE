"""
event_broker.py — Distribución en tiempo real de eventos (SSE)
====================================================================

Arquitectura:
    - Fuente de verdad: SQLite/Event Store (servicio_fabrica._registrar_evento)
    - Distribución: EventBroker con asyncio.Queue por deployment
    - Regla crítica: persistencia OCURRE ANTES de publicación SSE

    subscribe(deployment_id) -> asyncio.Queue
    publish(deployment_id, event)  -> pone evento en TODAS las colas del deployment
    unsubscribe(deployment_id, queue) -> remueve la cola

Thread-safety:
    - publish() puede llamarse desde código síncrono (thread pool de FastAPI)
    - Usa call_soon_threadsafe para poner eventos en asyncio.Queue
====================================================================
"""

import asyncio
import logging
import threading
from collections import defaultdict
from typing import Dict, List, Optional

logger = logging.getLogger("Hermes.Web.EventBroker")


class EventBroker:
    """Distribuidor de eventos en tiempo real para SSE.

    Cada deployment_id tiene una lista de colas (una por cliente SSE).
    publish() es thread-safe para ser llamado desde endpoints síncronos.
    """

    def __init__(self):
        self._lock = threading.Lock()
        self._queues: Dict[str, List[asyncio.Queue]] = defaultdict(list)
        self._loop: Optional[asyncio.AbstractEventLoop] = None

    def set_loop(self, loop: asyncio.AbstractEventLoop) -> None:
        """Fija el event loop para call_soon_threadsafe (llamar en startup)."""
        self._loop = loop

    def subscribe(self, deployment_id: str) -> asyncio.Queue:
        """Crea una nueva cola de eventos para un deployment.

        El llamador (SSE generator) debe await queue.get() para recibir eventos.
        """
        q: asyncio.Queue = asyncio.Queue()
        with self._lock:
            self._queues[deployment_id].append(q)
        logger.debug(f"EventBroker: cliente suscrito a {deployment_id} "
                     f"(total: {len(self._queues[deployment_id])})")
        return q

    def unsubscribe(self, deployment_id: str, q: asyncio.Queue) -> None:
        """Remueve una cola de la lista de suscriptores."""
        with self._lock:
            try:
                self._queues[deployment_id].remove(q)
                logger.debug(f"EventBroker: cliente desconectado de {deployment_id} "
                             f"(restantes: {len(self._queues[deployment_id])})")
            except ValueError:
                pass

    def publish(self, deployment_id: str, event: dict) -> None:
        """Publica un evento a TODOS los suscriptores de un deployment.

        Thread-safe: puede llamarse desde código síncrono.
        La persistencia en SQLite DEBE ocurrir ANTES de llamar a publish().
        """
        with self._lock:
            queues = list(self._queues.get(deployment_id, []))

        if not queues:
            return

        loop = self._loop
        if loop is None or loop.is_closed():
            logger.warning("EventBroker: sin event loop activo, evento no distribuido")
            return

        for q in queues:
            try:
                loop.call_soon_threadsafe(q.put_nowait, event)
            except Exception as e:
                logger.error(f"EventBroker: error publicando evento: {e}")

    def subscriber_count(self, deployment_id: str) -> int:
        """Retorna número de suscriptores activos para un deployment."""
        with self._lock:
            return len(self._queues.get(deployment_id, []))

    def cleanup_deployment(self, deployment_id: str) -> None:
        """Limpia todas las colas de un deployment (al finalizar)."""
        with self._lock:
            if deployment_id in self._queues:
                del self._queues[deployment_id]
                logger.debug(f"EventBroker: colas limpiadas para {deployment_id}")


# Instancia global (singleton) para toda la aplicación
_broker_instancia: Optional[EventBroker] = None


def obtener_broker() -> EventBroker:
    """Obtiene la instancia singleton del EventBroker."""
    global _broker_instancia
    if _broker_instancia is None:
        _broker_instancia = EventBroker()
    return _broker_instancia