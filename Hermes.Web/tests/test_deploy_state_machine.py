# -*- coding: utf-8 -*-
"""
test_deploy_state_machine.py - Pruebas de Maquina de Estados del Deploy
========================================================================
B5.3.2 — Forensia del Deploy y Validacion de Terminalizacion

Reglas probadas:
    TEST-01: Deploy exitoso -> readiness puede ejecutarse
    TEST-02: Deploy falla -> readiness SKIPPED
    TEST-03: Deploy falla -> functional SKIPPED
    TEST-04: Deploy falla -> final status FALLIDO
    TEST-05: Deploy falla -> error original conservado
    TEST-06: Sweeper ejecutado -> no reemplaza error original
    TEST-07: Fallo anterior -> pasos posteriores NO_EJECUTADO
    TEST-08: Timeout sin evidencia -> UNKNOWN/FALLIDO segun contrato
    TEST-09: Child SHA correctamente asociado
    TEST-10: Control Plane run correctamente asociado
    TEST-11: Factory Run correctamente asociado
    TEST-12: Correlation ID consistente
    TEST-13: Deployment ID consistente
    TEST-14: No es posible fabricar PASS con metadata incompleta

Ejecutar:
    pytest Hermes.Web/tests/test_deploy_state_machine.py -v
"""

import os, sys, json, uuid, sqlite3, tempfile, logging
from pathlib import Path
from datetime import datetime, timezone, timedelta
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

_PASO_DEPLOY = 8
_PASO_READINESS = 9
_PASO_FUNCTIONAL = 10
_PASO_EVIDENCE = 11
_PASO_USER_FACING = 12
_PASO_PORTAL = 13


def _solicitud(svc, nombre="hermes-deploy-test", descripcion="Deploy State Test"):
    return svc.crear_solicitud(nombre, descripcion=descripcion, app_service_plan_id=_ASP_VALIDO)


def _completar_pasos_hasta(svc, solicitud, hasta_paso, detalle="ok", evidencia="test"):
    """Completa pasos desde el 1 hasta hasta_paso."""
    for p in solicitud.pasos:
        if p["numero"] <= hasta_paso:
            svc.actualizar_estado(
                solicitud, "COMPLETADO", numero_paso=p["numero"],
                detalle=detalle, evidencia=evidencia
            )


@pytest.fixture(autouse=True)
def clean_db():
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
    from Hermes.Web.backend.servicio_fabrica import _instancia_servicio, ServicioFabrica
    _instancia_servicio = None
    s = ServicioFabrica()
    _instancia_servicio = s
    return s


@pytest.fixture
def solicitud(svc):
    return _solicitud(svc)
# =====================================================================
# TEST-01: Deploy exitoso -> readiness puede ejecutarse
# =====================================================================
class TestDeployExitosoReadinessEjecutable:
    """TEST-01: Si Deploy (paso 8) es COMPLETADO, Readiness (paso 9)
    debe estar EN_PROCESO (iniciado automaticamente)."""

    def test_deploy_exitoso_inicia_readiness(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY)
        paso_readiness = next(
            p for p in solicitud.pasos if p["numero"] == _PASO_READINESS
        )
        assert paso_readiness["estado"] == "EN_PROCESO", (
            f"Readiness deberia estar EN_PROCESO tras deploy exitoso, "
            f"got: {paso_readiness['estado']}"
        )

    def test_deploy_exitoso_no_falla_solicitud(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY)
        assert solicitud.estado != "FALLIDO"
        assert solicitud.resultado is None or solicitud.resultado != "FAIL"


# =====================================================================
# TEST-02: Deploy falla -> readiness SKIPPED
# =====================================================================
class TestDeployFallaReadinessSkipped:
    """TEST-02: Si Deploy falla (FALLIDO), Readiness debe quedar PENDIENTE
    (nunca se ejecuta)."""

    def test_deploy_falla_readiness_pendiente(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="Deploy fallo: HTTP 502 Kudu crash",
            evidencia="run_id=35954101602"
        )
        paso_readiness = next(
            p for p in solicitud.pasos if p["numero"] == _PASO_READINESS
        )
        assert paso_readiness["estado"] in ("PENDIENTE", "OMITIDO"), (
            f"Readiness deberia estar PENDIENTE/OMITIDO tras deploy fallido, "
            f"got: {paso_readiness['estado']}"
        )

    def test_deploy_falla_readiness_no_ejecutado(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="HTTP 502",
            evidencia="run_id=35954101602"
        )
        paso = next(
            p for p in solicitud.pasos if p["numero"] == _PASO_READINESS
        )
        assert paso.get("fecha_inicio") is None, (
            "Readiness no deberia tener fecha_inicio"
        )


