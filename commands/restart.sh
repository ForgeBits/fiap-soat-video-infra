#!/bin/bash

# Script para reiniciar os pods de um serviço (rollout restart)

set -e

SERVICE=$1

if [[ -z "$SERVICE" ]]; then
  echo "Uso: ./commands/restart.sh <service>"
  echo "Serviços disponíveis: auth, api, rabbitmq, elasticsearch, kibana"
  echo ""
  echo "Exemplo:"
  echo "  ./commands/restart.sh auth"
  echo "  ./commands/restart.sh api"
  exit 1
fi

# Mapeia o nome do serviço para o nome do deployment
case $SERVICE in
  auth)
    DEPLOYMENT="auth-service"
    ;;
  api)
    DEPLOYMENT="api-service"
    ;;
  rabbitmq)
    DEPLOYMENT="rabbitmq"
    ;;
  elasticsearch)
    DEPLOYMENT="elasticsearch"
    ;;
  kibana)
    DEPLOYMENT="kibana"
    ;;
  *)
    echo "Erro: Serviço '$SERVICE' não reconhecido."
    echo "Serviços disponíveis: auth, api, rabbitmq, elasticsearch, kibana"
    exit 1
    ;;
esac

echo "========================================="
echo "Reiniciando serviço $SERVICE..."
echo "========================================="

kubectl rollout restart deployment/$DEPLOYMENT

echo ""
echo "Aguardando rollout..."
kubectl rollout status deployment/$DEPLOYMENT

echo ""
echo "Serviço $SERVICE reiniciado com sucesso!"

