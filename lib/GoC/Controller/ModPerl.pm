package GoC::Controller::ModPerl;

use strict;
use warnings;

use Apache2::RequestRec (); # for $r->content_type
use Apache2::RequestIO ();  # for print
use Apache2::Const -compile => ':common';

use GoC::Controller;

sub handler {
    my $class = 'GoC::Controller';
    my $r = shift;

    #$r->content_type('text/plain');
    
    my $query_string = $r->args();

    # request input headers table
    my $headers_in = $r->headers_in();

    my $method = $r->method();

    # PATH_INFO
    my $path_info = $r->path_info();
    #   see also http://www.informit.com/articles/article.aspx?p=27110&seqNum=5

    print $class->go(
        headers => $headers_in,
        method => $method,
        path_info => $path_info,
    );
    return Apache2::Const::OK;
}

1;
