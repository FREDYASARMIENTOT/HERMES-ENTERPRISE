# -*- coding: utf-8 -*-
"""
====================================================================
test_asistente_ia.py — Asistente IA de configuracion de modelos
====================================================================

Chatbot de configuracion de IA en la creacion de proyectos Child.

Cobertura:
    BLOQUE 1  Helpers puros (url, mascara, huella, headers, endpoints)
    BLOQUE 2  Captura desde lenguaje natural (etiquetas y heuristica)
    BLOQUE 3  Maquina de estados conversacional (responder)
    BLOQUE 4  Validacion real de credenciales (httpx mockeado)
    BLOQUE 5  Router /api/asistente (contrato de endpoints)
    BLOQUE 6  Persistencia del proyecto Child (servicio_fabrica)
    BLOQUE 7  Regresion: creacion sin configuracion IA

Ejecutar:
    pytest Hermes.Web/tests/test_asistente_ia.py -v
====================================================================
"""

import os
import sys
import asyncio
import sqlite3
import tempfile
import logging
from pathlib import Path
from unittest.mock import MagicMock

import httpx

logging.disable(logging.CRITICAL)

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
if str(_PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(_PROJECT_ROOT))

import pytest  # noqa: E402

from Hermes.Web.backend.servicio_asistente_ia import (  # noqa: E402
    CATALOGO_PROVEEDORES,
    PROVEEDOR_POR_DEFECTO,
    AsistenteIA,
    capturar_campo,
    clasificar_http,
    construir_headers,
    detectar_proveedor,
    enmascarar_api_key,
    es_url_base_valida,
    extraer_detalle_error,
    extraer_url,
    huella_api_key,
    normalizar_url_base,
    parsear_etiquetados,
    resolver_endpoint_chat,
)
from Hermes.Web.api.api_asistente import (  # noqa: E402
    ChatRequest,
    ConfiguracionIA,
    MensajeChat,
    chat_asistente,
    estado_asistente,
    listar_campos,
    listar_proveedores,
    validar_configuracion,
)
from Hermes.Web.backend.servicio_fabrica import ServicioFabrica  # noqa: E402
from Hermes.Web.api.api_fabrica import SolicitudCrear, crear_proyecto  # noqa: E402

# App Service Plan valido (el mismo usado por la bateria canonica del portal)
_ASP_VALIDO = (
    "/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/"
    "resourceGroups/RG-Hermes-Proyectos/"
    "providers/Microsoft.Web/serverfarms/ASP-HERMES-PORTAL"
)

_URL_FOUNDRY = "https://proyecto-ia.services.ai.azure.com/models"
_MODELO_FOUNDRY = "Proyecto-ia-ur"
_API_KEY = "sk-clave-de-prueba-1234567890"

_CONFIG_VALIDA = {
    "proveedor": "msfoundry",
    "url_base": _URL_FOUNDRY,
    "api_key": _API_KEY,
    "modelo": _MODELO_FOUNDRY,
}


# ============================================================
# Helpers de prueba
# ============================================================

@pytest.fixture
def asistente():
    """Asistente aislado con la red desconectada (httpx mockeado)."""
    a = AsistenteIA()
    a._httpx = MagicMock()
    a._httpx_disponible = True
    return a


@pytest.fixture(autouse=True)
def sin_llm_interna(monkeypatch):
    """Garantiza que el LLM interno del asistente no se activa en pruebas."""
    for var in ("HERMES_ASISTENTE_URL_BASE", "HERMES_ASISTENTE_API_KEY",
                "HERMES_ASISTENTE_MODELO", "HERMES_ASISTENTE_PROVEEDOR"):
        monkeypatch.delenv(var, raising=False)


@pytest.fixture
def db_temporal():
    """Base de datos SQLite aislada por prueba."""
    tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    tmp.close()
    yield tmp.name
    try:
        os.unlink(tmp.name)
    except PermissionError:
        pass


def _respuesta_http(asistente, status_code, payload=None, texto=""):
    """Inyecta una respuesta HTTP simulada en el asistente."""
    respuesta = MagicMock()
    respuesta.status_code = status_code
    respuesta.text = texto
    if payload is None:
        respuesta.json.side_effect = ValueError("sin json")
    else:
        respuesta.json.return_value = payload
    asistente._httpx.post = MagicMock(return_value=respuesta)
    return asistente


def _respuesta_chat(contenido="pong", modelo_eco=None):
    """Payload OpenAI-compatible de exito."""
    return {
        "id": "chatcmpl-test",
        "model": modelo_eco or _MODELO_FOUNDRY,
        "choices": [{"index": 0, "message": {"role": "assistant", "content": contenido}}],
    }


