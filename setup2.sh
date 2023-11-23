#!/bin/bash

#OPTIONS!

MASTERONION="djroez6ke2mk44nqjtsny4gbbusrzjdq3ogxquwnbazjp43on5goq4yd.onion"
TORAUTHPASSWORD="r2765347"
BACKENDONIONURL="sun5h5eofekturbhrydsiyegevvo7macql2pezlb4cadgymi6h2svyad.onion"

#set to true if you want to setup local proxy instead of proxy over Tor
LOCALPROXY=false
PROXYPASSURL="10.10.10.10:80"

#Shared Front Captcha Key. Key alphanumeric between 64-128. Salt needs to be exactly 8 chars.
KEY="encryption_key"
SALT="1saltkey"
SESSION_LENGTH=3600

#CSS Branding

HEXCOLOR="9b59b6"
HEXCOLORDARK="6d3d82"
SITENAME="obsidian"

#There is more branding you need to do in the resty/caphtml_d.lua file near the end.

clear

echo "Welcome To The End Game DDOS Prevention Setup..."
sleep 1
BLUE='\033[1;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color
printf "\r\nProvided by your lovely ${BLUE}/u/Paris${NC} from dread. \r\n"
printf "with help from ${BLUE}/u/mr_white${NC} from whitehousemarket.\n"
echo "For the full effects of the DDOS prevention you will need to make sure to setup v3 onionbalance."
echo "Onionbalance v3 does have distinct descriptors in a forked version. Read the README.MD in the onionbalance folder for more information."

