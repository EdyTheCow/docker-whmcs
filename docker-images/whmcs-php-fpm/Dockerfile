FROM php:8.1-fpm
ENV DEBIAN_FRONTEND noninteractive

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
          libzip-dev \
          zip \
          curl \
          libmemcached-dev \
          libz-dev \
          libpq-dev \
          libjpeg-dev \
          libpng-dev \
          libfreetype6-dev \
          libmcrypt-dev; \
  rm -rf /var/lib/apt/lists/*

# Install additional PHP Packages and WHMCS Requirements
RUN docker-php-ext-configure zip && \
    docker-php-ext-install zip pdo_mysql mysqli

RUN docker-php-ext-configure gd \
  --prefix=/usr \
  --with-jpeg \
  --with-webp \
  --with-freetype; \
  docker-php-ext-install gd; \
  php -r 'var_dump(gd_info());'

RUN apt-get update -yqq && \
    apt-get install -y zlib1g-dev libicu-dev g++ && \
    docker-php-ext-configure intl && \
    docker-php-ext-install intl

RUN rm /etc/apt/preferences.d/no-debian-php && \
    apt-get -y install libxml2-dev php-soap && \
    docker-php-ext-install soap;

# Install the php ioncube loader (essential part to run WHMCS)
RUN cd /tmp \
    && curl -o ioncube.tar.gz https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz \
    && tar zxpf ioncube.tar.gz \
    && mv ioncube/ioncube_loader_lin_8.1.so /usr/local/lib/php/extensions/* \
    && rm -Rf ioncube.tar.gz ioncube \
    && echo "zend_extension=ioncube_loader_lin_8.1.so" > /usr/local/etc/php/conf.d/docker-php-ext-ioncube_loader.ini \
    && rm -rf /tmp/ioncube*

COPY ./whmcs.ini /usr/local/etc/php/conf.d
COPY ./xwhmcs.pool.conf /usr/local/etc/php-fpm.d/

USER root
RUN usermod -u 1000 www-data
WORKDIR /var/www

CMD ["php-fpm"]
EXPOSE 9000