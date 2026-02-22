#!/bin/bash

# ===========================================
# reload.sh - Recarrega config de um serviço
#   (reaplicar configmap + secret + rollout restart)
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Carrega .env
if [[ -f "$ROOT_DIR/.env" ]]; then
    export $(grep -v '^#' "$ROOT_DIR/.env" | xargs)
else
    echo -e "${RED}Erro: .env não encontrado em $ROOT_DIR${NC}"
    exit 1
fi

# Mapa de serviço -> nome do deployment
get_deployment_name() {
    case $1 in
        auth) echo "auth-service" ;;
        api) echo "api-service" ;;
        rabbitmq) echo "rabbitmq" ;;
        locust-auth) echo "locust-master" ;;
        locust-api) echo "locust-api-master" ;;
        *) echo "$1" ;;
    esac
}

show_help() {
    echo "Uso: $0 <serviço1,serviço2,...>"
    echo ""
    echo "Reaplicar configmap + secret e reinicia os pods de um serviço."
    echo "Use quando alterar uma env, configmap ou secret."
    echo ""
    echo "Serviços: auth, api, rabbitmq, locust-auth, locust-api"
    echo ""
    echo "Exemplos:"
    echo "  $0 auth            # Recarrega auth"
    echo "  $0 api             # Recarrega api"
    echo "  $0 auth,api        # Recarrega auth e api"
    echo "  $0 locust-auth     # Recarrega locust do auth"
    echo "  $0 locust-api      # Recarrega locust da api"
    exit 0
}

[[ -z "$1" || "$1" == "-h" || "$1" == "--help" ]] && show_help

reload_service() {
    local svc=$1
    local dir="$ROOT_DIR/k8s/$svc"
    local deployment=$(get_deployment_name "$svc")

    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}  ✗ Serviço '$svc' não encontrado${NC}"
        return 1
    fi

    echo -e "${YELLOW}[$svc] Recarregando configuração...${NC}"

    # Secret (com envsubst)
    if [[ -f "$dir/secret.yaml" ]]; then
        envsubst < "$dir/secret.yaml" | kubectl apply -f -
        echo -e "${GREEN}  ✓ secret atualizado${NC}"
    fi

    # ConfigMap
    if [[ -f "$dir/configmap.yaml" ]]; then
        kubectl apply -f "$dir/configmap.yaml"
        echo -e "${GREEN}  ✓ configmap atualizado${NC}"
    fi

    # Deployment (para garantir imagePullPolicy: Always)
    if [[ -f "$dir/deployment.yaml" ]]; then
        kubectl apply -f "$dir/deployment.yaml"
        echo -e "${GREEN}  ✓ deployment atualizado${NC}"
    fi

    # Rollout restart
    echo -e "${YELLOW}  Reiniciando pods...${NC}"
    kubectl rollout restart deployment/"$deployment" -n fiapx
    kubectl rollout status deployment/"$deployment" -n fiapx --timeout=120s

    # Se for locust-auth, reiniciar workers também
    if [[ "$svc" == "locust-auth" ]]; then
        kubectl rollout restart deployment/locust-worker -n fiapx
        kubectl rollout status deployment/locust-worker -n fiapx --timeout=120s
    fi

    # Se for locust-api, reiniciar workers também
    if [[ "$svc" == "locust-api" ]]; then
        kubectl rollout restart deployment/locust-api-worker -n fiapx
        kubectl rollout status deployment/locust-api-worker -n fiapx --timeout=120s
    fi

    echo -e "${GREEN}  ✓ $svc recarregado!${NC}"
    echo ""
}

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  ↻ RELOAD - Recarregando Configuração${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

IFS=',' read -ra SERVICES <<< "$1"
for svc in "${SERVICES[@]}"; do
    svc=$(echo "$svc" | xargs) # trim
    reload_service "$svc"
done

echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}  ✓ RELOAD completo!${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
kubectl get pods -n fiapx
echo ""

