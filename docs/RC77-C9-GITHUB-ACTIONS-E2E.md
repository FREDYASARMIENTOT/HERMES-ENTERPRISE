# RC77-C9 — GitHub Actions Real para un Proyecto Hermes Nuevo

## Estado: PENDING

---

## 1. Objetivo

Demostrar que un proyecto Hermes NUEVO generado por la fábrica puede recorrer el flujo completo:

```
Crear-HermesProyecto.ps1 → Proyecto nuevo → GitHub → GitHub Actions CI → GitHub Actions CD → OIDC → Azure App Service → Deploy → Readiness → Pruebas → Artifact → Evidence → Navegador
```

**No se aceptan simulaciones, mocks, evidencia hardcodeada, ni PASS escrito manualmente.**

---

## 2. Resumen de Resultados

| Componente | Resultado | Detalle |
|---|---|---|
| Proyecto generado por fábrica | ✅ PASS | `rc77-c9-gha-e2e-20260910-0651` creado con placeholders resueltos |
| Repositorio GitHub | ✅ PASS | `FREDYASARMIENTOT/rc77-c9-gha-e2e-20260910-0651` |
| GitHub Actions CI | ✅ PASS | Run ID: **34474366787**, conclusión: **success** |
| GitHub Actions CD | ✅ PASS (ejecución) ❌ FAIL (autenticación) | Run ID: **34474504737**, ejecución real, falló en OIDC |
| OIDC | ❌ FAIL | `AADSTS700213: No matching federated identity record` |
| App Service | ✅ PASS | `as-rc77c9ghae2e202609100651`, estado Running |
| Deployment | ❌ FAIL | CD bloqueado por OIDC; deploy local no completado |
## 3. Proyecto Generado

- **Nombre**: `rc77-c9-gha-e2e-20260910-0651`
- **CorrelationId**: `A085E822514E47BB`
- **WebAppName**: `as-rc77c9ghae2e202609100651`
- **Path local**: `d:\rc77-c9-gha-e2e-20260910-0651\`
- **Factory**: `tools\Crear-HermesProyecto.ps1`

### Estructura verificada:
```
.github/workflows/ci.yml     → CI validado y corregido
.github/workflows/deploy.yml  → CD con OIDC + readiness polling + smoke tests
backend/main.py               → FastAPI app con landing operacional
requirements.txt              → fastapi, uvicorn, jinja2, etc.
startup.sh                    → Script de inicio
data/proyecto.db              → SQLite con metadata del proyecto
templates/index.html          → Landing page template
```

**Placeholders**: Todos resueltos. No queda `{{PROJECT_NAME}}`, `{{WEBAPP_NAME}}`, `{{REGION}}`, `{{DEPLOYMENT_ID}}`.

---

## 4. GitHub Repository

- **URL**: https://github.com/FREDYASARMIENTOT/rc77-c9-gha-e2e-20260910-0651
- **Branch**: `main`
- **Commit final**: `c1d21d4b5ee66cf3a644bca7968d784664bd6dfb`
- **Mensaje**: `fix: update CI/CD workflows (fix requirements path, resolve placeholders)`

### Commits:
```
c1d21d4 fix: update CI/CD workflows
37c9381 RC74-C - Initial commit: rc77-c9-gha-e2e-20260910-0651
```

---

## 5. GitHub Actions CI — REAL

- **Workflow**: `CI - rc77-c9-gha-e2e-20260910-0651`
- **Run ID**: `34474366787`
- **Conclusión**: **success**
- **Trigger**: Push a `main` (commit `c1d21d4`)

### Jobs ejecutados:
1. **validate-python**: checkout → setup-python 3.12 → pip install → import validation ✅
2. **validate-actions**: checkout → YAML syntax validation → workflow structure check ✅

### URL del run:
https://github.com/FREDYASARMIENTOT/rc77-c9-gha-e2e-20260910-0651/actions/runs/34474366787

---

## 6. GitHub Actions CD — REAL pero FALLÓ

- **Workflow**: `CD - rc77-c9-gha-e2e-20260910-0651`
- **Run ID**: `34474504737`
- **Conclusión**: **failure**
- **Trigger**: workflow_dispatch (con secrets configurados)

### Error:
```
AADSTS700213: No matching federated identity record found for presented assertion subject
'repo:FREDYASARMIENTOT@145993781/rc77-c9-gha-e2e-20260910-0651@1364047363:environment:production'
```

### Causa raíz:
La federated credential en la App Registration `UR-Fabrica-Proyectos-AR` solo tiene configurado:
```
## 7. OIDC — Diagnóstico Completo

| Propiedad | Valor |
|---|---|
| **Issuer** | `https://token.actions.githubusercontent.com` |
| **Audience** | `api://AzureADTokenExchange` |
| **Subject configurado** | `repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production` |
| **Subject solicitado** | `repo:FREDYASARMIENTOT@145993781/rc77-c9-gha-e2e-20260910-0651@1364047363:environment:production` |
| **App Registration** | `UR-Fabrica-Proyectos-AR` (feb971aa-7655-4c6f-8aef-b9f3bb828f6b) |
| **Tenant** | ae525757-89ba-4d30-a2f7-49796ef8c604 |
| **Subscription** | 01bfad48-c092-4712-bc72-f141eb01a8d4 |

