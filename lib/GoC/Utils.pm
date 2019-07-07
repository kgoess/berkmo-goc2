package GoC::Utils;


use strict;
use warnings;

use DBI;

use Exporter 'import';
our @EXPORT_OK = qw(get_dbh today_ymd today_ymdhms);


my $_dbh;
sub get_dbh {

    my $dbfile = $ENV{SQLITE_FILE} || die "missing SQLITE_FILE IN env";

    $_dbh ||= DBI->connect("dbi:SQLite:dbname=$dbfile","","", {
        RaiseError => 1,
    });

    return $_dbh;
}

sub today_ymd {
	return DateTime->now(time_zone => 'America/Los_Angeles')->ymd;
}
sub today_ymdhms {
	return DateTime->now(time_zone => 'America/Los_Angeles')->datetime;
}

1;
