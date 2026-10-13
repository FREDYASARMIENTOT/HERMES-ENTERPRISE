# -*- coding: utf-8 -*-
"""
====================================================================
servicio_asistente_ia.py — Asistente IA de configuracion de modelos
====================================================================

Responsabilidades:
    1. Guiar conversacionalmente (chatbot) la captura de la
       configuracion de IA de un proyecto Child:
           - proveedor de modelo
           - url base
           - api key
           - modelo (deployment)
    2. Validar la conexion REAL contra el proveedor (llamada HTTP
       minima de chat completions) antes de aceptar la configuracion.
    3. Enmascarar/huellizar la api key para que nunca quede expuesta
       en respuestas HTTP ni en logs.

Proveedores soportados (catalogo):
    - msfoundry     Microsoft Foundry / Azure AI Foundry
    - azure-openai  Azure OpenAI Service (API v1)
    - openai        OpenAI
    - openrouter    OpenRouter
    - ollama        Ollama local
    - custom        Cualquier endpoint compatible con OpenAI

Cassette de red para pruebas:
    El servicio expone self._httpx y self._httpx_disponible siguiendo el
    mismo patron que ServicioAzure, de modo que las pruebas inyectan un
    mock sin tocar la red.

Seguridad:
    - La api key NUNCA se registra en logs (solo enmascarada).
    - La api key NUNCA se devuelve en respuestas del servicio.
    - Sin secretos en codigo: el bootstrap del asistente se lee de
      variables de entorno (HERMES_ASISTENTE_*).
====================================================================
"""

import os
import re
import time
import hashlib
import logging
from typing import Optional, Dict, Any, List, Tuple
from urllib.parse import urlparse

logger = logging.getLogger("Hermes.Web.ServicioAsistenteIA")

# ──────────────────────────────────────────────────────────────
# Catalogo de proveedores
# ──────────────────────────────────────────────────────────────

# auth_estilo:
#   "api-key"  -> header  api-key: <key>          (Azure Foundry / Azure OpenAI)
#   "bearer"   -> header  Authorization: Bearer <key>
#   "ninguna"  -> sin credencial (Ollama local)
CATALOGO_PROVEEDORES: List[Dict[str, Any]] = [
    {
        "id": "msfoundry",
        "nombre": "Microsoft Foundry (Azure AI Foundry)",
        "url_base_sugerida": "https://<recurso>.services.ai.azure.com/models",
        "auth_estilo": "api-key",
        "requiere_api_key": True,
        "plantilla_modelo": "<nombre-del-deployment>",
        "notas": (
            "Inference API de Foundry. El campo modelo es el nombre del "
            "deployment (ej: Proyecto-ia-ur). Endpoint de chat: "
            "<url_base>/chat/completions"
        ),
    },
    {
        "id": "azure-openai",
        "nombre": "Azure OpenAI Service (API v1)",
        "url_base_sugerida": "https://<recurso>.openai.azure.com/openai/v1",
        "auth_estilo": "api-key",
        "requiere_api_key": True,
        "plantilla_modelo": "<nombre-del-deployment>",
        "notas": "Endpoint de chat: <url_base>/chat/completions",
    },
    {
        "id": "openai",
        "nombre": "OpenAI",
        "url_base_sugerida": "https://api.openai.com/v1",
        "auth_estilo": "bearer",
        "requiere_api_key": True,
        "plantilla_modelo": "gpt-4o-mini",
        "notas": "Endpoint de chat: <url_base>/chat/completions",
    },
    {
        "id": "openrouter",
        "nombre": "OpenRouter",
        "url_base_sugerida": "https://openrouter.ai/api/v1",
        "auth_estilo": "bearer",
        "requiere_api_key": True,
        "plantilla_modelo": "deepseek/deepseek-chat",
        "notas": "Endpoint de chat: <url_base>/chat/completions",
    },
    {
        "id": "ollama",
        "nombre": "Ollama (local)",
        "url_base_sugerida": "http://localhost:11434/v1",
        "auth_estilo": "ninguna",
        "requiere_api_key": False,
        "plantilla_modelo": "llama3.1",
        "notas": "No requiere api key. Endpoint: <url_base>/chat/completions",
    },
    {
        "id": "custom",
        "nombre": "Compatible con OpenAI (personalizado)",
        "url_base_sugerida": "https://<host>/v1",
        "auth_estilo": "bearer",
        "requiere_api_key": True,
        "plantilla_modelo": "<nombre-del-modelo>",
        "notas": "Cualquier gateway que implemente POST /chat/completions",
    },
]

PROVEEDORES_POR_ID: Dict[str, Dict[str, Any]] = {p["id"]: p for p in CATALOGO_PROVEEDORES}

PROVEEDOR_POR_DEFECTO = "msfoundry"

# Orden obligatorio de captura de la conversacion
CAMPOS_OBLIGATORIOS: List[str] = ["proveedor", "url_base", "api_key", "modelo"]

