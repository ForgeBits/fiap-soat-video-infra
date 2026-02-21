#!/bin/bash

# Script para remover e reaplicar os secrets e configmaps de auth e api

set -e

# Carrega variáveis de ambiente do .env na raiz do projeto
ROOT_DIR="$(dirname "$0")/.."
export $(grep -v '^#' "$ROOT_DIR/.env" | xargs)

# Criar namespace se não existir
kubectl get namespace fiapx &>/dev/null || kubectl create namespace fiapx

echo "Removendo secret de auth..."
kubectl delete secret auth-secret -n fiapx --ignore-not-found

echo "Removendo secret de api..."
kubectl delete secret api-secret -n fiapx --ignore-not-found

echo "Removendo configmap de auth..."
kubectl delete configmap auth-configmap -n fiapx --ignore-not-found

echo "Removendo configmap de api..."
kubectl delete configmap api-configmap -n fiapx --ignore-not-found

echo "Aplicando secret de auth..."
envsubst < "$ROOT_DIR/k8s/auth/secret.yaml" | kubectl apply -f -

echo "Aplicando secret de api..."
envsubst < "$ROOT_DIR/k8s/api/secret.yaml" | kubectl apply -f -

echo "Aplicando configmap de auth..."
kubectl apply -f "$ROOT_DIR/k8s/auth/configmap.yaml"

echo "Aplicando configmap de api..."
kubectl apply -f "$ROOT_DIR/k8s/api/configmap.yaml"

echo "Secrets e configmaps aplicados com sucesso!"

