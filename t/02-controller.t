
use strict;
use warnings;

use Data::Dump qw/dump/;

use Test::More tests => 52;

use GoC::Controller;
use GoC::Controller::CGI;
use GoC::Model::Event;
use GoC::Model::Person;
use GoC::Model::PersonEventMap;
use GoC::Logger;

{
package MockRequest;
    sub new {
        my ($class, %p) = @_;

        return bless \%p, $class;
    }
    sub param {
        my ($self, $name) = @_;
        return $self->{$name};
    }
    no warnings 'once';
    *url_param = \&param;
}


$ENV{SQLITE_FILE} = 'goctest';
$ENV{GOC_URI_BASE} = '/goc2';
$ENV{GOC_STATIC_URI_BASE} = '/goc2-static';
unlink $ENV{SQLITE_FILE};

GoC::Model::Person->create_table;
GoC::Model::Event->create_table;
GoC::Model::PersonEventMap->create_table;
GoC::Logger->create_table;

my $user = GoC::Model::Person->new(
    name => 'loggedinuser',
    status => 'active',
);
$user->save;

test_change_status($user);
test_create_event($user);
test_edit_event($user);
test_delete_event($user);
test_create_person($user);
test_edit_person($user);


sub test_change_status {
    my $user = shift;

    GoC::Logger->clear_logs();

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
        logger => GoC::Logger->new(current_user => $user),
        uri_for => \&GoC::Controller::CGI::uri_for,
    );


    my ($status, $role) = $event->get_status_for_person($person);
    is $status, 'y';
    is $role, 'dancer';

    my $log_lines = GoC::Logger->get_log_lines;


    is   $log_lines->[0]{level}, 'info';
    is   $log_lines->[0]{actor_id}, $user->id;
    is   $log_lines->[0]{actor_name}, $user->name;
    like $log_lines->[0]{message}, qr/status change alice\[.\] for event fourth of july parade\[.\] for role dancer to status y/;

}
sub test_create_event {
    my $user = shift;

    GoC::Logger->clear_logs();

    # test failure, missing date
    my $request = MockRequest->new(
        'event-name' => 'test event 1',
        #'event-date' => '2019-09-01',
        'event-type' => 'party',
        'event-notification-email' => 'foo@bar.com',
    );
    my $result = GoC::Controller->create_event(
        method => 'POST',
        request => $request,
        logger => GoC::Logger->new(current_user => $user),
        uri_for => \&GoC::Controller::CGI::uri_for,
        current_user => $user,
    );
    is $result->{action}, 'display';
    like $result->{content}, qr/missing data for event-date/;

    # test success
    $request->{'event-date'} = '2019-09-01';
    $result = GoC::Controller->create_event(
        method => 'POST',
        request => $request,
        logger => GoC::Logger->new(current_user => $user),
        uri_for => \&GoC::Controller::CGI::uri_for,
        current_user => $user,
    );
    is $result->{action}, 'redirect';
    is $result->{headers}{Location}, '/goc2?path=/event&id=2&message=Event%20successfully%20created';

    my $log_lines = GoC::Logger->get_log_lines;
    is   $log_lines->[0]{level}, 'info';
    is   $log_lines->[0]{actor_id}, $user->id;
    is   $log_lines->[0]{actor_name}, $user->name;
    like $log_lines->[0]{message}, qr/created event test event 1\[\d+\] by loggedinuser\[\d+\]/;
}
sub test_edit_event {
    my $user = shift;

    GoC::Logger->clear_logs();

    my $event = GoC::Model::Event->new(
        name => 'christmas in july',
        date => '2019-07-04',
        type => 'gig',
        queen => 'alice',
        notes => 'blah',
        notification_email => 'foo@bar.com',
    );
    $event->save;

    # test failure, missing date
    my $request = MockRequest->new(
        'event-id' => $event->id,
        'event-name' => 'christmas in july (edited)',
        #'event-date' => '2019-09-01',
        'event-type' => 'party',
        'event-notification-email' => 'changed@email.com',
        'event-notes' => 'blah de blah',
        'event-queen' => 'the new queen',
    );
    my $result = GoC::Controller->create_event(
        method => 'POST',
        request => $request,
        logger => GoC::Logger->new(current_user => $user),
        uri_for => \&GoC::Controller::CGI::uri_for,
        current_user => $user,
    );
    is $result->{action}, 'display';
    like $result->{content}, qr/missing data for event-date/;

    # test success
    $request->{'event-date'} = '2019-09-01';
    $result = GoC::Controller->edit_event(
        method => 'POST',
        request => $request,
        logger => GoC::Logger->new(current_user => $user),
        uri_for => \&GoC::Controller::CGI::uri_for,
        current_user => $user,
    );
    is $result->{action}, 'redirect';
    is $result->{headers}{Location}, '/goc2?path=/event&id=3&message=Event%20%22christmas%20in%20july%20%28edited%29%22%20successfully%20edited';

    $event = GoC::Model::Event->load($event->id);
    is $event->name, 'christmas in july (edited)';
    is $event->type, 'party';
    is $event->notification_email, 'changed@email.com';
    is $event->notes, 'blah de blah';
    is $event->queen, 'the new queen';

    my $log_lines = GoC::Logger->get_log_lines;
    is   $log_lines->[0]{level}, 'info';
    is   $log_lines->[0]{actor_id}, $user->id;
    is   $log_lines->[0]{actor_name}, $user->name;
    like $log_lines->[0]{message}, qr/party event edited: christmas in july \(edited\)\[\d+\] by loggedinuser\[\d+\]/;
}

