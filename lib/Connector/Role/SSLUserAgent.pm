package Connector::Role::SSLUserAgent;
use Moose::Role;
use Data::Dumper;
use LWP::UserAgent;

has timeout => (
    is => 'rw',
    isa => 'Int',
    required => 0,
    default => 10,
    );

has proxy => (
    is => 'rw',
    isa => 'Str',
    required => 0,
    );

has agent => (
    is => 'rw',
    isa => 'Object',
    lazy => 1,
    builder => '_init_agent',
);
 
has use_net_ssl => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    );

has ssl_ignore_hostname => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    );

has ssl_ignore_mode => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    );

has certificate_file => (
    is => 'rw',
    isa => 'Str',
    );

has certificate_key_file => (
    is => 'rw',
    isa => 'Str',
    );

has certificate_p12_file => (
    is => 'rw',
    isa => 'Str',
    );

has certificate_key_password => (
    is => 'rw',
    isa => 'Str',
    );

has ca_certificate_path => (
    is => 'rw',
    isa => 'Str',
    );

has ca_certificate_file => (
    is => 'rw',
    isa => 'Str',
    );

sub _init_agent {

    my $self = shift;

    my %ENV_BACKUP = %ENV;

    my $ua = LWP::UserAgent->new;
    $ua->timeout( $self->timeout() );
    if ($self->proxy()) {
        $ua->proxy(['http', 'https'], $self->proxy());
    }

    # Force usage of net::ssl
    if ($self->use_net_ssl()) {
        require Net::SSL;
        $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "Net::SSL";

        if ($self->certificate_p12_file) {
            $ENV{HTTPS_PKCS12_FILE}  = $self->certificate_p12_file;

            if ($self->certificate_key_file || $self->certificate_file) {
                die "Options certificate_file/certificate_key_file and certificate_p12_file are mutually exclusive";
            }

            if ($self->certificate_key_password) {
                $ENV{HTTPS_PKCS12_PASSWORD}  = $self->certificate_key_password;
            }
        }

        if ($self->certificate_key_file) {
            if ($self->certificate_key_password) {
                die "Net::SSL does not support password protected keys - use certificate_p12_file instead";
            }

            if (!$self->certificate_file) {
                die "You need to pass certificate AND key file, use certificate_p12_file to pass a PKCS12";
            }

            $ENV{HTTPS_KEY_FILE}  = $self->certificate_key_file;
            $ENV{HTTPS_CERT_FILE} = $self->certificate_file;

        } elsif ($self->certificate_file) {
            die "You need to pass certificate AND key file, use certificate_p12_file to pass a PKCS12";
        }

        if ($self->ca_certificate_path) {
            $ENV{HTTPS_CA_DIR} = $self->ca_certificate_path;
        }

        if ($self->ca_certificate_file) {
            $ENV{HTTPS_CA_FILE} = $self->ca_certificate_file;
        }

        $self->log()->trace('Using Net::SSL, EVN is' . Dumper $ENV);

    } # end of Net:SSL, IO::Socket::SSL
    elsif( $self->LOCATION() =~ /^https:/i ) {

        require IO::Socket::SSL;
        $ENV{PERL_NET_HTTPS_SSL_SOCKET_CLASS} = "IO::Socket::SSL";

        my $ssl_opts = {
            verify_hostname => ($self->ssl_ignore_hostname ? 0 : 1),
            SSL_verify_mode => ($self->ssl_ignore_mode ? 0 : 1)
        };
        if ($self->certificate_p12_file) {
            die "Using pkcs12 containers is not supported by IO::Socket::SSL"
        }

        if ($self->certificate_key_file) {
            if (!$self->certificate_file) {
                die "You need to pass certificate AND key file";
            }
            $ssl_opts->{SSL_key_file}  = $self->certificate_key_file;
            $ssl_opts->{SSL_cert_file}  = $self->certificate_file;

            if ( $self->certificate_key_password ) {
                $ssl_opts->{SSL_passwd_cb} = sub { return $self->certificate_key_password; };
            }

        } elsif ($self->certificate_file) {
            die "You need to pass certificate AND key file";
        }

        if ($self->ca_certificate_path) {
	        $ssl_opts->{SSL_ca_path}  = $self->ca_certificate_path;
        }

        if ($self->ca_certificate_file) {
            $ssl_opts->{SSL_ca_file}  = $self->ca_certificate_file;
        }

        $ua->ssl_opts( %{$ssl_opts} );

        $self->log()->trace('Using IO::Socket::SSL with options ' . Dumper $ssl_opts);
    } else {
        # No ssl
    }

    return $ua;
}

1;

__END__;

=head1 Connector::Role::SSLUserAgent

Setup the HTTP UserAgent object with connection and SSL parameters.

=head2 LWP options

=over

=item timeout

Timeout for the connection in seconds, default is 10.

=item proxy

URL of a proxy to use, must include protocol and port,
e.g. https://proxy.intranet.company.com:8080/

=back

=head2 SSL support

This connector supports client authentication using certificates.

=over

=item use_net_ssl

Set this to a true value to use Net::SSL as backend library (otherwise
IO::Socket::SSL is used). Be aware the Net::SSL does not check the hostname
of the server certificate so Man-in-the-Middle-Attacks might be possible.
You should use this only with a really good reason or if you need support
for PKCS12 containers.

=item ssl_ignore_hostname

Do not validate the hostname of the server certificate (only useful with
IO::Socket::SSL as Net::SSL does not check the hostname at all).

=item certificate_file

Path to a PEM encoded certificate file.

=item certificate_key_file

Path to a PEM encoded key file.

=item certificate_p12_file

Path to a PKCS12 container file. This is only supported by Net:SSL and can
not be used together with certificate_file/certificate_key_file.

=item certificate_key_password

The plain password of your encrypted key or PKCS12 container. Note that
Net::SSL does not support password protected keys. You need to use a PKCS12
container instead! Leave this empty if your key is not protected by a password.

=item ca_certificate_path

Path to a directory with trusted certificates (with openssl hashed names).
Also used to validate the server certificate even if no client authentication
is used.

=item ca_certificate_file

Same as ca_certificate_path pointing to a single file.

=item ssl_ignore_mode

Boolean, turn of validation of ssl peer certificate (IO::Socket only).

=back