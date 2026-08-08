# Azure Identity Migration — RC75-C

## From: Implicit `az` CLI session (local only)

## To: OIDC federated identity for GitHub Actions

---

## CRITICAL FINDING: "UR - App - SII 2.0" MUST NOT BE REUSED

See **RC75-C0 App Registration Audit** for full details.

| App Registration | Verdict | Reason |
|---|---|---|
| `UR - App - SII 2.0` | ❌ DO NOT REUSE | **Subscription-wide Contributor + 10 Microsoft Graph app roles + 17 delegated scopes.** Reusing would violate least privilege and expose SII 2.0 operations to potential GitHub Actions compromise. |
| `Hermes-Enterprise-OIDC` (NEW) | ✅ MUST CREATE | **Clean, dedicated identity scoped only to `RG-Hermes-Proyectos` with zero Graph permissions.** |

---

## 1. Current State

Hermes Enterprise and all generated projects use `az` CLI commands (via `Azure.ps1`) that depend on an interactive `az login` session. This works for local development but has **zero automation** for CI/CD.

For GitHub Actions, the deploy workflows reference OIDC authentication (`azure/login@v2`) with secrets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` — but **these secrets are not configured** and the required App Registration `Hermes-Enterprise-OIDC` does not exist.

The existing App Registration `UR - App - SII 2.0` (App ID: `05827bb6-addd-4b44-8c1e-b86d4a3f6fa7`) has excessive permissions including **subscription-wide Contributor** and **10 Microsoft Graph application roles**. Reusing it is architecturally prohibited per RC75-C0 audit.

### Why This Matters

| Without OIDC | With OIDC |
|---|---|
| Manual `az login` required | Fully automated |
| No CI/CD Azure deployment | Autonomous deploy |
| Secret management is ad-hoc | Federated, no permanent secrets |
| Blocked for non-interactive use | Works in GitHub Actions |

---

## 2. Target Architecture

```
GitHub Actions Runner
    |
    |  id-token: write (in workflow YAML)
    v
GitHub OIDC Provider (token.actions.githubusercontent.com)
    |
    |  Federated Identity Credential
    v
Azure AD App Registration (Hermes-Enterprise-OIDC)
    |  Created: NEW (NOT UR - App - SII 2.0)
    |  RBAC: Contributor on RG-Hermes-Proyectos ONLY
    |  Graph API Permissions: NONE
    v
Azure Subscription (01bfad48-c092-4712-bc72-f141eb01a8d4)
    |
    |  Scope: /subscriptions/.../resourceGroups/RG-Hermes-Proyectos
    v
Azure Web Apps (in RG-Hermes-Proyectos)
```

### Key Principle

**No permanent secrets** are stored in GitHub. The OIDC token is issued per-run, scoped to the specific workflow, repository, and branch.

---

## 3. Migration Steps

### Step 1 — Create App Registration (HUMAN_REQUIRED)

An Azure AD Administrator must create a **new, dedicated** App Registration.
Do NOT reuse the existing `UR - App - SII 2.0`.

```powershell
# Create NEW App Registration (name must match config/Hermes.Azure.json)
az ad app create `
    --display-name "Hermes-Enterprise-OIDC" `
    --sign-in-audience AzureADMyOrg

# Note the appId from output
```

Azure Portal equivalent:
1. Go to Azure AD > App registrations > New registration
2. Name: `Hermes-Enterprise-OIDC`
3. Supported account types: "Accounts in this organizational directory only"
4. Register

### Step 2 — Create Federated Credential (HUMAN_REQUIRED)

Use `environment:production` subject type for enhanced security (not branch-based).

```powershell
# Get the App Registration object ID (not appId)
$appId = "<from-step-1>"
$appObjId = az ad app show --id $appId --query id -o tsv

# Create federated identity credential
az ad app federated-credential create `
    --id $appObjId `
    --parameters @{
        name="HERMES-ENTERPRISE-OIDC-FACTORY-PRODUCTION"
        issuer="https://token.actions.githubusercontent.com"
        subject="repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production"
        description="OIDC for Factory CI/CD from production environment"
        audiences=@("api://AzureADTokenExchange")
    }
```

The `subject` format uses `environment:production` to require GitHub Environments protection. This is more secure than branch-based (`ref:refs/heads/main`) because:
- Environments support required reviewers
- Environments support deployment branch policies
- The deploy.yml already uses `environment: production`

### Step 3 — Grant RBAC Role (HUMAN_REQUIRED)

**IMPORTANT:** Scope to `RG-Hermes-Proyectos` ONLY. Do NOT grant subscription-wide Contributor.

```powershell
# Assign Contributor role scoped to RG-Hermes-Proyectos only
$spId = az ad sp show --id $appId --query id -o tsv
az role assignment create `
    --assignee $spId `
    --role Contributor `
    --scope "/subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/resourceGroups/RG-Hermes-Proyectos"
```

