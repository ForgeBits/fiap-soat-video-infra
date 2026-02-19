#!/bin/bash

# ===========================================
# Script para Remover TODOS os Recursos K8s
# Use --rerun para reaplicar após remover
# ===========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Verificar parâmetro --rerun
RERUN=false
if [[ "$1" == "--rerun" ]] || [[ "$1" == "-r" ]]; then
    RERUN=true
fi

# Carregar variáveis de ambiente (necessário para rerun)
if [[ -f "$ROOT_DIR/.env" ]]; then
    export $(grep -v '^#' "$ROOT_DIR/.env" | xargs)
    echo -e "${GREEN}Variáveis de ambiente carregadas!${NC}"
else
    echo -e "${YELLOW}Aviso: Arquivo .env não encontrado em $ROOT_DIR${NC}"
    if [[ "$RERUN" == true ]]; then
        echo -e "${RED}Erro: .env é necessário para --rerun${NC}"
        exit 1
    fi
fi

echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Removendo TODOS os Recursos K8s${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# ===========================================
# REMOÇÃO
# ===========================================

# Remover Auth
echo -e "${YELLOW}Removendo serviço AUTH...${NC}"
kubectl delete deployment auth-service --ignore-not-found=true
kubectl delete service auth-service --ignore-not-found=true
kubectl delete configmap auth-config --ignore-not-found=true
kubectl delete secret auth-secret --ignore-not-found=true
echo -e "${GREEN}Auth removido!${NC}"
echo ""

# Remover API
echo -e "${YELLOW}Removendo serviço API...${NC}"
kubectl delete deployment api-service --ignore-not-found=true
kubectl delete service api-service --ignore-not-found=true
kubectl delete configmap api-config --ignore-not-found=true
kubectl delete secret api-secret --ignore-not-found=true
echo -e "${GREEN}API removido!${NC}"
echo ""

# Remover RabbitMQ
echo -e "${YELLOW}Removendo serviço RABBITMQ...${NC}"
kubectl delete deployment rabbitmq --ignore-not-found=true
kubectl delete service rabbitmq-service --ignore-not-found=true
kubectl delete configmap rabbitmq-config --ignore-not-found=true
kubectl delete secret rabbitmq-secret --ignore-not-found=true
echo -e "${GREEN}RabbitMQ removido!${NC}"
echo ""

# Remover Infrastructure (Elasticsearch e Kibana)
echo -e "${YELLOW}Removendo INFRASTRUCTURE (Elasticsearch/Kibana)...${NC}"
kubectl delete -f "$ROOT_DIR/k8s/infrastructure/elasticsearch.yaml" --ignore-not-found=true 2>/dev/null
kubectl delete -f "$ROOT_DIR/k8s/infrastructure/kibana.yaml" --ignore-not-found=true 2>/dev/null
echo -e "${GREEN}Infrastructure removido!${NC}"
echo ""

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}  TODOS os recursos foram removidos!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# ===========================================
# REAPLICAÇÃO (somente com --rerun)
# ===========================================

if [[ "$RERUN" == true ]]; then
    echo -e "${BLUE}=========================================${NC}"
    echo -e "${BLUE}  Reaplicando TODOS os Recursos K8s${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""

    # Aplicar Infrastructure
    echo -e "${YELLOW}Aplicando INFRASTRUCTURE...${NC}"
    kubectl apply -f "$ROOT_DIR/k8s/infrastructure/elasticsearch.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/infrastructure/kibana.yaml"
    echo -e "${GREEN}Infrastructure aplicado!${NC}"
    echo ""

    # Aplicar RabbitMQ
    echo -e "${YELLOW}Aplicando RABBITMQ...${NC}"
    envsubst < "$ROOT_DIR/k8s/rabbitmq/secret.yaml" | kubectl apply -f -
    kubectl apply -f "$ROOT_DIR/k8s/rabbitmq/configmap.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/rabbitmq/deployment.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/rabbitmq/service.yaml"
    echo -e "${GREEN}RabbitMQ aplicado!${NC}"
    echo ""

    # Aplicar Auth
    echo -e "${YELLOW}Aplicando AUTH...${NC}"
    envsubst < "$ROOT_DIR/k8s/auth/secret.yaml" | kubectl apply -f -
    kubectl apply -f "$ROOT_DIR/k8s/auth/configmap.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/auth/deployment.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/auth/service.yaml"
    echo -e "${GREEN}Auth aplicado!${NC}"
    echo ""

    # Aplicar API
    echo -e "${YELLOW}Aplicando API...${NC}"
    envsubst < "$ROOT_DIR/k8s/api/secret.yaml" | kubectl apply -f -
    kubectl apply -f "$ROOT_DIR/k8s/api/configmap.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/api/deployment.yaml"
    kubectl apply -f "$ROOT_DIR/k8s/api/service.yaml"
    echo -e "${GREEN}API aplicado!${NC}"
    echo ""

    echo -e "${BLUE}=========================================${NC}"
    echo -e "${GREEN}  TODOS os recursos foram reaplicados!${NC}"
    echo -e "${BLUE}=========================================${NC}"
    echo ""

    # Mostrar status dos pods
    echo -e "${YELLOW}Status dos pods:${NC}"
    kubectl get pods
fi

