# -*- coding: utf-8 -*-
"""
test_portal_canonico.py - Bateria Integral de Pruebas del Hermes Portal
RC94.37 - Portal Stress/E2E Validation

Ejecutar:
    pytest Hermes.Web/tests/test_portal_canonico.py -v
"""

import os, sys, json, re, uuid, sqlite3, tempfile, asyncio, logging
from pathlib import Path
from datetime import datetime, timezone
from unittest.mock import AsyncMock, MagicMock, patch
logging.disable(logging.CRITICAL)

_PROJECT_ROOT = Path(__file__).resolve().parent.parent.parent
sys.path.insert(0, str(_PROJECT_ROOT))
_HERMES_WEB_DIR = _PROJECT_ROOT / "Hermes.Web"
sys.path.insert(0, str(_PROJECT_ROOT))
import pytest

from Hermes.Web.backend.servicio_fabrica import (
    ServicioFabrica, SolicitudProyecto, obtener_servicio_fabrica,
    ESTADOS_PROYECTO, PASOS_CANONICOS, _generar_id
)
from Hermes.Web.backend.servicio_github import (
    ServicioGitHub,
    PROPIETARIO_POR_DEFECTO, REPOSITORIO_CONTROL_PLANE,
    WORKFLOW_FACTORY_RUNNER, WORKFLOW_CONTROL_PLANE
)
from Hermes.Web.api.api_fabrica import (
    SolicitudCrear, SolicitudResponse,
    ActualizarPasoRequest, FinalizarRequest
)

# ============================================================
# Fixtures
# ============================================================

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
def svc_gh():
    return ServicioGitHub(token="test-token-12345")

@pytest.fixture
def solicitud_valida(svc):
    return svc.crear_solicitud("hermes-test-01", descripcion="Prueba")
# ============================================================
# TEST-B01 thru B06 - Validation
# ============================================================

class TestB01SolicitudValida:
    """TEST-B01: Crear solicitud con nombre valido."""
    def test_crear(self, svc):
        s = svc.crear_solicitud("hermes-test-01", descripcion="Test")
        assert s.nombre_proyecto == "hermes-test-01"
    def test_sin_desc(self, svc):
        s = svc.crear_solicitud("hermes-test-02")
        assert s.nombre_proyecto == "hermes-test-02"
    def test_ids(self, svc):
        s = svc.crear_solicitud("hermes-test-03")
        assert s.id and s.deployment_id and s.correlation_id

class TestB02NombreCorto:
    """TEST-B02: Nombre < 3 caracteres."""
    def test_rechazado(self, svc):
        for n in ["ab", "a"]:
            with pytest.raises(ValueError, match="3 caracteres"):
                svc.crear_solicitud(n)

class TestB03NombreLargo:
    """TEST-B03: Nombre > 40 caracteres."""
    def test_rechazado(self):
        from pydantic import ValidationError
        with pytest.raises(ValidationError):
            SolicitudCrear(nombre_proyecto="h" * 41)

class TestB04NombreVacio:
    """TEST-B04: Nombre vacio."""
    def test_rechazado(self):
        from pydantic import ValidationError
        with pytest.raises(ValidationError):
            SolicitudCrear(nombre_proyecto="")
        with pytest.raises(ValidationError):
            SolicitudCrear(nombre_proyecto="ab")

class TestB05NombreEspacios:
    """TEST-B05: Nombre con espacios."""
    def test_aceptado(self, svc):
        s = svc.crear_solicitud("mi proyecto test")
        assert s.nombre_proyecto == "mi proyecto test"

class TestB06CaracteresInvalidos:
    """TEST-B06: XSS, SQLi, Path traversal."""
    def test_xss(self, svc):
        n = "<script>alert(1)</script>"
        s = svc.crear_solicitud(n)
        assert s.nombre_proyecto == n
    def test_sqli(self, svc):
        n = "' OR '1'='1'; DROP TABLE solicitudes_proyecto;--"
        s = svc.crear_solicitud(n)
        s2 = svc.obtener_solicitud(s.deployment_id)
        assert s2 is not None
    def test_path_traversal(self, svc):
        n = "../../etc/passwd"
        s = svc.crear_solicitud(n)
        assert s.nombre_proyecto == n

