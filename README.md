# Berkmo GoC2

A new Grid of Committment


# Misc notes:


eval $(perl -I ~/perl5/lib/perl5/ -Mlocal::lib)

SQLITE_FILE=$HOME/goc2/db/goc-live.sqlite perl bin/send-attendee-updates.pl

# Installation notes:

After that "eval" command above, install perl modules from CPAN the new way:

Use e.g. "cpanm DBD::SQLite" to install things (which is in in
~/perl5/bin/cpanm but that eval above should set that up for you).

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

    3   *   *   *   *   /home/lucybear/bin/send-event-notifications.pl
    5   5   *   *   *   /home/lucybear/bin/send-attendee-updates.pl
    8   8   *   *   2   /home/lucybear/bin/send-practice-reminder.pl --to 'Berkeley Morris <berkmorris-business@groups.io>'
    15  3   *   *   *   cp $SQLITE_FILE $SQLITE_FILE.bak
    17  3   *   *   *   cp $SQLITE_FILE $SQLITE_FILE.`date +\%Y-\%m`.bak
