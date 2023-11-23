#!/bin/bash

shopt -s nullglob dotglob
directory=(dependencies/*)
if [ ${#directory[@]} -gt 0 ]; then
read -p "Found Dependency Directory. Did you want to wipe? (y/n) " -n 1 -r
if [[ $REPLY =~ ^[y]$ ]]
then
     rm -R dependencies
echo
read -p "Did you want to resync? (y/n) " -n 1 -r
if [[ $REPLY =~ ^[y]$ ]]
then
echo
echo "resyncing"
else
exit 0
fi
echo
echo "Run again ;)"
else
echo
exit 0
fi
echo
exit 0
fi

apt-get update
apt-get -y install git
apt install build-essential libpcre3-dev libssl-dev zlib1g-dev libgd-dev -y

mkdir dependencies
cd dependencies
git clone https://github.com/vision5/ngx_devel_kit
git clone https://github.com/openresty/lua-resty-string
git clone https://github.com/cloudflare/lua-resty-cookie
git clone https://github.com/ittner/lua-gd
git clone https://github.com/bungle/lua-resty-session
git clone https://github.com/yorkane/socks-nginx-module.git
git clone https://github.com/wargio/naxsi.git
git clone https://github.com/openresty/headers-more-nginx-module.git
git clone https://github.com/openresty/echo-nginx-module.git
git clone https://github.com/libinjection/libinjection.git
git clone https://github.com/openresty/luajit2
git clone https://openresty.org/download/openresty-1.21.4.1.tar.gz

apt -y install gcc-9 g++-9
sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-9 9
sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-9 9
sudo update-alternatives --config gcc

cd luajit2
git checkout v2.1-20230911
cd ..

#some required stuff for lua/luajit. obviously versions should be ckecked with every install/update
git clone https://github.com/openresty/lua-nginx-module
cd lua-nginx-module
git checkout v0.10.16
cd ..

sed -i 's/r->quoted_uri || r->space_in_uri || r->internal/r->quoted_uri || r->internal/' socks-nginx-module/src/ngx_http_socks_module.c
sed -i 's/r->quoted_uri || r->space_in_uri || r->internal/r->quoted_uri || r->internal/' socks-nginx-module/src/ngx_http_socks_module.c
echo -e "LUAJIT_LIB=/usr/local/lib\n$(cat lua-nginx-module/config)" > lua-nginx-module/config
echo -e "LUAJIT_INC=/usr/local/include/luajit-2.1\n$(cat lua-nginx-module/config)" > lua-nginx-module/config