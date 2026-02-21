#!/bin/bash

# ===========================================
# Script de Teste de Carga - Auth Register
# ===========================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Valores padrão
REQUESTS_PER_SECOND=${1:-1000}
DURATION=${2:-30}
URL=${3:-"http://localhost:8081/auth/register"}

# Função de ajuda
show_help() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  Script de Teste de Carga - Auth Register${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "Uso: $0 [REQUESTS_PER_SECOND] [DURATION] [URL]"
    echo ""
    echo "Parâmetros:"
    echo "  REQUESTS_PER_SECOND  Número de requisições por segundo (padrão: 1000)"
    echo "  DURATION             Duração do teste em segundos (padrão: 30)"
    echo "  URL                  URL do endpoint (padrão: http://localhost:8081/auth/register)"
    echo ""
    echo "Exemplos:"
    echo "  $0                              # 1000 req/s por 30 segundos"
    echo "  $0 500 60                       # 500 req/s por 60 segundos"
    echo "  $0 2000 10 http://auth:8081     # 2000 req/s por 10 segundos em URL customizada"
    echo ""
    exit 0
}

# Verificar ajuda
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
fi

# Calcular intervalo entre requisições (em segundos)
INTERVAL=$(echo "scale=6; 1 / $REQUESTS_PER_SECOND" | bc)
TOTAL_REQUESTS=$((REQUESTS_PER_SECOND * DURATION))

# Criar diretório temporário para os resultados
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Iniciando Teste de Carga - Auth Register${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "${YELLOW}Configuração:${NC}"
echo -e "  URL:                  $URL"
echo -e "  Requisições/segundo:  $REQUESTS_PER_SECOND"
echo -e "  Duração:              ${DURATION}s"
echo -e "  Total de requisições: $TOTAL_REQUESTS"
echo -e "  Intervalo:            ${INTERVAL}s"
echo ""

# Contadores
SUCCESS_COUNT=0
FAILURE_COUNT=0
START_TIME=$(date +%s.%N)

# Função para gerar email único
generate_email() {
    local TIMESTAMP=$(date +%s%N)
    local RANDOM_NUM=$RANDOM
    echo "user_${TIMESTAMP}_${RANDOM_NUM}@loadtest.com"
}

# Função para enviar requisição
send_request() {
    local REQUEST_NUM=$1
    local EMAIL=$(generate_email)

    local RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" \
        --request POST \
        --url "$URL" \
        --header 'Content-Type: application/json' \
        --header 'User-Agent: load-test/1.0' \
        --data "{
            \"email\": \"$EMAIL\",
            \"password\": \"Senha123\"
        }" \
        --max-time 10)

    local HTTP_STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    local BODY=$(echo "$RESPONSE" | sed -e 's/HTTPSTATUS:.*//g')

    # Salvar resultado em arquivo temporário
    echo "$HTTP_STATUS" >> "$TEMP_DIR/results_${REQUEST_NUM}.txt"

    if [[ "$HTTP_STATUS" -ge 200 ]] && [[ "$HTTP_STATUS" -lt 300 ]]; then
        echo -e "${GREEN}[✓] Requisição #$REQUEST_NUM - Status: $HTTP_STATUS - Email: $EMAIL${NC}"
        return 0
    else
        # Extrair mensagem de erro do JSON (se existir)
        local ERROR_MSG=$(echo "$BODY" | grep -oP '"message"\s*:\s*"\K[^"]+' 2>/dev/null || echo "$BODY" | head -c 100)
        echo -e "${RED}[✗] Requisição #$REQUEST_NUM - Status: $HTTP_STATUS - Erro: $ERROR_MSG${NC}"
        return 1
    fi
}

# Loop principal de teste
echo -e "${YELLOW}Iniciando envio de requisições...${NC}"
echo ""

REQUEST_COUNT=0
SECOND_COUNT=0
CURRENT_SECOND_START=$(date +%s.%N)

for ((i=1; i<=TOTAL_REQUESTS; i++)); do
    send_request $i &
    REQUEST_COUNT=$((REQUEST_COUNT + 1))

    # Controlar o rate de requisições por segundo
    if (( REQUEST_COUNT >= REQUESTS_PER_SECOND )); then
        # Esperar completar o segundo atual
        CURRENT_TIME=$(date +%s.%N)
        ELAPSED_IN_SECOND=$(echo "$CURRENT_TIME - $CURRENT_SECOND_START" | bc)
        REMAINING=$(echo "1 - $ELAPSED_IN_SECOND" | bc)

        if (( $(echo "$REMAINING > 0" | bc -l) )); then
            sleep $REMAINING
        fi

        # Aguardar requisições do segundo atual
        wait

        SECOND_COUNT=$((SECOND_COUNT + 1))
        echo -e "${BLUE}--- Segundo $SECOND_COUNT de $DURATION completo (${REQUEST_COUNT} requisições) ---${NC}"

        REQUEST_COUNT=0
        CURRENT_SECOND_START=$(date +%s.%N)
    else
        # Pequeno delay entre requisições no mesmo segundo
        if (( $(echo "$INTERVAL < 0.001" | bc -l) )); then
            # Se o intervalo for muito pequeno, não fazer sleep
            :
        else
            sleep $INTERVAL 2>/dev/null || true
        fi
    fi
done

# Esperar todas as requisições terminarem
wait

END_TIME=$(date +%s.%N)
ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)

# Contar sucessos e falhas
SUCCESS_COUNT=$(find "$TEMP_DIR" -name "results_*.txt" -exec grep -c "^2" {} \; 2>/dev/null | awk '{s+=$1} END {print s}')
FAILURE_COUNT=$(find "$TEMP_DIR" -name "results_*.txt" -exec grep -cv "^2" {} \; 2>/dev/null | awk '{s+=$1} END {print s}')

# Se contadores estiverem vazios, definir como 0
SUCCESS_COUNT=${SUCCESS_COUNT:-0}
FAILURE_COUNT=${FAILURE_COUNT:-0}

# Calcular taxa de sucesso
if [[ $TOTAL_REQUESTS -gt 0 ]]; then
    SUCCESS_RATE=$(echo "scale=2; ($SUCCESS_COUNT * 100) / $TOTAL_REQUESTS" | bc)
else
    SUCCESS_RATE=0
fi

# Calcular requisições por segundo real
ACTUAL_RPS=$(echo "scale=2; $TOTAL_REQUESTS / $ELAPSED" | bc)

echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Teste de Carga Finalizado${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "${YELLOW}Resultados:${NC}"
echo -e "  Tempo total:          ${ELAPSED}s"
echo -e "  Total de requisições: $TOTAL_REQUESTS"
echo -e "  Sucessos:             ${GREEN}$SUCCESS_COUNT${NC}"
echo -e "  Falhas:               ${RED}$FAILURE_COUNT${NC}"
echo -e "  Taxa de sucesso:      ${SUCCESS_RATE}%"
echo -e "  RPS real:             ${ACTUAL_RPS} req/s"
echo -e "  RPS esperado:         $REQUESTS_PER_SECOND req/s"
echo ""

if [[ $SUCCESS_COUNT -gt 0 ]]; then
    echo -e "${GREEN}✓ Teste concluído com sucesso!${NC}"
else
    echo -e "${RED}✗ Teste falhou - nenhuma requisição bem sucedida${NC}"
    exit 1
fi

