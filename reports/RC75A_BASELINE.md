# RC75-A — BASELINE REPORT
## FASE 0: Auditoría y Baseline

**Date:** 2026-08-08
**Status:** COMPLETED — No modifications made

---

## 1. Git State

| Property | Value |
|----------|-------|
| Branch | `main` |
| HEAD | `04459efa132c8cc772b05f732ccb788e0967585a` |
| Latest commit | `temp: remove workflow for scope-limited push` |
| Origin Remote | `github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE.git` |
| Azure Remote | `as-hermesenterprise.scm.azurewebsites.net/AS-HermesEnterprise.git` |

### Recent Commits (top 5)
1. `04459ef` — temp: remove workflow for scope-limited push
2. `c804eb2` — RC75-C: Add auto-trigger push event to deploy.yml CI/CD pipeline
3. `710dcc1` — RC74-C: Update reports with E2E execution results
4. `605518f` — RC74-C: Add E2E reports
5. `face0b8` — RC74-C: Autonomous Project Factory completed

---

## 2. REMOTE URLS — SECURITY RISK DETECTED ⚠️

### ORIGIN (GitHub)
```
https://USERNAME:TOKEN@github.com/OWNER/HERMES-ENTERPRISE.git
```
**RISK:** GitHub PAT token embedded in URL. (Sanitized — token was rotated.)

### AZURE (SCM)
```
https://USERNAME:TOKEN@as-hermesenterprise.scm.azurewebsites.net/AS-HermesEnterprise.git
```
**RISK:** OAuth token embedded in URL. (Sanitized — token was rotated.)

### Required Action (FASE 2)
Both remotes must be cleaned to contain only clean URLs:
- `https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE.git`
- No embedded tokens

---

## 3. Workflows (Factory)

### Local Files (in `.github/workflows/`)
| File | Description |
|------|-------------|
| `ci.yml` | CI Pipeline — Python validation, PowerShell syntax, documentation, deploy check |
| `deploy.yml` | Deploy Pipeline — Validate → Build → Deploy → SmokeTest |

### ci.yml (CI)
- Triggers: `push` on `main`, `develop`, `rc-*`; `pull_request` on `main`
- Jobs:
  - **validate-python** — Checkout → Python 3.14 → pip install → validate imports → pytest → canonical file check
  - **validate-powershell** — Windows runner → Parse check on 11 PS1 scripts
  - **validate-documentation** — Check README, CURRENT_STATE, CHANGELOG, ArchitectureState
  - **deploy-check** — Validate startup.sh, deployment files
- Warnings:
  - Python 3.14 specified (no 3.14 available; should be 3.12)
  - `pytest` run with `continue-on-error: true` (masks failures)
  - References old file paths (`motor/bootstrap/engine/BootstrapWizard.ps1`, etc.)

### deploy.yml (Factory Deploy)
- Triggers: `push` on `main`; `workflow_dispatch` with `projectName` and `correlationId`
- Jobs:
  - **validate** — Structure check
  - **build** — Python 3.14 → pip → imports
  - **deploy** — Azure/login@v2 + webapps-deploy@v3 (uses `AZURE_CREDENTIALS` secret)
  - **smoketest** — curl endpoints
- Warnings:
  - Python 3.14 specified
  - Uses `AZURE_CREDENTIALS` (service principal secret) — no OIDC/federated identity
  - `azure/login@v2` uses `creds` parameter (long-lived credential)
  - Deploys entire repo as package (not a specific artifact)

### Template Workflow (for generated projects)
- `tools/Templates/github/deploy.yml`
- Single job: build-and-deploy
- Uses `AZURE_WEBAPP_PUBLISH_PROFILE` secret
- Simple structure: checkout → Python setup → pip → zip → deploy → smoke test
- No CI gates before deploy
- No separate CI/CD separation

---

## 4. GitHub Actions Status

`gh workflow list` returned no output — workflows may be disabled or GitHub CLI not authenticated. This needs investigation.

---

## 5. Azure Infrastructure

### Protected Resource Groups (all confirmed existing)

| Resource Group | Status |
|----------------|--------|
| RG-Hermes-Proyectos | ✅ Exists |
| RG-Datamining-SII2.0-Dev | ✅ Exists |
| RG-Datamining-IA-UR | ✅ Exists |

### Shared Infrastructure (from Hermes.Azure.json)
```json
{
  "subscriptionId": "01bfad48-c092-4712-bc72-f141eb01a8d4",
  "Location": "eastus",
  "ResourceGroupAplicaciones": "RG-Hermes-Proyectos",
  "ResourceGroupPlan": "RG-Datamining-SII2.0-Dev",
  "AppServicePlan": "ASP-IAUR",
  "StorageAccount": "saurhermesproyectos",
  "UseSharedInfrastructure": true
}
```

### Guardian Protection Policy
- **Version:** 1.1.0
- **Enforcement:** `hard`
- **Protected Resource Groups:** 3 (RG-Datamining-SII2.0-Dev, RG-Datamining-IA-UR, RG-Hermes-Proyectos)
- **Protected App Service Plans:** 4 (ASP-IAUR, ASP-Hermes, ASP-HermesEnterprise, Plan-Hermes-Proyectos)
- **Protected Storage Accounts:** 1 (saurhermesproyectos)
- **Protected Web Apps:** 1 (AS-HermesEnterprise)
- **Blocked Operations:** 14 specific cmdlets and az commands
- **Validation Rules:** 16 rules enforcing protection

