package GoC::Controller;

use strict;
use warnings;

use Carp qw/croak/;
use CGI::Cookie;
use Data::Dump qw/dump/;

use GoC::Logger;
use GoC::Model::Event;
use GoC::Model::Person;
use GoC::Model::PersonEventMap;
use GoC::Utils qw/uri_escape/;

my %handler_for_path = (
    ''               => sub { shift->main_page(@_) },
    '/'              => sub { shift->main_page(@_) },
    '/admin/logs'    => sub { shift->activity_logs(@_) },
    '/event'         => sub { shift->event_page(@_) },
    '/logout'        => sub { shift->logout(@_) },
    '/login'         => sub { shift->login_page(@_) },
    '/change-status' => sub { shift->change_status(@_) },
    '/create-event'  => sub { shift->create_event(@_) },
    '/edit-event'    => sub { shift->edit_event(@_) },
    '/delete-event'  => sub { shift->delete_event(@_) },
    '/create-person' => sub { shift->create_person(@_) },
    '/edit-person'   => sub { shift->edit_person(@_) },
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
        $p{logger} = GoC::Logger->new(current_user => $current_user);
    }
    if (my $handler = $handler_for_path{ $p{path_info} }) {
        return $handler->($class, %p),
    } else {
        die "missing handler for '$p{path_info}'";
    }
}

# when either GoC::Controller::ModPerl or Goc::Controller::CGI loads
# this module, Perl calls this import() function and we set the location
# of the uri_for implementation
sub import {
    my ($class, $location) = @_;

    return unless $location;

    no warnings 'redefine';

    my $uri_for_implementation = join '::', $location, 'uri_for';
    *uri_for = \&{$uri_for_implementation};

    my $static_uri_for_implementation = join '::', $location, 'static_uri_for';
    *static_uri_for = \&{$static_uri_for_implementation};
}

sub uri_for { ... }
sub static_uri_for { ... }

sub login_page {
    my ($class, %p) = @_;

    if ($p{method} eq 'GET') {
        return {
            action => 'display',
            content => GoC::View->login_page(),
        }

    } elsif ($p{method} eq 'POST') {
        my $id = scalar($p{request}->param('login_id'))
            or die "missing login_id";

        my $person = GoC::Model::Person->load($id)
            or die "no user found for id $id";;

         my $cookie = CGI::Cookie->new(
            -name  => 'Berkmo-GoC',
            -value => "user_id:$id",
         #   -expires => '-1y',
         );

        GoC::Logger->new(current_user => $person)->debug("logged in");
        return {
            action => 'redirect',
            headers => {
                Location  => uri_for(path => "/"),
            },
            cookie => $cookie,
        };
    } else {
        die "unrecognized method $p{method} in call to login_page";
    }

}

sub change_status {
    my ($class, %p) = @_;

    my $person_id = scalar($p{request}->param('person_id'))
        or die "missing person_id";

    my $person = GoC::Model::Person->load($person_id)
        or die "no user found for id $person_id";

    my $event_id = scalar($p{request}->param('event_id'))
        or die "missing event_id";

    my $event = GoC::Model::Event->load($event_id)
        or die "no event found for id $event_id";

    my $for_role = scalar($p{request}->param('for_role'))
        or die "missing for_role";

    $for_role =~ /^(?:muso|dancer)$/
        or die "wrong value for role: $for_role";

    my $status = scalar($p{request}->param('status'))
        or die "missing status";

    $status =~ /^[yn?]$/
        or die "wrong value for status: $status";

    GoC::Model::PersonEventMap->delete_person_from_event($person, $event);
    GoC::Model::PersonEventMap->add_person_to_event($person, $event, $for_role, $status);

    my $person_log_str = join '', $person->name, '[', $person->id, ']';
    my $event_log_str  = join '', $event->name,  '[', $event->id, ']';
    $p{logger}->info("status change $person_log_str for event $event_log_str for role $for_role to status $status");

    return {
        action => 'redirect',
        headers => {
            Location  => uri_for(path => "/event", id => $event_id),
        },
    };


}

sub logout {
    my ($class, %p) = @_;
     my $cookie = CGI::Cookie->new(
        -name  => 'Berkmo-GoC',
        -expires => '-1y',
        -value => 'whatever',
     );
    $p{logger}->debug("logged out") ;
    return {
        action => 'redirect',
        headers => {
            Location => uri_for(path => '/'),
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
            message => scalar($p{request}->param('message')),
        ),
    }
}