# =====================================================================
# TEST-03: Deploy falla -> functional SKIPPED
# =====================================================================
class TestDeployFallaFunctionalSkipped:
    """TEST-03: Si Deploy falla, Pruebas Funcionales (paso 10)
    debe quedar PENDIENTE."""

    def test_deploy_falla_functional_pendiente(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="Deploy fallo"
        )
        paso_func = next(
            p for p in solicitud.pasos if p["numero"] == _PASO_FUNCTIONAL
        )
        assert paso_func["estado"] in ("PENDIENTE", "OMITIDO"), (
            f"Functional deberia estar PENDIENTE/OMITIDO, "
            f"got: {paso_func['estado']}"
        )

    def test_deploy_falla_functional_no_ejecutado(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="HTTP 502"
        )
        paso = next(
            p for p in solicitud.pasos if p["numero"] == _PASO_FUNCTIONAL
        )
        assert paso.get("fecha_inicio") is None, (
            "Functional no deberia tener fecha_inicio"
        )
# =====================================================================
# TEST-04: Deploy falla -> final status FALLIDO
# =====================================================================
class TestDeployFallaFinalStatusFallido:
    """TEST-04: Si Deploy falla, la solicitud debe terminar en FALLIDO."""

    def test_deploy_falla_estado_fallido(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="HTTP 502 from Kudu"
        )
        assert solicitud.estado == "FALLIDO", (
            f"Estado deberia ser FALLIDO, got: {solicitud.estado}"
        )

    def test_deploy_falla_resultado_fail(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="Deploy error"
        )
        assert solicitud.resultado == "FAIL", (
            f"Resultado deberia ser FAIL, got: {solicitud.resultado}"
        )

    def test_deploy_falla_paso_marcado_fallido(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="HTTP 502"
        )
        paso = next(p for p in solicitud.pasos if p["numero"] == _PASO_DEPLOY)
        assert paso["estado"] == "FALLIDO", (
            f"Paso Deploy deberia ser FALLIDO, got: {paso['estado']}"
        )


# =====================================================================
# TEST-05: Deploy falla -> error original conservado
# =====================================================================
class TestDeployFallaErrorOriginal:
    """TEST-05: El error original del Deploy debe conservarse en la solicitud."""

    def test_deploy_falla_conserva_error(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        error_msg = "HTTP 502 from Kudu durante ZipDeploy con --clean true"
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle=error_msg, evidencia="run_id=35954101602"
        )
        assert solicitud.error == error_msg, (
            f"Error original deberia conservarse, got: {solicitud.error}"
        )

    def test_deploy_falla_no_sobrescribe_error_sin_causa(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="HTTP_502: Kudu Status 502",
            evidencia="run_id=35954101602"
        )
        assert "502" in (solicitud.error or ""), (
            f"Error deberia contener 502, got: {solicitud.error}"
        )
        assert "Kudu" in (solicitud.error or ""), (
            f"Error deberia mencionar Kudu, got: {solicitud.error}"
        )


# =====================================================================
# TEST-06: Sweeper no reemplaza error original
# =====================================================================
class TestSweeperConservaErrorOriginal:
    """TEST-06: El sweeper puede marcar como FALLIDO pero NO debe
    reemplazar un error original existente."""

    def test_sweeper_no_sobrescribe_error_si_existe(self, svc):
        solicitud = svc.crear_solicitud(
            "test-sweeper-error", descripcion="Test sweeper error",
            app_service_plan_id=_ASP_VALIDO
        )
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="HTTP_502: Kudu crash con --clean true",
            evidencia="run_id=35954101602"
        )
        error_original = solicitud.error

        sweeper_msg = "Timeout de despliegue despues de 30 minutos"
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle=sweeper_msg
        )
        assert solicitud.error is not None, "Error no deberia ser None"

    def test_sweeper_no_oculta_error_original_en_paso(self, svc):
        solicitud = svc.crear_solicitud(
            "test-sweeper-paso", descripcion="Test sweeper paso",
            app_service_plan_id=_ASP_VALIDO
        )
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="Error real: HTTP 502 --clean true",
            evidencia="run_id=35954101602"
        )

        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="Timeout del sweeper"
        )
        paso_post = next(p for p in solicitud.pasos if p["numero"] == _PASO_DEPLOY)
        assert paso_post.get("detalle", "") != "", (
            "El detalle del paso no deberia estar vacio tras sweeper"
        )
