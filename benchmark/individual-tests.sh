#!/bin/bash

# Individual runtime benchmarks
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="../results"

echo "Running individual runtime tests - $TIMESTAMP"

# Test Swoole
echo "Testing Swoole runtime..."
wrk -t12 -c400 -d30s --latency http://swoole:8000/api/health > "$RESULTS_DIR/swoole-individual-$TIMESTAMP.txt"

# Test PHP-FPM  
echo "Testing PHP-FPM runtime..."
wrk -t12 -c400 -d30s --latency http://php-fpm/api/health > "$RESULTS_DIR/php-fpm-individual-$TIMESTAMP.txt"

# Test FrankenPHP
echo "Testing FrankenPHP runtime..."
wrk -t12 -c400 -d30s --latency http://frankenphp:8000/api/health > "$RESULTS_DIR/frankenphp-individual-$TIMESTAMP.txt"

echo "Individual tests completed. Results in $RESULTS_DIR"