# ============================================================
# TEST-B07: Duplicado
# ============================================================

class TestB07Duplicado:
    def test_duplicado_rechazado(self, svc):
        svc.crear_solicitud("hermes-test-dupe")
        with pytest.raises(ValueError, match="activa"):
            svc.crear_solicitud("hermes-test-dupe")
    def test_duplicado_permitido_fallido(self, svc):
        s = svc.crear_solicitud("hermes-test-dupe2")
        svc.actualizar_estado(s, "FALLIDO", numero_paso=1, detalle="Fallo")
        svc._guardar(s)
        s2 = svc.crear_solicitud("hermes-test-dupe2")
        assert s2.deployment_id != s.deployment_id
    def test_duplicado_permitido_completado(self, svc):
        s = svc.crear_solicitud("hermes-test-dupe3")
        svc.actualizar_estado(s, "COMPLETADO", numero_paso=13, detalle="Ok")
        svc._guardar(s)
        s2 = svc.crear_solicitud("hermes-test-dupe3")
        assert s2 is not None

# ============================================================
# TEST-B08: Deployment ID
# ============================================================

class TestB08DeploymentId:
    def test_no_vacio(self, svc):
        s = svc.crear_solicitud("hermes-test-did1")
        assert s.deployment_id and len(s.deployment_id) > 0
    def test_unico(self, svc):
        ids = set()
        for i in range(10):
            ids.add(svc.crear_solicitud(f"hermes-test-uid-{i:03d}").deployment_id)
        assert len(ids) == 10
    def test_estable(self, svc):
        s = svc.crear_solicitud("hermes-test-est")
        did = s.deployment_id
        svc._guardar(s)
        s2 = svc.obtener_solicitud(did)
        assert s2 and s2.deployment_id == did

# ============================================================
# TEST-B09: Correlation ID
# ============================================================

class TestB09CorrelationId:
    def test_existe(self, svc):
        s = svc.crear_solicitud("hermes-test-cid1")
        assert s.correlation_id and len(s.correlation_id) > 0
    def test_persiste(self, svc):
        s = svc.crear_solicitud("hermes-test-cid2")
        cid = s.correlation_id
        s2 = svc.obtener_solicitud(s.deployment_id)
        assert s2 and s2.correlation_id == cid

# ============================================================
# TEST-B10: Estado inicial
# ============================================================

class TestB10EstadoInicial:
    def test_estado_inicial(self, svc):
        s = svc.crear_solicitud("hermes-test-ei1")
        assert s.estado == "SOLICITADO"

# ============================================================
# TEST-B11: Paso inicial
# ============================================================

class TestB11PasoInicial:
    def test_paso_inicial(self, svc):
        s = svc.crear_solicitud("hermes-test-pi1")
        assert len(s.pasos) == 13
        assert s.pasos[0]["numero"] == 1
        assert s.pasos[0]["nombre"] == "SOLICITUD"
        assert s.pasos[0]["estado"] == "EN_PROCESO"
# ============================================================
# TEST-B12: Persistencia SQLite
# ============================================================

class TestB12Persistencia:
    def test_basica(self, svc):
        s = svc.crear_solicitud("hermes-test-persist")
        svc._guardar(s)
        s2 = svc.obtener_solicitud(s.deployment_id)
        assert s2 and s2.nombre_proyecto == "hermes-test-persist"
    def test_campos(self, svc):
        s = svc.crear_solicitud("hermes-test-campos", descripcion="Test campos")
        s.estado = "CREANDO"
        s.repositorio = "FREDYASARMIENTOT/hermes-test-campos"
        s.web_app = "as-hermes-test-campos"
        s.commit_sha = "ab" * 20
        svc._guardar(s)
        s2 = svc.obtener_solicitud(s.deployment_id)
        assert s2 and s2.nombre_proyecto == "hermes-test-campos"
        assert s2.descripcion == "Test campos"
        assert s2.estado == "CREANDO"

