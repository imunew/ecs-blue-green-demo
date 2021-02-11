FROM php:7.4-fpm

# Install packages, extensions
RUN apt-get update \
  && apt-get install -y unzip zlib1g-dev libzip-dev \
  && docker-php-ext-install zip pdo_mysql opcache

# Composer install
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer
ENV COMPOSER_ALLOW_SUPERUSER 1
