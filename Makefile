.PHONY: help build up down logs clean setup-laravel setup-database fix-permissions clear-cache benchmark benchmark-all test-endpoints status health

# Default target
help:
	@echo "Laravel PHP Runtime Benchmark - Available Commands:"
	@echo ""
	@echo "  setup          - Complete setup: build, start and populate database"
	@echo "  build          - Build all Docker containers"
	@echo "  up             - Start all services"
	@echo "  down           - Stop all services"
	@echo "  status         - Show status of all services and containers"
	@echo "  health         - Check health of all services"
	@echo "  logs           - Show logs for all services"
	@echo "  clean          - Clean temporary data and reset database"
	@echo "  setup-laravel  - Initialize Laravel in all runtimes"
	@echo "  setup-database - Initialize and populate database with init.sql"
	@echo "  fix-permissions- Fix storage permissions for all containers"
	@echo "  test-endpoints - Test all API endpoints"
	@echo "  benchmark      - Run complete benchmark suite"
	@echo "  results        - Show latest benchmark results"
	@echo ""

# Build all containers
build:
	@echo "Building all containers..."
	docker-compose build

# Start all services
up:
	@echo "Starting all services..."
	docker-compose up -d postgres redis
	@echo "Waiting for database and redis to be ready..."
	sleep 10
	docker-compose up -d swoole php-fpm frankenphp
	@echo "Waiting for PHP services to be ready..."
	sleep 15

# Stop all services
down:
	@echo "Stopping all services..."
	docker-compose down

# Show logs
logs:
	docker-compose logs -f

# Clean temporary data and reset database
clean:
	@echo "🧹 Cleaning temporary data..."
	@echo "Stopping services..."
	docker-compose down
	@echo "Cleaning Laravel caches..."
	docker-compose run --rm swoole php artisan cache:clear || true
	docker-compose run --rm swoole php artisan config:clear || true
	docker-compose run --rm swoole php artisan route:clear || true
	docker-compose run --rm swoole php artisan view:clear || true
	@echo "Resetting database..."
	docker-compose up -d postgres
	sleep 5
	docker-compose exec postgres psql -U laravel -d laravel_benchmark -c "DROP SCHEMA public CASCADE; CREATE SCHEMA public;" || true
	docker-compose down
	@echo "✅ Cleanup complete! (Docker images preserved for faster builds)"

# Complete setup with database population
setup: build up setup-laravel setup-database fix-permissions
	@echo "✅ Complete setup finished!"

# Setup Laravel for all runtimes
setup-laravel:
	@echo "🔧 Setting up Laravel..."
	@echo "Fixing git ownership..."
	docker-compose exec swoole git config --global --add safe.directory /var/www/html || true
	@echo "Installing dependencies..."
	docker-compose exec swoole composer install --no-dev --optimize-autoloader --ignore-platform-reqs
	@echo "Generating application key..."
	docker-compose exec swoole php artisan key:generate --force
	@echo "✅ Laravel setup complete!"

# Fix permissions for all containers
fix-permissions:
	@echo "🔧 Fixing storage permissions..."
	docker-compose exec swoole chmod -R 777 /var/www/html/storage
	docker-compose exec swoole mkdir -p /var/www/html/storage/framework/cache/data
	docker-compose exec swoole chown -R www-data:www-data /var/www/html/storage
	docker-compose exec php-fpm chmod -R 777 /var/www/html/storage
	docker-compose exec php-fpm mkdir -p /var/www/html/storage/framework/cache/data
	docker-compose exec php-fpm chown -R www-data:www-data /var/www/html/storage
	docker-compose exec frankenphp chmod -R 777 /app/storage
	docker-compose exec frankenphp mkdir -p /app/storage/framework/cache/data
	docker-compose exec frankenphp chown -R www-data:www-data /app/storage

# Clear all Laravel caches
clear-cache:
	@echo "🧹 Clearing Laravel caches..."
	docker-compose exec swoole php artisan route:clear || true
	docker-compose exec swoole php artisan config:clear || true
	docker-compose exec swoole php artisan view:clear || true
	docker-compose exec swoole php artisan cache:clear || true

# Database setup and population with init.sql
setup-database:
	@echo "🗄️  Setting up database..."
	@echo "Verifying database connection..."
	docker-compose exec postgres psql -U laravel -d laravel_benchmark -c "SELECT version();" || true
	@echo "Populating database with init.sql..."
	cat database/init.sql | docker-compose exec -T postgres psql -U laravel -d laravel_benchmark
	@echo "✅ Database setup complete!"

# Check status of all services
status:
	@echo "📊 Service Status:"
	@echo "===================="
	@echo ""
	@echo "🐳 Docker Containers:"
	@docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" --filter "name=project-2" || echo "No containers running"
	@echo ""
	@echo "🔍 Service Health:"
	@echo "PostgreSQL:" && docker-compose exec postgres pg_isready -U laravel 2>/dev/null && echo "✅ Ready" || echo "❌ Not ready"
	@echo "Redis:" && docker-compose exec redis redis-cli ping 2>/dev/null && echo "✅ Ready" || echo "❌ Not ready"
	@echo "Swoole:" && curl -s http://localhost:8001/api/health >/dev/null 2>&1 && echo "✅ Ready" || echo "❌ Not ready"
	@echo "PHP-FPM:" && curl -s http://localhost:8002/api/health >/dev/null 2>&1 && echo "✅ Ready" || echo "❌ Not ready"
	@echo "FrankenPHP:" && curl -s http://localhost:8003/api/health >/dev/null 2>&1 && echo "✅ Ready" || echo "❌ Not ready"

