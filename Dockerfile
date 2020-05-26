FROM alpine AS build

WORKDIR /workspace

COPY src src
COPY package*.json config.yml ./
COPY public public

RUN apk add --no-cache npm \
    && npm install \
    && cp node_modules/bootstrap/fonts/* public/fonts/ \
    && rm public/dispatch* \
    # build bundle.js
    && npm run build


FROM alpine

WORKDIR /keepass4web

COPY cpanfile .
COPY bin bin
COPY lib lib
COPY --from=build /workspace/public /keepass4web/public
COPY --from=build /workspace/config.yml /conf/

RUN apk add --no-cache --virtual .build-deps \
    # install build tools
        alpine-sdk \
        perl-app-cpanminus \
        perl-dev \
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
    # install perl dependencies
    && cpanm --no-wget --installdeps . --with-all-features --with-recommends --with-suggests --notest --self-contained \
    # remove build tools
    && apk del --purge .build-deps \
    && rm -rf ~/.cpan* cpanfile \
    # redirect logs to stdout
    && sed -i "s/logger: 'File'/logger: 'Console'/" /conf/config.yml

EXPOSE 8080

VOLUME /conf

STOPSIGNAL SIGTERM

USER nobody:nogroup

ENV DANCER_CONFDIR /conf

CMD ["plackup", "bin/app.psgi", "--host", "0.0.0.0", "--port", "8080"]
