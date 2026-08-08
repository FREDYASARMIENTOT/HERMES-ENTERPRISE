# RC75-C2 — Azure Identity Migration: Configuration & Hardening

**Date:** 2026-08-08  
**Status:** CORRECTIONS COMPLETE (BLOCKED for OIDC until Azure AD admin action)  
**Phase:** RC75-C2 — Configuration Hardening & Documentation Sync

---

## 1. Summary

RC75-C2 applies all corrections identified in RC75-C0 (App Registration Audit) and RC75-C1 (Azure Authentication Audit) to the actual configuration files. No Azure resources were created, modified, or deleted.

### Changes Applied

| File | Correction |
|---|---|
| `config/Hermes.Azure.json` | `AzureIdentityMode` → `"TemporaryExistingApp"` (was `"OIDC"`). Added `AzureIdentityTargetApp: "Hermes-Enterprise-OIDC"`, `AzureIdentityScope: "RG-Hermes-Proyectos"`, `AzureIdentityScopeType: "ResourceGroup"`. Full description documents HUMAN_REQUIRED steps. |
| `tools/Modules/Azure.ps1` | `Get-AzureIdentityMode` and `Assert-AzureIdentityReady` updated: support `TemporaryExistingApp` and `DedicatedHermesApp` modes (not just `OIDC`). Updated error messages to reference `Hermes-Enterprise-OIDC` (not `Hermes-Enterprise-CI`). RBAC instructions now scope to `RG-Hermes-Proyectos` not subscription. |
| `docs/AzureIdentityMigration.md` | Added CRITICAL FINDING section: "UR - App - SII 2.0" MUST NOT BE REUSED. Updated all references from `Hermes-Enterprise-CI` to `Hermes-Enterprise-OIDC`. Step 3 now scopes RBAC to resource group. Step 5 now creates GitHub Environment. |
| `.github/workflows/deploy.yml` | Added `environment: production` gate to deploy job. Added `Record deployment artifact` step (correlation ID, timestamp, SHA). Added middleware header check to smoke test. |

---

## 2. Current Blockers

### BLOCKER 1: OIDC Authentication — HUMAN REQUIRED

GitHub Actions deploy workflow uses `azure/login@v2` with OIDC. This requires:

1. **Create App Registration** `Hermes-Enterprise-OIDC` (Application Administrator)
2. **Create federated credential** with subject `repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production`
3. **Grant Contributor** on `/subscriptions/.../resourceGroups/RG-Hermes-Proyectos` (not subscription-wide)
4. **Set GitHub secrets**: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
5. **Create GitHub Environment**: `production`

Until these are complete, the deploy pipeline will fail with:
```
Error: No client ID or client secret provided
```

### BLOCKER 2: Federated Credential Creation — HUMAN REQUIRED

The RC75-C1 test confirmed that the current user (`fredya.sarmiento@urosario.edu.co`) has **Contributor** at subscription level but **NOT** Application Administrator. Creating federated credentials requires:

- `Application Administrator` (Entra ID)
- `Cloud Application Administrator` (Entra ID)
- These are **separate** from Azure RBAC roles

---

## 3. Security Improvements

### Before RC75-C2

- `AzureIdentityMode: "OIDC"` — wrong semantic value, didn't exist as actual mode
- `Hermes-Enterprise-CI` referenced but App Registration doesn't exist
- RBAC implied at subscription level (no scope specification)
- No GitHub environment protection

### After RC75-C2

- `AzureIdentityMode: "TemporaryExistingApp"` — correct semantic value
- `AzureIdentityTargetApp: "Hermes-Enterprise-OIDC"` — explicit target
- `AzureIdentityScope: "RG-Hermes-Proyectos"` — RBAC scoped to resource group
- `AzureIdentityScopeType: "ResourceGroup"`
- `environment: production` — GitHub environment protection gate
- Correlation ID tracking added to pipeline

---

## 4. Configuration Validation

### config/Hermes.Azure.json

```json
{
    "Azure": {
        "subscriptionId": "01bfad48-c092-4712-bc72-f141eb01a8d4",
        "tenantId": "ae525757-89ba-4d30-a2f7-49796ef8c604",
        "AzureIdentityMode": "TemporaryExistingApp",
        "AzureIdentityTargetApp": "Hermes-Enterprise-OIDC",
        "AzureIdentityScope": "RG-Hermes-Proyectos",
        "AzureIdentityScopeType": "ResourceGroup",
        ...
    }
}
```

### Azure.ps1 Mode Detection

| Current Config | Mode Detected | Ready? |
|---|---|---|
| `TemporaryExistingApp` + all 3 GitHub secrets exist | `TemporaryExistingApp` | ✅ |
| `TemporaryExistingApp` + missing secrets | `TemporaryExistingApp` | ❌ (HUMAN_REQUIRED) |
| `LEGACY` | `LEGACY` | ✅ (if `az login` active) |

---

## 5. Next Steps (Human)

1. **Application Administrator** creates `Hermes-Enterprise-OIDC` App Registration
2. Adds federated credential for `repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production`
3. Grants `Contributor` on `RG-Hermes-Proyectos`
4. Sets `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID` as GitHub secrets
5. Creates `production` GitHub Environment
6. Pushes to `main` to trigger CI/CD pipeline
7. Verifies OIDC login → Deploy → Smoke Test

---

## 6. Autonomous (Already Working)

The following are 100% automated and require no human intervention:

- [x] Factory project structure validation
- [x] Python dependency installation
- [x] Python import validation
- [x] Guardian infrastructure protection validation
- [x] Configuration file existence checks
- [x] Smoke test endpoint validation (when deployed)
- [x] Middleware header checks (when deployed)

---

## 7. Evidence Files

| File | Description |
|---|---|
| `config/Hermes.Azure.json` | Corrected Azure configuration |
| `tools/Modules/Azure.ps1` | Updated Azure identity module |
| `docs/AzureIdentityMigration.md` | Updated migration guide |
| `.github/workflows/deploy.yml` | Updated deploy workflow |
| `docs/RC75-C2-STATE.md` | This report |
| `reports/RC75C0-AppRegistrationAudit.md` | App Registration audit (from C0) |
| `reports/RC75C0-AppRegistrationAudit.json` | App Registration audit data |
| `reports/RC75C1-AzureAuthAudit.md` | Azure auth audit (from C1) |
| `reports/RC75C1-AzureAuthAudit.json` | Azure auth audit data |

---

## 8. Conclusion

RC75-C2 corrects the identified configuration issues and hardens the authentication architecture. **No Azure resources were modified.** Full OIDC CI/CD remains BLOCKED until an Azure AD Application Administrator completes the human-required steps documented in `docs/AzureIdentityMigration.md`.

Once those steps are complete, the pipeline should work autonomously:
```
git push → GitHub Actions → OIDC login → Build → Deploy → Smoke Test