#!/bin/bash

# Script para remover todos os recursos K8s de um serviço (auth, api ou rabbitmq)

set -e

SERVICE=$1

if [[ -z "$SERVICE" ]]; then
  echo "Uso: ./commands/remove.sh <service>"
  echo "Serviços disponíveis: auth, api, rabbitmq, infrastructure"
  echo ""
  echo "Exemplo:"
  echo "  ./commands/remove.sh auth"
  echo "  ./commands/remove.sh api"
  echo "  ./commands/remove.sh rabbitmq"
  echo "  ./commands/remove.sh infrastructure"
  exit 1
fi

# Mapeia o nome do serviço para os nomes dos recursos
case $SERVICE in
  auth)
    DEPLOYMENT="auth-service"
    SERVICE_NAME="auth-service"
    CONFIGMAP="auth-configmap"
    SECRET="auth-secret"
    ;;
  api)
    DEPLOYMENT="api-service"
    SERVICE_NAME="api-service"
    CONFIGMAP="api-configmap"
    SECRET="api-secret"
    ;;
  rabbitmq)
    DEPLOYMENT="rabbitmq"
    SERVICE_NAME="rabbitmq"
    CONFIGMAP="rabbitmq-configmap"
    SECRET="rabbitmq-secret"
    ;;
  infrastructure)
    echo "========================================="
    echo "Removendo INFRASTRUCTURE..."
    echo "========================================="

    ROOT_DIR="$(dirname "$0")/.."

    echo "Removendo PostgreSQL Auth..."
    kubectl delete -f "$ROOT_DIR/k8s/infrastructure/postgres-auth.yaml" --ignore-not-found=true 2>/dev/null

    echo "Removendo PostgreSQL API..."
    kubectl delete -f "$ROOT_DIR/k8s/infrastructure/postgres-api.yaml" --ignore-not-found=true 2>/dev/null

    echo "Removendo Redis API..."
    kubectl delete -f "$ROOT_DIR/k8s/infrastructure/redis-api.yaml" --ignore-not-found=true 2>/dev/null

    echo "Removendo Elasticsearch..."
    kubectl delete -f "$ROOT_DIR/k8s/infrastructure/elasticsearch.yaml" --ignore-not-found=true 2>/dev/null

    echo "Removendo Kibana..."
    kubectl delete -f "$ROOT_DIR/k8s/infrastructure/kibana.yaml" --ignore-not-found=true 2>/dev/null

    echo "Removendo PVCs..."
    kubectl delete pvc postgres-auth-storage --ignore-not-found=true 2>/dev/null
    kubectl delete pvc postgres-api-storage --ignore-not-found=true 2>/dev/null
    kubectl delete pvc redis-api-storage --ignore-not-found=true 2>/dev/null
    kubectl delete pvc elastic-storage --ignore-not-found=true 2>/dev/null

    echo ""
    echo "Infrastructure removida com sucesso!"
    exit 0
    ;;
  *)
    echo "Erro: Serviço '$SERVICE' não reconhecido."
    echo "Serviços disponíveis: auth, api, rabbitmq, infrastructure"
    exit 1
    ;;
esac

echo "========================================="
echo "Removendo serviço $SERVICE..."
echo "========================================="

echo "Removendo service..."
kubectl delete service $SERVICE_NAME --ignore-not-found

echo "Removendo deployment..."
kubectl delete deployment $DEPLOYMENT --ignore-not-found

echo "Removendo configmap..."
kubectl delete configmap $CONFIGMAP --ignore-not-found

echo "Removendo secret..."
kubectl delete secret $SECRET --ignore-not-found

echo ""
echo "Serviço $SERVICE removido com sucesso!"