ETIQUETAS_CAMPO: Dict[str, str] = {
    "proveedor": "Proveedor de modelo",
    "url_base": "URL base",
    "api_key": "API Key",
    "modelo": "Modelo / Deployment",
}

# ──────────────────────────────────────────────────────────────
# Utilidades puras
# ──────────────────────────────────────────────────────────────

def normalizar_url_base(url_base: str) -> str:
    """
    Normaliza una url base: recorta espacios, elimina barras finales y
    agrega el esquema https:// cuando el usuario lo omite.
    """
    if not url_base:
        return ""
    valor = str(url_base).strip().strip('"').strip("'")
    while valor.endswith("/"):
        valor = valor[:-1]
    if not valor:
        return ""
    if "://" not in valor:
        host = valor.split("/")[0].lower()
        esquema = "http" if host.startswith(("localhost", "127.0.0.1", "0.0.0.0")) else "https"
        valor = f"{esquema}://{valor}"
    return valor


def es_url_base_valida(url_base: str) -> bool:
    """
    Valida que la url base sea usable: esquema http/https, host presente y
    un host con dominio completo (o localhost). Evita aceptar cadenas
    sueltas que el usuario escribio por error ("no-es-url").
    """
    try:
        partes = urlparse(url_base)
    except Exception:
        return False
    if partes.scheme not in ("http", "https"):
        return False
    host = (partes.netloc or "").split("@")[-1].split(":")[0].strip().lower()
    if not host:
        return False
    if host in ("localhost",):
        return True
    return "." in host


def enmascarar_api_key(api_key: str) -> str:
    """
    Devuelve una representacion enmascarada de la api key.
    Nunca revela mas de 4 caracteres iniciales y 4 finales.
    """
    if not api_key:
        return ""
    valor = str(api_key).strip()
    if len(valor) <= 8:
        return "*" * len(valor)
    return f"{valor[:4]}{'*' * 6}{valor[-4:]}"


def huella_api_key(api_key: str) -> str:
    """
    Devuelve la huella SHA-256 de la api key. Permite verificar que una
    key es la misma sin almacenar el secreto en claro junto al proyecto.
    """
    if not api_key:
        return ""
    return hashlib.sha256(str(api_key).strip().encode("utf-8")).hexdigest()


def detectar_proveedor(texto: str) -> Optional[str]:
    """Detecta el id de proveedor a partir de texto libre del usuario."""
    if not texto:
        return None
    plano = str(texto).strip().lower()
    for proveedor_id, alias in ALIAS_PROVEEDOR:
        for a in alias:
            if a in plano:
                return proveedor_id
    return None


def extraer_url(texto: str) -> Optional[str]:
    """Extrae la primera url de un texto libre."""
    if not texto:
        return None
    for token in str(texto).split():
        limpio = token.strip().strip('"').strip("'").strip("<>").strip(",").strip(".")
        if limpio.startswith("http://") or limpio.startswith("https://"):
            return normalizar_url_base(limpio)
    return None


def resolver_endpoint_chat(url_base: str) -> str:
    """
    Resuelve el endpoint de chat completions a partir de la url base.

        .../chat/completions -> sin cambios
        .../models           -> .../models/chat/completions   (Foundry)
        .../v1               -> .../v1/chat/completions
        ...                  -> .../v1/chat/completions
    """
    base = normalizar_url_base(url_base)
    if not base:
        return ""
    if base.endswith("/chat/completions"):
        return base
    if base.endswith("/models"):
        return f"{base}/chat/completions"
    if base.endswith("/v1"):
        return f"{base}/chat/completions"
    return f"{base}/v1/chat/completions"


def construir_headers(proveedor: str, api_key: str) -> Dict[str, str]:
    """Construye los headers de autenticacion segun el proveedor."""
    headers = {"Content-Type": "application/json"}
    proveedor_id = (proveedor or PROVEEDOR_POR_DEFECTO).strip().lower()
    meta = PROVEEDORES_POR_ID.get(proveedor_id)
    estilo = meta["auth_estilo"] if meta else "api-key"
    clave = (api_key or "").strip()
    if not clave:
        return headers
    if estilo == "bearer":
        headers["Authorization"] = f"Bearer {clave}"
    elif estilo == "api-key":
        # Azure Foundry / Azure OpenAI aceptan el header api-key.
        headers["api-key"] = clave
        headers["Authorization"] = f"Bearer {clave}"
    return headers


# ──────────────────────────────────────────────────────────────
# Captura de valores desde lenguaje natural
# ──────────────────────────────────────────────────────────────

_ETIQUETA_A_CAMPO: Dict[str, str] = {
    "proveedor": "proveedor", "provider": "proveedor",
    "url": "url_base", "url_base": "url_base", "url base": "url_base",
    "urlbase": "url_base", "base_url": "url_base", "base url": "url_base",
    "endpoint": "url_base",
    "api_key": "api_key", "api key": "api_key", "apikey": "api_key",
    "key": "api_key", "clave": "api_key",
    "modelo": "modelo", "model": "modelo",
    "deployment": "modelo", "deployment_name": "modelo", "deployment name": "modelo",
}

