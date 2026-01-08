#!/bin/sh

set -e

echo "Generating SSL certificate..."
if [ ! -f /etc/nginx/ssl/nginx.crt ]; then
    openssl req -x509 -nodes -days 365 \
        -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/nginx.key \
        -out /etc/nginx/ssl/nginx.crt \
        -subj "/C=FR/ST=IDF/L=Paris/O=42/CN=${DOMAIN_NAME}"
    echo "SSL certificate generated"
fi

echo "Configuring NGINX..."
envsubst '$DOMAIN_NAME' < /etc/nginx/nginx.conf > /tmp/nginx.conf
mv /tmp/nginx.conf /etc/nginx/nginx.conf

# Test NGINX configuration
nginx -t

echo "Starting NGINX..."
exec nginx -g "daemon off;"
