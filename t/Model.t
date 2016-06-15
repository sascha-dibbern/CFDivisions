#!/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use v5.14;

use CFDivisions::Model;
BEGIN { use_ok( 'CFDivisions::Model' ); }

subtest "Constructor" => sub {
    dies_ok {
	my $model = CFDivisions::Model->new(
	    divisions     => undef,
	    );
    } "Fail when no divisions";
    
    dies_ok {
	my $model = CFDivisions::Model->new(
	    divisions     => {},
	    dependencies  => undef,
	    );
    } "Fail when no dependencies";
    

    my $model = CFDivisions::Model->new(
	divisions     => {a=>'a',b=>'b'},
	dependencies  => {b=>['a']},
	);
    ok(defined $model,"Created model");
};

subtest "Circular division reference investigation" => sub {
    my $model = CFDivisions::Model->new(
	divisions     => {},
	dependencies  => {},
	);
    $model->add_to_circular_division_ref_investigation('1');
    lives_ok { $model->assert_no_circular_division_reference() }"Assert no circular reference 1";

    $model->add_to_circular_division_ref_investigation('2');
    lives_ok { $model->assert_no_circular_division_reference() } "Assert no circular reference 2";

    $model->add_to_circular_division_ref_investigation('1');
    dies_ok { $model->assert_no_circular_division_reference() } "Failed assert no circular reference 1";

    $model->remove_from_circular_division_ref_investigation('1');
    lives_ok { $model->assert_no_circular_division_reference() } "Assert no circular reference 1";

};

subtest "assert_existing_division_dependencies" => sub {
    my $model = CFDivisions::Model->new(
	divisions     => {a=>'1',b=>'2'},
	dependencies  => {b=>['a']},
	);

    lives_ok { $model->assert_existing_division_dependencies('b',['a']); } "Valid input data";

    dies_ok { $model->assert_existing_division_dependencies('b',['c']); } "Invalid input data: nonexisting division";
};

subtest "Divisionorder primitives" => sub {
    my $model = CFDivisions::Model->new(
	divisions     => {a=>'1',b=>'2'},
	dependencies  => {},
	);

    lives_ok { $model->assert_existing_division('a'); } "Success asserting existing division";
    dies_ok { $model->assert_existing_division('c'); } "Failed asserting existing division";

    $model->add_division_to_divisionorder('a');
    ok($model->is_division_in_divisionorder('a'),"Check one division in order");

    $model->add_division_to_divisionorder('b');
    ok($model->is_division_in_divisionorder('b'),"Check second division in order");

    my $d_order = $model->divisionorder();
    is_deeply(
	$d_order,
	['a','b'],
	"Right division order registration"
	);
};

subtest "Divisionorder building" => sub {
    my $model = CFDivisions::Model->new(
	divisions     => {a=>'1',b=>'2',c=>'3',d=>'4'},
	dependencies  => {
	    b=>['a'],
	    c=>['b'],
	    d=>['b','c'],
	}, # expected order -> a,b,c,d
	);
    
    my @order = $model->divisionorder();
    is_deeply(
	\@order,
	[
	 'a',
	 'b',
	 'c',
	 'd'
	],
	"Right division order"
	);
    #say Dumper($model);

};

subtest "Divisionorder building based on divisionfilter" => sub {
    my $model = CFDivisions::Model->new(
	divisionfilter => ['c'],
	divisions      => {a=>'1',b=>'2',c=>'3',d=>'4',e=>'5',f=>'6'},
	dependencies   => {
	    b=>['a'],
	    c=>['b'],
	    d=>['b','c'],
	    e=>['a'],
	    f=>['b'],
	}, # expected order -> a,b,c
	);
    
    my @order = $model->divisionorder();
    is_deeply(
	\@order,
	[
	 'a',
	 'b',
	 'c',
	],
	"Right division order and filtering"
	);
    #say Dumper($model);

};

done_testing;

