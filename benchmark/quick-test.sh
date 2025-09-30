#!/bin/bash

# Quick test script for all endpoints
echo "Quick endpoint testing..."

RUNTIMES=(
    "swoole:8000"
    "php-fpm"
    "frankenphp:8000"
)

ENDPOINTS=(
    "health"
    "database"
    "cache"
    "file-read"
    "cpu-intensive"
)

for runtime in "${RUNTIMES[@]}"; do
    echo "Testing $runtime:"
    for endpoint in "${ENDPOINTS[@]}"; do
        echo -n "  $endpoint: "
        status=$(curl -s -o /dev/null -w "%{http_code}" "http://$runtime/api/$endpoint" --max-time 10)
        if [ "$status" = "200" ]; then
            echo "✓ OK"
        else
            echo "✗ FAILED ($status)"
        fi
    done
    echo ""
done