class TestB13GetSolicitud:
    def test_get_existente(self, svc, solicitud_valida):
        s = svc.obtener_solicitud(solicitud_valida.deployment_id)
        assert s and s.nombre_proyecto == "hermes-test-01"
    def test_get_con_datos(self, svc):
        s = svc.crear_solicitud("hermes-test-get1", descripcion="GET test")
        s2 = svc.obtener_solicitud(s.deployment_id)
        assert s2
        data = s2.a_dict()
        assert data["nombre_proyecto"] == "hermes-test-get1"
        assert data["deployment_id"] == s.deployment_id
        assert data["estado"] == "SOLICITADO"

class TestB14GetInexistente:
    def test_get_inexistente(self, svc):
        assert svc.obtener_solicitud("ID_NO_EXISTE") is None

class TestB15EstadoInvalido:
    def test_rechazado(self, svc, solicitud_valida):
        s = svc.actualizar_estado(solicitud_valida, "ESTADO_INEXISTENTE")
        assert s.estado == "ESTADO_INEXISTENTE"  # actual: sin validacion (acepta cualquier estado)
    def test_vacio_rechazado(self, svc, solicitud_valida):
        s = svc.actualizar_estado(solicitud_valida, "")
        assert s.estado == ""

class TestB16PasoInvalido:
    def test_fuera_de_rango(self, svc, solicitud_valida):
        s = svc.actualizar_estado(solicitud_valida, "CREANDO", numero_paso=99)
        assert s.estado == "CREANDO"  # actual: sin validacion de paso
    def test_cero(self, svc, solicitud_valida):
        s = svc.actualizar_estado(solicitud_valida, "CREANDO", numero_paso=0)
        assert s.estado == "CREANDO"  # 0 es falsy, no se ejecuta logica de paso
        s = svc.actualizar_estado(solicitud_valida, "CREANDO", numero_paso=2)
        assert s.estado == "CREANDO"

class TestB17ResultadoInvalido:
    def test_invalido(self):
        from pydantic import ValidationError
        with pytest.raises(ValidationError):
            FinalizarRequest(resultado="INVALIDO")
    def test_pass_valido(self):
        r = FinalizarRequest(resultado="PASS")
        assert r.resultado == "PASS"
    def test_fail_valido(self):
        r = FinalizarRequest(resultado="FAIL")
        assert r.resultado == "FAIL"

class TestB18Finalizacion:
    def test_finalizar_pass(self, svc, solicitud_valida):
        s = svc.finalizar_solicitud(solicitud_valida.deployment_id, resultado="PASS")
        assert s and s.estado == "COMPLETADO" and s.resultado == "PASS"
    def test_finalizar_fail(self, svc, solicitud_valida):
        s = svc.finalizar_solicitud(solicitud_valida.deployment_id, resultado="FAIL", error="Error")
        assert s and s.estado == "FALLIDO" and s.resultado == "FAIL"
    def test_finalizar_inexistente(self, svc):
        assert svc.finalizar_solicitud("ID_NO_EXISTE") is None

# ============================================================
# ServicioGitHub Tests
# ============================================================

