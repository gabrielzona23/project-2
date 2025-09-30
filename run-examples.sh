#!/bin/bash

echo "========================================================"
echo "     EXEMPLOS DE TESTES - PHP RUNTIMES BENCHMARK"
echo "========================================================"
echo "PHP Version: $(docker-compose exec php-fpm php --version | head -1)"
echo "========================================================"

echo ""
echo "1. TESTE SIMPLES DE RESPOSTA:"
echo "------------------------------"
curl -s http://localhost:8002/test.php
echo ""

echo ""
echo "2. TESTE DE BENCHMARK CPU:"
echo "--------------------------"
curl -s "http://localhost:8002/benchmark.php?test=cpu"
echo ""

echo ""
echo "3. TESTE DE BENCHMARK MEMÓRIA:"
echo "-------------------------------"
curl -s "http://localhost:8002/benchmark.php?test=memory"
echo ""

echo ""
echo "4. TESTE DE CARGA SIMPLES (100 requests, 5 concurrent):"
echo "---------------------------------------------------------"
docker-compose exec -T php-fpm ab -q -n 100 -c 5 http://localhost/test.php | grep -E "(Requests per second|Time per request|Failed requests)"

echo ""
echo "5. TESTE DE CARGA CPU (50 requests, 3 concurrent):"
echo "----------------------------------------------------"
docker-compose exec -T php-fpm ab -q -n 50 -c 3 "http://localhost/benchmark.php?test=cpu" | grep -E "(Requests per second|Time per request|Failed requests)"

echo ""
echo "========================================================"
echo "Testes concluídos! PHP-FPM está funcionando corretamente"
echo "========================================================"