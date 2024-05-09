#!/usr/bin/env perl

# this is run from cron:
# 8	8	*	*	2

use 5.16.0;
use warnings;
use utf8;

use Email::Stuffer;
use Getopt::Long;

my ($from, $to, $help);
GetOptions(
    'from=s' => \$from,
    'to=s' => \$to,
    'h|help' => \$help,
);

if (!($from && $to) || $help) {
    my $usage = <<'EOL';

    usage: $0
        --from    'alice <aliace@example.com>'
        --to      'bob <bob@example.com>'

        -h|--help this help
EOL
    say $usage;
    exit 1;
}

my $html_part = <<EOL;
<div>
Hello everyone,
</div>

<div>
Practice tonight will be held in the hall at Christ Church, 2138 Cedar St, Berkeley, CA 94709.
</div>

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
Cheers,<br>
Luke
</div>

EOL

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

open my $fh, '|-', "/usr/sbin/sendmail -i $sendmail_to"
    or die "can't pipe to mail $!";

print $fh $stuffer->as_string;

close $fh or die "can't write to mail $!";


