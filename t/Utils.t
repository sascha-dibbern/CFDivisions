#!/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use v5.14;

use CFDivisions::Utils;

BEGIN { use_ok( 'CFDivisions::Utils' ); }

subtest "Canonization to CFE simple identifier-form" => sub {
    is(canonized_cfe_identifier('a'),'a',"Simple identifier");
    is(canonized_cfe_identifier('a/b?c&d+1'),'a_b_c_d_1','None word characters');
#    is(canonized_cfe_identifier('___a'),'a',"Remove prefixed '_'");
#    is(canonized_cfe_identifier('a___'),'a',"Remove postfixed '_'");
    is(canonized_cfe_identifier('a_b'),'a_b',"Keep '_'");
    is(canonized_cfe_identifier('a__b'),'a__b',"Keep multiple '_'");
};

subtest "is_cfe_identifier" => sub {
    ok(!is_cfe_identifier(undef),'Undefined identifier');
    ok(!is_cfe_identifier(''),'Empty identifier');
    ok(is_cfe_identifier('a'),"Valid identifier 'a'");
    ok(is_cfe_identifier('a_b'),"Valid identifier 'a_b'");
    ok(!is_cfe_identifier('1a'),'Invalid identifier starting with number');
    ok(!is_cfe_identifier('a!'),'Invalid identifier due to non-canonical form');

};

subtest "is_cfe_namespaced_identifier" => sub {
    ok(!is_cfe_namespaced_identifier(undef),'Undefined identifier');
    ok(!is_cfe_namespaced_identifier(''),'Empty identifier');
    ok(!is_cfe_namespaced_identifier('a'),'Not namespaces identifier');
   
    ok(!is_cfe_namespaced_identifier('a:b:c'),'False namespaces identifier'); # TODO: check with CFE rules if hierachies are allowed

    ok(!is_cfe_namespaced_identifier('_a:b'),"Invalid namespaces identifier start with '_'");

    ok(is_cfe_namespaced_identifier('a:b'),"Valid namespaced identifier 1");
    ok(is_cfe_namespaced_identifier('a:_b'),"Valid namespaced identifier 2");

    ok(!is_cfe_namespaced_identifier('a!:b'),"Invalid namespaces identifier not equivalent to canonization");

    ok(!is_cfe_namespaced_identifier('a:b!'),"Invalid identifier not equivalent to canonization");
};

subtest "Assertions" => sub {
    lives_ok { assert_cfengine_identifier('a'); } "Legal CFEngine identifier 'a'";
    lives_ok { assert_cfengine_identifier('a'); } "Legal CFEngine identifier 'a_'";
    lives_ok { assert_cfengine_identifier('a:b'); } "Legal CFEngine identifier 'a:b'";
    dies_ok { assert_cfengine_identifier(':b'); } "Illegal CFEngine identifier ':b'";
    dies_ok { assert_cfengine_identifier(':'); } "Illegal CFEngine identifier ':'";
    dies_ok { assert_cfengine_identifier('*'); } "Illegal CFEngine identifier";
#    dies_ok { assert_cfengine_identifier('_a'); } "Illegal CFEngine identifier starting with '_'";
};



done_testing();
