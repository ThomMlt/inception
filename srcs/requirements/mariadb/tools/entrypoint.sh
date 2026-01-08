#!/bin/sh

set -e

chown -R mysql:mysql /var/lib/mysql /run/mysqld

if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Initializing MariaDB database..."
    
    if [ -d "/var/lib/mysql/mysql" ]; then
        echo "Removing auto-generated mysql directory..."
        rm -rf /var/lib/mysql/*
    fi

    mysql_install_db --user=mysql --datadir=/var/lib/mysql

    echo "Starting temporary MariaDB instance..."
    
    mysqld --user=mysql --skip-networking --socket=/tmp/mysql_init.sock &
    pid="$!"
    
    echo "Waiting for MariaDB to start..."
    for i in $(seq 1 30); do
        if mysqladmin ping --socket=/tmp/mysql_init.sock --silent 2>/dev/null; then
            echo "MariaDB is ready for configuration!"
            break
        fi
        sleep 1
    done
    
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
    
    mysqladmin --socket=/tmp/mysql_init.sock shutdown
    wait "$pid"
    
    echo "MariaDB initialized successfully!"
else
    echo "MariaDB already initialized, skipping initialization"
fi

echo "Starting MariaDB..."
exec mysqld --user=mysql
