#!/bin/bash
# ============================================================
# crud_test.sh – Demonstra o CRUD completo da API DimDim
# Use este script para gravar o vídeo de evidência do CP2
#
# USO: bash scripts/crud_test.sh [BASE_URL]
# Ex:  bash scripts/crud_test.sh http://localhost:8000
# ============================================================

BASE=${1:-"http://localhost:8000"}

echo "==========================================="
echo "  DimDim – Evidência CRUD Completo"
echo "  Base URL: $BASE"
echo "==========================================="

# ── Health ───────────────────────────────────────────────────
echo ""
echo ">>> [HEALTH] Verificando API e conexão com banco..."
curl -s "$BASE/health" | python3 -m json.tool
sleep 1

# ── CREATE ───────────────────────────────────────────────────
echo ""
echo "==========================================="
echo ">>> [INSERT] Criando cliente Ana Silva..."
RESPONSE=$(curl -s -X POST "$BASE/clientes" \
  -H "Content-Type: application/json" \
  -d '{
    "nome":     "Ana Silva",
    "email":    "ana.silva@dimdim.com.br",
    "cpf":      "123.456.789-00",
    "telefone": "(11) 99999-0001",
    "saldo":    1500.00
  }')
echo "$RESPONSE" | python3 -m json.tool
CLIENT_ID=$(echo "$RESPONSE" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
echo "  ↳ ID criado: $CLIENT_ID"
sleep 1

echo ""
echo ">>> Confirmando no banco (GET /clientes/$CLIENT_ID)..."
curl -s "$BASE/clientes/$CLIENT_ID" | python3 -m json.tool
sleep 1

# ── READ ALL ──────────────────────────────────────────────────
echo ""
echo "==========================================="
echo ">>> [SELECT] Listando todos os clientes..."
curl -s "$BASE/clientes" | python3 -m json.tool
sleep 1

# ── UPDATE ───────────────────────────────────────────────────
echo ""
echo "==========================================="
echo ">>> [UPDATE] Atualizando telefone e saldo do cliente $CLIENT_ID..."
curl -s -X PUT "$BASE/clientes/$CLIENT_ID" \
  -H "Content-Type: application/json" \
  -d '{"telefone": "(11) 88888-0002", "saldo": 2500.00}' | python3 -m json.tool
sleep 1

echo ""
echo ">>> Confirmando UPDATE no banco..."
curl -s "$BASE/clientes/$CLIENT_ID" | python3 -m json.tool
sleep 1

# ── DELETE ───────────────────────────────────────────────────
echo ""
echo "==========================================="
echo ">>> [DELETE] Removendo cliente $CLIENT_ID..."
curl -s -X DELETE "$BASE/clientes/$CLIENT_ID" | python3 -m json.tool
sleep 1

echo ""
echo ">>> Confirmando DELETE (deve retornar 404)..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "$BASE/clientes/$CLIENT_ID")
echo "  ↳ HTTP Status: $HTTP_CODE (404 = cliente removido com sucesso)"

echo ""
echo "==========================================="
echo "  CRUD completo evidenciado!"
echo "==========================================="
