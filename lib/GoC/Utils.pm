package GoC::Utils;


use strict;
use warnings;

use DBI;

use Exporter 'import';
our @EXPORT_OK = qw(get_dbh);


my $_dbh;
sub get_dbh {

    my $dbfile = $ENV{SQLITE_FILE} || die "missing SQLITE_FILE IN env";

    $_dbh ||= DBI->connect("dbi:SQLite:dbname=$dbfile","","", {
        RaiseError => 1,
    });

    return $_dbh;
}



1;
