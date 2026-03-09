#!/usr/bin/env bash
set -euo pipefail

RG_NAME="${RG_NAME:-rg-apim-private-test}"

echo "Deleting resource group: ${RG_NAME}"
az group delete --name "${RG_NAME}" --yes --no-wait
