#!/usr/bin/perl

use strict;
use warnings;

use Encode qw/encode_utf8/;

use GoC::MailSender;
use GoC::Model::Event;

if (@ARGV) {
    die "this script takes no arguments";
}

my $gigs = GoC::Model::Event->get_upcoming_events(type => 'gig');

foreach my $gig (@$gigs) {
    print "looking at ".$gig->name."\n" if -t STDIN;
    my $notification_email = $gig->notification_email
        or next;
    my $updates = $gig->update_prev_attendees;

    next unless $updates;

    my $event_name = $gig->name;

    my $sender = GoC::MailSender->new(
        to => $notification_email,
        subject => encode_utf8($event_name),
    );

    $sender->attach(
        Data => encode_utf8($updates),
        Type => 'text/plain',
        Encoding => 'binary',
    );

    $sender->send();

    print "sending update for $event_name to $notification_email:\n$updates\n\n" if -t STDIN;
}

