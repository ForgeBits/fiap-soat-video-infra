#!/bin/bash

# ===========================================
# Script para Remover TODOS os Recursos K8s
# ===========================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'


echo -e "${BLUE}=========================================${NC}"
echo -e "${BLUE}  Removendo TODOS os Recursos K8s${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""

# ===========================================
# REMOÇÃO
# ===========================================

# Remover Auth
echo -e "${YELLOW}Removendo serviço AUTH...${NC}"
kubectl delete deployment auth-service -n fiapx --ignore-not-found=true
kubectl delete service auth-service -n fiapx --ignore-not-found=true
kubectl delete configmap auth-config -n fiapx --ignore-not-found=true
kubectl delete secret auth-secret -n fiapx --ignore-not-found=true
echo -e "${GREEN}Auth removido!${NC}"
echo ""

# Remover API
echo -e "${YELLOW}Removendo serviço API...${NC}"
kubectl delete deployment api-service -n fiapx --ignore-not-found=true
kubectl delete service api-service -n fiapx --ignore-not-found=true
kubectl delete configmap api-config -n fiapx --ignore-not-found=true
kubectl delete secret api-secret -n fiapx --ignore-not-found=true
echo -e "${GREEN}API removido!${NC}"
echo ""

# Remover RabbitMQ
echo -e "${YELLOW}Removendo serviço RABBITMQ...${NC}"
kubectl delete deployment rabbitmq -n fiapx --ignore-not-found=true
kubectl delete service rabbitmq-service -n fiapx --ignore-not-found=true
kubectl delete configmap rabbitmq-config -n fiapx --ignore-not-found=true
kubectl delete secret rabbitmq-secret -n fiapx --ignore-not-found=true
echo -e "${GREEN}RabbitMQ removido!${NC}"
echo ""

# Remover Infrastructure (PostgreSQL, Redis, MinIO, Elasticsearch, Kibana)
echo -e "${YELLOW}Removendo INFRASTRUCTURE (PostgreSQL/Redis/MinIO/Elasticsearch/Kibana)...${NC}"
kubectl delete -f "$ROOT_DIR/k8s/infrastructure/postgres-auth.yaml" --ignore-not-found=true 2>/dev/null
kubectl delete -f "$ROOT_DIR/k8s/infrastructure/postgres-api.yaml" --ignore-not-found=true 2>/dev/null
kubectl delete -f "$ROOT_DIR/k8s/infrastructure/redis-api.yaml" --ignore-not-found=true 2>/dev/null
kubectl delete -f "$ROOT_DIR/k8s/infrastructure/minio.yaml" --ignore-not-found=true 2>/dev/null
kubectl delete job minio-setup-bucket --ignore-not-found=true 2>/dev/null
kubectl delete -f "$ROOT_DIR/k8s/infrastructure/elasticsearch.yaml" --ignore-not-found=true 2>/dev/null
kubectl delete -f "$ROOT_DIR/k8s/infrastructure/kibana.yaml" --ignore-not-found=true 2>/dev/null

# Remover PVCs
echo -e "${YELLOW}Removendo PVCs...${NC}"
kubectl delete pvc postgres-auth-storage -n fiapx --ignore-not-found=true 2>/dev/null
kubectl delete pvc postgres-api-storage -n fiapx --ignore-not-found=true 2>/dev/null
kubectl delete pvc redis-api-storage -n fiapx --ignore-not-found=true 2>/dev/null
kubectl delete pvc minio-storage -n fiapx --ignore-not-found=true 2>/dev/null
kubectl delete pvc elastic-storage -n fiapx --ignore-not-found=true 2>/dev/null

echo -e "${GREEN}Infrastructure removido!${NC}"
echo ""

echo -e "${BLUE}=========================================${NC}"
echo -e "${GREEN}  TODOS os recursos foram removidos!${NC}"
echo -e "${BLUE}=========================================${NC}"
echo ""
echo -e "${YELLOW}Para reaplicar a infraestrutura, use:${NC}"
echo -e "  ./commands/apply-infra.sh      # Infraestrutura (PostgreSQL, Redis, MinIO, Elasticsearch, Kibana)"
echo -e "  ./commands/apply.sh rabbitmq   # RabbitMQ"
echo -e "  ./commands/apply.sh auth       # Auth Service"
echo -e "  ./commands/apply.sh api        # API Service"
echo ""


