#!/bin/bash

# Laravel PHP Runtime Benchmark Setup Script

set -e

echo "🚀 Laravel PHP Runtime Benchmark Setup"
echo "======================================"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker first."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "❌ docker-compose is not installed."
    exit 1
fi

echo "✅ Docker is running"

# Build containers
echo ""
echo "🔨 Building containers..."
docker-compose build --no-cache

# Start database and redis first
echo ""
echo "🗄️ Starting database and Redis..."
docker-compose up -d postgres redis

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 15

# Check database connection
echo "🔍 Checking database connection..."
for i in {1..30}; do
    if docker-compose exec -T postgres pg_isready -U laravel -d laravel_benchmark > /dev/null 2>&1; then
        echo "✅ Database is ready"
        break
    fi
    
    if [ $i -eq 30 ]; then
        echo "❌ Database is not ready after 30 attempts"
        exit 1
    fi
    
    sleep 2
done

# Check Redis connection
echo "🔍 Checking Redis connection..."
for i in {1..10}; do
    if docker-compose exec -T redis redis-cli ping > /dev/null 2>&1; then
        echo "✅ Redis is ready"
        break
    fi
    
    if [ $i -eq 10 ]; then
        echo "❌ Redis is not ready after 10 attempts"
        exit 1
    fi
    
    sleep 2
done

# Start PHP services
echo ""
echo "🐘 Starting PHP services..."
docker-compose up -d swoole php-fpm frankenphp

# Wait for PHP services
echo "⏳ Waiting for PHP services to start..."
sleep 20

# Install Laravel dependencies
echo ""
echo "📦 Installing Laravel dependencies..."
docker-compose exec swoole composer install --no-dev --optimize-autoloader

# Generate application key
echo "🔑 Generating application key..."
docker-compose exec swoole php artisan key:generate --force

# Run migrations
echo "🗄️ Running database migrations..."
docker-compose exec swoole php artisan migrate --force

# Cache configuration
echo "⚡ Caching configuration..."
docker-compose exec swoole php artisan config:cache
docker-compose exec swoole php artisan route:cache

# Test health endpoints
echo ""
echo "🏥 Testing health endpoints..."

# Wait a bit more for services to be fully ready
sleep 10

for port in 8001 8002 8003; do
    runtime_name=""
    case $port in
        8001) runtime_name="Swoole" ;;
        8002) runtime_name="PHP-FPM" ;;
        8003) runtime_name="FrankenPHP" ;;
    esac
    
    echo -n "Testing $runtime_name (port $port): "
    
    for i in {1..10}; do
        if curl -s -f "http://localhost:$port/api/health" > /dev/null 2>&1; then
            echo "✅ OK"
            break
        fi
        
        if [ $i -eq 10 ]; then
            echo "❌ FAILED"
        fi
        
        sleep 3
    done
done

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "Available services:"
echo "  • Swoole:     http://localhost:8001"
echo "  • PHP-FPM:    http://localhost:8002"  
echo "  • FrankenPHP: http://localhost:8003"
echo "  • PostgreSQL: localhost:5432"
echo "  • Redis:      localhost:6379"
echo ""
echo "Next steps:"
echo "  • Run 'make test-health' to test all endpoints"
echo "  • Run 'make benchmark-all' to start benchmarking"
echo "  • Check 'results/' directory for benchmark outputs"