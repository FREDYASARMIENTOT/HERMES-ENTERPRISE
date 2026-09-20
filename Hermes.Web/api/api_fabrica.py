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

import json
import asyncio
import logging
from datetime import datetime, timezone
from fastapi import APIRouter, Request, HTTPException, Response
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from typing import Optional, Dict, Any, List

from Hermes.Web.backend.event_broker import obtener_broker
from Hermes.Web.backend.servicio_fabrica import _ahora

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
                "web_app": d.get("web_app", ""),
                "azure_resource_exists": d.get("azure_resource_exists"),
                "azure_resource_check_status": d.get("azure_resource_check_status", "NO_VERIFICADO"),
                "azure_resource_checked_at": d.get("azure_resource_checked_at", ""),
                "commit_sha": d.get("commit_sha", ""),
                "paso_final": paso_final["nombre"] if paso_final else None,
                "paso_estado": paso_final["estado"] if paso_final else None,
                "detalle": d.get("error", "") or (paso_final.get("detalle", "") if paso_final else ""),
            })
        return {"proyectos": resultado, "total": len(resultado)}
    except Exception as e:
        logger.error(f"Error obteniendo historial: {e}")
        return {"proyectos": [], "total": 0, "error": str(e)}




@router.get("/fabrica/proyectos/{deployment_id}/azure-status", summary="Obtener estado Azure del recurso")
async def azure_status_proyecto(request: Request, deployment_id: str):
    """Obtiene el estado de reconciliacion Azure para un deployment."""
    try:
        servicio = request.app.state.servicio_fabrica
        solicitud = servicio.obtener_solicitud(deployment_id)
        if not solicitud:
            return {"error": "Deployment no encontrado"}
        d = solicitud.a_dict()
        return {
            "deployment_id": deployment_id,
            "project_name": d.get("nombre_proyecto", ""),
            "web_app": d.get("web_app", ""),
            "web_app_resource_group": d.get("web_app_resource_group", ""),
            "web_app_resource_id": d.get("web_app_resource_id", ""),
            "azure_resource_exists": d.get("azure_resource_exists"),
            "azure_resource_check_status": d.get("azure_resource_check_status", "NO_VERIFICADO"),
            "azure_resource_checked_at": d.get("azure_resource_checked_at", ""),
            "azure_resource_check_error": d.get("azure_resource_check_error", ""),
            "azure_hostname": d.get("azure_hostname", ""),
        }
    except Exception as e:
        logger.error(f"Error obteniendo azure status: {e}")
        return {"error": str(e)}

@router.post("/fabrica/proyectos/{deployment_id}/azure-check", summary="Verificar existencia en Azure ahora")
async def azure_check_proyecto(request: Request, deployment_id: str):
    """Verifica si el App Service asociado al deployment existe en Azure."""
    try:
        servicio = request.app.state.servicio_fabrica
        resultado = servicio.verificar_y_actualizar_estado_azure(deployment_id)
        return resultado
    except Exception as e:
        logger.error(f"Error verificando Azure: {e}")
        return {"error": str(e)}

@router.get("/fabrica/proyectos/reconcile", summary="Reconciliar todos los proyectos (Azure + GitHub + Runtime)")
async def reconcile_all(request: Request):
    """Recorre todos los deployments y verifica su existencia en Azure."""
    try:
        servicio = request.app.state.servicio_fabrica
        resultados = servicio.reconciliar_todos_los_proyectos()
        return resultados
    except Exception as e:
        logger.error(f"Error reconciliando Azure: {e}")
        return {"error": str(e), "total": 0, "existentes": 0, "eliminados": 0, "no_verificados": 0, "errores": 0, "detalles": []}

@router.get("/fabrica/proyectos/{deployment_id}", summary="Obtener estado de un proyecto")
@router.get("/fabrica/proyectos/{deployment_id}/resource-status", summary="Estado completo de recursos (Azure + GitHub + Runtime)")
async def resource_status_proyecto(request: Request, deployment_id: str):
    """Obtiene el estado completo de los 3 recursos del proyecto."""
    try:
        servicio = request.app.state.servicio_fabrica
        resultado = servicio.verificar_y_actualizar_estado_completo(deployment_id)
        return resultado
    except Exception as e:
        logger.error(f"Error obteniendo resource-status {deployment_id}: {e}")
        return {"error": str(e), "deployment_id": deployment_id}

