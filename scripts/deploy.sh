#!/usr/bin/env bash
set -euo pipefail

RG_NAME="${RG_NAME:-rg-apim-private-test}"
LOCATION="${LOCATION:-koreacentral}"
TEMPLATE_FILE="${TEMPLATE_FILE:-../infra/main.bicep}"
PARAM_FILE="${PARAM_FILE:-../infra/main.parameters.json}"
DO_WHAT_IF="${DO_WHAT_IF:-false}"

echo "Creating resource group: ${RG_NAME} (${LOCATION})"
az group create --name "${RG_NAME}" --location "${LOCATION}" >/dev/null

if [[ "${DO_WHAT_IF}" == "true" ]]; then
  echo "Running what-if deployment..."
  az deployment group what-if \
    --resource-group "${RG_NAME}" \
    --template-file "${TEMPLATE_FILE}" \
    --parameters "@${PARAM_FILE}"
else
  echo "Running deployment..."
  az deployment group create \
    --resource-group "${RG_NAME}" \
    --template-file "${TEMPLATE_FILE}" \
    --parameters "@${PARAM_FILE}"
fi
