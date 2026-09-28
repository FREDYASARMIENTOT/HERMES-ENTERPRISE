# -*- coding: utf-8 -*-
"""
test_e2e_app_service_gestion.py — E2E: Creación, Deploy, Detención y Eliminación
================================================================================

Flujo completo:
    1. Crear proyecto Child vía POST /api/fabrica/proyectos
    2. Completar los 13 pasos canónicos vía API (simula Pipeline CI/CD)
    3. Finalizar proyecto como PASS con metadata requerida
    4. Verificar estado COMPLETADO con resultado PASS
    5. Detener App Service vía POST /fabrica/proyectos/{id}/detener-app (Azure mockeado)
    6. Verificar bitácora registra evento de detención
    7. Eliminar App Service vía POST /fabrica/proyectos/{id}/eliminar-app (Azure mockeado)
    8. Verificar bitácora registra evento de eliminación
    9. Verificar proyecto persiste en BD (GitHub) — no se borra al eliminar Azure
    10. Verificar reconciliación muestra App Service como NO_EXISTE

Ejecutar:
    pytest Hermes.Web/tests/test_e2e_app_service_gestion.py -v --timeout=60

Requiere: pytest, fastapi, httpx, unittest.mock
"""

import os, sys, json, sqlite3, tempfile, logging
from pathlib import Path
from unittest.mock import patch, MagicMock
from datetime import datetime, timezone

logging.disable(logging.CRITICAL)

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(_PROJECT_ROOT))

import pytest
from fastapi.testclient import TestClient
from Hermes.Web.backend.main import app
from Hermes.Web.backend.servicio_fabrica import (
    ServicioFabrica, SolicitudProyecto, obtener_servicio_fabrica,
    ESTADOS_PROYECTO, PASOS_CANONICOS, _generar_id, _instancia_servicio
)
from Hermes.Web.backend.servicio_azure import ServicioAzure

_ASP_VALIDO = (
    "/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/"
    "resourceGroups/RG-Hermes-Proyectos/"
    "providers/Microsoft.Web/serverfarms/ASP-HERMES-PORTAL"
)

_NOMBRE_PROYECTO = "hermes-e2e-gestion-test"
_PREFIX_WEBAPP = "as-hermes-e2e-gestion-test"


# =====================================================================
# Fixtures
# =====================================================================

@pytest.fixture(autouse=True)
def clean_db():
    """Cada test usa base de datos temporal aislada."""
    tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
    tmp.close()
    db_path = tmp.name
    old = os.environ.get("HERMES_DB_PATH")
    os.environ["HERMES_DB_PATH"] = db_path
    yield db_path
    os.environ.pop("HERMES_DB_PATH", None)
    if old:
        os.environ["HERMES_DB_PATH"] = old
    try:
        os.unlink(db_path)
    except PermissionError:
        pass


@pytest.fixture
def svc(clean_db):
    """ServicioFabrica con DB limpia y singleton reseteado."""
    global _instancia_servicio
    _instancia_servicio = None
    s = ServicioFabrica()
    _instancia_servicio = s
    return s


@pytest.fixture
def client(svc):
    """TestClient de FastAPI con servicio inyectado."""
    app.state.servicio_fabrica = svc
    return TestClient(app)


# =====================================================================
# Helpers
# =====================================================================

def _completar_pasos_api(client, deployment_id):
    """Completa los 13 pasos canónicos vía API como COMPLETADO."""
    for num in range(1, 14):
        r = client.post(
            f"/api/fabrica/proyectos/{deployment_id}/paso",
            json={
                "numero_paso": num,
                "estado_paso": "COMPLETADO",
                "detalle": f"Paso {num} completado (E2E test)",
                "evidencia": "e2e-test-evidence",
            },
        )
        assert r.status_code == 200, (
            f"Paso {num}: esperaba 200, obtuvo {r.status_code}: {r.text}"
        )


def _establecer_metadata_api(client, deployment_id):
    """Establece metadata requerida para PASS (anti-false-PASS FASE-24)."""
    r = client.put(
        f"/api/fabrica/proyectos/{deployment_id}/metadata",
        json={
            "control_plane_run_id": "e2e-cp-run-001",
            "control_plane_status": "COMPLETADO",
            "readiness_result": "PASS",
            "functional_result": "PASS",
            "commit_sha": "e2e" + "a" * 37,
        },
    )
    assert r.status_code == 200, (
        f"Metadata: esperaba 200, obtuvo {r.status_code}: {r.text}"
    )