def _conversar(asistente, mensajes):
    """
    Recorre la conversacion manteniendo el borrador del lado del cliente:
    el API es stateless y el navegador es dueno del borrador.
    """
    borrador = {}
    historial = []
    ultimo = None
    for mensaje in mensajes:
        ultimo = asistente.responder(mensaje=mensaje, borrador=borrador, historial=historial)
        historial.append({"rol": "user", "contenido": mensaje})
        historial.append({"rol": "assistant", "contenido": ultimo["respuesta"]})
        for campo in ultimo["campos_capturados"]:
            # El navegador conserva el valor crudo que el usuario escribio
            borrador[campo] = mensaje.strip() if campo == "api_key" else ultimo["borrador"][campo]
    return ultimo


def _async(coro):
    """Ejecuta una corrutina del router en el bucle de eventos."""
    return asyncio.run(coro)


# ============================================================
# BLOQUE 1 — Helpers puros
# ============================================================

class TestCatalogoYHelpers:

    def test_catalogo_ids_unicos_e_incluye_msfoundry(self):
        ids = [p["id"] for p in CATALOGO_PROVEEDORES]
        assert len(ids) == len(set(ids)), "los ids de proveedor deben ser unicos"
        assert "msfoundry" in ids
        assert PROVEEDOR_POR_DEFECTO == "msfoundry"
        for proveedor in CATALOGO_PROVEEDORES:
            for clave in ("id", "nombre", "url_base_sugerida", "auth_estilo",
                          "requiere_api_key", "plantilla_modelo", "notas"):
                assert clave in proveedor, f"falta '{clave}' en {proveedor.get('id')}"

    @pytest.mark.parametrize("entrada,esperado", [
        ("https://x.services.ai.azure.com/models/", "https://x.services.ai.azure.com/models"),
        ("  https://api.openai.com/v1  ", "https://api.openai.com/v1"),
        ("api.openai.com/v1", "https://api.openai.com/v1"),
        ("localhost:11434/v1", "http://localhost:11434/v1"),
        ("", ""),
    ])
    def test_normalizar_url_base(self, entrada, esperado):
        assert normalizar_url_base(entrada) == esperado

    def test_es_url_base_valida(self):
        assert es_url_base_valida(_URL_FOUNDRY) is True
        assert es_url_base_valida("http://localhost:11434/v1") is True
        assert es_url_base_valida("http://127.0.0.1:8000/v1") is True
        assert es_url_base_valida("services.ai.azure.com") is False
        assert es_url_base_valida("no-es-url") is False
        assert es_url_base_valida("https://sin-punto/v1") is False
        assert es_url_base_valida("") is False

    def test_enmascarar_api_key_nunca_revela_el_secreto(self):
        clave = "sk-abcdefghijklmnopqrstuvwxyz012345"
        mascara = enmascarar_api_key(clave)
        assert clave not in mascara
        assert mascara.startswith("sk-a") and mascara.endswith("2345")
        assert len(mascara) < len(clave)
        assert enmascarar_api_key("abc") == "***"
        assert enmascarar_api_key("") == ""

    def test_huella_api_key_es_determinista_y_distinta(self):
        assert huella_api_key("sk-uno") == huella_api_key("sk-uno")
        assert huella_api_key("sk-uno") != huella_api_key("sk-dos")
        assert len(huella_api_key("sk-uno")) == 64
        assert huella_api_key("") == ""

    @pytest.mark.parametrize("texto,esperado", [
        ("use msfoundry por favor", "msfoundry"),
        ("Microsoft Foundry", "msfoundry"),
        ("azure ai foundry", "msfoundry"),
        ("azure openai", "azure-openai"),
        ("openrouter", "openrouter"),
        ("ollama local", "ollama"),
        ("openai", "openai"),
        ("un gateway compatible", "custom"),
        ("no se que poner", None),
    ])
    def test_detectar_proveedor(self, texto, esperado):
        assert detectar_proveedor(texto) == esperado

    def test_extraer_url(self):
        assert extraer_url("mi endpoint es https://a.b.com/models.") == "https://a.b.com/models"
        assert extraer_url("sin url") is None

    @pytest.mark.parametrize("url,esperado", [
        (_URL_FOUNDRY, _URL_FOUNDRY + "/chat/completions"),
        ("https://api.openai.com/v1", "https://api.openai.com/v1/chat/completions"),
        ("https://x.openai.azure.com/openai/v1", "https://x.openai.azure.com/openai/v1/chat/completions"),
        ("https://a.b.com/chat/completions", "https://a.b.com/chat/completions"),
        ("https://a.b.com", "https://a.b.com/v1/chat/completions"),
    ])
    def test_resolver_endpoint_chat(self, url, esperado):
        assert resolver_endpoint_chat(url) == esperado

    def test_construir_headers_por_proveedor(self):
        assert construir_headers("msfoundry", "k") == {
            "Content-Type": "application/json", "api-key": "k", "Authorization": "Bearer k"}
        assert construir_headers("openai", "k") == {
            "Content-Type": "application/json", "Authorization": "Bearer k"}
        assert construir_headers("ollama", "") == {"Content-Type": "application/json"}

    @pytest.mark.parametrize("status,esperado", [
        (200, "CONECTADO"), (400, "ERROR_SOLICITUD_INVALIDA"),
        (401, "ERROR_AUTENTICACION"), (403, "ERROR_PERMISOS"),
        (404, "ERROR_MODELO_NO_ENCONTRADO"), (429, "ERROR_CUOTA"),
        (500, "ERROR_PROVEEDOR"), (503, "ERROR_PROVEEDOR"),
    ])
    def test_clasificar_http(self, status, esperado):
        assert clasificar_http(status) == esperado

    def test_extraer_detalle_error_prioriza_el_motivo_real(self):
        # Comportamiento clave: nunca perder el motivo real devuelto por el host.
        assert extraer_detalle_error(
            {"error": {"message": "MODEL_DOES_NOT_SUPPORT_IMAGES"}}) == "MODEL_DOES_NOT_SUPPORT_IMAGES"
        assert extraer_detalle_error({"message": "gateway/input-invalid"}) == "gateway/input-invalid"
        assert extraer_detalle_error({"reason": "prompt rejected"}) == "prompt rejected"
        assert extraer_detalle_error({"detail": "FILE_NOT_STAGED"}) == "FILE_NOT_STAGED"
        assert extraer_detalle_error({"error": "bad-request"}) == "bad-request"
        assert extraer_detalle_error(None, "texto plano del host") == "texto plano del host"
        assert extraer_detalle_error({}, "") == ""


