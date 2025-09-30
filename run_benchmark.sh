#!/bin/bash

OUTPUT_FILE="benchmark.txt"

echo "🚀 Starting Benchmarks - $(date)" > $OUTPUT_FILE

monitor_and_run_test() {
  local endpoint_name=$1
  local url=$2
  
  echo "Endpoint: $endpoint_name" >> $OUTPUT_FILE
  
  (
    echo -e "\n--- 🐳 Container Stats (during $endpoint_name test) ---\n" >> $OUTPUT_FILE
    docker stats --no-stream | head -n 1 >> $OUTPUT_FILE
    
    end=$((SECONDS+30))
    while [ $SECONDS -lt $end ]; do
        docker stats --no-stream | tail -n +2 >> $OUTPUT_FILE
        sleep 1
    done
  ) &
  MONITOR_PID=$!

  echo -e "\n--- 🔬 WRK Results ---\n" >> $OUTPUT_FILE
  wrk -t16 -c100 -d30s --latency $url >> $OUTPUT_FILE
  
  wait $MONITOR_PID
  
  echo -e "\n--------------------------------------------------\n" >> $OUTPUT_FILE
}

# --- Server on Port 9801 (OpenSwoole) ---
echo -e "\n\n--- 📊 Results for OpenSwoole (Port 9801) ---\n" >> $OUTPUT_FILE
monitor_and_run_test "/api/health-check" "http://127.0.0.1:9801/api/health-check"
monitor_and_run_test "/api/static" "http://127.0.0.1:9801/api/static"
monitor_and_run_test "/api/http-request" "http://127.0.0.1:9801/api/http-request"

# --- Server on Port 9802 (Swoole) ---
echo -e "\n\n--- 📊 Results for Swoole (Port 9802) ---\n" >> $OUTPUT_FILE
monitor_and_run_test "/api/health-check" "http://127.0.0.1:9802/api/health-check"
monitor_and_run_test "/api/static" "http://127.0.0.1:9802/api/static"
monitor_and_run_test "/api/http-request" "http://127.0.0.1:9802/api/http-request"

# --- Server on Port 9804 (FrankenPHP) ---
echo -e "\n\n--- 📊 Results for FrankenPHP (Port 9804) ---\n" >> $OUTPUT_FILE
monitor_and_run_test "/api/health-check" "http://127.0.0.1:9804/api/health-check"
monitor_and_run_test "/api/static" "http://127.0.0.1:9804/api/static"
monitor_and_run_test "/api/http-request" "http://127.0.0.1:9804/api/http-request"

# --- Server on Port 9805 (PHP-FPM) ---
echo -e "\n\n--- 📊 Results for PHP-FPM (Port 9805) ---\n" >> $OUTPUT_FILE
monitor_and_run_test "/api/health-check" "http://127.0.0.1:9805/api/health-check"
monitor_and_run_test "/api/static" "http://127.0.0.1:9805/api/static"
monitor_and_run_test "/api/http-request" "http://127.0.0.1:9805/api/http-request"

echo -e "\n\n✅ Benchmarks and stats collection completed! Results saved in $OUTPUT_FILE"