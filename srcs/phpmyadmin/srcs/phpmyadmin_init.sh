#!/bin/sh

mkdir -p /run/nginx

mv ./default.conf /etc/nginx/conf.d/

mkdir -p /var/www/html
echo "<?php phpinfo(); ?>" > /var/www/html/index.php

wget https://files.phpmyadmin.net/phpMyAdmin/5.1.0/phpMyAdmin-5.1.0-all-languages.tar.gz
tar -xvf phpMyAdmin-5.1.0-all-languages.tar.gz
rm -rf phpMyAdmin-5.1.0-all-languages.tar.gz

mv phpMyAdmin-5.1.0-all-languages /var/www/html/phpmyadmin
mv /config.inc.php /var/www/html/phpmyadmin/

mkdir /var/www/html/phpmyadmin/tmp/
chmod -R 755 /var/www/*
chmod -R 777 /var/www/html/phpmyadmin/tmp

php-fpm7 && nginx -g "daemon off;"
