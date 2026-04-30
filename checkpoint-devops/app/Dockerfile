# ── Dockerfile – DimDim API (FastAPI + Oracle) ──────────────────────────────
FROM python:3.12-slim

LABEL maintainer="Equipe DimDim"
LABEL description="DimDim API - Gerenciamento de Clientes"

# Installs Oracle Instant Client deps (needed by python-oracledb thick mode, optional)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libaio1t64 curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

EXPOSE 8000

# Variáveis de ambiente (serão sobrescritas no docker run / compose)
ENV DB_USER=system \
    DB_PASSWORD=dimdim123 \
    DB_HOST=oracle-db \
    DB_PORT=1521 \
    DB_SERVICE=XEPDB1

CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8000"]
