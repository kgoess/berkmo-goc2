#!/Users/kevin/perl5/perlbrew/perls/perl-5.34.0/bin/perl

use strict;
use warnings;

use lib '/Users/kevin/git/berkmo-goc2/lib';
use lib '/Users/kevin/goc-lib/lib/perl5';


$ENV{SQLITE_FILE} = '/var/lib/goc/goc.sqlite';
$ENV{TT_INCLUDE_PATH} = '/Users/kevin/git/berkmo-goc2/templates';
$ENV{GOC_URI_BASE} = '/cgi-bin/goc.cgi';
$ENV{GOC_STATIC_URI_BASE} = '/goc2-static/static';

use GoC::Controller::CGI;

GoC::Controller::CGI->handler;


