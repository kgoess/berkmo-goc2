#!/usr/bin/perl

use strict;
use warnings;

use lib '/usr/home/berkmo/mylib/lib/perl5';

BEGIN {
    $ENV{SQLITE_FILE} = '/usr/home/berkmo/web/data/goc-live.sqlite';
    $ENV{TT_INCLUDE_PATH} = '/usr/home/berkmo/web/templates';
    $ENV{GOC_URI_BASE} = '/cgi-bin/goc2.cgi';
    $ENV{GOC_STATIC_URI_BASE} = '/goc2';
    $ENV{GOC_DATE} = 'FreeBSD';
}

use GoC::Controller::CGI;

GoC::Controller::CGI->handler;


