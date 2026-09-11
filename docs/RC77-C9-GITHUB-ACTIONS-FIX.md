# RC77-C9-FIX — GitHub Actions + OIDC + App Service Plan

## RESULTADO: PENDING

---

## 1. Problema encontrado

GitHub Actions CD no puede autenticarse en Azure mediante OIDC para proyectos Hermes NUEVOS.

### Síntoma
```
AADSTS700213: No matching federated identity record found for presented assertion
subject 'repo:FREDYASARMIENTOT@145993781/rc77-c9-fix-20260910-0735@1364116488:environment:production'
```

### Evidencia de GitHub Actions
- **CI**: ✅ Exitosa (Run ID: 34477797827)
- **CD**: ❌ Falló en `azure/login@v2` (Run ID: 34478014427)
- **URL CD**: https://github.com/FREDYASARMIENTOT/rc77-c9-fix-20260910-0735/actions/runs/34478014427
## 3. Diagnóstico completo

### 3a. ¿Qué identidad solicita GitHub Actions?
- **client-id**: `feb971aa-7655-4c6f-8aef-b9f3bb828f6b` (UR-Fabrica-Proyectos-AR)
- **tenant-id**: `ae525757-89ba-4d30-a2f7-49796ef8c604`
- **subscription-id**: `01bfad48-c092-4712-bc72-f141eb01a8d4`
- **auth-type**: SERVICE_PRINCIPAL (OIDC, sin client secret)

### 3b. Token OIDC generado por GitHub
- **Issuer**: `https://token.actions.githubusercontent.com`
- **Audience**: `api://AzureADTokenExchange`
- **Subject claim**: `repo:FREDYASARMIENTOT@145993781/rc77-c9-fix-20260910-0735@1364116488:environment:production`
- **job_workflow_ref**: `FREDYASARMIENTOT/rc77-c9-fix-20260910-0735/.github/workflows/deploy.yml@refs/heads/main`

### 3c. FIC existente en Azure AD
- **App Registration**: `UR-Fabrica-Proyectos-AR` (ID: `feb971aa-7655-4c6f-8aef-b9f3bb828f6b`)
- **Federated Credential subject**: `repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production`

### 3d. Mismatch
- El subject del token incluye `rc77-c9-fix-20260910-0735` (repo nuevo)
- La FIC solo acepta `HERMES-ENTERPRISE`
- Azure AD rechaza el exchange

---
## 5. Proyecto nuevo generado

| Propiedad | Valor |
|---|---|
| **Nombre** | `rc77-c9-fix-20260910-0735` |
| **Repositorio** | `FREDYASARMIENTOT/rc77-c9-fix-20260910-0735` |
| **Commit** | `798b695840586b71f671ed343484030aa1c300d9` |
| **WebApp** | `as-rc77c9fix202609100735` |
| **Factory** | `tools/Crear-HermesProyecto.ps1` (corregido) |

## 6. GitHub Actions CI

| Propiedad | Valor |
|---|---|
| **Workflow** | `CI - rc77-c9-fix-20260910-0735` |
| **Run ID** | `34477797827` |
| **Conclusión** | ✅ **success** |
| **URL** | https://github.com/FREDYASARMIENTOT/rc77-c9-fix-20260910-0735/actions/runs/34477797827 |

## 7. GitHub Actions CD

| Propiedad | Valor |
|---|---|
| **Workflow** | `CD - rc77-c9-fix-20260910-0735` |
| **Run ID** | `34478014427` |
| **Conclusión** | ❌ **failure** |
| **URL** | https://github.com/FREDYASARMIENTOT/rc77-c9-fix-20260910-0735/actions/runs/34478014427 |

### Jobs:
1. **Validate** ✅ success
2. **Build** ✅ success
3. **Deploy** ❌ failure (Azure Login OIDC)
## 8. OIDC

| Componente | Resultado |
|---|---|
| `azure/login@v2` ejecutado | ✅ Sí |
| Secrets configurados | ✅ Sí |
| Autenticación OIDC | ❌ **FAIL** |
| Error | `AADSTS700213` |
| Subject solicitado | `repo:FREDYASARMIENTOT@145993781/rc77-c9-fix-20260910-0735@...:production` |
| Subject configurado | `repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production` |

## 9. App Service Plan

- ✅ `provision-appservice.yml` corregido para crear SOLO el Plan
- ✅ No crea Web App automáticamente
- ✅ Web App se crea en etapa de CD

## 10. Web App

