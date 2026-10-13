# -*- coding: utf-8 -*-
"""
====================================================================
api_asistente.py — Router de /api/asistente para Hermes.Web
====================================================================

Asistente IA de configuracion del modelo de un proyecto Child.
Captura conversacionalmente proveedor, url base, api key y modelo, y
valida la credencial contra el proveedor antes de crear el proyecto.

Endpoints:
    GET  /api/asistente/proveedores -> Catalogo de proveedores soportados
    GET  /api/asistente/campos      -> Campos obligatorios y su orden
    GET  /api/asistente/estado      -> Salud del asistente (httpx, LLM interna)
    POST /api/asistente/chat        -> Un turno de conversacion
    POST /api/asistente/validar     -> Validacion REAL de la credencial

Seguridad:
    La api key viaja en el cuerpo del POST (misma sesion del navegador)
    pero NUNCA se devuelve en la respuesta: solo su version enmascarada
    y su huella SHA-256.
====================================================================
"""

import logging
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List

from Hermes.Web.backend.servicio_asistente_ia import (
    CATALOGO_PROVEEDORES,
    CAMPOS_OBLIGATORIOS,
    ETIQUETAS_CAMPO,
    PROVEEDOR_POR_DEFECTO,
    obtener_asistente_ia,
)

logger = logging.getLogger("Hermes.Web.API.Asistente")
router = APIRouter()

# ──────────────────────────────────────────────────────────────
# Modelos Pydantic
# ──────────────────────────────────────────────────────────────

class ConfiguracionIA(BaseModel):
    """Configuracion de IA capturada por el asistente para un proyecto Child."""
    proveedor: str = Field(PROVEEDOR_POR_DEFECTO,
                           description="id del proveedor del catalogo (ej: msfoundry)")
    url_base: str = Field("", description="URL base del endpoint del modelo")
    api_key: str = Field("", description="API key del proveedor (no se devuelve nunca)")
    modelo: str = Field("", description="Modelo o nombre del deployment")


class MensajeChat(BaseModel):
    """Mensaje de la conversacion del asistente."""
    rol: str = Field("user", description="user | assistant")
    contenido: str = Field("", description="Texto del mensaje")


class ChatRequest(BaseModel):
    """Un turno del chatbot de configuracion."""
    mensaje: str = Field("", description="Mensaje del usuario (vacio = saludo inicial)")
    borrador: Dict[str, Any] = Field(default_factory=dict,
                                     description="Borrador acumulado en el cliente")
    historial: List[MensajeChat] = Field(default_factory=list,
                                         description="Historial de la conversacion")
    usar_llm: bool = Field(False, description="Reformular la respuesta con el LLM interno")


class ChatResponse(BaseModel):
    """Respuesta de un turno del chatbot."""
    respuesta: str
    mensaje_tipo: str
    borrador: Dict[str, Any]
    campos_capturados: List[str]
    avisos: List[str]
    campo_actual: str
    campo_actual_etiqueta: str
    completado: bool
    listo_para_validar: bool
    reiniciado: bool
    llm_usado: bool


class ValidarResponse(BaseModel):
    """Resultado de la validacion real de la credencial."""
    ok: bool
    estado: str
    proveedor: str
    url_base: str
    endpoint: str
    modelo: str
    api_key_enmascarada: str
    api_key_huella: str
    http_status: Optional[int] = None
    latencia_ms: int = 0
    respuesta_modelo: str = ""
    error: str = ""
    detalle: str = ""


# ──────────────────────────────────────────────────────────────
# Endpoints
# ──────────────────────────────────────────────────────────────

@router.get("/asistente/proveedores", summary="Catalogo de proveedores de modelo")
async def listar_proveedores():
    """Devuelve los proveedores soportados por el asistente."""
    return {"total": len(CATALOGO_PROVEEDORES), "proveedores": CATALOGO_PROVEEDORES}


@router.get("/asistente/campos", summary="Campos obligatorios del asistente")
async def listar_campos():
    """Devuelve el orden de captura de los campos obligatorios."""
    return {
        "campos": [
            {"id": c, "etiqueta": ETIQUETAS_CAMPO.get(c, c)}
            for c in CAMPOS_OBLIGATORIOS
        ],
        "proveedor_por_defecto": PROVEEDOR_POR_DEFECTO,
    }


@router.get("/asistente/estado", summary="Salud del asistente IA")
async def estado_asistente():
    """Indica si httpx y el LLM interno del asistente estan disponibles."""
    try:
        return obtener_asistente_ia().estado()
    except Exception as e:
        logger.error(f"Error obteniendo estado del asistente: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


@router.post("/asistente/chat", summary="Turno de conversacion del asistente",
             response_model=ChatResponse)
async def chat_asistente(solicitud: ChatRequest):
    """Procesa un turno del chatbot de configuracion de IA."""
    try:
        asistente = obtener_asistente_ia()
        historial = [m.model_dump() for m in solicitud.historial]
        resultado = asistente.responder(
            mensaje=solicitud.mensaje,
            borrador=solicitud.borrador,
            historial=historial,
            usar_llm=solicitud.usar_llm,
        )
        return ChatResponse(**resultado)
    except Exception as e:
        logger.error(f"Error en chat del asistente: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


@router.post("/asistente/validar", summary="Validar credencial contra el proveedor",
             response_model=ValidarResponse)
async def validar_configuracion(config: ConfiguracionIA):
    """
    Valida la configuracion IA realizando una llamada real de chat
    completions. Es la prueba previa a la creacion del proyecto Child.
    """
    try:
        asistente = obtener_asistente_ia()
        resultado = asistente.validar_conexion(config.model_dump())
        if resultado.get("ok"):
            logger.info(
                "Configuracion IA validada: proveedor=%s modelo=%s endpoint=%s",
                resultado.get("proveedor"), resultado.get("modelo"),
                resultado.get("endpoint"),
            )
        else:
            logger.warning(
                "Configuracion IA rechazada: estado=%s detalle=%s",
                resultado.get("estado"), (resultado.get("detalle") or "")[:200],
            )
        return ValidarResponse(**resultado)
    except Exception as e:
        logger.error(f"Error validando configuracion IA: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")