# La etiqueta debe iniciar palabra (ni letra, ni digito, ni '_' o '/' antes):
# esto evita confundir la ruta ".../models" de una URL con la etiqueta "model".
_PATRON_ETIQUETA = re.compile(
    r"(?<![A-Za-z0-9_/])"
    r"(proveedor|provider|url[_ ]?base|base[_ ]?url|urlbase|endpoint|"
    r"api[_ ]?key|apikey|key|clave|modelo|model|deployment[_ ]?name|deployment)"
    r"\s*[:=]\s*",
    re.IGNORECASE,
)


def parsear_etiquetados(texto: str) -> Dict[str, str]:
    """
    Extrae pares 'etiqueta: valor' del mensaje del usuario. Permite que
    el usuario pegue la configuracion completa en un solo mensaje, por
    ejemplo:

        proveedor: msfoundry
        url_base: https://mi-recurso.services.ai.azure.com/models
        api_key: sk-xxxxxxxx
        modelo: Proyecto-ia-ur
    """
    resultado: Dict[str, str] = {}
    if not texto:
        return resultado
    coincidencias = list(_PATRON_ETIQUETA.finditer(texto))
    for indice, coincidencia in enumerate(coincidencias):
        etiqueta = coincidencia.group(1).strip().lower()
        campo = _ETIQUETA_A_CAMPO.get(etiqueta)
        if campo is None:
            campo = _ETIQUETA_A_CAMPO.get(etiqueta.replace(" ", "_"))
        if campo is None:
            continue
        inicio = coincidencia.end()
        fin = coincidencias[indice + 1].start() if indice + 1 < len(coincidencias) else len(texto)
        valor = texto[inicio:fin].strip().strip('"').strip("'").strip()
        valor = valor.strip(",").strip(";").strip()
        if not valor:
            continue
        if campo == "url_base":
            valor = extraer_url(valor) or normalizar_url_base(valor)
        elif campo == "proveedor":
            valor = detectar_proveedor(valor) or valor
        if valor:
            resultado[campo] = valor
    return resultado


def capturar_campo(campo: str, texto: str) -> Optional[str]:
    """
    Interpreta un mensaje libre como valor del campo indicado.
    Devuelve None cuando el mensaje no aporta un valor util.
    """
    valor = (texto or "").strip()
    if not valor or not campo:
        return None

    if campo == "proveedor":
        return detectar_proveedor(valor)

    if campo == "url_base":
        extraida = extraer_url(valor)
        if extraida:
            return extraida
        # Aceptar host sin esquema: "mi-recurso.services.ai.azure.com/models"
        for token in valor.split():
            limpio = token.strip().strip('"').strip("'").strip("<>").strip(",")
            if "." in limpio and not limpio.startswith(("sk-", "Bearer")):
                return normalizar_url_base(limpio)
        return None

    if campo == "api_key":
        limpio = valor
        if limpio.lower().startswith("bearer "):
            limpio = limpio[7:].strip()
        partes = [p for p in limpio.split() if p]
        if not partes:
            return None
        # La api key no contiene espacios: si el usuario escribio una
        # frase, el token mas largo suele ser la clave.
        return max(partes, key=len).strip('"').strip("'")

    if campo == "modelo":
        # El modelo/deployment es el texto restante, sin etiquetas ni comillas.
        primera_linea = valor.splitlines()[0].strip()
        return primera_linea.strip('"').strip("'").strip() or None

    return None


# ──────────────────────────────────────────────────────────────
# Clasificacion de respuestas HTTP del proveedor
# ──────────────────────────────────────────────────────────────

_MAPA_ESTADO_HTTP: Dict[int, str] = {
    400: "ERROR_SOLICITUD_INVALIDA",
    401: "ERROR_AUTENTICACION",
    403: "ERROR_PERMISOS",
    404: "ERROR_MODELO_NO_ENCONTRADO",
    408: "ERROR_TIMEOUT",
    413: "ERROR_SOLICITUD_INVALIDA",
    422: "ERROR_SOLICITUD_INVALIDA",
    429: "ERROR_CUOTA",
}

_MAPA_ESTADO_HTTP_5XX = "ERROR_PROVEEDOR"


def clasificar_http(status_code: int) -> str:
    """Traduce un codigo HTTP del proveedor a un estado semantico."""
    if status_code == 200:
        return "CONECTADO"
    if status_code in _MAPA_ESTADO_HTTP:
        return _MAPA_ESTADO_HTTP[status_code]
    if 500 <= status_code <= 599:
        return _MAPA_ESTADO_HTTP_5XX
    return "ERROR_PROVEEDOR"


