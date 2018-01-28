FROM nginx:1.13.3

RUN apt-get update
RUN echo Y | apt-get install wget
RUN cd /var && mkdir nginx-custom
RUN cd /var/nginx-custom && wget http://nginx.org/download/nginx-1.13.3.tar.gz
RUN cd /var/nginx-custom && tar -xvf nginx-1.13.3.tar.gz

RUN echo Y | apt-get install aptitude
RUN echo Y | aptitude install build-essential
RUN echo Y | aptitude install libpcre++-dev
RUN echo Y | aptitude install libssl-dev
RUN echo Y | aptitude install libxslt1-dev
RUN echo Y | aptitude install libgeoip-dev

RUN echo Y | apt-get install mysql-server
RUN apt-get install unzip
RUN echo Y | apt-get install default-libmysqlclient-dev
RUN cd /var/nginx-custom/nginx-1.13.3 && wget https://github.com/arut/nginx-mtask-module/archive/master.zip
RUN cd /var/nginx-custom/nginx-1.13.3 && unzip master.zip
RUN cd /var/nginx-custom/nginx-1.13.3 && wget https://github.com/arut/nginx-mysql-module/archive/master.zip
RUN cd /var/nginx-custom/nginx-1.13.3 && unzip master.zip.1


RUN echo Y | apt-get install gcc

RUN cd /var/nginx-custom/nginx-1.13.3 && ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-http_mp4_module --add-module=/var/nginx-custom/nginx-1.13.3/nginx-mtask-module-master --add-module=/var/nginx-custom/nginx-1.13.3/nginx-mysql-module-master

RUN cd /var/nginx-custom/nginx-1.13.3 && make
RUN cd /var/nginx-custom/nginx-1.13.3 && make install



RUN wget -qO - https://openresty.org/package/pubkey.gpg | apt-key add -
RUN apt-get -y install software-properties-common
RUN add-apt-repository -y "deb http://openresty.org/package/debian $(lsb_release -sc) openresty"
RUN apt-get update
RUN echo Y | apt-get install openresty