def _finalizar_proyecto_api(client, deployment_id):
    """Finaliza el proyecto como PASS."""
    r = client.post(
        f"/api/fabrica/proyectos/{deployment_id}/finalizar",
        json={"resultado": "PASS"},
    )
    assert r.status_code == 200, (
        f"Finalizar: esperaba 200, obtuvo {r.status_code}: {r.text}"
    )
    data = r.json()
    assert data["resultado"] == "PASS"
    assert data["estado"] == "COMPLETADO"
    return data


def _crear_proyecto_y_obtener_id(client):
    """Crea proyecto vía API y devuelve deployment_id."""
    respuesta = client.post("/api/fabrica/proyectos", json={
        "nombre_proyecto": _NOMBRE_PROYECTO,
        "descripcion": "Proyecto E2E App Service Gestion",
        "app_service_plan_id": _ASP_VALIDO,
    })
    assert respuesta.status_code == 202
    return respuesta.json()["deployment_id"]


def _preparar_proyecto_completado(client, svc):
    """
    Helper: crear proyecto, completar 13 pasos, metadata, finalizar PASS.
    Retorna deployment_id.
    """
    deployment_id = _crear_proyecto_y_obtener_id(client)
    _completar_pasos_api(client, deployment_id)
    _establecer_metadata_api(client, deployment_id)
    _finalizar_proyecto_api(client, deployment_id)
    return deployment_id
# =====================================================================
# E2E Test Class
# =====================================================================

class TestE2EAppServiceGestion:
    """Prueba E2E completa: crear proyecto -> desplegar -> detener -> eliminar."""

    def test_01_crear_proyecto(self, client, svc, clean_db):
        """Crear proyecto Child vía API y verificar respuesta."""
        respuesta = client.post("/api/fabrica/proyectos", json={
            "nombre_proyecto": _NOMBRE_PROYECTO,
            "descripcion": "Proyecto E2E App Service Gestion",
            "app_service_plan_id": _ASP_VALIDO,
        })
        assert respuesta.status_code == 202
        data = respuesta.json()
        assert data["nombre_proyecto"] == _NOMBRE_PROYECTO
        assert data["deployment_id"]
        assert data["correlation_id"]
        assert data["estado"] == "SOLICITADO"
        assert "mensaje" in data
        solicitud = svc.obtener_solicitud(data["deployment_id"])
        assert solicitud is not None
        assert solicitud.web_app == _PREFIX_WEBAPP

    def test_02_completar_pasos_y_finalizar(self, client, svc, clean_db):
        """Completar pipeline (13 pasos) y finalizar como PASS."""
        did = _crear_proyecto_y_obtener_id(client)
        _completar_pasos_api(client, did)
        _establecer_metadata_api(client, did)
        resultado = _finalizar_proyecto_api(client, did)
# ---------------------------------------------------------------
    # PARTE 2: Detener App Service
    # ---------------------------------------------------------------

    def test_03_detener_app_service(self, client, svc, clean_db):
        """Detener App Service vía API con Azure mockeado."""
        did = _preparar_proyecto_completado(client, svc)
        mock_r = {"exito": True, "status": "DETENIDO", "status_code": 200,
                  "error": "", "web_app_name": _PREFIX_WEBAPP}
        with patch.object(ServicioAzure, "detener_web_app", return_value=mock_r) as md:
            r = client.post(f"/api/fabrica/proyectos/{did}/detener-app")
        assert r.status_code == 200
        data = r.json()
        assert data.get("exito") is True
        assert data.get("status") == "DETENIDO"
        md.assert_called_once()
        assert md.call_args.kwargs.get("web_app_name") == _PREFIX_WEBAPP
        evts = svc.obtener_eventos(did)
        assert any("DETENER" in json.dumps(e.get("detalle", "")) for e in evts)
        # Estado Azure sincronizado en BD (el Web App sigue existiendo, solo detenido)
        assert svc.obtener_solicitud(did).azure_resource_check_status == "EXISTE"

    def test_03b_detener_app_service_error(self, client, svc, clean_db):
        """Detener App Service con error 404."""
        did = _preparar_proyecto_completado(client, svc)
        mock_r = {"exito": False, "status": "NO_EXISTE", "status_code": 404,
                  "error": "no existe", "web_app_name": _PREFIX_WEBAPP}
        with patch.object(ServicioAzure, "detener_web_app", return_value=mock_r):
            r = client.post(f"/api/fabrica/proyectos/{did}/detener-app")
        assert r.status_code == 200
        assert r.json().get("status") == "NO_EXISTE"

    # ---------------------------------------------------------------
    # PARTE 3: Eliminar App Service
    # ---------------------------------------------------------------

    def test_04_eliminar_app_service(self, client, svc, clean_db):
        """Eliminar App Service vía API con Azure mockeado."""
        did = _preparar_proyecto_completado(client, svc)
        mock_r = {"exito": True, "status": "ELIMINADO", "status_code": 200,
                  "error": "", "web_app_name": _PREFIX_WEBAPP}
        with patch.object(ServicioAzure, "eliminar_web_app", return_value=mock_r) as me:
            r = client.post(f"/api/fabrica/proyectos/{did}/eliminar-app")
        assert r.status_code == 200
        data = r.json()
        assert data.get("exito") is True
        assert data.get("status") == "ELIMINADO"
        me.assert_called_once()
        assert me.call_args.kwargs.get("web_app_name") == _PREFIX_WEBAPP
        evts = svc.obtener_eventos(did)
        assert any("ELIMIN" in json.dumps(e.get("detalle", "")) for e in evts)
        # Estado Azure sincronizado en BD: el Web App ya no existe
        assert svc.obtener_solicitud(did).azure_resource_check_status == "NO_EXISTE"

    def test_04b_eliminar_app_service_error(self, client, svc, clean_db):
        """Eliminar App Service con error 403."""
        did = _preparar_proyecto_completado(client, svc)
        mock_r = {"exito": False, "status": "ERROR_PERMISOS", "status_code": 403,
                  "error": "permisos", "web_app_name": _PREFIX_WEBAPP}
        with patch.object(ServicioAzure, "eliminar_web_app", return_value=mock_r):
            r = client.post(f"/api/fabrica/proyectos/{did}/eliminar-app")
        assert r.status_code == 200
        assert r.json().get("status") == "ERROR_PERMISOS"
        # El proyecto sigue en BD con estado COMPLETADO
        s = svc.obtener_solicitud(did)
        assert s.estado == "COMPLETADO"
        assert s.resultado == "PASS"
# ---------------------------------------------------------------
    # PARTE 3.5: Iniciar App Service
    # ---------------------------------------------------------------

    def test_04c_iniciar_app_service(self, client, svc, clean_db):
        """Iniciar App Service via API con Azure mockeado."""
        did = _preparar_proyecto_completado(client, svc)
        mock_r = {"exito": True, "status": "INICIADO", "status_code": 200,
                  "error": "", "web_app_name": _PREFIX_WEBAPP}
        with patch.object(ServicioAzure, "iniciar_web_app", return_value=mock_r) as mi:
            r = client.post(f"/api/fabrica/proyectos/{did}/iniciar-app")
        assert r.status_code == 200
        data = r.json()
        assert data.get("exito") is True
        assert data.get("status") == "INICIADO"
        mi.assert_called_once()
        assert mi.call_args.kwargs.get("web_app_name") == _PREFIX_WEBAPP
        evts = svc.obtener_eventos(did)
        assert any("INICIAR" in json.dumps(e.get("detalle", "")) for e in evts)
        assert svc.obtener_solicitud(did).azure_resource_check_status == "EXISTE"

    def test_04d_iniciar_app_service_error(self, client, svc, clean_db):
        """Iniciar App Service con error 404."""
        did = _preparar_proyecto_completado(client, svc)
        mock_r = {"exito": False, "status": "NO_EXISTE", "status_code": 404,
                  "error": "no existe", "web_app_name": _PREFIX_WEBAPP}
        with patch.object(ServicioAzure, "iniciar_web_app", return_value=mock_r):
            r = client.post(f"/api/fabrica/proyectos/{did}/iniciar-app")
        assert r.status_code == 200
        assert r.json().get("exito") is False
        assert r.json().get("status") == "NO_EXISTE"