# ============================================================
# BLOQUE 2 — Captura desde lenguaje natural
# ============================================================

class TestCapturaLenguajeNatural:

    def test_parsear_etiquetados_multilinea(self):
        texto = (
            "proveedor: msfoundry\n"
            f"url_base: {_URL_FOUNDRY}\n"
            f"api_key: {_API_KEY}\n"
            f"modelo: {_MODELO_FOUNDRY}\n"
        )
        assert parsear_etiquetados(texto) == _CONFIG_VALIDA

    def test_parsear_etiquetados_en_una_linea(self):
        texto = (f"proveedor=msfoundry  url_base={_URL_FOUNDRY}  "
                 f"api_key={_API_KEY}  modelo={_MODELO_FOUNDRY}")
        resultado = parsear_etiquetados(texto)
        assert resultado["proveedor"] == "msfoundry"
        assert resultado["url_base"] == _URL_FOUNDRY
        assert resultado["api_key"] == _API_KEY
        assert resultado["modelo"] == _MODELO_FOUNDRY

    def test_parsear_etiquetados_no_confunde_models_con_modelo(self):
        """La ruta '/models' de una URL no debe interpretarse como etiqueta."""
        assert parsear_etiquetados(_URL_FOUNDRY) == {}

    def test_parsear_etiquetados_texto_sin_etiquetas(self):
        assert parsear_etiquetados("hola, quiero configurar el modelo") == {}

    def test_capturar_campo_proveedor(self):
        assert capturar_campo("proveedor", "quiero usar MS Foundry") == "msfoundry"
        assert capturar_campo("proveedor", "no se") is None

    def test_capturar_campo_url_base_con_y_sin_esquema(self):
        assert capturar_campo("url_base", _URL_FOUNDRY) == _URL_FOUNDRY
        assert capturar_campo("url_base",
                              "proyecto-ia.services.ai.azure.com/models") == _URL_FOUNDRY
        assert capturar_campo("url_base", "sin url") is None

    def test_capturar_campo_api_key_descarta_etiquetas_y_bearer(self):
        assert capturar_campo("api_key", "Bearer sk-abc123456789") == "sk-abc123456789"
        assert capturar_campo("api_key", "mi clave es sk-abc123456789") == "sk-abc123456789"
        assert capturar_campo("api_key", "   ") is None

    def test_capturar_campo_modelo(self):
        assert capturar_campo("modelo", _MODELO_FOUNDRY) == _MODELO_FOUNDRY
        assert capturar_campo("modelo", '"Proyecto-ia-ur"\n(gracias)') == _MODELO_FOUNDRY


# ============================================================
# BLOQUE 3 — Maquina de estados conversacional
# ============================================================

