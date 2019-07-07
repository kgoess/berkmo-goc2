
use strict;
use warnings;

use DateTime;

use GoC::Logger;
use GoC::Model::Person;
use GoC::Model::Event;
use GoC::Model::PersonEventMap;
use GoC::Utils qw/get_dbh/;

open my $truncate, ">", $ENV{SQLITE_FILE};
close $truncate;

# DBD::SQLite::st execute failed: attempt to write a readonly database
# sudo chcon -R -t httpd_sys_content_rw_t /var/lib/berkmo-goc2/
# (and restart apache)
# https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/6/html/security-enhanced_linux/sect-security-enhanced_linux-working_with_selinux-selinux_contexts_labeling_files

GoC::Model::Person->create_table;
GoC::Model::Event->create_table;
GoC::Model::PersonEventMap->create_table;
GoC::Logger->create_table;
my $date_incr = 7;
my $event_date = sub { DateTime->now->add(days => $date_incr++)->ymd };

    my $parade = GoC::Model::Event->new(
        name => 'alameda parade',
        date => $event_date->(),
        queen => 'alice',
		type => 'gig',
        notes => 'blah blah blah',
    );
    $parade->save;

    my @events = (
        ['some other gig', 'frances', 'gig', 'blah blah blah git notes blah' ],
        ['a high-paying wedding gig', 'harry', 'gig', 'blah blah blah git notes blah' ],
        ['you come on after the dog', 'frances', 'gig', 'blah blah blah git notes blah' ],
        ['dancing in jail', 'harry', 'gig', 'blah blah blah git notes blah' ],
        ["buckingham palace (servant's entrance)", 'frances', 'gig', 'blah blah blah git notes blah' ],
        ['christmas in july in october', 'harry', 'gig', 'blah blah blah git notes blah' ],
        ['some really fun party', 'frances', 'party', 'boozing boozing'],
        ['an example party', 'harry', 'party', 'boozing boozing'],
        ['not a real party', 'frances', 'party', 'boozing boozing'],
        ['some fun stuff here', 'harry', 'party', 'boozing boozing'],
        ['birthday party for my cat', 'frances', 'party', 'boozing boozing'],
        ['world domination planning meeting', 'harry', 'party', 'boozing boozing'],
    );

    foreach my $event (@events) {
        GoC::Model::Event->new(
            name => $event->[0],
            date => $event_date->(),
            queen => $event->[1],
            type => $event->[2],
            notes => $event->[3],
        )->save;
    }
        
    GoC::Model::Event->new(
        name => 'old gig',
        date => '2019-01-01',
        queen => 'alice',
		type => 'gig',
    )->save;

    GoC::Model::Event->new(
        name => 'deleted gig',
        date => $event_date->(),
        queen => 'alice',
		type => 'gig',
		deleted => 1,
    )->save;
    my $alice = GoC::Model::Person->new(
        name => 'alice',
        status => 'active',
    );
    $alice->save;

    my $bob = GoC::Model::Person->new(
        name => 'bob',
        status => 'active',
    );
    $bob->save;

    my $chuck = GoC::Model::Person->new(
        name => 'chuck',
        status => 'inactive',
    );
    $chuck->save;
    my $doris = GoC::Model::Person->new(
        name => 'doris',
        status => 'active',
    );
    $doris->save;
    my $ethan = GoC::Model::Person->new(
        name => 'ethan',
        status => 'active',
    );
    $ethan->save;
    my $frances = GoC::Model::Person->new(
        name => 'frances',
        status => 'active',
    );
    $frances->save;
    my $gottfried = GoC::Model::Person->new(
        name => 'gottfried',
        status => 'active',
    );
    $gottfried->save;
    my $harry = GoC::Model::Person->new(
        name => 'harry',
        status => 'active',
    );
    $harry->save;
    my $ingrid = GoC::Model::Person->new(
        name => 'ingrid',
        status => 'active',
    );
    $ingrid->save;
    my $jeremy = GoC::Model::Person->new(
        name => 'jeremy',
        status => 'active',
    );
    $jeremy->save;
    my $kyle = GoC::Model::Person->new(
        name => 'kyle',
        status => 'active',
    );
    $kyle->save;
    my $lawrence = GoC::Model::Person->new(
        name => 'lawrence',
        status => 'active',
    );
    $lawrence->save;

    my $map = 'GoC::Model::PersonEventMap';
    $map->add_person_to_event($alice, $parade, 'dancer', 'y');
    $map->add_person_to_event($bob, $parade, 'dancer', 'y');
    $map->add_person_to_event($doris, $parade, 'dancer', 'n');
    $map->add_person_to_event($ethan, $parade, 'muso', 'y');
    $map->add_person_to_event($frances, $parade, 'muso', 'n');
    $map->add_person_to_event($gottfried, $parade, 'muso', 'n');
    $map->add_person_to_event($harry, $parade, 'muso', '?');
    $map->add_person_to_event($ingrid, $parade, 'dancer', 'y');
    $map->add_person_to_event($jeremy, $parade, 'dancer', 'y');
    $map->add_person_to_event($kyle, $parade, 'dancer', 'y');
    $map->add_person_to_event($lawrence, $parade, 'dancer', 'y');