# ---------------------------------------------------------------
    # PARTE 4: Persistencia del proyecto en BD (GitHub)
    # ---------------------------------------------------------------

    def test_05_proyecto_persiste_despues_de_eliminar_azure(self, client, svc, clean_db):
        """Proyecto debe persistir en BD tras eliminar App Service."""
        did = _preparar_proyecto_completado(client, svc)
        with patch.object(ServicioAzure, "eliminar_web_app",
                return_value={"exito": True, "status": "ELIMINADO",
                              "status_code": 200, "error": "",
                              "web_app_name": _PREFIX_WEBAPP}):
            client.post(f"/api/fabrica/proyectos/{did}/eliminar-app")
        s = svc.obtener_solicitud(did)
        assert s is not None
        assert s.nombre_proyecto == _NOMBRE_PROYECTO
        assert s.estado == "COMPLETADO"
        assert s.resultado == "PASS"
        assert s.repositorio != ""
        assert "FREDYASARMIENTOT" in s.repositorio

    def test_06_historial_incluye_proyecto(self, client, svc, clean_db):
        """Historial incluye proyecto tras detener/eliminar."""
        did = _preparar_proyecto_completado(client, svc)
        with patch.object(ServicioAzure, "detener_web_app",
                return_value={"exito": True, "status": "DETENIDO",
                              "status_code": 200, "error": "",
                              "web_app_name": _PREFIX_WEBAPP}):
            client.post(f"/api/fabrica/proyectos/{did}/detener-app")
        with patch.object(ServicioAzure, "eliminar_web_app",
                return_value={"exito": True, "status": "ELIMINADO",
                              "status_code": 200, "error": "",
                              "web_app_name": _PREFIX_WEBAPP}):
            client.post(f"/api/fabrica/proyectos/{did}/eliminar-app")
        r = client.get("/api/fabrica/proyectos/historial?limit=10")
        assert r.status_code == 200
        deploys = [p["deployment_id"] for p in r.json()["proyectos"]]
        assert did in deploys

    # ---------------------------------------------------------------
    # PARTE 5: Reconciliación Azure
    # ---------------------------------------------------------------

    def test_07_reconciliacion_refleja_eliminacion(self, client, svc, clean_db):
        """Reconciliación refleja NO_EXISTE tras eliminar."""
        did = _preparar_proyecto_completado(client, svc)
        with patch.object(ServicioAzure, "eliminar_web_app",
                return_value={"exito": True, "status": "ELIMINADO",
                              "status_code": 200, "error": "",
                              "web_app_name": _PREFIX_WEBAPP}):
            client.post(f"/api/fabrica/proyectos/{did}/eliminar-app")
        mock_v = {"exists": False, "status_code": 404, "status": "NO_EXISTE",
                  "error": "", "resource_id": "", "hostname": "",
                  "checked_at": datetime.now(timezone.utc).isoformat()}
        with patch.object(ServicioAzure, "verificar_existencia_web_app",
                          return_value=mock_v):
            r = svc.verificar_y_actualizar_estado_azure(did)
        assert r["status"] == "NO_EXISTE"
        assert r["exists"] is False
        s = svc.obtener_solicitud(did)
        assert s.azure_resource_check_status == "NO_EXISTE"

    # ---------------------------------------------------------------
    # PARTE 6: Frontend
    # ---------------------------------------------------------------

    def test_08_frontend_tiene_botones_gestion(self):
        """proyecto.html tiene botones Detener/Eliminar y modales."""
        html = Path(_PROJECT_ROOT, "Hermes.Web", "templates",
                    "proyecto.html").read_text(encoding="utf-8")
        for token in ["btn-detener", "btn-eliminar", "confirmarDetenerAppService",
                       "confirmarEliminarAppService", "confirmacionModal",
                       "progresoModal", "ejecutarAccionConfirmada",
                       "detener-app", "eliminar-app"]:
            assert token in html, f"Falta: {token}"
        lower = html.lower()
        for sec in ["ghp_", "gho_", "pat_", "authorization", "bearer"]:
            assert sec not in lower, f"Secreto: {sec}"

    def test_08b_portal_index_tiene_botones_gestion(self):
        """index.html (portal) expone botones Iniciar/Detener/Eliminar App Service."""
        html = Path(_PROJECT_ROOT, "Hermes.Web", "templates",
                    "index.html").read_text(encoding="utf-8")
        for token in ["btn-iniciar", "btn-detener", "btn-eliminar",
                      "gestion-btn", "confirmarGestionAppService",
                      "ejecutarGestionAppService", "gestionModal",
                      "gestionProgreso", "gestion-resultado",
                      "iniciar-app", "detener-app", "eliminar-app"]:
            assert token in html, f"Falta: {token}"
        lower = html.lower()
        for sec in ["ghp_", "gho_", "pat_", "authorization", "bearer"]:
            assert sec not in lower, f"Secreto: {sec}"
