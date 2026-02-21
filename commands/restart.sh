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

# Aplicar deployment para garantir imagePullPolicy: Always
echo "Aplicando deployment atualizado..."
DEPLOYMENT_FILE="k8s/$SERVICE/deployment.yaml"

if [[ -f "$DEPLOYMENT_FILE" ]]; then
  kubectl apply -f "$DEPLOYMENT_FILE"
  echo "✓ Deployment aplicado"
else
  echo "⚠ Arquivo de deployment não encontrado: $DEPLOYMENT_FILE"
  echo "Continuando com rollout restart..."
fi

echo ""
echo "Fazendo rollout restart..."
kubectl rollout restart deployment/$DEPLOYMENT -n fiapx

echo ""
echo "Aguardando rollout..."
kubectl rollout status deployment/$DEPLOYMENT -n fiapx

echo ""
echo "✓ Serviço $SERVICE reiniciado com sucesso!"
echo ""
echo "Verificando pods:"
kubectl get pods -n fiapx -l app=$DEPLOYMENT | head -5

