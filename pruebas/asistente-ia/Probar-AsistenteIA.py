# -*- coding: utf-8 -*-
"""
====================================================================
Probar-AsistenteIA.py — Driver de la PRUEBA LOCAL del Asistente IA
====================================================================

Valida, contra un proveedor REAL (Microsoft Foundry por defecto), la
nueva funcionalidad de configuracion de IA al crear proyectos hijos.

Ejecuta de punta a punta y SIN desplegar nada:
    1. Catalogo de proveedores y contrato de los helpers.
    2. Conversacion del chatbot (4 turnos) hasta completar la config.
    3. Validacion REAL de la credencial (chat completions).
    4. Creacion de la solicitud Child en una BD temporal + auditoria.
    5. Caso negativo: modelo inexistente -> estado y motivo accionables.

Uso directo:
    python pruebas/asistente-ia/Probar-AsistenteIA.py `
        --url-base "https://<recurso>.services.ai.azure.com/models" `
        --api-key  "<api-key>" `
        --modelo   "Proyecto-ia-ur" `
        --proveedor msfoundry

O mediante variables de entorno HERMES_IA_URL_BASE / HERMES_IA_API_KEY /
HERMES_IA_MODELO / HERMES_IA_PROVEEDOR.

Salida: lineas [PASS]/[FAIL] y codigo de salida 0 (todo OK) o 1 (fallos).
La api key NUNCA se imprime: solo mascara y huella SHA-256.
====================================================================
"""

import os
import sys
import argparse
import tempfile
import traceback
from pathlib import Path

_RAIZ_REPOSITORIO = Path(__file__).resolve().parent.parent.parent
if str(_RAIZ_REPOSITORIO) not in sys.path:
    sys.path.insert(0, str(_RAIZ_REPOSITORIO))

from Hermes.Web.backend.servicio_asistente_ia import (  # noqa: E402
    AsistenteIA,
    CATALOGO_PROVEEDORES,
    enmascarar_api_key,
    es_url_base_valida,
    huella_api_key,
    resolver_endpoint_chat,
)
from Hermes.Web.backend.servicio_fabrica import ServicioFabrica  # noqa: E402

ASP_VALIDO = (
    "/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/"
    "resourceGroups/RG-Hermes-Proyectos/"
    "providers/Microsoft.Web/serverfarms/ASP-HERMES-PORTAL"
)


class Reporte:
    """Acumula resultados [PASS]/[FAIL] de la prueba local."""

    def __init__(self):
        self.exitos = 0
        self.fallos = 0

    def caso(self, nombre, condicion, detalle=""):
        if condicion:
            self.exitos += 1
            print(f"  [PASS] {nombre}")
        else:
            self.fallos += 1
            print(f"  [FAIL] {nombre}" + (f" -> {detalle}" if detalle else ""))
        return bool(condicion)

    def seccion(self, titulo):
        print("")
        print(f"[Prueba] {titulo}")


def conversar(asistente, mensajes):
    """Recorre la conversacion manteniendo el borrador del lado del cliente."""
    borrador = {}
    historial = []
    ultimo = None
    for mensaje in mensajes:
        ultimo = asistente.responder(mensaje=mensaje, borrador=borrador, historial=historial)
        historial.append({"rol": "user", "contenido": mensaje})
        historial.append({"rol": "assistant", "contenido": ultimo["respuesta"]})
        for campo in ultimo["campos_capturados"]:
            borrador[campo] = mensaje if campo == "api_key" else ultimo["borrador"][campo]
    return ultimo


