# Berkmo GoC2

A new Grid of Committment


# Misc notes:


/usr/bin/sqlite3 -column -header ~/goc2/db/goc-live.sqlite


eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)
# or the old way PERL5LIB="$HOME/perl5/lib/perl5${PERL5LIB:+:${PERL5LIB}}"; export PERL5LIB;

SQLITE_FILE=$HOME/goc2/db/goc-live.sqlite perl bin/send-attendee-updates.pl

# Installation notes:

Install perl modules from CPAN the new way:

Use e.g. "cpanm DBD::SQLite" to install things (which is in in
~/perl5/bin/cpanm but that eval above should set that up for you).

or the old way:
    cpan> install Class::Accessor:Lite
    cpan> install DBD::SQLite
    cpan> install DBI
    cpan> install Data::Dump

see FCGI notes here https://docstore.mik.ua/orelly/linux/cgi/ch17_02.htm

    $ cd git
    $ git clone git@bitbucket.org:kgoess/berkmo-goc2.git
    $ cd berkmo-goc2
    $ perl Makefile.PL INSTALL_BASE=~/perl5
    $ make
    $ make test
    $ make install

    $ ./script/install-walton.sh

and in crontab -e

    MAILTO="kevin@goess.org"
    SQLITE_FILE=/home/lucybear/goc2/db/goc-live.sqlite
    PERL5LIB=/home/lucybear/perl5/lib/perl5

    3	*	*	*	*	/home/lucybear/bin/send-event-notifications.pl
    5   5   *   *   *   /home/lucybear/bin/send-attendee-updates.pl
    15  3   *   *   *   cp $SQLITE_FILE $SQLITE_FILE.bak
    17  3   *   *   *   cp $SQLITE_FILE $SQLITE_FILE.`date +%Y-%m`.bak
