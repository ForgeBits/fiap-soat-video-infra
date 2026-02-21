#!/bin/bash

# ===========================================
# Script de Teste de Carga para o Serviço de Vídeos
# ===========================================

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Valores padrão
REQUESTS_PER_SECOND=${1:-5}
DURATION=${2:-10}
URL=${3:-"http://localhost:8082/videos/process"}
VIDEO_FILE=${4:-"/home/mt-dev/Videos/OBS/2026-01-08 20-46-44.mp4"}
FORMAT=${5:-"png"}
FPS=${6:-15}
TOKEN=${7:-"eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJjbGllbnRJZCI6ImM3MjhjYmY0LTQwODQtNDVlNi1hMWYyLWQ0NTNjZjZhYTIxNyIsImVtYWlsIjoiZnVsYW5vQGVtYWlsLmNvbSIsImF1dGhlbnRpY2F0ZWQiOnRydWUsImlhdCI6MTc3MTM4MTQ1NSwiZXhwIjoxNzcxOTg2MjU1fQ.50kA-D2Uh0kg23TLKG2sbPCmSs1ti34OAd3cINqkaUc"}

# Função de ajuda
show_help() {
    echo -e "${BLUE}==========================================${NC}"
    echo -e "${BLUE}  Script de Teste de Carga${NC}"
    echo -e "${BLUE}==========================================${NC}"
    echo ""
    echo "Uso: $0 [REQUESTS_PER_SECOND] [DURATION] [URL] [VIDEO_FILE] [FORMAT] [FPS] [TOKEN]"
    echo ""
    echo "Parâmetros:"
    echo "  REQUESTS_PER_SECOND  Número de requisições por segundo (padrão: 5)"
    echo "  DURATION             Duração do teste em segundos (padrão: 10)"
    echo "  URL                  URL do endpoint (padrão: http://localhost:8082/videos/process)"
    echo "  VIDEO_FILE           Caminho do arquivo de vídeo"
    echo "  FORMAT               Formato de saída (padrão: png)"
    echo "  FPS                  Frames por segundo (padrão: 15)"
    echo "  TOKEN                Token JWT de autenticação"
    echo ""
    echo "Exemplos:"
    echo "  $0 10 30                    # 10 req/s por 30 segundos"
    echo "  $0 5 60 http://api:8082     # 5 req/s por 60 segundos em URL customizada"
    echo ""
    exit 0
}

# Verificar ajuda
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    show_help
fi

# Verificar se o arquivo existe
if [[ ! -f "$VIDEO_FILE" ]]; then
    echo -e "${RED}Erro: Arquivo de vídeo não encontrado: $VIDEO_FILE${NC}"
    exit 1
fi

# Calcular intervalo entre requisições
INTERVAL=$(echo "scale=4; 1 / $REQUESTS_PER_SECOND" | bc)
TOTAL_REQUESTS=$((REQUESTS_PER_SECOND * DURATION))

echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Iniciando Teste de Carga${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "${YELLOW}Configuração:${NC}"
echo -e "  URL:                  $URL"
echo -e "  Requisições/segundo:  $REQUESTS_PER_SECOND"
echo -e "  Duração:              ${DURATION}s"
echo -e "  Total de requisições: $TOTAL_REQUESTS"
echo -e "  Intervalo:            ${INTERVAL}s"
echo -e "  Arquivo:              $VIDEO_FILE"
echo -e "  Formato:              $FORMAT"
echo -e "  FPS:                  $FPS"
echo ""

# Contadores
SUCCESS_COUNT=0
FAILURE_COUNT=0
START_TIME=$(date +%s.%N)

# Função para enviar requisição
send_request() {
    local REQUEST_NUM=$1
    local RESPONSE=$(curl --silent --write-out "HTTPSTATUS:%{http_code}" \
        --request POST \
        --url "$URL" \
        --header "Authorization: Bearer $TOKEN" \
        --header 'Content-Type: multipart/form-data' \
        --header 'User-Agent: load-test/1.0' \
        --form "files=@$VIDEO_FILE;type=video/mp4" \
        --form "format=$FORMAT" \
        --form "framesPerSecond=$FPS" \
        --max-time 30)

    local HTTP_STATUS=$(echo "$RESPONSE" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    local BODY=$(echo "$RESPONSE" | sed -e 's/HTTPSTATUS:.*//g')

    if [[ "$HTTP_STATUS" -ge 200 ]] && [[ "$HTTP_STATUS" -lt 300 ]]; then
        echo -e "${GREEN}[✓] Requisição #$REQUEST_NUM - Status: $HTTP_STATUS${NC}"
        return 0
    else
        # Extrair mensagem de erro do JSON (se existir)
        local ERROR_MSG=$(echo "$BODY" | grep -oP '"message"\s*:\s*"\K[^"]+' 2>/dev/null || echo "$BODY" | head -c 200)
        echo -e "${RED}[✗] Requisição #$REQUEST_NUM - Status: $HTTP_STATUS - Erro: $ERROR_MSG${NC}"
        return 1
    fi
}

# Loop principal de teste
echo -e "${YELLOW}Iniciando envio de requisições...${NC}"
echo ""

for ((i=1; i<=TOTAL_REQUESTS; i++)); do
    send_request $i &

    # Controlar o rate de requisições
    if (( i % REQUESTS_PER_SECOND == 0 )); then
        # Esperar que as requisições do segundo atual terminem
        wait
        echo -e "${BLUE}--- Segundo $((i / REQUESTS_PER_SECOND)) de $DURATION completo ---${NC}"
    else
        sleep $INTERVAL
    fi
done

# Esperar todas as requisições terminarem
wait

END_TIME=$(date +%s.%N)
ELAPSED=$(echo "$END_TIME - $START_TIME" | bc)

echo ""
echo -e "${BLUE}==========================================${NC}"
echo -e "${BLUE}  Teste de Carga Finalizado${NC}"
echo -e "${BLUE}==========================================${NC}"
echo ""
echo -e "${YELLOW}Resultados:${NC}"
echo -e "  Tempo total:          ${ELAPSED}s"
echo -e "  Total de requisições: $TOTAL_REQUESTS"
echo ""
echo -e "${GREEN}Teste concluído!${NC}"

