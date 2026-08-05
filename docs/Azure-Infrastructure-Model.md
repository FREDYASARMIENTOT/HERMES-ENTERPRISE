# Azure Infrastructure Model
## Hermes Enterprise — Shared Infrastructure

### Purpose
This document defines the shared Azure infrastructure that will serve all Hermes Enterprise projects. No per-project resources are created here — only the foundation.

---

## Infrastructure Architecture

```
                    ┌──────────────────────────────────────┐
                    │          RG-Hermes-Proyectos          │
                    │       (Resource Group — Shared)       │
                    ├──────────────────────────────────────┤
                    │                                      │
                    │  ┌──────────────────────────────┐   │
                    │  │   Plan-Hermes-Proyectos       │   │
                    │  │  (App Service Plan — B1/B2)  │   │
                    │  └──────────────────────────────┘   │
                    │                                      │
                    │  ┌──────────────────────────────┐   │
                    │  │  Storage Account              │   │
                    │  │  (hermesinfra<random>)        │   │
                    │  │  - Blob: project assets       │   │
                    │  │  - Table: deployment state    │   │
                    │  │  - Queue: async jobs          │   │
                    │  └──────────────────────────────┘   │
                    │                                      │
                    │  ┌──────────────────────────────┐   │
                    │  │  Application Insights          │   │
                    │  │  (hermes-insights)             │   │
                    │  │  - Telemetry pipeline          │   │
                    │  └──────────────────────────────┘   │
                    │                                      │
                    │  ┌──────────────────────────────┐   │
                    │  │  Log Analytics Workspace      │   │
                    │  │  (hermes-logs)                │   │
                    │  │  - Kusto queries              │   │
                    │  │  - Centralized logging        │   │
                    │  └──────────────────────────────┘   │
                    │                                      │
                    │  ┌──────────────────────────────┐   │
                    │  │  Key Vault                    │   │
                    │  │  (hermes-kv-<random>)         │   │
                    │  │  - Secrets                   │   │
                    │  │  - Connection strings        │   │
                    │  │  - Certificates              │   │
                    │  └──────────────────────────────┘   │
                    │                                      │
                    │  ┌──────────────────────────────┐   │
                    │  │  Managed Identity             │   │
                    │  │  (User-Assigned)              │   │
                    │  │  - RBAC for all resources     │   │
                    │  └──────────────────────────────┘   │
                    │                                      │
                    └──────────────────────────────────────┘
```

---

## Resource Relationships

| Resource | Depends On | Purpose |
|----------|-----------|---------|
| RG-Hermes-Proyectos | — | Container for all shared infrastructure |
| Plan-Hermes-Proyectos | RG | Compute plan for all project web apps |
| Storage Account | RG | Blob/Table/Queue for project assets |
| Application Insights | RG + Storage | Telemetry ingestion |
| Log Analytics | RG | Centralized log storage |
| Key Vault | RG + Managed Identity | Secret management |
| Managed Identity | RG | RBAC identity for cross-resource auth |

---

## Resource Specifications

### 1. Resource Group: `RG-Hermes-Proyectos`
- **Location**: `eastus` (configurable)
- **Tags**: `Environment=Shared`, `ManagedBy=Hermes`, `Purpose=Infrastructure`

### 2. App Service Plan: `Plan-Hermes-Proyectos`
- **Sku**: `B1` (Basic — shared for all projects)
- **OS**: `Windows` (configurable)
- **Kind**: `app` (supports multiple web apps)

### 3. Storage Account: `hermesinfra<unique>`
- **Sku**: `Standard_LRS`
- **Kind**: `StorageV2`
- **Access Tier**: `Hot`
- **Services**: Blob, Table, Queue
- **Containers**: `project-assets`, `deployment-artifacts`

### 4. Application Insights: `hermes-insights`
- **Type**: `web`
- **Retention**: 90 days
- **Daily Cap**: 1 GB

### 5. Log Analytics Workspace: `hermes-logs`
- **Sku**: `PerGB2018`
- **Retention**: 30 days (configurable)

### 6. Key Vault: `hermes-kv-<unique>`
- **Sku**: `Standard`
- **Soft Delete**: Enabled
- **Purge Protection**: Enabled
- **Secrets**: `Hermes-SQLite-Connection`, `Hermes-Storage-Connection`

### 7. Managed Identity: `id-hermes-infra`
- **Type**: User-Assigned
- **RBAC Roles**: `Contributor` on RG, `Key Vault Secrets User`
- **Scoped to**: `RG-Hermes-Proyectos`

---

## Deployment Order

```
1. Managed Identity (needed by Key Vault access policies)
2. Resource Group
3. Storage Account
4. Log Analytics Workspace
5. Application Insights (linked to Log Analytics)
6. Key Vault (with access policy for Managed Identity)
7. App Service Plan
```

---

## Telemetry

Each provision operation records:
- Resource type, name, location
- Provisioning state
- Duration
- Error details (if any)
- Correlation ID

Telemetry is stored in:
1. Application Insights (direct)
2. SQLite (Hermes local DB — `AzureInfrastructure` table)
3. Log file (`logs/azure-provision.log`)

---

## Security

- No secrets in code — all via Key Vault
- Managed Identity for inter-resource auth
- No public endpoints for Storage (Private Endpoint ready)
- Key Vault access policies tied to Managed Identity
- All resources tagged `ManagedBy=Hermes` for cost tracking

---

## Next Steps (beyond RC68)

1. Per-project: Web App creation on shared Plan
2. Portal deployment under `RG-Hermes-Proyectos`
3. DNS + Front Door for global routing
4. SQL Database for per-project data