sub test_delete_event {
    my $user = shift;

    GoC::Logger->clear_logs();

    my $event = GoC::Model::Event->new(
        name => 'event to be deleted',
        date => '2019-07-04',
        type => 'gig',
        queen => 'alice',
        notes => 'blah',
        notification_email => 'foo@bar.com',
    );
    $event->save;

    my $request = MockRequest->new(
        'event-id' => $event->id,
    );
    my $result = GoC::Controller->delete_event(
        method => 'POST',
        request => $request,
        logger => GoC::Logger->new(current_user => $user),
        uri_for => \&GoC::Controller::CGI::uri_for,
        current_user => $user,
    );
    is $result->{action}, 'redirect';
    is $result->{headers}{Location}, '/goc2?path=/&message=Event%20%22event%20to%20be%20deleted%22%20has%20been%20marked%20as%20deleted';

    ok ! GoC::Model::Event->load($event->id);

    my $log_lines = GoC::Logger->get_log_lines;
    is   $log_lines->[0]{level}, 'info';
    is   $log_lines->[0]{actor_id}, $user->id;
    is   $log_lines->[0]{actor_name}, $user->name;
    like $log_lines->[0]{message}, qr/gig event marked deleted: event to be deleted\[\d+\] by loggedinuser\[\d+\]/;
}

sub test_create_person {
    my $user = shift;

    GoC::Logger->clear_logs();

    # test failure, missing date
    my $request = MockRequest->new(
        #'person-name' => 'John Smith',
    );
    my $result = GoC::Controller->create_person(
        method => 'POST',
        request => $request,
        logger => GoC::Logger->new(current_user => $user),
        uri_for => \&GoC::Controller::CGI::uri_for,
        current_user => $user,
    );
    is $result->{action}, 'display';
    like $result->{content}, qr/I need a name for the person/;

    # test success
    $request->{'person-name'} = 'John Smith';
    $result = GoC::Controller->create_person(
        method => 'POST',
        request => $request,
        logger => GoC::Logger->new(current_user => $user),
        uri_for => \&GoC::Controller::CGI::uri_for,
        current_user => $user,
    );
    is $result->{action}, 'redirect';
    is $result->{headers}{Location}, '/goc2?path=/&message=Person%20successfully%20created';

    my $log_lines = GoC::Logger->get_log_lines;
    is   $log_lines->[0]{level}, 'info';
    is   $log_lines->[0]{actor_id}, $user->id;
    is   $log_lines->[0]{actor_name}, $user->name;
    like $log_lines->[0]{message}, qr/New user John Smith\[\d\] created by loggedinuser\[\d\]/;
}

sub test_edit_person {
    my $user = shift;

    GoC::Logger->clear_logs();

    my $person = GoC::Model::Person->new(
        name => 'faithe',
        status => 'active',
    );
    $person->save();

    # test failure, missing date
    my $request = MockRequest->new(
        'person-id' => $person->id,
        #'person-name' => 'Faithe the Healer',
        'person-status' => 'inactive',
    );
    my $result = GoC::Controller->edit_person(
        method => 'POST',
        request => $request,
        logger => GoC::Logger->new(current_user => $user),
        uri_for => \&GoC::Controller::CGI::uri_for,
        current_user => $user,
    );
    is $result->{action}, 'display';
    like $result->{content}, qr/You can't change the person's name to a blank/;

    # test success
    $request->{'person-name'} = 'Faithe the Healer';
    $result = GoC::Controller->edit_person(
        method => 'POST',
        request => $request,
        logger => GoC::Logger->new(current_user => $user),
        uri_for => \&GoC::Controller::CGI::uri_for,
        current_user => $user,
    );
    is $result->{action}, 'redirect' or diag $result->{content};
    is $result->{headers}{Location}, '/goc2?path=/&message=Person%20%22Faithe%20the%20Healer%22%20has%20been%20updated';

    $person = GoC::Model::Person->load($person->id, include_everybody => 1);
    is $person->name, 'Faithe the Healer';
    is $person->status, 'inactive';

    my $log_lines = GoC::Logger->get_log_lines;
    is   $log_lines->[0]{level}, 'info';
    is   $log_lines->[0]{actor_id}, $user->id;
    is   $log_lines->[0]{actor_name}, $user->name;
    like $log_lines->[0]{message}, qr/User Faithe the Healer\[\d+\] edited by loggedinuser\[\d+\]/;

}
