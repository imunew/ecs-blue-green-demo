FROM php:7.4-fpm

# Install packages, extensions
RUN apt-get update \
  && apt-get install -y unzip zlib1g-dev libzip-dev \
  && docker-php-ext-install zip pdo_mysql opcache

# Add sources, configs
ADD ./app /var/www/app
ADD ./aws/ecs/app-service/php-fpm/etc/zz-www.conf /usr/local/etc/php-fpm.d/zz-www.conf

WORKDIR /var/www/app