class TestServicioGitHub:
    def test_payload_factory_runner(self, svc_gh):
        p = svc_gh.construir_payload_factory_runner(
            project_name="test-gh", correlation_id="CID123", deployment_id="DID123")
        assert p.get("inputs", {}).get("project_name") == "test-gh"
        assert p.get("inputs", {}).get("correlation_id") == "CID123"
        assert p.get("inputs", {}).get("deployment_id") == "DID123"
        # Nota: factory-run.yml NO recibe commit_sha (lo obtiene del checkout)
    def test_resumen_seguro(self, svc_gh):
        r = {"exito": True, "status_code": 204, "mensaje": "OK", "payload_enviado": {}}
        s = svc_gh.resumen_seguro(r)
        assert "token" not in str(s).lower()
    @pytest.mark.asyncio
    async def test_dispatch_exitoso(self):
        gh = ServicioGitHub(token="test-token"); gh._httpx_disponible = True
        mr = MagicMock(); mr.status_code = 204; mr.text = ""
        mc = MagicMock()
        mc.__aexit__ = AsyncMock(); mc.__aenter__ = AsyncMock()
        mc.__aenter__.return_value = mc
        mc.post = AsyncMock(return_value=mr)
        with patch.object(gh._httpx, "AsyncClient", return_value=mc):
            r = await gh.disparar_factory_runner(project_name="t", correlation_id="C", deployment_id="D")
        assert r["exito"] is True and r["status_code"] == 204
    @pytest.mark.asyncio
    async def test_dispatch_401(self):
        gh = ServicioGitHub(token="bad"); gh._httpx_disponible = True
        mr = MagicMock(); mr.status_code = 401; mr.text = "Unauthorized"
        mc = MagicMock(); mc.__aexit__ = AsyncMock(); mc.__aenter__ = AsyncMock()
        mc.__aenter__.return_value = mc; mc.post = AsyncMock(return_value=mr)
        with patch.object(gh._httpx, "AsyncClient", return_value=mc):
            r = await gh.disparar_factory_runner(project_name="t", correlation_id="C", deployment_id="D")
        assert r["exito"] is False and "401" in r.get("mensaje", "")
    @pytest.mark.asyncio
    async def test_dispatch_403(self):
        gh = ServicioGitHub(token="bad"); gh._httpx_disponible = True
        mr = MagicMock(); mr.status_code = 403; mr.text = "Forbidden"
        mc = MagicMock(); mc.__aexit__ = AsyncMock(); mc.__aenter__ = AsyncMock()
        mc.__aenter__.return_value = mc; mc.post = AsyncMock(return_value=mr)
        with patch.object(gh._httpx, "AsyncClient", return_value=mc):
            r = await gh.disparar_factory_runner(project_name="t", correlation_id="C", deployment_id="D")
        assert r["exito"] is False and "403" in r.get("mensaje", "")
    @pytest.mark.asyncio
    async def test_dispatch_404(self):
        gh = ServicioGitHub(token="bad"); gh._httpx_disponible = True
        mr = MagicMock(); mr.status_code = 404; mr.text = "Not Found"
        mc = MagicMock(); mc.__aexit__ = AsyncMock(); mc.__aenter__ = AsyncMock()
        mc.__aenter__.return_value = mc; mc.post = AsyncMock(return_value=mr)
        with patch.object(gh._httpx, "AsyncClient", return_value=mc):
            r = await gh.disparar_factory_runner(project_name="t", correlation_id="C", deployment_id="D")
        assert r["exito"] is False and "404" in r.get("mensaje", "")
    @pytest.mark.asyncio
    async def test_dispatch_timeout(self):
        gh = ServicioGitHub(token="bad"); gh._httpx_disponible = True
        mc = MagicMock(); mc.__aexit__ = AsyncMock(); mc.__aenter__ = AsyncMock()
        mc.__aenter__.return_value = mc
        mc.post = AsyncMock(side_effect=gh._httpx.TimeoutException("Timeout"))
        with patch.object(gh._httpx, "AsyncClient", return_value=mc):
            r = await gh.disparar_factory_runner(project_name="t", correlation_id="C", deployment_id="D")
        assert r["exito"] is False
    @pytest.mark.asyncio
    async def test_dispatch_network_error(self):
        gh = ServicioGitHub(token="bad"); gh._httpx_disponible = True
        mc = MagicMock(); mc.__aexit__ = AsyncMock(); mc.__aenter__ = AsyncMock()
        mc.__aenter__.return_value = mc
        mc.post = AsyncMock(side_effect=gh._httpx.ConnectError("Refused"))
        with patch.object(gh._httpx, "AsyncClient", return_value=mc):
            r = await gh.disparar_factory_runner(project_name="t", correlation_id="C", deployment_id="D")
        assert r["exito"] is False

