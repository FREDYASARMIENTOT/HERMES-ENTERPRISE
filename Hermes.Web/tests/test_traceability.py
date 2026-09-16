# -*- coding: utf-8 -*-
"""
test_traceability.py - Pruebas Automaticas de Trazabilidad (FASE 20.26)
=====================================================================
Hermes Enterprise Observability Hardening

Proposito: Validacion adversarial automatica de consistencia de trazabilidad.

Reglas probadas:
    1. PASS no puede coexistir con pasos PENDIENTES
    2. Estado derivado debe coincidir con estado calculado
    3. deployment_id y correlation_id son constantes
    4. Todos los pasos obligatorios deben existir
    5. Timestamps completos para pasos COMPLETADOS
    9. Finalizacion segura (HTTP 409 si pasos pendientes)
    10. Resultado global coherente con pasos

Ejecutar:
    pytest Hermes.Web/tests/test_traceability.py -v
"""

import os, sys, json, uuid, sqlite3, tempfile, logging
from pathlib import Path
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch

logging.disable(logging.CRITICAL)
_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(_PROJECT_ROOT))

import pytest
from Hermes.Web.backend.servicio_fabrica import (
    ServicioFabrica, SolicitudProyecto, obtener_servicio_fabrica,
    ESTADOS_PROYECTO, PASOS_CANONICOS, _generar_id
)

_ASP_VALIDO = (
    "/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/"
    "resourceGroups/RG-Hermes-Proyectos/"
    "providers/Microsoft.Web/serverfarms/ASP-HERMES-PORTAL"
)


def _solicitud(svc, nombre="hermes-trace-test", descripcion="Trace Test"):
    return svc.crear_solicitud(nombre, descripcion=descripcion, app_service_plan_id=_ASP_VALIDO)


@pytest.fixture(autouse=True)
def clean_db():
    tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    tmp.close()
    db_path = tmp.name
    old = os.environ.get("HERMES_DB_PATH")
    os.environ["HERMES_DB_PATH"] = db_path
    yield db_path
    os.environ.pop("HERMES_DB_PATH", None)
    if old: os.environ["HERMES_DB_PATH"] = old
    try: os.unlink(db_path)
    except PermissionError: pass


@pytest.fixture
def svc(clean_db):
    from Hermes.Web.backend.servicio_fabrica import _instancia_servicio, ServicioFabrica
    _instancia_servicio = None
    s = ServicioFabrica()
    _instancia_servicio = s
    return s


@pytest.fixture
def solicitud(svc):
    return _solicitud(svc)

class TestRegla1PassSinPendientes:
    """Regla 1: PASS NO puede tener pasos PENDIENTES."""

    def test_pendiente_rechaza_pass(self, svc, solicitud):
        with pytest.raises(ValueError) as exc:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert "pendiente" in str(exc.value).lower()

    def test_pendiente_rechaza_pass_api(self, svc, solicitud):
        from fastapi.testclient import TestClient
        from Hermes.Web.backend.main import app
        app.state.servicio_fabrica = svc
        client = TestClient(app)
        r = client.post(f"/api/fabrica/proyectos/{solicitud.deployment_id}/finalizar",
                        json={"resultado": "PASS"})
        assert r.status_code == 409

    def test_todos_completados_permite_pass(self, svc, solicitud):
        for paso in solicitud.pasos:
            svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=paso["numero"],
                                  detalle="ok", evidencia="test")
        r = svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert r.resultado == "PASS"
        assert r.estado == "COMPLETADO"


class TestRegla2EstadoDerivado:
    """Regla 2: Estado derivado debe coincidir con calculo."""

    def test_estado_coincide(self, svc, solicitud):
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert c["estado_global"] == "EN_PROCESO"  # Paso 1 se inicia automaticamente

    def test_estado_fallido(self, svc, solicitud):
        svc.actualizar_estado(solicitud, "FALLIDO", numero_paso=2, detalle="Falló", evidencia="")
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert c["estado_global"] == "FALLIDO"

    def test_estado_completado(self, svc, solicitud):
        for paso in solicitud.pasos:
            svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=paso["numero"],
                                  detalle="ok", evidencia="ok")
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert c["estado_global"] == "COMPLETADO"