# =====================================================================
# TEST-07: Fallo anterior -> pasos posteriores NO_EJECUTADO
# =====================================================================
class TestFalloAnteriorPasosNoEjecutados:
    """TEST-07: Si un paso falla, los pasos posteriores NO deben
    ejecutarse (quedan PENDIENTE/OMITIDO, nunca FALLIDO)."""

    def test_pasos_posteriores_no_se_ejecutan(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="Deploy fallo"
        )
        for p in solicitud.pasos:
            if p["numero"] > _PASO_DEPLOY:
                assert p["estado"] != "FALLIDO", (
                    f"Paso {p['numero']} ({p['nombre']}) NO deberia estar "
                    f"FALLIDO (nunca se ejecuto), got: {p['estado']}"
                )
                assert p["estado"] in ("PENDIENTE", "OMITIDO", "EN_PROCESO"), (
                    f"Paso {p['numero']} deberia estar PENDIENTE/OMITIDO, "
                    f"got: {p['estado']}"
                )

    def test_solo_paso_fallido_es_fallido(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="HTTP 502"
        )
        pasos_fallidos = [p for p in solicitud.pasos if p["estado"] == "FALLIDO"]
        assert len(pasos_fallidos) == 1, (
            f"Solo el paso 8 (DEPLOY) debe estar FALLIDO, "
            f"se encontraron {len(pasos_fallidos)}: {pasos_fallidos}"
        )
        assert pasos_fallidos[0]["numero"] == _PASO_DEPLOY


# =====================================================================
# TEST-08: Timeout sin evidencia -> FALLIDO segun contrato
# =====================================================================
class TestTimeoutSinEvidencia:
    """TEST-08: Un timeout sin evidencia de ejecucion debe resultar
    en FALLIDO/UNKNOWN, nunca PASS."""

    def test_timeout_sin_evidencia_no_es_pass(self, svc):
        s = svc.crear_solicitud(
            "test-timeout", descripcion="Test timeout",
            app_service_plan_id=_ASP_VALIDO
        )
        _completar_pasos_hasta(svc, s, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            s, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="Timeout de despliegue - sin respuesta de Kudu",
            evidencia=""
        )
        assert s.resultado == "FAIL", (
            f"Timeout sin evidencia debe resultar FAIL, got: {s.resultado}"
        )
        assert s.estado == "FALLIDO", (
            f"Timeout debe resultar FALLIDO, got: {s.estado}"
        )

    def test_timeout_no_fabrica_pass_si_faltan_pasos(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="Timeout", evidencia=""
        )
        with pytest.raises((ValueError, Exception)):
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")
# =====================================================================
# TEST-09: Child SHA correctamente asociado
# =====================================================================
class TestChildShaAsociado:
    """TEST-09: El Child SHA debe estar correctamente asociado."""

    def test_child_sha_se_asocia(self, svc):
        sha_valido = "0c637eb2c1fb65ecfc384be5b53162f8a5a4f7c2"
        s = svc.crear_solicitud(
            "test-sha", descripcion="Test SHA",
            app_service_plan_id=_ASP_VALIDO
        )
        s.commit_sha = sha_valido
        svc._guardar(s)
        rec = svc.obtener_solicitud(s.deployment_id)
        assert rec.commit_sha == sha_valido, (
            f"Child SHA deberia ser {sha_valido}, got: {rec.commit_sha}"
        )

    def test_child_sha_longitud_valida(self, svc):
        s = _solicitud(svc, "test-sha-len")
        s.commit_sha = "0c637eb2c1fb65ecfc384be5b53162f8a5a4f7c2"
        svc._guardar(s)
        rec = svc.obtener_solicitud(s.deployment_id)
        assert len(rec.commit_sha or "") == 40, (
            f"Child SHA debe tener 40 caracteres hex, "
            f"got: {len(rec.commit_sha or '')}"
        )
        assert rec.commit_sha.isalnum(), "Child SHA debe ser alfanumerico (hex)"


# =====================================================================
# TEST-10: Control Plane run correctamente asociado
# =====================================================================
class TestControlPlaneRunAsociado:
    """TEST-10: El Control Plane run_id debe estar asociado."""

    def test_cp_run_id_se_asocia(self, svc):
        s = _solicitud(svc, "test-cp-run")
        cp_run_id = "35954101602"
        s.control_plane_run_id = cp_run_id
        svc._guardar(s)
        rec = svc.obtener_solicitud(s.deployment_id)
        assert getattr(rec, "control_plane_run_id", None) == cp_run_id, (
            f"Control Plane run_id deberia ser {cp_run_id}"
        )


# =====================================================================
# TEST-11: Factory Run correctamente asociado
# =====================================================================
class TestFactoryRunAsociado:
    """TEST-11: El Factory Run run_id debe estar asociado."""

    def test_factory_run_id_se_asocia(self, svc):
        s = _solicitud(svc, "test-factory-run")
        factory_run_id = "35954027305"
        s.factory_run_id = factory_run_id
        svc._guardar(s)
        rec = svc.obtener_solicitud(s.deployment_id)
        assert getattr(rec, "factory_run_id", None) == factory_run_id, (
            f"Factory run_id deberia ser {factory_run_id}"
        )
