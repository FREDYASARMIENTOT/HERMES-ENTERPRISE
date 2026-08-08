# RC75-C1 — Azure Identity Preparation State

## Completed (from previous)

- [x] FASE 1 — Precheck: Confirm existing state (audit complete in RC75C0)
- [x] FASE 2 — Identify architecture: Factory vs Projects Azure auth models
- [x] FASE 3 — OIDC check: Confirm user cannot create App Registration (BLOCKED)
- [x] FASE 4 — Non-destructive validation: Subscription/tenant verified
- [x] FASE 5 — Blockers documented: RC75C1-AzureAuthAudit.md + RC75C1-AzureAuthAudit.json
- [x] FASE 6 — Migration readiness: docs/AzureIdentityMigration.md produced

## Remaining — Endurecimiento bajo HUMAN_REQUIRED

Current task adds non-destructive hardening to prepare RC75-C1 for completion:

- [x] Add AzureIdentityMode to Hermes.Azure.json (with tenantId)
- [x] Add Get-AzureIdentityMode to Azure.ps1
- [x] Add environment: production to Deploy workflow (guard against non-main pushes)
- [x] Verify no embedded tokens in workflows
- [x] Verify Guardian + InfrastructureProtection config integrity
- [x] Audit Resource Locks (read-only) via az CLI
- [x] Update docs/AzureIdentityMigration.md with clear CURRENT/TARGET
- [x] Generate RC75C1.md, RC75C1.json, RC75C1.html reports

## HUMAN_REQUIRED (BLOCKED — not part of this task)

The following require Azure AD Application Administrator and remain BLOCKED:
- Create App Registration "Hermes-Enterprise-CI"
- Create federated credential
- Grant RBAC Contributor role
- Set AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID secrets