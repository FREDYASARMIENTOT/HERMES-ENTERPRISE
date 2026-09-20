"""
====================================================================
test_azure_reconciliation.py — Pruebas de Azure Reconciliacion
====================================================================

Casos de prueba:
CASO 1: Azure 200 => EXISTE
CASO 2: Azure 404 => NO_EXISTE
CASO 3: Azure 403 => ERROR_PERMISOS
CASO 4: Azure timeout => ERROR_CONEXION
CASO 5: Azure 500 => ERROR_AZURE
CASO 6: sin web_app_name => NO_VERIFICADO
CASO 7: PASS + Azure eliminado => PASS conservado
CASO 8: FAIL + Azure existente => FAIL conservado
"""

import os
import sys
import unittest
from unittest.mock import Mock, patch, MagicMock
from typing import Dict, Optional

_HERMES_ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
if _HERMES_ROOT not in sys.path:
    sys.path.insert(0, _HERMES_ROOT)

from Hermes.Web.backend.servicio_fabrica import (
    ServicioFabrica, SolicitudProyecto, _generar_id, _ahora
)
from Hermes.Web.backend.servicio_azure import ServicioAzure, obtener_servicio_azure


def _ruta_db_temp():
    import tempfile
    return os.path.join(tempfile.gettempdir(), f"test_azure_recon_{_generar_id()}.db")


# ====== Pruebas del servicio Azure ======

class TestServicioAzureWebAppCheck(unittest.TestCase):
    """Pruebas para ServicioAzure.verificar_existencia_web_app."""

    def setUp(self):
        self.servicio = ServicioAzure()
        self.web_app_name = "as-test-web-app"
        self.resource_group = "RG-Hermes-Proyectos"
        self.subscription = "01bfad48-c092-4712-bc72-f141eb01a8d4"

    def _mock_httpx(self, status_code: int, json_data: Optional[Dict] = None):
        mock_httpx = MagicMock()
        mock_response = MagicMock()
        mock_response.status_code = status_code
        mock_response.json.return_value = json_data or {}
        mock_httpx.get.return_value = mock_response
        self.servicio._httpx = mock_httpx
        self.servicio._httpx_disponible = True
        self.servicio._obtener_token = Mock(return_value="fake-token")
        self.servicio._obtener_credential = Mock(return_value=True)

    def test_azure_200_devuelve_existe(self):
        """CASO 1: Azure 200 => EXISTE."""
        self._mock_httpx(200, {
            "properties": {"defaultHostName": "as-test-web-app.azurewebsites.net"}
        })
        resultado = self.servicio.verificar_existencia_web_app(
            self.web_app_name, self.resource_group, self.subscription
        )
        self.assertTrue(resultado["exists"])
        self.assertEqual(resultado["status"], "EXISTE")
        self.assertEqual(resultado["hostname"], "as-test-web-app.azurewebsites.net")

    def test_azure_404_devuelve_no_existe(self):
        """CASO 2: Azure 404 => NO_EXISTE."""
        self._mock_httpx(404)
        resultado = self.servicio.verificar_existencia_web_app(
            self.web_app_name, self.resource_group, self.subscription
        )
        self.assertFalse(resultado["exists"])
        self.assertEqual(resultado["status"], "NO_EXISTE")

    def test_azure_403_devuelve_error_permisos(self):
        """CASO 3: Azure 403 => ERROR_PERMISOS."""
        self._mock_httpx(403)
        resultado = self.servicio.verificar_existencia_web_app(
            self.web_app_name, self.resource_group, self.subscription
        )
        self.assertEqual(resultado["status"], "ERROR_PERMISOS")

    def test_azure_timeout_devuelve_error_conexion(self):
        """CASO 4: Azure timeout => ERROR_CONEXION."""
        mock_httpx = MagicMock()
        import httpx
        mock_httpx.get.side_effect = httpx.TimeoutException("Timeout")
        mock_httpx.TimeoutException = httpx.TimeoutException
        mock_httpx.ConnectError = httpx.ConnectError
        self.servicio._httpx = mock_httpx
        self.servicio._httpx_disponible = True
        self.servicio._obtener_token = Mock(return_value="fake-token")
        self.servicio._obtener_credential = Mock(return_value=True)
        resultado = self.servicio.verificar_existencia_web_app(
            self.web_app_name, self.resource_group, self.subscription
        )
        self.assertEqual(resultado["status"], "ERROR_CONEXION")

    def test_azure_500_devuelve_error_azure(self):
        """CASO 5: Azure 500 => ERROR_AZURE."""
        self._mock_httpx(500)
        resultado = self.servicio.verificar_existencia_web_app(
            self.web_app_name, self.resource_group, self.subscription
        )
        self.assertEqual(resultado["status"], "ERROR_AZURE")

    def test_sin_web_app_name_devuelve_no_verificado(self):
        """CASO 6: Sin web_app_name => NO_VERIFICADO."""
        resultado = self.servicio.verificar_existencia_web_app(
            "", self.resource_group, self.subscription
        )
        self.assertEqual(resultado["status"], "NO_VERIFICADO")


