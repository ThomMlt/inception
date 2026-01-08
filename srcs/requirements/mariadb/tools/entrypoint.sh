#!/bin/sh

set -e

# Ensure correct ownership
chown -R mysql:mysql /var/lib/mysql /run/mysqld

# Check if database needs initialization by looking for specific database, not just mysql dir
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Initializing MariaDB database..."
    
    # Remove auto-initialized mysql if it exists without our database
    if [ -d "/var/lib/mysql/mysql" ]; then
        echo "Removing auto-generated mysql directory..."
        rm -rf /var/lib/mysql/*
    fi

    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "Starting temporary MariaDB instance..."
    
    # Start MariaDB temporarily in background
    mysqld --user=mysql --skip-networking --socket=/tmp/mysql_init.sock &
    pid="$!"
    
    # Wait for MariaDB to be ready
    echo "Waiting for MariaDB to start..."
    for i in $(seq 1 30); do
        if mysqladmin ping --socket=/tmp/mysql_init.sock --silent 2>/dev/null; then
            echo "MariaDB is ready for configuration!"
            break
        fi
        sleep 1
    done
    
    # Configure database
    echo "Creating database and users..."
    mysql --socket=/tmp/mysql_init.sock <<EOF
DELETE FROM mysql.user WHERE User='';
DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost', '127.0.0.1', '::1');
ALTER USER 'root'@'localhost' IDENTIFIED BY '${MYSQL_ROOT_PASSWORD}';
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${MYSQL_PASSWORD}';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
FLUSH PRIVILEGES;
EOF
    
    echo "Database configuration complete!"
    
    # Stop temporary instance
    mysqladmin --socket=/tmp/mysql_init.sock shutdown
    wait "$pid"
    
    echo "MariaDB initialized successfully!"
else
    echo "MariaDB already initialized, skipping initialization"
fi

# Start MariaDB properly (PID 1)
echo "Starting MariaDB..."
exec mysqld --user=mysql
