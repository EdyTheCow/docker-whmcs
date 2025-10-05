FROM php:8.3-fpm-bookworm

# Fetch the helper
ADD --chmod=0755 https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/

# Install all WHMCS required extensions
RUN set -eux; \
  install-php-extensions \
    bcmath gd gmp imap intl mbstring mysqli pdo_mysql soap zip

# ionCube
RUN set -eux; \
  arch="$(uname -m)"; case "$arch" in x86_64|amd64) a="x86-64";; aarch64|arm64) a="aarch64";; *) echo "Unsupported $arch"; exit 1;; esac; \
  curl -fsSL "https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_${a}.tar.gz" -o /tmp/ioncube.tar.gz; \
  tar -xzf /tmp/ioncube.tar.gz -C /tmp; \
  php_minor="$(php -r 'echo PHP_MAJOR_VERSION.".".PHP_MINOR_VERSION;')"; \
  ext_dir="$(php -r 'echo ini_get("extension_dir");')"; \
  cp "/tmp/ioncube/ioncube_loader_lin_${php_minor}.so" "${ext_dir}/"; \
  echo "zend_extension=ioncube_loader_lin_${php_minor}.so" > /usr/local/etc/php/conf.d/00-ioncube.ini; \
  rm -rf /tmp/ioncube*

COPY ./whmcs.ini /usr/local/etc/php/conf.d/zz-whmcs.ini
COPY ./xwhmcs.pool.conf /usr/local/etc/php-fpm.d/zz-whmcs.conf

USER www-data
WORKDIR /var/www
EXPOSE 9000
CMD ["php-fpm"]