#!perl -T

use Test::More tests => 1;

BEGIN {
    use_ok( 'Statistics::OnlineCounter' ) || print "Bail out!
";
}

diag( "Testing Statistics::OnlineCounter $Statistics::OnlineCounter::VERSION, Perl $], $^X" );
