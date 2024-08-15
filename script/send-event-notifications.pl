#!/usr/bin/env perl

# this is run from cron:
# 3	*	*	*	*

use strict;
use warnings;

use GoC::Model::Event;
use GoC::Utils qw/today_ymd/;

my @events = GoC::Model::Event->get_pending_new_event_notifications;

my $today = today_ymd();

foreach my $event (@events) {
    print "sending event notification for ".$event->name."\n" if -t STDIN;
    send_group_notification($event);
    $event->group_notified_date($today);
    $event->update;
}


sub send_group_notification {
    my ($event) = @_;

    my $target_address = 'berkmorris-business@berkeley-morris.org';
    $ENV{REPLYTO} = 'berkmorris-business@berkeley-morris.org';
    #$ENV{REPLYTO} = 'kevin@goess.org';

    my ($name, $date, $type) = ($event->name, $event->date, $event->type);

    (my $clean_name = $name) =~ s/[^\w _.-]//g;
    $date =~ s/[^\d-]//g;

    my $exhortation = exhortation();


    open my $fh, '|-', "/usr/bin/mail -s 'a new $type on the grid: $clean_name' $target_address"
        or die "can't pipe to mail $!";
    print $fh <<EOL;
A new $type has been added to the grid of commitment!

    $date $name

$exhortation

https://www.berkeleymorris.org/goc2.cgi


--The Grid of Committment

EOL
    close $fh or die "can't write to mail $!";


    open $fh, '|-', "/usr/bin/mail -s 'testing body: a new $type on the grid: $clean_name' kevin\@goess.org"
        or die "can't pipe to mail $!";
    print $fh <<EOL;
A new $type has been added to the grid of commitment!

    $date $name

$exhortation

https://www.berkeleymorris.org/goc2.cgi


--The Grid of Committment

EOL
    close $fh or die "can't write to mail $!";
}

sub exhortation {

    my @exhortations = (
        q{Take life by the lapels and tell the grid that yes you're coming, or no you're bailing, or maybe you're not sure...},
        q{Show that you care and tell the grid yes, or no, or maybe. The tour queen will thank you!},
        q{Come, see, conquer, update your spot on the grid!},
        q{Life is 10% what happens to you and 90% how you react to it. React by updating the grid!},
        q{Remember, that which does not kill you postpones the inevitable. Mark your spot on the grid, please.},
        q{Wise men say that a journey of a thousand miles starts with updating the grid.},
        q{When birds fly in formation, they need only exert half the effort. Even in nature, teamwork results in collective laziness. Update your spot on the team grid now.},
        q{Until you have the courage to lose sight of the shore, you will not know the terror of being lost at sea. Come and update the grid.},
        q{You'll always miss 100% of the shots you don't take, and, statistically speaking, 99% of the shots you do. So sign up on the grid.},
        q{Well done is better than well said. Do it. Claim your spot on the grid.},
        q{Only you can change your life. No one can do it for you. The grid is waiting for your answer.},
        q{The will to win, the desire to succeed, the urge to reach your full potential...these are the things that will lead you to putting your answer on the grid.},
        q{We shall fight on the beaches, we shall fight on the landing grounds, we shall fight in the fields and in the streets, we shall fight in the hills; we will let the rest of the team know what we're doing and mark up the grid.},
        q{He that outlives this day, and comes safe home, will stand a tip-toe when this day is nam'd, and rouse him at the name of Crispian, and will add his name to the grid with whether he's going to come or no.},
        q{And now abideth faith, hope, charity, these three; but the greatest of these is updating the grid with your plans.},
        q{Who acts from love is greater than who acts from fear. And who updates the grid beats them all.},
        q{There is no such thing as a small act; there are only small people. And the ones who don't update the grid.},
        q{Who is wise? He who learns from all men. And who is coming to this event? He who updates the grid.},
    );
    my $exhortation = $exhortations[rand @exhortations];
    return $exhortation;
}
