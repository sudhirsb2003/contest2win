yes | yum install gcc gcc-c++ zlib-devel postgresql-server postgresql-devel openssl openssl-devel readline-* git-core autoconf automake libtool ImageMagick ImageMagick-devel httpd httpd-devel mod_ssl initng-conf-gtk

echo "/usr/local/lib" >> /etc/ld.so.conf
/sbin/ldconfig

echo "installing ruby..."
if [ ! -f ruby-1.8.7-p72.tar.gz ];
	then
		wget ftp://ftp.ruby-lang.org/pub/ruby/1.8/ruby-1.8.7-p72.tar.gz
fi
tar -xzf ruby-1.8.7-p72.tar.gz && cd ruby-1.8.7*
./configure && make
sudo make install
echo 'ruby installed.'
cd ..

echo "Installing rubygems..."
if [ ! -f rubygems-1.3.1.tgz ]; then wget http://rubyforge.org/frs/download.php/45905/rubygems-1.3.1.tgz ; fi
tar -xzf rubygems-1.3.1.tgz
cd rubygems-1.3.1
ruby setup.rb
cd ..
echo "rubygems installed!"

echo "installing rails..."
sudo gem install rails -v 2.2.2 --no-ri --no-rdoc
echo "rails installed!"

# install the cache server
echo "Installing memcached..."
wget http://www.monkey.org/~provos/libevent-1.2a.tar.gz
tar -xzf libevent-1.2a.tar.gz
cd libevent-1.2a
./configure
make; make install
cd ..

# install memcached
wget http://www.danga.com/memcached/dist/memcached-1.2.1.tar.gz
tar -xzf memcached-1.2.1.tar.gz
cd memcached-1.2.1
./configure
make; make install
cd ..

# auto start memcached
echo "/usr/local/bin/memcached -d -u nobody -P /var/run/memcached.pid" >> /etc/rc.local
ldconfig
/usr/local/bin/memcached -d -u nobody -P /var/run/memcached.pid
echo "memcached installed and started!"

# install gems
sudo gem install ruby-pg memcache-client fastercsv htmlentities RedCloth right_aws rmagick calendar_date_select rcov --no-ri --no-rdoc
gem install mislav-will_paginate -v2.2.3 --source http://gems.github.com

wget http://www.sphinxsearch.com/downloads/sphinx-0.9.8.tar.gz
tar -xzf sphinx-0.9.8.tar.gz
cd sphinx-0.9.8
./configure --with-pgsql --with-mysql=no
make && make install
cd ..

wget https://c2w-backups.s3.amazonaws.com/software/ffmpeg-full-src.tar.bz2
tar -xjf ffmpeg-full-src.tar.bz2
cd ffmpeg-full
./install
cd ..

gem install passenger  --no-ri --no-rdoc

passenger-install-apache2-module


# GeoIP
wget http://geolite.maxmind.com/download/geoip/api/c/GeoIP-1.4.6.tar.gz
tar -xzf GeoIP-1.4.6.tar.gz
cd GeoIP-1.4.6
./configure && make && make install
cd ..

wget http://geolite.maxmind.com/download/geoip/api/ruby/net-geoip-0.06.tar.gz
tar -xzf net-geoip-0.06.tar.gz
cd net-geoip-0.06
ruby extconf.rb
### edit the file Makefile and search for the text -Wall-g and change it to -Wall -g
perl -i.bak -p -e's/-Wall-g/-Wall -g/g' Makefile
make
make install
cd ..


# install python dependencies for Google AdSesne API
yes | yum install python-setuptools python-setuptools-devel
easy_install fpconst
easy_install pyXML
wget http://nchc.dl.sourceforge.net/sourceforge/pywebsvcs/SOAPpy-0.12.0.tar.gz
tar xzf SOAPpy-0.12.0.tar.gz
cd SOAPpy-0.12.0

