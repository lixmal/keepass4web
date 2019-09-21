FROM alpine

WORKDIR /opt/keepass4web/
RUN apk add --update --no-cache --virtual .build-deps \
    # install build tools
        npm \
        alpine-sdk \
        perl-app-cpanminus \
        perl-dev \
        git \
        # Kernel::Keyring
        keyutils-dev \
        # File::Magic
        file-dev \
        # GSSAPI
        krb5-dev \
        # LWP
        libressl-dev \
        # LWP
        zlib-dev \
        # XML::Parser
        expat-dev \
        # Term::ReadLine::Gnu
        ncurses-dev \
        # Term::ReadLine::Gnu
        readline-dev \
        # fixing some circular dependency problem
        perl-libwww \
    # install libs
    && apk add --no-cache \
        perl \
        # Kernel::Keyring
        keyutils-libs \
        # File::Magic
        libmagic \
        # GSSAPI
        krb5-libs \
        # XML::Parser
        expat \
        # LWP
        libressl \
        # LWP
        zlib \
        # Term::ReadLine::Gnu
        ncurses-libs \
        # Term::ReadLine::Gnu
        readline \
    # get source
    && cd .. \
    && git clone https://github.com/lixmal/keepass4web \
    && cd keepass4web \
    # install perl dependencies
    && cpanm --no-wget --installdeps . --with-all-features --with-recommends --with-suggests --notest --self-contained \
    # install js dependencies
    && npm install \
    && node_modules/.bin/gulp fonts \
    # build bundle.js
    && npm run build \
    && rm -rf node_modules \
    # remove build tools
    && apk del --purge .build-deps \
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

ENV DANCER_CONFDIR /conf

CMD ["plackup", "bin/app.psgi", "--host", "0.0.0.0", "--port", "8080"]
