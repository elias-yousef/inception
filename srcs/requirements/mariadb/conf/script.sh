#!/bin/bash

set -e

DB_PASSWORD=$(cat /run/secrets/db_password)
DB_ROOT_PASSWORD=$(cat /run/secrets/db_root_password)

#temp dir that stores PID and socker files while runing
mkdir -p /run/mysqild

#change the ownership from root to the user and group (mysql)
chown -R mysql:mysql /run/mysqld
chown -R mysql:mysql /var/lib/mysqld

if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "Initializing Mariadb data directory...."
    

fi



