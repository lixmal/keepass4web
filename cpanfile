requires 'YAML',                        0;
recommends 'YAML::XS',                  0;
requires 'Inline::C',                   0;
requires 'Dancer2',                     0;
requires 'Dancer2::Plugin::Ajax',       0;
requires 'Dancer2::Core::Time',         0;
suggests 'Dancer2::Session::Cookie',    0;
requires 'IPC::ShareLite',              0;
requires 'JSON',                        0;
recommends 'JSON::XS',                  0;
requires 'File::KeePass',               0;
requires 'Crypt::URandom',              0;
recommends 'Math::Random::ISAAC::XS',   0;
requires 'File::LibMagic',              1.07;
requires 'Sereal::Encoder',             0;
requires 'Sereal::Decoder',             0;
requires 'Crypt::Mode::CBC',            0;
recommends 'Crypt::Cipher::AES',        0;
requires 'URI::Escape',                 0;
requires 'MIME::Base64',                0;
requires 'Encode',                      0;
recommends 'Class::Load::XS',           0;
recommends 'URL::Encode::XS',           0;
recommends 'CGI::Deurl::XS',            0;
recommends 'HTTP::Parser::XS',          0;
recommends 'Scope::Upper',              0;
recommends 'Class::XSAccessor',         0;
recommends 'HTTP::XSCookies',           0;
recommends 'HTTP::XSHeaders',           0;

# explicit requirements of File::KeePass::Web
requires   'Digest::SHA',               0;
requires   'Crypt::Mode::CBC',          0;
requires   'Crypt::Rijndael',           0;

on 'test', sub {
    requires 'Test::More',            0;
    requires 'Plack::Test',           0;
    requires 'HTTP::Request::Common', 0;
    requires 'Crypt::URandom',        0;
    requires 'Encode',                0;
    requires 'MIME::Base64',          0;
    requires 'JSON',                  0;
};

feature 'LDAP', 'LDAP authentication backend' => sub {
    requires 'Net::LDAP',       0;
    requires 'Net::LDAP::Util', 0;
};

feature 'Htpasswd', 'Htpasswd authentication backend' => sub {
    requires 'Crypt::Eksblowfish::Bcrypt', 0;
    requires 'Authen::Htpasswd',           0;
};

feature 'Seafile', 'Seafile database backend' => sub {
    requires 'REST::Client', 0;
    requires 'URI::Escape',  0;
};

feature 'LWP', 'LWP database backend' => sub {
    requires 'LWP::UserAgent',        0;
    requires 'HTTP::Request::Common', 0;
    requires 'URI::Escape',           0;
    requires 'Encode',                0;
};

feature 'Dropbox', 'Dropbox database backend' => sub {
    requires 'WebService::Dropbox', 0;
};
