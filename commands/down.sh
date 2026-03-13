#!/bin/bash

# ===========================================
# down.sh - Remove recursos do cluster
# ===========================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$SCRIPT_DIR/.."

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

remove_infrastructure() {
    echo -e "${YELLOW}[infra] Removendo infrastructure...${NC}"
    for f in postgres-auth postgres-auth-config postgres-api redis-api elasticsearch kibana; do
        [[ -f "$ROOT_DIR/k8s/infrastructure/$f.yaml" ]] && kubectl delete -f "$ROOT_DIR/k8s/infrastructure/$f.yaml" --ignore-not-found=true 2>/dev/null && echo -e "${GREEN}  ✓ $f removido${NC}"
    done

    echo -e "${YELLOW}  Removendo PVCs...${NC}"
    for pvc in postgres-api-storage redis-api-storage minio-storage; do
        kubectl delete pvc "$pvc" -n fiapx --ignore-not-found=true 2>/dev/null
    done
    echo -e "${GREEN}  ✓ PVCs removidos (elastic-storage preservado)${NC}"
    echo ""
}

remove_service() {
    local svc=$1
    local dir="$ROOT_DIR/k8s/$svc"

    if [[ ! -d "$dir" ]]; then
        echo -e "${RED}  ✗ Serviço '$svc' não encontrado em k8s/${NC}"
        return 1
    fi

    echo -e "${YELLOW}[$svc] Removendo...${NC}"

    # HPA
    [[ -f "$dir/hpa.yaml" ]] && kubectl delete -f "$dir/hpa.yaml" --ignore-not-found=true 2>/dev/null && echo -e "${GREEN}  ✓ hpa${NC}"

    # Deployment
    [[ -f "$dir/deployment.yaml" ]] && kubectl delete -f "$dir/deployment.yaml" --ignore-not-found=true 2>/dev/null && echo -e "${GREEN}  ✓ deployment${NC}"

    # Service
    [[ -f "$dir/service.yaml" ]] && kubectl delete -f "$dir/service.yaml" --ignore-not-found=true 2>/dev/null && echo -e "${GREEN}  ✓ service${NC}"

    # ConfigMap
    [[ -f "$dir/configmap.yaml" ]] && kubectl delete -f "$dir/configmap.yaml" --ignore-not-found=true 2>/dev/null && echo -e "${GREEN}  ✓ configmap${NC}"

    # Secret
    [[ -f "$dir/secret.yaml" ]] && kubectl delete -f "$dir/secret.yaml" --ignore-not-found=true 2>/dev/null && echo -e "${GREEN}  ✓ secret${NC}"

    echo ""
}

show_help() {
    echo "Uso: $0 [serviço1,serviço2,...]"
    echo ""
    echo "Sem argumentos: remove TUDO"
    echo ""
    echo "Serviços: infra, rabbitmq, auth, api, worker, locust-auth"
    echo ""
    echo "Exemplos:"
    echo "  $0                     # Remove tudo"
    echo "  $0 auth                # Remove só o auth"
    echo "  $0 auth,api            # Remove auth e api"
    echo "  $0 locust-auth         # Remove locust do auth"
    exit 0
}

[[ "$1" == "-h" || "$1" == "--help" ]] && show_help

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  ▼ DOWN - Removendo Recursos K8s${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

SERVICES_ARG="${1:-all}"

if [[ "$SERVICES_ARG" == "all" ]]; then
    remove_service locust-auth
    remove_service worker
    remove_service api
    remove_service auth
    remove_service rabbitmq
    remove_infrastructure
else
    IFS=',' read -ra SERVICES <<< "$SERVICES_ARG"
    for svc in "${SERVICES[@]}"; do
        svc=$(echo "$svc" | xargs) # trim
        if [[ "$svc" == "infra" || "$svc" == "infrastructure" ]]; then
            remove_infrastructure
        else
            remove_service "$svc"
        fi
    done
fi

echo -e "${BLUE}==========================================${NC}"
echo -e "${GREEN}  ✓ DOWN completo!${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "${YELLOW}Pods restantes:${NC}"
kubectl get pods -n fiapx 2>/dev/null || echo "  Nenhum pod encontrado"
echo ""

