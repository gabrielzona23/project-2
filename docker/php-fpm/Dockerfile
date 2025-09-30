FROM php:8.3-fpm-alpine3.19

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    supervisor \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    unzip \
    git \
    postgresql-client \
    postgresql-dev \
    icu-dev \
    oniguruma-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libwebp-dev

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install \
        pdo \
        pdo_pgsql \
        pgsql \
        gd \
        xml \
        mbstring \
        intl \
        opcache \
        pcntl \
        bcmath

# Install Redis extension
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis \
    && apk del .build-deps

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy configurations
COPY nginx.conf /etc/nginx/nginx.conf
COPY php.ini /usr/local/etc/php/php.ini
COPY php-fpm.conf /usr/local/etc/php-fpm.d/www.conf
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Create Laravel storage directories
RUN mkdir -p storage/logs storage/framework/cache storage/framework/sessions storage/framework/views \
    && chmod -R 777 storage \
    && mkdir -p /run/nginx \
    && mkdir -p /var/log/supervisor

# Copy optimized composer files and install dependencies
# Note: composer.json will be available via volume mount at runtime
# RUN composer install will be done via make setup-laravel

# Expose port
EXPOSE 80

# Start supervisor
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]