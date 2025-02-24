#!/usr/bin/env perl

# this is run from cron:
# 8	8	*	*	2

use 5.16.0;
use warnings;
use utf8;

$ENV{GOC_URI_BASE} = '/goc2.cgi';

use Email::Stuffer;
use Getopt::Long;

use GoC::View;
use GoC::Model::Event;
use GoC::Utils qw/uri_escape/;

my ($from, $to, $help);
GetOptions(
    'from=s' => \$from,
    'to=s' => \$to,
    'h|help' => \$help,
);

if (!($from && $to) || $help) {
    my $usage = <<'EOL';

    usage: $0
        --from    'alice <alice@example.com>'
        --to      'bob <bob@example.com>'

        -h|--help this help
EOL
    say $usage;
    exit 1;
}

my $html_part_template = <<EOL;
<div>
Hello everyone,
</div>

<div>
Practice tonight will be held <strong>IN THE NEW HALL</strong> at the Berkeley Fellowship of
Unitarian Universalists hall at 1606 Bonita Ave., Berkeley, CA 94709
</div>
<br>

<div>
<b>🚨 COVID precautions 🚨</b>
<ul>
    <li>You must have received a negative result (and not a positive result) on a
    rapid test sometime in the 24 hours leading up to practice. If you're out of
    tests, just ask! We can help each other out.
    <li>You must be fully vaccinated + boosted
    <li>Masks encouraged
</ul>
</div>

<div>
Not going to make it? Reply to this message with your best excuse, real or
fictional. This will keep practice-related conversation confined to one thread
and make everyone's inboxes easier to manage.
</div>

<div>
<div>
<b>Upcoming Gigs:</b>
</div>
[% PROCESS eventtable
    events = gigs
-%]
<div>
<b>Upcoming Parties:</b>
</div>
[% PROCESS eventtable
    events = parties
-%]
[% BLOCK eventtable -%]
    [% FOREACH event IN events -%]
        <p>[% event.date_pretty  | html -%]
        <a href="[% uri_for(path => '/event', id => event.id) %]">
        [% event.name | html -%]
        </a>
        <br>
        Confirmed: [% event.get_num_persons('role', 'dancer', 'status', 'y') || 0 | html %] dancers / [% event.get_num_persons('role', 'muso', 'status', 'y') || 0 | html %] musos<br>
        Not Coming: [% event.get_num_persons('role', 'dancer', 'status', 'n') || 0 | html %] dancers / [% event.get_num_persons('role', 'muso', 'status', 'n') || 0 | html %] musos<br>
        Unsure: [% event.get_num_persons('role', 'dancer', 'status', '?') || 0 | html %] dancers / [% event.get_num_persons('role', 'muso', 'status', '?') || 0 | html %] musos<br>
        [% IF ! event.count_is_ok && event.get_days_until_go_nogo -%]
            [% event.get_days_until_go_nogo %] days until go/no-go<br>
        [% END -%]
    [% END -%]
[% END -%]
</div>

<div>
Cheers,<br>
Your Friendly Neighborhood Practice Reminder Bot
</div>

EOL


my $tt = Template->new();

my $html_part;
my %vars = (
    uri_for        => \&uri_for,
    gigs    => GoC::Model::Event->get_upcoming_events(type => 'gig'),
    parties => GoC::Model::Event->get_upcoming_events(type => 'party'),

);
$tt->process(\$html_part_template, \%vars, \$html_part)
    or die $tt->error;

my $sendmail_to = $to;
if ($sendmail_to =~ /<(.+)?>/) {
    $sendmail_to = $1;
}

my $subject = 'Practice reminder + excuses thread';

my $stuffer = Email::Stuffer
    ->from       ($from)
    ->to         ($to)
    ->subject    ($subject)
    #->text_body  ($text_part)
    ->html_body($html_part)
;

#open my $logfh, ">", "/home/lucybear/berkeleymorris.org/kgtesting.html";
#say $logfh '<html>';
#say $logfh scalar localtime;
#say $logfh $stuffer->as_string;
#say $logfh '</html>';
#close $logfh;
#exit;

open my $fh, '|-', "/usr/sbin/sendmail -i $sendmail_to"
    or die "can't pipe to mail $!";

print $fh $stuffer->as_string;

close $fh or die "can't write to mail $!";


# copied from GoC::Controller::ModPerl because moving it to a shared spot is
# more than I have time for ATM
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
        $url_params .= join '&', map { "$_=".uri_escape($p{$_}) } sort keys %p;
    }

    return "$base?path=$path$url_params";
}
