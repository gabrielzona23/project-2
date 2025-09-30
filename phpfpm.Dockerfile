FROM php:8.4-fpm-alpine

COPY --from=mlocati/php-extension-installer /usr/bin/install-php-extensions /usr/local/bin/
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

RUN install-php-extensions pcntl sockets pdo_mysql opcache

WORKDIR /var/www

COPY . /var/www
COPY .env.example /var/www/.env

RUN chown -R www-data:www-data /var/www

USER www-data
RUN composer install --no-dev --optimize-autoloader

USER root

RUN chmod -R 775 /var/www/storage /var/www/bootstrap/cache

EXPOSE 9000

CMD ["php-fpm"]
