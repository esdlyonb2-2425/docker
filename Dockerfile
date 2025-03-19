FROM php:8.3-apache

# Install required dependencies
RUN apt-get update && apt-get install -y \
    unzip \
    git \
    curl \
    libicu-dev \
    libpq-dev \
    libzip-dev \
    zip \
    postgresql-client \
    && docker-php-ext-install intl pdo pdo_pgsql opcache zip \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Enable Apache modules
RUN a2enmod rewrite ssl headers

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Install Symfony CLI
RUN curl -sS https://get.symfony.com/cli/installer | bash \
    && mv /root/.symfony5/bin/symfony /usr/local/bin/symfony

# Set working directory
WORKDIR /var/www/html
COPY public/.htaccess /var/www/html/public/.htaccess
# Copy project files
COPY . /var/www/html

# Ensure the public directory exists
RUN mkdir -p /var/www/html/public

# Check if composer.json exists before running composer install
RUN if [ -f "/var/www/html/composer.json" ]; then composer install --no-interaction --optimize-autoloader; fi

# Run Symfony requirements check
RUN if [ -f "/var/www/html/bin/console" ]; then symfony check:requirements; fi

# Ensure Apache runs as www-data
RUN echo "User www-data\nGroup www-data" > /etc/apache2/conf-available/docker-user.conf \
    && a2enconf docker-user

# Set up Apache default site configuration
RUN echo "<VirtualHost *:80>\n \
    ServerName localhost\n \
    DocumentRoot /var/www/html/public\n \
    <Directory /var/www/html/public>\n \
        Options Indexes FollowSymLinks\n \
        AllowOverride All\n \
        Require all granted\n \
    </Directory>\n \
    ErrorLog /var/log/apache2/error.log\n \
    CustomLog /var/log/apache2/access.log combined\n \
</VirtualHost>" > /etc/apache2/sites-available/000-default.conf

# Expose port 80
EXPOSE 80

# Start Apache in foreground
CMD ["apache2-foreground"]

# Create cache directory and set proper permissions.
RUN mkdir -p /var/www/html/var/cache && \
    chown -R www-data:www-data /var/www/html/var/cache && \
    chmod -R 775 /var/www/html/var/cache && \
    ls -ld /var/www/html/var/cache/prod #Verify the directory exist and permissions.
