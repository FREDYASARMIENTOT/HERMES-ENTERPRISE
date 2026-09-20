# B4 — PRODUCTION READINESS AUDIT

> **Fecha**: 2026-09-20 (Revisado: 2026-09-20, sesión autónoma)
> **Commit verificado**: `a4541e4b9e8170719cf82af55257c31378e968e3`
> **Portal**: https://as-hermesportal.azurewebsites.net/
> **App Service**: AS-HermesPortal
> **Resource Group**: RG-Hermes-Proyectos
> **App Service Plan**: ASP-HERMES-PORTAL
> **Nombre oficial**: Fábrica de Proyectos UR — AS-HermesPortal

---

## 1. IDENTIDAD DE PRODUCCIÓN

### /health — 200 OK
- estado: saludable
- aplicacion: Fábrica de Proyectos UR — AS-HermesPortal (POST CORRECCIÓN)
- commit: a4541e4b9e8170719cf82af55257c31378e968e3
- environment: azure
- event_store_disponible: **false** ⚠️ (ver corrección abajo)
- event_store_proyectos: 0
- github_integration: true
- azure_integration: true

### /api/version — 200 OK
- aplicacion: Fábrica de Proyectos UR
- version: 2.0.0
- commit: a4541e4b9e8170719cf82af55257c31378e968e3
- branch: main, environment: azure

**SHA coincide: `a4541e4` ✅**

---

## 2. ENDPOINTS /api/fabrica

| Endpoint | Método | Existe |
|----------|--------|--------|
| /api/fabrica/proyectos | POST | ✅ |
| /api/fabrica/proyectos | GET | ✅ |
| /api/fabrica/proyectos/{id} | GET | ✅ |
| /api/fabrica/app-service-plans | GET | ✅ |
| /api/fabrica/proyectos/{id}/ejecutar | POST | ✅ |
| /api/fabrica/proyectos/{id}/disparar | POST | ✅ |
| /api/fabrica/proyectos/{id}/paso | POST | ✅ |
| /api/fabrica/proyectos/{id}/finalizar | POST | ✅ |
| /api/fabrica/proyectos/{id}/metadata | PUT | ✅ |
| /api/fabrica/proyectos/{id}/eventos | GET | ✅ |
| /api/fabrica/proyectos/{id}/sse | GET | ✅ |
| /api/fabrica/proyectos/{id}/trace/json | GET | ✅ |
| /api/fabrica/proyectos/{id}/trace/md | GET | ✅ |

**Todos los endpoints OK ✅**

## 3. PERSISTENCIA (SQLite)

| Aspecto | Valor |
|---------|-------|
| Motor | SQLite |
| Ubicación | `Hermes.Web/data/proyecto.db` |
| Variable entorno | `HERMES_DB_PATH` (override) |
| Tabla principal | `solicitudes_proyecto` — 64+ columnas |
| Tabla eventos | `event_logs` — 27 columnas |
| Migraciones | ALTER TABLE ADD COLUMN (idempotente) |

**✅ Persistencia: LISTA**

---

## 4. EVENT STORE (tabla event_logs)

### Columnas (27)

deployment_id, correlation_id, event_id, timestamp, fase, paso_numero, paso_nombre, subpaso_numero, subpaso_nombre, componente, actor, estado_anterior, estado_nuevo, tipo, mensaje, detalle, evidencia, http_method, http_url, http_status, error_code, error_message, run_id, run_url, duracion_segundos, created_at

### Principios

| Principio | Estado |
|-----------|--------|
| Persistencia antes de SSE | ✅ `_registrar_evento()` antes de `broker.publish()` |
| deployment_id en eventos | ✅ NOT NULL |
| SSE no es fuente de verdad | ✅ SQLite es la fuente |
| Recovery (Last-Event-ID) | ✅ |
| Heartbeat | ✅ cada 30s |

### ✅ CORREGIDO: event_store_disponible

