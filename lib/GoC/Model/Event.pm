package GoC::Model::Event;

use strict;
use warnings;

use Carp qw/croak/;
use DateTime;
use File::Temp qw/tempfile tempdir/;

use GoC::Model::Person;
use GoC::Utils qw/get_dbh today_ymd yesterday_ymd tomorrow_ymd date_format_pretty clone/;

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
    'group_notified_date',
    'go_nogo_date',
    '_days_until_go_nogo',
    'date_created',
    'date_updated',
#        'email',
#        'xx',
    ],
);

sub get_upcoming_events {
    my ($class, %p) = @_;

    my $type = $p{type} || croak "missing event type in call to $class->get_upcoming_events";

    my $yesterday = yesterday_ymd();

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

    my $tomorrow = tomorrow_ymd();

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

# e.g. event.get_num_persons(role => 'dancer', status => 'y')
sub get_num_persons {
    my ($self, %p) = @_;

    # TODO: move this into PersonEventMap.pm?
    my $sql = <<EOL;
    SELECT count(*)
    FROM person
        JOIN person_to_event_map
        ON person.id = person_to_event_map.person_id
    WHERE person.status = 'active'
        AND event_id = ?
EOL

    my @sql_args = ($self->id);

    if ($p{role}) {
        $sql .= 'AND role = ? ';
        push @sql_args, $p{role};
    }
    if ($p{status}) {
        $sql .= 'AND person_to_event_map.status = ? ';
        push @sql_args, $p{status};
    }

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(@sql_args);

    my @rc;

    my $row = $sth->fetchrow_arrayref;
    return $row->[0];
}

sub get_days_until_go_nogo {
    my ($self, $now) = @_;

    $now ||= DateTime->now();

    if (my $days_until = $self->_days_until_go_nogo) {
        return $days_until
    }
    my ($y, $m, $d);

    my $go_nogo_str = $self->go_nogo_date
        or return;
    ($y, $m, $d) = $go_nogo_str =~ /^([0-9]{4})-([0-9]{2})-([0-9]{2})$/
        or return;
    my $go_nogo_dt = DateTime->new(year => $y, month => $m, day => $d);

    my $delta = $go_nogo_dt->delta_days($now)->delta_days();

    $self->_days_until_go_nogo($delta);

    return $delta;
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
        my $person = GoC::Model::Person->load($row->{person_id});
        push @rc, $person if $person->status eq 'active';
    }
    @rc = sort { $a->name cmp $b->name } @rc;
    return @rc;
}

sub get_prev_next_ids {
    my ($self) = @_;

    # https://stackoverflow.com/questions/79498428/how-to-get-previous-next-ids
    my $sql_prev_next = <<EOL;
    SELECT id, date, name, prev_id, next_id
    FROM (
        SELECT id, date, name,
        LAG(id, 1) OVER (ORDER BY date, name, id) AS prev_id,
        LEAD(id, 1) OVER (ORDER BY date, name, id) AS next_id
        FROM event
        WHERE type = ?
          AND deleted != 1
    )
    WHERE id = ?
EOL
    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql_prev_next);
    $sth->execute($self->type, $self->id);
    my $row = $sth->fetchrow_hashref;
    return $row->{prev_id}, $row->{next_id};
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
        group_notified_date,
        go_nogo_date,
        date_created,
        date_updated
    )
    VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?);
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
            group_notified_date
            go_nogo_date
            date_created
            date_updated
        /
    );

    $self->id($dbh->sqlite_last_insert_rowid);
}

sub date_pretty {
    my ($self) = @_;
    my ($year, $month, $day) = $self->date =~ /(\d\d\d\d)-(\d\d)-(\d\d)/;

    return date_format_pretty($year, $month, $day);
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
            group_notified_date = ?,
            go_nogo_date = ?,
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
            group_notified_date
            go_nogo_date
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

    my $diff = `cd $dir && diff -U1000 \$(basename $orig_filename) \$(basename $new_filename)`;

    my $num_dancers = $self->get_num_persons(role => 'dancer', status => 'y') // 0;
    my $num_musos   = $self->get_num_persons(role => 'muso', status => 'y') // 0;

    my $text = <<EOL;
There are $num_dancers dancers and $num_musos musos confirmed.

Below is a diff showing the recent changes in attendance.
Lines marked with "-" show the previous status, lines marked
with "+" show the current status.

EOL

    #print STDERR "$text$diff"; # add if -t STDIN ?
    return $text . $diff;
}

sub get_pending_new_event_notifications {
    my ($class) = @_;

    # yesterday just as a failsafe
    my $yesterday = yesterday_ymd();

    my $sql = <<EOL;
    SELECT *
    FROM event
    WHERE
        group_notified_date IS NULL
        AND date >= '$yesterday';
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute();
    my @found;
    while (my $row = $sth->fetchrow_hashref) {
        push @found, bless $row, $class;
    }

    return @found;
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
    go_nogo_date TEXT(20),
    group_notified_date TEXT(20),
    date_created TEXT(20),
    date_updated TEXT(20)
);
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute;

    $sth = $dbh->prepare('CREATE INDEX event_date_idx ON event (date)');
    $sth->execute;
    $sth = $dbh->prepare('CREATE INDEX event_date_multi_idx ON event (date, type, deleted)');
    $sth->execute;
    $sth = $dbh->prepare('CREATE INDEX event_id_multi_idx ON event (id, type, deleted)');
    $sth->execute;
    $sth = $dbh->prepare('CREATE INDEX event_type_idx ON event (type, deleted)');
    $sth->execute;

}

1;
__DATA__
