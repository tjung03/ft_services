#!/bin/sh

mkdir -p /run/nginx

mv ./default.conf /etc/nginx/conf.d/

mkdir -p /var/www/html
echo "<?php phpinfo(); ?>" > /var/www/html/index.php

wget https://wordpress.org/latest.tar.gz
tar -xvf latest.tar.gz
rm -rf latest.tar.gz

mv wordpress/ /var/www/html/
mv ./wp-config.php /var/www/html/wordpress

chmod -R 755 /var/www/*

php-fpm7 && nginx -g "daemon off;"
