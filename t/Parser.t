#!/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use v5.14;

use CFDivisions::Parser;

BEGIN { use_ok( 'CFDivisions::Parser' ); }

subtest "Constructor" => sub {
    dies_ok {
	my $p=CFDivisions::Parser->new();
    } "No 'library' argument";

    my $p=CFDivisions::Parser->new(library=>'test',inputs_path=>'/inputs');
    is($p->{inputs_vol},'',            "Attribute: inputs_vol");
    is($p->{inputs_dir},'/inputs',     "Attribute: inputs_dir");
    is($p->{basedir},   '/inputs/test',"Attribute: basedir");
};

subtest "is_valid_division_promise_file_path" => sub {
    my $p=CFDivisions::Parser->new(library=>'test',inputs_path=>'/inputs');
    ok (!$p->is_valid_division_promise_file_path(
	     '/inputs/test/abc/def',
	     'file',
	),"Not a valid division promises file path");
    ok ($p->is_valid_division_promise_file_path(
	    '/inputs/test/abc/def',
	    $CFDivisions::Parser::DIVISION_PROMISE_FILE,
	),"A valid division promises file path");
};

subtest "register_division_promise_file" => sub {
    my $p=CFDivisions::Parser->new(
	library=>'test',
	inputs_path=>'/inputs'
	);
    ok($p->register_division_promise_file(
	   '/inputs/test/abc/def',
	   $CFDivisions::Parser::DIVISION_PROMISE_FILE
       ),"Successfull registering");

    dies_ok {
	p->register_division_promise_file(
	    '/inputs/test/abc/def',
	    $CFDivisions::Parser::DIVISION_PROMISE_FILE
	    );
    } "Handle division name collision";

    my $div = $p->divisions();
    is_deeply(
	$div,{
	    'abc_def' => 'abc/def'
	},
	"Local divisions path"
	);
	
    my $dp = $p->divisionpaths();
    is_deeply(
	$dp,{
	    'abc_def' => '/inputs/test/abc/def'
	},
	"Absolute divisions path"
	);
};

subtest "parse_cfdivisions_bundlesequence_token" => sub {
    my $p=CFDivisions::Parser->new(
	library=>'test',
	inputs_path=>'/inputs'
	);

    ok(!$p->parse_cfdivisions_bundlesequence_token(
	    '',
	    'division'
       ),"Parse line without cfdivisions_bundlesequence token");

    ok($p->parse_cfdivisions_bundlesequence_token(
	    '# *cfdivisions_bundlesequence = a_b , c_d',
	    'div1'
       ),"Parse line with cfdivisions_bundlesequence containing bundles");
    my $bs1 = $p->bundlesequences();
    is_deeply(
	$bs1,
	{
          'div1' => [
	      'a_b',
	      'c_d'
	      ],
        },
	'Right bundlesequence with bundles'
	);

    ok($p->parse_cfdivisions_bundlesequence_token(
	    '# *cfdivisions_bundlesequence = ',
	    'div2'
       ),"Parse line with cfdivisions_bundlesequence containing no bundles");
    my $bs2 = $p->bundlesequences();
    is_deeply(
	$bs2,
	{
	    'div2' => [],
	    'div1' => [
		'a_b',
		'c_d'
		],
        },
	'No bundlesequence bundles'
	);
};

subtest "parse_cfdivisions_depends_token" => sub {
    my $p=CFDivisions::Parser->new(
	library=>'test',
	inputs_path=>'/inputs'
	);

    ok(!$p->parse_cfdivisions_depends_token(
	    '',
	    'division'
       ),"Parse line without cfdivisions_depends token");

    ok($p->parse_cfdivisions_depends_token(
	    '# *cfdivisions_depends = a_b , c_d',
	    'div1'
       ),"Parse line with cfdivisions_depends containing divisions");
    my $dep1 = $p->dependencies();
    is_deeply(
	$dep1,
	{
          'div1' => [
	      'a_b',
	      'c_d'
	      ],
        },
	'Right dependencies divisions'
	);

    ok($p->parse_cfdivisions_depends_token(
	    '# *cfdivisions_depends = ',
	    'div2'
       ),"Parse line with cfdivisions_depends containing no divisions");
    my $dep2 = $p->dependencies();
    is_deeply(
	$dep2,
	{
	    'div2' => [],
	    'div1' => [
		'a_b',
		'c_d'
		],
        },
	'No dependencies divisions'
	);
};

done_testing;
