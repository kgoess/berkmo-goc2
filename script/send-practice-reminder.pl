#!/usr/bin/env perl

# this is run from cron:
# 8	8	*	*	2

use strict;
use warnings;
use utf8;

use Email::Stuffer;


my $html_part = <<EOL;
<div>
Hello everyone,
</div>

<div>
Practice tonight will be held in the hall at Christ Church, 2138 Cedar St, Berkeley, CA 94709.
</div>

<div>
If Zoom is still a thing, <a
href="https://us02web.zoom.us/j/82579720636?pwd=OEp6MUlrcHNJSjREeGk5NjEvY3JkZz09">here's
the link</a>. We're bad at this, so if you want it, remind us to start the
meeting.
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

# works
# my $to = 'kgtesting@groups.io';
# untested
my $to = 'berkmorris-business@groups.io';
my $subject = 'Practice reminder + excuses thread';

my $stuffer = Email::Stuffer
    # works
    #->from       ('Luke Hillman <kevin@goess.org>')
    # untested
    ->from       ('Luke Hillman <contact@lukehillman.net>')
    ->to         ("Berkeley Morris <$to>")
    ->subject    ($subject)
    #->text_body  ($text_part)
    ->html_body($html_part)
;

open my $fh, '|-', "/usr/sbin/sendmail -i $to" 
    or die "can't pipe to mail $!";

print $fh $stuffer->as_string;

close $fh or die "can't write to mail $!";