- ⏭️ **No creada** — CD bloqueado en OIDC

## 11. Deployment

- ❌ **No realizado** — CD falló antes de llegar al paso de deployment

## 12. Tests / Artifact / Landing

- Todos ❌ No ejecutados — Sin aplicación desplegada

## 13. Trazabilidad

```
Commit 798b695
  ↓ Push a main
CI Run 34477797827 ✅ success
  ↓ workflow: CI - rc77-c9-fix-20260910-0735
CD Run 34478014427 ❌ failure
  ↓ workflow: CD - rc77-c9-fix-20260910-0735
  ↓ azure/login@v2 con OIDC
AADSTS700213 🔴 (subject mismatch)
  ↓ (bloqueado)
Azure App Service: no creado
```

**Cadena rota en**: `azure/login@v2` → OIDC authentication

## 14. Qué quedó pendiente

1. ❌ **OIDC desde nuevo proyecto**: No puede funcionar sin modificar Azure AD
2. ❌ **Deployment real**: Bloqueado por OIDC
3. ❌ **Pruebas funcionales, adversarial, navegador**: Sin deployment

## 15. Próximo paso

### Opción A (Recomendada): Arquitectura correcta
- El CD debe orquestarse desde `HERMES-ENTERPRISE` mediante `workflow_dispatch`
- `HERMES-ENTERPRISE` tiene la FIC que funciona
- Nuevos proyectos solo tienen CI (sin deploy.yml)

### Opción B: Múltiples FICs
- Crear una FIC por proyecto nuevo en Azure AD
- Violenta la regla "NO modificar Azure Identity"

## 16. Referencias

- **Evidence**: `evidence/rc77-c9-fix-evidence.json`
- **Factory**: `tools/Crear-HermesProyecto.ps1`
- **CI template**: `tools/Templates/github/ci.yml`
- **CD template**: `tools/Templates/github/deploy.yml`
- **Provisioning**: `.github/workflows/provision-appservice.yml`
- **Azure Config**: `config/Hermes.Azure.json`
- **CD Run**: https://github.com/FREDYASARMIENTOT/rc77-c9-fix-20260910-0735/actions/runs/34478014427
- **CI Run**: https://github.com/FREDYASARMIENTOT/rc77-c9-fix-20260910-0735/actions/runs/34477797827
4. **Smoke Test** ⏭️ skipped

## 4. Cambios realizados

### 4a. `provision-appservice.yml` — Separar App Service Plan de Web App

**Antes**: Creaba App Service Plan + Web App + App Settings + Startup Command + Logging
**Después**: Crea SOLO App Service Plan. Web App se crea en etapa de Deployment.

### 4b. `tools/Templates/github/deploy.yml` — Web App en CD

- Agregado paso `Provision Web App (if not exists)` que crea la Web App antes del deploy
- Agregado placeholder `{{RESOURCE_GROUP}}`
- Corregido `PROJECT_NAME` de `${{ github.ref_name }}` a valor estático del proyecto

### 4c. `tools/Crear-HermesProyecto.ps1` — Nuevo placeholder

- Agregado `-replace '{{RESOURCE_GROUP}}'` para el nuevo placeholder

### 4d. `tools/Templates/github/ci.yml` — Sin cambios adicionales

- Ya corregido en sesión anterior (requirements.txt path)

---

## 2. Causa raíz

La **Federated Identity Credential (FIC)** en la App Registration `UR-Fabrica-Proyectos-AR`
solo confía en el repositorio `HERMES-ENTERPRISE`:

| Propiedad | Configurado (FIC) | Real (GitHub token) |
|---|---|---|
| **Subject** | `repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production` | `repo:FREDYASARMIENTOT@145993781/rc77-c9-fix-20260910-0735@1364116488:environment:production` |
| **Repositorio** | `HERMES-ENTERPRISE` | `rc77-c9-fix-20260910-0735` |
| **Environment** | `production` | `production` |
| **¿Coinciden?** | | ❌ NO |

El template `deploy.yml` generado por la fábrica asume que OIDC funciona desde
cualquier repositorio nuevo, pero la FIC está diseñada exclusivamente para
`HERMES-ENTERPRISE`.

### Arquitectura inconsistente

```
config/Hermes.Azure.json:
  AzureIdentityMode: "DedicatedApp"
  UseSharedInfrastructure: false
  OIDCFederatedSubject: "repo:...HERMES-ENTERPRISE:environment:production"
```

**Conclusión**: La fábrica genera un CD que NO puede funcionar desde un repo nuevo.