# MATRIZ DE TRAZABILIDAD — HERMES-ENTERPRISE

> **Versión**: 1.0  
> **Fecha**: 2026-09-20  
> **Propósito**: Documentar la fuente real, momento de captura, persistencia, API y UI de cada dato de trazabilidad en el Portal Hermes.

---

## 1. IDENTIFICACIÓN DEL PROYECTO

| Dato | Fuente | Momento | Persistencia | API | UI | Evidencia |
|------|--------|---------|-------------|-----|----|-----------|
| `deployment_id` | Portal (uuid4.hex) | Crear solicitud | `solicitudes_proyecto.deployment_id` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | DB |
| `correlation_id` | Portal (uuid4.hex) | Crear solicitud | `solicitudes_proyecto.correlation_id` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | DB |
| `nombre_proyecto` | Usuario (formulario) | Crear solicitud | `solicitudes_proyecto.nombre_proyecto` | `GET /api/fabrica/proyectos/{id}` | Dashboard/Detalle | DB |
| `descripcion` | Usuario (formulario) | Crear solicitud | `solicitudes_proyecto.descripcion` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | DB |

## 2. APP SERVICE PLAN

| Dato | Fuente | Momento | Persistencia | API | UI | Evidencia |
|------|--------|---------|-------------|-----|----|-----------|
| `app_service_plan_id` | Usuario (selector) | Crear solicitud | `solicitudes_proyecto.app_service_plan_id` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | DB |
| `app_service_plan_name` | Azure ARM API | De resource ID | `solicitudes_proyecto.app_service_plan_name` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Factory Runner |
| `app_service_plan_resource_group` | Constante | Crear solicitud | `solicitudes_proyecto.app_service_plan_resource_group` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Código |

## 3. GITHUB

| Dato | Fuente | Momento | Persistencia | API | UI | Evidencia |
|------|--------|---------|-------------|-----|----|-----------|
| `repository_url` | Factory Runner | Factory completa | `solicitudes_proyecto.repository_url` | `GET /api/fabrica/proyectos/{id}` | Detalle (link) | factory-run.yml |
| `repository_name` | Factory Runner | Factory completa | `solicitudes_proyecto.repository_url` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Derivado |
| `repository_visibility` | Factory Runner | Factory completa | `solicitudes_proyecto.visibility` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | factory-run.yml |
| `commit_sha` | Factory Runner (git) | Factory completa | `solicitudes_proyecto.commit_sha` | `GET /api/fabrica/proyectos/{id}` | Detalle (link) | Verificable |
| `commit_url` | Factory Runner | Factory completa | `solicitudes_proyecto.commit_url` | `GET /api/fabrica/proyectos/{id}` | Detalle (link) | factory-run.yml |
| `branch` | Constante: main | Crear solicitud | No persistido | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Código |

## 4. FACTORY

| Dato | Fuente | Momento | Persistencia | API | UI | Evidencia |
|------|--------|---------|-------------|-----|----|-----------|
| `factory_run_id` | GitHub Actions run_id | Factory ejecuta | `solicitudes_proyecto.factory_run_id` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | factory-run.yml |
| `factory_run_url` | GitHub Actions | Factory ejecuta | `solicitudes_proyecto.factory_run_url` | `GET /api/fabrica/proyectos/{id}` | Detalle (link) | factory-run.yml |
| `factory_run_status` | GitHub Actions | Factory termina | `solicitudes_proyecto.factory_status` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | factory-run.yml |
| `factory_started_at` | GitHub Actions | Factory inicia | `solicitudes_proyecto.factory_started_at` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `factory_finished_at` | GitHub Actions | Factory termina | `solicitudes_proyecto.factory_finished_at` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | factory-run.yml |
| `factory_duration` | Calculado | Factory termina | `solicitudes_proyecto.factory_duration` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Calculado |

## 5. CHILD CI

