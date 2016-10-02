package Seafile::Client::REST;
use strict;
use warnings;

use REST::Client;
use JSON;
use URI::Escape;

use constant OK                          => 200;
use constant CREATED                     => 201;
use constant ACCEPTED                    => 202;
use constant MOVED_PERMANENTLY           => 301;
use constant BAD_REQUEST                 => 400;
use constant FORBIDDEN                   => 403;
use constant NOT_FOUND                   => 404;
use constant CONFLICT                    => 409;
use constant TOO_MANY_REQUESTS           => 429;
use constant REPO_PASSWD_REQUIRED        => 440;
use constant REPO_PASSWD_MAGIC_REQUIRED  => 441;
use constant INTERNAL_SERVER_ERROR       => 500;
use constant OPERATION_FAILED            => 520;

use constant API                         => 'api2/';

our $VERSION = 0.1;

BEGIN {
    require Exporter;
    our @ISA = 'Exporter';
    our @EXPORT = qw/
        OK
        CREATED
        ACCEPTED
        MOVED_PERMANENTLY
        BAD_REQUEST
        FORBIDDEN
        NOT_FOUND
        CONFLICT
        TOO_MANY_REQUESTS
        REPO_PASSWD_REQUIRED
        REPO_PASSWD_MAGIC_REQUIRED
        INTERNAL_SERVER_ERROR
        OPERATION_FAILED
    /;
}


sub new {
    my ($class, %args) = @_;

    my $token = delete $args{token};

    my $client = REST::Client->new(%args);

    # JSON doesn't seem to work with all API calls, so we stick to form encoded
    $client->addHeader('Content-Type', 'application/x-www-form-urlencoded; charset=utf-8');

    $client->addHeader('Accept', 'application/json; charset=utf-8');

    $client->addHeader('Authorization', "Token $token") if $token;

    return bless {
        client       => $client,
        token        => $token,
        error        => undef,
        code         => undef,
        location     => undef,
        json         => JSON->new->allow_nonref,
    }, $class;
}

sub ua {
    return shift->{client}->getUseragent;
}

sub error {
    return shift->{error};
}

sub code {
    return shift->{code};
}

sub token {
    return shift->{token}
}

sub location {
    return shift->{location};
}

sub _errhandler {
    my $self = shift;

    my $client = $self->{client};

    my $content = eval { $self->{json}->decode($client->responseContent) };
    # SF doesn't return any JSON when trying to access a download link and repo decryption expired
    if ($@ && $client->responseContent =~ /^Repo is encrypted/i) {
        $content = { error_msg => $client->responseContent };
        chomp $content->{error_msg};
    }

    my $code = $self->{code} = $client->responseCode;
    $self->{location} = $client->responseHeader('Location') if $client->responseHeader('Location');
    if ($code >= 400) {
        $self->{error} =
            ($content->{error_msg} ? " $content->{error_msg}" : '')
            . ($content->{detail} ? " $content->{detail}" : '');

        die $content->{error_msg} || $content->{detail} || 'Request failed', "\n";
    }
    $self->{error} = undef;

    return $content;
}

sub _request {
    my ($self, $method, $url, $params) = @_;

    my $client = $self->{client};

    $params = $client->buildQuery($params);
    if ($method =~ /^(?:PUT|PATCH|POST)$/) {
        # remove first question mark from query since it goes into the body
        $params =~ s/^.//;
        $client->request($method, API . $url, $params);
    }
    else {
        $client->request($method, API . "$url$params");
    }

    return $self->_errhandler;
}

sub init {
    my $self = shift;
    my %args = @_;
    my $content = $self->_request('POST', 'auth-token/', \%args);

    $self->{client}->addHeader('Authorization', "Token $content->{token}");
    $self->{token} = $content->{token};

    return $self;
}

sub ping {
    return shift->_request('GET', 'ping/');
}

sub authping {
    return shift->_request('GET', 'auth/ping/');
}

sub accounts {
    return shift->_request('GET', 'accounts/');
}

sub account_info {
    my $self = shift;
    my %params = @_;
    my $email = uri_escape_utf8 delete $params{email};
    return $self->_request('GET', "accounts/$email/")
}

sub check_account_info {
    return shift->_request('GET', 'account/info/');
}

sub create_account {
    my $self = shift;
    my %params = @_;
    my $email = uri_escape_utf8 delete $params{email};
    return $self->_request('PUT', "accounts/$email/", \%params)
}

sub update_account {
    my $self = shift;
    my %params = @_;
    my $email = uri_escape_utf8 delete $params{email};
    return $self->_request('PUT', "accounts/$email/", \%params)
}

sub delete_account {
    my $self = shift;
    my %params = @_;
    my $email = uri_escape_utf8 delete $params{email};
    return $self->_request('DELETE', "accounts/$email/")
}

sub server_info {
    return shift->_request('GET', 'server-info/');
}

