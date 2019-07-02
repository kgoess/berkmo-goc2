package GoC::Controller;

use strict;
use warnings;

use CGI::Cookie;
use Data::Dump qw/dump/;

use GoC::Model::Person;
use GoC::View;

my %handler_for_path = (
    '' => sub { shift->main_page(@_) },
    '/' => sub { shift->main_page(@_) },
    '/logout' => sub { shift->logout(@_) },
    '/login' => sub { shift->login_page(@_) },
    '/event' => sub { shift->event_page(@_) },
);

sub go {
    my ($class, %p) = @_;

    # this is wrong, but need a way to get past these if it's a login POST
    my $is_login_attempt = $p{method} eq 'POST' && $p{path_info} eq '/login';

    if (! $is_login_attempt) {

        if (! $p{headers}{Cookie}) {
            return { 
                action => 'display',
                content => GoC::View->login_page(),
            };
        }
        my $cookies = CGI::Cookie->parse($p{headers}{Cookie});
        if (! $cookies->{'Berkmo-GoC'}) {
            return { 
                action => 'display',
                content => GoC::View->login_page(),
            };
        }
        my ($id) = $cookies->{'Berkmo-GoC'}->value =~ /user_id:([0-9]+)/
            or die "can't parse cookie: $cookies->{'Berkmo-GoC'}";

        my $current_user = GoC::Model::Person->load($id)
            or die "no user found for id $id";;

        $p{current_user} = $current_user;
    }
    if (my $handler = $handler_for_path{ $p{path_info} }) {
        return $handler->($class, %p),
    } else {
        die "missing handler for '$p{path_info}'";
    }
}


sub login_page {
    my ($class, %p) = @_;

    if ($p{method} eq 'GET') {
        return {
            action => 'display',
            content => GoC::View->login_page(),
        }

    } elsif ($p{method} eq 'POST') {
        my $id = $p{request}->param('login_id')
            or die "missing login_id";

        my $person = GoC::Model::Person->load($id)
            or die "no user found for id $id";;

         my $cookie = CGI::Cookie->new(
            -name  => 'Berkmo-GoC',
            -value => "user_id:$id",
         #   -expires => '-1y',
         );
        return {
            action => 'redirect', 
            headers => {
                Location  => "/goc2",
            },
            cookie => $cookie,
        };
    } else {
        die "unrecognized method $p{method} in call to login_page";
    }

}

sub logout {
     my $cookie = CGI::Cookie->new(
        -name  => 'Berkmo-GoC',
        -expires => '-1y',
        -value => 'whatever',
     );
    return {
        action => 'redirect', 
        headers => {
            Location  => "/goc2",
        },
        cookie => $cookie,
    };
}

sub main_page {
    my ($class, %p) = @_;
    return {
        action => "display",
        content => GoC::View->main_page(
            current_user => $p{current_user},
        ),
    }
}

sub event_page {
    my ($class, %p) = @_;
    return {
        action => "display",
        content => GoC::View->event_page(
            event_id => $p{request}->param('id'), # an Apache2::Request object
            current_user => $p{current_user},
        ),
    }
}

1;
