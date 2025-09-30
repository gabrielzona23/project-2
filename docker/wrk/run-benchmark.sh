#!/bin/bash

# Benchmark script for Laravel PHP runtimes
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="/results"
BENCHMARK_DIR="/benchmark"

# Test configurations
THREADS=12
CONNECTIONS=(100 200 400 800)
DURATION="30s"

# Runtime endpoints
RUNTIMES=(
    "swoole:8000"
    "php-fpm"
    "frankenphp:8000"
)

# Test endpoints
ENDPOINTS=(
    "health"
    "database"
    "cache" 
    "file-read"
    "file-write"
    "api-external"
)

echo "Starting Laravel PHP Runtime Benchmark - $TIMESTAMP"
echo "=============================================="

# Create results directory
mkdir -p "$RESULTS_DIR"

# Function to run single benchmark
run_benchmark() {
    local runtime=$1
    local endpoint=$2
    local connections=$3
    local output_file=$4
    
    echo "Testing $runtime - $endpoint with $connections connections..."
    
    wrk -t$THREADS -c$connections -d$DURATION --latency \
        "http://$runtime/api/$endpoint" \
        >> "$output_file" 2>&1
    
    echo "---" >> "$output_file"
}

# Function to test all endpoints for a runtime
test_runtime() {
    local runtime=$1
    local runtime_name=$(echo $runtime | cut -d: -f1)
    
    echo "Testing runtime: $runtime_name"
    echo "==============================="
    
    local output_file="$RESULTS_DIR/${runtime_name}-benchmark-$TIMESTAMP.txt"
    
    echo "Laravel PHP Runtime Benchmark - $runtime_name" > "$output_file"
    echo "Timestamp: $TIMESTAMP" >> "$output_file"
    echo "Threads: $THREADS" >> "$output_file"
    echo "Duration: $DURATION" >> "$output_file"
    echo "=========================================" >> "$output_file"
    echo "" >> "$output_file"
    
    # Test all endpoints with different connection counts
    for endpoint in "${ENDPOINTS[@]}"; do
        echo "Endpoint: $endpoint" >> "$output_file"
        echo "-------------------" >> "$output_file"
        
        for conn in "${CONNECTIONS[@]}"; do
            echo "Connections: $conn" >> "$output_file"
            run_benchmark "$runtime" "$endpoint" "$conn" "$output_file"
            echo "" >> "$output_file"
            sleep 2  # Brief pause between tests
        done
        
        echo "" >> "$output_file"
    done
    
    echo "Results saved to: $output_file"
}

# Health check before starting benchmarks
echo "Performing health checks..."
for runtime in "${RUNTIMES[@]}"; do
    runtime_name=$(echo $runtime | cut -d: -f1)
    echo -n "Checking $runtime_name: "
    
    if curl -s -f "http://$runtime/api/health" > /dev/null; then
        echo "OK"
    else
        echo "FAILED - Skipping $runtime_name"
        # Remove failed runtime from array
        RUNTIMES=("${RUNTIMES[@]/$runtime}")
    fi
done

echo ""

# Run benchmarks for all healthy runtimes
for runtime in "${RUNTIMES[@]}"; do
    test_runtime "$runtime"
    echo ""
done

# Generate summary report
echo "Generating summary report..."
python3 "$BENCHMARK_DIR/analyze.py" "$RESULTS_DIR" "$TIMESTAMP"

echo ""
echo "Benchmark completed successfully!"
echo "Results available in: $RESULTS_DIR"
echo "Summary report: $RESULTS_DIR/summary-$TIMESTAMP.json"