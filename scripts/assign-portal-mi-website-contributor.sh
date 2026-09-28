#!/usr/bin/env bash
# =============================================================================
# assign-portal-mi-website-contributor.sh
# =============================================================================
# One-time script to assign "Website Contributor" role to the AS-HermesPortal
# System-Assigned Managed Identity (MI) at the RG scope.
#
# WHY IS THIS NEEDED?
#   The Portal's MI only had "Reader" at RG-Hermes-Proyectos scope, which allows
#   reading App Service Plans / Web Apps but NOT start/stop/delete. The portal
#   endpoints for App Service management:
#       POST /api/fabrica/proyectos/{id}/iniciar-app
#       POST /api/fabrica/proyectos/{id}/detener-app
#       POST /api/fabrica/proyectos/{id}/eliminar-app
#   returned "ERROR_PERMISOS" (Azure ARM 403) until this role was granted.
#
# LEAST PRIVILEGE
#   "Website Contributor" grants Microsoft.Web/sites/* (start, stop, restart,
#   delete, config...) on websites ONLY. It does NOT grant control over App
#   Service Plans, Storage, Key Vault or other resources in the RG.
#   Prefer this over "Contributor" unless broader access is explicitly required.
#
# Run from Azure Portal Cloud Shell (bash) with Owner/UserAccessAdmin privileges
# (or any identity holding Microsoft.Authorization/roleAssignments/write).
#
# Usage:
#   bash scripts/assign-portal-mi-website-contributor.sh
#   bash scripts/assign-portal-mi-website-contributor.sh --verify
# =============================================================================

set -euo pipefail

APP_NAME="as-hermesportal"
RESOURCE_GROUP="RG-Hermes-Proyectos"
SUBSCRIPTION_ID="${AZURE_SUBSCRIPTION_ID:-$(az account show --query id -o tsv 2>/dev/null || echo '')}"
ROLE="Website Contributor"

SCOPE="/subscriptions/${SUBSCRIPTION_ID}/resourceGroups/${RESOURCE_GROUP}"

# --- Help / Verify mode ---
if [[ "${1:-}" == "--verify" || "${1:-}" == "-v" ]]; then
  echo "=== Verifying '${ROLE}' assignment for ${APP_NAME} ==="
  MI_ID=$(az webapp identity show --name "${APP_NAME}" --resource-group "${RESOURCE_GROUP}" --query principalId -o tsv 2>/dev/null || true)
  if [[ -z "${MI_ID}" ]]; then
    echo "ERROR: No Managed Identity found for ${APP_NAME}"
    exit 1
  fi
  echo "MI Principal ID: ${MI_ID}"
  ROLE_CHECK=$(az role assignment list --assignee "${MI_ID}" --role "${ROLE}" --scope "${SCOPE}" --query "[].id" -o tsv 2>/dev/null || true)
  if [[ -n "${ROLE_CHECK}" ]]; then
    echo "OK: '${ROLE}' IS assigned to ${APP_NAME} MI at RG scope"
    echo "Role Assignment ID: ${ROLE_CHECK}"
    exit 0
  else
    echo "FAIL: '${ROLE}' is NOT assigned to ${APP_NAME} MI"
    echo "Run: bash $0"
    exit 1
  fi
fi

# --- Main: Assign role ---
echo "=== Assigning '${ROLE}' to ${APP_NAME} System-Assigned MI ==="
echo "Subscription:   ${SUBSCRIPTION_ID}"
echo "Resource Group: ${RESOURCE_GROUP}"
echo "Scope:          ${SCOPE}"
echo ""

if [[ -z "${SUBSCRIPTION_ID}" ]]; then
  echo "ERROR: Not logged into Azure. Run 'az login' first."
  exit 1
fi

MI_ID=$(az webapp identity show --name "${APP_NAME}" --resource-group "${RESOURCE_GROUP}" --query principalId -o tsv 2>/dev/null || true)
if [[ -z "${MI_ID}" ]]; then
  echo "WARNING: ${APP_NAME} does not have System-Assigned MI enabled. Enabling now..."
  az webapp identity assign --name "${APP_NAME}" --resource-group "${RESOURCE_GROUP}" --output none
  MI_ID=$(az webapp identity show --name "${APP_NAME}" --resource-group "${RESOURCE_GROUP}" --query principalId -o tsv)
fi
echo "MI Principal ID: ${MI_ID}"

echo "Checking if '${ROLE}' is already assigned..."
EXISTING=$(az role assignment list --assignee "${MI_ID}" --role "${ROLE}" --scope "${SCOPE}" --query "[].id" -o tsv 2>/dev/null || true)
if [[ -n "${EXISTING}" ]]; then
  echo "OK: '${ROLE}' already assigned (ID: ${EXISTING})"
  echo "No changes needed."
  exit 0
fi

echo "Assigning '${ROLE}' at RG scope..."
az role assignment create \
  --assignee-object-id "${MI_ID}" \
  --assignee-principal-type "ServicePrincipal" \
  --role "${ROLE}" \
  --scope "${SCOPE}" \
  --output none

echo ""
echo "=== SUCCESS ==="
echo "'${ROLE}' assigned to ${APP_NAME} MI at ${RESOURCE_GROUP} scope."
echo ""
echo "NOTE: RBAC propagation can take up to a few minutes."
echo "Verify with: bash $0 --verify"
echo ""
echo "Then the portal can manage App Services:"
echo "  https://${APP_NAME}.azurewebsites.net/"
echo "  (botones Iniciar / Detener / Eliminar en 'Ultimas 5 Creaciones de Proyectos Hijos')"