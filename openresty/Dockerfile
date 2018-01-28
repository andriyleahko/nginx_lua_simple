FROM danday74/nginx-lua

RUN apt-get update
RUN echo Y | apt-get install wget
RUN echo Y | apt-get install unzip
RUN cd /var && wget https://github.com/openresty/lua-resty-mysql/archive/master.zip

RUN cd /var && unzip master.zip

RUN echo Y | apt-get install mysql-server

RUN echo Y | apt-get install libmysqlclient-dev













