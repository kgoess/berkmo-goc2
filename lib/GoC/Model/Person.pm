package GoC::Model::Person;

use strict;
use warnings;

use Carp qw/croak/;

use GoC::Utils qw/get_dbh clone/;

use Class::Accessor::Lite(
    new => 1,
    rw  => [
    'id',  # the db primary key
    'name',
    'status', # active/inactive, etc.
    'deleted',

#        'email',
#        'xx',
    ],
);

sub save {
    my ($self) = @_;

    if ($self->id) {
        return $self->update;
    }

    my $sql = <<EOL;
    INSERT INTO person (
        name,
        status
    )
    VALUES (?,?);
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($self->name, $self->status);;

    $self->id($dbh->sqlite_last_insert_rowid);
}

sub load {
    my ($class, $id, %p) = @_;

    croak "missing id in call to $class->load" unless $id;

    my $sql = 'SELECT * FROM person WHERE id = ?';

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute($id);
    if (my $row = $sth->fetchrow_hashref) {
        return bless $row, $class;
    } else {
        return;
    }
}

sub get_all {
    my ($class, %p) = @_;

    my $sql = 'SELECT * FROM person';

    my @sql_args;


    my @where_clauses;

    if ($p{status}) {
        push @where_clauses, "status = ?";
        push @sql_args, $p{status};
    }
    if ($p{except_ids}) {
        push @where_clauses, "id NOT IN (".join(',', @{$p{except_ids}}).")";
    }
    if (@where_clauses) {
        $sql .= ' WHERE '. join(' AND ', @where_clauses);
    }
    $sql .= ' ORDER BY name ASC ';

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(@sql_args);
    my @rc;
    while (my $row = $sth->fetchrow_hashref) {
        push @rc, $class->new($row);
    }
    return @rc;
}


sub update {
    my ($self) = @_;

    my $sql = <<EOL;
        UPDATE person SET
            name = ?,
            status = ?,
            deleted = ?
        WHERE id = ?
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(map { $self->$_ } qw/name status deleted id/);
}

sub create_table {

    my $dbh = get_dbh();

    my $sql = <<EOL;
CREATE TABLE person (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name VARCHAR(255),
    status VARCHAR(255),
    deleted BOOLEAN
);
EOL
    my $sth = $dbh->prepare($sql);
    $sth->execute;
}
1;

__DATA__

