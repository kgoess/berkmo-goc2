package GoC::Controller::ModPerl;

use strict;
use warnings;

use Apache2::RequestRec (); # for $r->content_type
use Apache2::RequestIO ();  # for print
use Apache2::Const -compile => ':common';
use Apache2::Request;

use GoC::Controller __PACKAGE__;
use GoC::View __PACKAGE__;

sub handler {
    my $controller = 'GoC::Controller';
    my $r = shift;

    #$r->content_type('text/plain');
    
    my $query_string = $r->args();

    # request input headers table
    my $headers_in = $r->headers_in();

    my $method = $r->method();

    # PATH_INFO
    my $path_info = $r->path_info();
    #   see also http://www.informit.com/articles/article.aspx?p=27110&seqNum=5

    $r->content_type('text/html');
    my $result;

    eval {
        ($result) = $controller->go(
            headers   => $headers_in,
            method    => $method,
            path_info => $path_info,
            request   => Apache2::Request->new($r),
            uri_for   => \&uri_for,
            static_uri_for => \&static_uri_for,
        );
        1;
    } or do {
        my $err = $@;

        $r->content_type('text/plain');
        $r->print("Oops! The server encountered an error:\n\n$err");
        return Apache2::Const::OK;

    };

    if ($result->{action} eq 'redirect') {
        $r->err_headers_out->add('Set-Cookie' => $result->{cookie});
        $r->headers_out->set($_ => $result->{headers}{$_}) for keys %{$result->{headers}};
        $r->status(Apache2::Const::REDIRECT);

        return Apache2::Const::OK;
    } elsif ($result->{action} eq 'display') {
        $r->content_type('text/html');
        $r->print($result->{content});
        return Apache2::Const::OK;
    }
}

# TODO need to worry about escaping here
sub uri_for {
    my %p;
    if (ref $_[0] eq 'HASH') { # TT sends a hashref
        %p = %{ $_[0] };
    } else {
        %p = @_;
    }

    my $path = delete $p{path} || '/';

    my $base = $ENV{GOC_URI_BASE} or die "GOC_URI_BASE is unset in ENV";

    my $url_params = '';
    if (keys %p) {
        $url_params = '?'; # will also be different for mod_perl
        $url_params .= join '&', map { "$_=$p{$_}" } sort keys %p;
    }

    return "$base$path$url_params";
}

sub static_uri_for {
    my ($path) = @_;

    my $base = $ENV{GOC_STATIC_URI_BASE} or die "GOC_STATIC_URI_BASE is unset in ENV";

    return "$ENV{GOC_STATIC_URI_BASE}/$path";
}

1;