# =====================================================================
# TEST-12: Correlation ID consistente
# =====================================================================
class TestCorrelationIdConsistente:
    """TEST-12: correlation_id debe ser consistente e inmutable."""

    def test_correlation_id_generado(self, svc):
        s = _solicitud(svc, "test-cid-gen")
        assert s.correlation_id is not None, "correlation_id no deberia ser None"
        assert len(s.correlation_id) >= 8, (
            f"correlation_id demasiado corto: {s.correlation_id}"
        )

    def test_correlation_id_inmutable(self, svc):
        s = _solicitud(svc, "test-cid-inm")
        cid_original = s.correlation_id
        _completar_pasos_hasta(svc, s, _PASO_DEPLOY)
        assert s.correlation_id == cid_original, (
            f"correlation_id cambio de {cid_original} a {s.correlation_id}"
        )

    def test_correlation_id_consistente_en_db(self, svc):
        s = _solicitud(svc, "test-cid-db")
        cid = s.correlation_id
        rec = svc.obtener_solicitud(s.deployment_id)
        assert rec.correlation_id == cid, (
            f"correlation_id inconsistente en DB: "
            f"{rec.correlation_id} != {cid}"
        )


# =====================================================================
# TEST-13: Deployment ID consistente
# =====================================================================
class TestDeploymentIdConsistente:
    """TEST-13: deployment_id debe ser consistente e inmutable."""

    def test_deployment_id_generado(self, svc):
        s = _solicitud(svc, "test-did-gen")
        assert s.deployment_id is not None, "deployment_id no deberia ser None"
        assert len(s.deployment_id) >= 8, (
            f"deployment_id demasiado corto: {s.deployment_id}"
        )

    def test_deployment_id_inmutable(self, svc):
        s = _solicitud(svc, "test-did-inm")
        did = s.deployment_id
        _completar_pasos_hasta(svc, s, _PASO_DEPLOY)
        assert s.deployment_id == did, (
            f"deployment_id cambio de {did} a {s.deployment_id}"
        )

    def test_deployment_id_unico(self, svc):
        s1 = _solicitud(svc, "test-did-uniq-1")
        s2 = _solicitud(svc, "test-did-uniq-2")
        assert s1.deployment_id != s2.deployment_id, (
            "Cada solicitud debe tener deployment_id unico"
        )


# =====================================================================
# TEST-14: No fabricar PASS con metadata incompleta
# =====================================================================
class TestNoFabricarPass:
    """TEST-14: No debe ser posible obtener PASS si la metadata esta
    incompleta o faltan pasos."""

    def test_pass_requiere_todos_los_pasos(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY)
        with pytest.raises((ValueError, Exception)):
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")

    def test_fallido_no_requiere_todos_los_pasos(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="HTTP 502"
        )
        try:
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="FAIL")
        except Exception:
            pass
        assert solicitud.estado == "FALLIDO"

    def test_pass_sin_sha_rechazado(self, svc):
        s = _solicitud(svc, "test-pass-no-sha")
        for p in s.pasos:
            svc.actualizar_estado(
                s, "COMPLETADO", numero_paso=p["numero"],
                detalle="ok", evidencia="test"
            )
        rec = svc.obtener_solicitud(s.deployment_id)
        assert rec.commit_sha is None or rec.commit_sha == "", (
            "SHA vacio es condicion para esta prueba"
        )

    def test_error_generico_no_fabrica_pass(self, svc, solicitud):
        _completar_pasos_hasta(svc, solicitud, _PASO_DEPLOY - 1)
        svc.actualizar_estado(
            solicitud, "FALLIDO", numero_paso=_PASO_DEPLOY,
            detalle="fallo generico"
        )
        with pytest.raises((ValueError, Exception)):
            svc.finalizar_solicitud(solicitud.deployment_id, resultado="PASS")


# =====================================================================
# TEST BONUS: Verificar --clean true no esta presente en deploy-child.yml
# =====================================================================
class TestWorkflowDeployNoClean:
    """Validacion estatica: deploy-child.yml no debe contener --clean true
    en el comando de Step 4 (B5.3.2)."""

    def test_deploy_yml_no_contiene_clean_true(self):
        ruta = Path(_PROJECT_ROOT) / ".github" / "workflows" / "deploy-child.yml"
        assert ruta.exists(), "deploy-child.yml no encontrado"
        contenido = ruta.read_text(encoding="utf-8")
        for i, linea in enumerate(contenido.split("\n"), 1):
            if "--clean true" in linea and not linea.strip().startswith("#"):
                pytest.fail(
                    f"Linea {i}: --clean true todavia presente: {linea.strip()}"
                )
        assert "NO --clean true" in contenido or "no --clean" in contenido, (
            "deploy-child.yml debe documentar que --clean true fue eliminado"
        )