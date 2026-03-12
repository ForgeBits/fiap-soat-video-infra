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
        *) echo "$1" ;;
    esac
}

show_help() {
    echo "Uso: $0 <serviço1,serviço2,...>"
    echo ""
    echo "Reaplicar configmap + secret e reinicia os pods de um serviço."
    echo "Use quando alterar uma env, configmap ou secret."
    echo ""
    echo "Serviços: auth, api, worker, rabbitmq, locust-auth"
    echo ""
    echo "Exemplos:"
    echo "  $0 auth            # Recarrega auth"
    echo "  $0 api             # Recarrega api"
    echo "  $0 worker          # Recarrega worker"
    echo "  $0 auth,api        # Recarrega auth e api"
    echo "  $0 locust-auth     # Recarrega locust do auth"
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
    kubectl rollout restart deployment/"$deployment" -n fiapx 2>/dev/null || echo -e "${YELLOW}  ! Deployment $deployment não encontrado ou em transição${NC}"
    kubectl rollout status deployment/"$deployment" -n fiapx --timeout=120s 2>/dev/null || true

    # Se for o auth ou api, rodar migrações após o restart
    if [[ "$svc" == "auth" ]]; then
        echo -e "${YELLOW}  Executando migrações Prisma (Auth)...${NC}"
        AUTH_POD=$(kubectl get pods -n fiapx -l app=auth-service -o jsonpath="{.items[0].metadata.name}")
        kubectl exec -n fiapx "$AUTH_POD" -- npx prisma migrate deploy || echo -e "${RED}  ✗ Falha ao executar migrações no Auth${NC}"
    elif [[ "$svc" == "api" ]]; then
        echo -e "${YELLOW}  Executando migrações Prisma (API)...${NC}"
        API_POD=$(kubectl get pods -n fiapx -l app=api-service -o jsonpath="{.items[0].metadata.name}")
        kubectl exec -n fiapx "$API_POD" -- npx prisma migrate deploy || echo -e "${RED}  ✗ Falha ao executar migrações na API${NC}"
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

