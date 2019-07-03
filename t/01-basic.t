
use strict;
use warnings;

use Data::Dump qw/dump/;
use DateTime;
use Test::More tests => 99;

use GoC::Model::Person;
use GoC::Model::Event;
use GoC::Model::PersonEventMap;
use GoC::Utils qw/get_dbh/;

$ENV{SQLITE_FILE} = 'goctest';
unlink $ENV{SQLITE_FILE};

GoC::Model::Person->create_table;
GoC::Model::Event->create_table;
GoC::Model::PersonEventMap->create_table;

test_person_CRUD();
test_event_CRUD();
test_person_event_map_CRUD();
test_upcoming_events();
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


    $person = GoC::Model::Person->load($person->id);
    is $person->name, 'alice';
    is $person->status, 'retired';
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

    GoC::Model::PersonEventMap->delete_person_from_event($person, $event);
    ok ! $event->get_persons(role => 'muso', status => 'y');
    ok ! $event->get_status_for_person($person);

    #GoC::Model::PersonEventMap->update_person_for_event($person, $event, 'muso', 
    # pk?

}

sub test_upcoming_events {

    my $dbh = get_dbh();
    $dbh->do('DELETE FROM event');

    my $today = DateTime->now->ymd;
    
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

}


