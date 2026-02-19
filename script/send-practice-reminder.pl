#!/usr/bin/env perl

# this is run from cron:
# 8	8	*	*	2

use 5.16.0;
use warnings;
use utf8;

$ENV{GOC_URI_BASE} = 'https://berkeleymorris.org/goc2.cgi';

use Encode qw/encode_utf8/;
use Getopt::Long;

use GoC::View;
use GoC::MailSender;
use GoC::Model::Event;
use GoC::Utils qw/uri_escape/;

my ($to, $help);
GetOptions(
    'to=s' => \$to,
    'h|help' => \$help,
);

if (!($to) || $help) {
    my $usage = <<EOL;

    usage: $0
        --to 'bob <bob\@example.com>'
        --debug

        -h|--help this help

    set SMTP_DEBUG=1 for some output
EOL
    say $usage;
    exit 1;
}

my $html_part_template = <<EOL;
<div>
Hello everyone,
</div>

<div>
Practice tonight will be held at the Berkeley Fellowship of
Unitarian Universalists hall at 1606 Bonita Ave., Berkeley, CA 94709
</div>
<div>
Not going to make it? Reply to this message with your best excuse, real or
fictional. This will keep practice-related conversation confined to one thread
and make everyone's inboxes easier to manage.
</div>

<div>
<p>
<b>Upcoming Gigs:</b>
</p>
[% PROCESS eventtable
    events = gigs
-%]
<p>
<b>Upcoming Parties:</b>
</p>
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

<p>
Cheers,<br>
Your Friendly Neighborhood Practice Reminder Bot
</p>

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

my $subject = 'Practice reminder + excuses thread';

my $sender = GoC::MailSender->new(
    to => $to,
    subject => $subject,
);

$sender->attach(
    Data => encode_utf8($html_part),
    Type => 'text/html',
    Encoding => 'binary',
);

$sender->send();


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
