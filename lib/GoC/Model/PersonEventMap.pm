
package GoC::Model::PersonEventMap;

use strict;
use warnings;

use Carp qw/croak/;

use GoC::Utils qw/get_dbh today_ymd/;

sub add_person_to_event {
    my ($class, $person, $event, $role, $status) = @_;

    croak "missing args in call to $class->add_person_to_event"
        unless $person && $event && $role && $status;

    my $sql = <<EOL;
INSERT INTO person_to_event_map (
    person_id,
    event_id,
    role,
	status,
    updated
)
VALUES (?,?,?,?,?)
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($person->id, $event->id, $role, $status, today_ymd());
}

sub delete_person_from_event {
    my ($class, $person, $event) = @_;

    croak "missing args in call to $class->delete_person_from_event"
        unless $person && $event;
    my $sql = <<EOL;
DELETE FROM person_to_event_map
WHERE person_id = ?
AND event_id = ?
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($person->id, $event->id);
}


sub create_table {

    my $dbh = get_dbh();

    my $sql = <<EOL;
CREATE TABLE person_to_event_map (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    person_id INTEGER NOT NULL,
    event_id INTEGER NOT NULL,
    role NOT NULL,   /* dancer, muso, soprano, bass */
	status NOT NULL,  /* yes, no, maybe, etc */
    updated TEXT(20) NOT NULl
);

EOL

    my $sth = $dbh->prepare($sql);
    $sth->execute;

    my $index_sql = <<EOL;
CREATE UNIQUE INDEX idx_person_to_event_map 
ON person_to_event_map 
(person_id, event_id, role);
EOL

    $sth = $dbh->prepare($index_sql);
    $sth->execute;
}

1;
