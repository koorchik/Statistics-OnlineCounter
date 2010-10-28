package Statistics::OnlineCounter;

use strict;
use warnings;
use Carp;
use Time::Piece;
use Data::Dumper;

=head1 NAME

Statistics::OnlineCounter - Count interval statistics in realtime

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

Use this module if you want to get statistics in realtime.

You can count online users or mean request time
Then you can store and visualise this statistics using other tools(munin for example - http://munin-monitoring.org/)

    use Statistics::OnlineCounter;
    use Cache::Memcached::Fast;

    my $memd = new Cache::Memcached::Fast({ servers => ['127.0.0.1:11211'] });

    my $obj = Statistics::OnlineCounter->new( $memd, 5 ); # Pass memcache object and statistics interval (5 min)

    #### Counting request spent time statistics
    for (1..100) {
        my $value = rand(100); # some value
        $obj->add_data('request_spent_time', $value);
    }

    sleep 60; #wait for the next minute. Statistics is available for last 5 minutes before current

    say 'Total requests for last 5 minutes'               . $obj->count('request_spent_time');
    say 'Sum of spent time for request of last 5 minutes' . $obj->sum('request_spent_time');
    say 'Average request time for last 5 minutes'         . $obj->mean('request_spent_time');

    #### Counting users online in realtime
    # add something like this to open_session
    if ( !$session->get('last_users_incr') or time - $session->get('last_users_incr') > 5*60 ){
        $session->set('last_users_incr', time);
        $obj->add_data('users_online', 1);
    }


=head1 SUBROUTINES/METHODS


=head2 Statistics::OnlineCounter->new(\$memcached_object, $statistics_interval_in_minutes)

    returns Statistics::OnlineCounter object

=cut

sub new {
    my ( $class, $storage_object, $interval_in_minutes ) = @_;
    return unless ref $storage_object;
    my $self = {
        storage      => $storage_object, # In most cases this is Cache::Memcached::Fast instance
        interval     => $interval_in_minutes ,
        expire       => ($interval_in_minutes + 1) * 60, #keys expirationin in seconds
        counters     => {},
        prefix       => '__so_counters__',
    };

    bless $self, $class;

#    $self->{counters} = { map {$_ => 1} $self->counters() };

    return $self;
}

=head2 $INSTANCE->add_data( $counter_name, $integer_value )

    Adds new value to counter. 
    $integer_value will be transformed to positive integer in any case
    
    returns sum of all $numeric values

=cut

sub add_data {
    my ( $self, $counter_name, $value ) = @_;
    return
        unless defined($counter_name)
            && length($counter_name);

    {
        no warnings 'numeric';
        $value = abs( int($value) );
    }

    #$self->_register_counter($counter_name) unless ( $self->{counters}{$counter_name} ); # TODO

    my ( $count_prefix, $sum_prefix, $current_key_index ) = $self->_make_prefixes($counter_name);
    my ($sum_key, $count_key) = ($sum_prefix . $current_key_index, $count_prefix . $current_key_index);

    $self->{storage}->incr( $count_key, 1 )    or $self->{storage}->set( $count_key, 1,  $self->{expire} );
    $self->{storage}->incr( $sum_key, $value ) or $self->{storage}->set( $sum_key, $value, $self->{expire} );

}

=head2 $INSTANCE->mean($counter_name)

    returns average value calculated as $sum_of_all_values/$values_count

=cut

sub mean {
    my ( $self, $counter_name ) = @_;
    my ($count, $sum) = $self->_get_counter_stats($counter_name);
    
    return 0 unless $count;
    return int( $sum/$count + 0.5 );
}

=head2 $INSTANCE->count($counter_name)

    returns values count

=cut

sub count {
    my ( $self, $counter_name ) = @_;
    my ( $count, $sum ) = $self->_get_counter_stats($counter_name);
    return $count;
}

=head2 $INSTANCE->sum($counter_name)

    returns values sum

=cut

sub sum {
    my ( $self, $counter_name ) = @_;
    my ( $count, $sum ) = $self->_get_counter_stats($counter_name);
    return $sum;
}

=begin comment

TODO

#$INSTANCE->counters()

sub counters {
    my ($self) = @_;

}


#$INSTANCE->_register_counter($counter_name)

sub _register_counter_online {
    my ( $self, $counter_name ) = @_;

}
=end comment
=cut

################### INTERNAL USE ONLY ########################

#$INSTANCE->_get_counter_stats($counter_name)

sub _get_counter_stats {
    my ( $self, $counter_name ) = @_;
    my ( $count_prefix, $sum_prefix, $current_key_index ) = $self->_make_prefixes($counter_name);

    my ( $count, $sum, $data, @sum_keys, @count_keys ) = ( 0, 0, {} );

    for ( 0..$self->{interval} ) {
        next if $_ == $current_key_index;
        push @sum_keys,   $sum_prefix   . $_;
        push @count_keys, $count_prefix . $_;
    }

    # Get all statistics
    $data = $self->{storage}->get_multi( @count_keys );
    $count += $_ for values %$data;

    $data = $self->{storage}->get_multi( @sum_keys );
    $sum += $_ for values %$data;

    return( $count, $sum );
}

#$INSTANCE->_make_prefixes($counter_name)
sub _make_prefixes {
    my ( $self, $counter_name ) = @_;

    my $sum_prefix   = $self->{prefix}. '_c_' . $counter_name . '_sum_';
    my $count_prefix = $self->{prefix}. '_c_' . $counter_name . '_count_';
    my $current_key_index = localtime->min % $self->{interval};

    return( $count_prefix, $sum_prefix, $current_key_index );
}

=head1 TODO

=over 4

=item * impement retrieving names of all available counters

=item * improve documentation

=item * add more usage examples including munin

=item * improve tests

=back



=head1 AUTHOR

Viktor Turskyi, C<< <koorchik at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-statistics-onlinecounter at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Statistics-OnlineCounter>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Statistics::OnlineCounter

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Statistics-OnlineCounter>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Statistics-OnlineCounter>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Statistics-OnlineCounter>

=item * Search CPAN

L<http://search.cpan.org/dist/Statistics-OnlineCounter/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2010 Viktor Turskyi.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU Lesser General Public
License as published by the Free Software Foundation; either
version 2.1 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public
License along with this program; if not, write to the Free
Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA
02111-1307 USA.


=cut

1;    # End of Statistics::OnlineCounter
