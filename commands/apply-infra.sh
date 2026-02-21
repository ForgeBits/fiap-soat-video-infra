#!/bin/bash

# Script para aplicar os recursos de infraestrutura K8s (elasticsearch, kibana)

set -e

# Carrega variáveis de ambiente do .env na raiz do projeto
ROOT_DIR="$(dirname "$0")/.."
export $(grep -v '^#' "$ROOT_DIR/.env" | xargs)

# Criar namespace se não existir
kubectl get namespace fiapx &>/dev/null || kubectl create namespace fiapx

INFRA_DIR="$ROOT_DIR/k8s/infrastructure"

echo "========================================="
echo "Aplicando infraestrutura..."
echo "========================================="

echo "Aplicando PostgreSQL Auth..."
kubectl apply -f "$INFRA_DIR/postgres-auth.yaml"

echo "Aplicando PostgreSQL API..."
kubectl apply -f "$INFRA_DIR/postgres-api.yaml"

echo "Aplicando Redis API..."
kubectl apply -f "$INFRA_DIR/redis-api.yaml"

echo "Aplicando Elasticsearch..."
kubectl apply -f "$INFRA_DIR/elasticsearch.yaml"

echo "Aplicando Kibana..."
kubectl apply -f "$INFRA_DIR/kibana.yaml"

echo ""
echo "Infraestrutura aplicada com sucesso!"