def main() -> int:
    parser = argparse.ArgumentParser(description="Prueba local del Asistente IA")
    parser.add_argument("--url-base", default=os.environ.get("HERMES_IA_URL_BASE", ""))
    parser.add_argument("--api-key", default=os.environ.get("HERMES_IA_API_KEY", ""))
    parser.add_argument("--modelo", default=os.environ.get("HERMES_IA_MODELO", "Proyecto-ia-ur"))
    parser.add_argument("--proveedor", default=os.environ.get("HERMES_IA_PROVEEDOR", "msfoundry"))
    args = parser.parse_args()

    url_base = (args.url_base or "").strip()
    api_key = (args.api_key or "").strip()
    modelo = (args.modelo or "").strip()
    proveedor = (args.proveedor or "msfoundry").strip()

    if not url_base or not api_key:
        print("")
        print("[ERROR] Falta la configuracion del proveedor.")
        print("        Defina --url-base y --api-key (o las variables de entorno")
        print("        HERMES_IA_URL_BASE / HERMES_IA_API_KEY) e intente de nuevo.")
        print("")
        return 2

    config = {
        "proveedor": proveedor,
        "url_base": url_base,
        "api_key": api_key,
        "modelo": modelo,
    }

    print("=" * 70)
    print("PRUEBA LOCAL - Asistente IA de configuracion de proyectos Child")
    print("=" * 70)
    print(f"  Proveedor : {proveedor}")
    print(f"  URL base  : {url_base}")
    print(f"  Endpoint  : {resolver_endpoint_chat(url_base)}")
    print(f"  Modelo    : {modelo}")
    print(f"  API Key   : {enmascarar_api_key(api_key)}")
    print(f"  Huella    : {huella_api_key(api_key)[:16]}...")
    print("=" * 70)

    reporte = Reporte()
    asistente = AsistenteIA()

    # ── 1. Contrato estatico ──
    reporte.seccion("1. Contrato del asistente y catalogo de proveedores")
    reporte.caso("La URL base es valida", es_url_base_valida(url_base), url_base)
    ids = [p["id"] for p in CATALOGO_PROVEEDORES]
    reporte.caso("El proveedor existe en el catalogo", proveedor in ids, f"validos={ids}")
    reporte.caso("httpx disponible para la validacion real", asistente._httpx_disponible)

    # ── 2. Conversacion del chatbot ──
    reporte.seccion("2. Conversacion del chatbot (4 turnos)")
    ultimo = conversar(asistente, [proveedor, url_base, api_key, modelo])
    reporte.caso("La conversacion se completa",
                 ultimo.get("completado") is True, str(ultimo.get("respuesta", ""))[:120])
    reporte.caso("El modelo fue capturado", ultimo["borrador"].get("modelo") == modelo)
    reporte.caso("La api key no se filtra en la respuesta", api_key not in repr(ultimo))
    reporte.caso("La api key se muestra enmascarada",
                 ultimo["borrador"].get("api_key_enmascarada") == enmascarar_api_key(api_key))

    # ── 3. Validacion REAL de la credencial ──
    reporte.seccion("3. Validacion REAL contra el proveedor (previa a produccion)")
    resultado = asistente.validar_conexion(config)
    print(f"         HTTP={resultado['http_status']} estado={resultado['estado']} "
          f"latencia={resultado['latencia_ms']}ms")
    if not resultado["ok"]:
        print(f"         Error   : {resultado['error']}")
        print(f"         Detalle : {resultado['detalle']}")
        print(f"         Endpoint: {resultado['endpoint']}")
    reporte.caso("La credencial fue aceptada por el proveedor",
                 resultado["ok"] is True,
                 f"{resultado['estado']} | {resultado.get('error', '')}")
    reporte.caso("La api key no aparece en el resultado", api_key not in repr(resultado))
    reporte.caso("El asistente registra la validacion",
                 asistente.validacion_reciente(config) is True)

    # ── 4. Creacion del proyecto hijo ──
    reporte.seccion("4. Creacion de la solicitud Child (auditoria server-side)")
    config_auditada = dict(config)
    config_auditada["ia_validado"] = ("CONECTADO" if asistente.validacion_reciente(config)
                                      else "NO_VERIFICADO")
    with tempfile.TemporaryDirectory() as tmp:
        ruta_db = str(Path(tmp) / "fabrica_local.db")
        servicio = ServicioFabrica(ruta_db=ruta_db)
        solicitud = servicio.crear_solicitud(
            nombre_proyecto="hermes-ia-local-01",
            descripcion="Prueba local del Asistente IA",
            app_service_plan_id=ASP_VALIDO,
            ia_config=config_auditada,
        )
        reporte.caso("El proyecto hijo registra la configuracion de IA",
                     solicitud.ia_configurada == "SI")
        reporte.caso("Proveedor persistido correctamente",
                     solicitud.ia_proveedor == proveedor)
        reporte.caso("Modelo persistido correctamente", solicitud.ia_modelo == modelo)
        reporte.caso("Estado de validacion auditado",
                     solicitud.ia_validado == "CONECTADO",
                     f"valor={solicitud.ia_validado}")

        releida = servicio.obtener_solicitud(solicitud.deployment_id)
        reporte.caso("La solicitud se relee desde SQLite",
                     releida is not None and releida.ia_modelo == modelo)
        reporte.caso("a_dict() no expone la api key",
                     api_key not in repr(releida.a_dict()))
        reporte.caso("El Event Store no expone la api key",
                     api_key not in repr(servicio.obtener_eventos(solicitud.deployment_id)))

        credencial = servicio.obtener_credencial_ia(solicitud.deployment_id)
        reporte.caso("La credencial queda disponible para el Factory",
                     credencial is not None and credencial.get("api_key") == api_key)

        # ── 5. Caso negativo ──
        reporte.seccion("5. Caso negativo: modelo inexistente")
        negativo = asistente.validar_conexion(dict(config, modelo="modelo-que-no-existe-ur"))
        print(f"         HTTP={negativo['http_status']} estado={negativo['estado']}")
        print(f"         Motivo  : {negativo['error']}")
        reporte.caso("El modelo inexistente NO es aceptado", negativo["ok"] is False)
        reporte.caso("Devuelve un estado semantico, no un mensaje generico",
                     str(negativo["estado"]).startswith("ERROR_"))
        reporte.caso("Propaga el motivo real del proveedor", bool(negativo["error"]))

    print("")
    print("=" * 70)
    print(f"RESULTADO: {reporte.exitos} PASS / {reporte.fallos} FAIL")
    print("=" * 70)
    if reporte.fallos:
        print("La prueba local NO paso. Corrija lo anterior antes de produccion.")
        return 1
    print("La prueba local paso. Es seguro continuar con la prueba en produccion.")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except Exception:
        print("")
        print("[ERROR] Excepcion no controlada durante la prueba local:")
        traceback.print_exc()
        sys.exit(1)