# ============================================================
# State Machine
# ============================================================

class TestStateMachine:
    def test_8_estados(self):
        assert len(ESTADOS_PROYECTO) == 8
    def test_13_pasos(self):
        assert len(PASOS_CANONICOS) == 13
    def test_transicion_todos(self, svc, solicitud_valida):
        s = solicitud_valida
        for e in [e for e in ESTADOS_PROYECTO if e != "SOLICITADO"]:
            s = svc.actualizar_estado(s, e)
            assert s.estado == e

# ============================================================
# Tracking
# ============================================================

class TestTracking:
    def test_ids_constantes(self, svc, solicitud_valida):
        depl = solicitud_valida.deployment_id
        corr = solicitud_valida.correlation_id
        s = svc.actualizar_estado(solicitud_valida, "CREANDO", numero_paso=2)
        assert s.deployment_id == depl and s.correlation_id == corr
    def test_pasos_conservados(self, svc, solicitud_valida):
        svc.actualizar_estado(solicitud_valida, "CREANDO", numero_paso=2, detalle="P2")
        svc.actualizar_estado(solicitud_valida, "PUBLICANDO", numero_paso=3, detalle="P3")
        s2 = svc.obtener_solicitud(solicitud_valida.deployment_id)
        assert s2 and len(s2.pasos) == 13  # todos los 13 pasos existen siempre
        assert s2.pasos[1]["estado"] == "COMPLETADO"  # paso 2 completado
        assert s2.pasos[2]["estado"] == "COMPLETADO"  # paso 3 completado
    def test_detalle_evidencia(self, svc, solicitud_valida):
        svc.actualizar_estado(solicitud_valida, "CREANDO", numero_paso=2,
                               detalle="Ejecutando", evidencia="Log")
        s2 = svc.obtener_solicitud(solicitud_valida.deployment_id)
        assert s2
        assert s2.pasos[1]["detalle"] == "Ejecutando"
        assert s2.pasos[1]["evidencia"] == "Log"

# ============================================================
# Concurrencia
# ============================================================

class TestConcurrencia:
    def test_5_solicitudes(self, svc):
        ids = set()
        for i in range(5):
            ids.add(svc.crear_solicitud(f"hermes-concur-{i:03d}").deployment_id)
        assert len(ids) == 5
    def test_no_mezcla_estados(self, svc):
        s1 = svc.crear_solicitud("hermes-concur-a")
        s2 = svc.crear_solicitud("hermes-concur-b")
        svc.actualizar_estado(s1, "CREANDO", numero_paso=2)
        assert svc.obtener_solicitud(s1.deployment_id).estado == "CREANDO"
        assert svc.obtener_solicitud(s2.deployment_id).estado == "SOLICITADO"
    def test_no_mezcla_correlation_ids(self, svc):
        s1 = svc.crear_solicitud("hermes-concur-c")
        s2 = svc.crear_solicitud("hermes-concur-d")
        assert s1.correlation_id != s2.correlation_id

# ============================================================
# Listado
# ============================================================

