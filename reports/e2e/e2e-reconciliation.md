# FASE 24 — TRACEABILITY RECONCILIATION
# Fecha: 2026-09-20

## Hallazgo 1: CI #147 Drift Classification

| Workflow | Result | Classification | Justification |
|----------|--------|----------------|---------------|
| deploy.yml | WARN+FAIL | LEGACY | AS-HermesEnterprise deleted. Workflow says "DEPLOY DISABLED". No debe ser validado. |
| deploy-child.yml | WARN+FAIL | FALSE_POSITIVE | "artifact upload" no aplica (deploy via Azure CLI). "startup-command" auto-detectado. No hay drift real. |
| ci.yml (real) | PASS | CORRECT | |
| ci.yml (template) | PASS | CORRECT | |

### Action:
- [ ] Fix validator: skip deploy.yml (legacy)
- [ ] Fix validator: don't require artifact upload for deploy-type workflows
- [ ] Fix validator: don't require startup-command (auto-detected by Azure)

## Hallazgo 2: Database

**Estado**: PERSISTENCIA REAL FUNCIONAL (parcial)

- **event_logs**: ✅ EXISTS (27 columns, 55 rows)
- **Migration**: ✅ Idempotent (ALTER TABLE ADD COLUMN with try/except)
- **Missing columns in existing DB**: child_ci_run_id, child_ci_run_url, child_ci_status, child_ci_started_at, child_ci_finished_at, child_ci_duration, azure_state, azure_location, azure_subscription_id, azure_web_app_name, readiness_http_status, readiness_url, readiness_timestamp, evidence_status, evidence_url, branch
- **Fix**: Migration runs on next Portal restart — no code change needed

## Hallazgo 3: Factory Runner

- **factory_started_at**: ✅ CORRECT — already in factory-run.yml line 428
- Format: `$(date -u +%Y-%m-%dT%H:%M:%SZ)`

## Hallazgo 4: Control Plane Metadata

**Missing from PUT metadata**:
- evidence_result ❌
- evidence_url ❌
- azure_hostname ❌
- azure_state ❌
- azure_location ❌

**Action**: Add these to deploy-child.yml PUT payload

## Hallazgo 5: Child CI Tracking

- **child_ci_***: NOT CAPTURED — paso 4 is hardcoded
- Register_paso 4 uses `"COMPLETADO"` and `"PASS"` — not real data
- **Action**: Need real GitHub Actions dispatch tracking

## Hallazgo 6: servicio_datos_proyecto.py _simular_resultado

| Method | Usage | Classification | Action |
|--------|-------|---------------|--------|
| obtener_estado_telemetria() | **ALWAYS** | PRODUCTION | REFACTOR — gets real data |
| obtener_estado_despliegue() | **ALWAYS** | PRODUCTION | REFACTOR — gets real data |
| obtener_version_hermes() | fallback | PRODUCTION (fallback) | KEEP |
| obtener_estado_proyecto() | fallback | PRODUCTION (fallback) | KEEP |
| obtener_estado_workspace() | fallback | PRODUCTION (fallback) | KEEP |
| obtener_estado_git() | fallback | PRODUCTION (fallback) | KEEP |

## Hallazgo 7: Runtime Child

**Status**: RUNTIME_NO_VALIDADO
- SCM_DO_BUILD: configured
- startup.sh: pip install removed
- Need real Child deployment to validate

## Summary

| Item | Status |
|------|--------|
| DB event_logs | ✅ REAL |
| Migration idempotent | ✅ CORRECT |
| Factory started_at | ✅ CORRECT |
| Control Plane metadata | ❌ PENDING |
| Child CI tracking | ❌ PENDING |
| servicio_datos_proyecto sim | ❌ PENDING REFACTOR |
| API returns real metadata | ✅ CORRECT (dependent on DB migration) |
| UI shows real metadata | ❌ PENDING |
| Validator classification | ✅ COMPLETE (this report) |
| Runtime validated | ❌ NO_VALIDADO |