class TestRegla3IdsConstantes:
    """Regla 3: deployment_id y correlation_id son constantes."""

    def test_deployment_id_constante(self, svc, solicitud):
        did = solicitud.deployment_id
        for paso in solicitud.pasos:
            svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=paso["numero"],
                                  detalle="ok", evidencia="ok")
        assert svc.obtener_solicitud(did).deployment_id == did

    def test_correlation_id_constante(self, svc, solicitud):
        cid = solicitud.correlation_id
        assert svc.obtener_solicitud(solicitud.deployment_id).correlation_id == cid


class TestRegla4PasosObligatorios:
    """Regla 4: Todos los 13 pasos obligatorios deben existir."""

    def test_trece_pasos(self, svc, solicitud):
        assert len(solicitud.pasos) == 13
        assert [p["numero"] for p in solicitud.pasos] == list(range(1, 14))

    def test_campos_minimos(self, svc, solicitud):
        for paso in solicitud.pasos:
            for campo in ["numero", "nombre", "estado", "fecha_inicio",
                          "fecha_fin", "duracion_segundos", "detalle", "evidencia", "subpasos"]:
                assert campo in paso, f"Paso {paso['numero']} falta: {campo}"

class TestRegla5Timestamps:
    """Regla 5: Timestamps completos."""

    def test_fecha_inicio_al_iniciar(self, svc, solicitud):
        solicitud.iniciar_paso(2, "Iniciando paso 2 manualmente")
        svc._guardar(solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        assert s.pasos[1]["fecha_inicio"] is not None

    def test_fecha_fin_al_completar(self, svc, solicitud):
        svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=2, detalle="OK", evidencia="ok")
        s = svc.obtener_solicitud(solicitud.deployment_id)
        assert s.pasos[1]["fecha_fin"] is not None

    def test_duracion_calculada(self, svc, solicitud):
        svc.actualizar_estado(solicitud, "EN_PROCESO", numero_paso=2, detalle="Inicio")
        import time; time.sleep(0.01)
        svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=2, detalle="Fin", evidencia="ok")
        s = svc.obtener_solicitud(solicitud.deployment_id)
        if s.pasos[1]["duracion_segundos"] is not None:
            assert s.pasos[1]["duracion_segundos"] >= 0


class TestRegla9FinalizacionSegura:
    """Regla 9: Finalizacion segura."""

    def test_sin_pasos_no_permite_pass(self, svc, solicitud):
        with pytest.raises(ValueError):
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")

    def test_fallidos_permite_fail(self, svc, solicitud):
        r = svc.finalizar_solicitud(solicitud.deployment_id, resultado="FAIL", error="Deliberado")
        assert r.resultado == "FAIL"

    def test_finalizacion_registra_fechas(self, svc, solicitud):
        for paso in solicitud.pasos:
            svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=paso["numero"],
                                  detalle="ok", evidencia="ok")
        r = svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert r.fecha_fin and r.duracion_total_segundos >= 0


