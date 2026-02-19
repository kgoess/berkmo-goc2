=head1 NAME

GoC::MailSender - sends mail

=head1 SYNOPSIS

    my $sender = GoC::MailSender->new(
        to => 'bob@example.com', 
        subject => encode_utf8($event_name),
    );

    $sender->attach(
        Data => encode_utf8($html_part),
        Type => 'text/html',
        Encoding => 'binary',
    );

    $sender->send();

=head1 DESCRIPTION

Bundling up the email sending here. The local mail queues on our
dreamhost VPS get gummed up, so we're going out through
smtp.dreamhost.com instead with an authenticated account.

=cut

package GoC::MailSender;

use 5.32.1;
use warnings;

use MIME::Entity;
use Email::Sender::Simple qw( sendmail );
use Email::Sender::Transport::SMTP;

use constant SMTP_USER => 'notifications@berkeleymorris.org';
use constant SMTP_PASS_FILE => "$ENV{HOME}/.smtp-pass";
use constant SMTP_HOST => 'smtp.dreamhost.com';

sub new {
    my ($class, %args) = @_;

    my $self = {};

    my $to     = $args{to};
    my $subject = $args{subject};

    $self->{mime} = MIME::Entity->build(
        From    => SMTP_USER, # required by smtp.dreamhost.com
        To      => $to,
        Subject => $subject,
        Type    => "multipart/mixed",
    );

    return bless $self, $class;
}

sub attach {
    my ($self, %args) = @_;

    $self->{mime}->attach(%args);
}

sub send {
    my ($self) = @_;

    open my $fh, '<', SMTP_PASS_FILE or die $!;
    my $smtp_pass = <$fh>;
    close $fh;
    chomp $smtp_pass;

    my $transport = Email::Sender::Transport::SMTP->new(
        host => SMTP_HOST,
        port => 465,
        ssl => 'ssl',
        sasl_username => SMTP_USER,
        sasl_password => $smtp_pass,
        debug => $ENV{SMTP_DEBUG},
    );

    sendmail($self->{mime}, { transport => $transport });
}

1;
