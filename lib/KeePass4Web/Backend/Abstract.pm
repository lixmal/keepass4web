package KeePass4Web::Backend::Abstract;
use strict;
use warnings;

# Abstract class for KeePass database backends

my @methods = qw/
    get_key
    get_db
    put_db
    credentials_init
    credentials_tpl
    authenticated
/;

sub new {
    my ($class, @args) = @_;
    my $self = bless {}, $class;

    $self->init(@args);
    $self->check_interface;
    return $self;
}

sub init { die 'Init not implemented' }

sub check_interface {
    my ($self) = @_;
    foreach my $method (@methods) {
        $self->can($method) or die "Method $method not implemented";
    }
}

1;
