package GoC::Controller::CGI;

use strict;
use warnings;

use CGI;

use GoC::Controller 'GoC::Controller::CGI';
use GoC::View 'GoC::Controller::CGI';
use URI::Escape qw/uri_escape/;

sub handler {
    my $class = 'GoC::Controller';

    my $result;

    my $headers_in = get_request_headers();

    my $method = get_http_method();

    my $q = CGI->new();

    my $path_info = get_path_info($q);

    eval {
        ($result) = $class->go(
            headers   => $headers_in,
            method    => $method,
            path_info => $path_info,
            request   => $q, 
            uri_for   => \&uri_for,
            static_uri_for => \&static_uri_for,
        );
        1;
    } or do {
        my $err = $@;

die $err; # FIXME
#        $r->content_type('text/plain');
#        $r->print("Oops! The server encountered an error:\n\n$err");
#        return Apache2::Const::OK;

    };

    if ($result->{action} eq 'redirect') {
#        $r->err_headers_out->add('Set-Cookie' => $result->{cookie});
#        $r->headers_out->set($_ => $result->{headers}{$_}) for keys %{$result->{headers}};
#        $r->status(Apache2::Const::REDIRECT);
        print $q->header(
            -type       => 'text/html',
            -charset    => 'utf-8',
            #-nph        => 1,
            -status     => '302 Redirect',
            #-expires    => '+3d',
            -cookie     => $result->{cookie},
            %{ $result->{headers} },
        );
        #print $q->header($_ => $result->{headers}{$_}) for keys %{$result->{headers}};
#
#        return Apache2::Const::OK;
    } elsif ($result->{action} eq 'display') {
        print $q->header(
            -type       => 'text/html',
            -charset    => 'utf-8',
            #-nph        => 1,
            #-status     => '402 Payment required',
            #-expires    => '+3d',
            #-cookie     => $cookie,
        );

            ;
#        $r->content_type('text/html');
        print $result->{content};
#        return Apache2::Const::OK;
    }
}

# is the mod_perl version case-insensitive? How does
# psgi do it?
sub get_request_headers {
    my %headers = ();

    foreach my $key (sort keys %ENV) {
        next unless $key =~ /^HTTP_/;
        my ($header_name) = $key =~ /HTTP_(.+)/
            or next;

        $header_name = lc $header_name;
        $header_name =~ s/\b(.)/uc($1)/eg;
        $headers{$header_name} = $ENV{$key};
    }
    return \%headers;
}

sub get_http_method {
    return $ENV{REQUEST_METHOD};
}

sub get_path_info {
    my ($q) = @_;
    # which one of these?
    # REQUEST_URI: /cgi-bin/test.cgi?param1=val1
    # SCRIPT_NAME: /cgi-bin/test.cgi

    # enforce scalar context to get the first param only
    my $path  = $q->url_param("path");

    # (note path should start with a slash, enforce that here?)
    return $path // '';
}

    
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
        $url_params = '&'; # will also be different for mod_perl
        $url_params .= join '&', map { "$_=".uri_escape($p{$_}) } sort keys %p;
    }

    return "$base?path=$path$url_params";
}

sub static_uri_for {
    my ($path) = @_;

    my $base = $ENV{GOC_STATIC_URI_BASE} or die "GOC_STATIC_URI_BASE is unset in ENV";

    return "$ENV{GOC_STATIC_URI_BASE}/$path";
}

1;