class TestConversacion:

    def test_primer_turno_saluda_y_pide_proveedor(self, asistente):
        r = asistente.responder()
        assert r["mensaje_tipo"] == "pregunta"
        assert r["campo_actual"] == "proveedor"
        assert "Asistente IA" in r["respuesta"]
        assert "msfoundry" in r["respuesta"]  # ofrece el catalogo
        assert r["completado"] is False

    def test_secuencia_completa_de_cuatro_pasos(self, asistente):
        r = _conversar(asistente, [
            "msfoundry",
            _URL_FOUNDRY,
            _API_KEY,
            _MODELO_FOUNDRY,
        ])
        assert r["completado"] is True
        assert r["listo_para_validar"] is True
        assert r["mensaje_tipo"] == "completado"
        assert r["borrador"]["proveedor"] == "msfoundry"
        assert r["borrador"]["url_base"] == _URL_FOUNDRY
        assert r["borrador"]["modelo"] == _MODELO_FOUNDRY
        # La api key jamas se devuelve en claro: solo enmascarada
        assert r["borrador"]["api_key"] == ""
        assert _API_KEY not in r["respuesta"]
        assert r["borrador"]["api_key_enmascarada"].startswith("sk-c")

    def test_orden_de_preguntas_es_el_contrato(self, asistente):
        borrador = {}
        campos = []
        for mensaje in ("msfoundry", _URL_FOUNDRY, _API_KEY, _MODELO_FOUNDRY):
            r = asistente.responder(mensaje, borrador=borrador)
            campos.append(r["campo_actual"])
            for campo in r["campos_capturados"]:
                borrador[campo] = mensaje
        assert campos == ["url_base", "api_key", "modelo", ""]

    def test_pegado_completo_en_un_solo_mensaje(self, asistente):
        texto = (f"proveedor: msfoundry\nurl_base: {_URL_FOUNDRY}\n"
                 f"api_key: {_API_KEY}\nmodelo: {_MODELO_FOUNDRY}")
        r = asistente.responder(texto)
        assert r["completado"] is True
        assert set(r["campos_capturados"]) == {"proveedor", "url_base", "api_key", "modelo"}

    def test_comando_reiniciar_limpia_el_borrador(self, asistente):
        r = asistente.responder("reiniciar", borrador=dict(_CONFIG_VALIDA))
        assert r["reiniciado"] is True
        assert r["borrador"]["campos_faltantes"] == ["proveedor", "url_base", "api_key", "modelo"]
        assert r["completado"] is False

    def test_comando_cancelar(self, asistente):
        r = asistente.responder("cancelar", borrador=dict(_CONFIG_VALIDA))
        assert r["reiniciado"] is True
        assert r["mensaje_tipo"] == "info"
        assert r["completado"] is False

    def test_url_invalida_genera_aviso_y_no_avanza(self, asistente):
        borrador = {"proveedor": "msfoundry"}
        r = asistente.responder("no-es-una-url", borrador=borrador)
        assert r["campo_actual"] == "url_base"
        assert r["completado"] is False
        assert r["avisos"], "debe informar que no se pudo interpretar el valor"

    def test_usar_llm_sin_bootstrap_no_rompe(self, asistente):
        r = asistente.responder("msfoundry", usar_llm=True)
        assert r["llm_usado"] is False
        assert r["borrador"]["proveedor"] == "msfoundry"

    def test_responder_nunca_devuelve_la_api_key_cruda(self, asistente):
        r = asistente.responder(
            f"api_key: {_API_KEY}",
            borrador={"proveedor": "msfoundry", "url_base": _URL_FOUNDRY},
        )
        serializado = repr(r)
        assert _API_KEY not in serializado


# ============================================================
# BLOQUE 4 — Validacion real de credenciales (httpx mockeado)
# ============================================================

