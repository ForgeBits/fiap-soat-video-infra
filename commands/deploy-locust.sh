#!/bin/bash

# Script para deploy do Locust no Kubernetes

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

# Cores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=========================================="
echo -e "  Deploy Locust - Load Testing"
echo -e "==========================================${NC}"
echo ""

# Criar namespace se não existir
kubectl get namespace fiapx &>/dev/null || kubectl create namespace fiapx

echo -e "${YELLOW}Aplicando ConfigMap...${NC}"
kubectl apply -f "$ROOT_DIR/k8s/locust/configmap.yaml"

echo -e "${YELLOW}Aplicando Deployments...${NC}"
kubectl apply -f "$ROOT_DIR/k8s/locust/deployment.yaml"

echo -e "${YELLOW}Aplicando Service...${NC}"
kubectl apply -f "$ROOT_DIR/k8s/locust/service.yaml"

echo ""
echo -e "${GREEN}✓ Locust deployado com sucesso!${NC}"
echo ""

echo -e "${YELLOW}Aguardando pods ficarem prontos...${NC}"
kubectl wait --for=condition=ready pod -l app=locust -n fiapx --timeout=60s 2>/dev/null || true

echo ""
echo -e "${BLUE}Status dos pods:${NC}"
kubectl get pods -n fiapx -l app=locust

echo ""
echo -e "${BLUE}Para acessar a UI do Locust:${NC}"
echo -e "  kubectl port-forward -n fiapx service/locust-master 8089:8089"
echo ""
echo -e "  Depois acesse: ${GREEN}http://localhost:8089${NC}"
echo ""

