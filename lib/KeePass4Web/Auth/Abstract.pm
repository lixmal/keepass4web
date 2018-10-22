package KeePass4Web::Auth::Abstract;
use strict;
use warnings;

# Abstract class for Auth backend

my @methods = qw/
    auth
    case_sensitive
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