class TestValidarConexion:

    def test_200_devuelve_conectado_con_eco_del_modelo(self, asistente):
        _respuesta_http(asistente, 200, _respuesta_chat("pong"))
        r = asistente.validar_conexion(_CONFIG_VALIDA)
        assert r["ok"] is True
        assert r["estado"] == "CONECTADO"
        assert r["http_status"] == 200
        assert r["respuesta_modelo"] == "pong"
        assert r["endpoint"] == _URL_FOUNDRY + "/chat/completions"
        assert r["latencia_ms"] >= 0

    def test_el_endpoint_se_construye_correctamente(self, asistente):
        _respuesta_http(asistente, 200, _respuesta_chat())
        asistente.validar_conexion(_CONFIG_VALIDA)
        endpoint_usado = asistente._httpx.post.call_args[0][0]
        assert endpoint_usado == _URL_FOUNDRY + "/chat/completions"

    def test_el_payload_es_minimo_para_evitar_errores_de_parametros(self, asistente):
        """
        Solo 'model' y 'messages'. Ni temperature ni max_tokens: los
        modelos desplegados (DeepSeek) los rechazan con errores enganosos.
        """
        _respuesta_http(asistente, 200, _respuesta_chat())
        asistente.validar_conexion(_CONFIG_VALIDA)
        cuerpo = asistente._httpx.post.call_args[1]["json"]
        assert set(cuerpo.keys()) == {"model", "messages"}
        assert cuerpo["model"] == _MODELO_FOUNDRY

    def test_los_headers_de_msfoundry_llevan_api_key(self, asistente):
        _respuesta_http(asistente, 200, _respuesta_chat())
        asistente.validar_conexion(_CONFIG_VALIDA)
        headers = asistente._httpx.post.call_args[1]["headers"]
        assert headers["api-key"] == _API_KEY
        assert headers["Authorization"] == f"Bearer {_API_KEY}"

    @pytest.mark.parametrize("status,estado", [
        (401, "ERROR_AUTENTICACION"),
        (403, "ERROR_PERMISOS"),
        (404, "ERROR_MODELO_NO_ENCONTRADO"),
        (429, "ERROR_CUOTA"),
        (400, "ERROR_SOLICITUD_INVALIDA"),
        (500, "ERROR_PROVEEDOR"),
    ])
    def test_estados_de_error_http(self, asistente, status, estado):
        _respuesta_http(asistente, status, {"error": {"message": "detalle-del-host"}})
        r = asistente.validar_conexion(_CONFIG_VALIDA)
        assert r["ok"] is False
        assert r["estado"] == estado
        assert "detalle-del-host" in r["error"], "el motivo del host debe propagarse"

    def test_400_propaga_el_reason_real_del_proveedor(self, asistente):
        """Caso real observado: MODEL_DOES_NOT_SUPPORT_IMAGES."""
        _respuesta_http(asistente, 400, {
            "error": {"code": "invalid_payload", "message": "MODEL_DOES_NOT_SUPPORT_IMAGES"}
        })
        r = asistente.validar_conexion(_CONFIG_VALIDA)
        assert r["estado"] == "ERROR_SOLICITUD_INVALIDA"
        assert r["detalle"] == "MODEL_DOES_NOT_SUPPORT_IMAGES"
        assert "MODEL_DOES_NOT_SUPPORT_IMAGES" in r["error"]

    def test_400_sin_json_usa_el_texto_plano(self, asistente):
        _respuesta_http(asistente, 400, None, "gateway/input-invalid")
        r = asistente.validar_conexion(_CONFIG_VALIDA)
        assert "gateway/input-invalid" in r["detalle"]

    def test_timeout(self, asistente):
        asistente._httpx.post = MagicMock(side_effect=httpx.TimeoutException("boom"))
        r = asistente.validar_conexion(_CONFIG_VALIDA)
        assert r["ok"] is False
        assert r["estado"] == "ERROR_TIMEOUT"

    def test_error_de_conexion(self, asistente):
        asistente._httpx.post = MagicMock(
            side_effect=httpx.ConnectError("dns", request=httpx.Request("POST", "https://x")))
        r = asistente.validar_conexion(_CONFIG_VALIDA)
        assert r["ok"] is False
        assert r["estado"] == "ERROR_CONEXION"

    def test_proveedor_desconocido(self, asistente):
        r = asistente.validar_conexion(dict(_CONFIG_VALIDA, proveedor="inventado"))
        assert r["estado"] == "ERROR_PROVEEDOR_DESCONOCIDO"
        assert "msfoundry" in r["detalle"]

    def test_url_invalida(self, asistente):
        r = asistente.validar_conexion(dict(_CONFIG_VALIDA, url_base="no-es-url"))
        assert r["estado"] == "ERROR_URL_INVALIDA"

    def test_sin_modelo(self, asistente):
        r = asistente.validar_conexion(dict(_CONFIG_VALIDA, modelo=""))
        assert r["estado"] == "ERROR_SIN_MODELO"

    def test_sin_api_key_cuando_el_proveedor_la_requiere(self, asistente):
        r = asistente.validar_conexion(dict(_CONFIG_VALIDA, api_key=""))
        assert r["estado"] == "ERROR_SIN_API_KEY"

    def test_ollama_no_requiere_api_key(self, asistente):
        _respuesta_http(asistente, 200, _respuesta_chat("eco"))
        r = asistente.validar_conexion({
            "proveedor": "ollama", "url_base": "http://localhost:11434/v1",
            "api_key": "", "modelo": "llama3.1",
        })
        assert r["ok"] is True

    def test_el_resultado_nunca_contiene_la_api_key(self, asistente):
        _respuesta_http(asistente, 200, _respuesta_chat())
        r = asistente.validar_conexion(_CONFIG_VALIDA)
        assert _API_KEY not in repr(r)
        assert r["api_key_enmascarada"].startswith("sk-c")
        assert len(r["api_key_huella"]) == 64


# ============================================================
# BLOQUE 5 — Router /api/asistente
# ============================================================