This ensures the CI/CD identity can ONLY manage resources within `RG-Hermes-Proyectos` and cannot affect:
- `RG-Datamining-SII2.0-Dev`
- `RG-Datamining-IA-UR`
- Any other Resource Groups in the subscription

### Step 4 — Configure GitHub Secrets (HUMAN_REQUIRED)

```bash
gh secret set AZURE_CLIENT_ID --body "$appId"
gh secret set AZURE_TENANT_ID --body "ae525757-89ba-4d30-a2f7-49796ef8c604"
gh secret set AZURE_SUBSCRIPTION_ID --body "01bfad48-c092-4712-bc72-f141eb01a8d4"
```

### Step 5 — Create GitHub Environment (HUMAN_REQUIRED)

The deploy workflow references `environment: production`. This must exist in GitHub.

```bash
# Create production environment
gh api --method PUT repos/FREDYASARMIENTOT/HERMES-ENTERPRISE/environments/production

# Optionally add protection rules (recommended)
# gh api --method POST repos/FREDYASARMIENTOT/HERMES-ENTERPRISE/environments/proformation/deployment-branch-policies \
#   --input '{"name":"main"}'
```

After these steps, the deploy workflow will automatically use OIDC authentication when triggered by a push to `main`.
### Step 5 — Automated Validation (AUTOMATIC — Already implemented)

Azure.ps1 now includes:
- `Get-AzureIdentityMode`: Returns identity mode from config and checks GitHub secrets
- `Assert-AzureIdentityReady`: Validates readiness with descriptive HUMAN_REQUIRED messages
- `AzureIdentityMode = "TemporaryExistingApp"`: Correctly set in config (NOT "OIDC" as before)

---

## 4. Verification

After completing Steps 1-4:

### Manual Workflow Trigger

Either:
1. Push to `main` (triggers deploy.yml automatically)
2. Or use: `gh workflow run deploy.yml`

### Check Output

```bash
# View workflow run
gh run list --workflow deploy.yml --limit 1

# Check specific run
gh run view <run-id> --log
```

Expected success path:
```
Azure Login (OIDC) -> PASS
Build and Package -> PASS
Deploy to Azure -> PASS
Smoke Test -> PASS
```

### Local Verification

```bash
# Test OIDC token exchange (requires App Registration + federated credential)
# This is informational only — OIDC only works in GitHub Actions context
echo "OIDC will be verified by GitHub Actions workflow run"
```

---

## 5. Rollback Plan

| Step | Rollback |
|---|---|
| App Registration | Delete `Hermes-Enterprise-CI` from Azure AD |
| Federated credential | Delete the credential from the App Registration |
| RBAC role | Remove the role assignment |
| GitHub secrets | `gh secret delete AZURE_CLIENT_ID` (and others) |
| Azure.ps1 changes | Revert to previous version |

---

## 6. Testing Strategy

### Pre-Migration Tests (Current)
- [PASS] Local `az` CLI works
- [PASS] Local `az webapp create` works
- [PASS] Local `az webapp deploy` works
- [PASS] Local smoke tests work

### Post-Migration Tests
- [ ] GitHub Actions OIDC login succeeds
- [ ] GitHub Actions deploy succeeds
- [ ] GitHub Actions smoke tests pass
- [ ] No manual intervention in pipeline

### Regression Tests
- [ ] Local operations still work (backward compatible)
- [ ] Project creation still works
- [ ] Guardian still protects infrastructure

---

## 7. Future Enhancements (RC75-D)

After OIDC is working for the Factory:

- **Per-project App Registrations**: Each generated project gets its own federated credential
- **Automatic secret injection**: `Crear-HermesProyecto.ps1` sets project secrets via `gh secret set`
- **Multi-branch support**: Federated credentials for `main` and `develop` branches
- **Environment-specific**: Separate App Registrations for dev/staging/production

---

## 8. Dependency Graph

```
This Migration
    |
    +-- Requires: Azure AD Application Administrator (HUMAN)
    |       |
    |       +-- Create App Registration
    |       +-- Create federated credential
    |       +-- Grant RBAC role
    |
    +-- Requires: GitHub repo admin (HUMAN)
    |       |
    |       +-- Set repository secrets
    |
    +-- Enables: RC75-C2 (Project template enhancement)
    |       |
    |       +-- Auto-secret management in Crear-HermesProyecto
    |       +-- Per-project federated credentials
    |
    +-- Enables: RC75-D (Production CI/CD autonomy)
            |
            +-- Fully automated pipeline
            +-- No manual Azure authentication
```

---

*Document generated: 2026-08-08*
*Phase: RC75-C1 — Azure Authentication Audit*
*Status: BLOCKED — Waiting for Azure AD admin action*