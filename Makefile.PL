use inc::Module::Install;

name     'Connector';
all_from 'lib/Connector.pm';
#license  'perl';

requires   'Moose';
requires    'Log::Log4perl';

recommends 'Config::Versioned' => '0.5';
recommends 'Config::Std';
recommends 'YAML';

recommends 'Text::CSV_XS';

recommends 'Template';
recommends 'Proc::SafeExec';

build_requires 'Test::More';

auto_install;

WriteAll;

