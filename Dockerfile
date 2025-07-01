# Dockerfile for Laravel Blog Project (Laravel 11.x)

FROM serversideup/php:8.3-fpm-nginx AS base

# Switch to root user for system installations
USER root

# Install PHP extensions required by Laravel
RUN install-php-extensions \
    exif \
    bcmath \
    pdo_sqlite \
    fileinfo \
    tokenizer \
    curl \
    xml

# Install Node.js (v20.18.0) using node-build
ARG NODE_VERSION=20.18.0
ENV PATH=/usr/local/node/bin:$PATH
RUN curl -sL https://github.com/nodenv/node-build/archive/master.tar.gz | tar xz -C /tmp/ && \
    /tmp/node-build-master/bin/node-build "$NODE_VERSION" /usr/local/node && \
    corepack enable && \
    rm -rf /tmp/node-build-master

# Switch back to www-data user
USER www-data

# Set environment variables
FROM base
ENV SSL_MODE="off"
ENV AUTORUN_ENABLED="true"
ENV PHP_OPCACHE_ENABLE="1"
ENV HEALTHCHECK_PATH="/up"

# Copy Laravel source code to container
COPY --chown=www-data:www-data . /var/www/html

# Change working directory
WORKDIR /var/www/html

# Install PHP dependencies
RUN composer install --no-interaction --prefer-dist --optimize-autoloader

# Generate application key and install Laravel Horizon & Telescope
RUN php artisan key:generate && \
    php artisan horizon:install && \
    php artisan telescope:install && \
    php artisan storage:link

# Install JS dependencies and build production assets
RUN yarn install --immutable && \
    yarn build && \
    rm -rf node_modules

# Set correct permissions for Laravel directories
RUN chmod -R 775 storage bootstrap/cache database && \
    chown -R www-data:www-data storage bootstrap/cache database

# Expose ports for Nginx and healthcheck
EXPOSE 80 443 9000

# Final healthcheck definition (optional)
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s \
  CMD curl --fail http://localhost$HEALTHCHECK_PATH || exit 1

# Add custom entrypoint for SQLite + migrate
COPY entrypoint.sh /usr/local/bin/entrypoint.sh

# Switch to root temporarily to set permissions
USER root
RUN chmod +x /usr/local/bin/entrypoint.sh

# Back to safer default user
USER www-data

ENTRYPOINT ["entrypoint.sh"]
