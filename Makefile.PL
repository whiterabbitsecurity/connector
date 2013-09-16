use inc::Module::Install;

name     'Connector';
all_from 'lib/Connector.pm';
#license  'perl';

requires   'Moose';
requires    'Log::Log4perl';

recommends 'Config::Versioned' => '0.5';
recommends 'Config::Std';
recommends 'Net::LDAP';
recommends 'YAML';

recommends 'Text::CSV_XS';

recommends 'Template';
recommends 'Proc::SafeExec';

build_requires 'Test::More';

test_requires 'Test::More';
test_requires 'Config::Versioned';
test_requires 'Config::Std';
test_requires 'YAML';
test_requires 'Template';

auto_install;

WriteAll;

