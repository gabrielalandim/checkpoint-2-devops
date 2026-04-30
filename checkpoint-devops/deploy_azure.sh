#!/bin/bash
# ============================================================
# deploy_azure.sh – Deploy DimDim no Azure Container Instances
# Pré-requisitos: az CLI instalado e logado (az login)
#
# USO: bash scripts/deploy_azure.sh [SEU_RM]
# ============================================================

RM=${1:-"RM000000"}
RESOURCE_GROUP="rg-dimdim-${RM,,}"
LOCATION="brazilsouth"
ACR_NAME="acrdimdim${RM,,}"         # Azure Container Registry
ACI_GROUP="aci-dimdim-${RM,,}"

echo "==========================================="
echo "  DimDim – Deploy Azure  |  $RM"
echo "==========================================="

# ── 1. Resource Group ────────────────────────────────────────
echo ""
echo "[1/6] Criando Resource Group..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --output table

# ── 2. Azure Container Registry ──────────────────────────────
echo ""
echo "[2/6] Criando Azure Container Registry (ACR)..."
az acr create \
  --resource-group "$RESOURCE_GROUP" \
  --name "$ACR_NAME" \
  --sku Basic \
  --admin-enabled true \
  --output table

ACR_SERVER=$(az acr show --name "$ACR_NAME" --query loginServer -o tsv)
ACR_USER=$(az acr credential show --name "$ACR_NAME" --query username -o tsv)
ACR_PASS=$(az acr credential show --name "$ACR_NAME" --query "passwords[0].value" -o tsv)

echo "  ↳ ACR: $ACR_SERVER"

# ── 3. Build e Push da imagem ─────────────────────────────────
echo ""
echo "[3/6] Build e push da imagem da API para o ACR..."
az acr build \
  --registry "$ACR_NAME" \
  --image dimdim-api:latest \
  ./app

# ── 4. Deploy Oracle XE no ACI ───────────────────────────────
echo ""
echo "[4/6] Subindo Oracle XE no Azure Container Instances..."
az container create \
  --resource-group "$RESOURCE_GROUP" \
  --name "oracle-db-${RM,,}" \
  --image gvenzl/oracle-xe:21-slim \
  --cpu 2 --memory 4 \
  --ports 1521 \
  --environment-variables \
      ORACLE_PASSWORD=dimdim123 \
      ORACLE_DATABASE=XEPDB1 \
  --dns-name-label "oracle-db-${RM,,}" \
  --output table

ORACLE_FQDN=$(az container show \
  --resource-group "$RESOURCE_GROUP" \
  --name "oracle-db-${RM,,}" \
  --query ipAddress.fqdn -o tsv)

echo "  ↳ Oracle FQDN: $ORACLE_FQDN"
echo "  ↳ Aguardando Oracle inicializar (90s)..."
sleep 90

# ── 5. Deploy API no ACI ──────────────────────────────────────
echo ""
echo "[5/6] Subindo DimDim API no Azure Container Instances..."
az container create \
  --resource-group "$RESOURCE_GROUP" \
  --name "dimdim-api-${RM,,}" \
  --image "${ACR_SERVER}/dimdim-api:latest" \
  --registry-login-server "$ACR_SERVER" \
  --registry-username "$ACR_USER" \
  --registry-password "$ACR_PASS" \
  --cpu 1 --memory 1.5 \
  --ports 8000 \
  --environment-variables \
      DB_USER=system \
      DB_PASSWORD=dimdim123 \
      DB_HOST="$ORACLE_FQDN" \
      DB_PORT=1521 \
      DB_SERVICE=XEPDB1 \
      APP_ENV=production \
  --dns-name-label "dimdim-api-${RM,,}" \
  --output table

API_FQDN=$(az container show \
  --resource-group "$RESOURCE_GROUP" \
  --name "dimdim-api-${RM,,}" \
  --query ipAddress.fqdn -o tsv)

# ── 6. Resultado ──────────────────────────────────────────────
echo ""
echo "==========================================="
echo "  Deploy Azure concluído!"
echo "==========================================="
echo ""
echo "  API:    http://${API_FQDN}:8000"
echo "  Docs:   http://${API_FQDN}:8000/docs"
echo "  Health: http://${API_FQDN}:8000/health"
echo ""
echo "  Oracle: ${ORACLE_FQDN}:1521"
echo "==========================================="
