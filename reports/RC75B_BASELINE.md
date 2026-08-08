# RC75-B — BASELINE REPORT
## FASE 0: Auditoría post-RC75-A

**Date:** 2026-08-08
**Status:** COMPLETED — No modifications made
**Previous:** RC75-A (commit 6f06850) — GitHub CI/CD Autonomous Foundation & Credential Hardening

---

## 1. Git State

| Property | Value |
|----------|-------|
| Branch | `main` |
| HEAD | `6f068504cd780225c8f63d5c34c15f3293bee046` |
| Latest commit | `RC75-A — GitHub CI/CD Autonomous Foundation & Credential Hardening` |
| Origin Remote | `https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE.git` |
| Working Tree | ✅ CLEAN (no uncommitted changes) |
| Remote embedded tokens | ✅ CLEAN (RC75-A FASE 2 was applied) |

---

## 2. GitHub Authentication Status

| Check | Result |
|-------|--------|
| `gh auth status` | ✅ Logged in as `FREDYASARMIENTOT` |
| Token scopes | `gist`, `read:org`, `repo`, `workflow` |
| Git operations protocol | `https` (via GCM) |
| Token type | `gho_*` (GitHub CLI OAuth token, managed securely) |
| Secret exposure in logs/files | ✅ NONE detected |

### Workflow Permissions (checked via .github/workflows/*.yml)

| Workflow | `id-token: write` | `contents: read` | Notes |
|----------|------------------|------------------|-------|
| `.github/workflows/ci.yml` | ❌ NOT SET | ❌ NOT SET | No explicit permissions block |
| `.github/workflows/deploy.yml` | ❌ NOT SET | ❌ NOT SET | Uses AZURE_CREDENTIALS (not OIDC) |

---

## 3. Azure Authentication Status

| Check | Result |
|-------|--------|
| Azure CLI logged in | ✅ `analiticaur@urosario.edu.co` |
| Subscription ID | `01bfad48-c092-4712-bc72-f141eb01a8d4` |
| Tenant ID | `ae525757-89ba-4d30-a2f7-49796ef8c604` |
| OIDC App Registration (Hermes) | ❌ **NOT FOUND** — `az ad app list --filter Hermes*` returned empty |
| Federated credentials | ❌ NONE — no App Registration exists |
| AZURE_CREDENTIALS in Factory workflow | ⚠️ PRESENT (legacy, should be OIDC) |

### OIDC Bootstrap Required

```
ONE-TIME HUMAN BOOTSTRAP:
  1. Create Azure AD App Registration for Hermes OIDC
  2. Configure federated credential for GitHub Actions
  3. Assign RBAC role (e.g., Website Contributor) to App's Service Principal
  4. Store AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID as GitHub secrets
```

---

## 4. Workflows State

### Factory Workflows (`.github/workflows/`)

