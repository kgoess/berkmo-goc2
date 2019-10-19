package GoC::Model::Event;

use strict;
use warnings;

use Carp qw/croak/;
use DateTime;
use File::Temp qw/tempfile tempdir/;

use GoC::Model::Person;
use GoC::Utils qw/get_dbh today_ymd clone/;

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
    'prev_attendees',
    'num_dancers_required',
    'num_musos_required',
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

sub get_past_events {
    my ($class, %p) = @_;

    #my $type = $p{type} || croak "missing event type in call to $class->get_past_events";

    my $tomorrow = DateTime
        ->now
        ->add( days => 1 )
        ->ymd;

    my $sql = <<EOL;
    SELECT * FROM event
    WHERE date <= '$tomorrow'
    --AND type = ?
    AND deleted != 1
    ORDER BY date DESC, name ASC
    LIMIT ?
EOL
    my $limit = $p{limit} || 50;
    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($limit);
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

sub get_num_persons {
    my ($self, %p) = @_;

    # TODO: move this into PersonEventMap.pm?
    my $sql = <<EOL;
    SELECT count(*)
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

    my $row = $sth->fetchrow_arrayref;
    return $row->[0];
}

sub count_is_ok {
    my ($self) = @_;

    my $sql = <<EOL;
    SELECT role, count(*) as count
    FROM person_to_event_map
    WHERE event_id = ?
    AND status = 'y'
    GROUP BY role
EOL

    my @sql_args = ($self->id);

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(@sql_args);

    my %count;
    while (my $row = $sth->fetchrow_hashref) {
        my ($role, $count) = @{$row}{qw/role count/};
        $count{$role} = $count;
    }

    my $rc = ($count{dancer}//0) >= $self->num_dancers_required
            && ($count{muso}//0) >= $self->num_musos_required;
    return $rc;
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

sub get_prev_next_ids {
    my ($self) = @_;

    my $yesterday = DateTime
        ->now
        ->subtract( days => 1 )
        ->ymd;

    my $sql_prev = <<EOL;
        SELECT id, date, name
        FROM event
        WHERE date <= ?
        AND date >= '$yesterday'
        AND id != ?
        AND type = ?
        AND deleted != 1
        ORDER BY date DESC, name ASC
        LIMIT 1
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql_prev);
    $sth->execute($self->date, $self->id, $self->type);
    my $prev_id;
    if (my $row = $sth->fetchrow_hashref) {
        $prev_id = $row->{id};
    }
    my $sql_next = <<EOL;
        SELECT id, date, name
        FROM event
        WHERE date >= ?
        AND date >= '$yesterday'
        AND id != ?
        AND type = ?
        AND deleted != 1
        ORDER BY date ASC, name ASC
        LIMIT 1
EOL
    $sth = $dbh->prepare($sql_next);
    $sth->execute($self->date, $self->id, $self->type);
    my $next_id;
    if (my $row = $sth->fetchrow_hashref) {
        $next_id = $row->{id};
    }
    return $prev_id, $next_id;
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
        num_dancers_required,
        num_musos_required,
        deleted,
        date_created,
        date_updated
    )
    VALUES (?,?,?,?,?,?,?,?,?,?,?);
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
        qw/ name
            date
            queen
            notification_email
            type
            notes
            num_dancers_required
            num_musos_required
            deleted
            date_created
            date_updated
        /
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
            prev_attendees = ?,
            deleted = ?,
            num_dancers_required = ?,
            num_musos_required = ?,
            date_updated = ?
            /* date_created not updatable */
        WHERE id = ?
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $self->date_updated(today_ymd());
    $sth->execute(
        map { $self->$_ }
        qw/
            name
            date
            queen
            notification_email
            type
            notes
            prev_attendees
            deleted
            num_dancers_required
            num_musos_required
            date_updated
           id
        /
    );
}

sub update_prev_attendees {
    my ($self) = @_;

    my @persons = $self->get_persons;
    my $statuses = '';
    foreach my $person (sort { $a->name cmp $b->name } @persons) {
        $statuses .= $person->name.': '.join(' ', $self->get_status_for_person($person))."\n";
    }
    if (($self->prev_attendees//'') eq ($statuses//'')) {
        return;
    }

    my $orig = $self->prev_attendees || '';
    my $prev_updated = $self->date_updated;

    $self->prev_attendees($statuses);
    $self->save;

    my $dir = tempdir( CLEANUP => 1 );

    my ($orig_fh, $orig_filename) =
        tempfile(DIR => $dir, TEMPLATE => "list-from-$prev_updated-XXXXX" );
    print $orig_fh $orig;
    close $orig_fh;
    my $today = today_ymd();
    my ($new_fh, $new_filename) =
        tempfile(DIR => $dir, TEMPLATE => "current-attendee-list-$today-XXXXX");
    print $new_fh $statuses;
    close $new_fh;

    my $diff = `cd $dir && diff -u \$(basename $orig_filename) \$(basename $new_filename)`;
    return $diff;
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
    prev_attendees VARCHAR(1024),
    num_dancers_required INT default 10,
    num_musos_required INT default 1,
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
