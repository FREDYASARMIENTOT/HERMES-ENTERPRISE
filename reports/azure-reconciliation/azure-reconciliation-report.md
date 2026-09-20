# Resource Reconciliation Report - RF-RECONCILIACION-002

## Summary

| Item | Status |
|------|--------|
| Azure App Service verification | IMPLEMENTED (ARM API) |
| GitHub Repository verification | IMPLEMENTED (GitHub API v3) |
| Runtime/VENV verification | IMPLEMENTED (Health endpoint) |
| 3-resource reconciliation | COMPLETE |
| Active/Historic separation | Azure EXISTE = Active |
| Event Store | Reconciliation events registered |
| Resultado historico preserved | PASS/FAIL untouched |
| Dashboard updated | GitHub + Runtime counters |
| Column RECURSOS added | VENV | GITHUB | APP SERVICE |
| Single resource endpoint | GET /{id}/resource-status |
| Mass reconciliation | GET /reconcile (all 3 resources) |
| Unit tests | 14/14 PASS |
| Commit | f8ecabe pushed to origin/main |

## Architecture

For each deployment, 3 independent resources are verified:

PROYECTO -> RUNTIME/VENV (health endpoint of App Service)
PROYECTO -> GITHUB (GitHub REST API /repos/{owner}/{repo})
PROYECTO -> AZURE APP SERVICE (Azure ARM REST API Microsoft.Web/sites)

Each resource has its own status: EXISTE, NO_EXISTE, ERROR, NO_VERIFICADO.

## New API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| GET | /api/fabrica/proyectos/{id}/resource-status | Full 3-resource status |
| POST | /api/fabrica/proyectos/{id}/github-check | Verify GitHub now |
| POST | /api/fabrica/proyectos/{id}/runtime-check | Verify Runtime now |
| GET | /api/fabrica/proyectos/reconcile | Mass reconcile (all resources) |

## Commit

f8ecabe feat(reconciliacion): RF-RECONCILIACION-002 inventario real de 3 recursos

## Portal

URL: https://as-hermesportal.azurewebsites.net/
CI/CD: GitHub Actions auto-deploys on main push
