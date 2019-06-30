package GoC::Utils;


use strict;
use warnings;

use DBI;

use Exporter 'import';
our @EXPORT_OK = qw(get_dbh);


sub get_dbh {

    my $dbfile = $ENV{SQLITE_FILE} || die "missing SQLITE_FILE IN env";

    my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile","","", {
        RaiseError => 1,
    });

    return $dbh;
}



1;
