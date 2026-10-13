# -*- coding: utf-8 -*-
"""
====================================================================
test_asistente_ia_myfoundry_live.py — PRUEBA LOCAL (LIVE)
Asistente IA contra Microsoft Foundry / Azure AI Foundry
====================================================================

Esta bateria sale a la RED: valida la credencial REAL de un deployment
de Microsoft Foundry (por ejemplo el deployment 'Proyecto-ia-ur') antes
de realizar cualquier prueba en produccion.

Se SALTA automaticamente si no se define la configuracion por entorno,
de modo que la suite CI sigue siendo determinista y sin secretos.

PREPARACION (PowerShell, en la raiz del repositorio):

    $env:HERMES_IA_URL_BASE  = "https://<recurso>.services.ai.azure.com/models"
    $env:HERMES_IA_API_KEY   = "<api-key-del-recurso>"
    $env:HERMES_IA_MODELO    = "Proyecto-ia-ur"
    $env:HERMES_IA_PROVEEDOR = "msfoundry"

EJECUCION:

    python -m pytest Hermes.Web/tests/test_asistente_ia_myfoundry_live.py -v -s

Nota: la api key NUNCA se imprime (solo su mascara y su huella SHA-256).
====================================================================
"""

import os
import sys
import logging
from pathlib import Path

logging.disable(logging.CRITICAL)

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

import pytest  # noqa: E402

from Hermes.Web.backend.servicio_asistente_ia import (  # noqa: E402
    AsistenteIA,
    enmascarar_api_key,
    es_url_base_valida,
    huella_api_key,
    resolver_endpoint_chat,
)
from Hermes.Web.backend.servicio_fabrica import ServicioFabrica  # noqa: E402
from Hermes.Web.api.api_asistente import ConfiguracionIA  # noqa: E402

# ── Configuracion de la prueba live (desde el entorno) ──
URL_BASE = os.environ.get("HERMES_IA_URL_BASE", "").strip()
API_KEY = os.environ.get("HERMES_IA_API_KEY", "").strip()
MODELO = os.environ.get("HERMES_IA_MODELO", "Proyecto-ia-ur").strip()
PROVEEDOR = os.environ.get("HERMES_IA_PROVEEDOR", "msfoundry").strip()

pytestmark = pytest.mark.skipif(
    not (URL_BASE and API_KEY),
    reason=("Prueba LIVE deshabilitada: defina HERMES_IA_URL_BASE y "
            "HERMES_IA_API_KEY (y opcionalmente HERMES_IA_MODELO, "
            "HERMES_IA_PROVEEDOR) para ejecutarla."),
)

_ASP_VALIDO = (
    "/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/"
    "resourceGroups/RG-Hermes-Proyectos/"
    "providers/Microsoft.Web/serverfarms/ASP-HERMES-PORTAL"
)


def _config():
    return {
        "proveedor": PROVEEDOR,
        "url_base": URL_BASE,
        "api_key": API_KEY,
        "modelo": MODELO,
    }


def _conversar(asistente, mensajes):
    """Recorre la conversacion completa manteniendo el borrador del cliente."""
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


@pytest.fixture(scope="module", autouse=True)
def anuncio_configuracion():
    """Imprime la configuracion live con la api key SIEMPRE enmascarada."""
    print("\n" + "=" * 68)
    print("PRUEBA LOCAL — Asistente IA contra Microsoft Foundry")
    print("=" * 68)
    print(f"  Proveedor : {PROVEEDOR}")
    print(f"  URL base  : {URL_BASE}")
    print(f"  Endpoint  : {resolver_endpoint_chat(URL_BASE)}")
    print(f"  Modelo    : {MODELO}")
    print(f"  API Key   : {enmascarar_api_key(API_KEY)}")
    print(f"  Huella    : {huella_api_key(API_KEY)[:16]}...")
    print("=" * 68)


def test_la_url_base_es_valida():
    assert es_url_base_valida(URL_BASE), f"URL base invalida: {URL_BASE}"


