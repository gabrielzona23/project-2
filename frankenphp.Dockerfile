FROM php:8.4-alpine

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

RUN install-php-extensions pcntl sockets

COPY . /var/www
COPY .env.example /var/www/.env

WORKDIR /var/www

RUN apk add --no-cache jq wget

ARG TARGETARCH
RUN case ${TARGETARCH} in \
        "amd64") FILE_ARCH="x86_64" ;; \
        "arm64") FILE_ARCH="aarch64" ;; \
    esac \
    && wget -O/usr/local/bin/frankenphp $(wget -qO- https://api.github.com/repos/dunglas/frankenphp/releases/latest | jq --arg a "frankenphp-linux-${FILE_ARCH}" -r '.assets[] | select(.name==$a) | .browser_download_url') \
    && chmod +x /usr/local/bin/frankenphp

RUN composer install --no-dev --optimize-autoloader

ENTRYPOINT ["php", "artisan", "octane:start", "--server=frankenphp", "--port=9804", "--workers=16", "--host=0.0.0.0"]