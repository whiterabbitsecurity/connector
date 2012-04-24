use inc::Module::Install;

name     'Connector';
abstract 'A generic connection to a hierarchical-structured data set';
all_from 'lib/Connector.pm';
author   'Scott T. Hardin <mrscotty@hnsc.de>';
license  'perl';

requires   'Moose';

recommends 'Config::Versioned' => '0.5';
recommends 'Config::Std';
recommends 'YAML';

recommends 'Text::CSV_XS';

recommends 'Template';
recommends 'Proc::SafeExec';

build_requires 'Test::More';

auto_install;

WriteAll;

