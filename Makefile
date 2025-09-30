.PHONY: help build up down logs clean setup-laravel setup-database fix-permissions clear-cache benchmark benchmark-all test-health test-endpoints

# Default target
help:
	@echo "Laravel PHP Runtime Benchmark - Available Commands:"
	@echo ""
	@echo "  setup          - Build and start all services"
	@echo "  build          - Build all Docker containers"
	@echo "  up             - Start all services"
	@echo "  down           - Stop all services"
	@echo "  logs           - Show logs for all services"
	@echo "  clean          - Stop services and remove volumes"
	@echo "  setup-laravel  - Initialize Laravel in all runtimes"
	@echo "  setup-database - Initialize and seed database"
	@echo "  fix-permissions- Fix storage permissions for all containers"
	@echo "  test-health    - Test health endpoints for all runtimes"
	@echo "  test-endpoints - Test all API endpoints"
	@echo "  benchmark      - Run individual benchmarks"
	@echo "  benchmark-all  - Run complete benchmark suite"
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

# Clean everything
clean:
	@echo "Cleaning up..."
	docker-compose down -v
	docker system prune -f

# Complete setup
setup: build up setup-laravel

# Setup Laravel for all runtimes
setup-laravel:
	@echo "Setting up Laravel..."
	@echo "Fixing git ownership..."
	docker-compose exec swoole git config --global --add safe.directory /var/www/html || true
	@echo "Installing dependencies..."
	docker-compose exec swoole composer install --no-dev --optimize-autoloader --ignore-platform-reqs
	@echo "Generating application key..."
	docker-compose exec swoole php artisan key:generate --force
	@echo "Verifying database initialization..."
	docker-compose exec postgres psql -U laravel -d laravel_benchmark -c "SELECT 'Database initialized successfully';" || true
	@echo "Running database migrations..."
	docker-compose exec swoole php artisan migrate --force || true
	@echo "Seeding database..."
	docker-compose exec swoole php artisan db:seed --force || true
	@echo "Fixing permissions..."
	@make fix-permissions
	@echo "Clearing caches..."
	@make clear-cache
	@echo "Laravel setup complete!"

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

# Database setup and initialization
setup-database:
	@echo "🗄️  Setting up database..."
	@echo "Verifying database connection..."
	docker-compose exec postgres psql -U laravel -d laravel_benchmark -c "SELECT version();" || true
	@echo "Running migrations..."
	docker-compose exec swoole php artisan migrate:fresh --force || true
	@echo "Seeding database..."
	docker-compose exec swoole php artisan db:seed --force || true
	@echo "Database setup complete!"

# Test health endpoints
test-health:
	@echo "Testing health endpoints..."
	@echo "Swoole (port 8001):"
	@curl -s http://localhost:8001/api/health || echo "Failed"
	@echo ""
	@echo "PHP-FPM (port 8002):"
	@curl -s http://localhost:8002/api/health || echo "Failed"
	@echo ""
	@echo "FrankenPHP (port 8003):"
	@curl -s http://localhost:8003/api/health || echo "Failed"
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

# Development helpers
dev-swoole:
	docker-compose exec swoole php artisan octane:start --host=0.0.0.0 --port=8000

dev-frankenphp:
	docker-compose exec frankenphp php artisan octane:start --server=frankenphp --host=0.0.0.0 --port=8000

restart-runtime:
	docker-compose restart swoole php-fpm frankenphp

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

health-check: ## Check health of all services
	@echo "🔍 Checking service health..."
	@echo "PostgreSQL 16:"
	@docker-compose exec postgres pg_isready -U laravel || echo "❌ PostgreSQL not ready"
	@echo "Redis 7:"
	@docker-compose exec redis redis-cli ping || echo "❌ Redis not ready"
	@echo "PHP-FPM (8002):"
	@curl -s http://localhost:8002/api/health || echo "❌ PHP-FPM not ready"
	@echo "Swoole (8001):"
	@curl -s http://localhost:8001/api/health || echo "❌ Swoole not ready"
	@echo "FrankenPHP (8003):"
	@curl -s http://localhost:8003/api/health || echo "❌ FrankenPHP not ready"

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