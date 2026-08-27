# RC77 — Provision App Service Audit

**Estado:** `RC77-PREPARED` (con HUMAN_REQUIRED pendiente)

**Fecha:** 2026-08-26

---

## Resumen

| Componente | Estado |
|---|---|
| Workflow: `provision-appservice.yml` | ✅ PASS |
| Config: `Hermes.Azure.json` | ✅ PASS |
| Módulo: `Azure.ps1` (Read-AzureConfiguration) | ✅ PASS |
| Módulo: `Azure.ps1` (Get-AzureIdentityMode) | ✅ PASS |
| Módulo: `Azure.ps1` (Assert-AzureIdentityReady) | ✅ PASS |
| Guardian: `Hermes.InfrastructureProtection.json` | ✅ PASS (sin cambios necesarios) |
| Application (Client) ID | ⛔ HUMAN_REQUIRED |
| GitHub Secrets (AZURE_CLIENT_ID) | ⛔ HUMAN_REQUIRED |
| GitHub Environment "production" | ⛔ HUMAN_REQUIRED |

---

## Detalle por punto RC77

### 1. Identidad (config/Hermes.Azure.json)
- ✅ `AzureIdentityMode`: `DedicatedApp`
- ✅ `AzureIdentityTargetApp`: `UR-Fabrica-Proyectos-AR`
- ✅ `AzureIdentityTargetAppId`: `null` (no inventado)
- ✅ `AzureIdentityScope`: `RG-Hermes-Proyectos`
- ✅ Sin client secrets, tokens ni AZURE_CREDENTIALS

### 2. GitHub OIDC
- ✅ `permissions: { contents: read, id-token: write }`
- ✅ `azure/login@v2` con `client-id`, `tenant-id`, `subscription-id` desde secrets
- ✅ Sin GUIDs hardcodeados
- ✅ Sin AZURE_CREDENTIALS, client-secret, password, token, service-principal JSON

### 3. Environment
- ✅ `environment: production` declarado
- ✅ No intenta crear el Environment automáticamente

### 4. projectName validado
- ✅ Regex: `^[a-z0-9-]{3,40}$`
- ✅ Rechaza: espacios, comillas, backticks, $, ;, &, |, /, \, shell commands
- ✅ Falla rápido si inválido

### 5. Resource Group fijo
- ✅ RG fijo: `RG-Hermes-Proyectos`
- ✅ READ ONLY: `az group show` — si no existe, FAIL claro
- ✅ No crea RG automáticamente

### 6. App Service Plan
- ✅ Nombre: `asp-{projectName}`
- ✅ Linux, SKU seleccionado, location
- ✅ Si no existe: crea
- ✅ Si existe: valida kind (linux), location — FAIL si incompatible
- ✅ No modifica silenciosamente

### 7. Web App
- ✅ Nombre: `as-{projectName}`
- ✅ Si no existe: crea
- ✅ Si existe: muestra estado sin destruir/reemplazar
- ✅ Sin `--force`

### 8. App Settings
- ✅ Solo `PROJECT_NAME` (valor público)
- ✅ No contiene: AZURE_CLIENT_ID, AZURE_TENANT_ID, AZURE_SUBSCRIPTION_ID
- ✅ No contiene: APPINSIGHTS_INSTRUMENTATIONKEY
- ✅ Solo aplica si APP_CREATED=true (nueva Web App)

### 9. Logging
- ✅ Habilitado para Web App (nueva o existente)

### 10. Idempotencia
- ✅ Primera ejecución: crea Plan + Web App
- ✅ Segunda ejecución: detecta existentes, valida, no duplica, no destruye
- ✅ Variables CREATED/APP_CREATED controlan flujo

### 11. Seguridad
- ✅ Sin tokens, passwords, client secrets, ghp_, gho_, github_pat_
- ✅ Sin AZURE_CREDENTIALS, connection strings, credenciales embebidas
- ✅ Sin comandos destructivos:
  - `az group delete`: ❌ NO ENCONTRADO
  - `az webapp delete`: ❌ NO ENCONTRADO
  - `az appservice plan delete`: ❌ NO ENCONTRADO
  - `az resource delete`: ❌ NO ENCONTRADO
  - `--force`: ❌ NO ENCONTRADO

### 12. Output
- ✅ Muestra: Project, Resource Group, Plan, Web App, Runtime, Location, Identity Mode, OIDC Status
- ✅ No muestra secretos ni GUIDs

### 13. Validaciones locales realizadas
- ✅ YAML válido
- ✅ JSON válido (Hermes.Azure.json)
- ✅ AzureIdentityMode: DedicatedApp
- ✅ OIDC referenciado sin GUIDs
- ✅ environment production declarado
- ✅ permissions: id-token
- ✅ Sin secretos embebidos
- ✅ Sin comandos destructivos

---

## Bloqueos (HUMAN_REQUIRED)

| # | Requisito | Detalle |
|---|---|---|
| 1 | **Application (Client) ID** | Ejecutar: `az ad app list --display-name "UR-Fabrica-Proyectos-AR" --query "[0].appId" -o tsv` en Azure Cloud Shell |
| 2 | **GitHub Secret: AZURE_CLIENT_ID** | `gh secret set AZURE_CLIENT_ID --repo FREDYASARMIENTOT/HERMES-ENTERPRISE --body "<ClientID>"` |
| 3 | **GitHub Secret: AZURE_TENANT_ID** | `gh secret set AZURE_TENANT_ID --repo FREDYASARMIENTOT/HERMES-ENTERPRISE --body "ae525757-89ba-4d30-a2f7-49796ef8c604"` |
| 4 | **GitHub Secret: AZURE_SUBSCRIPTION_ID** | `gh secret set AZURE_SUBSCRIPTION_ID --repo FREDYASARMIENTOT/HERMES-ENTERPRISE --body "01bfad48-c092-4712-bc72-f141eb01a8d4"` |
| 5 | **GitHub Environment "production"** | Crear en Settings > Environments > New environment "production" |
| 6 | **Federated Credential** | Verificar que exista federated credential para `repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production` |

---

## Próximo paso

Una vez resueltos los HUMAN_REQUIRED:

1. Hacer commit + push a `main` (incluye los 3 archivos modificados)
2. Ir a GitHub Actions > "Provision App Service" > Run workflow
3. Ingresar `projectName: my-test-project`
4. Verificar creación en Azure Portal

<!-- EOF -->