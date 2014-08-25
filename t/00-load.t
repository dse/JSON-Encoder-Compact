#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 1;

BEGIN {
    use_ok( 'JSON::Encoder::Compact' ) || print "Bail out!\n";
}

diag( "Testing JSON::Encoder::Compact $JSON::Encoder::Compact::VERSION, Perl $], $^X" );
