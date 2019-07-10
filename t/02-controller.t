
use strict;
use warnings;

use Data::Dump qw/dump/;

use Test::More tests => 6;

use GoC::Controller;
use GoC::Model::Event;
use GoC::Model::Person;
use GoC::Model::PersonEventMap;
use GoC::Logger;

package MockRequest {
    sub new {
        my ($class, %p) = @_;

        return bless \%p, $class;
    }
    sub param {
        my ($self, $name) = @_;
        return $self->{$name};
    }
}



$ENV{SQLITE_FILE} = 'goctest';
unlink $ENV{SQLITE_FILE};

GoC::Model::Person->create_table;
GoC::Model::Event->create_table;
GoC::Model::PersonEventMap->create_table;
GoC::Logger->create_table;

test_change_status();


sub test_change_status {

    my $person = GoC::Model::Person->new(
        name => 'alice',
        status => 'active',
    );
    $person->save();
    my $event = GoC::Model::Event->new(
        name => 'fourth of july parade',
        date => '2019-07-01',
        type => 'gig',
        queen => 'alice',
        notes => 'blah',
    );
    $event->save;

    my $request = MockRequest->new(
        person_id => $person->id,
        event_id => $event->id,
        for_role => 'dancer',
        status => 'y',
    );
    GoC::Controller->change_status(
        request => $request,
        logger => GoC::Logger->new(current_user => $person)
    );


    my ($status, $role) = $event->get_status_for_person($person);
    is $status, 'y';
    is $role, 'dancer';

    my $log_lines = GoC::Logger->get_log_lines;


    is   $log_lines->[0]{level}, 'info';
    is   $log_lines->[0]{actor_id}, $person->id;
    is   $log_lines->[0]{actor_name}, $person->name;
    like $log_lines->[0]{message}, qr/status change alice\[.\] for event fourth of july parade\[.\] for role dancer to status y/;


}
     
