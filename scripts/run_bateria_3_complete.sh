#!/bin/bash

# Script orquestrador para Bateria 3 - Teste Completo com Monitoramento de Recursos
# Executa teste K6 comprehensive e monitora recursos simultaneamente

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="/home/incicle-zona/TCC/project-2/results/bateria_3_${TIMESTAMP}"
PROJECT_DIR="/home/incicle-zona/TCC/project-2"

echo "🚀 BATERIA 3 - COMPREHENSIVE LOAD TESTING WITH RESOURCE MONITORING"
echo "═══════════════════════════════════════════════════════════════════"
echo "📊 Timestamp: ${TIMESTAMP}"
echo "📁 Resultados: ${LOG_DIR}"
echo "⏱️  Duração: 5.5 minutos"
echo "🎯 Foco: Todas as rotas + Monitoramento de recursos"
echo ""

# Verificar se containers estão rodando
echo "🔍 Verificando status dos containers..."
cd "${PROJECT_DIR}"
make status

# Criar diretório de resultados
mkdir -p "${LOG_DIR}"

# Função de cleanup
cleanup() {
    echo ""
    echo "🛑 Finalizando processos..."
    
    # Parar monitoramento
    if [[ -n "${MONITOR_PID}" ]]; then
        kill "${MONITOR_PID}" 2>/dev/null || true
        wait "${MONITOR_PID}" 2>/dev/null || true
    fi
    
    # Parar K6 se ainda estiver rodando
    pkill -f "k6-bateria-3-comprehensive" 2>/dev/null || true
    
    echo "✅ Cleanup concluído"
}

# Configurar trap para cleanup
trap cleanup SIGINT SIGTERM EXIT

# Iniciar monitoramento de recursos em background
echo "📊 Iniciando monitoramento de recursos..."
"${PROJECT_DIR}/scripts/monitor_resources.sh" &
MONITOR_PID=$!
sleep 3  # Aguardar inicialização do monitoramento

# Verificar se monitoramento iniciou
if ! kill -0 "${MONITOR_PID}" 2>/dev/null; then
    echo "❌ Erro ao iniciar monitoramento de recursos"
    exit 1
fi

echo "✅ Monitoramento ativo (PID: ${MONITOR_PID})"
echo ""

# Executar teste K6
echo "🚀 Iniciando K6 Comprehensive Test..."
echo "📋 Categorias testadas:"
echo "   - Static endpoints (20%)"
echo "   - Database operations (15%)"  
echo "   - Cache operations (15%)"
echo "   - File operations (10%)"
echo "   - CPU intensive (15%)"
echo "   - Memory tests (5%)"
echo "   - Mixed workload (10%)"
echo "   - Concurrent tests (5%)"
echo "   - Runtime info (5%)"
echo ""

cd "${PROJECT_DIR}"

# Executar K6 e salvar output
docker run --rm --network host \
  -v "$(pwd):/app" -w /app \
  -v "${LOG_DIR}:/results" \
  grafana/k6:latest run benchmark/k6-bateria-3-comprehensive.js \
  --out json=/results/k6-results.json \
  | tee "${LOG_DIR}/k6-output.txt"

K6_EXIT_CODE=$?

# Aguardar um pouco para capturar dados finais
echo "⏳ Aguardando coleta final de dados..."
sleep 10

# Parar monitoramento
echo "🛑 Parando monitoramento..."
kill "${MONITOR_PID}" 2>/dev/null || true
wait "${MONITOR_PID}" 2>/dev/null || true

# Gerar relatório consolidado
echo "📊 Gerando relatório consolidado..."

cat > "${LOG_DIR}/BATERIA_3_SUMMARY.md" << EOF
# 📊 Bateria 3 - Comprehensive Load Testing Results

**Data:** $(date '+%d/%m/%Y')  
**Horário:** $(date '+%H:%M:%S')  
**Duração:** 5.5 minutos  
**Status:** $([ $K6_EXIT_CODE -eq 0 ] && echo "✅ SUCESSO" || echo "❌ FALHAS DETECTADAS")  

## 🎯 Estratégia Executada

### Progressive Load Testing com TODAS as rotas

**6 Stages:**
- Stage 1: 0→10 VUs (60s) - Warm-up
- Stage 2: 10→25 VUs (60s) - Low load  
- Stage 3: 25→50 VUs (60s) - Medium load
- Stage 4: 50→100 VUs (60s) - High load
- Stage 5: 100→200 VUs (60s) - Stress test
- Stage 6: 200→0 VUs (30s) - Cool-down

### Categorias de Endpoints Testadas

| Categoria | Peso | Endpoints |
|-----------|------|-----------|
| **Static** | 20% | /api, /api/static, /api/health |
| **Database** | 15% | /api/database/*, /api/database/read, write, complex |
| **Cache** | 15% | /api/cache/*, /api/cache/read, write |
| **File** | 10% | /api/file-read, /api/file-write, /api/file-operations |
| **CPU** | 15% | /api/cpu-intensive, /api/json-encode, /api/json-decode |
| **Memory** | 5% | /api/memory-test |
| **Mixed** | 10% | /api/mixed-workload, /api/stress-test |
| **Concurrent** | 5% | /api/concurrent/light, medium, heavy |
| **Runtime** | 5% | /api/runtime-info |

## 📁 Arquivos Gerados

- \`k6-results.json\` - Dados brutos do K6
- \`k6-output.txt\` - Log completo da execução
- \`*_resources.log\` - Logs de recursos por container
- \`system_resources.log\` - Recursos do sistema
- \`RESOURCE_SUMMARY.md\` - Resumo de recursos

## 📊 Análise de Recursos

EOF

# Adicionar estatísticas básicas se arquivos existirem
for container in "swoole_benchmark" "frankenphp_benchmark" "php_fpm_benchmark"; do
    if [[ -f "${LOG_DIR}/${container}_resources.log" ]]; then
        lines=$(wc -l < "${LOG_DIR}/${container}_resources.log")
        echo "- **${container}:** ${lines} registros de recursos" >> "${LOG_DIR}/BATERIA_3_SUMMARY.md"
    fi
done

cat >> "${LOG_DIR}/BATERIA_3_SUMMARY.md" << EOF

## 🎓 Valor Acadêmico

Esta bateria coletou dados abrangentes sobre:

1. **Performance por tipo de operação** - Como cada runtime se comporta com diferentes workloads
2. **Padrões de uso de recursos** - CPU e memória correlacionados com carga e tipo de operação  
3. **Escalabilidade diferenciada** - Breaking points específicos por categoria de endpoint
4. **Eficiência operacional** - Relação performance/recursos para cada runtime

---

**🔬 Material científico completo para análise comparativa de runtimes PHP modernos!**
EOF

echo ""
echo "🎉 BATERIA 3 CONCLUÍDA COM SUCESSO!"
echo "═══════════════════════════════════════"
echo "📁 Resultados salvos em: ${LOG_DIR}"
echo "📊 Arquivos principais:"
echo "   - BATERIA_3_SUMMARY.md"
echo "   - k6-results.json"
echo "   - *_resources.log"
echo ""
echo "🎓 Dados coletados: Performance + Recursos + Todas as categorias de endpoint!"
echo "📈 Próximo passo: Análise detalhada dos dados para o TCC"