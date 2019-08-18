package GoC::Utils;


use strict;
use warnings;

use DBI;

use Exporter 'import';
our @EXPORT_OK = qw(
    get_dbh
    static_uri_for
    today_ymd
    today_ymdhms
    uri_escape
    uri_for
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

# TODO need to worry about escaping here
sub uri_for {
    my %p;
    if (ref $_[0] eq 'HASH') { # TT sends a hashref
        %p = %{ $_[0] };
    } else {
        %p = @_;
    }

    my $path = delete $p{path} || '/';

    my $base = $ENV{GOC_URI_BASE} or die "GOC_URI_BASE is unset in ENV";

    my $url_params = '';
    if (keys %p) {
        $url_params = '&'; # will also be different for mod_perl
        $url_params .= join '&', map { "$_=$p{$_}" } sort keys %p;
    }


    #FIXME this will be different for mod_perl
    return "$base?path=$path$url_params";
}

sub static_uri_for {
    my ($path) = @_;

    my $base = $ENV{GOC_STATIC_URI_BASE} or die "GOC_STATIC_URI_BASE is unset in ENV";

    return "$ENV{GOC_STATIC_URI_BASE}/$path";
}

1;
