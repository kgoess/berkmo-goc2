package GoC::Controller;

use strict;
use warnings;

use CGI::Cookie;
use Data::Dump qw/dump/;

use GoC::Model::Person;
use GoC::Model::PersonEventMap;
use GoC::View;

my %handler_for_path = (
    ''               => sub { shift->main_page(@_) },
    '/'              => sub { shift->main_page(@_) },
    '/logout'        => sub { shift->logout(@_) },
    '/login'         => sub { shift->login_page(@_) },
    '/event'         => sub { shift->event_page(@_) },
    '/change-status' => sub { shift->change_status(@_) },
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

sub change_status {
    my ($class, %p) = @_;

    my $person_id = $p{request}->param('person_id')
        or die "missing person_id";

    my $person = GoC::Model::Person->load($person_id)
        or die "no user found for id $person_id";

    my $event_id = $p{request}->param('event_id')
        or die "missing event_id";

    my $event = GoC::Model::Event->load($event_id)
        or die "no event found for id $event_id";

    my $for_role = $p{request}->param('for_role')
        or die "missing for_role";

    $for_role =~ /^(?:muso|dancer)$/
        or die "wrong value for role: $for_role";

    my $status = $p{request}->param('status')
        or die "missing status";

    $status =~ /^[yn?]$/
        or die "wrong value for status: $status";

    GoC::Model::PersonEventMap->delete_person_from_event($person, $event);
    GoC::Model::PersonEventMap->add_person_to_event($person, $event, $for_role, $status);

    return {
        action => 'redirect', 
        headers => {
            Location  => "/goc2/event?id=$event_id",
        },
    };


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
