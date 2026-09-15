#!/usr/bin/env bash
# =============================================================================
# assign-portal-mi-reader.sh
# =============================================================================
# One-time script to assign Reader role to AS-HermesPortal System-Assigned MI.
# Run from Azure Portal Cloud Shell (bash) with Owner/UserAccessAdmin privileges.
#
# Usage:
#   bash scripts/assign-portal-mi-reader.sh
#
# After running, verify:
#   bash scripts/assign-portal-mi-reader.sh --verify
# =============================================================================

set -euo pipefail

APP_NAME="as-hermesportal"
RESOURCE_GROUP="RG-Hermes-Proyectos"
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-$(az account show --query id -o tsv 2>/dev/null || echo '')}"
ROLE="Reader"

# --- Help / Verify mode ---
if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" ]]; then
  echo "=== Verifying Reader role assignment for ${APP_NAME} ==="
  MI_ID=$(az webapp identity show --name "${APP_NAME}" --resource-group "${RESOURCE_GROUP}" --query principalId -o tsv 2>/dev/null || true)
  if [[ -z "${MI_ID}" ]]; then
    echo "ERROR: No Managed Identity found for ${APP_NAME}"
    echo "Enable it via Portal or run: az webapp identity assign --name ${APP_NAME} --resource-group ${RESOURCE_GROUP}"
    exit 1
  fi
  echo "MI Principal ID: ${MI_ID}"
  ROLE_CHECK=$(az role assignment list --assignee "${MI_ID}" --role "${ROLE}" --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}" --query "[].id" -o tsv 2>/dev/null || true)
  if [[ -n "${ROLE_CHECK}" ]]; then
    echo "OK: Reader role IS assigned to ${APP_NAME} MI at RG scope"
    echo "Role Assignment ID: ${ROLE_CHECK}"
    exit 0
  else
    echo "FAIL: Reader role is NOT assigned to ${APP_NAME} MI"
    echo "Run: bash $0"
    exit 1
  fi
fi

# --- Main: Assign Reader role ---
echo "=== Assigning Reader role to ${APP_NAME} System-Assigned MI ==="
echo "Subscription: ${SUBSCRIPTION_ID}"
echo "Resource Group: ${RESOURCE_GROUP}"
echo ""

# Validate Azure CLI session
if [[ -z "${SUBSCRIPTION_ID}" ]]; then
  echo "ERROR: Not logged into Azure. Run 'az login' first."
  echo "In Azure Portal Cloud Shell, you are already logged in."
  exit 1
fi

# Get MI principal ID
echo "Fetching MI Principal ID..."
MI_ID=$(az webapp identity show --name "${APP_NAME}" --resource-group "${RESOURCE_GROUP}" --query principalId -o tsv 2>/dev/null || true)
if [[ -z "${MI_ID}" ]]; then
  echo "WARNING: ${APP_NAME} does not have System-Assigned MI enabled."
  echo "Enabling now..."
  az webapp identity assign --name "${APP_NAME}" --resource-group "${RESOURCE_GROUP}" --output none
  MI_ID=$(az webapp identity show --name "${APP_NAME}" --resource-group "${RESOURCE_GROUP}" --query principalId -o tsv)
  echo "MI enabled. Principal ID: ${MI_ID}"
else
  echo "MI Principal ID: ${MI_ID}"
fi

# Check if role already exists
echo "Checking if Reader role already assigned..."
EXISTING=$(az role assignment list --assignee "${MI_ID}" --role "${ROLE}" --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}" --query "[].id" -o tsv 2>/dev/null || true)
if [[ -n "${EXISTING}" ]]; then
  echo "OK: Reader role already assigned (ID: ${EXISTING})"
  echo "No changes needed."
  exit 0
fi

# Assign Reader role
echo "Assigning Reader role at RG scope..."
az role assignment create \
  --assignee-object-id "${MI_ID}" \
  --assignee-principal-type "ServicePrincipal" \
  --role "Reader" \
  --scope "/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}" \
  --output none

echo ""
echo "=== SUCCESS ==="
echo "Reader role assigned to ${APP_NAME} MI at RG-Hermes-Proyectos scope."
echo ""
echo "Now the Portal's /api/fabrica/app-service-plans endpoint should return real plans."
echo "Verify at: https://${APP_NAME}.azurewebsites.net/api/fabrica/app-service-plans"
echo ""
echo "To verify via CLI: bash $0 --verify"