package Kernel::Keyring;
use strict;
use warnings;

use Inline 'C';
use Inline C => Config => LIBS => '-lkeyutils';
use Exporter 'import';

Inline->init;

our $VERSION = 0.1.0;

our @EXPORT = qw/
    key_add
    key_get_by_id
    key_timeout
    key_unlink
    key_session
    key_perm
    key_revoke
/;

my %keyrings = (
    '@t'  => -1,  # KEY_SPEC_THREAD__key
    '@p'  => -2,  # KEY_SPEC_PROCESS__key
    '@s'  => -3,  # KEY_SPEC_SESSION__key
    '@u'  => -4,  # KEY_SPEC_USER__key
    '@us' => -5,  # KEY_SPEC_USER_SESSION__key
    '@g'  => -6,  # KEY_SPEC_GROUP__key
    '@a'  => -7,  # KEY_SPEC_REQKEY_AUTH_KEY
);


sub key_add {
    if (@_ != 4) {
        die "Wrong number of parameters\n";
    }
    my $keyring = $keyrings{$_[3]} or die "Unknown keyring: $_[3]\n";
    my $id = _key_add($_[0], $_[1], $_[2], length $_[2], $keyring);
    if ($id < 0) {
        die "Error adding key: $!\n"
    }
    return $id;
}

sub key_get_by_id {
    if (!$_[0]) {
        die "No key id given\n";
    }
    my ($ret, $key) = _key_read($_[0]);
    if ($ret < 0) {
        die "Error retieving key: $!\n"
    }
    return $key;
}

sub key_timeout {
    if (@_ != 2) {
        die "Wrong number of parameters\n";
    }
    my $ret = _key_timeout(@_);
    if ($ret < 0) {
        die "Error setting timeout: $!\n"
    }
    return $ret;
}

sub key_unlink {
    if (@_ != 2) {
        die "Wrong number of parameters\n";
    }
    my $keyring = $keyrings{$_[1]} or die "Unknown _key: $_[1]\n";
    my $ret = _key_unlink($_[0], $keyring);
    if ($ret < 0) {
        die "Error unlinking key: $!\n"
    }
    return $ret;
}

sub key_session {
    my $id = _key_session($_[0] || 'K::KR:' . int rand 2**32);
    if ($id < 0) {
        die "Error joining session: $!\n"
    }
    return $id;
}

sub key_perm {
    if (@_ != 2) {
        die "Wrong number of parameters\n";
    }
    my $ret = _key_perm(@_);
    if ($ret < 0) {
        die "Error setting permissions: $!\n"
    }
    return $ret;
}

sub key_revoke {
    if (@_ != 1) {
        die "Wrong number of parameters\n";
    }
    my $ret = _key_revoke(@_);
    if ($ret < 0) {
        die "Error revoking key: $!\n"
    }
    return $ret;
}


__DATA__
__C__

#include <keyutils.h>
#include <string.h>

// using int for key_serial_t and unsigned for key_perm_t,
// as perl doesn't know those and there is no typemap yet

int _key_add(char* type, char* desc, char* data, int datalen, int keyring) {
	return add_key(type, desc, data, datalen, keyring);
}

void _key_read(int key_id) {
    Inline_Stack_Vars;
	void* key = NULL;
	int ret = keyctl_read_alloc(key_id, &key);

    Inline_Stack_Reset;
    Inline_Stack_Push(sv_2mortal(newSViv(ret)));
    if (key != NULL)
        Inline_Stack_Push(sv_2mortal(newSVpv(key, ret)));
    Inline_Stack_Done;
}

long _key_timeout(int key_id, unsigned int timeout) {
    return keyctl_set_timeout(key_id, timeout);
}

long _key_unlink(int key_id, int keyring) {
    return keyctl_unlink(key_id, keyring);
}

int _key_session(char* desc) {
    return keyctl_join_session_keyring(desc);
}

long _key_perm(int key_id, unsigned int perm) {
    return keyctl_setperm(key_id, perm);
}

long _key_revoke(int key_id) {
    return keyctl_revoke(key_id);
}

