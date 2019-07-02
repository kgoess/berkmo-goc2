package GoC::Controller;

use strict;
use warnings;

use Data::Dump qw/dump/;

use GoC::View;

sub go {
    my ($class, %p) = @_;

    if (! $p{headers}{Cookie} || ! $p{headers}{Cookie}{'Berkmo-GoC'}) {
        return $class->login_page(%p);
    }

    return dump \%p;
}


sub login_page {
    my ($class, %p) = @_;

    if ($p{method} eq 'GET') {
        return GoC::View->login_page();

    } elsif ($p{method} eq 'POST') {
        #my $id = perldoc

        
    
    } else {
        die "unrecognized method $p{method} in call to login_page";
    }

}


1;
