# REPORTE E2E — HERMES-ENTERPRISE

## Información General

- **Fecha**: 2026-09-20
- **Commit**: 66313f8
- **Último cambio**: fix(portal): FASE-24 E2E traceability
- **Portal**: https://as-hermesportal.azurewebsites.net/

## Resumen de Cambios Realizados

### 1. Persistencia (Schema DB)
| Columna | Estado |
|---------|--------|
| child_ci_run_id | ✅ AGREGADO |
| child_ci_run_url | ✅ AGREGADO |
| child_ci_status | ✅ AGREGADO |
| child_ci_started_at | ✅ AGREGADO |
| child_ci_finished_at | ✅ AGREGADO |
| child_ci_duration | ✅ AGREGADO |
| zure_hostname | ✅ AGREGADO (ya en SELECT) |
| zure_state | ✅ AGREGADO |
| zure_location | ✅ AGREGADO |
| zure_subscription_id | ✅ AGREGADO |
| zure_web_app_name | ✅ AGREGADO |
| eadiness_http_status | ✅ AGREGADO |
| eadiness_url | ✅ AGREGADO |
| eadiness_timestamp | ✅ AGREGADO |
| vidence_status | ✅ AGREGADO |
| vidence_url | ✅ AGREGADO |
| ranch | ✅ AGREGADO |

### 2. APIs Corregidas
| Endpoint | Antes | Después |
|----------|-------|---------|
| /api/azure | 
o_configurado | Consulta Azure ARM REST API real |
| /api/git | branch main, 0 commits | Commit, branch, count reales |
| /api/github | URL hardcoded | Verificación GitHub API real |
| /api/workspace | 
o_configurado | Estructura real del workspace |
| /api/despliegue | Región hardcoded | Info real del entorno |
| /api/telemetria | Ceros | Métricas desde DB real |
| /api/bootstrap | ootstrap_completado | Componentes reales |
| /api/proyecto | Placeholder | Estadísticas desde DB real |
| /health | Parcial | Checks reales (DB, GitHub, Azure) |

### 3. Startup.sh
- **Línea 8-9**: pip install -r requirements.txt -q → **ELIMINADO**
- Razón: SCM_DO_BUILD_DURING_DEPLOYMENT=true ya instalado por Oryx durante deploy

### 4. Factory Runner
- Agregado actory_started_at al payload de metadata (usando ${{ github.run_started_at }})

### 5. Tests
- **80/80** traceability tests ✅
- **95/95** portal canonico tests ✅
- **14/14** azure reconciliation tests ✅
- **Total: 189/189** tests PASS

## Pendiente

| Item | Prioridad | Acción |
|------|-----------|--------|
| Control Plane metadata completa | ALTA | Agregar evidence_*, azure_hostname a deploy-child.yml |
| Captura child_ci_* en workflow | MEDIA | Agregar al factory-run.yml / deploy-child.yml |
| servicio_datos_proyecto.py | BAJA | Refactorizar _simular_resultado |
| UI templates | MEDIA | Mostrar nuevos campos child_ci_*, azure_* |
| Prueba E2E real desde navegador | ALTA | Manual - crear proyecto desde Portal |

## Commit

- 49285b - fix(portal): FASE-24 E2E traceability
- 66313f8 - docs: update TRACEABILITY-MATRIX.md
