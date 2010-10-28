#!perl -T

use Test::More tests => 21;

BEGIN {
    use_ok('Statistics::OnlineCounter') || print "Bail out!
";
}


diag("Testing Statistics::OnlineCounter $Statistics::OnlineCounter::VERSION, Perl $], $^X");

can_ok( 'Statistics::OnlineCounter', qw/new add_data mean count sum/ );

use Cache::Memcached::Fast;
my $memd = Cache::Memcached::Fast->new({
    servers => ['127.0.0.1:11211']
});

my $obj = new_ok( 'Statistics::OnlineCounter' => [$memd, 5] );

# Adding good data
ok( $obj->add_data( 'counter1', 0 ), 'Adding Data' );
ok( $obj->add_data( 'counter1', 3 ), 'Adding Data' );
ok( $obj->add_data( 'counter1', 7 ), 'Adding Data' );

ok( $obj->add_data( 'counter2', 21 ), 'Adding Data' );
ok( $obj->add_data( 'counter2', 23 ), 'Adding Data' );
ok( $obj->add_data( 'counter2', 12 ), 'Adding Data' );

# Adding problem data
ok( $obj->add_data( 'counter1', -1 ),   'Adding Data' );
ok( $obj->add_data( 'counter1', 2.4 ),  'Adding Data' );
ok( $obj->add_data( 'counter1', 'az' ), 'Adding Data' );

ok( $obj->add_data( 'counter2', -21 ),   'Adding Data' );
ok( $obj->add_data( 'counter2', 23.3 ),  'Adding Data' );
ok( $obj->add_data( 'counter2', 'asf' ), 'Adding Data' );

#sleep(61);

# Checking list
# is_deeply( [$obj->counters()], ['counter1', 'counter2'], 'Getting list of counter names' );

# Checking mean
is( $obj->mean('counter1'), 2,  'Checking mean' );
is( $obj->mean('counter2'), 17, 'Checking mean' );

# Checking count
is( $obj->count('counter1'), 6, 'Checking count' );
is( $obj->count('counter2'), 6, 'Checking count' );

# Checking sum
is( $obj->sum('counter1'), 13,  'Checking sum' );
is( $obj->sum('counter2'), 100, 'Checking sum' );
