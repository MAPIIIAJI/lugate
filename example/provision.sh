#!/usr/bin/env bash

# Install dependencies
sudo apt-get -y update
sudo apt-get -y install cmake git libpcre3 wget gcc g++ luajit libluajit-5.1-2 libluajit-5.1-dev libssl-dev autotools-dev luajit luarocks libssl1.0.0
sudo luarocks install lugate

# Download nginx
wget http://nginx.org/download/nginx-1.9.12.tar.gz
tar xvzf http://nginx.org/download/nginx-1.9.12.tar.gz
cd nginx-1.9.12

# Download devel kit
git clone https://github.com/simpl/ngx_devel_kit.git

# Download lua module
git clone https://github.com/openresty/lua-nginx-module.git

# Get pcre
wget ftp://ftp.csx.cam.ac.uk/pub/software/programming/pcre/pcre-8.37.tar.bz2
tar xvjf pcre2-10.20.tar.bz2 && mv pcre2-10.20.tar.bz2 pcre

# Get zlib lib
git clone https://github.com/madler/zlib.git

# Tell nginx's build system where to find LuaJIT 2.1:
export LUAJIT_LIB=/usr/lib/x86_64-linux-gnu/libluajit-5.1.so.2.0.2
export LUAJIT_INC=/usr/include/luajit-2.0

# Configure
./configure \
  --sbin-path=/usr/sbin/nginx \
  --conf-path=/usr/local/nginx/nginx.conf \
  --pid-path=/usr/local/nginx/nginx.pid \
  --with-http_ssl_module \
  --with-pcre=./pcre \
  --with-zlib=./zlib \
  --add-module=./ngx_devel_kit \
  --add-module=./lua-nginx-module

# Compile
make -j2 && make install