#### ci.yml
| Aspect | Status | Notes |
|--------|--------|-------|
| Trigger | ✅ Push to `main`/`develop`/`rc-*` + PR `main` | Correct |
| Python version | ⚠️ Python 3.14 specified | Should be 3.12 (3.14 doesn't exist) |
| `continue-on-error: true` on test | ⚠️ Masks failures | Still present from RC74-C |
| `permissions` block | ❌ Missing | No `id-token: write`, no `contents: read` |

#### deploy.yml
| Aspect | Status | Notes |
|--------|--------|-------|
| Trigger | ✅ Push to `main` + `workflow_dispatch` | Correct |
| Azure Login | ⚠️ Uses `AZURE_CREDENTIALS` | No OIDC; uses `creds` parameter |
| `permissions` block | ❌ Missing | Required for OIDC |
| Smoke test `if:` condition | ⚠️ `always()` | Should be `success()` for proper gating |

### Project Workflow Templates (`tools/Templates/github/`)

#### ci.yml (template)
| Aspect | Status | Notes |
|--------|--------|-------|
| Trigger | ✅ Push to `main` | Correct |
| Structure | ✅ Validate → Test → Lint | Valid |
| `permissions` block | ❌ Missing | Required for OIDC |
| Python version | ✅ 3.12 | Correct |

#### deploy.yml (template)
| Aspect | Status | Notes |
|--------|--------|-------|
| Trigger | ✅ Push to `main` | Correct |
| Azure Login | ✅ OIDC configured | Uses `client-id`, `tenant-id`, `subscription-id` secrets |
| Build → Deploy → SmokeTest | ✅ Structure correct | Valid pipeline |
| `permissions` block | ❌ Missing | Required for OIDC at job level |
| ZIP structure | ⚠️ Uses `frontend/`, `database/` dirs | May not exist in all projects |
| Wait time | ⚠️ `sleep 30` hardcoded | Could fail on slow deployments |

---

## 5. Guardian Status

| Check | Status |
|-------|--------|
| Policy config exists | ✅ `config/Hermes.InfrastructureProtection.json` |
| Enforcement mode | ✅ `hard` |
| Protected RGs | ✅ RG-Hermes-Proyectos, RG-Datamining-SII2.0-Dev, RG-Datamining-IA-UR |
| Protected ASPs | ✅ ASP-IAUR, ASP-Hermes, ASP-HermesEnterprise, Plan-Hermes-Proyectos |
| Protected Storage | ✅ saurhermesproyectos |
| Protected Web Apps | ✅ AS-HermesEnterprise |
| Case-sensitivity fix applied | ✅ (RC75-A FASE 7) |
| Unit tests pass | ✅ 46/46 (from RC73-B) |

---

## 6. Key Files State (post-RC75-A)

| File | Status | Notes |
|------|--------|-------|
| `tools/Crear-HermesProyecto.ps1` | ✅ UPDATED | OIDC secrets step added (lines 141-181) |
| `tools/Invoke-ProjectValidation.ps1` | ✅ NEW | 28 non-destructive tests |
| `tools/Modules/GitHub.ps1` | ✅ UPDATED | `Set-GitHubActionsSecrets` function |
| `tools/Modules/Azure.ps1` | ✅ UNCHANGED | Uses `az webapp deploy` (needs AZ login) |
| `tools/Modules/Guardian.ps1` | ✅ UPDATED | Case-sensitivity fix |
| `tools/Templates/github/deploy.yml` | ✅ UPDATED | OIDC template with secrets placeholders |
| `docs/Azure-OIDC-Setup.md` | ✅ NEW | OIDC bootstrap documentation |
| `reports/RC75A_BASELINE.md/.json` | ✅ EXIST | Baseline from RC75-A |

---

## 7. Known Issues and Risks

| ID | Issue | SeverITY | Phase to Address |
|----|-------|----------|------------------|
| RC75B-R1 | **No Azure AD App Registration for OIDC** | **BLOCKER** | FASE 2 (HUMAN_BOOTSTRAP) |
| RC75B-R2 | No `permissions:` block in Factory workflows | HIGH | FASE 4 |
| RC75B-R3 | `continue-on-error: true` on test job in ci.yml | HIGH | FASE 4 |
| RC75B-R4 | Python 3.14 specified in Factory ci.yml | MEDIUM | FASE 4 |
| RC75B-R5 | Factory deploy.yml uses AZURE_CREDENTIALS (not OIDC) | MEDIUM | FASE 4 |
| RC75B-R6 | Template deploy.yml has no `permissions:` block | MEDIUM | FASE 4 |
| RC75B-R7 | Smoke test `if:` uses `always()` not `success()` | MEDIUM | FASE 4 |

---

## 8. RC75-A Completion Status

| Phase | Status | Evidence |
|-------|--------|----------|
| FASE 0 — Audit & Baseline | ✅ PASS | RC75A_BASELINE.md |
| FASE 1 — Credential Architecture | ✅ PASS | GCM + OIDC design documented |
| FASE 2 — Clean remote tokens | ✅ PASS | No embedded tokens in remotes |
| FASE 3 — Factory/Projects separation | ✅ PASS | Crear-HermesProyecto creates independent repos |
| FASE 4 — Canonical workflow | ✅ PASS | ci.yml + deploy.yml templates |
| FASE 5 — Workflow warnings | ✅ PASS | Python 3.12, updated actions |
| FASE 6 — Azure OIDC design | ✅ PASS | docs/Azure-OIDC-Setup.md |
| FASE 7 — Guardian fix | ✅ PASS | Case-sensitivity bug fixed |
| FASE 8 — Crear-HermesProyecto update | ✅ PASS | OIDC secrets step added |
| FASE 9 — Validation suite | ✅ PASS | Invoke-ProjectValidation.ps1 (28 tests) |
| FASE 10 — Real CI/CD validation | ⏳ **DEFERRED** | Requires OIDC bootstrap |
| FASE 11 — Failure gate test | ⏳ **DEFERRED** | Requires OIDC bootstrap |
| FASE 12 — Autonomy measurement | ⏳ **DEFERRED** | Requires F10 + F11 |
| FASE 13 — Observability | ✅ PASS | RC75A.md/.json/.html |
| FASE 14 — Git clean | ✅ PASS | No secrets in diff/staged |
| FASE 15 — Commit | ✅ PASS | `6f06850` on `main` |

---

## 9. Baseline Decision

**Phase 0 complete.** No files were modified.

### Critical Findings for RC75-B

1. **BLOCKER [RC75B-R1]**: No Azure AD App Registration for OIDC exists. A `ONE-TIME HUMAN BOOTSTRAP` is required to:
   - Create Azure AD App Registration
   - Configure federated credential for `repo:FREDYASARMIENTOT/HERMES-ENTERPRISE` (branch: `main`)
   - Assign Website Contributor role to App's Service Principal on RG-Hermes-Proyectos
   - Set AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID as GitHub Actions secrets

2. **HIGH [RC75B-R2]**: Factory workflows lack `permissions:` blocks — needed for OIDC `id-token: write`

3. **HIGH [RC75B-R3]**: `continue-on-error: true` in ci.yml test job masks failures

4. **MEDIUM [RC75B-R5/R6]**: Template workflows need `permissions:` blocks for OIDC compatibility

### Plan for RC75-B

- **FASE 1**: Audit GitHub authentication → ✅ Already PASS (rc75-a left it clean)
- **FASE 2**: Validate OIDC Azure → ⚠️ **BLOCKED** — needs human bootstrap
- **FASE 3**: Audit canonical workflow → ✅ Will review and fix
- **FASE 4**: Fix warnings/errors → ✅ Will fix known issues (R2-R7)
- **FASE 5**: Validate Factory (Crear-HermesProyecto) → ✅ Will verify
- **FASE 6**: Create test project → ⏳ Deferred until OIDC bootstrap
- **FASE 7**: Real CI/CD test → ⏳ Deferred until OIDC bootstrap
- **FASE 8**: Validate OIDC real → ⏳ Deferred
- **FASE 9**: Functional validation → ⏳ Deferred
- **FASE 10**: Failure gate → ⏳ Deferred
- **FASE 11**: Recovery → ⏳ Deferred
- **FASE 12**: Autonomy measurement → ⏳ Deferred
- **FASE 13**: Guardian validation → ✅ Will run static validation
- **FASE 14**: Security validation → ✅ Will verify
- **FASE 15**: Reports → Will generate RC75B_E2E.*
- **FASE 16**: Git → Will commit
- **FASE 17**: Documentation → Will update

### OIDC Bootstrap Required for Progression

```
To unblock RC75-B FASE 6-11, a human must:

1. az ad app create --display-name "Hermes-Enterprise-OIDC"
2. az ad app federated-credential create (for GitHub repo FREDYASARMIENTOT/HERMES-ENTERPRISE)
3. az ad sp create --id <app-id>
4. az role assignment create (Website Contributor on RG-Hermes-Proyectos)
5. gh secret set AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID
```

Without this, FASE 6-11 cannot execute real OIDC-based CI/CD.