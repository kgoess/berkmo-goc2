#!/usr/bin/perl

use strict;
use warnings;

use lib (
    "/home/lucybear/perl5/lib/perl5",
    "/home/lucybear/perl5/lib/perl5/x86_64-linux-gnu-thread-multi/",
);

BEGIN {
    $ENV{SQLITE_FILE} = '/home/lucybear/goc2/db/goc-live.sqlite';
    $ENV{TT_INCLUDE_PATH} = '/home/lucybear/goc2/templates/';
    $ENV{GOC_URI_BASE} = '/goc2.cgi';
    $ENV{GOC_STATIC_URI_BASE} = '/goc2';
}

use GoC::Controller::CGI;

GoC::Controller::CGI->handler;