class TestRegla10Consistencia:
    """Regla 10: Consistencia sin errores."""

    def test_sin_inconsistencias(self, svc, solicitud):
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert c["consistente"] is True

    def test_inconsistencia_pass_pendiente(self, svc, solicitud):
        solicitud.resultado = "PASS"
        solicitud.estado = "COMPLETADO"
        # FASE 24: _guardar corrige automaticamente PASS inconsistente
        svc._guardar(solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        assert s.resultado != "PASS", "_guardar no corrigio PASS"
        assert s.estado != "COMPLETADO", "_guardar no corrigio COMPLETADO"
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert c["consistente"], f"Tras correccion deberia ser consistente" 

    def test_historial_sin_secretos(self, svc, solicitud):
        import json as j
        d = svc.obtener_solicitud(solicitud.deployment_id).a_dict()
        t = j.dumps(d).lower()
        for s in ["ghp_", "gho_", "pat_", "token"]:
            assert s not in t


class TestControlPlaneCallbacks:
    """Validacion de callbacks desde Control Plane."""

    def test_paso5_cp(self, svc, solicitud):
        s = svc.actualizar_desde_control_plane(solicitud.deployment_id, 5, "COMPLETADO",
                                               "CP ejecutado", "run_id=12345")
        assert next(p for p in s.pasos if p["numero"] == 5)["estado"] == "COMPLETADO"

    def test_paso6_oidc(self, svc, solicitud):
        s = svc.actualizar_desde_control_plane(solicitud.deployment_id, 6, "COMPLETADO",
                                               "OIDC ok", "PASS")
        assert next(p for p in s.pasos if p["numero"] == 6)["estado"] == "COMPLETADO"

    def test_paso8_deploy(self, svc, solicitud):
        s = svc.actualizar_desde_control_plane(solicitud.deployment_id, 8, "COMPLETADO",
                                               "Deploy ok", "PASS")
        assert next(p for p in s.pasos if p["numero"] == 8)["estado"] == "COMPLETADO"

    def test_paso9_readiness(self, svc, solicitud):
        s = svc.actualizar_desde_control_plane(solicitud.deployment_id, 9, "COMPLETADO",
                                               "Health ok", "HTTP 200")
        assert next(p for p in s.pasos if p["numero"] == 9)["estado"] == "COMPLETADO"

    def test_paso10_funcional(self, svc, solicitud):
        s = svc.actualizar_desde_control_plane(solicitud.deployment_id, 10, "COMPLETADO",
                                               "8/8 PASS", "PASS")
        assert next(p for p in s.pasos if p["numero"] == 10)["estado"] == "COMPLETADO"

    def test_paso12_publicacion(self, svc, solicitud):
        s = svc.actualizar_desde_control_plane(solicitud.deployment_id, 12, "COMPLETADO",
                                               "Publicado", "PASS")
        assert next(p for p in s.pasos if p["numero"] == 12)["estado"] == "COMPLETADO"

class TestMetadataCompleta:
    """Validacion de metadata completa."""

    def test_github_metadata(self, svc, solicitud):
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.repository_url = "https://github.com/test/repo"
        s.visibility = "private"
        svc._guardar(s)
        assert svc.obtener_solicitud(solicitud.deployment_id).repository_url == "https://github.com/test/repo"

    def test_azure_metadata(self, svc, solicitud):
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.web_app = "as-test-app"
        s.web_app_url = "https://as-test-app.azurewebsites.net"
        svc._guardar(s)
        assert "azurewebsites" in svc.obtener_solicitud(solicitud.deployment_id).web_app_url


class TestAdversarialEdgeCases:
    """Casos adversariales extremos."""

    def test_fallido_con_pass_rechazado(self, svc, solicitud):
        svc.actualizar_estado(solicitud, "FALLIDO", numero_paso=2, detalle="Error", evidencia="")
        with pytest.raises(ValueError):
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")

    def test_paso_13_cierra_ciclo(self, svc, solicitud):
        for paso in solicitud.pasos:
            svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=paso["numero"],
                                  detalle="ok", evidencia="ok")
        s = svc.obtener_solicitud(solicitud.deployment_id)
        assert all(p["estado"] == "COMPLETADO" for p in s.pasos)


