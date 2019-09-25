
package GoC::View;

use strict;
use warnings;

use Carp qw/croak/;
use Template;

use GoC::Logger;
use GoC::Model::Event;
use GoC::Model::Person;

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

sub main_page {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $template = 'main-html.tt';
    my $vars = get_vars(
        \%p,
        organization_name => 'Berkeley Morris',
        gigs    => GoC::Model::Event->get_upcoming_events(type => 'gig'),
        parties => GoC::Model::Event->get_upcoming_events(type => 'party'),
        current_user => $p{current_user},
        message => $p{message},
    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub event_page {
    my ($class, %p) = @_;

    $p{event_id} || croak "missing event_id in call to $class->event_page";

    my $tt = get_tt();

    my $event = GoC::Model::Event->load($p{event_id})
        or croak "no event found for id $p{event_id}";

    my @statuses = ('y', 'n', '?');

    my %dancers_for_status;
    my $num_dancers = 0;
    foreach my $status (@statuses) {
        my @dancers = $event->get_persons(role => 'dancer', status => $status);
        $dancers_for_status{$status} = \@dancers;
        $num_dancers += @dancers;
    }

    my %musos_for_status;
    my $num_musos = 0;
    foreach my $status (@statuses) {
        my @musos = $event->get_persons(role => 'muso', status => $status);
        $musos_for_status{$status} = \@musos;
        $num_musos += @musos;
    }
    my ($status, $role) = $event->get_status_for_person($p{current_user});

    my ($prev_id, $next_id) = $event->get_prev_next_ids;

    my $template = 'event-page.tt';
    my $vars = get_vars(
        \%p,
        organization_name   => 'Berkeley Morris',
        statuses            => \@statuses,
        event               => $event,
        dancers_for_status  => \%dancers_for_status,
        num_dancers         => $num_dancers,
        musos_for_status    => \%musos_for_status,
        num_musos           => $num_musos,
        current_user        => $p{current_user},
        current_user_status => $status,
        current_user_role   => $role,
        message             => $p{message},
        prev_id             => $prev_id,
        next_id             => $next_id,
        current_tab         => $p{current_tab},
    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub create_event_page {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $param = sub { scalar($p{request}->param(shift)) };

    my $template = 'event-editor.tt';
    my $vars = get_vars(
        \%p,
        organization_name => 'Berkeley Morris',
        current_user      => $p{current_user},
        errors            => $p{errors},
        #request           => $p{request},
        event_name        => $param->('event-name'),
        event_date        => $param->('event-date'),
        event_queen       => $param->('event-queen'),
        event_notification_email => $param->('event-notification-email'),
        event_type        => $param->('event-type'),
        event_notes       => $param->('event-notes'),
    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub edit_event_page {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $event = GoC::Model::Event->load($p{event_id})
        or croak "no event found for id $p{event_id}";

    my $param = sub { scalar($p{request}->param(shift)) };

    my $param_or_field = sub {
        my ($param_name, $obj_value) = @_;
        if ($p{errors} && @{ $p{errors} }) {
            return scalar($p{request}->param($param_name));
        } else {
            return $obj_value;
        }
    };


    my $template = 'event-editor.tt';
    my $vars = get_vars(
        \%p,
        organization_name => 'Berkeley Morris',
        current_user      => $p{current_user},
        errors            => $p{errors},
        #request => $p{request},
        event_name        => $param_or_field->('event-name', $event->name),
        event_id          => $param_or_field->('event-id', $event->id),
        event_date        => $param_or_field->('event-date', $event->date),
        event_queen       => $param_or_field->('event-queen', $event->queen),
        event_notification_email => $param_or_field->('event-notification-email', $event->notification_email),
        event_type        => $param_or_field->('event-type', $event->type),
        event_notes       => $param_or_field->('event-notes', $event->notes),
    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;

}
sub create_person_page {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $template = 'person-editor.tt';
    my $vars = get_vars(
        \%p,
        organization_name => 'Berkeley Morris',
        current_user => $p{current_user},
        errors => $p{errors},
        request => $p{request},
        person => $p{person},
    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub pick_person_to_edit_page {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $show_inactive = scalar($p{request}->param('show-inactive'));

    my $template = 'person-editor-picker.tt';
    my $vars = get_vars(
        \%p,
        organization_name => 'Berkeley Morris',
        current_user      => $p{current_user},
        errors            => $p{errors},
        #request          => $p{request},
        active_people     => [ GoC::Model::Person->get_all($show_inactive ? () : (status => 'active')) ],
        show_inactive     => $show_inactive,
    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub edit_person_page {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $template = 'person-editor.tt';
    my $vars = get_vars(
        \%p,
        organization_name => 'Berkeley Morris',
        current_user      => $p{current_user},
        errors            => $p{errors},
        request           => $p{request},
    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub login_page {
    my ($class, %p) = @_;

    my $show_inactive = scalar($p{request}->param('show-inactive'));

    my $tt = get_tt();

    my $template = 'login-page.tt';
    my $vars = get_vars(
        \%p,
        people => [
            GoC::Model::Person->get_all($show_inactive ? () : (status => 'active'))
        ],
        show_inactive => $show_inactive,
    );

    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub activity_logs {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $template = 'activity-logs.tt';
    my $vars = get_vars(
        \%p,
        logs => GoC::Logger->get_log_lines(),
    );

    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

my $_tt;
sub get_tt {

    my $config = {
        INCLUDE_PATH => ($ENV{TT_INCLUDE_PATH} || './templates'),
        PRE_PROCESS => 'header.tt', # add config as arrayref with organization_name?
        POST_PROCESS => 'footer.tt',
    };

    $_tt ||= Template->new($config);
    return $_tt;
}

sub get_vars {
    my $p = shift;
    my %vars = @_;

    return {
        uri_for        => \&uri_for,
        static_uri_for => \&static_uri_for,
        %vars,
    };
}



1;
