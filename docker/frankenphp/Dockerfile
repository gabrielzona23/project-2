FROM dunglas/frankenphp:1-php8.3-alpine

# Install additional PHP extensions
RUN install-php-extensions \
    pdo_pgsql \
    pgsql \
    redis \
    opcache \
    intl \
    zip \
    bcmath \
    gd \
    exif \
    pcntl \
    sockets

# Install system dependencies
RUN apk add --no-cache \
    curl \
    git \
    unzip \
    supervisor

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /app

# Copy Caddyfile
COPY Caddyfile /etc/caddy/Caddyfile

# Copy PHP configuration
COPY php.ini /usr/local/etc/php/php.ini

# Copy supervisor configuration
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create Laravel storage directories
RUN mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views \
    && chmod -R 777 storage \
    && mkdir -p /var/log/supervisor

# Install Composer dependencies (will be overridden by volume mount)
# Note: composer install will be done via make setup-laravel

# Expose port
EXPOSE 8000

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]