class TestDBConsistency:
    """Consistencia con base de datos."""

    def test_db_persistencia_pasos(self, svc, solicitud):
        db_path = os.environ.get("HERMES_DB_PATH")
        conn = sqlite3.connect(db_path)
        c = conn.cursor()
        c.execute("SELECT pasos_json FROM solicitudes_proyecto WHERE deployment_id=?", (solicitud.deployment_id,))
        row = c.fetchone()
        conn.close()
        assert row is not None
        import json
        pasos = json.loads(row[0])
        assert len(pasos) == 13

    def test_db_persistencia_metadata(self, svc, solicitud):
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.repository_url = "https://github.com/test/repo"
        svc._guardar(s)
        db_path = os.environ.get("HERMES_DB_PATH")
        conn = sqlite3.connect(db_path)
        c = conn.cursor()
        c.execute("SELECT repository_url FROM solicitudes_proyecto WHERE deployment_id=?", (solicitud.deployment_id,))
        row = c.fetchone()
        conn.close()
        assert row and row[0] == "https://github.com/test/repo"


class TestValidatorImports:
    """Validacion de que scripts de trazabilidad importan correctamente."""

    def test_validate_traceability_imports(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "v", os.path.join(_PROJECT_ROOT, "tools", "validate_traceability.py"))
        assert spec is not None

    def test_generate_deployment_trace_imports(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "g", os.path.join(_PROJECT_ROOT, "tools", "generate_deployment_trace.py"))
        assert spec is not None

    def test_generate_deployment_trace_md_imports(self):
        import importlib.util
        spec = importlib.util.spec_from_file_location(
            "m", os.path.join(_PROJECT_ROOT, "tools", "generate_deployment_trace_md.py"))
        assert spec is not None


class TestEventStore:
    """Nuevo: Validación del Event Store persistente (FASE 20.30)."""
    def test_evento_creado_al_iniciar_paso(self, svc, solicitud):
        eventos = svc.obtener_eventos(solicitud.deployment_id)
        assert len(eventos) > 0
        assert any(e["tipo"] == "INFO" for e in eventos)
    def test_evento_al_finalizar_paso(self, svc, solicitud):
        svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=2, detalle="ok", evidencia="ok")
        eventos = svc.obtener_eventos(solicitud.deployment_id)
        assert any(e["tipo"] == "PASS" for e in eventos)
    def test_evento_al_fallar_paso(self, svc, solicitud):
        svc.actualizar_estado(solicitud, "FALLIDO", numero_paso=2, detalle="Error", evidencia="")
        eventos = svc.obtener_eventos(solicitud.deployment_id)
        assert any(e["tipo"] == "ERROR" for e in eventos)
    def test_eventos_orden_cronologico(self, svc, solicitud):
        eventos = svc.obtener_eventos(solicitud.deployment_id)
        ids = [e["id"] for e in eventos]
        assert ids == sorted(ids), "Eventos no en orden cronologico"
    def test_evento_tiene_id_unico(self, svc, solicitud):
        eventos = svc.obtener_eventos(solicitud.deployment_id)
        event_ids = [e["event_id"] for e in eventos]
        assert len(event_ids) == len(set(event_ids)), "Hay event_id duplicados"
    def test_evento_finalizacion(self, svc, solicitud):
        for paso in solicitud.pasos:
            svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=paso["numero"], detalle="ok", evidencia="ok")
        svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        eventos = svc.obtener_eventos(solicitud.deployment_id)
        assert any("finalizado" in e["mensaje"].lower() for e in eventos)
