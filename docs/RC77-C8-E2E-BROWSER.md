# RC77-C8: Operational Deployment Landing Page — E2E Browser Test

## Objective
Replace the "Hello World" static landing page with a fully dynamic **HERMES ENTERPRISE — INFORME DE DESPLIEGUE** operational dashboard that displays real deployment data, functional test results, and access links.

## Architecture

```
User Browser
   │
   ├─ GET /  ──────────────► FastAPI (Jinja2 template) ──► SQLite
   ├─ GET /health ─────────► FastAPI ──► {status, db, version}
   ├─ GET /api/version ────► FastAPI ──► {app, version, commit}
   ├─ GET /api/proyecto ───► FastAPI ──► SQLite ──► {project info}
   ├─ GET /openapi.json ───► FastAPI (auto-generated)
   ├─ GET /swagger ────────► FastAPI (Swagger UI)
   ├─ GET /redoc ──────────► FastAPI (ReDoc UI)
   └─ GET /nonexistent ───► FastAPI ──► 404 JSON {detail, path, method}
```

### Key Components

| Component | Role |
|-----------|------|
| `tools/Templates/backend/main.py` | Server-rendered HTML template with Jinja2-like placeholders → replaced at project creation |
| `tools/Modules/RenderEngine.ps1` | `New-ProyectoLanding` function renders the deployment report HTML |
| `tools/Modules/SmokeTests.ps1` | `Test-ProyectoLanding` validates title, content, negative checks, AZ204 compliance |
| `tools/Crear-HermesProyecto.ps1` | Orchestrates full pipeline: create → build → deploy → test → open browser |
| `Hermes.Web/backend/main.py` (deployed) | FastAPI backend serving all endpoints + SQLite-backed landing page |

## Pipeline Steps

1. **Create project** — copies templates, replaces `{{PLACEHOLDERS}}` with project-specific values
2. **Build + Deploy** — packages as ZIP, deploys to Azure App Service (Python 3.12)
3. **Smoke Tests** — validates all 7+ endpoints with HTTP codes and response times
4. **Auto-Correction** — if partial failure, re-deploys and re-tests (up to 2 cycles)
5. **Deployment Report** — generates `deployment-report.json` in project root with full metadata
6. **Landing Update** — re-renders landing page with live SQLite data (pass/fail per endpoint)
7. **Browser** — automatically opens `https://<app>.azurewebsites.net/`
8. **Git Commit + Push** — final commit and push to GitHub

## Command

```powershell
# Full E2E (creates new project, deploys, tests, opens browser):
.\tools\Crear-HermesProyecto.ps1 -NombreProyecto "rc77-c8-browser-<timestamp>"

# Run smoke tests only against a deployed app:
.\tools\Modules\SmokeTests.ps1 -BaseUrl "https://<app>.azurewebsites.net"
```

## Validation Criteria

| Test | Expected | Negative Check |
|------|----------|----------------|
| Landing title | Contains "HERMES ENTERPRISE — INFORME DE DESPLIEGUE" | Rejects "Hello World" |
| Project name | Matches project name from SQLite | Rejects Azure default page |
| Status badge | `🟢 OPERATIVO` when all tests pass, `🔴 FALLIDO` otherwise | — |
| Functional tests | Real HTTP codes (200, 404) with PASS/FAIL | No hardcoded "PASS" |
| Endpoint list | 7+ endpoints displayed with actual response times | — |
| Timeline | Shows build, deploy, test events with timestamps | — |
| Access links | Frontend, Health, Swagger, OpenAPI, Version, Proyecto, ReDoc all clickable | — |
| Azure/GitHub/CI | Status badges for each | — |

## Results (RC77-C8)

> **Note:** Full E2E test requires live Azure subscription. Evidence below reflects the verified integration test results from the development environment.

- ✅ Landing page renders dynamic deployment report (no "Hello World")
- ✅ All 7 endpoints respond with expected HTTP codes
- ✅ `Test-ProyectoLanding` validates title, content, negative checks
- ✅ `deployment-report.json` generated with project metadata and test results
- ✅ Enhanced success banner displays all access links
- ✅ `{{REGION}}` and `{{DEPLOYMENT_ID}}` injected during project creation
- ✅ `New-ProyectoLanding` accepts `$WebAppName` parameter for accurate URLs