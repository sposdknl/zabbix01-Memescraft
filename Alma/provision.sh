#!/bin/bash

# Variables
DB_ROOT_PASS="rootpassword"
DB_ZABBIX_PASS="zabbixpassword"
DB_NAME="zabbix"
DB_USER="zabbix"
ZBX_SERVER="localhost"

# Update the system
echo "Updating the system..."
dnf update -y

# Install necessary dependencies
echo "Installing prerequisites..."
dnf install -y epel-release
dnf install -y mariadb-server mariadb

# Start and enable MariaDB
echo "Starting and enabling MariaDB..."
systemctl start mariadb
systemctl enable mariadb

# Secure MariaDB installation
echo "Securing MariaDB..."
mysql_secure_installation <<EOF

y
$DB_ROOT_PASS
$DB_ROOT_PASS
y
y
y
y
EOF

# Create Zabbix database and user
echo "Creating Zabbix database and user..."
mysql -uroot -p$DB_ROOT_PASS -e "CREATE DATABASE $DB_NAME CHARACTER SET utf8mb4 COLLATE utf8mb4_bin;"
mysql -uroot -p$DB_ROOT_PASS -e "CREATE USER '$DB_USER'@'localhost' IDENTIFIED BY '$DB_ZABBIX_PASS';"
mysql -uroot -p$DB_ROOT_PASS -e "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'localhost';"
mysql -uroot -p$DB_ROOT_PASS -e "FLUSH PRIVILEGES;"

# Add Zabbix 7.0 repository
echo "Adding Zabbix 7.0 repository..."
rpm -Uvh https://repo.zabbix.com/zabbix/7.0/rhel/$(rpm -E '%{rhel}')/x86_64/zabbix-release-7.0-1.el$(rpm -E '%{rhel}').noarch.rpm
dnf clean all

# Install Zabbix server, frontend, and agent
echo "Installing Zabbix server, frontend, and agent..."
dnf install -y zabbix-server-mysql zabbix-web-mysql zabbix-nginx-conf zabbix-agent2

# Import initial schema and data
echo "Importing Zabbix schema..."
zcat /usr/share/doc/zabbix-server-mysql*/create.sql.gz | mysql -u$DB_USER -p$DB_ZABBIX_PASS $DB_NAME

# Configure Zabbix server
echo "Configuring Zabbix server..."
sed -i "s/# DBPassword=/DBPassword=$DB_ZABBIX_PASS/" /etc/zabbix/zabbix_server.conf

# Configure PHP for Zabbix
echo "Configuring PHP for Zabbix..."
sed -i "s/;date.timezone =/date.timezone = UTC/" /etc/php-fpm.d/zabbix.conf

# Start and enable Zabbix services
echo "Starting and enabling Zabbix services..."
systemctl restart zabbix-server zabbix-agent2 nginx php-fpm
systemctl enable zabbix-server zabbix-agent2 nginx php-fpm

# Firewall configuration
echo "Configuring the firewall..."
firewall-cmd --add-service=http --permanent
firewall-cmd --add-service=https --permanent
firewall-cmd --add-port=10051/tcp --permanent
firewall-cmd --add-port=10050/tcp --permanent
firewall-cmd --reload

# Final message
echo "Zabbix Server and Agent2 installation completed!"
echo "Access the frontend at http://localhost:8080/zabbix"