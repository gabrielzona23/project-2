#!/bin/bash

#!/bin/bash

# Script para monitorar recursos durante testes de carga
# Coleta dados de CPU, memória e rede dos containers

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="results/bateria_3_$TIMESTAMP"
MONITOR_INTERVAL=5  # segundos entre coletas

echo "🔍 Iniciando monitoramento de recursos..."
echo "📊 Intervalo: ${MONITOR_INTERVAL}s"
echo "📁 Diretório: $RESULTS_DIR"

# Criar diretório de resultados
mkdir -p "$RESULTS_DIR"

# Função para coletar stats dos containers
collect_container_stats() {
    local output_file="$1"
    
    while true; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # Coletar stats dos containers de benchmark
        docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}" \
            swoole_benchmark frankenphp_benchmark php_fpm_benchmark 2>/dev/null | \
            while IFS=$'\t' read -r container cpu mem net block; do
                if [[ "$container" != "CONTAINER" ]]; then
                    echo "$timestamp,$container,$cpu,$mem,$net,$block" >> "$output_file"
                fi
            done
        
        sleep $MONITOR_INTERVAL
    done
}

# Função para coletar stats do sistema
collect_system_stats() {
    local output_file="$1"
    
    while true; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # CPU usage
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
        
        # Memory usage
        mem_info=$(free -m | grep '^Mem:')
        mem_total=$(echo $mem_info | awk '{print $2}')
        mem_used=$(echo $mem_info | awk '{print $3}')
        mem_free=$(echo $mem_info | awk '{print $4}')
        mem_percent=$(echo "scale=2; $mem_used * 100 / $mem_total" | bc 2>/dev/null || echo "0")
        
        # Load average
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
        
        echo "$timestamp,$cpu_usage,$mem_total,$mem_used,$mem_free,$mem_percent,$load_avg" >> "$output_file"
        
        sleep $MONITOR_INTERVAL
    done
}

# Iniciar coleta em background
echo "🚀 Iniciando coleta de dados..."

# Headers dos arquivos CSV
echo "timestamp,container,cpu_percent,memory_usage,network_io,block_io" > "$RESULTS_DIR/container_stats.csv"
echo "timestamp,cpu_percent,mem_total_mb,mem_used_mb,mem_free_mb,mem_percent,load_avg" > "$RESULTS_DIR/system_stats.csv"

# Iniciar processos de coleta
collect_container_stats "$RESULTS_DIR/container_stats.csv" &
CONTAINER_PID=$!

collect_system_stats "$RESULTS_DIR/system_stats.csv" &
SYSTEM_PID=$!

echo "✅ Monitoramento iniciado!"
echo "📊 Container stats PID: $CONTAINER_PID"
echo "🖥️  System stats PID: $SYSTEM_PID"
echo ""
echo "Para parar o monitoramento, execute:"
echo "kill $CONTAINER_PID $SYSTEM_PID"
echo ""
echo "⏰ Pressione Ctrl+C para parar todos os processos"

# Função para cleanup
cleanup() {
    echo ""
    echo "🛑 Parando monitoramento..."
    kill $CONTAINER_PID $SYSTEM_PID 2>/dev/null
    wait
    echo "✅ Monitoramento finalizado!"
    echo "📁 Dados salvos em: $RESULTS_DIR"
    exit 0
}

# Trap para cleanup
trap cleanup SIGINT SIGTERM

# Manter script rodando
while true; do
    sleep 1
done
# Monitora CPU, memória e I/O dos containers

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="/home/incicle-zona/TCC/project-2/results/bateria_3_${TIMESTAMP}"
CONTAINERS=("swoole_benchmark" "frankenphp_benchmark" "php_fpm_benchmark")

echo "🔍 Iniciando monitoramento de recursos - Bateria 3"
echo "📊 Timestamp: ${TIMESTAMP}"
echo "📁 Logs salvos em: ${LOG_DIR}"

# Criar diretório de logs
mkdir -p "${LOG_DIR}"