| Dato | Fuente | Momento | Persistencia | API | UI | Evidencia |
|------|--------|---------|-------------|-----|----|-----------|
| `child_ci_run_id` | Child repo CI run | CI ejecuta | `solicitudes_proyecto.child_ci_run_id` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `child_ci_run_url` | Child repo CI | CI ejecuta | `solicitudes_proyecto.child_ci_run_url` | `GET /api/fabrica/proyectos/{id}` | Detalle (link) | Pendiente |
| `child_ci_status` | Child repo CI | CI termina | `solicitudes_proyecto.child_ci_status` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `child_ci_started_at` | Child repo CI | CI inicia | `solicitudes_proyecto.child_ci_started_at` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `child_ci_finished_at` | Child repo CI | CI termina | `solicitudes_proyecto.child_ci_finished_at` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `child_ci_duration` | Calculado | CI termina | `solicitudes_proyecto.child_ci_duration` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |

## 6. CONTROL PLANE

| Dato | Fuente | Momento | Persistencia | API | UI | Evidencia |
|------|--------|---------|-------------|-----|----|-----------|
| `control_plane_run_id` | GitHub Actions run_id | CP ejecuta | `solicitudes_proyecto.control_plane_run_id` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `control_plane_run_url` | GitHub Actions | CP ejecuta | `solicitudes_proyecto.control_plane_run_url` | `GET /api/fabrica/proyectos/{id}` | Detalle (link) | Pendiente |
| `control_plane_status` | GitHub Actions | CP termina | `solicitudes_proyecto.control_plane_status` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `control_plane_started_at` | GitHub Actions | CP inicia | `solicitudes_proyecto.control_plane_started_at` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `control_plane_finished_at` | GitHub Actions | CP termina | `solicitudes_proyecto.control_plane_finished_at` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `control_plane_duration` | Calculado | CP termina | `solicitudes_proyecto.control_plane_duration` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |

## 7. AZURE

| Dato | Fuente | Momento | Persistencia | API | UI | Evidencia |
|------|--------|---------|-------------|-----|----|-----------|
| `azure_subscription_id` | Constante | Crear solicitud | `solicitudes_proyecto.app_service_plan_subscription` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Código |
| `azure_resource_group` | Constante | Crear solicitud | `solicitudes_proyecto.web_app_resource_group` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Código |
| `azure_app_service_plan` | Azure ARM API | Validación | `solicitudes_proyecto.app_service_plan_name` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `azure_web_app_name` | Control Plane | CP crea Web App | `solicitudes_proyecto.web_app` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | deploy-child.yml |
| `azure_hostname` | Azure Web App | CP crea Web App | `solicitudes_proyecto.web_app_url` | `GET /api/fabrica/proyectos/{id}` | Detalle (link) | deploy-child.yml |
| `azure_state` | Azure ARM API | CP termina | No persistido | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `azure_location` | Azure ARM API | Validación | No persistido | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |

## 8. VALIDACIÓN

| Dato | Fuente | Momento | Persistencia | API | UI | Evidencia |
|------|--------|---------|-------------|-----|----|-----------|
| `readiness_status` | CP (health check) | Job readiness | `solicitudes_proyecto.readiness_result` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `readiness_http_status` | CP | Job readiness | `solicitudes_proyecto.readiness_result` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `readiness_url` | CP | Derivado de URL | web_app_url + /health | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `readiness_timestamp` | CP | Job readiness | En event_logs | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `functional_status` | CP | Job func. tests | `solicitudes_proyecto.functional_result` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `functional_pass_count` | CP | Job func. tests | `solicitudes_proyecto.functional_pass_count` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `functional_fail_count` | CP | Job func. tests | `solicitudes_proyecto.functional_fail_count` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `evidence_status` | CP | Job evidence | `solicitudes_proyecto.evidence_result` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |

## 9. ESTADO GLOBAL

| Dato | Fuente | Momento | Persistencia | API | UI | Evidencia |
|------|--------|---------|-------------|-----|----|-----------|
| `estado_global` | Portal (calculado) | Cada actualización | `solicitudes_proyecto.estado` | `GET /api/fabrica/proyectos/{id}` | Dashboard/Detalle | DB |
| `resultado` | Portal (PASS/FAIL) | Al finalizar | `solicitudes_proyecto.resultado` | `GET /api/fabrica/proyectos/{id}` | Dashboard/Detalle | DB |
| `fecha_inicio` | Portal | Crear solicitud | `solicitudes_proyecto.fecha_solicitud` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | DB |
| `fecha_fin` | Portal | Al finalizar | `solicitudes_proyecto.fecha_fin` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |
| `duracion_total_segundos` | Portal (calculado) | Al finalizar | `solicitudes_proyecto.duracion_total_segundos` | `GET /api/fabrica/proyectos/{id}` | Detalle proyecto | Pendiente |

