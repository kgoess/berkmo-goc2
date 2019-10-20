#!/bin/sh -x

cp cgi-bin/goc-moggy.cgi ~/web/cgi-bin/goc2.cgi

cp -rf lib/GoC* ~/mylib/lib/perl5/

cp -rf static/* ~/web/docs/goc2/

cp script/send-attendee-updates.pl ~/bin/
