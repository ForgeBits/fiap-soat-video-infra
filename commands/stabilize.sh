#!/bin/bash

# ===========================================
# stabilize.sh - Força estabilização dos pods
#   (deleta HPA, força replicas, recria HPA)
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Mapa de serviço -> deployment name
get_deployment_name() {
    case $1 in
        auth) echo "auth-service" ;;
        api) echo "api-service" ;;
        *) echo "$1" ;;
    esac
}

show_help() {
    echo "Uso: $0 <serviço> [replicas]"
    echo ""
    echo "Força estabilização dos pods quando o HPA demora a reduzir."
    echo "Remove HPA temporariamente, escala para o valor desejado e recria."
    echo ""
    echo "Argumentos:"
    echo "  serviço     Nome do serviço (auth, api)"
    echo "  replicas    Número de réplicas desejado (padrão: minReplicas do HPA)"
    echo ""
    echo "Exemplos:"
    echo "  $0 auth          # Estabiliza auth no minReplicas (3)"
    echo "  $0 auth 5        # Estabiliza auth em 5 pods"
    echo "  $0 api 1         # Estabiliza api em 1 pod"
    exit 0
}

[[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]] && show_help

SERVICE=$1
DEPLOYMENT=$(get_deployment_name "$SERVICE")
HPA_FILE="$ROOT_DIR/k8s/$SERVICE/hpa.yaml"

# Descobrir minReplicas do arquivo HPA (se existir)
DEFAULT_REPLICAS=1
if [[ -f "$HPA_FILE" ]]; then
    DEFAULT_REPLICAS=$(grep "minReplicas" "$HPA_FILE" | head -1 | awk '{print $2}')
    DEFAULT_REPLICAS=${DEFAULT_REPLICAS:-1}
fi

TARGET_REPLICAS=${2:-$DEFAULT_REPLICAS}

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  ⚖ STABILIZE - Estabilizando Pods${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Status antes
CURRENT=$(kubectl get pods -n fiapx -l app="$DEPLOYMENT" --no-headers 2>/dev/null | wc -l)
echo -e "${YELLOW}Status atual:${NC}"
echo "  Serviço:    $SERVICE"
echo "  Deployment: $DEPLOYMENT"
echo "  Pods atuais: $CURRENT"
echo "  Target:      $TARGET_REPLICAS"
echo ""

# 1. Deletar HPA
HPA_NAME="${DEPLOYMENT}-hpa"
if kubectl get hpa "$HPA_NAME" -n fiapx &>/dev/null; then
    echo -e "${YELLOW}1. Removendo HPA temporariamente...${NC}"
    kubectl delete hpa "$HPA_NAME" -n fiapx
    echo -e "${GREEN}  ✓ HPA removido${NC}"
else
    echo -e "${YELLOW}1. Nenhum HPA encontrado para $SERVICE, pulando...${NC}"
fi
echo ""

# 2. Forçar replicas
echo -e "${YELLOW}2. Escalando para $TARGET_REPLICAS pods...${NC}"
kubectl scale deployment "$DEPLOYMENT" -n fiapx --replicas="$TARGET_REPLICAS"
echo -e "${GREEN}  ✓ Scale aplicado${NC}"
echo ""

# 3. Aguardar limpeza
echo -e "${YELLOW}3. Aguardando pods estabilizarem...${NC}"
for i in {1..12}; do
    sleep 5
    CURRENT=$(kubectl get pods -n fiapx -l app="$DEPLOYMENT" --no-headers 2>/dev/null | wc -l | tr -d ' ')
    TERMINATING=$(kubectl get pods -n fiapx -l app="$DEPLOYMENT" --no-headers 2>/dev/null | grep -c "Terminating" 2>/dev/null || true)
    TERMINATING=$(echo "$TERMINATING" | head -1 | tr -d ' ')
    TERMINATING=${TERMINATING:-0}
    echo "   Pods: $CURRENT (Terminating: $TERMINATING)"
    if [[ "$CURRENT" -le "$TARGET_REPLICAS" ]] && [[ "$TERMINATING" -eq 0 ]]; then
        break
    fi
done
echo ""

# 4. Recriar HPA (se existir arquivo)
if [[ -f "$HPA_FILE" ]]; then
    echo -e "${YELLOW}4. Recriando HPA...${NC}"
    kubectl apply -f "$HPA_FILE"
    echo -e "${GREEN}  ✓ HPA recriado${NC}"
else
    echo -e "${YELLOW}4. Sem arquivo HPA para $SERVICE, pulando...${NC}"
fi
echo ""

# Status final
echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}  ✓ STABILIZE completo!${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

FINAL=$(kubectl get pods -n fiapx -l app="$DEPLOYMENT" --no-headers 2>/dev/null | wc -l)
RUNNING=$(kubectl get pods -n fiapx -l app="$DEPLOYMENT" --no-headers 2>/dev/null | grep -c "Running" || echo "0")

echo -e "${YELLOW}Resultado:${NC}"
echo "  Pods: $FINAL total, $RUNNING running"
echo ""

if [[ -f "$HPA_FILE" ]]; then
    kubectl get hpa -n fiapx "$HPA_NAME" 2>/dev/null
    echo ""
fi

kubectl get pods -n fiapx -l app="$DEPLOYMENT"
echo ""

