package GoC::Utils;


use strict;
use warnings;

use DBI;

use Exporter 'import';
our @EXPORT_OK = qw(
    clone
    get_dbh
    today_ymd
    today_ymdhms
    uri_escape
);


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

# borrowed from URI::Escape
# Build a char->hex map
my %Escapes;
for (0..255) {
    $Escapes{chr($_)} = sprintf("%%%02X", $_);
}
my %Unsafe = (
    RFC3986 => qr/[^A-Za-z0-9\-\._~]/,
);

sub uri_escape {
    my($text) = @_;
    return undef unless defined $text;
    $text =~ s/($Unsafe{RFC3986})/$Escapes{$1} || _fail_hi($1)/ge;
    return $text;
}
sub _fail_hi {
    my $chr = shift;
    Carp::croak(sprintf "Can't escape \\x{%04X}, try uri_escape_utf8() instead", ord($chr));
}


sub clone {
    my ($self) = @_;
    my %clone = %$self;
    return bless \%clone, ref $self;
}



1;
