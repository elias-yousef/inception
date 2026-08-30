#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

# what is -z ????
if [ -z "$MYSQL_DATABASE" ] || [ -z "$MYSQL_USER" ]; then
    echo "ERROR: MYSQL_DATABASE and MYSQL_USER env variables must be set."
    exit 1
fi

#temp dir that stores PID and socker files while runing
mkdir -p /run/mysqld

#change the ownership from root to the user and group (mysql)
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysql

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing Mariadb data directory...."
    # creat MariaDB internal system databases
    # where in the hard drive to build the filing cabinet
    # Make sure that every file owned by the user mysql
    mariadb-install-db --user=mysql --datadir=/var/lib/mysql

    # '@'%' it allow user to connect to database from everywhere
    # '@'localhost' if i was inside the database

    cat << EOF >/tmp/init.sql

-- set root pass --
ALTER USER 'root'@'localhost' IDENTIFIED BY '${DB_ROOT_PASSWORD}';

-- creat WordPress datapase if not exist --
CREATE DATABASE IF NOT EXISTS \`${MYSQL_DATABASE}\`;

-- creat word press database user --
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'localhost' IDENTIFIED BY '${DB_PASSWORD}';

-- give user the full access to the wordpress database --
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'%';
GRANT ALL PRIVILEGES ON \`${MYSQL_DATABASE}\`.* TO '${MYSQL_USER}'@'localhost';

-- Relaod privilege tables immediately --
FLUSH PRIVILEGES;
EOF
# FLUSH PRIVILEGES;prevents me from haveing to turn the database off and on again
# to make sure the new rules work by updateing its RAM cache while still running
    echo "Running mariadb with init-file..."
    exec mariadbd --user=mysql --init-file=/tmp/init.sql

else
    echo "already intialized, starting normally..."
    exec mariadbd --user=mysql
fi



