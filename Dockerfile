# Use the lightweight Alpine-based PHP 8.5 FPM image
FROM php:8.5-fpm-alpine

# 1. Install system dependencies for WordPress extensions
# We include build-base and autoconf temporarily to compile PECL extensions
RUN apk add --no-cache \
    freetype-dev \
    libjpeg-turbo-dev \
    libpng-dev \
    libwebp-dev \
    libavif-dev \
    imagemagick-dev \
    libzip-dev \
    icu-dev \
    libxml2-dev \
    oniguruma-dev \
    $PHPIZE_DEPS

# 2. Configure and install standard extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp --with-avif \
    && docker-php-ext-install -j$(nproc) \
        bcmath \
        exif \
        gd \
        intl \
        mysqli \
        opcache \
        pdo_mysql \
        zip

# 3. Install PECL extensions (Imagick and Redis)
# Note: For Imagick on Alpine, we occasionally need to pull from a specific 
# repository or compile from source depending on 2026's edge updates.
RUN pecl install imagick redis \
    && docker-php-ext-enable imagick redis

# 4. Clean up the build dependencies to keep the image slim
RUN apk del $PHPIZE_DEPS

# 5. Set recommended PHP.ini settings
RUN { \
        echo 'opcache.memory_consumption=128'; \
        echo 'opcache.interned_strings_buffer=8'; \
        echo 'opcache.max_accelerated_files=4000'; \
        echo 'opcache.revalidate_freq=2'; \
        echo 'upload_max_filesize=64M'; \
        echo 'post_max_size=64M'; \
        echo 'memory_limit=256M'; \
    } > /usr/local/etc/php/conf.d/wp-recommended.ini

WORKDIR /var/www/html

# Use production ini settings
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

EXPOSE 9000
CMD ["php-fpm"]
    
