#!/usr/bin/env bash

source /app/vagrant/provision/common.sh

#== Import script args ==

timezone=$(echo "$1")
readonly IP=$2

#== Provision script ==

info "Provision-script user: `whoami`"

#export DEBIAN_FRONTEND=noninteractive
export FREEBSD_FRONTEND=noninteractive

info "Configure timezone"
#timedatectl set-timezone ${timezone} --no-ask-password
export TZ=${timezone}

info "AWK initial replacement work"
awk -v ip=$IP -f /app/vagrant/provision/provision.awk /app/environments/dev/*end/config/main-local.php

#info "Prepare root password for MySQL"
#debconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password \"''\""
#debconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password \"''\""
#bsdconf-set-selections <<< "mysql-community-server mysql-community-server/root-pass password \"''\""
#bsdconf-set-selections <<< "mysql-community-server mysql-community-server/re-root-pass password \"''\""
#echo "Done!"

info "Update OS software"
#apt-get update
pkg update
#apt-get upgrade -y

info "Install additional software"
pkg install -y php81 php81-{curl,intl,mysqli,gd,mbstring,xml} nginx unzip mysql80-server php81-pecl-xdebug-3.1.5
info "Configure startup"
echo 'nginx_enable="YES"' >> /etc/rc.conf &&
echo 'mysql_enable="YES"' >> /etc/rc.conf &&
echo 'php_fpm_enable="YES"' >> /etc/rc.conf
echo "Done!"

info "Configure MySQL"
#sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf
sed -i "s/.*bind-address.*/bind-address = 0.0.0.0/" /usr/local/etc/mysql/my.cnf
mysql -uroot <<< "CREATE USER 'root'@'%' IDENTIFIED BY ''"
mysql -uroot <<< "GRANT ALL PRIVILEGES ON *.* TO 'root'@'%'"
mysql -uroot <<< "DROP USER 'root'@'localhost'"
mysql -uroot <<< "FLUSH PRIVILEGES"
echo "Done!"

info "Configure PHP-FPM"
sed -i 's/user = www/user = vagrant/g' /usr/local/etc/php-fpm.d/www.conf
sed -i 's/group = www/group = vagrant/g' /usr/local/etc/php-fpm.d/www.conf
sed -i 's/owner = www/owner = vagrant/g' /usr/local/etc/php-fpm.d/www.conf
#cat << EOF > /etc/php/7.0/mods-available/xdebug.ini
cat << EOF > /usr/local/etc/php/ext-20-xdebug.ini
zend_extension=xdebug.so
xdebug.remote_enable=1
xdebug.remote_connect_back=1
xdebug.remote_port=9000
xdebug.remote_autostart=1
EOF
echo "Done!"

info "Configure NGINX"
#sed -i 's/user www-data/user vagrant/g' /etc/nginx/nginx.conf
sed -i 's/user www-data/user vagrant/g' /usr/local/etc/nginx/nginx.conf
echo "Done!"

info "create directory in nginx"
mkdir -p /usr/local/etc/nginx/site-enable
echo "Done!"

info "Enabling site configuration"
ln -s /app/vagrant/nginx/app.conf /usr/local/etc/nginx/site-enable/app.conf
echo "Done!"

info "Initailize databases for MySQL"
mysql -uroot <<< "CREATE DATABASE yii2advanced"
mysql -uroot <<< "CREATE DATABASE yii2advanced_test"
echo "Done!"

info "Install composer"
curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer