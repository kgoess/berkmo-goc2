
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
    ['some other gig', 'faythe', 'gig', 'blah blah blah git notes blah' ],
    ['a high-paying wedding gig', 'heidi', 'gig', 'blah blah blah git notes blah' ],
    ['you come on after the dog', 'faythe', 'gig', 'blah blah blah git notes blah' ],
    ['dancing in jail', 'heidi', 'gig', 'blah blah blah git notes blah' ],
    ["buckingham palace (servant's entrance)", 'faythe', 'gig', 'blah blah blah git notes blah' ],
    ['christmas in july in october', 'heidi', 'gig', 'blah blah blah git notes blah' ],
    ['some really fun party', 'faythe', 'party', 'boozing boozing'],
    ['an example party', 'heidi', 'party', 'boozing boozing'],
    ['not a real party', 'faythe', 'party', 'boozing boozing'],
    ['some fun stuff here', 'heidi', 'party', 'boozing boozing'],
    ['birthday party for my cat', 'faythe', 'party', 'boozing boozing'],
    ['world domination planning meeting', 'heidi', 'party', 'boozing boozing'],
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
my $dan = GoC::Model::Person->new(
    name => 'dan',
    status => 'active',
);
$dan->save;
my $eve = GoC::Model::Person->new(
    name => 'eve',
    status => 'active',
);
$eve->save;
my $faythe = GoC::Model::Person->new(
    name => 'faythe',
    status => 'active',
);
$faythe->save;
my $grace = GoC::Model::Person->new(
    name => 'grace',
    status => 'active',
);
$grace->save;
my $heidi = GoC::Model::Person->new(
    name => 'heidi',
    status => 'active',
);
$heidi->save;
my $ivan = GoC::Model::Person->new(
    name => 'ivan',
    status => 'active',
);
$ivan->save;
my $judy = GoC::Model::Person->new(
    name => 'judy',
    status => 'active',
);
$judy->save;
my $mallory = GoC::Model::Person->new(
    name => 'mallory',
    status => 'active',
);
$mallory->save;
my $olivia = GoC::Model::Person->new(
    name => 'olivia',
    status => 'active',
);
$olivia->save;

my $map = 'GoC::Model::PersonEventMap';
$map->add_person_to_event($alice, $parade, 'dancer', 'y');
$map->add_person_to_event($bob, $parade, 'dancer', 'y');
$map->add_person_to_event($dan, $parade, 'dancer', 'n');
$map->add_person_to_event($eve, $parade, 'muso', 'y');
$map->add_person_to_event($faythe, $parade, 'muso', 'n');
$map->add_person_to_event($grace, $parade, 'muso', 'n');
$map->add_person_to_event($heidi, $parade, 'muso', '?');
$map->add_person_to_event($ivan, $parade, 'dancer', 'y');
$map->add_person_to_event($judy, $parade, 'dancer', 'y');
$map->add_person_to_event($mallory, $parade, 'dancer', 'y');
$map->add_person_to_event($olivia, $parade, 'dancer', 'y');

my $admin = GoC::Model::Person->new(
    name => 'admin',
    status => 'active',
);
$admin->save;
my $logger = GoC::Logger->new(current_user => $admin);

my @log_timestamps = qw(
    2019-07-07T16:04:46
    2019-07-07T16:04:49
    2019-07-07T16:04:54
    2019-07-07T16:04:56
    2019-07-07T16:04:57
    2019-07-07T16:05:02
    2019-07-07T16:05:04
    2019-07-07T16:05:06
    2019-07-07T19:07:51
    2019-07-08T21:29:36
);

{
    no warnings 'redefine';
    local *GoC::Logger::today_ymdhms = sub { shift @log_timestamps };
my @logs = split "\n", <<EOL;
debug|5|eve|logged out
debug|6|faythe|logged in
info|6|faythe|status change faythe(6) for event alameda parade(1) for role dancer to status n
info|6|faythe|status change faythe(6) for event alameda parade(1) for role dancer to status ?
info|6|faythe|status change faythe(6) for event alameda parade(1) for role dancer to status y
info|6|faythe|status change faythe(6) for event a high-paying wedding gig(3) for role muso to status n
info|6|faythe|status change faythe(6) for event a high-paying wedding gig(3) for role dancer to status n
info|6|faythe|status change faythe(6) for event a high-paying wedding gig(3) for role dancer to status y
info|5|eve|status change eve(5) for event alameda parade(1) for role dancer to status ?
|debug|2|bob|logged in
EOL
    foreach my $line (@logs) {
        chomp $line;
        my @rec = split qr{\|}, $line;
        my $level = $rec[0] or next;
        $logger->$level($rec[3]);
    }
}