def test_conexion_real_chat_completions():
    """La prueba clave previa a produccion: llamada REAL al deployment."""
    asistente = AsistenteIA()
    resultado = asistente.validar_conexion(_config())
    print("\n  HTTP:", resultado["http_status"],
          "| estado:", resultado["estado"],
          "| latencia:", resultado["latencia_ms"], "ms")
    if not resultado["ok"]:
        print("  Error  :", resultado["error"])
        print("  Detalle:", resultado["detalle"])
    assert resultado["ok"] is True, (
        f"La credencial fue rechazada ({resultado['estado']}): "
        f"{resultado['error']} | detalle={resultado['detalle']}"
    )
    assert resultado["http_status"] == 200
    assert resultado["endpoint"] == resolver_endpoint_chat(URL_BASE)
    assert API_KEY not in repr(resultado), "la api key no debe aparecer en el resultado"


def test_el_asistente_registra_la_validacion():
    asistente = AsistenteIA()
    assert asistente.validacion_reciente(_config()) is False
    assert asistente.validar_conexion(_config())["ok"] is True
    assert asistente.validacion_reciente(_config()) is True


def test_flujo_completo_del_chatbot():
    """Conversacion determinista de 4 turnos hasta la configuracion completa."""
    asistente = AsistenteIA()
    ultimo = _conversar(asistente, [PROVEEDOR, URL_BASE, API_KEY, MODELO])
    assert ultimo["completado"] is True, "la conversacion no llego a completarse"
    assert ultimo["borrador"]["modelo"] == MODELO
    assert API_KEY not in repr(ultimo), "la api key no debe filtrarse en la respuesta"


def test_creacion_del_proyecto_hijo_con_ia_validada(tmp_path):
    """Flujo end-to-end local: validar -> crear solicitud -> auditar."""
    asistente = AsistenteIA()
    assert asistente.validar_conexion(_config())["ok"] is True

    servicio = ServicioFabrica(ruta_db=str(tmp_path / "fabrica_live.db"))
    config = _config()
    config["ia_validado"] = ("CONECTADO" if asistente.validacion_reciente(config)
                             else "NO_VERIFICADO")

    solicitud = servicio.crear_solicitud(
        nombre_proyecto="hermes-ia-live-01",
        descripcion="Prueba local del Asistente IA (Foundry)",
        app_service_plan_id=_ASP_VALIDO,
        ia_config=config,
    )
    assert solicitud.ia_configurada == "SI"
    assert solicitud.ia_proveedor == PROVEEDOR
    assert solicitud.ia_modelo == MODELO
    assert solicitud.ia_url_base == URL_BASE
    assert solicitud.ia_api_key_enmascarada == enmascarar_api_key(API_KEY)
    assert solicitud.ia_validado == "CONECTADO"

    releida = servicio.obtener_solicitud(solicitud.deployment_id)
    assert releida.ia_modelo == MODELO
    assert API_KEY not in repr(releida.a_dict())

    credencial = servicio.obtener_credencial_ia(solicitud.deployment_id)
    assert credencial["api_key"] == API_KEY
    assert credencial["modelo"] == MODELO

    assert API_KEY not in repr(servicio.obtener_eventos(solicitud.deployment_id))


def test_modelo_inexistente_devuelve_un_estado_util():
    """
    Caso negativo: un modelo inexistente debe producir un estado y un
    motivo claros (nunca un mensaje generico sin informacion accionable).
    """
    asistente = AsistenteIA()
    resultado = asistente.validar_conexion(
        dict(_config(), modelo="modelo-que-no-existe-ur"))
    print("\n  Estado del caso negativo:", resultado["estado"],
          "| HTTP:", resultado["http_status"])
    print("  Motivo:", resultado["error"])
    assert resultado["ok"] is False
    assert resultado["estado"] in (
        "ERROR_MODELO_NO_ENCONTRADO", "ERROR_SOLICITUD_INVALIDA",
        "ERROR_AUTENTICACION", "ERROR_PERMISOS",
    )
    assert resultado["error"], "debe devolver un mensaje accionable"
    assert resultado["http_status"] is not None


def test_contrato_de_ConfiguracionIA_con_los_valores_reales():
    modelo = ConfiguracionIA(**_config())
    assert modelo.proveedor == PROVEEDOR
    assert modelo.modelo == MODELO
    assert API_KEY not in modelo.model_dump_json(exclude={"api_key"})