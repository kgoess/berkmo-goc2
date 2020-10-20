#!/bin/sh -x

set -e 

cp cgi-bin/goc-walton.cgi ~/berkeleymorris.org/goc2.cgi

cp -rf static/* ~/berkeleymorris.org/goc2/

cp script/send-attendee-updates.pl ~/bin/

cp script/send-event-notifications.pl ~/bin/

cp -rf templates ~/goc2/

