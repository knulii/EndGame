#!/bin/bash

apt-get update
apt-get -y upgrade

command="nginx -v"
nginxv=$( ${command} 2>&1 )
NGINXVERSION=$(echo $nginxv | grep -o '[0-9.]*$')

NGINXOPENSSL="1.1.1d"

wget https://nginx.org/download/nginx-1.22.0.tar.gz
tar -xzvf nginx-1.23.0.tar.gz

cp -R dependencies/* nginx-1.22.0/

cd nginx-1.22.0

wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz
tar -xzvf openssl-1.1.1d.tar.gz

mv openssl-1.1.1d openssl-

export LUAJIT_LIB=/usr/local/lib
export LUAJIT_INC=/usr/local/include/luajit-2.1
./configure --with-cc-opt='-Wno-stringop-overflow -Wno-stringop-truncation -Wno-cast-function-type' \
--with-ld-opt="-Wl,-rpath,/usr/local/lib" \
--with-compat --with-openssl=openssl- \
--with-http_ssl_module \
--add-dynamic-module=naxsi/naxsi_src \
--add-dynamic-module=headers-more-nginx-module \
--add-dynamic-module=echo-nginx-module \
--add-dynamic-module=ngx_devel_kit \
--add-dynamic-module=lua-nginx-module \

--prefix=/var/www/html \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--modules-path=/etc/nginx/modules

make -j16 modules

cp -r objs modules
rm -R /etc/nginx/modules
mkdir /etc/nginx/modules
mv modules /etc/nginx/modules