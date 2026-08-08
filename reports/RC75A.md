# RC75-A — GitHub CI/CD Autonomous Foundation & Credential Hardening

## Status: IN PROGRESS (FASE 7/15)

### Completed Phases

| Fase | Status | Description |
|------|--------|-------------|
| FASE 0 | ✅ PASS | Audit and Baseline generated |
| FASE 1 | ✅ PASS | GitHub Credential Architecture designed |
| FASE 2 | ✅ PASS | Embedded tokens cleaned from remotes |
| FASE 3 | ✅ PASS | Factory vs Projects separation enforced |
| FASE 4 | ✅ PASS | Canonical CI/CD workflow templates created |
| FASE 5 | ✅ PASS | Workflow warnings fixed |
| FASE 6 | ✅ PASS | Azure OIDC authentication designed and documented |
| FASE 7 | ✅ PASS | Guardian audited and hardened |

### FASE 0 — Audit and Baseline
- Branch: main
- HEAD: 04459efa132c8cc772b05f732ccb788e0967585a
- Origin: https://github.com/FREDYASARMIENTOT/HERMES-ENTERPRISE.git
- Workflows: .github/workflows/ci.yml, .github/workflows/deploy.yml
- Guardian: Active (hard enforcement)
- Azure subscription: 01bfad48-c092-4712-bc72-f141eb01a8d4
- Reports: RC75A_BASELINE.md, RC75A_BASELINE.json

### FASE 1 — GitHub Credential Architecture
- Git Credential Manager configured for HTTPS
- No PAT embedded in remote URLs
- OIDC recommended for Azure auth from GitHub Actions

### FASE 2 — Remote URL Cleanup
- origin: Clean URL (no embedded token)
- azure: Clean URL (no embedded token)
- Verified: no tokens in remote URLs

### FASE 3 — Factory vs Projects Separation
- Hermes-Enterprise = Factory repository
- Projects created have OWN independent repos:
  - github.com/FREDYASARMIENTOT/<ProjectName>
- Each project has:
  - Independent git init
  - Independent origin
  - Independent workflow
  - Independent CI/CD

### FASE 4 — Canonical Workflow
- tools/Templates/github/ci.yml — CI pipeline
  - Setup Python 3.11
  - Install dependencies
  - Lint with flake8
  - Run unit tests
  - Run API health tests
  - Validate frontend
- tools/Templates/github/deploy.yml — CD pipeline
  - Build and ZIP
  - Azure Login (OIDC if configured, else AZURE_CREDENTIALS)
  - Deploy to Azure WebApp
  - Smoke test
  - Conditional: deploy only if CI passes

### FASE 5 — Workflow Warnings Fixed
- actions/checkout: v4 (latest stable)
- actions/setup-python: v5 (latest)
- azure/webapps-deploy: v3 (latest)
- Azure Login: v2 (OIDC support)
- Python version: 3.11 (explicit, valid)
- continue-on-error removed from deploy jobs
- All workflows clean of deprecation warnings

### FASE 6 — Azure OIDC Authentication
- Architecture: GitHub Actions → OIDC → Azure
- docs/Azure-OIDC-Setup.md documents ONE-TIME HUMAN BOOTSTRAP
- Secrets configured via `gh secret set`:
  - AZURE_CLIENT_ID
  - AZURE_TENANT_ID
  - AZURE_SUBSCRIPTION_ID
- Integration added to Crear-HermesProyecto (step 11)
- Secrets never written to files

### FASE 7 — Guardian Audit
- Guardian config: config/Hermes.InfrastructureProtection.json
- Mode: hard enforcement
- Protected resources verified:
  - RG-Datamining-SII2.0-Dev
  - RG-Datamining-IA-UR
  - RG-Hermes-Proyectos
  - ASP-IAUR, ASP-Hermes, ASP-HermesEnterprise, Plan-Hermes-Proyectos
  - saurhermesproyectos
  - AS-HermesEnterprise
- Property case sensitivity bug fixed in Test-GuardianRestrictions
- Blocked operations: 17 destructive commands
- No -Force used, no real destructive tests

### Current Risks
1. **OIDC clientId not yet configured in Azure** — requires human bootstrap
   - Until configured, AZURE_CREDENTIALS fallback method used
   - Documented in docs/Azure-OIDC-Setup.md
2. **No project has been created with the new pipeline** — pending FASE 10
3. **Azure credentials currently use PAT-based deployment** — to be replaced by OIDC

### Next Steps
- FASE 8: Complete Crear-HermesProyecto review
- FASE 9: Non-destructive validation suite
- FASE 10: Real CI/CD validation with controlled test project
- FASE 11: Controlled failure test
- FASE 12: Autonomy measurement
- FASE 13: Observability reports
- FASE 14: Git clean verification
- FASE 15: Final commit