# Check health of all services
health:
	@echo ""
	@echo "🏥 SERVICE HEALTH CHECK"
	@echo "======================"
	@echo ""
	@echo "📊 Infrastructure Services:"
	@echo -n "  🐘 PostgreSQL 17:    " && (docker-compose exec postgres pg_isready -U laravel >/dev/null 2>&1 && echo "✅ Ready (Connected)" || echo "❌ Not ready")
	@echo -n "  🔴 Redis 7:          " && (docker-compose exec redis redis-cli ping >/dev/null 2>&1 && echo "✅ Ready (PONG)" || echo "❌ Not ready")
	@echo ""
	@echo "🚀 PHP Runtime Services:"
	@echo -n "  ⚡ Swoole (8001):    " && (curl -s http://localhost:8001/api/health >/dev/null 2>&1 && echo "✅ Ready (HTTP 200)" || echo "❌ Not ready")
	@echo -n "  � PHP-FPM (8002):   " && (curl -s http://localhost:8002/api/health >/dev/null 2>&1 && echo "✅ Ready (HTTP 200)" || echo "❌ Not ready")
	@echo -n "  🦆 FrankenPHP (8003): " && (curl -s http://localhost:8003/api/health >/dev/null 2>&1 && echo "✅ Ready (HTTP 200)" || echo "❌ Not ready")
	@echo ""
	@echo "📋 Quick Summary:"
	@total=0; ready=0; \
	docker-compose exec postgres pg_isready -U laravel >/dev/null 2>&1 && ready=$$((ready + 1)); total=$$((total + 1)); \
	docker-compose exec redis redis-cli ping >/dev/null 2>&1 && ready=$$((ready + 1)); total=$$((total + 1)); \
	curl -s http://localhost:8001/api/health >/dev/null 2>&1 && ready=$$((ready + 1)); total=$$((total + 1)); \
	curl -s http://localhost:8002/api/health >/dev/null 2>&1 && ready=$$((ready + 1)); total=$$((total + 1)); \
	curl -s http://localhost:8003/api/health >/dev/null 2>&1 && ready=$$((ready + 1)); total=$$((total + 1)); \
	echo "  Services Ready: $$ready/$$total"
	@echo ""
	@echo "💡 Tips:"
	@echo "  • Use 'make status' for detailed container info"
	@echo "  • Use 'make test-endpoints' for full endpoint testing"
	@echo "  • Use 'make benchmark-quick' for performance check"
	@echo ""

# Run individual benchmarks
benchmark:
	@echo "Running endpoint detailed benchmark with k6..."
	docker run --rm -i --network host grafana/k6 run - < benchmark/k6-endpoint-detailed.js

# Run complete benchmark suite
benchmark-all:
	@echo "Running complete benchmark suite with k6..."
	@mkdir -p results
	docker run --rm -i --network host grafana/k6 run - < benchmark/k6-final-complete.js

# Show results
results:
	@echo "Latest benchmark results:"
	@ls -la results/ | tail -10

# Quick test all endpoints
test-endpoints:
	@echo "Testing all endpoints..."
	@echo "Swoole (port 8001):"
	@for endpoint in health health-check database cache file-read file-write api-external; do \
		echo -n "  /api/$$endpoint: "; \
		curl -s -o /dev/null -w "%{http_code}" http://localhost:8001/api/$$endpoint && echo " OK" || echo " FAILED"; \
	done
	@echo ""
	@echo "PHP-FPM (port 8002):"
	@for endpoint in health health-check database cache file-read file-write api-external; do \
		echo -n "  /api/$$endpoint: "; \
		curl -s -o /dev/null -w "%{http_code}" http://localhost:8002/api/$$endpoint && echo " OK" || echo " FAILED"; \
	done
	@echo ""
	@echo "FrankenPHP (port 8003):"
	@for endpoint in health health-check database cache file-read file-write api-external; do \
		echo -n "  /api/$$endpoint: "; \
		curl -s -o /dev/null -w "%{http_code}" http://localhost:8003/api/$$endpoint && echo " OK" || echo " FAILED"; \
	done
	@echo ""

# Benchmark commands
benchmark-complete: ## Run comprehensive benchmark on all runtimes
	@echo "🚀 Running comprehensive benchmarks with k6..."
	docker run --rm -i --network host grafana/k6 run - < benchmark/k6-final-complete.js
	@echo "📊 Results saved in ./results/"

benchmark-quick: ## Quick benchmark test
	@echo "⚡ Running quick benchmark tests..."
	@echo "Testing PHP-FPM..."
	@curl -s -w "Time: %{time_total}s, Status: %{http_code}\n" http://localhost:8002/ > /dev/null || echo "❌ PHP-FPM unavailable"
	@echo "Testing Swoole..."
	@curl -s -w "Time: %{time_total}s, Status: %{http_code}\n" http://localhost:8001/ > /dev/null || echo "❌ Swoole unavailable"
	@echo "Testing FrankenPHP..."
	@curl -s -w "Time: %{time_total}s, Status: %{http_code}\n" http://localhost:8003/ > /dev/null || echo "❌ FrankenPHP unavailable"

install: ## Install and setup complete project
	@echo "Setting up project-2..."
	@mkdir -p results
	@make build
	@make up
	@make setup-laravel
	@echo "✅ Project setup complete!"

rebuild: ## Rebuild and restart all services
	docker-compose down
	docker-compose build
	docker-compose up -d