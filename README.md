# KeePass4Web

An application which serves KeePass database entries on a web frontend.

Databases can be fetched from a configureable location (Filesystem, Seafile, Dropbox, ...).

Frontend authenticates users (LDAP, SQL, ...) before any database access is granted.

Written in Perl and JavaScript.

This will probably only run under some flavour of Linux. The instructions assume a Linux environment.


## PREREQUISITES


##### Libraries / Packages

- build-essential *(building C part of Kernel::Keyring and other XS modules)*
- libkeyutils-dev
- libkeyutils1
- libapache2-mod-perl2 *(if running mod_perl2 with apache2)*
- libmagic1
- libmagic-dev

##### Perl modules

###### Core
- Inline::C
- Dancer
- Dancer::Session::Cookie *(default session engine, `Cookie` in config)*
- IPC::ShareLite
- JSON
- JSON::XS *(for performance)*
- Plack *(if using mod_perl2 or fastcgi)*
- File::KeePass
- Bytes::Random::Secure
- Math::Random::ISAAC::XS *(recommended for performance)*
- File::LibMagic
- Sereal::Encoder
- Sereal::Decoder
- Crypt::Mode::CBC
- Crypt::Cipher::AES *(default cipher)*

###### LDAP
- Net::LDAP

###### Htpasswd
- Crypt::Eksblowfish::Bcrypt *(bcrypt)*
- Authen::Htpasswd  *(md5, sha1, crypt, plain)*

###### Seafile
- REST::Client

###### HTTP
- LWP::UserAgent

###### Bundled modules, may become external
- File::KeePass::Web
- Kernel::Keyring
- Auth::LDAP
- Seafile::Client::REST

Most modules can be taken from the disto, e.g. for Ubuntu 14.04:

- libinline-perl
- libdancer-perl
- libfile-keepass-perl
- libdancer-session-cookie-perl
- libipc-sharelite-perl
- libsereal-encoder-perl
- libsereal-decoder-perl
- libbytes-random-secure-perl
- libmath-random-isaac-xs-perl
- libplack-perl
- libjson-perl
- libjson-xs-perl
- libnet-ldap-perl

Remaining modules need to be installed from CPAN.
Alternatively you can get all modules in the most recent version from CPAN, although this will take quite some time to install.


For building the JavaScript part you will also need npm (version 3+ recommended, else your node_modules directory will explode!) and therefore `Node.js`


## INSTALL

- From source:
    - Clone the repo to some dir
        > git clone https://github.com/lixmal/keepass4web.git /opt/keepass4web/

        > cd /opt/keepass4web/

    - Follow `BUILDING`, `MODULE INSTALLATION`, `CONFIGURATION`, `DEPLOYMENT` in that order

- From dist tar:
    - Grab the latest tar from github: https://github.com/lixmal/keepass4web/releases
    - Untar it to some directory, e.g. /opt
    - Optionally rename it to keepass4web (for consistency with this README)
    - Follow `MODULE INSTALLATION`, `CONFIGURATION`, `DEPLOYMENT` in that order


## BUILDING

The minified, bundled file will be written to public/scripts/bundle.js

- Install Node/npm, e.g. for Ubuntu
    > sudo apt-get install npm

- Install js modules
    > npm install

- Copy bootstrap font files
    > node_modules/.bin/gulp fonts

- Build js bundle
    > npm run build

- For a non-uglified version you can run
    > npm run dev

## BUNDLING

Output will be a `KeePass4Web-{VERSION}.tar.gz` file, which includes all files required to run the app but without the development/build files

- Follow `BUILDING` first, then run the perl make file
    > perl Makefile.PL

- Bundle the app to a tar
    > make dist

- Clean up afterwards
    > make clean


## MODULE INSTALLATION

E.g. for Ubuntu 14.04 with mod_perl2:

##### Core

- Install disto packages
    > sudo apt-get install build-essential libkeyutils-dev libkeyutils1 libmagic1 libmagic-dev libapache2-mod-perl2 libinline-perl libdancer-perl libfile-keepass-perl libdancer-session-cookie-perl libbytes-random-secure-perl libmath-random-isaac-xs-perl libplack-perl libjson-xs-perl libjson-perl libipc-sharelite-perl libsereal-encoder-perl libsereal-decoder-perl

- Install remaining Perl modules via cpan, depending on cipher configuration
    > cpan Crypt::Mode::CBC Crypt::Cipher::AES File::LibMagic

##### LDAP
> sudo apt-get install libnet-ldap-perl

