#!/bin/bash

# Bateria 2 - Escalabilidade Progressiva
# Data: 01/10/2025
# Objetivo: Análise de scalabilidade dos runtimes PHP

set -e

# Configuration
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
RESULTS_DIR="results/bateria_2_${TIMESTAMP}"
K6_SCRIPT="benchmark/k6-bateria-2-escalabilidade.js"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Iniciando Bateria 2 - Escalabilidade Progressiva${NC}"
echo -e "${BLUE}📅 Data: $(date)${NC}"
echo -e "${BLUE}🎯 Objetivo: Análise de scalabilidade 10→200 VUs${NC}"
echo

# Create results directory
mkdir -p "$RESULTS_DIR"

# Pre-flight checks
echo -e "${YELLOW}🔍 Verificando pré-requisitos...${NC}"

# Check if containers are running
if ! docker ps | grep -q "benchmark"; then
    echo -e "${RED}❌ Containers não estão rodando${NC}"
    echo -e "${YELLOW}💡 Execute: make up${NC}"
    exit 1
fi

# Check K6 availability
if ! command -v k6 &> /dev/null; then
    echo -e "${RED}❌ K6 não encontrado${NC}"
    echo -e "${YELLOW}💡 Instale K6 primeiro${NC}"
    exit 1
fi

# Health check endpoints
echo -e "${YELLOW}🏥 Verificando health dos runtimes...${NC}"
runtimes=("swoole:8001" "frankenphp:8003" "php_fpm:8002")
all_healthy=true

for runtime in "${runtimes[@]}"; do
    name=$(echo $runtime | cut -d':' -f1)
    port=$(echo $runtime | cut -d':' -f2)
    
    if curl -s -f "http://localhost:${port}/" > /dev/null; then
        echo -e "${GREEN}✅ ${name}${NC}"
    else
        echo -e "${RED}❌ ${name}${NC}"
        all_healthy=false
    fi
done

if [ "$all_healthy" = false ]; then
    echo -e "${RED}❌ Nem todos os runtimes estão saudáveis${NC}"
    exit 1
fi

echo

# Record system state before test
echo -e "${YELLOW}📊 Coletando estado inicial do sistema...${NC}"
echo "=== System State Before Test ===" > "$RESULTS_DIR/system_state_before.txt"
date >> "$RESULTS_DIR/system_state_before.txt"
echo >> "$RESULTS_DIR/system_state_before.txt"

echo "=== CPU Info ===" >> "$RESULTS_DIR/system_state_before.txt"
nproc >> "$RESULTS_DIR/system_state_before.txt"
echo >> "$RESULTS_DIR/system_state_before.txt"

echo "=== Memory Info ===" >> "$RESULTS_DIR/system_state_before.txt"
free -h >> "$RESULTS_DIR/system_state_before.txt"
echo >> "$RESULTS_DIR/system_state_before.txt"

echo "=== Docker Stats ===" >> "$RESULTS_DIR/system_state_before.txt"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker ps --filter "name=benchmark" --format "{{.Names}}") >> "$RESULTS_DIR/system_state_before.txt"

# Execute Bateria 2
echo -e "${GREEN}🚀 Executando Bateria 2 - Escalabilidade Progressiva${NC}"
echo -e "${BLUE}⏱️  Duração estimada: 6 minutos (330 segundos)${NC}"
echo -e "${BLUE}📈 Progressão: 10→25→50→100→200 VUs${NC}"
echo

# Start background monitoring
echo -e "${YELLOW}📊 Iniciando monitoramento de recursos...${NC}"
(
    while true; do
        echo "$(date): $(docker stats --no-stream --format "{{.Container}}: CPU {{.CPUPerc}} | MEM {{.MemUsage}}" $(docker ps --filter "name=benchmark" --format "{{.Names}}"))" >> "$RESULTS_DIR/resource_monitoring.log"
        sleep 5
    done
) &
MONITOR_PID=$!

