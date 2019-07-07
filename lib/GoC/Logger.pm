package GoC::Logger;

use strict;
use warnings;

use Data::Dump qw/dump/;

use GoC::Utils qw/get_dbh today_ymdhms/;

use Class::Accessor::Lite(
    new => 1,
    rw  => [
    'current_user',
    ],
);

sub info {
    my ($self, $msg) = @_;

    $self->logit($msg, 'info');
}
sub debug {
    my ($self, $msg) = @_;

    $self->logit($msg, 'debug');
}


sub logit {
    my ($self, $msg, $level) = @_;
    my $sql = <<EOL;
    INSERT INTO log (
        timestamp,
        level,
        actor_id,
        actor_name,
        message
    )
    values (?,?,?,?,?);
EOL
    
    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute(
        today_ymdhms(), 
        $level,
        $self->current_user->id, 
        $self->current_user->name,
        $msg);
}

sub get_log_lines {
    my ($class) = @_;

    my $sql = <<EOL;
    SELECT * 
    FROM log 
    WHERE level = 'info'
    ORDER BY timestamp DESC
    LIMIT 1000
EOL
    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute;
    my @results;
    while (my $row = $sth->fetchrow_hashref) {
        push @results, $row;
    }
    return \@results;
}



sub create_table {
    my ($class) = @_;

    my $sql = <<EOL;
CREATE TABLE log (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    level TEXT NOT NULL,
    actor_id INT NOT NULL,
    actor_name TEXT NOT NULL,
    message VARCHAR(255) NOT NULL
);
EOL

    my $dbh = get_dbh();
    my $sth = $dbh->prepare($sql);
    $sth->execute;
}

1;
