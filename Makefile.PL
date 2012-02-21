use inc::Module::Install;

name     'Connector';
all_from 'lib/Connector.pm';
author   'Scott T. Hardin <mrscotty@hnsc.de>';
license  'perl';

requires 'Config::Versioned';
recommends 'Config::Std';
recommends 'YAML';

build_requires 'Test::More';

auto_install;

WriteAll;