# Execute K6 test
k6 run \
    --out json="$RESULTS_DIR/k6_results.json" \
    --summary-export="$RESULTS_DIR/k6_summary.json" \
    "$K6_SCRIPT" | tee "$RESULTS_DIR/k6_output.txt"

# Stop monitoring
kill $MONITOR_PID 2>/dev/null || true

# Record system state after test
echo -e "${YELLOW}📊 Coletando estado final do sistema...${NC}"
echo "=== System State After Test ===" > "$RESULTS_DIR/system_state_after.txt"
date >> "$RESULTS_DIR/system_state_after.txt"
echo >> "$RESULTS_DIR/system_state_after.txt"

echo "=== Memory Info ===" >> "$RESULTS_DIR/system_state_after.txt"
free -h >> "$RESULTS_DIR/system_state_after.txt"
echo >> "$RESULTS_DIR/system_state_after.txt"

echo "=== Docker Stats ===" >> "$RESULTS_DIR/system_state_after.txt"
docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" $(docker ps --filter "name=benchmark" --format "{{.Names}}") >> "$RESULTS_DIR/system_state_after.txt"

# Generate quick analysis
echo -e "${YELLOW}📊 Gerando análise preliminar...${NC}"
cat > "$RESULTS_DIR/README.md" << EOF
# Bateria 2 - Escalabilidade Progressiva

**Data:** $(date)  
**Duração:** 330 segundos (5.5 minutos)  
**Estratégia:** Load testing progressivo  

## 📊 Configuração do Teste

### Progressão de Carga

- **Estágio 1:** 10 VUs por 60s (warm-up)
- **Estágio 2:** 25 VUs por 60s  
- **Estágio 3:** 50 VUs por 60s
- **Estágio 4:** 100 VUs por 60s
- **Estágio 5:** 200 VUs por 60s (stress test)
- **Cool-down:** 0 VUs por 30s

### Endpoints Testados

- \`/\` - Página inicial
- \`/api/cache\` - Teste de cache Redis  
- \`/api/static\` - Conteúdo estático

### Runtimes Comparados

- **Swoole** (Laravel Octane) - Port 8001
- **FrankenPHP** - Port 8003
- **PHP-FPM + Nginx** - Port 8002

## 📁 Arquivos Gerados

- \`k6_results.json\` - Dados completos K6
- \`k6_summary.json\` - Resumo de métricas
- \`k6_output.txt\` - Log de execução
- \`resource_monitoring.log\` - Monitoramento de recursos
- \`system_state_before.txt\` - Estado inicial do sistema
- \`system_state_after.txt\` - Estado final do sistema

## 🎯 Objetivos de Análise

1. **Curvas de Escalabilidade** - P95 latency vs VUs
2. **Pontos de Saturação** - Onde cada runtime atinge limite
3. **Degradação de Performance** - Como performance diminui com carga
4. **Eficiência de Recursos** - CPU/Memory usage patterns
5. **Comparação de Estabilidade** - Variabilidade sob stress

## 📊 Próximos Passos

1. Análise detalhada dos dados JSON
2. Geração de gráficos comparativos
3. Identificação de breaking points
4. Correlação com uso de recursos
5. Documentação de findings acadêmicos

---

**Status:** ✅ Teste executado com sucesso  
**Dados:** Prontos para análise acadêmica
EOF

echo
echo -e "${GREEN}✅ Bateria 2 concluída com sucesso!${NC}"
echo -e "${BLUE}📁 Resultados salvos em: $RESULTS_DIR${NC}"
echo -e "${BLUE}📊 Próximo passo: Análise dos dados para identificar curvas de escalabilidade${NC}"
echo
echo -e "${YELLOW}💡 Para análise rápida, execute:${NC}"
echo -e "${YELLOW}   cat $RESULTS_DIR/k6_output.txt | grep -A 10 'checks'${NC}"