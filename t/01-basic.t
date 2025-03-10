
use strict;
use warnings;

use Data::Dump qw/dump/;
use Test::More tests => 51;

use GoC::Model::Person;
use GoC::Model::Event;
use GoC::Model::PersonEventMap;
use GoC::Utils qw/get_dbh today_ymd yesterday_ymd/;

reset_db();

test_person_CRUD();
test_event_CRUD();
test_event_prev_next();
test_event_prev_next_same_day();
test_event_prev_may_day();
test_person_event_map_CRUD();
test_upcoming_events();
test_attendee_list_notifications();
test_new_event_notifications();
test_person_get_all();


sub test_person_CRUD {
    my $person = GoC::Model::Person->new(
        name => 'alice',
        status => 'active',
    );
    $person->save();

    $person = GoC::Model::Person->load($person->id);
    is $person->name, 'alice';
    is $person->status, 'active';

    $person->status('retired');
    $person->update();


    $person = GoC::Model::Person->load($person->id, include_everybody => 1);
    is $person->name, 'alice';
    is $person->status, 'retired';

    ok ! GoC::Model::Person->load(123123123);
}

sub test_event_CRUD {
    my $event = GoC::Model::Event->new(
        name => 'fourth of july parade',
        date => '2019-07-01',
        type => 'gig',
        queen => 'alice',
        notes => 'blah',
    );
    $event->save;

    $event = GoC::Model::Event->load($event->id);
    is $event->name, 'fourth of july parade';
    is $event->date, '2019-07-01';
    is $event->queen, 'alice';
    is $event->type, 'gig';

    $event->queen('bob');
    $event->update;

    $event = GoC::Model::Event->load($event->id);
    is $event->queen, 'bob';

    ok ! GoC::Model::Event->load(1232123);
}
sub test_event_prev_next {
    reset_db();

    my $armistice_day = GoC::Model::Event->new(
        name => 'armistice day',
        date => '2021-11-11',
        type => 'gig',
    );
    $armistice_day->save;
    my $armistice_eve = GoC::Model::Event->new(
        name => 'armistice eve',
        date => '2021-11-10',
        type => 'gig',
    );
    $armistice_eve->save;
    my $day_after_armistice = GoC::Model::Event->new(
        name => 'day after armistice',
        date => '2021-11-12',
        type => 'gig',
    );
    $day_after_armistice->save;
    my $zzz_day_after = GoC::Model::Event->new(
        name => 'zzz alphabetically after',
        date => '2021-11-12',
        type => 'gig',
    );
    $zzz_day_after->save;
    my $party = GoC::Model::Event->new(
        # first alphabetically, but not a gig
        name => 'armistice party',
        date => '2021-11-12',
        type => 'party',
    );
    $party->save;

    my ($prev, $next) = $armistice_day->get_prev_next_ids;

    is $prev, $armistice_eve->id, GoC::Model::Event->load($prev)->name." is the previous event";
    is $next, $day_after_armistice->id, GoC::Model::Event->load($next)->name." is the next event";
}

sub test_event_prev_next_same_day {
    reset_db();

    my $event = GoC::Model::Event->new(
        name => 'armistice day',
        date => '2020-11-11',
        type => 'gig',
    );
    $event->save;
    my $event_prev = GoC::Model::Event->new(
        name => 'armistice eve',
        date => '2020-11-10',
        type => 'gig',
    );
    $event_prev->save;
    my $event_next = GoC::Model::Event->new(
        name => 'day after armistice',
        date => '2020-11-12',
        type => 'gig',
    );
    $event_next->save;
    my $event_not_next = GoC::Model::Event->new(
        name => 'zzz alphabetically after',
        date => '2020-11-12',
        type => 'gig',
    );
    $event_not_next->save;
    my $party = GoC::Model::Event->new(
        # first alphabetically, but not a gig
        name => 'armistice party',
        date => '2020-11-12',
        type => 'party',
    );
    $party->save;

    my ($prev, $next) = $event->get_prev_next_ids;

    is $prev, $event_prev->id, "$prev is the previous event";
    is $next, $event_next->id, "$next is the next event";
}