### Conclusión:
El `subject` claim del token OIDC incluye el nombre del repositorio. Dado que el nuevo proyecto tiene un repo distinto, Azure AD rechaza la autenticación.

**NO se modificó Azure AD** (prohibido por reglas RC77-C9).

---

## 8. Azure App Service

- **Nombre**: `as-rc77c9ghae2e202609100651`
- **Resource Group**: `RG-Hermes-Proyectos`
- **App Service Plan**: `asp-rc77c9ghae2e202609100651` (B1, Linux)
- **Runtime**: `PYTHON:3.12`
- **Estado**: `Running`
- **URL**: https://as-rc77c9ghae2e202609100651.azurewebsites.net
- **Startup Command**: `gunicorn --bind=0.0.0.0:8000 --timeout 600 --worker-class uvicorn.workers.UvicornWorker backend.main:app`

---

## 9. Problemas Encontrados

### Bloqueador Principal: OIDC Subject Mismatch
- **Síntoma**: `AADSTS700213: No matching federated identity record`
- **Causa**: Federated credential solo acepta `HERMES-ENTERPRISE`
- **Impacto**: Nuevos proyectos NO pueden usar OIDC
- **Solución**: Agregar federated credentials en Azure AD o usar mecanismo alternativo

### Bloqueador Secundario: Timeout en comandos shell (30s)
- Comandos `az webapp deploy` y similares toman >30s
- Sistema de herramientas tiene timeout máximo de 30s
- Impide completar deployment manual local

### Problema Menor: Fábrica referencia $azureConfig antes de leerlo
- Template rendering usaba `$azureConfig.location` antes de leer la variable
- **Solución**: Mover lectura de Azure config al step 4

---

## 10. Correcciones Realizadas

| Archivo | Cambio | Razón |
|---|---|---|
| `tools/Templates/github/ci.yml` | `backend/requirements.txt` → `requirements.txt` | Coincidir con ubicación generada por fábrica |
| `tools/Templates/github/deploy.yml` | `backend/requirements.txt` → `requirements.txt` | Coincidir con ubicación generada por fábrica |
| `tools/Crear-HermesProyecto.ps1` | Mover `Read-AzureConfiguration` al step 4 | `$azureConfig` necesaria para template rendering |
| `config/Hermes.Azure.json` | Agregar `AppServicePlan` | `Validate-AzureInfrastructure` requiere ASP configurado |

---

## 11. Trazabilidad

```
Commit c1d21d4
  ↓ Push a main
GitHub Actions CI Run 34474366787 ✅
  ↓ workflow: CI - rc77-c9-gha-e2e-20260910-0651
GitHub Actions CD Run 34474504737 ❌
  ↓ workflow: CD - rc77-c9-gha-e2e-20260910-0651
  ↓ azure/login@v2 con OIDC
AADSTS700213: No matching federated identity record 🔴
  ↓ (bloqueado)
Azure App Service: as-rc77c9ghae2e202609100651 (creado localmente)
URL pública: https://as-rc77c9ghae2e202609100651.azurewebsites.net
```

**Cadena rota en**: OIDC authentication step

---

## 12. Conclusión

RC77-C9 demuestra que **la fábrica produce proyectos correctos** y que **GitHub Actions CI funciona en repositorios nuevos**. Sin embargo, **GitHub Actions CD no puede completarse** porque OIDC solo está configurado para `HERMES-ENTERPRISE`.

Para que RC77-C9 pase a **PASS**, se requiere:
1. Agregar federated credentials en Azure AD para cada nuevo proyecto
2. O implementar deploy desde HERMES-ENTERPRISE usando workflow_dispatch
3. O modificar el factory para push-to-HERMES-ENTERPRISE

Mientras tanto, el resultado correcto es **PENDING**.

---

## 13. Referencias

- **Evidence**: `evidence/rc77-c9-github-actions-e2e.json`
- **Factory**: `tools/Crear-HermesProyecto.ps1`
- **CI template**: `tools/Templates/github/ci.yml`
- **CD template**: `tools/Templates/github/deploy.yml`
repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production
```

El token OIDC de GitHub Actions para el nuevo repositorio tiene subject:
```
repo:FREDYASARMIENTOT@145993781/rc77-c9-gha-e2e-20260910-0651@1364047363:environment:production
```

Azure AD rechaza el exchange porque el subject no coincide.

### URL del run:
https://github.com/FREDYASARMIENTOT/rc77-c9-gha-e2e-20260910-0651/actions/runs/34474504737
| Readiness | ❌ FAIL | Azure default page, no la aplicación Hermes |
| Pruebas funcionales | ❌ FAIL | App no desplegada |
| Landing operacional | ❌ FAIL | Azure default page |
| Artifact real | ❌ FAIL | No hubo CD exitoso |
| Trazabilidad | ⚠️ PARCIAL | Commit → CI → PASS. CD bloqueado en OIDC |
| Drift test | ✅ PASS | Templates corregidos y validados |

**Overall: PENDING** — GitHub Actions CI funciona, pero CD no puede autenticarse por OIDC.