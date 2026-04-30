#!/bin/bash
# ============================================================
# setup_docker.sh – Cria todos os objetos Docker manualmente
# DimDim - 2º Checkpoint DevOps & Cloud Computing
#
# USO: bash scripts/setup_docker.sh [SEU_RM]
# Ex:  bash scripts/setup_docker.sh RM123456
# ============================================================

RM=${1:-"RM000000"}
echo "==========================================="
echo "  DimDim Docker Setup  |  $RM"
echo "==========================================="

# ── 1. Rede ─────────────────────────────────────────────────
echo ""
echo "[1/5] Criando rede dimdim-network..."
docker network create dimdim-network 2>/dev/null || echo "  ↳ rede já existe, pulando."

# ── 2. Volume ────────────────────────────────────────────────
echo ""
echo "[2/5] Criando volume nomeado oracle-data..."
docker volume create oracle-data 2>/dev/null || echo "  ↳ volume já existe, pulando."

# ── 3. Container Oracle XE ───────────────────────────────────
echo ""
echo "[3/5] Subindo container Oracle XE (gvenzl/oracle-xe:21-slim)..."
echo "      (Pode demorar ~2-3 min no primeiro pull)"
docker run -d \
  --name "oracle-db-${RM}" \
  --network dimdim-network \
  -p 1521:1521 \
  -v oracle-data:/opt/oracle/oradata \
  -e ORACLE_PASSWORD=dimdim123 \
  -e ORACLE_DATABASE=XEPDB1 \
  gvenzl/oracle-xe:21-slim

echo "  ↳ Aguardando Oracle ficar saudável (pode levar ~2 min)..."
until docker exec "oracle-db-${RM}" healthcheck.sh 2>/dev/null; do
  printf "."
  sleep 10
done
echo ""
echo "  ↳ Oracle pronto!"

# ── 4. Build da imagem da API ─────────────────────────────────
echo ""
echo "[4/5] Fazendo build da imagem dimdim-api..."
docker build -t dimdim-api:latest ./app

# ── 5. Container da API ───────────────────────────────────────
echo ""
echo "[5/5] Subindo container da API FastAPI..."
docker run -d \
  --name "dimdim-api-${RM}" \
  --network dimdim-network \
  -p 8000:8000 \
  -e DB_USER=system \
  -e DB_PASSWORD=dimdim123 \
  -e DB_HOST="oracle-db-${RM}" \
  -e DB_PORT=1521 \
  -e DB_SERVICE=XEPDB1 \
  -e APP_ENV=production \
  dimdim-api:latest

echo ""
echo "==========================================="
echo "  Setup concluído!"
echo "==========================================="
echo ""
echo "  API disponível em:  http://localhost:8000"
echo "  Docs (Swagger):     http://localhost:8000/docs"
echo "  Health check:       http://localhost:8000/health"
echo ""
echo "  Containers em execução:"
docker ps --filter "name=${RM}" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
echo ""
echo "  Para evidências do CP, rode:"
echo "    docker ps"
echo "    docker image ls"
echo "    docker volume ls"
echo "    docker network ls"
