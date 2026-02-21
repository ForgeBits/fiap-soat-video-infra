#!/bin/bash

# ============================================
# Deploy S3 Bucket - FIAP Video Worker
# ============================================

set -e

echo "========================================="
echo "  Deploy S3 Bucket: fiap-video-worker"
echo "========================================="
echo ""

# Verificar se AWS CLI está configurado
if ! aws sts get-caller-identity &> /dev/null; then
    echo "❌ Erro: AWS CLI não configurado"
    echo "Execute: aws configure"
    exit 1
fi

echo "✓ AWS CLI configurado"
echo ""

# Inicializar Terraform
echo "Inicializando Terraform..."
terraform init

echo ""
echo "Planejando mudanças..."
terraform plan -out=tfplan

echo ""
read -p "Deseja aplicar as mudanças? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    echo ""
    echo "Aplicando configuração..."
    terraform apply tfplan

    echo ""
    echo "========================================="
    echo "  ✓ Bucket S3 criado com sucesso!"
    echo "========================================="
    echo ""

    echo "Informações do bucket:"
    terraform output

    echo ""
    echo "Para usar na aplicação, configure:"
    echo "AWS_S3_BUCKET=fiap-video-worker"
    echo "AWS_REGION=$(terraform output -raw bucket_region)"
else
    echo "Deploy cancelado."
    rm -f tfplan
fi

