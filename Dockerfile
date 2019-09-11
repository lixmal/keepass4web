FROM ubuntu:18.04

WORKDIR /opt/
RUN apt-get update\
    && apt -y install \
    node-gyp \
    nodejs-dev \
    npm \
    build-essential \
    libkeyutils-dev \
    libkeyutils1 \
    libmagic1 \
    libmagic-dev \
    libwww-perl \
    cpanminus \
    git \
    && git clone https://github.com/lixmal/keepass4web \
    && cd keepass4web \
    && cpanm --installdeps . --with-all-features --with-recommends --with-suggests --notest \
    && npm install \ 
    && node_modules/.bin/gulp fonts \ 
    && npm run build \
    && rm -rf node_modules \
    && apt -y purge \
    npm \
    build-essential \
    cpanminus \
    libmagic-dev \
    libkeyutils-dev \
    && apt -y autoremove \
    && apt -y clean \
    && rm -rf ~/.cpan*
    
EXPOSE 8080

VOLUME ["/conf"]

STOPSIGNAL SIGTERM

USER nobody:nogroup
CMD ["plackup", "bin/app.psgi", "--host", "localhost", "--port", "8080"]
