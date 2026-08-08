# RC75-C1 — Azure Authentication Audit & OIDC Migration Report

## Executive Summary

This report documents the audit of Azure authentication mechanisms used by Hermes Enterprise (Factory) and the generated projects. It identifies what works, what is blocked, and the exact steps required to complete OIDC federated identity.

---

## 1. Current Authentication Architecture

### Hermes Enterprise (Factory)

| Component | Auth Method | Status |
|---|---|---|
| `.github/workflows/deploy.yml` | OIDC via `azure/login@v2` | ⚠️ Needs secrets |
| `tools/Modules/Azure.ps1` | `az` CLI (local session) | ✅ Works locally |
| `Crear-HermesProyecto.ps1` | `az` CLI (local session) | ✅ Works locally |
| GitHub Actions Factory | OIDC reference (no secrets set) | ❌ Blocked |

### Generated Projects (template)

| Component | Auth Method | Status |
|---|---|---|
| `.github/workflows/deploy.yml` template | OIDC via `azure/login@v2` | ⚠️ Needs per-project secrets |
| CI workflow template | No Azure auth needed | ✅ Works |

### Deploy Workflow OIDC Configuration

Both Factory and project templates use:
```yaml
- name: Azure Login (OIDC)
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

---

## 2. Secrets Audit

### GitHub Repository Secrets (FREDYASARMIENTOT/HERMES-ENTERPRISE)

| Secret | Status | Required For |
|---|---|---|
| `AZURE_CLIENT_ID` | ❌ NOT SET | OIDC auth (Factory + Projects) |
| `AZURE_TENANT_ID` | ❌ NOT SET | OIDC auth (Factory + Projects) |
| `AZURE_SUBSCRIPTION_ID` | ❌ NOT SET | OIDC auth (Factory + Projects) |
| `AZURE_CREDENTIALS` | ❌ NOT SET | Legacy auth (not recommended) |

**Root cause:** These secrets have never been configured at the repository level. The deploy workflows reference them but GitHub Actions would fail at runtime with "secret not found" errors.

### Organization-Level Secrets (FREDYASARMIENTOT)

Not applicable — `FREDYASARMIENTOT` is a personal GitHub account, not an organization. No org-level secrets exist.

### Local Azure Authentication

| Method | Status | Notes |
|---|---|---|
| `az login` interactive | ✅ Works | Used by developer for local operations |
| `az login --service-principal` | ❌ Not configured | No service principal available |
| Managed Identity | ❌ Not configured | N/A for local dev |

---

## 3. Azure AD App Registration Audit

### Existing App Registrations

| Display Name | App ID | Purpose |
|---|---|---|
| `Modelo-IA-UR-Modelo-IA-UR-Hermes-HermesEnterpriseSeniorCodingAgent-57d59-AgentIdentityBlueprint` | `3ac1cae9-acd2-46cb-9d3f-1abd19510fd8` | Unknown/legacy |

### Required App Registrations

| Required App | Purpose | Status |
|---|---|---|
| `Hermes-Enterprise-CI` | OIDC federated identity for Factory CI/CD | ❌ BLOCKED — Cannot create |

### Creation Attempt

```
Command: az ad app create --display-name "Hermes-Enterprise-CI" --sign-in-audience AzureADMyOrg
Result: ERROR: Insufficient privileges to complete the operation.
```

**The current user does NOT have Azure AD Application Administrator permissions** and cannot create App Registrations.

---

## 4. Blockers Identified

### Blocker 1: App Registration Creation (HUMAN_REQUIRED)

**Status:** 🛑 BLOCKED
**Impact:** Cannot create OIDC federated credential
**Requires:** Azure AD Administrator with Application Admin role
**Action:** Manual creation of App Registration + federated credentials

### Blocker 2: GitHub Secrets Configuration (HUMAN_REQUIRED)

**Status:** 🛑 BLOCKED
**Impact:** Factory deploy.yml will fail; project templates will fail
**Requires:** GitHub repo admin to set secrets
**Action:** Set `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`

### Blocker 3: Subscription ID Unknown

**Status:** ⚠️ Not yet verified
**Impact:** Cannot complete OIDC setup
**Action:** Verify current Azure subscription ID

---

## 5. OIDC Readiness Score

| Requirement | Status | Notes |
|---|---|---|
| GitHub Actions `id-token: write` | ✅ Already configured | In both deploy.yml and template |
| `azure/login@v2` usage | ✅ Already configured | In both deploy.yml and template |
| App Registration exists | ❌ NOT CREATED | Blocked by permissions |
| Federated credential exists | ❌ NOT CREATED | Depends on App Registration |
| GitHub secrets configured | ❌ NOT SET | Need AZURE_CLIENT_ID, etc. |
| `az` CLI can test locally | ✅ Working | For post-setup verification |

**OIDC Readiness: 25%** — The workflow structure is correct but the Azure AD prerequisites are not in place.

---

## 6. Migration Path

### Phase 1: Manual Setup (HUMAN_REQUIRED — 15 minutes)

An Azure AD Administrator must:

1. Create App Registration `Hermes-Enterprise-CI`
2. Create federated credential for GitHub:
   - Issuer: `https://token.actions.githubusercontent.com`
   - Subject: `repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:ref:refs/heads/main`
   - Audience: `api://AzureADTokenExchange`