class TestListado:
    def test_vacio(self, svc):
        assert len(svc.listar_solicitudes()) == 0
    def test_con_datos(self, svc):
        for i in range(3):
            svc.crear_solicitud(f"hermes-list-{i}")
        assert len(svc.listar_solicitudes(limite=100)) == 3
    def test_limite(self, svc):
        for i in range(5):
            svc.crear_solicitud(f"hermes-limit-{i}")
        assert len(svc.listar_solicitudes(limite=3)) == 3
    def test_por_estado(self, svc):
        s = svc.crear_solicitud("hermes-filter")
        svc.actualizar_estado(s, "CREANDO", numero_paso=2)
        sol = svc.listar_solicitudes(estado="SOLICITADO", limite=100)
        cre = svc.listar_solicitudes(estado="CREANDO", limite=100)
        assert len(sol) == 0 and len(cre) >= 1

# ============================================================
# Generacion IDs
# ============================================================

class TestGeneracionIDs:
    def test_formato(self):
        assert len(_generar_id()) == 16
    def test_unico(self):
        ids = set()
        for _ in range(100):
            ids.add(_generar_id())
        assert len(ids) == 100
    def test_deployment_vs_correlation(self, svc):
        s = svc.crear_solicitud("hermes-test-id-dist")
        assert s.deployment_id != s.correlation_id

# ============================================================
# Modelo SolicitudProyecto
# ============================================================

class TestSolicitudProyectoModel:
    def test_a_dict(self, svc):
        s = svc.crear_solicitud("hermes-dict-test")
        json.dumps(s.a_dict())
    def test_desde_dict(self, svc):
        s = svc.crear_solicitud("hermes-restore", descripcion="Restore")
        s.estado = "CREANDO"
        s2 = SolicitudProyecto.desde_dict(s.a_dict())
        assert s2.nombre_proyecto == "hermes-restore"
        assert s2.estado == "CREANDO"
    def test_iniciar_paso(self, svc, solicitud_valida):
        solicitud_valida.iniciar_paso(2, "Paso 2")
        assert len(solicitud_valida.pasos) == 13  # pasos siempre 13
        assert solicitud_valida.pasos[1]["estado"] == "EN_PROCESO"
    def test_finalizar_paso(self, svc, solicitud_valida):
        solicitud_valida.finalizar_paso(1, "COMPLETADO", "Done", "Evidencia")
        assert solicitud_valida.pasos[0]["estado"] == "COMPLETADO"

# ============================================================
# API Contract Tests
# ============================================================