# =====================================================================
# Pruebas de integración de servicios (sin API)
# =====================================================================

class TestServicioAzureMockeado:
    """Pruebas directas al servicio con Azure mockeado."""

    @pytest.fixture(autouse=True)
    def setup(self, clean_db):
        self.svc = ServicioFabrica()
        global _instancia_servicio
        _instancia_servicio = self.svc

    def test_detener_app_service_desde_servicio(self):
        """servicio_fabrica.detener_app_service con Azure mock."""
        sol = self.svc.crear_solicitud("hermes-e2e-direct", descripcion="Direct",
                                        app_service_plan_id=_ASP_VALIDO)
        did = sol.deployment_id
        mr = {"exito": True, "status": "DETENIDO", "status_code": 200,
              "error": "", "web_app_name": sol.web_app}
        with patch.object(ServicioAzure, "detener_web_app", return_value=mr):
            r = self.svc.detener_app_service(did)
        assert r["exito"] is True
        assert r["status"] == "DETENIDO"
        assert r["project_name"] == "hermes-e2e-direct"
        evts = self.svc.obtener_eventos(did)
        assert any("DETENER" in json.dumps(e.get("detalle", "")) for e in evts)

    def test_eliminar_app_service_desde_servicio(self):
        """servicio_fabrica.eliminar_app_service con Azure mock."""
        sol = self.svc.crear_solicitud("hermes-e2e-direct-elim",
                                        descripcion="Direct elim",
                                        app_service_plan_id=_ASP_VALIDO)
        did = sol.deployment_id
        mr = {"exito": True, "status": "ELIMINADO", "status_code": 200,
              "error": "", "web_app_name": sol.web_app}
        with patch.object(ServicioAzure, "eliminar_web_app", return_value=mr):
            r = self.svc.eliminar_app_service(did)
        assert r["exito"] is True
        assert r["status"] == "ELIMINADO"
        assert r["project_name"] == "hermes-e2e-direct-elim"
        evts = self.svc.obtener_eventos(did)
        assert any("ELIMIN" in json.dumps(e.get("detalle", "")) for e in evts)

    def test_detener_app_service_con_404(self):
        """detener_app_service cuando Azure devuelve 404 (no existe)."""
        sol = self.svc.crear_solicitud("hermes-e2e-404", descripcion="404 test",
                                        app_service_plan_id=_ASP_VALIDO)
        did = sol.deployment_id
        mr = {"exito": False, "status": "NO_EXISTE", "status_code": 404,
              "error": f"Web App {sol.web_app} no existe en Azure",
              "web_app_name": sol.web_app}
        with patch.object(ServicioAzure, "detener_web_app", return_value=mr):
            r = self.svc.detener_app_service(did)
        assert r.get("exito") is False
        assert r.get("status") == "NO_EXISTE"

    def test_eliminar_app_service_con_404(self):
        """eliminar_app_service cuando Azure devuelve 404 (ya eliminado)."""
        sol = self.svc.crear_solicitud("hermes-e2e-404-del",
                                        descripcion="404 del test",
                                        app_service_plan_id=_ASP_VALIDO)
        did = sol.deployment_id
        mr = {"exito": False, "status": "NO_EXISTE", "status_code": 404,
              "error": f"Web App {sol.web_app} no existe en Azure",
              "web_app_name": sol.web_app}
        with patch.object(ServicioAzure, "eliminar_web_app", return_value=mr):
            r = self.svc.eliminar_app_service(did)
        assert r.get("exito") is False
        assert r.get("status") == "NO_EXISTE"

    def test_detener_deployment_inexistente(self):
        """detener_app_service con deployment_id que no existe."""
        r = self.svc.detener_app_service("NONEXISTENT1234")
        assert r.get("exito") is False
        assert "no encontrado" in r.get("error", "").lower()

    def test_eliminar_deployment_inexistente(self):
        """eliminar_app_service con deployment_id que no existe."""
        r = self.svc.eliminar_app_service("NONEXISTENT5678")
        assert r.get("exito") is False
        assert "no encontrado" in r.get("error", "").lower()

    def test_iniciar_app_service_desde_servicio(self):
        """servicio_fabrica.iniciar_app_service con Azure mock."""
        sol = self.svc.crear_solicitud("hermes-e2e-direct-start",
                                        descripcion="Direct start",
                                        app_service_plan_id=_ASP_VALIDO)
        did = sol.deployment_id
        mr = {"exito": True, "status": "INICIADO", "status_code": 200,
              "error": "", "web_app_name": sol.web_app}
        with patch.object(ServicioAzure, "iniciar_web_app", return_value=mr):
            r = self.svc.iniciar_app_service(did)
        assert r["exito"] is True
        assert r["status"] == "INICIADO"
        assert r["project_name"] == "hermes-e2e-direct-start"
        evts = self.svc.obtener_eventos(did)
        assert any("INICIAR" in json.dumps(e.get("detalle", "")) for e in evts)

    def test_iniciar_app_service_con_404(self):
        """iniciar_app_service cuando Azure devuelve 404 (no existe)."""
        sol = self.svc.crear_solicitud("hermes-e2e-404-start",
                                        descripcion="404 start test",
                                        app_service_plan_id=_ASP_VALIDO)
        did = sol.deployment_id
        mr = {"exito": False, "status": "NO_EXISTE", "status_code": 404,
              "error": f"Web App {sol.web_app} no existe en Azure",
              "web_app_name": sol.web_app}
        with patch.object(ServicioAzure, "iniciar_web_app", return_value=mr):
            r = self.svc.iniciar_app_service(did)
        assert r.get("exito") is False
        assert r.get("status") == "NO_EXISTE"

    def test_iniciar_deployment_inexistente(self):
        """iniciar_app_service con deployment_id que no existe."""
        r = self.svc.iniciar_app_service("NONEXISTENT9012")
        assert r.get("exito") is False
        assert "no encontrado" in r.get("error", "").lower()
