#!/bin/bash

# RELATÓRIO FINAL PROJECT-2 - BENCHMARKS COMPLETOS
DATE=$(date +%Y%m%d_%H%M%S)
REPORT_FILE="results/benchmark_complete_${DATE}.txt"

echo "🚀 RELATÓRIO COMPLETO DE BENCHMARK PROJECT-2" > $REPORT_FILE
echo "Data: $(date)" >> $REPORT_FILE
echo "=====================================================" >> $REPORT_FILE

echo -e "\n📊 1. SWOOLE PING API (15s, 4t, 50c)" >> $REPORT_FILE
docker run --rm --network host wrk-tool wrk -t4 -c50 -d15s --latency http://localhost:8001/api/ping >> $REPORT_FILE

echo -e "\n📊 2. FRANKENPHP PING API (15s, 4t, 50c)" >> $REPORT_FILE  
docker run --rm --network host wrk-tool wrk -t4 -c50 -d15s --latency http://localhost:8003/api/ping >> $REPORT_FILE

echo -e "\n📊 3. SWOOLE STATIC API (15s, 4t, 50c)" >> $REPORT_FILE
docker run --rm --network host wrk-tool wrk -t4 -c50 -d15s --latency http://localhost:8001/api/static >> $REPORT_FILE

echo -e "\n📊 4. FRANKENPHP STATIC API (15s, 4t, 50c)" >> $REPORT_FILE
docker run --rm --network host wrk-tool wrk -t4 -c50 -d15s --latency http://localhost:8003/api/static >> $REPORT_FILE

echo -e "\n📊 5. SWOOLE CPU TEST (10s, 2t, 20c)" >> $REPORT_FILE
docker run --rm --network host wrk-tool wrk -t2 -c20 -d10s --latency http://localhost:8001/api/cpu/1000 >> $REPORT_FILE

echo -e "\n📊 6. FRANKENPHP CPU TEST (10s, 2t, 20c)" >> $REPORT_FILE
docker run --rm --network host wrk-tool wrk -t2 -c20 -d10s --latency http://localhost:8003/api/cpu/1000 >> $REPORT_FILE

echo -e "\n=====================================================" >> $REPORT_FILE
echo "✅ Relatório salvo em: $REPORT_FILE" >> $REPORT_FILE
echo "🎯 PROJECT-2 MIGRATION: SUCCESS!" >> $REPORT_FILE

echo "✅ Relatório completo salvo em: $REPORT_FILE"