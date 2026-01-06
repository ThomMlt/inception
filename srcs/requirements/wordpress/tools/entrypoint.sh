#!/bin/sh

set -e

cd /var/www/wordpress

# Wait for MariaDB to be ready
echo "Waiting for MariaDB..."
while ! mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; do
    sleep 2
done
echo "MariaDB is ready!"

# Download WordPress if not present
if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."
    
    # Remove any partial downloads
    rm -rf /var/www/wordpress/*
    
    wp core download --allow-root

    echo "Creating wp-config.php..."
    wp config create --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb:3306"

    echo "Installing WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL"

    echo "Creating additional user..."
    wp user create --allow-root \
        "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD"
    
    echo "WordPress installation complete!"
fi

# Proper permissions
chown -R www-data:www-data /var/www/wordpress

echo "Starting PHP-FPM..."
# Start PHP-FPM in foreground
exec php-fpm7.4 -F
