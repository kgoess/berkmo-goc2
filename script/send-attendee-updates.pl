#!/usr/bin/perl

use strict;
use warnings;

use GoC::Model::Event;

my $gigs = GoC::Model::Event->get_upcoming_events(type => 'gig');

foreach my $gig (@$gigs) {
    print "looking at ".$gig->name."\n" if -t STDIN;
    my $notification_email = $gig->notification_email
        or next;
    my $updates = $gig->update_prev_attendees;

    next unless $updates;

    (my $clean_event_name = $gig->name) =~ s/[^\w _.-]//g;

    my $target_address = quotemeta $notification_email;

    print "sending update for $clean_event_name to $notification_email:\n$updates\n\n" if -t STDIN;
    open my $fh, '|-', "/usr/bin/mail -s 'attendee list has changed for $clean_event_name' $target_address" 
        or die "can't pipe to mail $!";

    print $fh $target_address;

    close $fh or die "can't write to mail $!";
    # bvh doesn't have /usr/bin/mail, see /usr/local/bin/check-dyn-ip.pl for alternative
}