# ====== Pruebas de reconciliacion en ServicioFabrica ======

class TestReconciliacionEnServicioFabrica(unittest.TestCase):
    """Pruebas para reconciliacion Azure via ServicioFabrica."""

    def setUp(self):
        self.ruta_db = _ruta_db_temp()
        self.svc = ServicioFabrica(ruta_db=self.ruta_db)
        self.azure_svc = obtener_servicio_azure()

    def tearDown(self):
        if os.path.exists(self.ruta_db):
            os.remove(self.ruta_db)

    def _crear_solicitud(self, nombre="test-recon-01", web_app="as-test-recon-01"):
        sol = self.svc.crear_solicitud(
            nombre_proyecto=nombre,
            descripcion="Test reconciliation",
            app_service_plan_id=("/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/"
                                 "resourceGroups/RG-Hermes-Proyectos/"
                                 "providers/Microsoft.Web/serverfarms/ASP-HERMES-PORTAL")
        )
        sol.web_app = web_app
        sol.web_app_resource_group = "RG-Hermes-Proyectos"
        sol.app_service_plan_subscription = "01bfad48-c092-4712-bc72-f141eb01a8d4"
        self.svc._guardar(sol)
        return sol

    def _completar_todos_los_pasos(self, sol):
        """Marca los 13 pasos como COMPLETADO para que FASE-24 permita PASS."""
        for paso in sol.pasos:
            paso["estado"] = "COMPLETADO"
            paso["fecha_inicio"] = _ahora()
            paso["fecha_fin"] = _ahora()
            paso["duracion_segundos"] = 1.0

    def test_pass_con_recurso_eliminado_conserva_resultado(self):
        """CASO 7: PASS + Azure eliminado => PASS conservado, recurso = NO_EXISTE."""
        sol = self._crear_solicitud("test-pass-elim", "as-pass-elim")
        self._completar_todos_los_pasos(sol)
        sol.resultado = "PASS"
        sol.estado = "COMPLETADO"
        self.svc._guardar(sol)

        # Patch the method on the singleton instance
        with patch.object(self.azure_svc, 'verificar_existencia_web_app',
                          return_value={
                              "exists": False, "status_code": 404, "status": "NO_EXISTE",
                              "error": "", "resource_id": "", "hostname": "",
                              "checked_at": _ahora(),
                          }):
            resultado = self.svc.verificar_y_actualizar_estado_azure(sol.deployment_id)

        self.assertEqual(resultado["status"], "NO_EXISTE")
        self.assertFalse(resultado["exists"])
        sol_act = self.svc.obtener_solicitud(sol.deployment_id)
        self.assertEqual(sol_act.resultado, "PASS")
        self.assertFalse(sol_act.azure_resource_exists)
        self.assertEqual(sol_act.azure_resource_check_status, "NO_EXISTE")

    def test_fail_con_recurso_existente_conserva_resultado(self):
        """CASO 8: FAIL + Azure existente => FAIL conservado, recurso = EXISTE."""
        sol = self._crear_solicitud("test-fail-exist", "as-fail-exist")
        sol.resultado = "FAIL"
        sol.estado = "FALLIDO"
        self.svc._guardar(sol)

        with patch.object(self.azure_svc, 'verificar_existencia_web_app',
                          return_value={
                              "exists": True, "status_code": 200, "status": "EXISTE",
                              "error": "", "resource_id": "", "hostname": "",
                              "checked_at": _ahora(),
                          }):
            resultado = self.svc.verificar_y_actualizar_estado_azure(sol.deployment_id)

        self.assertEqual(resultado["status"], "EXISTE")
        self.assertTrue(resultado["exists"])
        sol_act = self.svc.obtener_solicitud(sol.deployment_id)
        self.assertEqual(sol_act.resultado, "FAIL")
        self.assertTrue(sol_act.azure_resource_exists)
        self.assertEqual(sol_act.azure_resource_check_status, "EXISTE")

    def test_reconciliacion_masiva_actualiza_estados(self):
        """Reconciliacion masiva actualiza correctamente estados."""
        sol1 = self._crear_solicitud("mass-01", "as-mass-01")
        sol2 = self._crear_solicitud("mass-02", "as-mass-02")
        sol3 = self._crear_solicitud("mass-03", "")

        def mock_check(web_app_name, resource_group="RG-Hermes-Proyectos", subscription_id="01bfad48-c092-4712-bc72-f141eb01a8d4"):
            if web_app_name == "as-mass-01":
                return {"exists": True, "status_code": 200, "status": "EXISTE",
                        "error": "", "resource_id": "", "hostname": "", "checked_at": _ahora()}
            elif web_app_name == "as-mass-02":
                return {"exists": False, "status_code": 404, "status": "NO_EXISTE",
                        "error": "", "resource_id": "", "hostname": "", "checked_at": _ahora()}
            return {"exists": False, "status_code": 0, "status": "NO_VERIFICADO",
                    "error": "Sin web_app", "resource_id": "", "hostname": "", "checked_at": _ahora()}

        with patch.object(self.azure_svc, 'verificar_existencia_web_app', side_effect=mock_check):
            resultados = self.svc.reconciliar_todos_los_proyectos()

        self.assertEqual(resultados["total"], 3)
        self.assertEqual(resultados["azure_existentes"], 1)
        self.assertEqual(resultados["azure_eliminados"], 1)
        self.assertEqual(resultados["azure_no_verificados"], 1)
        self.assertEqual(resultados["azure_errores"], 0)

    def test_actualizar_estado_azure_en_bd(self):
        """Actualizar estado Azure en BD debe persistir correctamente."""
        sol = self._crear_solicitud("bd-update", "as-bd-update")
        resultado_azure = {
            "exists": True, "status_code": 200, "status": "EXISTE",
            "error": "", "resource_id": "", "hostname": "as-bd-update.azurewebsites.net",
            "checked_at": _ahora(),
        }
        ok = self.svc._actualizar_estado_azure_en_bd(sol.deployment_id, resultado_azure)
        self.assertTrue(ok)
        sol2 = self.svc.obtener_solicitud(sol.deployment_id)
        self.assertTrue(sol2.azure_resource_exists)
        self.assertEqual(sol2.azure_resource_check_status, "EXISTE")
        self.assertEqual(sol2.azure_hostname, "as-bd-update.azurewebsites.net")

    def test_verificar_deployment_inexistente(self):
        """Verificar deployment inexistente debe devolver error."""
        resultado = self.svc.verificar_y_actualizar_estado_azure("NONEXISTENT")
        self.assertEqual(resultado.get("status"), "NO_VERIFICADO")
        self.assertIn("no encontrado", resultado.get("error", ""))


