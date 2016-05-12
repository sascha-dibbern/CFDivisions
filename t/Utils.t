#!/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use v5.14;

use CFDivisions::Utils;

BEGIN { use_ok( 'CFDivisions::Utils' ); }

subtest "Assertions" => sub {
    lives_ok { assert_cfengine_identifier('a'); } "Legal CFEngine identifier 'a'";
    lives_ok { assert_cfengine_identifier('a'); } "Legal CFEngine identifier 'a_'";
    dies_ok { assert_cfengine_identifier('*'); } "Illegal CFEngine identifier";
    dies_ok { assert_cfengine_identifier('_'); } "Illegal CFEngine identifier starting with '_'";
};


subtest "Canonization of division names" => sub {
    is(canonize_divisionname('a/b?c&d+1'),'a_b_c_d_1','None word characters');
    is(canonize_divisionname('___a'),'a',"Remove prefixed '_'");
    is(canonize_divisionname('a___'),'a',"Remove postfixed '_'");
    is(canonize_divisionname('a_b'),'a_b',"Keep '_'");
    is(canonize_divisionname('a__b'),'a__b',"Keep multiple '_'");
};

done_testing();