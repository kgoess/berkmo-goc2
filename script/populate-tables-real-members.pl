
use strict;
use warnings;

use Data::Dump qw/dump/;
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

my @members = get_real_members();

my $random_user = sub { $members[ int rand(@members) ]->{name} };
my @events = (
    ['alameda parade', $random_user->(), 'gig', 'blah blah blah git notes blah' ],
    ['some other gig', $random_user->(), 'gig', 'blah blah blah git notes blah' ],
    ['a high-paying wedding gig', $random_user->(), 'gig', 'blah blah blah git notes blah' ],
    ['you come on after the dog', $random_user->(), 'gig', 'blah blah blah git notes blah' ],
    ['dancing in jail', $random_user->(), 'gig', 'blah blah blah git notes blah' ],
    ["buckingham palace (servant's entrance)", $random_user->(), 'gig', 'blah blah blah git notes blah' ],
    ['christmas in july in october', $random_user->(), 'gig', 'blah blah blah git notes blah' ],
    ['some really fun party', $random_user->(), 'party', 'boozing boozing'],
    ['an example party', $random_user->(), 'party', 'boozing boozing'],
    ['not a real party', $random_user->(), 'party', 'boozing boozing'],
    ['some fun stuff here', $random_user->(), 'party', 'boozing boozing'],
    ['birthday party for my cat', $random_user->(), 'party', 'boozing boozing'],
    ['world domination planning meeting', $random_user->(), 'party', 'boozing boozing'],
);

my @event_objs;
foreach my $event (@events) {
    my $e = 
        GoC::Model::Event->new(
            name => $event->[0],
            date => $event_date->(),
            queen => $event->[1],
            type => $event->[2],
            notes => $event->[3],
        );
    $e->save;
    push @event_objs, $e;
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


my @person_objs;
foreach my $m (@members) {
    my $person = GoC::Model::Person->new(
        name => $m->{name},
        status => $m->{status} ? $m->{status} : 'active',
    );
    $person->save;
    push @person_objs, $person;
}

my $map = 'GoC::Model::PersonEventMap';

my @y_n_q = (qw/y y y y n ?/);
foreach my $p (@person_objs) {
    foreach my $e (@event_objs) {
        next if $p->status eq 'inactive';
        next if (int rand(3) >= 1);
        my $what = int rand 2 ? 'dancer' : 'muso';
        my $y_n =  $y_n_q[int rand 6];
        $map->add_person_to_event($p, $e, $what, $y_n);
    }
}


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


sub get_real_members {

    my @members;
    open my $fh, "<", "../berkmo-website/private/current.vcf";
    my $member = {};
    while (<$fh>) {
        chomp;
        if (/^n:/) {
            $member->{name} = $_ =~ s/.*;//r;
            $member->{name} or die "nothing";
        } elsif (/^note:\s*(\w+)/) {
            $member->{status} = 'inactive';
        } elsif (/^end:/) {
            push @members, $member if $member->{name};
            $member = {};
        }
    }
    return @members;
}