# =====================================================================
# Pruebas de bitácora (eventos de gestión)
# =====================================================================

class TestBitacoraEventosGestion:
    """Verificar que los eventos de gestión quedan registrados correctamente."""

    @pytest.fixture(autouse=True)
    def setup(self, clean_db):
        self.svc = ServicioFabrica()
        global _instancia_servicio
        _instancia_servicio = self.svc
        self.sol = self.svc.crear_solicitud("hermes-e2e-bit-test",
                                             descripcion="Bitacora test",
                                             app_service_plan_id=_ASP_VALIDO)
        self.did = self.sol.deployment_id

    def test_evento_detener_tiene_fase_gestion(self):
        """Evento detener tiene fase=GESTION y componente=AZURE."""
        mr = {"exito": True, "status": "DETENIDO", "status_code": 200,
              "error": "", "web_app_name": self.sol.web_app}
        with patch.object(ServicioAzure, "detener_web_app", return_value=mr):
            self.svc.detener_app_service(self.did)
        evts = self.svc.obtener_eventos(self.did)
        hit = [e for e in evts if e.get("fase") == "GESTION"
               and e.get("componente") == "AZURE"
               and "DETENER" in json.dumps(e.get("detalle", ""))]
        assert len(hit) >= 1
        assert hit[0].get("tipo") == "INFO"

    def test_evento_eliminar_tiene_fase_gestion(self):
        """Evento eliminar tiene fase=GESTION y componente=AZURE."""
        mr = {"exito": True, "status": "ELIMINADO", "status_code": 200,
              "error": "", "web_app_name": self.sol.web_app}
        with patch.object(ServicioAzure, "eliminar_web_app", return_value=mr):
            self.svc.eliminar_app_service(self.did)
        evts = self.svc.obtener_eventos(self.did)
        hit = [e for e in evts if e.get("fase") == "GESTION"
               and e.get("componente") == "AZURE"
               and "ELIMIN" in json.dumps(e.get("detalle", ""))]
        assert len(hit) >= 1
        assert hit[0].get("tipo") == "INFO"

    def test_evento_error_detener_tipo_error(self):
        """Evento error al detener tiene tipo=ERROR."""
        mr = {"exito": False, "status": "ERROR_PERMISOS", "status_code": 403,
              "error": "Azure ARM 403", "web_app_name": self.sol.web_app}
        with patch.object(ServicioAzure, "detener_web_app", return_value=mr):
            self.svc.detener_app_service(self.did)
        evts = self.svc.obtener_eventos(self.did)
        hit = [e for e in evts if e.get("tipo") == "ERROR"
               and e.get("componente") == "AZURE"]
        assert len(hit) >= 1
        assert "Error deteniendo" in hit[0].get("mensaje", "")

    def test_evento_iniciar_tiene_fase_gestion(self):
        """Evento iniciar tiene fase=GESTION y componente=AZURE."""
        mr = {"exito": True, "status": "INICIADO", "status_code": 200,
              "error": "", "web_app_name": self.sol.web_app}
        with patch.object(ServicioAzure, "iniciar_web_app", return_value=mr):
            self.svc.iniciar_app_service(self.did)
        evts = self.svc.obtener_eventos(self.did)
        hit = [e for e in evts if e.get("fase") == "GESTION"
               and e.get("componente") == "AZURE"
               and "INICIAR" in json.dumps(e.get("detalle", ""))]
        assert len(hit) >= 1
        assert hit[0].get("tipo") == "INFO"

    def test_evento_error_iniciar_tipo_error(self):
        """Evento error al iniciar tiene tipo=ERROR."""
        mr = {"exito": False, "status": "ERROR_PERMISOS", "status_code": 403,
              "error": "Azure ARM 403", "web_app_name": self.sol.web_app}
        with patch.object(ServicioAzure, "iniciar_web_app", return_value=mr):
            self.svc.iniciar_app_service(self.did)
        evts = self.svc.obtener_eventos(self.did)
        hit = [e for e in evts if e.get("tipo") == "ERROR"
               and e.get("componente") == "AZURE"]
        assert len(hit) >= 1
        assert "Error iniciando" in hit[0].get("mensaje", "")
