#!/usr/bin/perl 
#===============================================================================
#
#         FILE:  test.pl
#
#        USAGE:  ./test.pl  
#
#  DESCRIPTION:  
#
#      OPTIONS:  ---
# REQUIREMENTS:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  YOUR NAME (), 
#      COMPANY:  
#      VERSION:  1.0
#      CREATED:  10/27/2010 01:19:20 AM
#     REVISION:  ---
#===============================================================================

use strict;
use warnings;
use Statistics::OnlineCounter;
use Cache::Memcached::Fast;

my $memd = new Cache::Memcached::Fast({ servers => ['127.0.0.1:11211'] });

my $obj = Statistics::OnlineCounter->new( $memd, 5 );

for (1..100) {
	$obj->add_data('test2', rand(time))
}

print $obj->mean('test2');