class TestRouterAsistente:

    @pytest.fixture
    def singleton(self, monkeypatch):
        """Sustituye el singleton del asistente por uno aislado y mockeado."""
        a = AsistenteIA()
        a._httpx = MagicMock()
        a._httpx_disponible = True
        monkeypatch.setattr(
            "Hermes.Web.api.api_asistente.obtener_asistente_ia", lambda: a)
        return a

    def test_get_proveedores_expone_el_catalogo(self):
        r = _async(listar_proveedores())
        assert r["total"] == len(CATALOGO_PROVEEDORES)
        ids = [p["id"] for p in r["proveedores"]]
        assert "msfoundry" in ids

    def test_get_campos_respeta_el_orden_obligatorio(self):
        r = _async(listar_campos())
        assert [c["id"] for c in r["campos"]] == \
            ["proveedor", "url_base", "api_key", "modelo"]
        assert r["campos"][1]["etiqueta"] == "URL base"
        assert r["proveedor_por_defecto"] == "msfoundry"

    def test_get_estado_reporta_salud(self, singleton):
        r = _async(estado_asistente())
        assert r["servicio"] == "asistente-ia"
        assert r["httpx_disponible"] is True
        assert r["proveedores_disponibles"] == len(CATALOGO_PROVEEDORES)
        assert r["redaccion_llm_disponible"] is False  # sin bootstrap de entorno
        assert r["validaciones_en_cache"] == 0

    def test_post_chat_primer_turno(self, singleton):
        r = _async(chat_asistente(ChatRequest()))
        assert r.campo_actual == "proveedor"
        assert r.completado is False
        assert "msfoundry" in r.respuesta

    def test_post_chat_flujo_completo(self, singleton):
        borrador = {}
        historial = []
        for mensaje in ("msfoundry", _URL_FOUNDRY, _API_KEY, _MODELO_FOUNDRY):
            r = _async(chat_asistente(ChatRequest(
                mensaje=mensaje, borrador=borrador, historial=historial)))
            historial.append(MensajeChat(rol="user", contenido=mensaje))
            historial.append(MensajeChat(rol="assistant", contenido=r.respuesta))
            for campo in r.campos_capturados:
                borrador[campo] = mensaje if campo == "api_key" else r.borrador[campo]
        assert r.completado is True
        assert r.listo_para_validar is True
        assert r.borrador["api_key"] == ""
        assert _API_KEY not in r.respuesta

    def test_post_validar_ok(self, singleton):
        _respuesta_http(singleton, 200, _respuesta_chat("pong"))
        r = _async(validar_configuracion(ConfiguracionIA(**_CONFIG_VALIDA)))
        assert r.ok is True
        assert r.estado == "CONECTADO"
        assert r.respuesta_modelo == "pong"
        assert _API_KEY not in r.model_dump_json()

    def test_post_validar_expone_el_motivo_del_proveedor(self, singleton):
        _respuesta_http(singleton, 400, {
            "error": {"message": "MODEL_DOES_NOT_SUPPORT_IMAGES"}})
        r = _async(validar_configuracion(ConfiguracionIA(**_CONFIG_VALIDA)))
        assert r.ok is False
        assert r.http_status == 400
        assert "MODEL_DOES_NOT_SUPPORT_IMAGES" in r.error

    def test_configuracion_ia_tiene_proveedor_por_defecto(self):
        modelo = ConfiguracionIA()
        assert modelo.proveedor == "msfoundry"
        assert modelo.url_base == "" and modelo.api_key == "" and modelo.modelo == ""

    def test_solicitud_crear_acepta_la_configuracion_ia(self):
        solicitud = SolicitudCrear(
            nombre_proyecto="hermes-ia-01",
            app_service_plan_id=_ASP_VALIDO,
            ia=ConfiguracionIA(**_CONFIG_VALIDA),
        )
        datos = solicitud.model_dump()
        assert datos["ia"]["proveedor"] == "msfoundry"
        assert datos["ia"]["modelo"] == _MODELO_FOUNDRY

    def test_validacion_reciente_solo_tras_un_exito(self, asistente):
        assert asistente.validacion_reciente(_CONFIG_VALIDA) is False
        _respuesta_http(asistente, 401, {"error": {"message": "bad key"}})
        asistente.validar_conexion(_CONFIG_VALIDA)
        assert asistente.validacion_reciente(_CONFIG_VALIDA) is False, \
            "una validacion fallida no debe quedar registrada"
        _respuesta_http(asistente, 200, _respuesta_chat())
        asistente.validar_conexion(_CONFIG_VALIDA)
        assert asistente.validacion_reciente(_CONFIG_VALIDA) is True

    def test_validacion_reciente_distinge_configuraciones(self, asistente):
        _respuesta_http(asistente, 200, _respuesta_chat())
        asistente.validar_conexion(_CONFIG_VALIDA)
        assert asistente.validacion_reciente(dict(_CONFIG_VALIDA, modelo="otro")) is False
        assert asistente.validacion_reciente(dict(_CONFIG_VALIDA, api_key="otra")) is False

    def test_validacion_reciente_respeta_el_ttl(self, asistente):
        _respuesta_http(asistente, 200, _respuesta_chat())
        asistente.validar_conexion(_CONFIG_VALIDA)
        assert asistente.validacion_reciente(_CONFIG_VALIDA, ttl=0) is False


