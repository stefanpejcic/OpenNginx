FROM alpine:latest
LABEL maintainer="stefan@pejcic.rs"
LABEL author="Stefan Pejcic"

RUN apk update && apk upgrade
RUN apk add --update wget \
	tar \
	autoconf \
	automake \ 
	build-base \ 
	git \ 
	openssl-dev \
	curl-dev \
 	geoip-dev \
 	lmdb-dev \
 	pcre-dev \
 	libtool \
 	libxml2-dev \
 	libressl-dev \ 
	yajl-dev \
 	pkgconf  \
	zlib-dev \
	linux-headers 
	
# compile latest modsec
RUN cd /tmp && git clone https://github.com/SpiderLabs/ModSecurity 
RUN cd /tmp/ModSecurity && git submodule init && git submodule update
RUN cd /tmp/ModSecurity && ./build.sh && \
	./configure && \
	make && \
	make install

# latest nginx from  https://nginx.org/en/CHANGES
RUN cd /tmp && git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git \
    && wget http://nginx.org/download/nginx-1.27.0.tar.gz \
    && tar zxvf nginx-1.27.0.tar.gz

RUN cd /tmp/nginx-1.27.0/ && ./configure  --user=root --group=root --with-debug --with-ipv6 --with-http_ssl_module  --with-compat --add-module=/tmp/ModSecurity-nginx --without-http_access_module --without-http_auth_basic_module --without-http_autoindex_module --without-http_empty_gif_module --without-http_fastcgi_module --without-http_referer_module --without-http_memcached_module --without-http_scgi_module --without-http_split_clients_module --without-http_ssi_module --without-http_uwsgi_module \
    && make \
    && make install 

# latest owasp core ruleset
RUN git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git /usr/src/owasp-modsecurity-crs
RUN cp -R /usr/src/owasp-modsecurity-crs/rules/ /usr/local/nginx/conf/ 
RUN mv /usr/local/nginx/conf/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example  /usr/local/nginx/conf/rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf 
RUN mv /usr/local/nginx/conf/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf.example  /usr/local/nginx/conf/rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf 

# fail2ban
# todo: from fail2ban
RUN apk add fail2ban
RUN rm /etc/fail2ban/jail.d/alpine-ssh.conf

# start nginx and fail2ban. 
CMD ./usr/local/nginx/sbin/nginx -g 'daemon off;'
CMD [ "fail2ban-server", "-f", "-x", "-v", "start" ]

# expose 80 and 443 port for nginx
EXPOSE 80 443
