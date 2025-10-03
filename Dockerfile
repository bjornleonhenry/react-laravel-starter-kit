# Multi-stage build for React Laravel Starter Kit
# Stage 1: Build the frontend
FROM node:18-alpine AS frontend-builder

WORKDIR /app/frontend

# Copy package files
COPY frontend/package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY frontend/ .

# Build the frontend
RUN npm run build

# Stage 2: Build the backend
FROM composer:latest AS backend-builder

WORKDIR /app/backend

# Copy composer files
COPY backend/composer.json backend/composer.lock ./

# Install dependencies
RUN composer install --no-dev --optimize-autoloader --no-interaction

# Stage 3: Production image
FROM php:8.2-fpm-alpine AS production

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    sqlite \
    supervisor \
    curl \
    zip \
    unzip \
    git \
    && rm -rf /var/cache/apk/*

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_sqlite

# Set working directory
WORKDIR /var/www/html

# Copy PHP configuration
COPY docker/php.ini /usr/local/etc/php/conf.d/app.ini

# Copy Nginx configuration
COPY docker/nginx.conf /etc/nginx/nginx.conf

# Copy Supervisor configuration
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Copy backend application
COPY --from=backend-builder /app/backend /var/www/html/backend

# Copy frontend build
COPY --from=frontend-builder /app/frontend/dist /var/www/html/public

# Create necessary directories
RUN mkdir -p /var/www/html/backend/storage/logs \
    && mkdir -p /var/www/html/backend/storage/framework/cache \
    && mkdir -p /var/www/html/backend/storage/framework/sessions \
    && mkdir -p /var/www/html/backend/storage/framework/views \
    && mkdir -p /var/www/html/backend/bootstrap/cache

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/backend/storage \
    && chmod -R 775 /var/www/html/backend/bootstrap/cache

# Copy environment file
COPY docker/.env.production /var/www/html/backend/.env

# Generate application key
WORKDIR /var/www/html/backend
RUN php artisan key:generate --force

# Run migrations
RUN php artisan migrate --force

# Expose port
EXPOSE 80

# Start services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

# Development stage
FROM php:8.2-fpm-alpine AS development

# Install system dependencies
RUN apk add --no-cache \
    nginx \
    sqlite \
    supervisor \
    curl \
    zip \
    unzip \
    git \
    nodejs \
    npm \
    && rm -rf /var/cache/apk/*

# Install PHP extensions
RUN docker-php-ext-install pdo pdo_sqlite

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy PHP configuration
COPY docker/php.ini /usr/local/etc/php/conf.d/app.ini

# Copy Nginx configuration
COPY docker/nginx-dev.conf /etc/nginx/nginx.conf

# Copy Supervisor configuration
COPY docker/supervisord-dev.conf /etc/supervisor/conf.d/supervisord.conf

# Copy application code
COPY . /var/www/html/

# Install backend dependencies
WORKDIR /var/www/html/backend
RUN composer install

# Install frontend dependencies
WORKDIR /var/www/html/frontend
RUN npm install

# Create necessary directories
RUN mkdir -p /var/www/html/backend/storage/logs \
    && mkdir -p /var/www/html/backend/storage/framework/cache \
    && mkdir -p /var/www/html/backend/storage/framework/sessions \
    && mkdir -p /var/www/html/backend/storage/framework/views \
    && mkdir -p /var/www/html/backend/bootstrap/cache

# Set permissions
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 /var/www/html/backend/storage \
    && chmod -R 775 /var/www/html/backend/bootstrap/cache

# Copy development environment file
COPY docker/.env.development /var/www/html/backend/.env

# Generate application key
WORKDIR /var/www/html/backend
RUN php artisan key:generate --force

# Run migrations
RUN php artisan migrate --force

# Build frontend
WORKDIR /var/www/html/frontend
RUN npm run build

# Expose ports
EXPOSE 80 5173

# Start services
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
