# Azure OIDC Setup for GitHub Actions

## ONE-TIME HUMAN BOOTSTRAP

This document describes the **one-time** human setup required to enable
OIDC (OpenID Connect) authentication between GitHub Actions and Azure.

Once configured, **no manual credential management is needed** for
deployments. GitHub Actions authenticates to Azure automatically using
federated identity.

## Prerequisites

- Azure subscription with Owner or User Access Administrator permissions
- GitHub organization or user account where repos are created

## Step 1: Create Azure AD Application (or use existing)

```bash
# Create app registration
az ad app create --display-name "Hermes-Enterprise-OIDC" --sign-in-audience AzureADMyOrg

# Get the app ID (clientId)
APP_ID=$(az ad app list --display-name "Hermes-Enterprise-OIDC" --query "[0].appId" -o tsv)

# Create service principal
az ad sp create --id $APP_ID
```

## Step 2: Create Federated Credentials

For each GitHub repository that needs deployment access:

```bash
# For a specific repo
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "HERMES-ENTERPRISE-deploy",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:FREDYASARMIENTOT/HERMES-ENTERPRISE:environment:production",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For any repo in the organization (use org-based subject)
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "any-repo-branch-main",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:FREDYASARMIENTOT/*:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'

# For environment-based deployments
az ad app federated-credential create \
  --id $APP_ID \
  --parameters '{
    "name": "any-repo-environment-production",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:FREDYASARMIENTOT/*:environment:production",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

## Step 3: Assign Contributor role to the service principal

```bash
# Assign Contributor on the resource group where WebApps are created
az role assignment create \
  --assignee $APP_ID \
  --role Contributor \
  --scope /subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/resourceGroups/RG-Hermes-Proyectos

# Assign Website Contributor for Web App management
az role assignment create \
  --assignee $APP_ID \
  --role "Website Contributor" \
  --scope /subscriptions/01bfad48-c092-4712-bc72-f141eb01a8d4/resourceGroups/RG-Hermes-Proyectos
```

## Step 4: Configure GitHub Secrets (done automatically by Crear-HermesProyecto)

Once the Azure AD App and federated credentials are created,
Crear-HermesProyecto will automatically configure these secrets
in each new GitHub repository:

- `AZURE_CLIENT_ID` - The app/client ID
- `AZURE_TENANT_ID` - The Azure AD tenant ID  
- `AZURE_SUBSCRIPTION_ID` - The Azure subscription ID

These are set using `gh secret set` and **never written to files**.

## Verification

```bash
# Verify federated credentials exist
az ad app federated-credential list --id $APP_ID

# Verify role assignment
az role assignment list --assignee $APP_ID --output table

# Check that secrets are set in repo
gh secret list --repo FREDYASARMIENTOT/HERMES-ENTERPRISE
```

## How It Works

```
GitHub Actions
    |
    | 1. Request OIDC token from GitHub's OIDC provider
    | 2. Exchange token for Azure access token
    | 3. Use Azure access token for all azure/* operations
    v
Azure (via azure/login@v2)
```

The workflow uses `azure/login@v2` with OIDC parameters:

```yaml
- name: Azure Login (OIDC)
  uses: azure/login@v2
  with:
    client-id: ${{ secrets.AZURE_CLIENT_ID }}
    tenant-id: ${{ secrets.AZURE_TENANT_ID }}
    subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
```

## Security

- **No PATs, no passwords, no permanent secrets**
- Tokens are short-lived (auto-refreshed per job)
- Federated credentials can be scoped per repo/branch/environment
- Roles can be scoped per resource group
- All credential configuration is **human-only** (one time)