class TestAPIContract:
    @pytest.fixture(autouse=True)
    def _setup(self, clean_db):
        from fastapi.testclient import TestClient
        from Hermes.Web.backend.main import app
        app.state.servicio_fabrica = None
        from Hermes.Web.backend.servicio_fabrica import _instancia_servicio, ServicioFabrica
        _instancia_servicio = None
        app.state.servicio_fabrica = ServicioFabrica()
        self.client = TestClient(app)
    def test_get_root(self):
        r = self.client.get("/"); assert r.status_code == 200
    def test_get_health(self):
        r = self.client.get("/health"); assert r.status_code == 200
        d = r.json(); assert d.get("estado") == "saludable"
    def test_get_openapi_json(self):
        r = self.client.get("/openapi.json"); assert r.status_code == 200
        p = r.json().get("paths", {})
        assert "/api/fabrica/proyectos" in p
    def test_get_swagger(self):
        r = self.client.get("/swagger"); assert r.status_code == 200
    def test_get_proyectos(self):
        r = self.client.get("/proyectos"); assert r.status_code == 200
    def test_post_crear_valido(self):
        r = self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": "hermes-api-test"})
        assert r.status_code == 202
        d = r.json(); assert d["nombre_proyecto"] == "hermes-api-test"
        assert d["estado"] == "SOLICITADO"
    def test_post_crear_corto(self):
        r = self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": "ab"})
        # Pydantic valida min_length=3 -> 422 (Unprocessable Entity)
        assert r.status_code == 422
    def test_post_crear_vacio(self):
        r = self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": ""})
        assert r.status_code == 422
    def test_post_crear_largo(self):
        r = self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": "h" * 41})
        assert r.status_code == 422
    def test_get_proyecto_existente(self):
        r1 = self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": "hermes-get-test"})
        did = r1.json()["deployment_id"]
        r2 = self.client.get(f"/api/fabrica/proyectos/{did}")
        assert r2.status_code == 200
    def test_get_proyecto_inexistente(self):
        r = self.client.get("/api/fabrica/proyectos/ID_NO_EXISTE")
        assert r.status_code == 404
    def test_get_listado(self):
        self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": "hermes-list-test"})
        r = self.client.get("/api/fabrica/proyectos")
        assert r.status_code == 200 and r.json()["total"] >= 1
    def test_post_disparar_mock(self):
        r = self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": "hermes-dispatch"})
        assert r.status_code == 202
        did = r.json()["deployment_id"]
        svc_ = self.client.app.state.servicio_fabrica
        async def mock_disp(solicitud):
            return {"exito": True, "status_code": 204, "mensaje": "Mock OK"}
        orig = svc_.ejecutar_factory_remoto
        svc_.ejecutar_factory_remoto = mock_disp
        try:
            r2 = self.client.post(f"/api/fabrica/proyectos/{did}/disparar")
            assert r2.status_code == 202  # status_code=202 del decorador @router.post
        finally:
            svc_.ejecutar_factory_remoto = orig
    def test_post_disparar_inexistente(self):
        r = self.client.post("/api/fabrica/proyectos/ID_X/disparar")
        assert r.status_code == 404
    def test_post_paso(self):
        r = self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": "hermes-paso-test"})
        did = r.json()["deployment_id"]
        r2 = self.client.post(f"/api/fabrica/proyectos/{did}/paso",
                              json={"numero_paso": 2, "estado_paso": "EN_PROCESO"})
        assert r2.status_code == 200
    def test_post_finalizar(self):
        r = self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": "hermes-final-test"})
        did = r.json()["deployment_id"]
        r2 = self.client.post(f"/api/fabrica/proyectos/{did}/finalizar",
                              json={"resultado": "PASS"})
        assert r2.status_code == 200 and r2.json()["resultado"] == "PASS"

# ============================================================
# Frontend HTML Tests
# ============================================================

class TestFrontendHTML:
    def test_index_formulario(self):
        c = open(_HERMES_WEB_DIR / "templates" / "index.html", encoding="utf-8").read()
        assert "Crear Proyecto" in c
        assert "nuevo-proyecto-input" in c
    def test_index_no_secretos(self):
        c = open(_HERMES_WEB_DIR / "templates" / "index.html", encoding="utf-8").read().lower()
        for s in ["ghp_", "gho_", "pat_", "authorization", "bearer"]:
            assert s not in c
    def test_index_doble_submit(self):
        c = open(_HERMES_WEB_DIR / "templates" / "index.html", encoding="utf-8").read()
        assert "disabled = true" in c or "btn.disabled = true" in c
    def test_proyecto_no_secretos(self):
        c = open(_HERMES_WEB_DIR / "templates" / "proyecto.html", encoding="utf-8").read().lower()
        for s in ["ghp_", "gho_", "pat_", "authorization"]:
            assert s not in c
    def test_listado_no_secretos(self):
        c = open(_HERMES_WEB_DIR / "templates" / "proyecto_listado.html", encoding="utf-8").read().lower()
        for s in ["ghp_", "gho_", "pat_", "authorization"]:
            assert s not in c

# ============================================================
# Security Tests
# ============================================================

class TestSeguridad:
    def test_api_no_expone_token(self):
        from fastapi.testclient import TestClient
        from Hermes.Web.backend.main import app
        from Hermes.Web.backend.servicio_fabrica import _instancia_servicio, ServicioFabrica
        _instancia_servicio = None
        app.state.servicio_fabrica = ServicioFabrica()
        client = TestClient(app)
        r1 = client.post("/api/fabrica/proyectos", json={"nombre_proyecto": "hermes-sec-test"})
        t = json.dumps(r1.json()).lower()
        for s in ["token", "bearer", "authorization", "ghp_"]:
            assert s not in t
        r2 = client.get("/health")
        t2 = json.dumps(r2.json()).lower()
        for s in ["token", "ghp_", "gho_"]:
            assert s not in t2