sub event_page {
    my ($class, %p) = @_;
    return {
        action => "display",
        content => GoC::View->event_page(
            event_id => scalar($p{request}->param('id')), # an Apache2::Request object
            current_user => $p{current_user},
        ),
    }
}

sub activity_logs {
    my ($class, %p) = @_;
    return {
        action => "display",
        content => GoC::View->activity_logs(
            current_user => $p{current_user},
        ),
    }
}

package EmptyRequest {
    sub new { return bless {} };
    sub param {};
}

sub create_event {
    my ($class, %p) = @_;
    if ($p{method} eq 'GET') {
        return {
            action => 'display',
            content => GoC::View->create_event_page(
                current_user => $p{current_user},
                request => EmptyRequest->new(),
            ),
        }

    } elsif ($p{method} eq 'POST') {

        my @errors;
        foreach my $f (qw/event-name event-date event-type/) {
            if (! scalar($p{request}->param($f))) {
                push @errors, "missing data for $f";
            }
        }
        my $event_date = scalar($p{request}->param('event-date')) // '';
        if ($event_date !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}/) {
                push @errors, "wrong format for event-date, should be yyyy-mm-dd, not '$event_date'";
        }
        if (my $email = scalar($p{request}->param('event-notification-email'))) {
            if ($email !~ /^[^@]+@[^@]+$/) {
                push @errors, "that doesn't look like an email to me";
            }
        }
        if (@errors) {
            return {
                action => 'display',
                content => GoC::View->create_event_page(
                    current_user => $p{current_user},
                    errors       => \@errors,
                    request      => $p{request},
                ),
            }
        }

        my $r = $p{request};
        my $event = GoC::Model::Event->new(
            name => scalar($r->param('event-name')),
            date => scalar($r->param('event-date')),
            queen => scalar($r->param('event-queen')),
            notification_email => scalar($r->param('event-notification-email')),
            type => scalar($r->param('event-type')),
            notes => scalar($r->param('event-notes')),
        );
        $event->save;

        my $user = $p{current_user};
        my $person_log_str = join '', $user->name, '[', $user->id, ']';
        my $event_log_str  = join '', $event->name,  '[', $event->id, ']';
        $p{logger}->info("created event $event_log_str by $person_log_str");

        my $msg = uri_escape("Event successfully created");
        return {
            action => 'redirect',
            headers => {
                Location => uri_for( path => '/', message => $msg),
            },
        };
    }
}