# Função para monitorar um container específico
monitor_container() {
    local container=$1
    local output_file="${LOG_DIR}/${container}_resources.log"
    
    echo "🐳 Iniciando monitoramento do container: ${container}"
    echo "timestamp,cpu_percent,memory_usage,memory_limit,memory_percent,network_rx,network_tx,block_read,block_write" > "${output_file}"
    
    while true; do
        if docker ps --format "table {{.Names}}" | grep -q "^${container}$"; then
            # Usar docker stats com formato personalizado
            docker stats --no-stream --format "table {{.CPUPerc}},{{.MemUsage}},{{.MemPerc}},{{.NetIO}},{{.BlockIO}}" "${container}" 2>/dev/null | tail -n +2 | while IFS= read -r line; do
                if [[ -n "$line" ]]; then
                    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
                    # Processar linha e extrair métricas
                    cpu=$(echo "$line" | cut -d',' -f1 | sed 's/%//')
                    mem_usage=$(echo "$line" | cut -d',' -f2 | cut -d'/' -f1 | sed 's/[^0-9.]//g')
                    mem_limit=$(echo "$line" | cut -d',' -f2 | cut -d'/' -f2 | sed 's/[^0-9.]//g')
                    mem_percent=$(echo "$line" | cut -d',' -f3 | sed 's/%//')
                    net_io=$(echo "$line" | cut -d',' -f4)
                    net_rx=$(echo "$net_io" | cut -d'/' -f1 | sed 's/[^0-9.]//g')
                    net_tx=$(echo "$net_io" | cut -d'/' -f2 | sed 's/[^0-9.]//g')
                    block_io=$(echo "$line" | cut -d',' -f5)
                    block_read=$(echo "$block_io" | cut -d'/' -f1 | sed 's/[^0-9.]//g')
                    block_write=$(echo "$block_io" | cut -d'/' -f2 | sed 's/[^0-9.]//g')
                    
                    echo "${timestamp},${cpu},${mem_usage},${mem_limit},${mem_percent},${net_rx},${net_tx},${block_read},${block_write}" >> "${output_file}"
                fi
            done
        else
            echo "⚠️  Container ${container} não encontrado. Aguardando..."
        fi
        sleep 2
    done
}

# Função para monitorar sistema geral
monitor_system() {
    local output_file="${LOG_DIR}/system_resources.log"
    
    echo "💻 Iniciando monitoramento do sistema"
    echo "timestamp,cpu_usage,memory_total,memory_used,memory_free,load_avg_1m,load_avg_5m,load_avg_15m" > "${output_file}"
    
    while true; do
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        
        # CPU usage (overall)
        cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | sed 's/%us,//')
        
        # Memory info
        memory_info=$(free -m | grep '^Mem:')
        memory_total=$(echo "$memory_info" | awk '{print $2}')
        memory_used=$(echo "$memory_info" | awk '{print $3}')
        memory_free=$(echo "$memory_info" | awk '{print $4}')
        
        # Load average
        load_avg=$(uptime | awk -F'load average:' '{print $2}' | sed 's/^ *//')
        load_1m=$(echo "$load_avg" | cut -d',' -f1 | sed 's/^ *//')
        load_5m=$(echo "$load_avg" | cut -d',' -f2 | sed 's/^ *//')
        load_15m=$(echo "$load_avg" | cut -d',' -f3 | sed 's/^ *//')
        
        echo "${timestamp},${cpu_usage},${memory_total},${memory_used},${memory_free},${load_1m},${load_5m},${load_15m}" >> "${output_file}"
        
        sleep 5
    done
}

# Função para parar monitoramento
cleanup() {
    echo "🛑 Parando monitoramento de recursos..."
    pkill -f "monitor_container"
    pkill -f "monitor_system"
    
    # Gerar relatório final
    echo "📊 Gerando relatório de recursos..."
    echo "# Relatório de Recursos - Bateria 3" > "${LOG_DIR}/RESOURCE_SUMMARY.md"
    echo "**Timestamp:** ${TIMESTAMP}" >> "${LOG_DIR}/RESOURCE_SUMMARY.md"
    echo "**Duração:** 5.5 minutos" >> "${LOG_DIR}/RESOURCE_SUMMARY.md"
    echo "" >> "${LOG_DIR}/RESOURCE_SUMMARY.md"
    
    for container in "${CONTAINERS[@]}"; do
        if [[ -f "${LOG_DIR}/${container}_resources.log" ]]; then
            lines=$(wc -l < "${LOG_DIR}/${container}_resources.log")
            echo "- **${container}:** ${lines} registros coletados" >> "${LOG_DIR}/RESOURCE_SUMMARY.md"
        fi
    done
    
    echo "✅ Monitoramento finalizado. Logs em: ${LOG_DIR}"
    exit 0
}

# Capturar sinal de interrupção
trap cleanup SIGINT SIGTERM

# Iniciar monitoramento de containers em background
for container in "${CONTAINERS[@]}"; do
    monitor_container "$container" &
done

# Iniciar monitoramento do sistema
monitor_system &

# Aguardar sinal para parar
echo "🔄 Monitoramento ativo. Pressione Ctrl+C para parar."
echo "📁 Logs sendo salvos em tempo real em: ${LOG_DIR}"

# Loop infinito até receber sinal
while true; do
    sleep 10
    # Status check a cada 10 segundos
    echo "📊 $(date '+%H:%M:%S') - Monitoramento ativo..."
done