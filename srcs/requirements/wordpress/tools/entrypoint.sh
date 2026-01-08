#!/bin/sh

set -e

cd /var/www/wordpress

echo "Waiting for MariaDB..."
for i in $(seq 1 60); do
    if mysqladmin ping -h mariadb -u"$MYSQL_USER" -p"$MYSQL_PASSWORD" --silent 2>/dev/null; then
        echo "MariaDB is ready!"
        break
    fi
    if [ "$i" -eq 60 ]; then
        echo "ERROR: MariaDB not ready after 60 seconds"
        exit 1
    fi
    sleep 1
done

if [ ! -f wp-config.php ]; then
    echo "Downloading WordPress..."
    
    rm -rf /var/www/wordpress/*
    
    wp core download --allow-root

    echo "Creating wp-config.php..."
    wp config create --allow-root \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$MYSQL_PASSWORD" \
        --dbhost="mariadb:3306" \
        --skip-check

    echo "Installing WordPress..."
    wp core install --allow-root \
        --url="https://${DOMAIN_NAME}" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email

    echo "Creating additional user..."
    wp user create --allow-root \
        "$WP_USER" "$WP_USER_EMAIL" \
        --user_pass="$WP_USER_PASSWORD" \
        --role=editor
    
    echo "WordPress installation complete!"
else
    echo "WordPress already installed, skipping installation"
fi

chown -R www-data:www-data /var/www/wordpress
chmod -R 755 /var/www/wordpress

echo "Starting PHP-FPM..."
exec php-fpm8.2 -F
