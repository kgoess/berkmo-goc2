package GoC::Utils;


use strict;
use warnings;

use DBI;
if (!$ENV{GOC_DATE}) {
    require DateTime;
}

use Exporter 'import';
our @EXPORT_OK = qw(
    clone
    get_dbh
    today_ymd
    tomorrow_ymd
    yesterday_ymd
    today_ymdhms
    date_format_pretty
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

sub clear_dbh { undef $_dbh }; # for tests

$ENV{TZ} = 'America/Los_Angeles';

sub today_ymd {
    my $s;
    if (use_bsd_date()) {
        $s = `date -j '+%Y-%m-%d'`;
        chomp $s;
    } else {
        $s = DateTime->now(time_zone => 'America/Los_Angeles')->ymd;
    }
    return $s;
}
sub today_ymdhms {
    my $s;
    if (use_bsd_date()) {
        $s = `date -j '+%Y-%m-%dT%H:%M:%S'`;
        chomp $s;
    } else {
        $s = DateTime->now(time_zone => 'America/Los_Angeles')->datetime;
    }
    return $s;
}
sub yesterday_ymd {
    my $s;

    if (use_bsd_date()) {
        $s = `date -j -v -1d '+%Y-%m-%d'`;
        chomp $s;
    } else {
        $s = DateTime
            ->now
            ->subtract( days => 1 )
            ->ymd;
    }
    return $s;

}
sub tomorrow_ymd {
    my $s;

    if (use_bsd_date()) {
        $s = `date -j -v +1d '+%Y-%m-%d'`;
        chomp $s;
    } else {
        $s = DateTime
            ->now
            ->add( days => 1 )
            ->ymd;
    }
    return $s;
}

sub date_format_pretty {
    my ($y, $m, $d) = @_;

    my $date = sprintf("%04d%02d%02d", $y, $m, $d);

    my $s;
    if (use_bsd_date()) {
        $s = `date -j -f '%Y%m%d' $date '+%a, %b %e'`;
        chomp $s;
    } else {
        my $datetime = DateTime->new(
            year  => $y,
            month => $m,
            day   => $d,
        );
        $s = $datetime->strftime("%a, %b %e");
    }

    return $s;
}

sub use_bsd_date {
    return ($ENV{GOC_DATE}//'') eq 'FreeBSD';
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