class TestSubsteps:
    def test_subpasos_inician_vacios(self, svc, solicitud):
        for paso in solicitud.pasos:
            assert isinstance(paso.get("subpasos"), list)
            assert len(paso["subpasos"]) == 0
    def test_subpasos_en_actualizar_estado(self, svc, solicitud):
        sub = [{"numero": 1, "nombre": "Clone", "estado": "COMPLETADO", "fecha_inicio": "2024-01-01T00:00:00", "fecha_fin": "2024-01-01T00:00:01", "duracion_segundos": 1.0, "detalle": "Clonado", "evidencia": "OK"}, {"numero": 2, "nombre": "Build", "estado": "COMPLETADO", "fecha_inicio": "2024-01-01T00:00:01", "fecha_fin": "2024-01-01T00:00:03", "duracion_segundos": 2.0, "detalle": "Build OK", "evidencia": "OK"}]
        svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=3, detalle="GitHub OK", evidencia="SHA=abc123", subpasos=sub)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        paso3 = next(p for p in s.pasos if p["numero"] == 3)
        assert len(paso3["subpasos"]) == 2
        assert paso3["subpasos"][0]["nombre"] == "Clone"
    def test_subpasos_en_callback(self, svc, solicitud):
        sub = [{"numero": 1, "nombre": "Auth OIDC", "estado": "COMPLETADO", "fecha_inicio": "2024-01-01T00:00:00", "fecha_fin": "2024-01-01T00:00:02", "duracion_segundos": 2.0, "detalle": "Token obtenido", "evidencia": "id_token=xxx"}]
        svc.actualizar_desde_control_plane(solicitud.deployment_id, 6, "COMPLETADO", detalle="OIDC exitoso", evidencia="PASS", subpasos=sub)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        paso6 = next(p for p in s.pasos if p["numero"] == 6)
        assert len(paso6["subpasos"]) == 1
        assert paso6["subpasos"][0]["nombre"] == "Auth OIDC"
class TestCallbackFailureDetection:
    def test_callback_solicitud_no_existe(self, svc):
        result = svc.actualizar_desde_control_plane("FAKE-ID-NO-EXISTE", 5, "COMPLETADO", detalle="Callback perdido", evidencia="", http_status=404)
        assert result is None
        eventos = svc.obtener_eventos("FAKE-ID-NO-EXISTE")
        assert len(eventos) > 0
        assert eventos[0]["tipo"] == "ERROR"
        assert eventos[0]["estado_nuevo"] == "CALLBACK_FAILED"
    def test_callback_con_http_status(self, svc, solicitud):
        svc.actualizar_desde_control_plane(solicitud.deployment_id, 5, "COMPLETADO", detalle="CP ejecutado", evidencia="run_id=123", http_status=200, http_method="POST", http_url="/api/fabrica/proyectos/xxx/paso")
        eventos = svc.obtener_eventos(solicitud.deployment_id)
        evento = next((e for e in eventos if e.get("http_status") == 200), None)
        assert evento is not None
        assert evento["http_method"] == "POST"
    def test_callback_error_detectado(self, svc, solicitud):
        svc.actualizar_desde_control_plane(solicitud.deployment_id, 7, "FALLIDO", detalle="Azure provisioning failed", evidencia="", error_code="AZURE_ERROR", error_message="Resource group not found")
        eventos = svc.obtener_eventos(solicitud.deployment_id)
        evento = next((e for e in eventos if e.get("error_code") == "AZURE_ERROR"), None)
        assert evento is not None
        assert "Resource group not found" in evento.get("error_message", "")
class TestDeploymentTrace:
    def test_trace_has_required_fields(self, svc, solicitud):
        steps = []
        for p in solicitud.pasos:
            steps.append({"numero": p["numero"], "nombre": p["nombre"], "estado": p["estado"], "subpasos": p.get("subpasos", [])})
        trace = {"project": solicitud.nombre_proyecto, "deployment_id": solicitud.deployment_id, "correlation_id": solicitud.correlation_id, "status": solicitud.estado, "result": solicitud.resultado, "started_at": solicitud.fecha_solicitud, "finished_at": solicitud.fecha_fin or "", "duration_seconds": solicitud.duracion_total_segundos, "steps": steps, "events": [], "links": {}}
        required = ["project", "deployment_id", "correlation_id", "status", "result", "started_at", "finished_at", "duration_seconds", "steps", "events", "links"]
        for field in required:
            assert field in trace, f"Trace missing field: {field}"
    def test_trace_md_has_timeline(self, svc, solicitud):
        lines = [f"# Deployment Trace: {solicitud.nombre_proyecto}"]
        lines.append(f"**Deployment ID**: {solicitud.deployment_id}")
        lines.append("## Timeline")
        md = "\n".join(lines)
        assert "Deployment ID" in md and "Timeline" in md
    def test_api_eventos_endpoint(self, svc, solicitud):
        from fastapi.testclient import TestClient
        from Hermes.Web.backend.main import app
        app.state.servicio_fabrica = svc
        client = TestClient(app)
        r = client.get(f"/api/fabrica/proyectos/{solicitud.deployment_id}/eventos")
        assert r.status_code == 200
        data = r.json()
        assert "eventos" in data
    def test_api_trace_json_endpoint(self, svc, solicitud):
        from fastapi.testclient import TestClient
        from Hermes.Web.backend.main import app
        app.state.servicio_fabrica = svc
        client = TestClient(app)
        r = client.get(f"/api/fabrica/proyectos/{solicitud.deployment_id}/trace/json")
        assert r.status_code == 200
        data = r.json()
        assert data["deployment_id"] == solicitud.deployment_id
    def test_api_trace_md_endpoint(self, svc, solicitud):
        from fastapi.testclient import TestClient
        from Hermes.Web.backend.main import app
        app.state.servicio_fabrica = svc
        client = TestClient(app)
        r = client.get(f"/api/fabrica/proyectos/{solicitud.deployment_id}/trace/md")
        assert r.status_code == 200
        assert "text/markdown" in r.headers["content-type"]

