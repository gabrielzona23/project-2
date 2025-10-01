#!/bin/bash

# Script orquestrador para Bateria 3 - Teste completo com monitoramento
# Executa teste K6 + monitoramento de recursos simultaneamente

set -e

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="results/bateria_3_$TIMESTAMP"

echo "🚀 ===== BATERIA 3 - TESTE COMPLETO ====="
echo "📅 Data: $(date)"
echo "⏰ Timestamp: $TIMESTAMP"
echo "📁 Resultados: $RESULTS_DIR"
echo ""

# Criar diretório de resultados
mkdir -p "$RESULTS_DIR"

# Verificar se containers estão rodando
echo "🔍 Verificando containers..."
if ! docker ps | grep -q "swoole_benchmark"; then
    echo "❌ Container swoole_benchmark não está rodando"
    echo "Execute: make up"
    exit 1
fi

if ! docker ps | grep -q "frankenphp_benchmark"; then
    echo "❌ Container frankenphp_benchmark não está rodando"  
    echo "Execute: make up"
    exit 1
fi

if ! docker ps | grep -q "php_fpm_benchmark"; then
    echo "❌ Container php_fpm_benchmark não está rodando"
    echo "Execute: make up"
    exit 1
fi

echo "✅ Todos os containers estão rodando"
echo ""

# Verificar health dos serviços
echo "🏥 Verificando health dos serviços..."
for runtime in "swoole:8001" "frankenphp:8003" "php_fpm:8002"; do
    name=$(echo $runtime | cut -d: -f1)
    port=$(echo $runtime | cut -d: -f2)
    
    if curl -s "http://localhost:$port/api/health" > /dev/null; then
        echo "✅ $name: Healthy"
    else
        echo "❌ $name: Not healthy"
        echo "Aguardando 5 segundos..."
        sleep 5
    fi
done
echo ""

# Função para cleanup
cleanup() {
    echo ""
    echo "🛑 Interrompendo testes..."
    
    # Matar processos de monitoramento
    if [[ -n "$MONITOR_PID" ]]; then
        echo "🔍 Parando monitoramento..."
        kill $MONITOR_PID 2>/dev/null || true
        wait $MONITOR_PID 2>/dev/null || true
    fi
    
    # Matar processo K6
    if [[ -n "$K6_PID" ]]; then
        echo "📊 Parando teste K6..."
        kill $K6_PID 2>/dev/null || true
        wait $K6_PID 2>/dev/null || true
    fi
    
    echo "✅ Cleanup concluído"
    echo "📁 Resultados salvos em: $RESULTS_DIR"
    exit 0
}

# Configurar trap para cleanup
trap cleanup SIGINT SIGTERM

# Iniciar monitoramento de recursos em background
echo "🔍 Iniciando monitoramento de recursos..."
export RESULTS_DIR="$RESULTS_DIR"
./scripts/monitor_resources.sh &
MONITOR_PID=$!
echo "📊 Monitoramento PID: $MONITOR_PID"
echo ""

# Aguardar alguns segundos para monitoramento inicializar
sleep 3

# Executar teste K6
echo "🚀 Iniciando teste K6..."
echo "⏱️  Duração estimada: 5.5 minutos"
echo "📈 Estágios: 10→25→50→100→200→0 VUs"
echo ""

# Executar K6 e capturar PID
docker run --rm --network host \
    -v $(pwd):/app \
    -w /app \
    grafana/k6:latest run benchmark/k6-bateria-3-completo.js \
    > "$RESULTS_DIR/k6_output.txt" 2>&1 &
K6_PID=$!

echo "📊 Teste K6 PID: $K6_PID"
echo ""
echo "⏳ Aguardando conclusão do teste..."
echo "   (Pressione Ctrl+C para interromper)"
echo ""

# Aguardar conclusão do K6
wait $K6_PID
K6_EXIT_CODE=$?

echo ""
if [[ $K6_EXIT_CODE -eq 0 ]]; then
    echo "✅ Teste K6 concluído com sucesso!"
else
    echo "⚠️ Teste K6 finalizado com código: $K6_EXIT_CODE"
fi

# Parar monitoramento
echo "🛑 Parando monitoramento..."
kill $MONITOR_PID 2>/dev/null || true
wait $MONITOR_PID 2>/dev/null || true

# Gerar resumo dos resultados
echo ""
echo "📋 ===== RESUMO DOS RESULTADOS ====="
echo "📁 Diretório: $RESULTS_DIR"
echo "📊 Arquivos gerados:"

if [[ -f "$RESULTS_DIR/k6_output.txt" ]]; then
    echo "  ✅ k6_output.txt - Resultados do teste K6"
    lines=$(wc -l < "$RESULTS_DIR/k6_output.txt")
    echo "     📄 $lines linhas de output"
fi

if [[ -f "$RESULTS_DIR/container_stats.csv" ]]; then
    echo "  ✅ container_stats.csv - Estatísticas dos containers"
    lines=$(wc -l < "$RESULTS_DIR/container_stats.csv")
    echo "     📊 $((lines-1)) amostras coletadas"
fi

if [[ -f "$RESULTS_DIR/system_stats.csv" ]]; then
    echo "  ✅ system_stats.csv - Estatísticas do sistema"
    lines=$(wc -l < "$RESULTS_DIR/system_stats.csv")
    echo "     💻 $((lines-1)) amostras coletadas"
fi

echo ""
echo "🎯 Para análise detalhada:"
echo "   📊 cat $RESULTS_DIR/k6_output.txt | tail -50"
echo "   📈 head $RESULTS_DIR/container_stats.csv"
echo "   💻 head $RESULTS_DIR/system_stats.csv"
echo ""
echo "🎓 Bateria 3 completa - Dados prontos para análise acadêmica!"