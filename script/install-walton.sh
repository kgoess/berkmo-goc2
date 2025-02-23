#!/bin/sh -x

# this also works for iad1-shared-e1-28 on dreamhost, the new version of walton
#

set -e 


echo See the README.md for the steps to install the perl libraries

cp cgi-bin/goc-walton.cgi ~/berkeleymorris.org/goc2.cgi

cp -rf static/* ~/berkeleymorris.org/goc2/

cp script/send-attendee-updates.pl ~/bin/

cp script/send-event-notifications.pl ~/bin/

cp -rf templates ~/goc2/