# ====== Pruebas de frontend ======

class TestFrontendAzureStatus(unittest.TestCase):
    """Pruebas de UI para Azure Status en templates."""

    def test_proyecto_html_tiene_seccion_azure(self):
        html_path = os.path.join(_HERMES_ROOT, "Hermes.Web", "templates", "proyecto.html")
        with open(html_path, "r", encoding="utf-8") as f:
            html = f.read()
        self.assertIn("Estado Actual de Azure", html)
        self.assertIn("azure-resource-status", html)
        self.assertIn("azure-checked-at", html)
        self.assertIn("azure-resource-id", html)
        self.assertIn("verificarAzureAhora", html)

    def test_proyecto_html_tiene_funciones_js(self):
        html_path = os.path.join(_HERMES_ROOT, "Hermes.Web", "templates", "proyecto.html")
        with open(html_path, "r", encoding="utf-8") as f:
            html = f.read()
        self.assertIn("function actualizarAzureStatus", html)
        self.assertIn("function verificarAzureAhora", html)

    def test_index_html_tiene_azure_fields(self):
        html_path = os.path.join(_HERMES_ROOT, "Hermes.Web", "templates", "index.html")
        with open(html_path, "r", encoding="utf-8") as f:
            html = f.read()
        self.assertIn("azure_resource_check_status", html)


if __name__ == "__main__":
    unittest.main()