sub edit_event {
    my ($class, %p) = @_;
    if ($p{method} eq 'GET') {
        return {
            action => 'display',
            content => GoC::View->edit_event_page(
                current_user => $p{current_user},
                event_id => scalar($p{request}->param('event-id')),
                request => EmptyRequest->new(),
            ),
        }

    } elsif ($p{method} eq 'POST') {

        croak "missing event-id in POST to edit_event"
            unless scalar($p{request}->param('event-id'));

        my @errors;
        foreach my $f (qw/event-name event-date event-type/) {
            if (! scalar($p{request}->param($f))) {
                push @errors, "missing data for $f";
            }
        }
        if (scalar($p{request}->param('event-date'))  !~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}/) {
                push @errors, "wrong format for event-date, should be yyyy-mm-dd";
        }
        if (my $email = scalar($p{request}->param('event-notification-email'))) {
            if ($email !~ /^[^@]+@[^@]+$/) {
                push @errors, "that doesn't look like an email to me";
            }
        }
        if (@errors) {
            return {
                action => 'display',
                content => GoC::View->edit_event_page(
                    current_user => $p{current_user},
                    event_id     => scalar($p{request}->param('event-id')),
                    errors       => \@errors,
                    request      => $p{request},
                ),
            }
        }

        my $r = $p{request};
        my $event_id = scalar($p{request}->param('event-id'));
        my $event = GoC::Model::Event->load($event_id)
            or croak "no event found for id $event_id";
        $event->name(scalar($r->param('event-name')));
        $event->date(scalar($r->param('event-date')));
        $event->queen(scalar($r->param('event-queen')));
        $event->notification_email(scalar($r->param('event-notification-email')));
        $event->type(scalar($r->param('event-type')));
        $event->notes(scalar($r->param('event-notes')));
        $event->update;

        my $person_log_str = join '', $p{current_user}->name, '[', $p{current_user}->id, ']';
        my $event_log_str  = join '', $event->name,  '[', $event->id, ']';
        $p{logger}->info($event->type." event edited: $event_log_str by $person_log_str");

        my $msg = uri_escape('Event "'.$event->name.'" successfully edited');
        return {
            action => 'redirect',
            headers => {
                Location => uri_for( path => '/', message => $msg),
            },
        };
    }
}
sub delete_event {
    my ($class, %p) = @_;
    if ($p{method} eq 'GET') {
        return {
            action => 'redirect',
            headers => {
                Location => uri_for(
                    path => '/',
                    message => 'GET not supported for /delete-event',
                ),
            },
        };

    } elsif ($p{method} eq 'POST') {

        my @errors;

        my $event_id = scalar($p{request}->url_param('event-id'))
            or croak "missing event-id param for /delete-event";

        my $r = $p{request};
        my $event = GoC::Model::Event->load($event_id)
            or croak "no event found for id $event_id";
        $event->deleted(1);
        $event->update;

        my $person_log_str = join '', $p{current_user}->name, '[', $p{current_user}->id, ']';
        my $event_log_str  = join '', $event->name,  '[', $event->id, ']';
        $p{logger}->info($event->type." event marked deleted: $event_log_str by $person_log_str");

        my $msg = uri_escape('Event "'.$event->name.'" has been marked as deleted');
        return {
            action => 'redirect',
            headers => {
                Location => uri_for( path => '/', message => $msg),
            },
        };
    }
}
sub create_person {
    my ($class, %p) = @_;
    if ($p{method} eq 'GET') {
        return {
            action => 'display',
            content => GoC::View->create_person_page(
                current_user => $p{current_user},
                request => EmptyRequest->new(),
            ),
        }

    } elsif ($p{method} eq 'POST') {

        my @errors;
         if (! scalar($p{request}->param('person-name'))) {
                push @errors, "I need a name for the person";
        }
        if (@errors) {
            return {
                action => 'display',
                content => GoC::View->create_person_page(
                    current_user => $p{current_user},
                    errors       => \@errors,
                    request      => $p{request},
                ),
            }
        }

        my $r = $p{request};
        my $person = GoC::Model::Person->new(
            name  => scalar($r->param('person-name')),
            status  => 'active',
        );
        $person->save;
        my $person_log_str = join '', $person->name, '[', $person->id, ']';
        my $user_log_str = join '', $p{current_user}->name, '[', $p{current_user}->id, ']';
        $p{logger}->info("New user $person_log_str created by $user_log_str");

        my $msg = uri_escape("Person successfully created");
        return {
            action => 'redirect',
            headers => {
                Location => uri_for(path => '/', message => $msg),
            },
        };
    }
}

sub edit_person {
    my ($class, %p) = @_;
    if ($p{method} eq 'GET') {
        if (my $person_id = $p{request}->param('person-id')) {
            my $person = GoC::Model::Person->load($person_id)
                or die "can't find person for id $person_id";
            return {
                action => 'display',
                content => GoC::View->create_person_page(
                    current_user => $p{current_user},
                    person =>  $person,
                ),
            }
        } else {
            return {
                action => 'display',
                content => GoC::View->pick_person_to_edit_page (
                    current_user => $p{current_user},
                ),
            }
        }

    } elsif ($p{method} eq 'POST') {
        my $person_id = $p{request}->param('person-id')
            or die "missing person_id in POST to edit_person";
        my $person = GoC::Model::Person->load($person_id)
            or die "can't find person for id $person_id";

        my @errors;
        if (! $p{request}->param('person-name')) {
            push @errors, "You can't change the person's name to a blank.";
        }
        if (@errors) {
            return {
                action => 'display',
                content => GoC::View->create_person_page(
                    current_user => $p{current_user},
                    errors       => \@errors,
                    request      => $p{request},
                    person       => $person,
                ),
            }
        }

        $person->name(scalar($p{request}->param('person-name')));
        $person->status(scalar($p{request}->param('person-status')));
        $person->update;

        my $person_log_str = join '', $person->name, '[', $person->id, ']';
        my $user_log_str = join '', $p{current_user}->name, '[', $p{current_user}->id, ']';
        $p{logger}->info("User $person_log_str edited by $user_log_str");

        my $msg = uri_escape('Person "'.$person->name.'" has been updated');
        return {
            action => 'redirect',
            headers => {
                Location  => uri_for(path => "/", message => $msg),
            },
        };
    }
}

1;