---

## 10. ENDPOINTS DEL PORTAL — ESTADO ACTUAL

| Endpoint | Estado | Problema |
|----------|--------|----------|
| `GET /api/version` | ✅ **Bueno** | Obtiene commit real de git, branch, python version |
| `GET /api/proyecto` | ❌ **Placeholder** | Devuelve `{"proyecto": "Hermes Enterprise", "estado": "activo"}` |
| `GET /api/workspace` | ❌ **Placeholder** | Devuelve `workspace_no_configurado` |
| `GET /api/git` | ❌ **Placeholder** | Devuelve branch `main`, 0 commits hardcoded |
| `GET /api/github` | ❌ **Placeholder** | Devuelve URL hardcoded |
| `GET /api/entorno` | ✅ **Bueno** | Usa platform module |
| `GET /api/azure` | ❌ **Placeholder** | Devuelve `no_configurado` |
| `GET /api/sqlite` | ❌ **Placeholder** | Devuelve `no_verificado` |
| `GET /api/despliegue` | ❌ **Placeholder** | Región y plataforma hardcoded |
| `GET /api/telemetria` | ❌ **Placeholder** | Devuelve ceros |
| `GET /api/bootstrap` | ❌ **Placeholder** | Devuelve `bootstrap_completado` |
| `GET /api/fabrica/proyectos` | ✅ **Funcional** | Proyectos reales desde DB |
| `GET /api/fabrica/proyectos/{id}` | ✅ **Funcional** | Datos reales de proyecto |
| `POST /api/fabrica/proyectos` | ✅ **Funcional** | Creación real con persistencia |
| `PUT /api/fabrica/proyectos/{id}/metadata` | ✅ **Funcional** | Actualiza metadata |
| `GET /api/fabrica/proyectos/{id}/eventos` | ✅ **Funcional** | Eventos desde DB |
| `GET /api/fabrica/proyectos/{id}/trace/json` | ✅ **Funcional** | Trazabilidad desde DB |
| `GET /api/fabrica/app-service-plans` | ✅ **Funcional** | Planes desde Azure ARM |
| `GET /health` | ⚠️ **Parcial** | No expone todos los checks |

## 11. HALLAZGOS CRÍTICOS

### Hallazgo 1: `event_logs` no existe en DB actual
La migración de esquema crea la tabla `event_logs` solo cuando el servicio se inicializa. La DB existente no la tiene.

### Hallazgo 2: Datos de Factory Runner no llegan completamente
El workflow `factory-run.yml` envía metadata vía PUT, pero no envía `factory_started_at`.

### Hallazgo 3: Control Plane no reporta metadata completa al Portal
El workflow `deploy-child.yml` registra pasos vía POST/paso, pero no envía metadata de `control_plane_run_id`, `readiness_result`, `functional_result`, `evidence_result`, `functional_pass_count`, `functional_fail_count`.

### Hallazgo 4: APIs placeholder en dashboard
Múltiples endpoints del dashboard devuelven valores hardcoded en lugar de consultar fuentes reales.

### Hallazgo 5: `servicio_datos_proyecto.py` simula resultados
Usa `_simular_resultado()` que devuelve placeholders.

## 12. PLAN DE CORRECCIÓN

1. **Migrar DB existente**: Agregar columnas faltantes y crear `event_logs` table
2. **Actualizar APIs dashboard**: Consultar fuentes reales (DB, git, Azure, sistema)
3. **Factory Runner metadata**: Agregar `factory_started_at` al payload
4. **Control Plane metadata**: Agregar reporte completo (`control_plane_*`, `readiness_*`, `functional_*`, `evidence_*`)
5. **Child CI tracking**: Agregar columna y captura de `child_ci_*` fields
6. **`servicio_datos_proyecto.py`**: Reemplazar `_simular_resultado` con consultas reales
7. **UI**: Corregir visualización de datos faltantes en templates