sub starred_files {
    return shift->_request('GET', 'starredfiles/');
}

sub star_file {
    my $self = shift;
    my %params = @_;
    return $self->_request('POST', "starredfiles/", \%params)
}

sub unstar_file {
    my $self = shift;
    my %params = @_;
    return $self->_request('DELETE', "starredfiles/", \%params)
}

sub user_messages {
    my $self = shift;
    my %params = @_;
    my $id_or_email = uri_escape_utf8 delete $params{id_or_email};
    return $self->_request('GET', "user/msgs/$params{id_or_email}/")
}

sub reply_user_message {
    my $self = shift;
    my %params = @_;
    my $id_or_email = uri_escape_utf8 delete $params{id_or_email};
    return $self->_request('POST', "user/msgs/$id_or_email/", \%params)
}

sub unseen_messages {
    my $self = shift;
    return $self->_request('GET', "unseen_messages/")
}
sub groups {
    my $self = shift;
    return $self->_request('GET', "groups/")
}

sub add_group {
    my $self = shift;
    my %params = @_;
    return $self->_request('PUT', "groups/", \%params)
}

sub delete_group {
    my $self = shift;
    my %params = @_;
    my $group_id = uri_escape_utf8 delete $params{group_id};
    return $self->_request('DELETE', "groups/$group_id/")
}

sub rename_group {
    my $self = shift;
    my %params = @_;
    $params{operation} = 'rename';
    my $group_id = uri_escape_utf8 delete $params{group_id};
    return $self->_request('POST', "groups/$group_id/", \%params)
}

sub add_group_member {
    my $self = shift;
    my %params = @_;
    my $group_id = uri_escape_utf8 delete $params{group_id};
    return $self->_request('PUT', "groups/$group_id/members/", \%params)
}

sub delete_group_member {
    my $self = shift;
    my %params = @_;
    my $group_id = uri_escape_utf8 delete $params{group_id};
    return $self->_request('DELETE', "groups/$group_id/members/", \%params)
}

sub group_messages {
    my $self = shift;
    my %params = @_;
    my $group_id = uri_escape_utf8 delete $params{group_id};
    return $self->_request('GET', "group/msgs/$group_id/")
}


sub group_message_detail {
    my $self = shift;
    my %params = @_;
    my $group_id = uri_escape_utf8 $params{group_id};
    my $msg_id = uri_escape_utf8 delete $params{msg_id};
    return $self->_request('GET', "group/$group_id/msg/$msg_id/")
}

sub send_group_message {
    my $self = shift;
    my %params = @_;
    my $group_id = uri_escape_utf8 delete $params{group_id};
    return $self->_request('POST', "group/msgs/$group_id/", \%params)
}

sub reply_group_message {
    my $self = shift;
    my %params = @_;
    my $group_id = uri_escape_utf8 delete $params{group_id};
    my $msg_id   = uri_escape_utf8 delete $params{msg_id};
    return $self->_request('POST', "group/$group_id/msg/$msg_id/", \%params)
}

sub group_message_replies {
    return shift->_request('GET', 'new_replies/')
}

sub shared_links {
    return shift->_request('GET', 'shared-links/')
}

sub create_share_link {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('PUT', "repos/$repo_id/file/shared-link/", \%params)
}

sub delete_share_link {
    my $self = shift;
    my %params = @_;
    return $self->_request('DELETE', "shared-links/", \%params)
}

sub list_direntry {
    my $self = shift;
    my %params = @_;
    my $token = uri_escape_utf8 delete $params{'token'};
    return $self->_request('GET', "d/$token/dir/", \%params)
}

sub shared_libraries {
    return shift->_request('GET', 'shared-repos/')
}

sub be_shared_libraries {
    return shift->_request('GET', 'shared-repos/')
}

sub share_library {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('PUT', "shared-repos/$repo_id/", \%params)
}

sub unshare_library {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('DELETE', "shared-repos/$repo_id/", \%params)
}

sub shared_files {
    return shift->_request('GET', 'shared-files/')
}

sub download_shared_file {
    my $self = shift;
    my %params = @_;
    my $token = uri_escape_utf8 delete $params{token};
    return $self->_request('GET', "f/$token/", \%params)
}

sub shared_file_detail {
    my $self = shift;
    my %params = @_;
    my $token = uri_escape_utf8 delete $params{token};
    return $self->_request('GET', "f/$token/detail/", \%params)
}

sub delete_shared_file {
    my $self = shift;
    my %params = @_;
    return $self->_request('DELETE', "shared-files/", \%params)
}

sub download_private_shared_file {
    my $self = shift;
    my %params = @_;
    my $token = uri_escape_utf8 delete $params{token};
    return $self->_request('GET', "s/f/$token/", \%params)
}