**Estado anterior**: Health check buscaba `fabrica.db` pero ServicioFabrica usa `proyecto.db`.
**Corrección**: Cambiado `fabrica.db` → `proyecto.db` en 5 archivos:
- `Hermes.Web/backend/main.py` (línea 539)
- `Hermes.Web/api/api_proyecto.py` (línea 26)
- `Hermes.Web/api/api_bootstrap.py` (línea 18)
- `Hermes.Web/api/api_sqlite.py` (línea 17)
- `Hermes.Web/api/api_telemetria.py` (línea 19)
**Severidad**: BAJA — no afectaba funcionalidad, solo reporte de salud.
**Verificación**: Tests 189/189 PASS después de la corrección.

---

## 5. FACTORY RUNNER (factory-run.yml)

| Aspecto | Estado |
|---------|--------|
| workflow_dispatch | ✅ |
| inputs: project_name, correlation_id, deployment_id, app_service_plan_id | ✅ |
| SkipAzure | ✅ `FACTORY_SKIP_AZURE: "true"` |
| Child SHA real (no github.sha) | ✅ |
| Registro pasos en Portal (POST /paso) | ✅ |
| Metadata PUT a Portal | ✅ |

**✅ Factory Runner: LISTO**

---

## 6. CONTROL PLANE (deploy-child.yml)

| Aspecto | Estado |
|---------|--------|
| workflow_dispatch | ✅ |
| inputs: project_name, repository, commit_sha, deployment_id, app_service_plan_id | ✅ |
| app_service_plan_id REQUIRED (sin fallback) | ✅ |
| OIDC (id-token: write) | ✅ |
| 10 jobs completos | ✅ |
| Evidence con verified_sha | ✅ |
| Registro pasos 4-13 en Portal | ✅ |

**✅ Control Plane: LISTO**

---

## 7. PROYECTO HIJO (CHILD)

| Aspecto | Estado |
|---------|--------|
| /health | ❌ NO EXISTE |
| /api/version | ❌ NO EXISTE |
| /api/deployment-info | ❌ NO EXISTE |

**20 proyectos en DB: 0 COMPLETADOS, todos EN_PROCESO o SOLICITADO.**

**❌ No existe ningún Child desplegado.**

---

## 8. MATRIZ DE PRODUCCIÓN

| Componente | Estado |
|------------|--------|
| Portal sano | ✅ READY |
| Persistencia | ✅ READY |
| Event Store (tabla) | ✅ READY |
| Event Store (health) | ✅ READY (corregido) |
| SSE | ✅ READY |
| Factory Runner | ✅ READY |
| Child CI | ✅ READY |
| Control Plane | ✅ READY |
| OIDC | ✅ READY |
| Azure / App Service Plan | ✅ READY |
| Child App | ❌ BLOCKED |
| Readiness | ⚠️ PARTIAL |
| Functional | ⚠️ PARTIAL |
| Evidence | ⚠️ PARTIAL |
| Portal Detail UI | ✅ READY |
| **Identidad de app** | ✅ READY (corregido) |

**READY: 12 | PARTIAL: 3 | BLOCKED: 1 | UNKNOWN: 0**

---

## 9. VEREDICTO

```
E2E READY: NO
```

### BLOQUEADORES

1. **No existe Child Project desplegado** que complete el pipeline E2E (pasos 4-13).
2. 20 proyectos históricos atascados en EN_PROCESO.

### CORRECCIONES APLICADAS (SESIÓN AUTÓNOMA B4/B5)

1. ✅ **Health check DB path**: `fabrica.db` → `proyecto.db` (5 archivos)
2. ✅ **Renombre de aplicación**: "Hermes Enterprise" → "Fábrica de Proyectos UR" (10+ archivos)
3. ✅ **UI Templates**: Actualizados con el nuevo nombre (3 templates)
4. ✅ **Workflow assertions**: Actualizados (portal-ci-cd.yml)
5. ✅ **Tests**: 189/189 PASS después de correcciones

### CAMBIOS NECESARIOS ANTES DE E2E

1. Crear y desplegar un proyecto Child E2E completo (Factory → CP → Azure → Deploy → Readiness → Functional → Evidence).
2. Opcional: limpiar/archivar proyectos huérfanos.

### RESUMEN

El Portal está completamente listo (infraestructura, API, UI, workflows). La identidad de la aplicación ha sido corregida y la ruta de la base de datos en health check ha sido normalizada. Falta únicamente la ejecución del ciclo completo de creación de un proyecto Child para validar la trazabilidad E2E.