#!/bin/sh
set -e

if [ ! -d vendor ]; then
  echo "📁 Membuat folder vendor/"
  mkdir vendor
fi
echo "📁 Melewati chmod vendor/, bind mount tidak bisa dimodifikasi dari container"

echo "📦 Menjalankan composer install..."
composer install --no-interaction --prefer-dist --optimize-autoloader

if [ ! -f database/database.sqlite ]; then
  echo "📁 Membuat database SQLite..."
  mkdir -p database
  touch database/database.sqlite
  chmod -R 775 database
fi

echo "🔁 Menjalankan php artisan migrate..."
php artisan migrate --force || true

echo "🚀 Menjalankan PHP-FPM..."
exec php-fpm
