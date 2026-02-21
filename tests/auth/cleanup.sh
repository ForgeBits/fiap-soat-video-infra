#!/bin/bash

# ===========================================
# Script de Limpeza - Dados de Teste Auth
# ===========================================

# Cores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Limpeza de Dados de Teste - Auth${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""

# Contar quantos usuários de teste existem
echo -e "${YELLOW}Verificando usuários de teste...${NC}"
COUNT=$(kubectl exec -it statefulset/postgres-auth -- psql -U auth_user -d auth_db -t -c "SELECT count(*) FROM users WHERE email LIKE '%@loadtest.com';" 2>/dev/null | tr -d ' \r\n')

if [[ -z "$COUNT" ]] || [[ "$COUNT" == "0" ]]; then
    echo -e "${GREEN}✓ Nenhum usuário de teste encontrado${NC}"
    exit 0
fi

echo -e "${YELLOW}Encontrados $COUNT usuários de teste${NC}"
echo ""

read -p "Deseja remover todos os usuários de teste? (yes/no): " confirm

if [[ "$confirm" != "yes" ]]; then
    echo -e "${YELLOW}Operação cancelada${NC}"
    exit 0
fi

echo ""
echo -e "${YELLOW}Removendo usuários de teste...${NC}"

kubectl exec -it statefulset/postgres-auth -- psql -U auth_user -d auth_db -c "DELETE FROM users WHERE email LIKE '%@loadtest.com';"

if [[ $? -eq 0 ]]; then
    echo ""
    echo -e "${GREEN}✓ $COUNT usuários de teste removidos com sucesso!${NC}"
else
    echo ""
    echo -e "${RED}✗ Erro ao remover usuários de teste${NC}"
    exit 1
fi