# ============================================================
# BLOQUE 6 — Persistencia del proyecto Child
# ============================================================

class _EstadoFalso:
    def __init__(self, servicio):
        self.servicio_fabrica = servicio


class _AppFalsa:
    def __init__(self, servicio):
        self.state = _EstadoFalso(servicio)


class _RequestFalso:
    """Request minimo para invocar los endpoints de fabrica sin servidor."""

    def __init__(self, servicio):
        self.app = _AppFalsa(servicio)


class TestPersistenciaProyectoChild:

    def test_crear_solicitud_con_ia_persiste_metadatos(self, db_temporal):
        svc = ServicioFabrica(ruta_db=db_temporal)
        s = svc.crear_solicitud("hermes-ia-01", app_service_plan_id=_ASP_VALIDO,
                                ia_config=dict(_CONFIG_VALIDA))
        assert s.ia_proveedor == "msfoundry"
        assert s.ia_url_base == _URL_FOUNDRY
        assert s.ia_modelo == _MODELO_FOUNDRY
        assert s.ia_configurada == "SI"
        assert s.ia_api_key_enmascarada.startswith("sk-c")
        assert len(s.ia_api_key_huella) == 64

        releida = svc.obtener_solicitud(s.deployment_id)
        assert releida is not None
        assert releida.ia_proveedor == "msfoundry"
        assert releida.ia_url_base == _URL_FOUNDRY
        assert releida.ia_modelo == _MODELO_FOUNDRY
        assert releida.ia_api_key_enmascarada == s.ia_api_key_enmascarada
        assert releida.ia_configurada == "SI"

    def test_a_dict_nunca_expone_la_api_key(self, db_temporal):
        svc = ServicioFabrica(ruta_db=db_temporal)
        s = svc.crear_solicitud("hermes-ia-02", app_service_plan_id=_ASP_VALIDO,
                                ia_config=dict(_CONFIG_VALIDA))
        datos = s.a_dict()
        assert _API_KEY not in repr(datos)
        assert datos["ia_api_key_enmascarada"].startswith("sk-c")
        assert datos["ia_proveedor"] == "msfoundry"

    def test_la_fila_de_la_solicitud_no_contiene_la_api_key(self, db_temporal):
        svc = ServicioFabrica(ruta_db=db_temporal)
        s = svc.crear_solicitud("hermes-ia-03", app_service_plan_id=_ASP_VALIDO,
                                ia_config=dict(_CONFIG_VALIDA))
        conn = sqlite3.connect(db_temporal)
        conn.row_factory = sqlite3.Row
        fila = conn.execute(
            "SELECT * FROM solicitudes_proyecto WHERE deployment_id = ?",
            (s.deployment_id,)).fetchone()
        conn.close()
        assert fila is not None
        assert _API_KEY not in "".join(str(v) for v in dict(fila).values())

    def test_la_credencial_vive_en_su_propia_tabla(self, db_temporal):
        svc = ServicioFabrica(ruta_db=db_temporal)
        s = svc.crear_solicitud("hermes-ia-04", app_service_plan_id=_ASP_VALIDO,
                                ia_config=dict(_CONFIG_VALIDA))
        credencial = svc.obtener_credencial_ia(s.deployment_id)
        assert credencial is not None
        assert credencial["api_key"] == _API_KEY
        assert credencial["api_key_enmascarada"].startswith("sk-c")
        assert credencial["api_key_huella"] == s.ia_api_key_huella
        assert svc.eliminar_credencial_ia(s.deployment_id) is True
        assert svc.obtener_credencial_ia(s.deployment_id) is None

    def test_obtener_credencial_inexistente_devuelve_none(self, db_temporal):
        svc = ServicioFabrica(ruta_db=db_temporal)
        assert svc.obtener_credencial_ia("NO-EXISTE") is None

    def test_el_evento_de_solicitud_no_registra_la_api_key(self, db_temporal):
        svc = ServicioFabrica(ruta_db=db_temporal)
        s = svc.crear_solicitud("hermes-ia-05", app_service_plan_id=_ASP_VALIDO,
                                ia_config=dict(_CONFIG_VALIDA))
        eventos = svc.obtener_eventos(s.deployment_id)
        assert eventos, "debe registrarse el evento de solicitud"
        assert _API_KEY not in repr(eventos)
        detalle = str(eventos[0].get("detalle", ""))
        assert "ia_proveedor=msfoundry" in detalle
        assert f"ia_modelo={_MODELO_FOUNDRY}" in detalle
        assert s.ia_api_key_huella[:12] in detalle

    def test_listar_solicitudes_incluye_la_configuracion_ia_sin_secreto(self, db_temporal):
        svc = ServicioFabrica(ruta_db=db_temporal)
        svc.crear_solicitud("hermes-ia-06", app_service_plan_id=_ASP_VALIDO,
                            ia_config=dict(_CONFIG_VALIDA))
        solicitudes = svc.listar_solicitudes(limite=5)
        assert solicitudes
        assert _API_KEY not in repr([x.a_dict() for x in solicitudes])
        assert solicitudes[0].ia_configurada == "SI"

    def test_normaliza_la_url_base_al_persistir(self, db_temporal):
        svc = ServicioFabrica(ruta_db=db_temporal)
        s = svc.crear_solicitud(
            "hermes-ia-07", app_service_plan_id=_ASP_VALIDO,
            ia_config=dict(_CONFIG_VALIDA, url_base=_URL_FOUNDRY + "/"))
        assert s.ia_url_base == _URL_FOUNDRY

    def test_no_se_crea_credencial_sin_configuracion_ia(self, db_temporal):
        svc = ServicioFabrica(ruta_db=db_temporal)
        s = svc.crear_solicitud("hermes-sin-ia", app_service_plan_id=_ASP_VALIDO)
        assert s.ia_configurada == "NO"
        assert s.ia_proveedor == ""
        assert svc.obtener_credencial_ia(s.deployment_id) is None