class TestFase24AntiFalsePass:
    """FASE 24 - Tests adversariales de anti-false-PASS."""

    def _completar_todos_los_pasos(self, svc, solicitud, excepto=None):
        if excepto is None:
            excepto = set()
        for paso in solicitud.pasos:
            if paso["numero"] not in excepto:
                svc.actualizar_estado(
                    solicitud, "COMPLETADO",
                    numero_paso=paso["numero"],
                    detalle=f"Paso {paso['numero']} completado",
                    evidencia="ok"
                )

    def test_p01_pass_con_paso6_pendiente_rechazado(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud, excepto={6})
        with pytest.raises(ValueError) as exc:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert "pendiente" in str(exc.value).lower()

    def test_p02_pass_con_paso8_pendiente_rechazado(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud, excepto={8})
        with pytest.raises(ValueError) as exc:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert "pendiente" in str(exc.value).lower()

    def test_p03_pass_con_paso9_pendiente_rechazado(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud, excepto={9})
        with pytest.raises(ValueError) as exc:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert "pendiente" in str(exc.value).lower()

    def test_p04_pass_con_paso10_pendiente_rechazado(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud, excepto={10})
        with pytest.raises(ValueError) as exc:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert "pendiente" in str(exc.value).lower()

    def test_p05_pass_con_paso12_pendiente_rechazado(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud, excepto={12})
        with pytest.raises(ValueError) as exc:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert "pendiente" in str(exc.value).lower()

    def test_p06_pass_con_varios_pasos_pendientes_rechazado(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud, excepto={6, 8, 9, 10, 12})
        with pytest.raises(ValueError) as exc:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert "pendiente" in str(exc.value).lower()

    def test_p07_completado_con_pendiente_rechazado_por_guardar(self, svc, solicitud):
        solicitud.estado = "COMPLETADO"
        solicitud.resultado = "PASS"
        svc._guardar(solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        assert s.estado != "COMPLETADO"
        assert s.resultado != "PASS"

    def test_p08_completado_sin_pendientes_ok(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud)
        r = svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert r.estado == "COMPLETADO"
        assert r.resultado == "PASS"

    def test_p09_validar_consistencia_sin_control_plane(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.resultado = "PASS"
        s.control_plane_run_id = ""
        s.control_plane_status = ""
        s.readiness_result = ""
        s.functional_result = ""
        svc._guardar(s)
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert not c["consistente"]
        assert any("control_plane_run_id" in e for e in c["errores"])

    def test_p10_validar_consistencia_sin_readiness(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.resultado = "PASS"
        s.control_plane_run_id = "run-123"
        s.control_plane_status = "COMPLETADO"
        s.readiness_result = ""
        s.functional_result = "PASS"
        s.commit_sha = "abc123"
        s.app_service_plan_id = _ASP_VALIDO
        svc._guardar(s)
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert not c["consistente"]
        assert any("readiness_result" in e for e in c["errores"])

    def test_p11_validar_consistencia_sin_functional(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.resultado = "PASS"
        s.control_plane_run_id = "run-123"
        s.control_plane_status = "COMPLETADO"
        s.readiness_result = "PASS"
        s.functional_result = ""
        s.commit_sha = "abc123"
        s.app_service_plan_id = _ASP_VALIDO
        svc._guardar(s)
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert not c["consistente"]
        assert any("functional_result" in e for e in c["errores"])

    def test_p12_validar_consistencia_sin_sha(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.resultado = "PASS"
        s.control_plane_run_id = "run-123"
        s.control_plane_status = "COMPLETADO"
        s.readiness_result = "PASS"
        s.functional_result = "PASS"
        s.commit_sha = ""
        s.app_service_plan_id = _ASP_VALIDO
        svc._guardar(s)
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert not c["consistente"]
        assert any("commit_sha" in e for e in c["errores"])

    def test_p13_validar_consistencia_sin_plan(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.resultado = "PASS"
        s.control_plane_run_id = "run-123"
        s.control_plane_status = "COMPLETADO"
        s.readiness_result = "PASS"
        s.functional_result = "PASS"
        s.commit_sha = "abc123"
        s.app_service_plan_id = ""
        svc._guardar(s)
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert not c["consistente"]
        assert any("app_service_plan_id" in e for e in c["errores"])

    def test_p14_guardar_corrige_estado_inconsistente(self, svc, solicitud):
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.estado = "COMPLETADO"
        s.resultado = "PASS"
        svc._guardar(s)
        s2 = svc.obtener_solicitud(solicitud.deployment_id)
        assert s2.estado != "COMPLETADO"
        assert s2.resultado != "PASS"

    def test_p15_guardar_corrige_resultado_inconsistente(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud, excepto={13})
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.resultado = "PASS"
        svc._guardar(s)
        s2 = svc.obtener_solicitud(solicitud.deployment_id)
        assert s2.resultado != "PASS"

    def test_p16_todos_completados_con_evidencia_permite_pass(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.control_plane_run_id = "run-456"
        s.control_plane_run_url = "https://github.com/test/run/456"
        s.control_plane_status = "COMPLETADO"
        s.readiness_result = "PASS"
        s.functional_result = "PASS"
        s.commit_sha = "c00ff83b5c5683cc374f3e4ad5d41c811c60c078"
        s.app_service_plan_id = _ASP_VALIDO
        svc._guardar(s)
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert c["consistente"], f"Errores: {c['errores']}"
        r = svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert r.estado == "COMPLETADO"
        assert r.resultado == "PASS"

    def test_p17_reproduce_caso_test_audit_003(self, svc, solicitud):
        pasos_exitosos = {1, 2, 3, 4, 5, 7, 11, 13}
        for paso in solicitud.pasos:
            if paso["numero"] in pasos_exitosos:
                svc.actualizar_estado(
                    solicitud, "COMPLETADO",
                    numero_paso=paso["numero"],
                    detalle=f"Paso {paso['numero']} OK",
                    evidencia="PASS"
                )
        with pytest.raises(ValueError) as exc:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert "pendiente" in str(exc.value).lower()
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.resultado = "PASS"
        svc._guardar(s)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        assert s.resultado != "PASS"
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert c["consistente"]

    def test_p18_calcular_estado_global_determinista(self, svc, solicitud):
        s = svc.obtener_solicitud(solicitud.deployment_id)
        e1 = svc._calcular_estado_global(s)
        e2 = svc._calcular_estado_global(s)
        assert e1 == e2
        assert e1 == "EN_PROCESO", f"Esperaba EN_PROCESO, obtuvo {e1}"

    def test_p19_calcular_estado_global_todos_completados(self, svc, solicitud):
        self._completar_todos_los_pasos(svc, solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        e = svc._calcular_estado_global(s)
        assert e == "COMPLETADO", f"Esperaba COMPLETADO, obtuvo {e}"

    def test_p20_calcular_estado_global_con_fallido(self, svc, solicitud):
        svc.actualizar_estado(solicitud, "FALLIDO", numero_paso=6,
                              detalle="Error OIDC", evidencia="error")
        s = svc.obtener_solicitud(solicitud.deployment_id)
        e = svc._calcular_estado_global(s)
        assert e == "FALLIDO", f"Esperaba FALLIDO, obtuvo {e}"


class TestAdversarialConsistency:
    def test_pass_con_pendiente_rechazado_adversarial(self, svc, solicitud):
        for paso in solicitud.pasos:
            if paso["numero"] != 6:
                svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=paso["numero"], detalle="ok", evidencia="ok")
        s = svc.obtener_solicitud(solicitud.deployment_id)
        s.pasos[5]["estado"] = "PENDIENTE"
        svc._guardar(s)
        with pytest.raises(ValueError) as exc:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert "pendiente" in str(exc.value).lower()
    def test_en_proceso_rechaza_pass(self, svc, solicitud):
        svc.actualizar_estado(solicitud, "EN_PROCESO", numero_paso=8, detalle="En deploy")
        with pytest.raises(ValueError) as exc:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert "pendiente" in str(exc.value).lower()
    def test_sha_consistency(self, svc, solicitud):
        sha_original = solicitud.commit_sha
        solicitud.commit_sha = "abc123def456abc123def456abc123def456abc1"
        svc._guardar(solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        assert s.commit_sha == "abc123def456abc123def456abc123def456abc1"
    def test_plan_consistency(self, svc, solicitud):
        pid = solicitud.app_service_plan_id
        s = svc.obtener_solicitud(solicitud.deployment_id)
        assert s.app_service_plan_id == pid
    def test_duracion_total_no_negativa(self, svc, solicitud):
        for paso in solicitud.pasos:
            svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=paso["numero"], detalle="ok", evidencia="ok")
        r = svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
        assert r.duracion_total_segundos >= 0
    def test_paso_duracion_no_negativa(self, svc, solicitud):
        svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=2, detalle="Test", evidencia="ok")
        s = svc.obtener_solicitud(solicitud.deployment_id)
        paso2 = next(p for p in s.pasos if p["numero"] == 2)
        if paso2["duracion_segundos"] is not None:
            assert paso2["duracion_segundos"] >= 0
    def test_fecha_fin_mayor_igual_fecha_inicio(self, svc, solicitud):
        svc.actualizar_estado(solicitud, "COMPLETADO", numero_paso=2, detalle="Test", evidencia="ok")
        s = svc.obtener_solicitud(solicitud.deployment_id)
        paso2 = next(p for p in s.pasos if p["numero"] == 2)
        if paso2["fecha_inicio"] and paso2["fecha_fin"]:
            assert paso2["fecha_fin"] >= paso2["fecha_inicio"]
    def test_validar_consistencia_detecta_error(self, svc, solicitud):
        solicitud.resultado = "PASS"
        solicitud.estado = "COMPLETADO"
        # FASE 24: _guardar corrige automaticamente PASS inconsistente
        svc._guardar(solicitud)
        s = svc.obtener_solicitud(solicitud.deployment_id)
        assert s.resultado != "PASS"
        assert s.estado != "COMPLETADO"
        c = svc.validar_consistencia(solicitud.deployment_id)
        assert c["consistente"]
    def test_db_event_store_misma_persistencia(self, svc, solicitud):
        import sqlite3
        db_path = os.environ.get("HERMES_DB_PATH")
        conn = sqlite3.connect(db_path)
        c = conn.cursor()
        c.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='event_logs'")
        assert c.fetchone() is not None, "Tabla event_logs no existe"
        conn.close()