def extraer_detalle_error(payload: Any, texto_plano: str = "") -> str:
    """
    Extrae, sin lanzar excepciones, el motivo real devuelto por el
    proveedor. Es la pieza que evita el mensaje generico e inutil:
    prioriza error.message / detail / reason del JSON recibido.
    """
    if isinstance(payload, dict):
        for clave in ("message", "reason", "detail", "error_description"):
            valor = payload.get(clave)
            if isinstance(valor, str) and valor.strip():
                return valor.strip()
        err = payload.get("error")
        if isinstance(err, dict):
            for clave in ("message", "code", "reason", "detail"):
                valor = err.get(clave)
                if isinstance(valor, str) and valor.strip():
                    return valor.strip()
        if isinstance(err, str) and err.strip():
            return err.strip()
    if isinstance(texto_plano, str) and texto_plano.strip():
        return texto_plano.strip()[:600]
    return ""


def extraer_contenido_respuesta(payload: Any) -> str:
    """
    Extrae el contenido textual de una respuesta de chat completions.
    Soporta el formato OpenAI (choices[0].message.content) y variantes
    con 'output_text' o 'content' plano.
    """
    if not isinstance(payload, dict):
        return ""
    try:
        elecciones = payload.get("choices")
        if isinstance(elecciones, list) and elecciones:
            primera = elecciones[0] or {}
            mensaje = primera.get("message")
            if isinstance(mensaje, dict):
                contenido = mensaje.get("content")
                if isinstance(contenido, str):
                    return contenido.strip()
            texto = primera.get("text")
            if isinstance(texto, str):
                return texto.strip()
        for clave in ("output_text", "content", "response"):
            valor = payload.get(clave)
            if isinstance(valor, str) and valor.strip():
                return valor.strip()
    except Exception:
        return ""
    return ""


# Alias aceptados para detectar el proveedor en lenguaje natural.
# El orden importa: la primera coincidencia gana.
ALIAS_PROVEEDOR: List[Tuple[str, List[str]]] = [
    ("msfoundry", [
        "msfoundry", "ms foundry", "microsoft foundry", "azure ai foundry",
        "foundry", "services.ai.azure.com", "ai.azure.com",
    ]),
    ("azure-openai", [
        "azure openai", "azure-openai", "azureopenai", "openai.azure.com",
    ]),
    ("openrouter", ["openrouter", "open router"]),
    ("ollama", ["ollama"]),
    ("openai", ["openai", "api.openai.com"]),
    ("custom", ["custom", "personalizado", "compatible", "gateway", "otro"]),
]

# Timeout de la validacion de conexion (segundos)
TIMEOUT_VALIDACION = 20.0

# Timeout del redactado asistido por LLM (segundos)
TIMEOUT_REDACCION_LLM = 12.0

# Ventana durante la cual una validacion exitosa sigue siendo valida.
# Permite que la creacion del proyecto Child compruebe, server-side, que
# la credencial fue realmente validada (y no solo declarada por el cliente).
VALIDACION_TTL_SEGUNDOS = 900

# Prompt de sistema del redactado asistido (opcional).
SISTEMA_REDACCION = (
    "Eres el Asistente IA de configuracion de la Fabrica de Proyectos de la "
    "Universidad del Rosario. Hablas en espanol neutro, breve y profesional. "
    "Tu unico objetivo es guiar al usuario a proporcionar cuatro datos del "
    "modelo de IA de un proyecto nuevo: proveedor, url base, api key y modelo. "
    "REGLAS ESTRICTAS: (1) nunca inventes ni modifiques valores tecnicos; "
    "(2) nunca repitas una api key, solo mencionala como enmascarada; "
    "(3) no agregues pasos que no esten indicados en 'Siguiente paso obligatorio'; "
    "(4) responde en 2 a 5 lineas."
)


# ──────────────────────────────────────────────────────────────
# Helpers de borrador
# ──────────────────────────────────────────────────────────────

def campo_faltante(borrador: Dict[str, Any]) -> Optional[str]:
    """Devuelve el primer campo obligatorio aun no capturado."""
    for campo in CAMPOS_OBLIGATORIOS:
        if not str((borrador or {}).get(campo, "") or "").strip():
            return campo
    return None


def resumen_borrador(borrador: Dict[str, Any]) -> Dict[str, Any]:
    """
    Devuelve el borrador listo para UI: la api key siempre enmascarada y
    se marca que campos faltan.
    """
    datos = borrador or {}
    faltantes = [c for c in CAMPOS_OBLIGATORIOS
                 if not str(datos.get(c, "") or "").strip()]
    return {
        "proveedor": str(datos.get("proveedor", "") or ""),
        "url_base": normalizar_url_base(str(datos.get("url_base", "") or "")),
        "api_key": "",
        "api_key_enmascarada": enmascarar_api_key(str(datos.get("api_key", "") or "")),
        "api_key_presente": bool(str(datos.get("api_key", "") or "").strip()),
        "modelo": str(datos.get("modelo", "") or ""),
        "campos_faltantes": faltantes,
        "campo_actual": faltantes[0] if faltantes else "",
        "completado": not faltantes,
    }


