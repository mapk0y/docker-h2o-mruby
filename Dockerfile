FROM alpine:3.5

ENV URL         https://github.com/h2o/h2o/archive
# v2.0.5 can not build mruby
#  https://github.com/h2o/h2o/pull/1149/files
ENV H2O_VERSION 2.0.4

RUN set -ex \
        && apk add --no-cache --virtual .h2o-builddeps \
            openssl \
            cmake \
            make \
            gcc \
            libc-dev \
            g++ \
            zlib-dev \
            libuv-dev \
            wslay-dev \
            ruby \
            ruby-dev \
            git \
            bison \
            linux-headers \
    && wget -O - ${URL}/v${H2O_VERSION}.tar.gz | tar xzf - \
    && cd h2o-${H2O_VERSION} \
    && cmake -DWITH_BUNDLED_SSL=on -DWITH_MRUBY=on . \
    && make -j$(getconf _nprocessors_onln) \
    && make install \
    && runDeps="$( \
        scanelf --needed --nobanner --recursive /usr/local \
            | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
            | sort -u \
            | xargs -r apk info --installed \
            | sort -u \
    )" \
    && apk add --no-cache --virtual .h2o-rundeps $runDeps \
    && apk del .h2o-builddeps \
    && cd / \
    && rm -rf /h2o-${H2O_VERSION}
    
COPY h2o.conf /etc/h2o/
CMD ["h2o", "--conf", "/etc/h2o/h2o.conf"]