# trying to repro the bug
sub test_event_prev_may_day {
    reset_db();

    my $event_apr_30 = GoC::Model::Event->new(
        name => 'april event',
        date => '2025-04-30',
        type => 'gig',
    );
    $event_apr_30->save;
    my $event_may1_a = GoC::Model::Event->new(
        name => 'May Day morning',
        date => '2025-05-01',
        type => 'gig',
    );
    $event_may1_a->save;
    my $event_may1_b = GoC::Model::Event->new(
        name => 'May Day tour',
        date => '2025-05-01',
        type => 'gig',
    );
    $event_may1_b->save;
    my $event_may_2 = GoC::Model::Event->new(
        name => 'may 2 event',
        date => '2025-05-02',
        type => 'gig',
    );
    $event_may_2->save;

    my ($prev, $next);
    ($prev, $next) = $event_apr_30->get_prev_next_ids;
    ok! $prev, 'no prev event to apr 30' or diag "prev is $prev";
    is $next, $event_may1_a->id, "may 1 b $next is the next event";

    ($prev, $next) = $event_may1_a->get_prev_next_ids;
    is $prev, $event_apr_30->id, "apr 3 $prev is the previous event $prev";
    is $next, $event_may1_b->id, "may 1 b $next is the next event" or diag "next is $next";

    ($prev, $next) = $event_may1_b->get_prev_next_ids;
    is $prev, $event_may1_a->id, "may 1 a $prev is the previous event";
    is $next, $event_may_2->id, "may 2 $next is the next event" or dump $next;

    ($prev, $next) = $event_may_2->get_prev_next_ids;
    is $prev, $event_may1_b->id, "may 1 b $prev is the previous event";
    ok ! $next, "may 2 is the last event" or diag "next is $next";

    GoC::Utils::clear_dbh();
}

sub test_person_event_map_CRUD {

    my $event = GoC::Model::Event->new(
        name => 'fourth of july parade',
        date => '2019-07-01',
        queen => 'alice',
        notes => 'blah',
    );
    $event->save;

    my $person = GoC::Model::Person->new(
        name => 'alice',
        status => 'active',
    );
    $person->save();

    GoC::Model::PersonEventMap->add_person_to_event($person, $event, 'muso', 'y');

    my @persons = $event->get_persons(role => 'muso');
    is $persons[0]->name, 'alice';

    @persons = $event->get_persons(role => 'muso', status => 'y');
    is $persons[0]->name, 'alice';

    my ($status, $role) = $event->get_status_for_person($person);
    is $status, 'y';
    is $role, 'muso';

    # test for somebody who has no status for this event
    my $bob = GoC::Model::Person->new(
        name => 'bob',
        status => 'active',
    );
    $bob->save();
    ($status, $role) = $event->get_status_for_person($bob);
    ok ! $status;

    # test get_num_persons with a tive/inactive
    is $event->get_num_persons(role => 'muso'), 1;
    my $carlos = GoC::Model::Person->new(
        name => 'carlos',
        status => 'active',
    );
    $carlos->save();
    GoC::Model::PersonEventMap->add_person_to_event($carlos, $event, 'muso', 'y');
    is $event->get_num_persons(role => 'muso'), 2;
    $carlos->status('inactive');
    $carlos->save;
    is $event->get_num_persons(role => 'muso'), 1;
    GoC::Model::PersonEventMap->delete_person_from_event($carlos, $event);
    is $event->get_num_persons(role => 'muso'), 1;



    GoC::Model::PersonEventMap->delete_person_from_event($person, $event);
    ok ! $event->get_persons(role => 'muso', status => 'y');
    ok ! $event->get_status_for_person($person);

    #GoC::Model::PersonEventMap->update_person_for_event($person, $event, 'muso',
    # pk?

}