sub private_shared_file_detail {
    my $self = shift;
    my %params = @_;
    my $token = uri_escape_utf8 delete $params{token};
    return $self->_request('GET', "s/f/$token/detail/", \%params)
}

sub default_library {
    return shift->_request('GET', 'default-repo/')
}

sub create_default_library {
    return shift->_request('POST', 'default-repo/')
}

sub libraries {
    return shift->_request('GET', 'repos')
}

sub library_info {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/")
}

sub library_owner {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/owner/")
}

sub library_history {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/history/")
}

sub create_library {
    my $self = shift;
    my %params = @_;
    return $self->_request('POST', 'repos/', \%params)
}

sub check_sub_library {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('POST', "repos/$repo_id/dir/sub_repo/", \%params)
}

sub delete_library {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('DELETE', "repos/$repo_id/")
}

sub decrypt_library {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('POST', "repos/$repo_id/", \%params)
}

sub create_public_library {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('POST', "repos/$repo_id/public/")
}

sub remove_public_library {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('DELETE', "repos/$repo_id/public/")
}

sub library_download_info {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/download-info/")
}

sub virtual_libraries {
    return shift->_request('GET', 'virtual-repos')
}

sub search_libraries {
    my $self = shift;
    my %params = @_;
    return $self->_request('GET', 'search/', \%params)
}

sub download_file {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    my $url = $self->_request('GET', "repos/$repo_id/file/", \%params);

    $self->{location} = $url;
    # strip host from url, it's already set by Rest::Client
    $url =~ s/^[^:]+:\/\/[^\/]+\///;

    $self->{client}->request('GET', $url);
    $self->_errhandler;

    return \$self->{client}->responseContent;
}

sub file_info {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/file/detail/", \%params)
}

sub file_history {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/file/history/", \%params)
}

sub download_file_revision {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/file/revision/", \%params)
}

sub create_file {
    my $self = shift;
    my %params = @_;
    $params{operation} = 'create';
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('POST', "repos/$repo_id/file/", \%params)
}

sub rename_file {
    my $self = shift;
    my %params = @_;
    $params{operation} = 'rename';
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('POST', "repos/$repo_id/file/", \%params)
}

sub lock_file {
    my $self = shift;
    my %params = @_;
    $params{operation} = 'lock';
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('PUT', "repos/$repo_id/file/", \%params)
}

sub unlock_file {
    my $self = shift;
    my %params = @_;
    $params{operation} = 'unlock';
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('PUT', "repos/$repo_id/file/", \%params)
}

sub move_file {
    my $self = shift;
    my %params = @_;
    $params{operation} = 'move';
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('POST', "repos/$repo_id/file/", \%params)
}

sub copy_file {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('POST', "repos/$repo_id/fileops/copy/", \%params)
}

sub revert_file {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('PUT', "repos/$repo_id/file/revert/", \%params)
}

sub delete_file {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('DELETE', "repos/$repo_id/file/", \%params)
}

sub upload_link {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/upload-link/", \%params)
}

sub update_link {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/update-link/")
}

sub upload_blocks_link {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/upload-blks-link/")
}

sub update_blocks_link {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/update-blks-link/")
}

sub directory_entries {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/dir/", \%params)
}

sub create_directory {
    my $self = shift;
    my %params = @_;
    $params{operation} = 'mkdir';
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('POST', "repos/$repo_id/dir/", \%params)
}

sub rename_directory {
    my $self = shift;
    my %params = @_;
    $params{operation} = 'rename';
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('POST', "repos/$repo_id/dir/", \%params)
}

sub delete_directory {
    my $self = shift;
    my %params = @_;
    $params{operation} = 'rename';
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('DELETE', "repos/$repo_id/dir/", \%params)
}

sub download_directory {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/dir/download/", \%params)
}

sub share_directory {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('POST', "repos/$repo_id/dir/share/", \%params)
}

sub user_avatar {
    my $self = shift;
    my %params = @_;
    my $user = uri_escape_utf8 delete $params{'user'};
    my $size = uri_escape_utf8 delete $params{'size'};
    return $self->_request('GET', "avatars/user/$user/resized/$size/")
}

sub group_avatar {
    my $self = shift;
    my %params = @_;
    my $group_id = uri_escape_utf8 delete $params{'group_id'};
    my $size     = uri_escape_utf8 delete $params{'size'};
    return $self->_request('GET', "avatars/group/$group_id/resized/$size/")
}

sub thumbnail_image {
    my $self = shift;
    my %params = @_;
    my $repo_id = uri_escape_utf8 delete $params{'repo-id'};
    return $self->_request('GET', "repos/$repo_id/thumbnail/", \%params)
}

sub groupandcontacts {
    return shift->_request('GET', 'groupandcontacts/');
}

sub file_activities {
    return shift->_request('GET', 'events/');
}

sub add_organization {
    my $self = shift;
    my %params = @_;
    return $self->_request('POST', 'organization/', \%params)
}

1;