# ============================================================
# BLOQUE 7 — Flujo completo de creacion via API (con auditoria)
# ============================================================

class TestFlujoCreacionConAsistente:

    @pytest.fixture
    def asistente_auditor(self, monkeypatch):
        a = AsistenteIA()
        a._httpx = MagicMock()
        a._httpx_disponible = True
        monkeypatch.setattr(
            "Hermes.Web.api.api_fabrica.obtener_asistente_ia", lambda: a)
        return a

    def test_creacion_sin_validacion_previa_marca_no_verificado(
            self, db_temporal, asistente_auditor):
        svc = ServicioFabrica(ruta_db=db_temporal)
        respuesta = _async(crear_proyecto(
            _RequestFalso(svc),
            SolicitudCrear(nombre_proyecto="hermes-audit-01",
                           app_service_plan_id=_ASP_VALIDO,
                           ia=ConfiguracionIA(**_CONFIG_VALIDA))))
        solicitud = svc.obtener_solicitud(respuesta.deployment_id)
        assert solicitud.ia_configurada == "SI"
        assert solicitud.ia_validado == "NO_VERIFICADO"
        assert solicitud.ia_validado_en == ""

    def test_creacion_tras_validacion_exitosa_marca_conectado(
            self, db_temporal, asistente_auditor):
        svc = ServicioFabrica(ruta_db=db_temporal)
        _respuesta_http(asistente_auditor, 200, _respuesta_chat("pong"))
        asistente_auditor.validar_conexion(dict(_CONFIG_VALIDA))
        respuesta = _async(crear_proyecto(
            _RequestFalso(svc),
            SolicitudCrear(nombre_proyecto="hermes-audit-02",
                           app_service_plan_id=_ASP_VALIDO,
                           ia=ConfiguracionIA(**_CONFIG_VALIDA))))
        solicitud = svc.obtener_solicitud(respuesta.deployment_id)
        assert solicitud.ia_validado == "CONECTADO"
        assert solicitud.ia_validado_en != ""
        assert "Asistente IA" in solicitud.ia_validacion_detalle

    def test_creacion_sin_ia_sigue_funcionando(self, db_temporal, asistente_auditor):
        """Regresion: el flujo historico de creacion no se altera."""
        svc = ServicioFabrica(ruta_db=db_temporal)
        respuesta = _async(crear_proyecto(
            _RequestFalso(svc),
            SolicitudCrear(nombre_proyecto="hermes-sin-ia-02",
                           app_service_plan_id=_ASP_VALIDO)))
        assert respuesta.estado == "SOLICITADO"
        solicitud = svc.obtener_solicitud(respuesta.deployment_id)
        assert solicitud.ia_configurada == "NO"
        assert solicitud.ia_proveedor == ""
        assert svc.obtener_credencial_ia(respuesta.deployment_id) is None

    def test_la_credencial_del_proyecto_es_recuperable_para_el_factory(
            self, db_temporal, asistente_auditor):
        """El Factory puede leer la credencial para inyectarla en el Child."""
        svc = ServicioFabrica(ruta_db=db_temporal)
        respuesta = _async(crear_proyecto(
            _RequestFalso(svc),
            SolicitudCrear(nombre_proyecto="hermes-audit-04",
                           app_service_plan_id=_ASP_VALIDO,
                           ia=ConfiguracionIA(**_CONFIG_VALIDA))))
        credencial = svc.obtener_credencial_ia(respuesta.deployment_id)
        assert credencial["proveedor"] == "msfoundry"
        assert credencial["url_base"] == _URL_FOUNDRY
        assert credencial["modelo"] == _MODELO_FOUNDRY
        assert credencial["api_key"] == _API_KEY