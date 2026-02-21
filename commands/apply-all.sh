#!/bin/bash

# ===========================================
# Script para Aplicar TODOS os Recursos K8s
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Carrega variáveis de ambiente do .env na raiz do projeto
if [[ -f "$ROOT_DIR/.env" ]]; then
    export $(grep -v '^#' "$ROOT_DIR/.env" | xargs)
    echo -e "${GREEN}Variáveis de ambiente carregadas!${NC}"
else
    echo -e "${RED}Erro: Arquivo .env não encontrado em $ROOT_DIR${NC}"
    exit 1
fi

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Aplicando TODOS os Recursos K8s${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# ===========================================
# 1. CRIAR NAMESPACE
# ===========================================

echo -e "${YELLOW}[1/5] Criando namespace fiapx...${NC}"
kubectl get namespace fiapx &>/dev/null || kubectl create namespace fiapx
echo -e "${GREEN}✓ Namespace criado/verificado!${NC}"
echo ""

# ===========================================
# 2. APLICAR INFRASTRUCTURE
# ===========================================

echo -e "${YELLOW}[2/5] Aplicando INFRASTRUCTURE...${NC}"
echo ""

echo "  → PostgreSQL Auth..."
kubectl apply -f "$ROOT_DIR/k8s/infrastructure/postgres-auth.yaml"

echo "  → PostgreSQL API..."
kubectl apply -f "$ROOT_DIR/k8s/infrastructure/postgres-api.yaml"

echo "  → Redis API..."
kubectl apply -f "$ROOT_DIR/k8s/infrastructure/redis-api.yaml"

echo "  → Elasticsearch..."
kubectl apply -f "$ROOT_DIR/k8s/infrastructure/elasticsearch.yaml"

echo "  → Kibana..."
kubectl apply -f "$ROOT_DIR/k8s/infrastructure/kibana.yaml"

echo -e "${GREEN}✓ Infrastructure aplicada!${NC}"
echo ""

# Aguardar bancos de dados estarem prontos
echo -e "${YELLOW}Aguardando bancos de dados ficarem prontos...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres-auth -n fiapx --timeout=120s 2>/dev/null || echo "  PostgreSQL Auth ainda inicializando..."
kubectl wait --for=condition=ready pod -l app=postgres-api -n fiapx --timeout=120s 2>/dev/null || echo "  PostgreSQL API ainda inicializando..."
kubectl wait --for=condition=ready pod -l app=redis-api -n fiapx --timeout=60s 2>/dev/null || echo "  Redis API ainda inicializando..."
echo ""

# ===========================================
# 3. APLICAR RABBITMQ
# ===========================================

echo -e "${YELLOW}[3/5] Aplicando RABBITMQ...${NC}"
echo ""

echo "  → Secret..."
envsubst < "$ROOT_DIR/k8s/rabbitmq/secret.yaml" | kubectl apply -f -

echo "  → ConfigMap..."
kubectl apply -f "$ROOT_DIR/k8s/rabbitmq/configmap.yaml"

echo "  → Deployment..."
kubectl apply -f "$ROOT_DIR/k8s/rabbitmq/deployment.yaml"

echo "  → Service..."
kubectl apply -f "$ROOT_DIR/k8s/rabbitmq/service.yaml"

echo -e "${GREEN}✓ RabbitMQ aplicado!${NC}"
echo ""

# Aguardar RabbitMQ estar pronto
echo -e "${YELLOW}Aguardando RabbitMQ ficar pronto...${NC}"
kubectl wait --for=condition=ready pod -l app=rabbitmq -n fiapx --timeout=90s 2>/dev/null || echo "  RabbitMQ ainda inicializando..."
echo ""

# ===========================================
# 4. APLICAR AUTH
# ===========================================

echo -e "${YELLOW}[4/5] Aplicando AUTH SERVICE...${NC}"
echo ""

echo "  → Secret..."
envsubst < "$ROOT_DIR/k8s/auth/secret.yaml" | kubectl apply -f -

echo "  → ConfigMap..."
kubectl apply -f "$ROOT_DIR/k8s/auth/configmap.yaml"

echo "  → Deployment..."
kubectl apply -f "$ROOT_DIR/k8s/auth/deployment.yaml"

echo "  → Service..."
kubectl apply -f "$ROOT_DIR/k8s/auth/service.yaml"

echo -e "${GREEN}✓ Auth Service aplicado!${NC}"
echo ""

# ===========================================
# 5. APLICAR API
# ===========================================

echo -e "${YELLOW}[5/5] Aplicando API SERVICE...${NC}"
echo ""

echo "  → Secret..."
envsubst < "$ROOT_DIR/k8s/api/secret.yaml" | kubectl apply -f -

echo "  → ConfigMap..."
kubectl apply -f "$ROOT_DIR/k8s/api/configmap.yaml"

echo "  → Deployment..."
kubectl apply -f "$ROOT_DIR/k8s/api/deployment.yaml"

echo "  → Service..."
kubectl apply -f "$ROOT_DIR/k8s/api/service.yaml"

echo -e "${GREEN}✓ API Service aplicado!${NC}"
echo ""

# ===========================================
# FINALIZAÇÃO
# ===========================================

echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}  ✓ TODOS os recursos foram aplicados!${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

echo -e "${YELLOW}Aguardando todos os pods ficarem prontos...${NC}"
echo ""

# Mostrar status dos pods
kubectl get pods -n fiapx

echo ""
echo -e "${YELLOW}Para verificar o status detalhado:${NC}"
echo -e "  kubectl get all -n fiapx"
echo -e "  kubectl get pods -n fiapx -w"
echo ""
echo -e "${YELLOW}Para ver logs:${NC}"
echo -e "  kubectl logs -f deployment/auth-service -n fiapx"
echo -e "  kubectl logs -f deployment/api-service -n fiapx"
echo ""

