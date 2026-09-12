"""
====================================================================
api_fabrica.py — Router de /api/fabrica para Hermes.Web
====================================================================

Endpoints:
    POST   /api/fabrica/proyectos          -> Crear solicitud de proyecto
    GET    /api/fabrica/proyectos          -> Listar solicitudes
    GET    /api/fabrica/proyectos/{id}     -> Obtener estado de solicitud
    POST   /api/fabrica/proyectos/{id}/ejecutar -> Ejecutar Factory local
    POST   /api/fabrica/proyectos/{id}/paso     -> Actualizar paso (Control Plane)
    POST   /api/fabrica/proyectos/{id}/finalizar -> Finalizar solicitud
====================================================================
"""

import logging
from fastapi import APIRouter, Request, HTTPException
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List

logger = logging.getLogger("Hermes.Web.API.Fabrica")
router = APIRouter()

# ──────────────────────────────────────────────────────────────
# Modelos Pydantic
# ──────────────────────────────────────────────────────────────

class SolicitudCrear(BaseModel):
    """Modelo para crear una solicitud de proyecto."""
    nombre_proyecto: str = Field(..., min_length=3, max_length=40,
                                 description="Nombre del proyecto (ej: hermes-fabrica-04)")
    descripcion: str = Field("", description="Descripción del proyecto")

class SolicitudResponse(BaseModel):
    """Modelo de respuesta para una solicitud."""
    id: str
    nombre_proyecto: str
    estado: str
    correlation_id: str
    deployment_id: str
    mensaje: str = ""

class ActualizarPasoRequest(BaseModel):
    """Modelo para actualizar un paso (desde Control Plane)."""
    numero_paso: int = Field(..., ge=1, le=13)
    estado_paso: str = Field(..., pattern="^(EN_PROCESO|COMPLETADO|FALLIDO|OMITIDO)$")
    detalle: str = ""
    evidencia: str = ""

class FinalizarRequest(BaseModel):
    """Modelo para finalizar una solicitud."""
    resultado: str = Field("PASS", pattern="^(PASS|FAIL)$")
    error: str = ""# ──────────────────────────────────────────────────────────────
# Endpoints
# ──────────────────────────────────────────────────────────────

@router.post("/fabrica/proyectos",
             summary="Crear solicitud de proyecto Child",
             status_code=202,
             response_model=SolicitudResponse)
async def crear_proyecto(request: Request, solicitud: SolicitudCrear):
    """Crea una solicitud para crear un nuevo proyecto Child."""
    try:
        servicio = request.app.state.servicio_fabrica
        resultado = servicio.crear_solicitud(
            nombre_proyecto=solicitud.nombre_proyecto,
            descripcion=solicitud.descripcion
        )
        logger.info(
            f"Proyecto solicitado: {resultado.nombre_proyecto} "
            f"(deployment: {resultado.deployment_id})"
        )
        return SolicitudResponse(
            id=resultado.id,
            nombre_proyecto=resultado.nombre_proyecto,
            estado=resultado.estado,
            correlation_id=resultado.correlation_id,
            deployment_id=resultado.deployment_id,
            mensaje="Solicitud recibida. Use GET /api/fabrica/proyectos/{deployment_id} para seguimiento."
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except Exception as e:
        logger.error(f"Error creando solicitud: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


@router.get("/fabrica/proyectos", summary="Listar solicitudes de proyectos")
async def listar_proyectos(request: Request, limite: int = 20, estado: Optional[str] = None):
    """Lista las solicitudes de proyectos registradas."""
    try:
        servicio = request.app.state.servicio_fabrica
        solicitudes = servicio.listar_solicitudes(limite=limite, estado=estado)
        return {"total": len(solicitudes), "solicitudes": [s.a_dict() for s in solicitudes]}
    except Exception as e:
        logger.error(f"Error listando solicitudes: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


@router.get("/fabrica/proyectos/{deployment_id}", summary="Obtener estado de un proyecto")
async def obtener_proyecto(request: Request, deployment_id: str):
    """Obtiene el estado completo de una solicitud de proyecto."""
    try:
        servicio = request.app.state.servicio_fabrica
        resultado = servicio.obtener_solicitud(deployment_id)
        if not resultado:
            raise HTTPException(status_code=404, detail=f"Solicitud no encontrada: {deployment_id}")
        return resultado.a_dict()
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error obteniendo solicitud {deployment_id}: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


@router.post("/fabrica/proyectos/{deployment_id}/ejecutar", summary="Ejecutar Factory local")
async def ejecutar_factory(request: Request, deployment_id: str):
    """Ejecuta la Factory localmente para procesar la solicitud."""
    try:
        servicio = request.app.state.servicio_fabrica
        solicitud = servicio.obtener_solicitud(deployment_id)
        if not solicitud:
            raise HTTPException(status_code=404, detail=f"Solicitud no encontrada: {deployment_id}")
        if solicitud.estado != "SOLICITADO":
            raise HTTPException(
                status_code=400,
                detail=f"La solicitud está en estado '{solicitud.estado}', no se puede ejecutar"
            )
        import threading
        hilo = threading.Thread(
            target=servicio.ejecutar_factory_local,
            args=(solicitud,), daemon=True
        )
        hilo.start()
        return {"mensaje": "Factory iniciada en segundo plano", "deployment_id": deployment_id, "estado": "CREANDO"}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error ejecutando Factory: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


@router.post("/fabrica/proyectos/{deployment_id}/paso", summary="Actualizar paso (Control Plane)")
async def actualizar_paso(request: Request, deployment_id: str, paso: ActualizarPasoRequest):
    """Actualiza el estado de un paso desde el Control Plane."""
    try:
        servicio = request.app.state.servicio_fabrica
        resultado = servicio.actualizar_desde_control_plane(
            deployment_id=deployment_id, numero_paso=paso.numero_paso,
            estado_paso=paso.estado_paso, detalle=paso.detalle, evidencia=paso.evidencia
        )
        if not resultado:
            raise HTTPException(status_code=404, detail=f"Solicitud no encontrada: {deployment_id}")
        return {"mensaje": "Paso actualizado", "deployment_id": deployment_id,
                "estado": resultado.estado, "paso": paso.numero_paso, "estado_paso": paso.estado_paso}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error actualizando paso: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


@router.post("/fabrica/proyectos/{deployment_id}/finalizar", summary="Finalizar solicitud")
async def finalizar_proyecto(request: Request, deployment_id: str, final: FinalizarRequest):
    """Finaliza una solicitud con resultado PASS o FAIL."""
    try:
        servicio = request.app.state.servicio_fabrica
        resultado = servicio.finalizar_solicitud(
            deployment_id=deployment_id, resultado=final.resultado, error=final.error
        )
        if not resultado:
            raise HTTPException(status_code=404, detail=f"Solicitud no encontrada: {deployment_id}")
        return {"mensaje": f"Solicitud finalizada: {final.resultado}",
                "deployment_id": deployment_id, "estado": resultado.estado, "resultado": resultado.resultado}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error finalizando solicitud: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")
