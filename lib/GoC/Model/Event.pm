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
    'queen',  # name, email, whatever, not a FK
    'type', # gig, party
    'notes',
    'status',
    'deleted',
    'date_created',
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


sub get_persons {
    my ($self, %p) = @_;


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

    my $sql = <<EOL;
    INSERT INTO event (
        name,
        date,
        queen,
        type,
        notes,
        deleted,
        date_created
    )
    VALUES (?,?,?,?,?,?,?);
EOL

    if (! $self->date_created) {
        $self->date_created(today_ymd());
    }

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(map { $self->$_ } qw/name date queen type notes deleted date_created/);

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
    my ($class, $id) = @_;

    croak "missing id in call to $class->load" unless $id;

    my $sql = <<EOL;
        SELECT * FROM event WHERE id = ?;
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($id);
    return bless $sth->fetchrow_hashref, $class;
}

sub update {
    my ($self) = @_;

    my $sql = <<EOL;
        UPDATE event SET
            name = ?,
            date = ?,
            queen = ?,
            type = ?,
            notes = ?,
            deleted = ?
            /* date_created not updatable */
        WHERE id = ?
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(map { $self->$_ } qw/name date queen type notes deleted id/);
}

sub create_table {
    my ($class) = @_;

    my $sql = <<EOL;
CREATE TABLE event (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(255),
    date TEXT(20),
    queen VARCHAR(255),
    type VARCHAR(255),
    notes VARCHAR(1024), /* length is ignored */
    status VARCHAR(255),
    deleted BOOLEAN,
    date_created TEXT(20)
);
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute;
}

1;
__DATA__