##### Htpasswd
> cpan Authen::Htpasswd Crypt::Eksblowfish::Bcrypt

##### Seafile
> cpan REST::Client

##### HTTP
> sudo apt-get install libwww-perl


## CONFIGURATION

- Copy or rename `config.yml.dist` to `config.yml`
    > cp config.yml.dist config.yml

- Change `session_cookie_key` to a **long** and **random** value if using `Cookie` in `session`, e.g.
    > pwgen -ysN1 128


## DEPLOYMENT

Running this app on a web server with mod_perl2 or fcgi is **recommended** but running as standalone app is possible as well (with Dancer's capabilities).

- Create the log directory (as defined in config.yml)
    > sudo mkdir /var/log/keepass4web/

- The directory the app lives in has to be readable by the user running the web server, e.g.
    > sudo chown -R root:www-data /opt/keepass4web/ /var/log/keepass4web/

    > chmod g+r -R /opt/keepass4web/

- Addtionally, it needs write permissions on the log directory, e.g.
    > chmod g+w /var/log/keepass4web/

- Remove permissions on sensitive data for everyone else
    > chmod o-rwx /opt/keepass4web/config.yml /var/log/keepass4web/

- Finally, give web server user acces to the .Inline directory to compile C files necessary for Kernel::Keyring
    > chmod g+w /opt/keepass4web/.Inline

- Optionally, run the compile process beforehand by loading the module once
    > cd /opt/keepass4web/

    > perl -MKernel::Keyring -Ilib -e ''

- For apache, enable the perl mod and ssl
    > sudo a2enmod perl

    > sudo a2enmod ssl

    > sudo a2ensite default-ssl


##### Running apache2 using mod_perl2/Plack with TLS:

Example config default-ssl:

```apache
# Initialises keyring session
PerlSetEnv KP_APPDIR /opt/keepass4web/.Inline
PerlSwitches -I/opt/keepass4web/lib/
PerlModule KeePass4Web::Apache2
PerlPostConfigHandler KeePass4Web::Apache2::post_config

<IfModule mod_ssl.c>
    <VirtualHost _default_:443>
    ServerName example.org

    SSLEngine on
    SSLCertificateFile    /etc/ssl/certs/ssl-cert-snakeoil.pem
    SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

    PerlOptions +Parent
    <Location /keepass/>
        SetHandler perl-script
        PerlResponseHandler Plack::Handler::Apache2
        PerlSetVar psgi_app /opt/keepass4web/bin/app.pl
    </Location>


    </VirtualHost>
</IfModule>
```


##### Using the standalone server on default port 8080

- Run (as correct user)
    > ./bin/app.pl


- As there is no TLS or IPv6, it is recommonded to run a front-end web server with reverse proxy, example config for apache:
    ```apache
    <IfModule mod_ssl.c>
        <VirtualHost _default_:443>
        ServerName example.org

        SSLEngine on
        SSLCertificateFile    /etc/ssl/certs/ssl-cert-snakeoil.pem
        SSLCertificateKeyFile /etc/ssl/private/ssl-cert-snakeoil.key

        ProxyPass        /keepass/ http://localhost:8080/
        ProxyPassReverse /keepass/ http://localhost:8080/


        </VirtualHost>
    </IfModule>
    ```

##### Open `https://<domain>/keepass/` (notice the trailing slash)


##### Refer to [Dancer::Deployment](http://search.cpan.org/dist/Dancer/lib/Dancer/Deployment.pod) for more options.

## BACKENDS

### Authentication

Credentials may be further passed to the database backend via `auth_reuse_cred` config option.
This way users don't have to enter their credentials twice (for auth backend and database backend) if they are identical.
Useful when the database backend server uses the same auth backend internally.

##### LDAP

Attempts to authenticate the user against an LDAP server (Microsoft AD, 389 Directory Server, OpenLDAP, ...)

##### SQL (planned)

##### Htpasswd

Authentication using apache htpasswd files.
Support for plain, sha1, crypt, md5 and bcrypt. Only bcrypt is considered secure.

##### PAM (planned)

### Database

##### Filesystem

Grabs the KeePass database from the local filesystem. No support for local key files if configured statically (in config.yml).
Can get database and key file location from auth backend.
Web server needs read access to the files.

##### Seafile

KeePass database is stored in the private cloud.

Locations for the database and the key file can be configured in config.yml (global for all users) or fetched from auth backend (individually per user).
Location syntax is '\<repository-id>/\<path-to-database>', see config.yml.dist for an example.

The server uses the (possibly auth backend) credentials to fetch a token from Seafile which is used for consequent requests.
No user credentials are saved anywhere at any time!

Right now the server does all Seafile requests. It is planned to migrate to a model where the client fetches the token from the Seafile server (if on the same domain) and passes it to the app server.
Logging into some service on behalf of the user is an anti-pattern, therefore it is not recommended for non private servers.

##### Dropbox (planned)

##### WebDAV (planned)

##### HTTP

Backend to fetch database from http, ftp or other (see [LWP NETWORK SUPPORT](http://search.cpan.org/dist/libwww-perl/lib/LWP.pm#NETWORK_SUPPORT)).
Supports per-user database and key file location from auth backend. No support for key files if configured statically (in config.yml).
Http basic auth is supported, but only globally (same for all users, even if urls differ). Otherwise it would be necessary to store the user credentials in the session, which might be not a good idea.
Database upload (saving) is only implemented for http right now.

Username and password may also be supplied in the form of `ftp://username:password@example.org`

## MISCELLANEOUS

- Show currently used shared segments
    > sudo ipcs

- Removing segments (effectively closing user databases)
    > sudo ipcrm -M `key`

- Show kernel keyrings in use (as root)
    > sudo cat /proc/keys

    > sudo cat/proc/key-users

- Adding users to .htpasswd, using bcrypt (needs apache2-utils)
    > touch .htpasswd               # create file

    > htpasswd -B .htpasswd <username>

    > sudo chown root:www-data .htpasswd # change group

    > chmod g+r,o-rwx .htpasswd     # remove permission of others, add read to webserver user


## LIMITATIONS

- KeePass databases are read only for now
- Caching of KeePass databases happens in SysV IPC shared memory, whose maximum size depends on the OS. Defined by `shmall` and `shmmni` kernel variables
    > sudo cat /proc/sys/kernel/shmmni

    > sudo cat /proc/sys/kernel/shmall
- Limits of kernel keyring apply
- Because right now all cached databases are seralised and deserialised together, more *simultaneously active* users will make fetching the database from IPC slower for every user. A better approach would be using one shared segment per user, which would make one roundtrip perpetual

## BUGS / CAVEATS / TODO

- Using mod_perl apache may create two kernel session keyrings, because it restarts directly after startup, effectively executing KeePass4Web::KeePass twice

- Log may have 'Key has been revoked' messages: happens when session keyring gets revoked once user (who (re)started the server) logs out. Please file a bug report in this case.

- Minor layout issues on the web frontend

- Loading masks for long running ajax requests missing

- Tests

- CSRF




## APP DETAILS / BACKGROUND
### Sequence of client/server operations

```
Client                                                       Server


Load website /
                              request KeePass tree
                              -------------------->

                                                        Check sesssion

                              not authenticated
                              <--------------------

Redirect to /user_login
Show credentials dialog

                              user credentials
                              -------------------->

                                                        User auth (LDAP, SQL, ...)

                                           login OK
                              <--------------------

Redirect to /backend_login
Show backend login dialog

                              backend credentials
                              -------------------->

                                                        Init DB backend / receive backend token
                                           login OK
                              <--------------------

Redirect to /db_login
Show KeePass password dialog

                              KeePass credentials
                              -------------------->
                                                        Possibly decrypt backend repo
                                                        Get KeePass database from backend
                                                        Possibly get Key file from backend
                                                        Decrypt KeePass database with master key + key file
                                                        Encrypt all password fields
                                                        Encrypt serialised string with newly generated key
                                                        Put encryption key into kernel keyring
                                                        Write keyring ids to session
                                                        Put encrypted database into IPC shared memory
                                      decryption OK
                              <--------------------

Redirect to /
                              request KeePass tree
                              -------------------->

                                                        Get database from IPC shared memory
                                                        Get encryption key from session
                                                        Decrypt database with key

                                  Send KeePass tree
                              <--------------------
Show KeePass tree

...

Password request by user
                              Request pw entry
                              -------------------->

                                                        Get keyring id from session
                                                        Get encryption key from kernel keyring
                                                        Get database from IPC shared memory
                                                        Decrypt database
                                                        Decrypt requested password

                                  Send pw entry
                              <--------------------
Show cleartext pw



...


Page reload

                              Request KeePass tree
                              -------------------->
                                                        Get database from IPC shared memory

                                  Send KeePass tree
                              <--------------------
Show KeePass tree

```