class AsistenteIA:
    """
    Asistente conversacional de configuracion de modelos IA.

    Responsabilidades:
        - Mantener la maquina de estados de captura de los 4 campos.
        - Redactar las preguntas y validar los valores capturados.
        - Validar la conexion real contra el proveedor (validar_conexion).
    """

    def __init__(self):
        self._httpx = None
        self._httpx_disponible = False
        # Cache en memoria de validaciones exitosas: {clave: timestamp}
        self._validaciones: Dict[str, float] = {}
        try:
            import httpx
            self._httpx = httpx
            self._httpx_disponible = True
        except ImportError:
            logger.error("httpx no instalado — validacion de IA deshabilitada")

    # ─── Bootstrap del LLM interno del asistente ───

    def configuracion_llm_interna(self) -> Dict[str, Any]:
        """
        Lee el bootstrap del LLM que redacta las respuestas del asistente
        desde variables de entorno. Nunca contiene secretos en codigo.
        """
        url_base = normalizar_url_base(os.environ.get("HERMES_ASISTENTE_URL_BASE", ""))
        api_key = os.environ.get("HERMES_ASISTENTE_API_KEY", "").strip()
        modelo = os.environ.get("HERMES_ASISTENTE_MODELO", "").strip()
        proveedor = (os.environ.get("HERMES_ASISTENTE_PROVEEDOR", "")
                     or PROVEEDOR_POR_DEFECTO).strip().lower()
        return {
            "configurado": bool(url_base and modelo and (api_key or proveedor == "ollama")),
            "proveedor": proveedor,
            "url_base": url_base,
            "modelo": modelo,
            "api_key_presente": bool(api_key),
            "api_key_enmascarada": enmascarar_api_key(api_key),
        }

    def estado(self) -> Dict[str, Any]:
        """Estado publico del asistente (apto para endpoint /estado)."""
        llm = self.configuracion_llm_interna()
        return {
            "servicio": "asistente-ia",
            "httpx_disponible": self._httpx_disponible,
            "proveedor_por_defecto": PROVEEDOR_POR_DEFECTO,
            "campos_obligatorios": list(CAMPOS_OBLIGATORIOS),
            "proveedores_disponibles": len(CATALOGO_PROVEEDORES),
            "llm_interna": llm,
            "redaccion_llm_disponible": bool(llm["configurado"] and self._httpx_disponible),
            "validaciones_en_cache": len(self._validaciones),
            "validacion_ttl_segundos": VALIDACION_TTL_SEGUNDOS,
        }

    # ─── Validacion real de la conexion ───

    def validar_conexion(
        self,
        config: Dict[str, Any],
        timeout: float = TIMEOUT_VALIDACION,
    ) -> Dict[str, Any]:
        """
        Valida la configuracion IA realizando una llamada REAL de chat
        completions con el payload minimo posible:

            {"model": <modelo>, "messages": [{"role": "user", ...}]}

        Se omite deliberadamente temperatura y max_tokens: algunos
        modelos desplegados (ej. DeepSeek) rechazan parametros no
        soportados y devolverian un error enganoso.

        Devuelve un dict serializable. Nunca incluye la api key en claro.
        """
        datos = config or {}
        proveedor = str(datos.get("proveedor", "") or PROVEEDOR_POR_DEFECTO).strip().lower()
        url_base = normalizar_url_base(str(datos.get("url_base", "") or ""))
        api_key = str(datos.get("api_key", "") or "").strip()
        modelo = str(datos.get("modelo", "") or "").strip()

        resultado: Dict[str, Any] = {
            "ok": False,
            "estado": "NO_VERIFICADO",
            "proveedor": proveedor,
            "url_base": url_base,
            "endpoint": "",
            "modelo": modelo,
            "api_key_enmascarada": enmascarar_api_key(api_key),
            "api_key_huella": huella_api_key(api_key),
            "http_status": None,
            "latencia_ms": 0,
            "respuesta_modelo": "",
            "error": "",
            "detalle": "",
        }

        meta = PROVEEDORES_POR_ID.get(proveedor)
        if meta is None:
            resultado["estado"] = "ERROR_PROVEEDOR_DESCONOCIDO"
            resultado["error"] = f"Proveedor no soportado: '{proveedor}'"
            resultado["detalle"] = "Proveedores validos: " + ", ".join(PROVEEDORES_POR_ID.keys())
            return resultado
        if not es_url_base_valida(url_base):
            resultado["estado"] = "ERROR_URL_INVALIDA"
            resultado["error"] = f"URL base invalida: '{url_base}'"
            resultado["detalle"] = "Debe iniciar con http:// o https:// y tener un host."
            return resultado
        if not modelo:
            resultado["estado"] = "ERROR_SIN_MODELO"
            resultado["error"] = "El modelo/deployment es obligatorio"
            return resultado
        if meta["requiere_api_key"] and not api_key:
            resultado["estado"] = "ERROR_SIN_API_KEY"
            resultado["error"] = "El proveedor requiere api key"
            resultado["detalle"] = meta["notas"]
            return resultado
        if not self._httpx_disponible:
            resultado["estado"] = "ERROR_LIBRERIA"
            resultado["error"] = "httpx no disponible en el runtime"
            return resultado

        endpoint = resolver_endpoint_chat(url_base)
        resultado["endpoint"] = endpoint

        headers = construir_headers(proveedor, api_key)
        cuerpo = {
            "model": modelo,
            "messages": [{"role": "user", "content": "ping"}],
        }

        inicio = time.time()
        try:
            respuesta = self._httpx.post(
                endpoint, headers=headers, json=cuerpo, timeout=timeout
            )
        except Exception as e:
            resultado["latencia_ms"] = int((time.time() - inicio) * 1000)
            nombre_exc = type(e).__name__
            if "Timeout" in nombre_exc:
                resultado["estado"] = "ERROR_TIMEOUT"
                resultado["error"] = f"Timeout tras {timeout}s sin respuesta del proveedor"
            else:
                resultado["estado"] = "ERROR_CONEXION"
                resultado["error"] = f"Fallo de conexion: {nombre_exc}"
            resultado["detalle"] = str(e)[:600]
            logger.warning(
                "Validacion IA fallo (%s) proveedor=%s modelo=%s",
                resultado["estado"], proveedor, modelo,
            )
            return resultado

        resultado["latencia_ms"] = int((time.time() - inicio) * 1000)
        status = getattr(respuesta, "status_code", None)
        resultado["http_status"] = status

        payload: Any = None
        try:
            payload = respuesta.json()
        except Exception:
            payload = None
        try:
            texto_plano = getattr(respuesta, "text", "") or ""
        except Exception:
            texto_plano = ""

        resultado["estado"] = (
            clasificar_http(int(status)) if status is not None else "ERROR_CONEXION"
        )
        resultado["ok"] = resultado["estado"] == "CONECTADO"

        if resultado["ok"]:
            resultado["respuesta_modelo"] = extraer_contenido_respuesta(payload)[:300]
            self._registrar_validacion(resultado)
            logger.info(
                "Validacion IA OK proveedor=%s modelo=%s latencia=%sms",
                proveedor, modelo, resultado["latencia_ms"],
            )
            return resultado

        # Fallo: exponer SIEMPRE el motivo real devuelto por el proveedor.
        resultado["detalle"] = extraer_detalle_error(payload, texto_plano)[:600]
        resultado["error"] = self._mensaje_estado(resultado["estado"], resultado["detalle"])
        logger.warning(
            "Validacion IA %s proveedor=%s modelo=%s http=%s detalle=%s",
            resultado["estado"], proveedor, modelo, status,
            (resultado["detalle"] or "")[:200],
        )
        return resultado

    def _mensaje_estado(self, estado: str, detalle: str) -> str:
        """Mensaje accionable en espanol para cada estado de fallo."""
        base = {
            "ERROR_AUTENTICACION": "La api key fue rechazada (401). Verifique que sea la clave del recurso correcto.",
            "ERROR_PERMISOS": "La api key no tiene permisos para este recurso o modelo (403).",
            "ERROR_MODELO_NO_ENCONTRADO": "El modelo/deployment indicado no existe en el endpoint (404).",
            "ERROR_CUOTA": "Cuota o limite de tasa excedido (429). Reintente o revise la cuota.",
            "ERROR_SOLICITUD_INVALIDA": "El proveedor rechazo la solicitud (400/422).",
            "ERROR_PROVEEDOR": "El proveedor devolvio un error interno (5xx).",
            "ERROR_TIMEOUT": "Timeout esperando al proveedor.",
            "ERROR_CONEXION": "Fallo de conexion con el proveedor.",
        }.get(estado, "La validacion de la configuracion IA fallo.")
        if detalle:
            return f"{base} Detalle del proveedor: {detalle}"
        return base

    # ─── Registro server-side de validaciones ───

    @staticmethod
    def _clave_validacion(config: Dict[str, Any]) -> str:
        """
        Construye la clave de una configuracion validada. Incluye la huella
        de la api key (nunca la clave en claro).
        """
        datos = config or {}
        api_key = str(datos.get("api_key", "") or "").strip()
        url = normalizar_url_base(str(datos.get("url_base", "") or ""))
        return "|".join([
            str(datos.get("proveedor", "") or "").strip().lower(),
            resolver_endpoint_chat(url),
            str(datos.get("modelo", "") or "").strip(),
            huella_api_key(api_key),
        ])

    def _registrar_validacion(self, resultado: Dict[str, Any]) -> None:
        """Registra una validacion exitosa en la cache en memoria."""
        clave = "|".join([
            str(resultado.get("proveedor", "") or ""),
            str(resultado.get("endpoint", "") or ""),
            str(resultado.get("modelo", "") or ""),
            str(resultado.get("api_key_huella", "") or ""),
        ])
        self._validaciones[clave] = time.time()
        # Poda oportunista para evitar crecimiento indefinido
        if len(self._validaciones) > 512:
            limite = time.time() - VALIDACION_TTL_SEGUNDOS
            self._validaciones = {k: v for k, v in self._validaciones.items() if v >= limite}

    def validacion_reciente(
        self,
        config: Dict[str, Any],
        ttl: Optional[float] = None,
    ) -> bool:
        """
        Indica si esta configuracion exacta fue validada con exito hace
        menos de 'ttl' segundos. Permite auditar, server-side, que la
        credencial de un proyecto Child fue realmente probada.
        """
        ventana = VALIDACION_TTL_SEGUNDOS if ttl is None else ttl
        momento = self._validaciones.get(self._clave_validacion(config))
        if not momento:
            return False
        return (time.time() - momento) <= ventana

    def limpiar_validaciones(self) -> None:
        """Vacia la cache de validaciones (uso en pruebas y mantenimiento)."""
        self._validaciones.clear()

    # ─── Conversacion (chatbot) ───

    def _saludo(self) -> str:
        return (
            "Hola, soy el Asistente IA de Hermes. Le ayudare a configurar el "
            "modelo de lenguaje del nuevo proyecto Child y a verificar la "
            "credencial antes de crearlo."
        )

    def _pregunta(self, campo: str) -> str:
        """Devuelve la pregunta en espanol para el campo indicado."""
        if not campo:
            return "La configuracion ya esta completa."
        if campo == "proveedor":
            listado = "\n".join(
                f"  - {p['id']}: {p['nombre']}" for p in CATALOGO_PROVEEDORES
            )
            return (
                "Paso 1/4 - ¿Que proveedor de modelo desea usar?\n"
                f"{listado}\n"
                f"(puede escribir el nombre o el id; por defecto: {PROVEEDOR_POR_DEFECTO})"
            )
        if campo == "url_base":
            return (
                "Paso 2/4 - ¿Cual es la URL base del endpoint?\n"
                "Ejemplo Microsoft Foundry: "
                "https://mi-recurso.services.ai.azure.com/models"
            )
        if campo == "api_key":
            return (
                "Paso 3/4 - ¿Cual es la API Key?\n"
                "Se mostrara enmascarada, nunca se registra en logs y nunca se "
                "devuelve al navegador."
            )
        return (
            "Paso 4/4 - ¿Cual es el modelo o nombre del deployment?\n"
            "Ejemplo MS Foundry: Proyecto-ia-ur"
        )

    def _resumen_final(self, borrador: Dict[str, Any]) -> str:
        return (
            "Configuracion completa. Resumen:\n"
            f"  - Proveedor: {borrador.get('proveedor', '')}\n"
            f"  - URL base: {normalizar_url_base(str(borrador.get('url_base', '') or ''))}\n"
            f"  - Modelo / deployment: {borrador.get('modelo', '')}\n"
            f"  - API Key: {enmascarar_api_key(str(borrador.get('api_key', '') or ''))}\n\n"
            "Pulse 'Validar conexion' para comprobar la credencial contra el "
            "proveedor antes de crear el proyecto."
        )

    def _respuesta(
        self,
        borrador: Dict[str, Any],
        respuesta: str,
        tipo: str,
        campo_actual: Optional[str],
        capturados: List[str],
        avisos: List[str],
        reiniciado: bool = False,
        llm_usado: bool = False,
    ) -> Dict[str, Any]:
        """Empaqueta el resultado de un turno de conversacion."""
        resumen = resumen_borrador(borrador)
        return {
            "respuesta": respuesta,
            "mensaje_tipo": tipo,
            "borrador": resumen,
            "campos_capturados": list(capturados),
            "avisos": list(avisos),
            "campo_actual": campo_actual or "",
            "campo_actual_etiqueta": ETIQUETAS_CAMPO.get(campo_actual or "", ""),
            "completado": resumen["completado"],
            "listo_para_validar": resumen["completado"],
            "reiniciado": reiniciado,
            "llm_usado": llm_usado,
        }

    def responder(
        self,
        mensaje: str = "",
        borrador: Optional[Dict[str, Any]] = None,
        historial: Optional[List[Dict[str, Any]]] = None,
        usar_llm: bool = False,
    ) -> Dict[str, Any]:
        """
        Procesa un turno de conversacion del chatbot.

        Es una funcion pura respecto de la red: la maquina de estados es
        determinista y testeable. Solo consulta al LLM interno cuando
        usar_llm=True y el asistente esta bootstrapeado por entorno.
        """
        actual: Dict[str, Any] = {c: str((borrador or {}).get(c, "") or "")
                                  for c in CAMPOS_OBLIGATORIOS}
        texto = (mensaje or "").strip()
        capturados: List[str] = []
        avisos: List[str] = []
        reiniciado = False
        tipo = "pregunta"
        llm_usado = False

        minuscula = texto.lower()
        if minuscula in ("cancelar", "salir"):
            return self._respuesta(
                {}, "Conversacion cancelada. No se guardo ninguna configuracion.",
                "info", "proveedor", [], [], reiniciado=True,
            )
        if minuscula in ("reiniciar", "reset", "limpiar", "empezar de nuevo"):
            actual = {c: "" for c in CAMPOS_OBLIGATORIOS}
            reiniciado = True
            avisos.append("Configuracion reiniciada.")
            texto = ""

        if texto:
            etiquetados = parsear_etiquetados(texto)
            nuevos: Dict[str, str] = dict(etiquetados)
            if not etiquetados:
                campo_esperado = campo_faltante(actual) or "modelo"
                valor = capturar_campo(campo_esperado, texto)
                if valor:
                    nuevos[campo_esperado] = valor
                else:
                    avisos.append(
                        f"No pude interpretar un valor valido para "
                        f"'{ETIQUETAS_CAMPO.get(campo_esperado, campo_esperado)}'."
                    )
            for campo, valor in nuevos.items():
                valor = str(valor or "").strip()
                if not valor:
                    continue
                if campo == "url_base":
                    valor = normalizar_url_base(valor)
                    if not es_url_base_valida(valor):
                        avisos.append(f"La URL base '{valor}' no es valida.")
                        continue
                actual[campo] = valor
                capturados.append(campo)

        faltante = campo_faltante(actual)
        primer_turno = not historial and not texto and not capturados

        if faltante is None:
            texto_respuesta = self._resumen_final(actual)
            tipo = "completado"
        elif primer_turno:
            texto_respuesta = f"{self._saludo()}\n\n{self._pregunta(faltante)}"
        elif avisos:
            tipo = "aviso"
            texto_respuesta = " ".join(avisos) + "\n\n" + self._pregunta(faltante)
        else:
            etiquetas = ", ".join(ETIQUETAS_CAMPO.get(c, c) for c in capturados)
            confirmacion = f"Capturado: {etiquetas}." if etiquetas else ""
            texto_respuesta = (confirmacion + "\n\n" + self._pregunta(faltante)).strip()

        if usar_llm and texto:
            redactado = self._redactar_con_llm(texto_respuesta, historial, texto)
            if redactado:
                texto_respuesta = redactado
                llm_usado = True

        return self._respuesta(
            actual, texto_respuesta, tipo, faltante, capturados, avisos,
            reiniciado=reiniciado, llm_usado=llm_usado,
        )

    def _redactar_con_llm(
        self,
        instruccion: str,
        historial: Optional[List[Dict[str, Any]]],
        texto_usuario: str,
    ) -> Optional[str]:
        """
        Reformula el siguiente paso de la conversacion con el LLM interno
        del asistente. Es estrictamente opcional: ante cualquier fallo se
        devuelve None y se conserva el texto deterministico.
        """
        llm = self.configuracion_llm_interna()
        if not llm["configurado"] or not self._httpx_disponible:
            return None
        endpoint = resolver_endpoint_chat(llm["url_base"])
        api_key = os.environ.get("HERMES_ASISTENTE_API_KEY", "")
        headers = construir_headers(llm["proveedor"], api_key)

        mensajes: List[Dict[str, str]] = [
            {"role": "system", "content": SISTEMA_REDACCION},
            {"role": "system", "content": f"Siguiente paso obligatorio: {instruccion[:700]}"},
        ]
        for m in (historial or [])[-8:]:
            if not isinstance(m, dict):
                continue
            rol = str(m.get("rol") or m.get("role") or "user").lower()
            contenido = str(m.get("contenido") or m.get("content") or "").strip()
            if not contenido:
                continue
            mensajes.append({
                "role": "assistant" if rol in ("assistant", "asistente") else "user",
                "content": contenido[:1500],
            })
        mensajes.append({"role": "user", "content": texto_usuario[:1500]})

        try:
            respuesta = self._httpx.post(
                endpoint, headers=headers,
                json={"model": llm["modelo"], "messages": mensajes},
                timeout=TIMEOUT_REDACCION_LLM,
            )
            if getattr(respuesta, "status_code", None) != 200:
                return None
            contenido = extraer_contenido_respuesta(respuesta.json()).strip()
            return contenido[:900] or None
        except Exception as e:
            logger.warning("Redaccion LLM del asistente fallo: %s", type(e).__name__)
            return None


# ──────────────────────────────────────────────────────────────
# Singleton
# ──────────────────────────────────────────────────────────────

_asistente_ia_singleton: Optional[AsistenteIA] = None


def obtener_asistente_ia() -> AsistenteIA:
    """Devuelve la instancia unica del AsistenteIA (singleton lazy)."""
    global _asistente_ia_singleton
    if _asistente_ia_singleton is None:
        _asistente_ia_singleton = AsistenteIA()
        logger.info("AsistenteIA inicializado (httpx=%s)",
                    _asistente_ia_singleton._httpx_disponible)
    return _asistente_ia_singleton