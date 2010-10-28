use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Statistics::OnlineCounter',
    license             => 'lgpl',
    dist_author         => q{Viktor Turskyi <koorchik@cpan.org>},
    dist_version_from   => 'lib/Statistics/OnlineCounter.pm',
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'Statistics-OnlineCounter-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
