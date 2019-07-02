
package GoC::View;

use strict;
use warnings;

use Carp qw/croak/;
use Template;

use GoC::Model::Event;

sub main_page {
    my ($class) = @_;

    my $tt = get_tt();

    my $template = 'main-html.tt';
    my $vars = {
        organization_name => 'Berkeley Morris',
        gigs    => GoC::Model::Event->get_upcoming_events(type => 'gig'),
        parties => GoC::Model::Event->get_upcoming_events(type => 'party'),
    };
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

    my $template = 'event-page.tt';
    my $vars = {
        organization_name => 'Berkeley Morris',
        statuses => \@statuses,
        event => $event,
        dancers_for_status => \%dancers_for_status,
        num_dancers => $num_dancers,
        musos_for_status => \%musos_for_status,
        num_musos => $num_musos,
    };
    my $output = '';

    $tt->process($template, $vars, \$output)
           || die $tt->error();

    return $output;
}

sub login_page {
    my ($class) = @_;

    my $tt = get_tt();

    my $template = 'login-page.tt';
    my $vars = {
        people = [ GoC::Model::Person->get_all(status => 'active') ],
    };

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
1;