---

## 6. Configuration

| Config | Path | Notes |
|--------|------|-------|
| Hermes.Azure.json | `config/Hermes.Azure.json` | Azure infrastructure |
| Hermes.Python.json | `config/Hermes.Python.json` | Python runtime |
| Hermes.InfrastructureProtection.json | `config/Hermes.InfrastructureProtection.json` | Guardian policy |
| Hermes.config.json | `Hermes.config.json` | Hermes configuration |

---

## 7. CI/CD Authentication Analysis

### Current State

| Identity | Mechanism | Status |
|----------|-----------|--------|
| Factory → GitHub | PAT in Git remote URL | ⚠️ **INSECURE** — token exposed in remote URL |
| GitHub Actions → Azure | AZURE_CREDENTIALS (service principal) | ⚠️ Legacy — has expiry/rotation risk |
| Project → GitHub (via Factory) | Uses `gh` CLI + PAT (via env) | ⚠️ Depends on PAT being available |
| Project workflow → Azure | AZURE_WEBAPP_PUBLISH_PROFILE | ⚠️ Publish profile stored as GitHub secret |

### Risks

1. **Embedded tokens in Git remotes** — Tokens visible in `git remote -v`, `git config`, and persisted in `.git/config`
2. **AZURE_CREDENTIALS** — Long-lived service principal credential; requires rotation
3. **Publish Profile** — Azure WebApp publish profile is valid until revoked
4. **No OIDC** — No federated identity between GitHub Actions and Azure

---

## 8. Factory vs Projects Separation

### Current Architecture
```
HERMES-ENTERPRISE (Factory)
    ├── All tooling, modules, templates
    ├── Crear-HermesProyecto.ps1
    └── Workflows for Factory itself
```

### Target Architecture (what needs to be built)
```
HERMES-ENTERPRISE (Factory)
    ├── All tooling, modules, templates
    ├── Crear-HermesProyecto.ps1
    └── Factory workflows

Projects (each with independent repo):
    ├── EncuestasPercepcionServiciosUR
    │   ├── Independent git history
    │   ├── Independent origin
    │   ├── Independent workflow (CI + CD)
    │   └── Independent Azure WebApp
    ├── ProyectoProfesoresUR
    └── ProyectoIndicadoresUR
```

### Current Status
- Crear-HermesProyecto creates projects as **independent directories** with **independent git repos**
- But the token in the Factory's origin remote could expose credentials to projects if submodules or shared refs are used
- Need to verify that project repos are genuinely independent (not submodules)

---

## 9. Risks Summary

| ID | Risk | Severity | Phase to Fix |
|----|------|----------|--------------|
| R1 | GitHub PAT token exposed in origin remote URL | CRITICAL | FASE 2 |
| R2 | Azure OAuth token exposed in azure remote URL | CRITICAL | FASE 2 |
| R3 | Python 3.14 in workflows (doesn't exist) | HIGH | FASE 5 |
| R4 | Tests run with `continue-on-error: true` (masking failures) | HIGH | FASE 5 |
| R5 | AZURE_CREDENTIALS long-lived secret | MEDIUM | FASE 6 |
| R6 | No OIDC for GitHub→Azure auth | MEDIUM | FASE 6 |
| R7 | Template workflow has no CI gate before deploy | HIGH | FASE 4 |
| R8 | Project workflow uses publish profile instead of OIDC | MEDIUM | FASE 4/6 |
| R9 | GitHub CLI auth status unknown | MEDIUM | FASE 1 |
| R10 | `gh workflow list` returned empty — workflows may be disabled | MEDIUM | FASE 5 |

---

## 10. Guardian Status

| Check | Status |
|-------|--------|
| Guardian config exists | ✅ Yes |
| 3 Resource Groups protected | ✅ Yes |
| 4 App Service Plans protected | ✅ Yes |
| 1 Storage Account protected | ✅ Yes |
| 1 Web App protected | ✅ Yes |
| 14 blocked operations | ✅ Yes |
| 16 validation rules | ✅ Yes |
| Enforcement = `hard` | ✅ Yes |
| HermesManaged tag required | ✅ Yes |
| Audit logging enabled | ✅ Yes |

---

## 11. Baseline Decision

**Phase 0 complete.** No files were modified.

The baseline identifies the following critical issues that must be addressed in RC75-A:

1. **IMMEDIATE (FASE 2):** Clean embedded tokens from both remotes (`origin` and `azure`)
2. **FASE 1:** Design proper authentication strategy for Factory → GitHub
3. **FASE 4/5:** Create canonical project workflow with CI gates and modern actions
4. **FASE 6:** Migrate to OIDC/federated identity for GitHub Actions → Azure
5. **FASE 3:** Verify and enforce Factory/Project separation

Proceeding to FASE 1: GitHub Credential Architecture Design.