FROM ubuntu:18.04

WORKDIR /opt/keepass4web/
RUN apt-get update\
    # install build tools
    && apt -y install \
        npm \
        build-essential \
        libkeyutils-dev \
        libkeyutils1 \
        libmagic1 \
        libmagic-dev \
        libwww-perl \
        cpanminus \
        git \
    # get source
    && cd .. \
    && git clone https://github.com/lixmal/keepass4web \
    && cd keepass4web \
    # install perl dependencies
    && cpanm --installdeps . --with-all-features --with-recommends --with-suggests --notest --self-contained \
    # install js dependencies
    && npm install \ 
    && node_modules/.bin/gulp fonts \ 
    # build bundle.js
    && npm run build \
    && rm -rf node_modules \
    # remove build tools
    && apt -y purge \
        npm \
        build-essential \
        cpanminus \
        libmagic-dev \
        libkeyutils-dev \
        git \
    && apt -y autoremove \
    && apt -y clean \
    && rm -rf ~/.cpan* \
    # create dirs
    && mkdir /conf /var/log/keepass4web \
    && chmod o+w /var/log/keepass4web \
    # redirect logs to stdout
    && ln -s /dev/stdout /var/log/keepass4web/ \
    && sed -i 's/info.log/stdout/' config.yml \
    # move config to volume
    && mv config.yml /conf/
    
EXPOSE 8080

VOLUME ["/conf"]

STOPSIGNAL SIGTERM

USER nobody:nogroup

CMD ["env", "DANCER_CONFDIR=/conf", "plackup", "bin/app.psgi", "--host", "0.0.0.0", "--port", "8080"]