if [ ${#MASTERONION} -lt 62 ]; then
 echo "MASTEWRONION doesn't have the correct length. The url needs to include the .onion at the end." 
 exit 0
fi

if [ -z "$TORAUTHPASSWORD" ]
then
  echo "you didn't enter your tor authpassword"
  exit 0
fi

shopt -s nullglob dotglob
directory=(dependencies/*)
if [ ${#directory[@]} -gt 0 ]
then
echo "Dependency Folder Found!"
else
echo "You need to get the dependencies first. Run './getdependencies.sh'"
exit 0
fi

echo "Proceeding to do the configuration and setup. This will take awhile."
sleep 5

### Configuration
string="s/masterbalanceonion/"
string+="$MASTERONION"
string+="/g"
sed -i $string site.conf

string="s/torauthpassword/"
string+="$TORAUTHPASSWORD"
string+="/g"
sed -i $string site.conf

string="s/backendurl/"
string+="$BACKENDONIONURL"
string+="/g"
sed -i $string site.conf

string="s/proxypassurl/"
string+="$PROXYPASSURL"
string+="/g"
sed -i $string site.conf

string="s/encryption_key/"
string+="$KEY"
string+="/g"
sed -i $string lua/cap.lua

string="s/salt1234/"
string+="$SALT"
string+="/g"
sed -i $string lua/cap.lua

string="s/sessionconfigvalue/"
string+="$SESSION_LENGTH"
string+="/g"
sed -i $string lua/cap.lua

string="s/HEXCOLOR/"
string+="$HEXCOLOR"
string+="/g"
sed -i $string cap_d.css

string="s/HEXCOLOR/"
string+="$HEXCOLOR"
string+="/g"
sed -i $string queue.html

string="s/HEXCOLORDARK/"
string+="$HEXCOLORDARK"
string+="/g"
sed -i $string queue.html

string="s/SITENAME/"
string+="$SITENAME"
string+="/g"
sed -i $string queue.html

string="s/SITENAME/"
string+="$SITENAME"
string+="/g"
sed -i $string resty/caphtml_d.lua

if $LOCALPROXY
then
string="s/#proxy_pass/"
string+="proxy_pass"
string+="/g"
sed -i $string site.conf
else
string="s/#socks_/"
string+="socks_"
string+="/g"
sed -i $string site.conf
fi

apt-get update
apt-get install libevent-dev libssl-dev -y
apt-get install -y apt-transport-https lsb-release ca-certificates dirmngr

wget https://dist.torproject.org/tor-0.4.8.1-alpha.tar.gz
tar -xf tor-0.4.8.1-alpha.tar.gz
cd tor-0.4.8.1-alpha
./configure --enable-gpl && make -j12
make install
cd ..

apt-key add nginx_signing.key

apt-get update
apt-get install -y tor nyx nginx
apt-get install -y vanguards
apt-get install -y build-essential zlib1g-dev libpcre3 libpcre3-dev uuid-dev gcc git wget curl libgd3 libgd-dev

command="nginx -v"
nginxv=$( ${command} 2>&1 )
NGINXVERSION=$(echo $nginxv | grep -o '[0-9.]*$')

NGINXOPENSSL="1.1.1d"

wget https://nginx.org/download/nginx-1.22.0.tar.gz
tar -xzvf nginx-1.22.0.tar.gz

cp -R dependencies/* nginx-1.22.0/

cd nginx-1.22.0
git clone https://github.com/libinjection/libinjection.git
cp -fr libinjection naxsi/naxsi_src/

wget https://www.openssl.org/source/openssl-1.1.1d.tar.gz
tar -xzvf openssl-1.1.1d.tar.gz

git clone https://github.com/openresty/lua-nginx-module.git

cd luajit2
make -j8 && make install
cd ..

ln -sf luajit-2.1. /usr/local/bin/luajit

cd lua-resty-string
make install
cd ..

cd lua-resty-cookie
make install
cd ..

cd lua-gd
gcc -o gd.so -DGD_XPM -DGD_JPEG -DGD_FONTCONFIG -DGD_FREETYPE -DGD_PNG -DGD_GIF -O2 -Wall -fPIC -fomit-frame-pointer -I/usr/local/include/luajit-2.1 -DVERSION=\"2.0.33r3\" -shared -lgd luagd.c
cp -f gd.so /usr/local/lib/lua/5.1/gd.so
cd ..

mkdir /usr/local/lib/lua/resty/
cp -a lua-resty-session/lib/resty/session* /usr/local/lib/lua/resty/

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
--add-dynamic-module=socks-nginx-module \
--prefix=/etc/nginx/html \
--sbin-path=/usr/sbin/nginx \
--conf-path=/etc/nginx/nginx.conf \
--error-log-path=/var/log/nginx/error.log \
--modules-path=/etc/nginx/modules

wget https://github.com/c64bob/lua-resty-aes/raw/master/lib/resty/aes_functions.lua
cp -r aes_functions.lua /usr/local/lib/lua/resty/aes_functions.lua

mkdir /etc/nginx/
mkdir /etc/nginx/resty/
#include seems to be a bit mssed up with luajit
ln -s /usr/local/lib/lua/resty/ /etc/nginx/resty/

make -j16 modules

cp -r objs modules
make install
cp -r modules /etc/nginx/html/modules/
cd ..

cp -r lua /etc/nginx/html/
cp -r nginx.conf /etc/nginx/nginx.conf
cp -fr naxsi_core.rules /etc/nginx/naxsi_core.rules
cp -fr naxsi_whitelist.rules /etc/nginx/naxsi_whitelist.rules
cp -fr lua /etc/nginx/
cp -fr resty/* /etc/nginx/resty/resty/
cp -fr /etc/nginx/resty/resty/caphtml_d.lua /etc/nginx/resty/caphtml_d.lua
cp -fr random.lua /etc/nginx/resty/resty/random.lua
cp -fr queue.html /etc/nginx/queue.html
mkdir /etc/nginx/sites-enabled/
cp -fr site.conf /etc/nginx/sites-enabled/site.conf
cp -fr cap_d.css /etc/nginx/cap_d.css
chown -R www-data:www-data /etc/nginx/
chown -R www-data:www-data /usr/local/lib/lua
chmod 755 startup.sh
cp -fr startup.sh /startup.sh
chmod 755 rc.local
cp -fr rc.local /etc/rc.local
cp -fr sysctl.conf /etc/sysctl.conf
cp -fr gd.so /usr/local/lib/lua/5.1/
pkill tor

cp -r torrc /usr/local/etc/tortorrc

if $LOCALPROXY
then
echo "localproxy enabled"
else
cp -fr torrc2 /usr/local/etc/tortorrc2
cp -fr torrc3 /usr/local/etc/tortorrc3
fi

torhash=$(tor --hash-password $TORAUTHPASSWORD| tail -c 62)
string="s/hashedpassword/"
string+="$torhash"
string+="/g"
sed -i $string /usr/local/etc/tortorrc

sleep 10

tor

sleep 20

HOSTNAME="$(cat /usr/local/etc/torhidden_service/hostname)"

string="s/mainonion/"
string+="$HOSTNAME"
string+="/g"
sed -i $string /etc/nginx/sites-enabled/site.conf

echo "MasterOnionAddress $MASTERONION" > /usr/local/etc/torhidden_service/ob_config

pkill tor
sleep 10

sed -i "s/#HiddenServiceOnionBalanceInstance/HiddenServiceOnionBalanceInstance/g" /usr/local/etc/tor/torrc

tor

if $LOCALPROXY
then
echo "localproxy enabled"
else
tor -f /usr/local/etc/tortorrc2
tor -f /usr/local/etc/tortorrc3
fi

cp -r nginx.service /lib/systemd/system/

nginx
service vanguards start
nginx -s stop
nginx

clear

echo "ALL SETUP! Your new front address is"
echo $HOSTNAME
echo "Add it to your onionbalance configuration!"