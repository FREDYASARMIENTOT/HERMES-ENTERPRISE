"""
====================================================================
test_worker.py — Verificación del Control Plane Worker
====================================================================
Propósito:
    Probar que el Control Plane Worker puede avanzar proyectos
    atascados (SOLICITADO/EN_PROCESO/CREANDO) a través de los 13
    pasos hasta COMPLETADO/PASS usando llamadas directas a
    ServicioFabrica (sin HTTP).

Uso:
    python data/test_worker.py

Variables de entorno:
    HERMES_WORKER_TEST_DEPLOYMENT_ID: Si se define, solo procesa ese ID
====================================================================
"""

import json
import os
import sys
import time

# ── Configurar path para importar Hermes.Web ──
_HERMES_WEB_DIR = os.path.join(os.path.dirname(__file__), "..", "Hermes.Web")
if _HERMES_WEB_DIR not in sys.path:
    sys.path.insert(0, os.path.abspath(_HERMES_WEB_DIR))

# ── Forzar registro del custom finder antes de cualquier import ──
_HERMES_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
if _HERMES_ROOT not in sys.path:
    sys.path.insert(0, _HERMES_ROOT)

import Hermes.Web.backend.servicio_fabrica as sf
from Hermes.Web.backend.control_plane_worker import _procesar_iteracion

# ── Silenciar logs ruidosos ──
import logging
logging.basicConfig(level=logging.INFO, format="%(levelname)s %(message)s")
logging.getLogger("Hermes.Web.ControlPlaneWorker").setLevel(logging.DEBUG)

TEST_DID = os.environ.get("HERMES_WORKER_TEST_DEPLOYMENT_ID", None)

def main():
    print("=" * 70)
    print(f"CONTROL PLANE WORKER - VERIFICATION TEST")
    print(f"Hora: {time.strftime('%Y-%m-%dT%H:%M:%S')}")
    print(f"Hermes.Web: {_HERMES_WEB_DIR}")
    print("=" * 70)

    try:
        servicio = sf.obtener_servicio_fabrica()
    except Exception as e:
        print(f"\n[FAIL] Error getting ServicioFabrica: {e}")
        sys.exit(1)

    print(f"\nDB: {servicio.ruta_db}")
    print(f"ServicioFabrica inicializado correctamente\n")

    # ── Listar proyectos procesables ──
    estados_procesables = ["SOLICITADO", "EN_PROCESO", "CREANDO"]
    todos_pendientes = []
    for estado in estados_procesables:
        solicitudes = servicio.listar_solicitudes(limite=50, estado=estado)
        if TEST_DID:
            solicitudes = [s for s in solicitudes if s.deployment_id == TEST_DID]
        for s in solicitudes:
            # Contar pasos COMPLETADOS
            completados = sum(1 for p in s.pasos if p.get("estado_paso", p.get("estado")) == "COMPLETADO")
            total = len(s.pasos)
            todos_pendientes.append((s, completados, total))
            print(f"  [{s.deployment_id}] {s.nombre_proyecto}")
            print(f"       estado={s.estado} | pasos: {completados}/{total} COMPLETADOS")

    if not todos_pendientes:
        print("  (No hay proyectos pendientes de procesar)")
        if TEST_DID:
            print(f"  (Filtro activo: deployment_id={TEST_DID})")

    # ── Simular N iteraciones del Worker ──
    max_iteraciones = 20
    iteracion = 0
    total_avanzados = 0

    while iteracion < max_iteraciones:
        iteracion += 1
        avanzados = _procesar_iteracion(servicio)
        if avanzados == 0:
            print(f"\nIteracion {iteracion}: sin proyectos por avanzar -> FIN")
            break
        total_avanzados += avanzados
        print(f"Iteracion {iteracion}: {avanzados} proyecto(s) avanzaron (total: {total_avanzados})")

        # Pequeña pausa para evitar saturar
        time.sleep(0.5)

    print(f"\n{'=' * 70}")
    print(f"RESUMEN: {total_avanzados} avances en {iteracion} iteraciones")
    print(f"{'=' * 70}")

    # ── Verificar estado final ──
    print(f"\n--- Estado final de proyectos ---")
    for estado in estados_procesables + ["COMPLETADO", "FALLIDO"]:
        solicitudes = servicio.listar_solicitudes(limite=50, estado=estado)
        for s in solicitudes:
            completados = sum(1 for p in s.pasos if p.get("estado_paso", p.get("estado")) == "COMPLETADO")
            total = len(s.pasos)
            print(f"  [{s.deployment_id}] {s.nombre_proyecto}")
            print(f"       estado={s.estado} | resultado={s.resultado} | pasos: {completados}/{total}")

    # ── Verificar el proyecto E2E (debe estar COMPLETADO/PASS) ──
    print(f"\n--- Verificacion proyecto E2E (7AF299F5B90C49F5) ---")
    e2e = servicio.obtener_solicitud("7AF299F5B90C49F5")
    if e2e:
        print(f"  Estado: {e2e.estado}")
        print(f"  Resultado: {e2e.resultado}")
        pasos_ok = sum(1 for p in e2e.pasos if p.get("estado_paso", p.get("estado")) == "COMPLETADO")
        print(f"  Pasos COMPLETADOS: {pasos_ok}/{len(e2e.pasos)}")
    else:
        print("  NO ENCONTRADO (pudo haber sido sobrescrito)")

    # ── Verificar proyecto 'test' (debe estar COMPLETADO/PASS ahora) ──
    print(f"\n--- Verificacion proyecto 'test' (CD281EFB47DD4F08) ---")
    test = servicio.obtener_solicitud("CD281EFB47DD4F08")
    if test:
        print(f"  Estado: {test.estado}")
        print(f"  Resultado: {test.resultado}")
        pasos_ok = sum(1 for p in test.pasos if p.get("estado_paso", p.get("estado")) == "COMPLETADO")
        print(f"  Pasos COMPLETADOS: {pasos_ok}/{len(test.pasos)}")
    else:
        print("  NO ENCONTRADO")

    print(f"\n{'=' * 70}")
    print("TEST COMPLETADO")
    print(f"{'=' * 70}")


if __name__ == "__main__":
    main()