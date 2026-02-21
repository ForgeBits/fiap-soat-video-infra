#!/bin/bash

# Script para aplicar todos os recursos K8s de um serviço (auth ou api)

set -e

SERVICE=$1
SHIFT_ARGS=1

if [[ -z "$SERVICE" ]]; then
  echo "Uso: ./commands/apply.sh <service>"
  echo "Serviços disponíveis: auth, api, rabbitmq"
  echo ""
  echo "Exemplo:"
  echo "  ./commands/apply.sh auth"
  echo "  ./commands/apply.sh api"
  echo "  ./commands/apply.sh rabbitmq"
  exit 1
fi

# Carrega variáveis de ambiente do .env na raiz do projeto
ROOT_DIR="$(dirname "$0")/.."
export $(grep -v '^#' "$ROOT_DIR/.env" | xargs)

# Criar namespace se não existir
kubectl get namespace fiapx &>/dev/null || kubectl create namespace fiapx

SERVICE_DIR="$ROOT_DIR/k8s/$SERVICE"

if [[ ! -d "$SERVICE_DIR" ]]; then
  echo "Erro: Serviço '$SERVICE' não encontrado em k8s/"
  echo "Serviços disponíveis: auth, api, rabbitmq"
  exit 1
fi

echo "========================================="
echo "Aplicando serviço $SERVICE..."
echo "========================================="

echo "Aplicando secret..."
envsubst < "$SERVICE_DIR/secret.yaml" | kubectl apply -f -

echo "Aplicando configmap..."
kubectl apply -f "$SERVICE_DIR/configmap.yaml"

echo "Aplicando deployment..."
kubectl apply -f "$SERVICE_DIR/deployment.yaml"

echo "Aplicando service..."
kubectl apply -f "$SERVICE_DIR/service.yaml"

echo ""
echo "Serviço $SERVICE aplicado com sucesso!"