@router.post("/fabrica/proyectos/{deployment_id}/github-check", summary="Verificar existencia en GitHub ahora")
async def github_check_proyecto(request: Request, deployment_id: str):
    """Verifica si el repositorio GitHub asociado al deployment existe."""
    try:
        servicio = request.app.state.servicio_fabrica
        resultado = servicio.verificar_y_actualizar_estado_github(deployment_id)
        return resultado
    except Exception as e:
        logger.error(f"Error verificando GitHub: {e}")
        return {"error": str(e)}

@router.post("/fabrica/proyectos/{deployment_id}/runtime-check", summary="Verificar Runtime/VENV ahora")
async def runtime_check_proyecto(request: Request, deployment_id: str):
    """Verifica si el runtime/VENV del proyecto esta operativo."""
    try:
        servicio = request.app.state.servicio_fabrica
        resultado = servicio.verificar_y_actualizar_estado_runtime(deployment_id)
        return resultado
    except Exception as e:
        logger.error(f"Error verificando Runtime: {e}")
        return {"error": str(e)}

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
    """Finaliza una solicitud con resultado PASS o FAIL.

    Validación adversarial (FASE 20):
    - Si resultado=PASS, todos los 13 pasos deben estar COMPLETADOS.
    - Si hay pasos pendientes HTTP 409 Conflict.
    """
    try:
        servicio = request.app.state.servicio_fabrica

        # Validación adversarial: PASS require todos los pasos COMPLETADOS
        if final.resultado == "PASS":
            consistencia = servicio.validar_consistencia(deployment_id)
            if not consistencia["consistente"]:
                raise HTTPException(
                    status_code=409,
                    detail={
                        "resultado": "FAIL",
                        "error": "No se puede finalizar con PASS: pasos pendientes",
                        "pasos_pendientes": consistencia["pasos_pendientes"],
                        "errores": consistencia["errores"]
                    }
                )

        resultado = servicio.finalizar_solicitud(
            deployment_id=deployment_id, resultado=final.resultado, error=final.error
        )
        if not resultado:
            raise HTTPException(status_code=404, detail=f"Solicitud no encontrada: {deployment_id}")
        logger.info(f"Solicitud finalizada: {deployment_id} -> {final.resultado}")
        return {"mensaje": f"Solicitud finalizada: {final.resultado}",
                "deployment_id": deployment_id, "estado": resultado.estado, "resultado": resultado.resultado}
    except HTTPException:
        raise
    except ValueError as e:
        raise HTTPException(status_code=409, detail={"resultado": "FAIL", "error": str(e)})
    except Exception as e:
        logger.error(f"Error finalizando solicitud: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


@router.put("/fabrica/proyectos/{deployment_id}/metadata", summary="Actualizar metadatos del proyecto (Factory/Control Plane)")
async def actualizar_metadata(request: Request, deployment_id: str, metadata: Dict[str, Any]):
    """
    Actualiza metadatos de trazabilidad del proyecto.
    Usado por Factory Runner y Control Plane para registrar:
    - repository_url, commit_url, visibility
    - factory_run_id, factory_run_url, factory_status
    - control_plane_run_id, control_plane_run_url, control_plane_status
    - validation results, timing
    """
    try:
        servicio = request.app.state.servicio_fabrica
        solicitud = servicio.obtener_solicitud(deployment_id)
        if not solicitud:
            raise HTTPException(status_code=404, detail=f"Solicitud no encontrada: {deployment_id}")

        updated = False
        for key, value in metadata.items():
            if hasattr(solicitud, key) and key not in ("id", "nombre_proyecto", "estado", "pasos"):
                setattr(solicitud, key, value)
                updated = True

        if not updated:
            return {"mensaje": "Sin cambios", "deployment_id": deployment_id}

        solicitud.fecha_actualizacion = datetime.now(timezone.utc).isoformat()
        servicio._guardar(solicitud)
        logger.info(f"Metadatos actualizados para {deployment_id}: {list(metadata.keys())}")
        return {"mensaje": "Metadatos actualizados", "deployment_id": deployment_id, "actualizado": True}
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error actualizando metadatos {deployment_id}: {e}")
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

@router.get("/fabrica/proyectos/{deployment_id}/eventos",
            summary="Obtener event log del proyecto",
            description="Obtiene el log cronológico de eventos del proyecto desde el Event Store")
async def obtener_eventos(request: Request, deployment_id: str):
    """Obtiene el event log completo de un deployment."""
    try:
        servicio = request.app.state.servicio_fabrica
        eventos = servicio.obtener_eventos(deployment_id)
        solicitud = servicio.obtener_solicitud(deployment_id)
        return {
            "deployment_id": deployment_id,
            "project": solicitud.nombre_proyecto if solicitud else "",
            "total_eventos": len(eventos),
            "eventos": eventos
        }
    except Exception as e:
        logger.error(f"Error obteniendo eventos: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


@router.get("/fabrica/proyectos/{deployment_id}/trace/json",
            summary="Obtener deployment-trace.json",
            description="Genera deployment-trace.json desde la fuente persistente")
async def obtener_trace_json(request: Request, deployment_id: str):
    """Genera deployment-trace.json en tiempo real desde DB."""
    try:
        servicio = request.app.state.servicio_fabrica
        solicitud = servicio.obtener_solicitud(deployment_id)
        if not solicitud:
            raise HTTPException(status_code=404, detail="Solicitud no encontrada")

        from datetime import datetime
        def calc_dur(inicio, fin):
            if not inicio or not fin: return 0.0
            try:
                i = datetime.fromisoformat(inicio.replace("Z", "+00:00"))
                f = datetime.fromisoformat(fin.replace("Z", "+00:00"))
                return round((f - i).total_seconds(), 2)
            except: return 0.0

        steps = []
        for p in solicitud.pasos:
            steps.append({
                "numero": p["numero"], "nombre": p["nombre"],
                "estado": p["estado"], "detalle": p.get("detalle", ""),
                "evidencia": p.get("evidencia", ""),
                "fecha_inicio": p.get("fecha_inicio") or "",
                "fecha_fin": p.get("fecha_fin") or "",
                "duracion_segundos": p.get("duracion_segundos") or calc_dur(p.get("fecha_inicio"), p.get("fecha_fin")),
                "subpasos": p.get("subpasos", [])
            })

        eventos = servicio.obtener_eventos(deployment_id)
        dur = solicitud.duracion_total_segundos or calc_dur(solicitud.fecha_solicitud, solicitud.fecha_fin)
        asp_link = f"https://portal.azure.com/#resource/{solicitud.app_service_plan_id}" if solicitud.app_service_plan_id else ""

        trace = {
            "project": solicitud.nombre_proyecto,
            "deployment_id": solicitud.deployment_id,
            "correlation_id": solicitud.correlation_id,
            "status": solicitud.estado,
            "result": solicitud.resultado,
            "started_at": solicitud.fecha_solicitud,
            "finished_at": solicitud.fecha_fin or "",
            "duration_seconds": dur,
            "steps": steps,
            "events": eventos,
            "links": {
                "repository": solicitud.repository_url or "",
                "commit": solicitud.commit_url or "",
                "factory_run": solicitud.factory_run_url or "",
                "control_plane_run": solicitud.control_plane_run_url or "",
                "web_app": solicitud.web_app_url or "",
                "azure_portal": asp_link
            }
        }
        return trace
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generando trace JSON: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")
@router.get("/fabrica/proyectos/{deployment_id}/trace/md",
            summary="Obtener deployment-trace.md",
            description="Genera Markdown de trazabilidad desde DB")
async def obtener_trace_md(request: Request, deployment_id: str):
    """Genera deployment-trace.md en tiempo real desde DB."""
    try:
        servicio = request.app.state.servicio_fabrica
        solicitud = servicio.obtener_solicitud(deployment_id)
        if not solicitud:
            raise HTTPException(status_code=404, detail="Solicitud no encontrada")

        from datetime import datetime
        def calc_dur(inicio, fin):
            if not inicio or not fin: return 0.0
            try:
                i = datetime.fromisoformat(inicio.replace("Z", "+00:00"))
                f = datetime.fromisoformat(fin.replace("Z", "+00:00"))
                return round((f - i).total_seconds(), 2)
            except: return 0.0

        def dur_hum(seg):
            if not seg or seg <= 0: return "-"
            m, s = divmod(int(seg), 60)
            return f"{m}m {s}s" if m else f"{s}s"

        did = solicitud.deployment_id
        cid = solicitud.correlation_id
        nombre = solicitud.nombre_proyecto
        eventos = servicio.obtener_eventos(deployment_id)
        dur = calc_dur(solicitud.fecha_solicitud, solicitud.fecha_fin)

        lines = []
        lines.append(f"# Deployment Trace: {nombre}")
        lines.append("")
        lines.append(f"**Deployment ID**: `{did}`")
        lines.append(f"**Correlation ID**: `{cid}`")
        lines.append(f"**Estado**: {solicitud.estado}")
        lines.append(f"**Resultado**: {solicitud.resultado or '-'}")
        lines.append(f"**Inicio**: {solicitud.fecha_solicitud}")
        lines.append(f"**Fin**: {solicitud.fecha_fin or '-'}")
        lines.append(f"**Duración**: {dur_hum(dur)}")
        lines.append("")
        lines.append("---")
        lines.append("## Timeline")
        lines.append("")
        lines.append("| # | Paso | Estado | Inicio | Fin | Duración |")
        lines.append("|---|---|---|---|---|---|")
        for p in solicitud.pasos:
            pdur = p.get("duracion_segundos") or calc_dur(p.get("fecha_inicio"), p.get("fecha_fin"))
            lines.append(
                f"| {p['numero']} | {p['nombre']} | {p['estado']} | "
                f"{(p.get('fecha_inicio') or '-')[:19]} | "
                f"{(p.get('fecha_fin') or '-')[:19]} | "
                f"{dur_hum(pdur)} |"
            )
        lines.append("")
        lines.append("---")
        lines.append("## Event Log")
        lines.append("")
        lines.append(f"Total eventos: {len(eventos)}")
        lines.append("")
        lines.append("| Timestamp | Tipo | Paso | Mensaje |")
        lines.append("|---|---|---|---|")
        for ev in eventos:
            ts = (ev.get("timestamp") or "")[:23]
            lines.append(f"| {ts} | {ev.get('tipo','')} | {ev.get('paso_numero','')} | {ev.get('mensaje','')} |")
        lines.append("")
        lines.append("---")
        lines.append("## Links")
        lines.append("")
        lines.append(f"- **Repository**: [{solicitud.repository_url}]({solicitud.repository_url})")
        lines.append(f"- **Commit**: [{solicitud.commit_sha or '-'}]({solicitud.commit_url or '#'})")
        lines.append(f"- **Web App**: [{solicitud.web_app_url}]({solicitud.web_app_url})")
        lines.append(f"- **Factory Run**: [{solicitud.factory_run_id or '-'}]({solicitud.factory_run_url or '#'})")
        if solicitud.app_service_plan_id:
            asp_link = f"https://portal.azure.com/#resource/{solicitud.app_service_plan_id}"
            lines.append(f"- **Azure Portal**: [{solicitud.app_service_plan_name or 'Plan'}]({asp_link})")
        lines.append("")

        md = "\n".join(lines)
        return Response(content=md, media_type="text/markdown",
                        headers={"Content-Disposition": f"attachment; filename=deployment-trace-{did}.md"})
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error generando trace MD: {e}")
        raise HTTPException(status_code=500, detail=f"Error interno: {str(e)}")


# ──────────────────────────────────────────────────────────────
# Endpoint SSE — Eventos en tiempo real
# ──────────────────────────────────────────────────────────────

@router.get(
    "/fabrica/proyectos/{deployment_id}/eventos/stream",
    summary="Stream de eventos en tiempo real (SSE)",
    response_class=StreamingResponse,
)
async def stream_eventos(request: Request, deployment_id: str):
    """Endpoint SSE para eventos de un deployment en tiempo real.

    Formatos SSE:
        id: <event_id>
        event: deployment_event
        data: <JSON>

    Heartbeat cada 30 segundos.
    Soporta Last-Event-ID para reconexión.
    Al finalizar el deployment, envía evento final y cierra.
    """
    servicio = request.app.state.servicio_fabrica
    if not servicio:
        raise HTTPException(status_code=503, detail="Servicio no disponible")

    # Verificar que el deployment existe
    solicitud = servicio.obtener_solicitud(deployment_id)
    if not solicitud:
        raise HTTPException(status_code=404, detail="Deployment no encontrado")

    # ── Replay: si el cliente envía Last-Event-ID, recuperar eventos faltantes ──
    last_event_id = request.headers.get("Last-Event-ID", "")
    eventos_replay = []
    if last_event_id:
        try:
            eventos_replay = servicio.obtener_eventos_desde(
                deployment_id, last_event_id
            )
            logger.info(
                f"SSE replay: {len(eventos_replay)} eventos desde {last_event_id} "
                f"para {deployment_id}"
            )
        except Exception as e:
            logger.warning(f"SSE replay error: {e}")

    broker = obtener_broker()
    queue = broker.subscribe(deployment_id)
    terminated = False

    async def _generar_eventos():
        nonlocal terminated
        try:
            # ── Enviar eventos de replay primero ──
            for ev in eventos_replay:
                yield _formato_sse(ev)
                await asyncio.sleep(0)

            # ── Enviar último evento conocido si no hay replay ──
            # (para que el cliente tenga al menos el estado actual)
            if not last_event_id:
                evts = servicio.obtener_eventos(deployment_id)
                for ev in evts:
                    yield _formato_sse(ev)
                    await asyncio.sleep(0)

            # ── Bucle principal: esperar eventos nuevos + heartbeat ──
            heartbeat_interval = 30  # segundos
            while not terminated:
                try:
                    # Esperar evento con timeout para heartbeat
                    evento = await asyncio.wait_for(
                        queue.get(), timeout=heartbeat_interval
                    )
                    if evento is None:
                        # Señal de terminación
                        terminated = True
                        break
                    yield _formato_sse(evento)

                    # Si es evento final, cerrar después de enviarlo
                    if evento.get("tipo") in ("TERMINACION", "FIN"):
                        yield _formato_sse_final(evento)
                        terminated = True
                        break

                except asyncio.TimeoutError:
                    # Heartbeat
                    yield f"event: heartbeat\ndata: {json.dumps({'timestamp': _ahora()})}\n\n"

        except asyncio.CancelledError:
            logger.debug(f"SSE conexión cancelada para {deployment_id}")
        except Exception as e:
            logger.error(f"SSE error en stream para {deployment_id}: {e}")
        finally:
            broker.unsubscribe(deployment_id, queue)

    return StreamingResponse(
        _generar_eventos(),
        media_type="text/event-stream",
        headers={
            "Cache-Control": "no-cache",
            "Connection": "keep-alive",
            "X-Accel-Buffering": "no",
        },
    )


def _formato_sse(evento: dict) -> str:
    """Formatea un evento como mensaje SSE."""
    event_id = evento.get("event_id", "")
    data = json.dumps(evento, ensure_ascii=False, default=str)
    return f"id: {event_id}\nevent: deployment_event\ndata: {data}\n\n"


def _formato_sse_final(evento: dict) -> str:
    """Formatea el evento final de terminación."""
    data = json.dumps(evento, ensure_ascii=False, default=str)
    return f"event: deployment_finished\ndata: {data}\n\n"

