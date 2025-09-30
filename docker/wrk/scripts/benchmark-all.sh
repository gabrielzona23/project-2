#!/bin/bash

# Benchmark script for PHP runtimes - Project-2
set -e

RESULTS_DIR="/benchmark/results"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
REPORT_FILE="${RESULTS_DIR}/benchmark_${TIMESTAMP}.txt"

# Create results directory
mkdir -p "$RESULTS_DIR"

# Test configurations
DURATION="30s"
THREADS=4
CONNECTIONS=10

echo "=== PHP Runtime Performance Benchmark - Project-2 ===" | tee "$REPORT_FILE"
echo "Timestamp: $(date)" | tee -a "$REPORT_FILE"
echo "Duration: $DURATION, Threads: $THREADS, Connections: $CONNECTIONS" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Function to test a service
test_service() {
    local name=$1
    local url=$2
    local endpoint=${3:-""}
    
    echo "Testing $name ($url$endpoint)..." | tee -a "$REPORT_FILE"
    
    # Check if service is available
    if ! curl -s --max-time 5 "$url$endpoint" > /dev/null 2>&1; then
        echo "❌ $name is not available at $url$endpoint" | tee -a "$REPORT_FILE"
        echo "" | tee -a "$REPORT_FILE"
        return 1
    fi
    
    # Run wrk benchmark
    echo "Running wrk test..." | tee -a "$REPORT_FILE"
    wrk -t$THREADS -c$CONNECTIONS -d$DURATION --timeout 10s "$url$endpoint" >> "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    # Run Apache Bench for comparison
    echo "Running Apache Bench test (100 requests)..." | tee -a "$REPORT_FILE"
    ab -n 100 -c 10 "$url$endpoint" 2>/dev/null | grep -E "(Requests per second|Time per request|Failed requests)" >> "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
    
    echo "✅ $name test completed" | tee -a "$REPORT_FILE"
    echo "===========================================" | tee -a "$REPORT_FILE"
    echo "" | tee -a "$REPORT_FILE"
}

# Test all PHP runtimes
echo "🚀 Starting benchmark tests..." | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# PHP-FPM
test_service "PHP-FPM" "http://php_fpm_benchmark" "/"

# Swoole  
test_service "Swoole" "http://swoole_benchmark:8000" "/"

# FrankenPHP
test_service "FrankenPHP" "http://frankenphp_benchmark:8000" "/"

# Test API endpoints if available
echo "🔥 Testing API endpoints..." | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

test_service "PHP-FPM API" "http://php_fpm_benchmark" "/api/health"
test_service "Swoole API" "http://swoole_benchmark:8000" "/api/health"  
test_service "FrankenPHP API" "http://frankenphp_benchmark:8000" "/api/health"

echo "📊 Benchmark completed!" | tee -a "$REPORT_FILE"
echo "Results saved to: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

# Generate summary
echo "📈 PERFORMANCE SUMMARY" | tee -a "$REPORT_FILE"
echo "======================" | tee -a "$REPORT_FILE"
grep "Requests/sec" "$REPORT_FILE" | tee -a "$REPORT_FILE"

echo ""
echo "✅ Full benchmark report: $REPORT_FILE"