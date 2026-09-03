requires 'Log::Log4perl';
requires 'Moose';
requires 'perl', '5.014';
recommends 'Config::Std';

# DateTime needed for Connector::Iterator
recommends 'DateTime';

recommends 'DBI';
recommends 'Feature::Compat::Try';
recommends 'IO::Socket::SSL';
recommends 'JSON';
recommends 'LWP::Protocol::https';
recommends 'LWP::UserAgent';
recommends 'Net::LDAP';
recommends 'Proc::SafeExec';
recommends 'Template';
recommends 'Text::CSV_XS';
recommends 'YAML';

on build => sub {
    requires 'Config::Merge';
    requires 'Config::Std';
    requires 'DBD::SQLite';
    requires 'DBI';
    requires 'ExtUtils::MakeMaker', '6.59';
    requires 'IO::Socket::SSL';
    requires 'JSON';
    requires 'LWP::Protocol::https';
    requires 'LWP::UserAgent';
    requires 'Proc::SafeExec';
    requires 'Feature::Compat::Try';
    requires 'Template';
    requires 'YAML';
};

on develop => sub {
    requires 'Test::CPAN::Meta';
    requires 'Test::MinimumVersion::Fast', '0.04';
    requires 'Test::PAUSE::Permissions', '0.04';
    requires 'Test::Pod', '1.41';
    requires 'Test::Spellunker', 'v0.2.7';
};

on test => sub {
    requires 'DateTime';        # Connector::Iterator, t/01-multi.t
    requires 'Path::Class';     # t/01-iterator.t, t/01-tee.t
    requires 'Test::More';
};
