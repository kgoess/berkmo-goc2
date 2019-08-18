
package GoC::View;

use strict;
use warnings;

use Carp qw/croak/;
use Template;

use GoC::Logger;
use GoC::Model::Event;
use GoC::Model::Person;
use GoC::Utils qw/
    static_uri_for
    uri_for
/;

sub main_page {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $template = 'main-html.tt';
    my $vars = get_vars(
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

    my $template = 'event-page.tt';
    my $vars = get_vars(
        organization_name => 'Berkeley Morris',
        statuses => \@statuses,
        event => $event,
        dancers_for_status => \%dancers_for_status,
        num_dancers => $num_dancers,
        musos_for_status => \%musos_for_status,
        num_musos => $num_musos,
        current_user => $p{current_user},
        current_user_status => $status,
        current_user_role => $role,
    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub create_event_page {
    my ($class, %p) = @_;

    my $tt = get_tt();

    my $template = 'event-editor.tt';
    my $vars = get_vars(
        organization_name => 'Berkeley Morris',
        current_user => $p{current_user},
        errors => $p{errors},
        request => $p{request},
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
        organization_name => 'Berkeley Morris',
        current_user => $p{current_user},
        errors => $p{errors},
        request => $p{request},
    );
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;

}

sub login_page {
    my ($class) = @_;

    my $tt = get_tt();

    my $template = 'login-page.tt';
    my $vars = get_vars(
        people => [ GoC::Model::Person->get_all(status => 'active') ],
    );

    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub activity_logs {
    my ($class) = @_;

    my $tt = get_tt();

    my $template = 'activity-logs.tt';
    my $vars = get_vars(
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
    my %p = @_;

    return {
        uri_for => \&uri_for,
        static_uri_for => \&static_uri_for,
        %p,
    };
}



1;
