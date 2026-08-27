# Azure Identity Migration — RC77-C2

## Current State: Dedicated App / OIDC Preparado

**Status:** `RC77-C2 PREPARED` (con 1 BLOCKER)

---

## Identidad Confirmada

| Atributo | Valor |
|---|---|
| **App Registration** | `UR-Fabrica-Proyectos-AR` |
| **Application (Client) ID** | `feb971aa-7655-4c6f-8aef-b9f3bb828f6b` |
| **Service Principal Object ID** | `5616db94-97be-44d4-8216-f38b704522c2` |
| **Tenant ID** | `ae525757-89ba-4d30-a2f7-49796ef8c604` |
| **Subscription ID** | `01bfad48-c092-4712-bc72-f141eb01a8d4` |

> ⚠️ NOTA HISTÓRICA: `feb971aa-7655-4c6f-8aef-b9f3bb828f6b` documentado originalmente como "SP Object ID" pero tras verificación es el **Application (Client) ID**. El SP Object ID real es `5616db94-97be-44d4-8216-f38b704522c2`.

---

## Arquitectura Definitiva

```
GitHub Actions Runner
    |
    |  permissions: { id-token: write, contents: read }
    v
GitHub OIDC Provider (token.actions.githubusercontent.com)
    |
    |  Federated Identity Credential (subject actualmente INCOMPLETO)
    v
Azure AD App Registration: UR-Fabrica-Proyectos-AR
    |  App ID: feb971aa-7655-4c6f-8aef-b9f3bb828f6b
    |  SP Object ID: 5616db94-97be-44d4-8216-f38b704522c2
    |  Federated Credential: github-production
    |    Subject: repo:FREDYASARMIENTOT/    ← INCOMPLETO
    |    Expected: repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production
    v
RBAC: Contributor
    |  Scope: /subscriptions/.../resourceGroups/RG-Hermes-Proyectos
    v
RG-Hermes-Proyectos
    |
    v
Azure App Services (per-project: as-{projectName})
```

## Security Model

- **No permanent secrets** in GitHub (OIDC token per-run)
- **No `AZURE_CREDENTIALS`** JSON file
- **No Client Secret** stored
- **No subscription-wide permissions**
- **Zero Graph API permissions** on App Registration
- **Guardian protection active** on `RG-Hermes-Proyectos`

---

## Prerequisites Status

| Requirement | Status | Detail |
|---|---|---|
| App Registration `UR-Fabrica-Proyectos-AR` | ✅ EXISTENTE | Creado 2026-08-18 |
| Service Principal | ✅ EXISTENTE | Object ID: `5616db94-97be-44d4-8216-f38b704522c2` |
| RBAC Contributor | ✅ VALIDADO | Scope: `RG-Hermes-Proyectos` |
| GitHub Secrets (3) | ✅ PRESENTES | AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID |
| GitHub Environment `production` | ✅ CREADO | 2026-08-27 |
| Federated Credential | ⚠️ BLOQUEO | Subject incompleto: `repo:FREDYASARMIENTOT/` |
| OIDC E2E Test | ⏳ NOT_RUN | Pendiente de corregir federated credential |

---

## Federated Credential Issue

**Observado:**
```json
{
  "subject": "repo:FREDYASARMIENTOT/",
  "issuer": "https://token.actions.githubusercontent.com",
  "audiences": ["api://AzureADTokenExchange"]
}
```

**Requerido:**
```
subject: repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production
```

El subject actual es incompleto. GitHub Actions envía un subject claim con el formato completo `repo:owner/repo:environment:env`. Azure AD requiere coincidencia exacta. Sin corrección, cualquier intento de OIDC fallará.

### Acción Requerida

Actualizar la federated credential existente:

```powershell
# Obtener Object ID de la App Registration
$appObjectId = az ad app show --id "feb971aa-7655-4c6f-8aef-b9f3bb828f6b" --query id -o tsv

# Actualizar subject
az ad app federated-credential update `
  --id $appObjectId `
  --federated-credential-id "a2f3f6f7-45a3-45c9-a822-a6501b2df9e5" `
  --subject "repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production"
```

---

## Workflow Audit

| File | OIDC Config | Hardcoded Secrets | projectName Validation | Notes |
|---|---|---|---|---|
| `.github/workflows/ci.yml` | ✅ id-token: write | ✅ None | N/A (CI only) | Sin Azure login |
| `.github/workflows/deploy.yml` | ✅ azure/login@v2 | ✅ None | ⚠️ Sin validar | OIDC correcto |
| `.github/workflows/provision-appservice.yml` | ✅ azure/login@v2 | ✅ None | ✅ Validado | Endurecido RC77 |

---

## Verified Provisioned Resources

| Recurso | Nombre | Estado | RG |
|---|---|---|---|
| App Service Plan | `asp-test-prueba` | Linux B1 | RG-Hermes-Proyectos |
| Web App | `as-test-prueba` | Running | RG-Hermes-Proyectos |

---

## Guardian Status

- ✅ Config found: `Hermes.InfrastructureProtection.json` version 1.1.0
- ✅ Blocked operations include `az group delete`, `az webapp delete`, `az appservice plan delete`
- ✅ `RG-Hermes-Proyectos` is protected
- ✅ No bypass detected
- ✅ No `-Force` in workflows

## Resource Locks

- ℹ️ No locks on `RG-Hermes-Proyectos`

---

## Migration History

| Phase | Status | Date |
|---|---|---|
| RC75-C: Initial Identity Audit | ✅ COMPLETED | 2026-08-07 |
| RC75-C1: App Registration Analysis | ✅ COMPLETED | 2026-08-08 |
| RC77: Provision App Service Workflow | ✅ PREPARED | 2026-08-26 |
| **RC77-C2: Identity Finalization** | **⚠️ READY_FOR_E2E (con BLOCKER)** | **2026-08-27** |

---

*Document updated: 2026-08-27*
*Phase: RC77-C2 — Identity Finalization*








