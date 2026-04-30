# 🟡 DimDim – Gerenciamento de Clientes em Docker
**DevOps Tools & Cloud Computing – 2º Checkpoint 1º Semestre – FIAP**

> Migração do ambiente de desenvolvimento para **Docker** com **FastAPI + Oracle XE**, hospedado no **Azure**.

---

## 📋 Arquitetura

```
┌─────────────────────────────────────────────────┐
│              dimdim-network (bridge)             │
│                                                  │
│  ┌──────────────────┐    ┌────────────────────┐ │
│  │  dimdim-api-RM   │───▶│  oracle-db-RM      │ │
│  │  FastAPI :8000   │    │  Oracle XE  :1521  │ │
│  │  Python 3.12     │    │  Volume: oracle-data│ │
│  └──────────────────┘    └────────────────────┘ │
└─────────────────────────────────────────────────┘
         │                          │
     :8000 (host)              :1521 (host)
```

**Tecnologias:**
- 🐍 Python 3.12 + FastAPI 0.111 + uvicorn
- 🗄️ Oracle XE 21c (`gvenzl/oracle-xe:21-slim`)
- 🐳 Docker + Docker Compose
- ☁️ Azure Container Instances (ACI) + Azure Container Registry (ACR)

---

## ⚡ Pré-requisitos

| Ferramenta | Versão mínima |
|---|---|
| Docker Desktop / Docker Engine | 24+ |
| Docker Compose | v2+ |
| Python (opcional, para testes locais) | 3.11+ |
| Azure CLI (para deploy em nuvem) | 2.55+ |

---

## 🚀 Opção 1 – Subir com Docker Compose (mais fácil)

```bash
# Clone o repositório
git clone https://github.com/SEU_USUARIO/dimdim-docker.git
cd dimdim-docker

# Edite o RM no docker-compose.yml (container_name)
# Suba tudo com um comando
docker compose up -d

# Acompanhe os logs
docker compose logs -f
```

Aguarde ~2 minutos para o Oracle XE inicializar completamente.

---

## 🔧 Opção 2 – Setup Manual (comandos individuais)

```bash
# 1. Rede
docker network create dimdim-network

# 2. Volume nomeado
docker volume create oracle-data

# 3. Container Oracle XE
docker run -d \
  --name oracle-db-RM000000 \
  --network dimdim-network \
  -p 1521:1521 \
  -v oracle-data:/opt/oracle/oradata \
  -e ORACLE_PASSWORD=dimdim123 \
  -e ORACLE_DATABASE=XEPDB1 \
  gvenzl/oracle-xe:21-slim

# Aguardar Oracle ficar saudável (~2 min)
docker logs -f oracle-db-RM000000

# 4. Build da imagem da API
docker build -t dimdim-api:latest ./app

# 5. Container da API
docker run -d \
  --name dimdim-api-RM000000 \
  --network dimdim-network \
  -p 8000:8000 \
  -e DB_USER=system \
  -e DB_PASSWORD=dimdim123 \
  -e DB_HOST=oracle-db-RM000000 \
  -e DB_PORT=1521 \
  -e DB_SERVICE=XEPDB1 \
  -e APP_ENV=production \
  dimdim-api:latest
```

> 💡 Use o script automatizado: `bash scripts/setup_docker.sh RM000000`

---

## ☁️ Opção 3 – Deploy no Azure

```bash
# Pré-requisito: az login
az login

# Deploy completo (cria ACR, sobe Oracle XE e API no ACI)
bash scripts/deploy_azure.sh RM000000
```

O script cria automaticamente:
- Resource Group `rg-dimdim-rm000000`
- Azure Container Registry
- 2x Azure Container Instances (oracle-db + dimdim-api)

---

## 🌐 Acessando a API

| Recurso | URL |
|---|---|
| Swagger UI (documentação interativa) | http://localhost:8000/docs |
| ReDoc | http://localhost:8000/redoc |
| Health Check | http://localhost:8000/health |
| Listar clientes | http://localhost:8000/clientes |

---

## 📌 Endpoints do CRUD

### ➕ CREATE – Criar cliente
```bash
curl -X POST http://localhost:8000/clientes \
  -H "Content-Type: application/json" \
  -d '{
    "nome":     "João Santos",
    "email":    "joao@dimdim.com.br",
    "cpf":      "111.222.333-44",
    "telefone": "(11) 99999-0001",
    "saldo":    1000.00
  }'
```

### 📋 READ – Listar todos
```bash
curl http://localhost:8000/clientes
```

### 🔍 READ – Buscar por ID
```bash
curl http://localhost:8000/clientes/1
```

### ✏️ UPDATE – Atualizar cliente
```bash
curl -X PUT http://localhost:8000/clientes/1 \
  -H "Content-Type: application/json" \
  -d '{"saldo": 2500.00, "telefone": "(11) 88888-0002"}'
```

### 🗑️ DELETE – Remover cliente
```bash
curl -X DELETE http://localhost:8000/clientes/1
```

### 🎬 Script de evidência completa (para o vídeo)
```bash
bash scripts/crud_test.sh http://localhost:8000
```

---

## 🐳 Comandos de evidência Docker (para o PDF)

```bash
docker ps
docker image ls
docker volume ls
docker network ls
```

---

## 📁 Estrutura do Projeto

```
dimdim-docker/
├── app/
│   ├── main.py           # Aplicação FastAPI (CRUD completo)
│   ├── requirements.txt  # Dependências Python
│   └── Dockerfile        # Imagem da API
├── scripts/
│   ├── setup_docker.sh   # Setup manual (rede, volume, containers)
│   ├── deploy_azure.sh   # Deploy no Azure (ACI + ACR)
│   └── crud_test.sh      # Evidência CRUD para o vídeo
├── docker-compose.yml    # Orquestração local
└── README.md             # Este arquivo (How-to)
```

---

## 🔒 Variáveis de Ambiente

| Variável | Padrão | Descrição |
|---|---|---|
| `DB_USER` | `system` | Usuário Oracle |
| `DB_PASSWORD` | `dimdim123` | Senha Oracle |
| `DB_HOST` | `oracle-db` | Host/nome do container Oracle |
| `DB_PORT` | `1521` | Porta Oracle |
| `DB_SERVICE` | `XEPDB1` | Service name do Oracle XE |
| `APP_ENV` | `production` | Ambiente da aplicação |

---

## 🛑 Parar e limpar tudo

```bash
# Com compose
docker compose down -v

# Manual
docker stop dimdim-api-RM000000 oracle-db-RM000000
docker rm   dimdim-api-RM000000 oracle-db-RM000000
docker volume rm oracle-data
docker network rm dimdim-network
```

---

## 👥 Equipe

| RM | Nome |
|---|---|
| RM000000 | Integrante 1 |
| RM000001 | Integrante 2 |
| RM000002 | Integrante 3 |

> **Disciplina:** DevOps Tools & Cloud Computing  
> **Professor:** João Menk – profjoao.menk@fiap.com.br  
> **FIAP – Tecnologia em Desenvolvimento de Sistemas**