# =====================================================================
# Pruebas de API endpoints (errores y casos borde)
# =====================================================================

class TestAPIEndpointsGestion:
    """Pruebas de bordes de los endpoints de gestión."""

    @pytest.fixture(autouse=True)
    def setup(self, clean_db):
        global _instancia_servicio
        _instancia_servicio = None
        self.svc = ServicioFabrica()
        _instancia_servicio = self.svc
        app.state.servicio_fabrica = self.svc
        self.client = TestClient(app)

    def test_detener_proyecto_inexistente(self):
        """Error al detener deployment que no existe."""
        r = self.client.post("/api/fabrica/proyectos/ID_INEXISTENTE/detener-app")
        assert r.status_code == 200
        assert r.json().get("exito") is False
        assert "no encontrado" in r.json().get("error", "").lower()

    def test_eliminar_proyecto_inexistente(self):
        """Error al eliminar deployment que no existe."""
        r = self.client.post("/api/fabrica/proyectos/ID_INEXISTENTE/eliminar-app")
        assert r.status_code == 200
        assert r.json().get("exito") is False
        assert "no encontrado" in r.json().get("error", "").lower()

    def test_detener_method_not_allowed(self):
        """GET a /detener-app debe fallar (solo POST)."""
        r = self.client.get("/api/fabrica/proyectos/ID_TEST/detener-app")
        assert r.status_code in (405, 404)

    def test_eliminar_method_not_allowed(self):
        """GET a /eliminar-app debe fallar (solo POST)."""
        r = self.client.get("/api/fabrica/proyectos/ID_TEST/eliminar-app")
        assert r.status_code in (405, 404)

    def test_iniciar_proyecto_inexistente(self):
        """Error al iniciar deployment que no existe."""
        r = self.client.post("/api/fabrica/proyectos/ID_INEXISTENTE/iniciar-app")
        assert r.status_code == 200
        assert r.json().get("exito") is False
        assert "no encontrado" in r.json().get("error", "").lower()

    def test_iniciar_method_not_allowed(self):
        """GET a /iniciar-app debe fallar (solo POST)."""
        r = self.client.get("/api/fabrica/proyectos/ID_TEST/iniciar-app")
        assert r.status_code in (405, 404)

    def test_openapi_incluye_endpoints_gestion(self):
        """OpenAPI spec incluye /iniciar-app, /detener-app y /eliminar-app."""
        r = self.client.get("/openapi.json")
        assert r.status_code == 200
        paths = r.json().get("paths", {})
        assert "/api/fabrica/proyectos/{deployment_id}/iniciar-app" in paths
        assert "/api/fabrica/proyectos/{deployment_id}/detener-app" in paths
        assert "/api/fabrica/proyectos/{deployment_id}/eliminar-app" in paths


if __name__ == "__main__":
    pytest.main([__file__, "-v", "--tb=short"])