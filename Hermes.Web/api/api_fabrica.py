"""
====================================================================
api_fabrica.py — Router de /api/fabrica para Hermes.Web
====================================================================

Endpoints:
    POST   /api/fabrica/proyectos          -> Crear solicitud de proyecto
    GET    /api/fabrica/proyectos          -> Listar solicitudes
    GET    /api/fabrica/proyectos/{id}     -> Obtener estado de solicitud
    GET    /api/fabrica/app-service-plans  -> Listar App Service Plans disponibles
    POST   /api/fabrica/proyectos/{id}/ejecutar -> Ejecutar Factory local (PowerShell)
    POST   /api/fabrica/proyectos/{id}/disparar -> Disparar Factory Runner remoto (GitHub Actions)
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
    app_service_plan_id: str = Field(
        "",
        description="Resource ID completo del App Service Plan de destino (RG-Hermes-Proyectos)"
    )

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
    error: str = ''

# ──────────────────────────────────────────────────────────────
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
            descripcion=solicitud.descripcion,
            app_service_plan_id=solicitud.app_service_plan_id
        )
        logger.info(
            f"Proyecto solicitado: {resultado.nombre_proyecto} "
            f"(deployment: {resultado.deployment_id}) "
            f"(plan: {solicitud.app_service_plan_id or 'NO_ESPECIFICADO'})"
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



@router.get("/fabrica/proyectos/historial", summary="Obtener historial de proyectos (Top 5)")
async def historial_proyectos(request: Request, limit: int = 5):
    """Obtiene las ultimas N solicitudes de proyectos ordenadas por fecha descendente."""
    try:
        servicio = request.app.state.servicio_fabrica
        proyectos = servicio.listar_solicitudes(limite=max(1, min(50, limit)))
        resultado = []
        for p in proyectos:
            d = p.a_dict()
            duracion = ""
            if d.get("fecha_solicitud") and d.get("fecha_actualizacion"):
                try:
                    from datetime import datetime
                    inicio = datetime.fromisoformat(d["fecha_solicitud"])
                    fin = datetime.fromisoformat(d["fecha_actualizacion"])
                    segundos = int((fin - inicio).total_seconds())
                    if segundos >= 60:
                        duracion = f"{segundos // 60}m {segundos % 60}s"
                    else:
                        duracion = f"{segundos}s"
                except Exception:
                    pass
            paso_final = None
            for paso in d.get("pasos", []):
                if paso.get("estado") in ("COMPLETADO", "FALLIDO", "EN_PROCESO"):
                    paso_final = paso
            resultado.append({
                "nombre_proyecto": d.get("nombre_proyecto", ""),
                "estado": d.get("estado", ""),
                "resultado": d.get("resultado", ""),
                "fecha_solicitud": d.get("fecha_solicitud", ""),
                "fecha_actualizacion": d.get("fecha_actualizacion", ""),
                "duracion": duracion,
                "deployment_id": d.get("deployment_id", ""),
                "correlation_id": d.get("correlation_id", ""),
                "repositorio": d.get("repositorio", ""),
                "web_app_url": d.get("web_app_url", ""),
                "commit_sha": d.get("commit_sha", ""),
                "paso_final": paso_final["nombre"] if paso_final else None,
                "paso_estado": paso_final["estado"] if paso_final else None,
                "detalle": d.get("error", "") or (paso_final.get("detalle", "") if paso_final else ""),
            })
        return {"proyectos": resultado, "total": len(resultado)}
    except Exception as e:
        logger.error(f"Error obteniendo historial: {e}")
        return {"proyectos": [], "total": 0, "error": str(e)}


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


@router.post("/fabrica/proyectos/{deployment_id}/disparar",
             summary="Disparar Factory Runner (GitHub Actions remoto)",
             status_code=202)
async def disparar_factory_runner(request: Request, deployment_id: str):
    """Dispara factory-run.yml en HERMES-ENTERPRISE via GitHub API."""
    try:
        servicio = request.app.state.servicio_fabrica
        solicitud = servicio.obtener_solicitud(deployment_id)
        if not solicitud:
            raise HTTPException(status_code=404,
                                detail=f"Solicitud no encontrada: {deployment_id}")
        if solicitud.estado != "SOLICITADO":
            raise HTTPException(
                status_code=400,
                detail=f"La solicitud está en estado '{solicitud.estado}', no se puede disparar"
            )
        resultado = await servicio.ejecutar_factory_remoto(solicitud)
        if resultado.get("exito"):
            return {
                "mensaje": "Factory Runner disparado exitosamente",
                "deployment_id": deployment_id,
                "estado": "CREANDO",
                "dispatch_result": resultado.get("payload_enviado", {})
            }
        else:
            raise HTTPException(
                status_code=502,
                detail=(
                    f"Error disparando Factory Runner: "
                    f"{resultado.get('mensaje', 'Error desconocido')}"
                )
            )
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error disparando Factory Runner {deployment_id}: {e}")
        raise HTTPException(status_code=500,
                            detail=f"Error interno: {str(e)}")


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
# ──────────────────────────────────────────────────────────────
# Endpoint: Listar App Service Plans
# ──────────────────────────────────────────────────────────────


@router.get("/fabrica/app-service-plans",
            summary="Listar App Service Plans disponibles",
            description="Obtiene la lista de App Service Plans en RG-Hermes-Proyectos")
async def listar_app_service_planes(request: Request):
    """Lista los App Service Plans disponibles en RG-Hermes-Proyectos."""
    try:
        from Hermes.Web.backend.servicio_azure import obtener_servicio_azure
        servicio_azure = obtener_servicio_azure()
        resultado = servicio_azure.listar_app_service_plans()
        if not resultado["exito"]:
            logger.warning(f"Error listando planes: {resultado.get('error', '')}")
            return {
                "exito": False,
                "planes": [],
                "error": resultado.get("error", "No fue posible obtener los App Service Plans.")
            }
        return {
            "exito": True,
            "planes": resultado["planes"],
            "total": len(resultado["planes"])
        }
    except ImportError:
        logger.error("servicio_azure no disponible")
        return {"exito": False, "planes": [], "error": "Módulo Azure no disponible"}
    except Exception as e:
        logger.error(f"Error en listar_app_service_planes: {e}")
        return {"exito": False, "planes": [], "error": f"Error interno: {str(e)}"}