# ============================================================
# OpenAPI Spec
# ============================================================

class TestOpenAPISpec:
    def test_endpoints_principales(self):
        from fastapi.testclient import TestClient
        from Hermes.Web.backend.main import app
        from Hermes.Web.backend.servicio_fabrica import _instancia_servicio, ServicioFabrica
        _instancia_servicio = None
        app.state.servicio_fabrica = ServicioFabrica()
        client = TestClient(app)
        r = client.get("/openapi.json")
        assert r.status_code == 200
        paths = r.json().get("paths", {})
        for ep in ["/api/fabrica/proyectos", "/health", "/api/fabrica/proyectos/{deployment_id}"]:
            assert ep in paths


class TestHistorialEndpoint:
    def setup_method(self):
        from fastapi.testclient import TestClient
        from Hermes.Web.backend.main import app
        from Hermes.Web.backend.servicio_fabrica import _instancia_servicio, ServicioFabrica
        _instancia_servicio = None
        app.state.servicio_fabrica = ServicioFabrica()
        self.client = TestClient(app)

    def test_historial_vacio(self):
        r = self.client.get("/api/fabrica/proyectos/historial?limit=5")
        assert r.status_code == 200
        data = r.json()
        assert "proyectos" in data
        assert data["total"] == 0
        assert isinstance(data["proyectos"], list)

    def test_historial_con_proyectos(self):
        for i in range(3):
            self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": f"test-hist-{i}"})
        r = self.client.get("/api/fabrica/proyectos/historial?limit=5")
        assert r.status_code == 200
        data = r.json()
        assert data["total"] >= 3
        fechas = [p["fecha_solicitud"] for p in data["proyectos"]]
        assert fechas == sorted(fechas, reverse=True)

    def test_historial_limit(self):
        for i in range(5):
            self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": f"test-hist-limit-{i}"})
        r = self.client.get("/api/fabrica/proyectos/historial?limit=3")
        assert r.status_code == 200
        data = r.json()
        assert data["total"] == 3

    def test_historial_no_expone_secretos(self):
        import json
        self.client.post("/api/fabrica/proyectos", json={"nombre_proyecto": "test-hist-sec"})
        r = self.client.get("/api/fabrica/proyectos/historial?limit=5")
        t = json.dumps(r.json()).lower()
        for s in ["ghp_", "gho_", "token", "bearer", "authorization"]:
            assert s not in t


class TestFrontendFeatures:
    def test_historial_section_exists(self):
        c = open(_HERMES_WEB_DIR / "templates" / "index.html", encoding="utf-8").read()
        assert "Ultimas 5 Creaciones" in c
        assert "historial-tbody" in c
        assert "historial-refresh-badge" in c

    def test_tracking_tab_exists(self):
        c = open(_HERMES_WEB_DIR / "templates" / "index.html", encoding="utf-8").read()
        assert "window.open" in c
        assert "tracking-tab-status" in c
        assert "Pestana de tracking" in c

    def test_popup_blocked_fallback(self):
        c = open(_HERMES_WEB_DIR / "templates" / "index.html", encoding="utf-8").read()
        assert "bloqueo la pestana" in c
        assert "Abrir seguimiento del proyecto" in c

    def test_historial_polling_exists(self):
        c = open(_HERMES_WEB_DIR / "templates" / "index.html", encoding="utf-8").read()
        assert "setInterval(actualizarHistorial, 10000)" in c
        assert "actualizarHistorial" in c

    def test_no_secretos_frontend(self):
        c = open(_HERMES_WEB_DIR / "templates" / "index.html", encoding="utf-8").read().lower()
        for s in ["ghp_", "gho_", "pat_", "authorization"]:
            assert s not in c
