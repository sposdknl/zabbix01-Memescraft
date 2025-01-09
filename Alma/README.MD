# Manuál na manuální instalaci Zabbix server verze 7.0 LTS
1. Nejprve nainstalujeme Zabbix repozitář pro naší verzi operačního systému (v mém případě AlmaLinux 9) pomocí tohodle příkazu:
sudo rpm -Uvh https://repo.zabbix.com/zabbix/7.0/alma/9/x86_64/zabbix-release-latest-7.0.el9.noarch.rpm

2. Nainstalujeme Zabbix server, webové rozhraní a agenta:
sudo dnf install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent

3. Nainstalujeme databázi, aktivujeme ji a bezpečně nainstalujeme (v mém případě MariaDB):
sudo dnf install -y mariadb-server
sudo systemctl start mariadb
sudo systemctl enable mariadb
sudo mysql_secure_installation

4. Přihlásíme se do MariaDB:
sudo mysql -uroot -p

5. Nastavíme si náš Zabbix repozitář, nastavíme heslo a dáme repozitáři práva, a pak odhlásíme se:
create database zabbix character set utf8mb4 collate utf8mb4_bin;
create user zabbix@localhost identified by 'password';
grant all privileges on zabbix.* to zabbix@localhost;
set global log_bin_trust_function_creators = 1;
quit;

6. Importujeme a načteme náš Zabbix repozitář:
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix

7. Zase zapneme MariaDB a nastavíme trust_function_creators: (důvod proč jsme to neudělali předtím je ten že by bez toho příkazu se nemusel dobře načíst repozitář nebo importovat)
sudo mysql -uroot -p
set global log_bin_trust_function_creators = 0;
quit;

8. nastavíme mariaDB heslo na heslo pro dobré zapamatování a restartujeme a povolíme naše už nastavené Zabbix služby:
DBPassword=password
sudo systemctl restart zabbix-server zabbix-agent httpd php-fpm
sudo systemctl enable zabbix-server zabbix-agent httpd php-fpm

9. nainstalujeme a spustíme Apache:
sudo dnf install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
