
package GoC::View;

use strict;
use warnings;

use Template;

use GoC::Model::Event;

sub main_page {
    my ($class) = @_;

    my $config = {
		INCLUDE_PATH => './templates',
		# PRE_PROCESS => header?
	};

	my $tt = Template->new($config);

	my $template = 'main-html.tt';
	my $vars = {
		organization_name => 'Berkeley Morris',
		gigs => GoC::Model::Event->get_upcoming_events(type => 'gig'),
	};
	my $output = '';

	$tt->process($template, $vars, \$output)
   		|| die $tt->error();

	return $output;
}

1;