sub test_upcoming_events {

    my $dbh = get_dbh();
    $dbh->do('DELETE FROM event');

    my $today = today_ymd();

    GoC::Model::Event->new(
        name => 'fourth of july parade',
        date => $today,
        queen => 'alice',
        type => 'gig',
        notes => 'blah',
    )->save;

    GoC::Model::Event->new(
        name => 'some other gig',
        date => $today,
        queen => 'alice',
        type => 'gig',
    )->save;


    GoC::Model::Event->new(
        name => 'a party',
        date => $today,
        queen => 'alice',
        type => 'party',
    )->save;

    GoC::Model::Event->new(
        name => 'old gig',
        date => '2019-01-01',
        queen => 'alice',
        type => 'gig',
    )->save;

    GoC::Model::Event->new(
        name => 'deleted gig',
        date => '2019-01-01',
        queen => 'alice',
        type => 'gig',
        deleted => 1,
    )->save;

    my $gigs = GoC::Model::Event->get_upcoming_events(type => 'gig');

    is @$gigs, 2;
    is $gigs->[0]->name, 'fourth of july parade';
    is $gigs->[1]->name, 'some other gig';

}

sub test_attendee_list_notifications {

    my $dbh = get_dbh();
    $dbh->do('DELETE FROM event');

    my $today = today_ymd();

    my $event = GoC::Model::Event->new(
        name => 'fourth of july parade',
        date => $today,
        queen => 'alice',
        notification_email => 'alice@example.com',
        type => 'gig',
        notes => 'blah',
    );
    $event->save;

    my $alice = GoC::Model::Person->new(
        name => 'alice',
        status => 'active',
    );
    $alice->save();
    GoC::Model::PersonEventMap->add_person_to_event($alice, $event, 'dancer', 'y');

    my $bob = GoC::Model::Person->new(
        name => 'bob',
        status => 'active',
    );
    $bob->save();
    GoC::Model::PersonEventMap->add_person_to_event($bob, $event, 'dancer', 'y');

    ok ! $event->prev_attendees;

    my $changed = $event->update_prev_attendees();
    like $changed, qr/\+alice: y dancer\n\+bob: y dancer\n/;

    GoC::Model::PersonEventMap->delete_person_from_event($bob, $event);
    GoC::Model::PersonEventMap->add_person_to_event($bob, $event, 'dancer', 'n');

    $changed = $event->update_prev_attendees();
    like $changed, qr/alice: y dancer\n\-bob: y dancer\n\+bob: n dancer\n/;
}

sub test_new_event_notifications {

    my $dbh = get_dbh();
    $dbh->do('DELETE FROM event');

    my $today = today_ymd();

    my $gig = GoC::Model::Event->new(
        name => 'fourth of july parade',
        date => $today,
        queen => 'alice',
        notification_email => 'alice@example.com',
        type => 'gig',
        notes => 'blah',
    );
    $gig->save;
    my $party = GoC::Model::Event->new(
        name => 'fourth of july parade',
        date => $today,
        queen => 'alice',
        notification_email => 'alice@example.com',
        type => 'party',
        notes => 'blah',
    );
    $party->save;

    my @events = GoC::Model::Event->get_pending_new_event_notifications;
    is @events, 2;

    map { $_->group_notified_date($today); $_->update } @events;

    my @nothing = GoC::Model::Event->get_pending_new_event_notifications;
    is @nothing, 0;
}

sub test_person_get_all {

    my $dbh = get_dbh();
    $dbh->do('DELETE FROM person');

    GoC::Model::Person->new(
        name => 'alice',
        status => 'active',
    )->save();
    GoC::Model::Person->new(
        name => 'bob',
        status => 'active',
    )->save();
    GoC::Model::Person->new(
        name => 'chuck',
        status => 'retired',
    )->save();

    my @people = GoC::Model::Person->get_all(status => 'active');
    is scalar @people, 2;
    is $people[0]->name, 'alice';
    is $people[1]->name, 'bob';


    @people = GoC::Model::Person->get_all();
    is scalar @people, 3;
    is $people[0]->name, 'alice';
    is $people[1]->name, 'bob';
    is $people[2]->name, 'chuck';

    my @except = ($people[0]->id, $people[2]->id);
    @people = GoC::Model::Person->get_all(except_ids => \@except);
    is scalar @people, 1;
    is $people[0]->name, 'bob';

}

sub reset_db {
    GoC::Utils::clear_dbh();
    $ENV{SQLITE_FILE} = 'goctest';
    unlink $ENV{SQLITE_FILE};

    GoC::Model::Person->create_table;
    GoC::Model::Event->create_table;
    GoC::Model::PersonEventMap->create_table;
}


