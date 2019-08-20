package GoC::Model::Event;

use strict;
use warnings;

use Carp qw/croak/;
use DateTime;

use GoC::Model::Person;
use GoC::Utils qw/get_dbh today_ymd/;

use Class::Accessor::Lite(
    new => 1,
    rw  => [
    'id',
    'name',
    'date',
    'queen',  # name, whatever, not a FK
    'notification_email', 
    'type', # gig, party
    'notes',
    'deleted',
    'date_created',
    'date_updated',
#        'email',
#        'xx',
    ],
);

sub get_upcoming_events {
    my ($class, %p) = @_;

    my $type = $p{type} || croak "missing event type in call to $class->get_upcoming_events";

    my $yesterday = DateTime
        ->now
        ->subtract( days => 1 )
        ->ymd;

    my $sql = <<EOL;
    SELECT * FROM event
    WHERE date >= '$yesterday'
    AND type = ?
    AND deleted != 1
    ORDER BY date, name
EOL
    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($type);
    my @rc;
    while (my $row = $sth->fetchrow_hashref) {
        push @rc, GoC::Model::Event->new($row);
    }
    return \@rc;
}

sub get_status_for_person {
    my ($self, $person) = @_;

    my $sql = <<EOL;
    SELECT status, role
    FROM person_to_event_map
    WHERE event_id = ?
    AND person_id = ?
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($self->id, $person->id);

    if (my $row = $sth->fetchrow_arrayref) {
        return @$row;
    }
}
    


sub get_persons {
    my ($self, %p) = @_;

    # TODO: move this into PersonEventMap.pm?
    my $sql = <<EOL;
    SELECT person_id
    FROM person_to_event_map
    WHERE event_id = ?
EOL

    my @sql_args = ($self->id);

    if ($p{role}) {
        $sql .= 'AND role = ? ';
        push @sql_args, $p{role};
    }
    if ($p{status}) {
        $sql .= 'AND status = ? ';
        push @sql_args, $p{status};
    }

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(@sql_args);

    my @rc;

    while (my $row = $sth->fetchrow_hashref) {
        push @rc, GoC::Model::Person->load($row->{person_id});
    }
    @rc = sort { $a->name cmp $b->name } @rc;
    return @rc;
}
sub save {
    my ($self) = @_;

    if ($self->id) {
        return $self->update;
    }

    my $sql = <<EOL;
    INSERT INTO event (
        name,
        date,
        queen,
        notification_email,
        type,
        notes,
        deleted,
        date_created,
        date_updated
    )
    VALUES (?,?,?,?,?,?,?,?,?);
EOL

    if (! $self->date_created) {
        $self->date_created(today_ymd());
    }
    if (! $self->date_updated) {
        $self->date_updated(today_ymd());
    }
    if (! defined $self->deleted) {
        $self->deleted(0)
    }

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(
        map { $self->$_ } 
        qw/name date queen notification_email type notes deleted date_created date_updated/
    );

    $self->id($dbh->sqlite_last_insert_rowid);
}

sub date_pretty {
    my ($self) = @_;
    my ($year, $month, $day) = $self->date =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;
    my $datetime = DateTime->new(
        year => $year,
        month => $month,
        day => $day,
    );

    return $datetime->strftime("%a, %b %e");
}


sub load {
    my ($class, $id, %p) = @_;

    croak "missing id in call to $class->load" unless $id;

    my $sql = 'SELECT * FROM event WHERE id = ?';

    if ($p{include_deleted}) {
        $sql .= ' AND deleted = 1 ';
    } else {
        $sql .= ' AND deleted = 0 ';
    }

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($id);
    if (my $row = $sth->fetchrow_hashref) {
        return bless $row, $class;
    } else {
        return;
    }
}

sub update {
    my ($self) = @_;

    my $sql = <<EOL;
        UPDATE event SET
            name = ?,
            date = ?,
            queen = ?,
            notification_email = ?,
            type = ?,
            notes = ?,
            deleted = ?,
            date_updated = ?
            /* date_created not updatable */
        WHERE id = ?
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $self->date_updated(today_ymd());
    $sth->execute(
        map { $self->$_ } 
        qw/name date queen notification_email type notes deleted date_updated
           id
        /
    );
}

sub create_table {
    my ($class) = @_;

    my $sql = <<EOL;
CREATE TABLE event (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(255),
    date TEXT(20),
    queen VARCHAR(255),
    notification_email VARCHAR(64),
    type VARCHAR(255),
    notes VARCHAR(1024), /* length is ignored */
    deleted BOOLEAN NOT NULL DEFAULT 0,
    date_created TEXT(20),
    date_updated TEXT(20)
);
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute;
}

1;
__DATA__
