#!/bin/bash

# ===========================================
# up.sh - Sobe todo o cluster (ou serviços específicos)
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

# Funções auxiliares
apply_namespace() {
    kubectl apply -f "$ROOT_DIR/k8s/namespace.yaml" 2>/dev/null || \
    kubectl get namespace fiapx &>/dev/null || kubectl create namespace fiapx
    echo -e "${GREEN}  ✓ Namespace fiapx${NC}"
}

apply_infrastructure() {
    echo -e "${YELLOW}[infra] Aplicando infrastructure...${NC}"
    for f in postgres-auth postgres-auth-config postgres-api redis-api elasticsearch kibana; do
        [[ -f "$ROOT_DIR/k8s/infrastructure/$f.yaml" ]] && kubectl apply -f "$ROOT_DIR/k8s/infrastructure/$f.yaml" && echo -e "${GREEN}  ✓ $f${NC}"
    done
    echo ""
    echo -e "${YELLOW}  Aguardando databases...${NC}"
    kubectl wait --for=condition=ready pod -l app=postgres-auth -n fiapx --timeout=120s 2>/dev/null || true
    kubectl wait --for=condition=ready pod -l app=postgres-api -n fiapx --timeout=120s 2>/dev/null || true
    kubectl wait --for=condition=ready pod -l app=redis-api -n fiapx --timeout=60s 2>/dev/null || true
    echo ""
}

apply_service() {
    local svc=$1
    local dir="$ROOT_DIR/k8s/$svc"

    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}  ✗ Serviço '$svc' não encontrado em k8s/${NC}"
        return 1
    fi

    echo -e "${YELLOW}[$svc] Aplicando...${NC}"

    # Secret (com envsubst)
    [[ -f "$dir/secret.yaml" ]] && envsubst < "$dir/secret.yaml" | kubectl apply -f - && echo -e "${GREEN}  ✓ secret${NC}"

    # ConfigMap
    [[ -f "$dir/configmap.yaml" ]] && kubectl apply -f "$dir/configmap.yaml" && echo -e "${GREEN}  ✓ configmap${NC}"

    # Deployment
    [[ -f "$dir/deployment.yaml" ]] && kubectl apply -f "$dir/deployment.yaml" && echo -e "${GREEN}  ✓ deployment${NC}"

    # Service
    [[ -f "$dir/service.yaml" ]] && kubectl apply -f "$dir/service.yaml" && echo -e "${GREEN}  ✓ service${NC}"

    # HPA
    [[ -f "$dir/hpa.yaml" ]] && kubectl apply -f "$dir/hpa.yaml" && echo -e "${GREEN}  ✓ hpa${NC}"

    echo ""
}

show_help() {
    echo "Uso: $0 [serviço1,serviço2,...] [--locust-auth] [--locust-api] [--locust]"
    echo ""
    echo "Sem argumentos: sobe TUDO (infra + rabbitmq + auth + api)"
    echo ""
    echo "Serviços: infra, rabbitmq, auth, api, locust-auth, locust-api"
    echo ""
    echo "Exemplos:"
    echo "  $0                     # Sobe tudo"
    echo "  $0 auth                # Sobe só o auth"
    echo "  $0 auth,api            # Sobe auth e api"
    echo "  $0 infra,rabbitmq      # Sobe infra e rabbitmq"
    echo "  $0 --locust-auth       # Sobe tudo + locust do auth"
    echo "  $0 --locust-api        # Sobe tudo + locust da api"
    echo "  $0 --locust            # Sobe tudo + ambos locust"
    exit 0
}

[[ "$1" == "-h" || "$1" == "--help" ]] && show_help

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  ▲ UP - Subindo Recursos K8s${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

apply_namespace

# Se --locust-auth, --locust-api ou --locust foi passado em qualquer posição
DEPLOY_LOCUST_AUTH=false
DEPLOY_LOCUST_API=false
for arg in "$@"; do
    [[ "$arg" == "--locust-auth" ]] && DEPLOY_LOCUST_AUTH=true
    [[ "$arg" == "--locust-api" ]] && DEPLOY_LOCUST_API=true
    [[ "$arg" == "--locust" ]] && DEPLOY_LOCUST_AUTH=true && DEPLOY_LOCUST_API=true
done

# Se nenhum argumento (ou só --locust*), sobe tudo
SERVICES_ARG="${1:-all}"
[[ "$SERVICES_ARG" == "--locust"* ]] && SERVICES_ARG="all"

if [[ "$SERVICES_ARG" == "all" ]]; then
    apply_infrastructure
    apply_service rabbitmq
    echo -e "${YELLOW}  Aguardando RabbitMQ...${NC}"
    kubectl wait --for=condition=ready pod -l app=rabbitmq -n fiapx --timeout=90s 2>/dev/null || true
    echo ""
    apply_service auth
    apply_service api
else
    IFS=',' read -ra SERVICES <<< "$SERVICES_ARG"
    for svc in "${SERVICES[@]}"; do
        svc=$(echo "$svc" | xargs) # trim
        if [[ "$svc" == "infra" || "$svc" == "infrastructure" ]]; then
            apply_infrastructure
        else
            apply_service "$svc"
        fi
    done
fi

# Locust Auth
if [[ "$DEPLOY_LOCUST_AUTH" == true ]]; then
    apply_service locust-auth
fi

# Locust API
if [[ "$DEPLOY_LOCUST_API" == true ]]; then
    apply_service locust-api
fi

echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}  ✓ UP completo!${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
kubectl get pods -n fiapx
echo ""