3. Grant the service principal Contributor role on the target subscription
4. Provide `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`

### Phase 2: GitHub Secrets Configuration (HUMAN_REQUIRED — 2 minutes)

```bash
gh secret set AZURE_CLIENT_ID --body "<from-app-registration>"
gh secret set AZURE_TENANT_ID --body "<from-azure-ad>"
gh secret set AZURE_SUBSCRIPTION_ID --body "<from-azure-account>"
```

### Phase 3: Project Template Enhancement (AUTOMATIC — scope of RC75-C)

After Phases 1-2 complete, update `Crear-HermesProyecto.ps1` to:
1. Create per-project App Registration (if permissions allow) OR document why not
2. Set per-project secrets automatically via `gh secret set`
3. Generate per-project federated credentials

---

## 7. Service Principal Alternative (if OIDC is blocked permanently)

If organization policy prevents creating App Registrations for OIDC:

| Method | Pros | Cons |
|---|---|---|
| Service Principal with secret | Simple, well-understood | Permanent secret, rotation needed |
| Service Principal with certificate | More secure than secret | Certificate rotation still needed |
| Manual `AZURE_CREDENTIALS` JSON | Works today | Credential in GitHub Secrets |
| OIDC (recommended) | No permanent secrets, auto-rotation | Requires App Registration creation |

**Fallback recommendation:** If OIDC is permanently blocked, use a Service Principal with a client secret stored as `AZURE_CREDENTIALS` JSON. This is less secure but functional.

---

## 8. Current Azure Subscription Info

```json
{
  "subscriptionId": "01bfad48-c092-4712-bc72-f141eb01a8d4",
  "tenantId": "ae525757-89ba-4d30-a2f7-49796ef8c604",
  "currentUser": "analiticaur@urosario.edu.co"
}
```

---

## 9. Recommendations

1. **[HIGH] Request App Registration creation** from Azure AD administrator
2. **[HIGH] Configure GitHub secrets** once App Registration exists
3. **[MEDIUM] Verify OIDC login** with a manual GitHub Actions run post-setup
4. **[MEDIUM] Document credentials policy** for project repositories
5. **[LOW] Implement `Set-AzureGitHubSecrets` function** in Azure.ps1 for automation
6. **[LOW] Add secret validation** to `Invoke-ProjectValidation.ps1` to check for missing secrets

---

## 10. AUTONOMY SCORE

| Category | Score | Notes |
|---|---|---|
| OIDC workflow structure | ✅ 100% | Correct YAML in Factory + templates |
| App Registration creation | ❌ 0% | BLOCKED — Human required |
| Federated credential setup | ❌ 0% | BLOCKED — Human required |
| GitHub secrets configuration | ❌ 0% | BLOCKED — Human required |
| Project secret management | ❌ 0% | Not yet implemented |
| **Overall OIDC Autonomy** | **20%** | |

---

## Appendix: Azure Subscription Details

```yaml
subscription: Azure subscription 1 (01bfad48-c092-4712-bc72-f141eb01a8d4)
tenant: ae525757-89ba-4d30-a2f7-49796ef8c604
current_user: analiticaur@urosario.edu.co
app_registrations:
  - name: Modelo-IA-UR-Modelo-IA-UR-Hermes-HermesEnterpriseSeniorCodingAgent-57d59-AgentIdentityBlueprint
    id: 3ac1cae9-acd2-46cb-9d3f-1abd19510fd8
    purpose: Unknown/legacy
github_secrets:
  AZURE_CLIENT_ID: NOT SET
  AZURE_TENANT_ID: NOT SET
  AZURE_SUBSCRIPTION_ID: NOT SET
  AZURE_CREDENTIALS: NOT SET
```

---

*Report generated: 2026-08-08T12:57:00-05:00*
*Phase: RC75-C1 — Azure Authentication Audit*