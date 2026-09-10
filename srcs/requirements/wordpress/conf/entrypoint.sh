#!/bin/bash

# Exit immediately if any command fails (Defense in depth)
set -e

echo "Starting WordPress container setup..."

# 1. Read secrets from Docker's secure mount points
DB_PASSWORD=$(cat /run/secrets/db_password)
WP_ADMIN_PASSWORD=$(cat /run/secrets/wp_admin_password)
WP_USER_PASSWORD=$(cat /run/secrets/wp_user_password)

# 2. Set the working directory where WordPress files will live
cd /var/www/html

# 3. Defensive Wait Loop: Wait until MariaDB is fully ready and accepting connections
echo "Waiting for MariaDB to become available..."
while ! mariadb -h mariadb -u "$MYSQL_USER" -p"$DB_PASSWORD" -e "SELECT 1;" >/dev/null 2>&1; do
    echo "MariaDB is booting up, sleeping for 3 seconds..."
    sleep 3
done
echo "MariaDB is up and responding!"

# 4. Check if WordPress core files are already downloaded
if [ ! -f "wp-settings.php" ]; then
    echo "Downloading WordPress core files..."
    wp core download --allow-root

    echo "Generating wp-config.php..."
    wp config create \
        --dbname="$MYSQL_DATABASE" \
        --dbuser="$MYSQL_USER" \
        --dbpass="$DB_PASSWORD" \
        --dbhost="mariadb" \
        --allow-root

    echo "Installing WordPress..."
    # CRITICAL RULE: The admin username CANNOT contain 'admin' or 'administrator'
    wp core install \
        --url="$DOMAIN_NAME" \
        --title="Inception 42" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="eabushak@student.42amman.jo" \
        --allow-root

    echo "Creating secondary user..."
    # Project rule: There must be two users in your database, one being the admin
    wp user create \
        "$WP_USER_NAME" \
        "eabushak_user@student.42amman.jo" \
        --user_pass="$WP_USER_PASSWORD" \
        --role="editor" \
        --allow-root

    echo "WordPress installation and configuration completed successfully!"
else
    echo "WordPress is already installed, skipping setup..."
fi

# 5. Hand over PID 1 to PHP-FPM in the foreground (Crucial for container lifecycle)
echo "Starting PHP-FPM..."
exec php-fpm8.2 -F