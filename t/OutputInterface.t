#!/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use v5.14;

use CFDivisions::OutputInterface;

BEGIN { use_ok( 'CFDivisions::OutputInterface' ); }

my %default_args=(
    library         => 'lib',
    basedir         => '/basedir',
    bundlesequences => {
	a=>['bund_a'],
	b=>['bund_b'],
    },
    divisions   => {
	a=>'lib/path_a',
	b=>'lib/path_b',
    },
    divisionpaths   => {
	a=>'/root/lib/path_a',
	b=>'/root/lib/path_b',
    },
    divisionorder   => ['a','b'],
);

subtest "Constructor" => sub {
    my $oi;
    lives_ok {
	$oi=CFDivisions::OutputInterface->new(
	    %default_args,
	    );
    } "Argumentative constructor";

};

subtest "Class strings" => sub {
    my $oi=CFDivisions::OutputInterface->new(
	%default_args,
	);

    my @out=$oi->classes_strings();
    is_deeply(
	\@out,
	[
          '+cfdivisionlibrary_lib',
          '+lib_a',
          '+lib_b'
        ],
	"classes_strings"
	);
};

subtest "Variable strings" => sub {
    my $oi=CFDivisions::OutputInterface->new(
	%default_args,
	);

    is($oi->input_files_variable(),
       '@cfdivisions_lib_inputs={"/root/lib/path_a","/root/lib/path_b"}',
       "input_files_variable");

    is($oi->bundlesequence_variable(),
       q/@cfdivisions_lib_bundlesequence={"bund_a","bund_b"}/,
       "bundlesequence_variable");

    is(
	$oi->library_basedir(),
	"=lib_basedir=/basedir",
	"library_basedir"
	);

    is(
	$oi->library_divisions(),
	'@lib_divisions={"a","b"}',
	"library_divisions"
	);

    is_deeply(
	scalar $oi->library_division_localpaths(),
	[
	 '=lib_localpath[a]=lib/path_a',
	 '=lib_localpath[b]=lib/path_b',
	],
	"library_division_localpaths"
	);

    is_deeply(
	scalar $oi->library_division_paths(),
	[
	 '=lib_path[a]=/root/lib/path_a',
	 '=lib_path[b]=/root/lib/path_b',
	],
	"library_division_paths"
	);

    is_deeply(
	scalar $oi->variables_strings(),
	[
	 '@cfdivisions_lib_inputs={"/root/lib/path_a","/root/lib/path_b"}',
	 '@cfdivisions_lib_bundlesequence={"bund_a","bund_b"}',
	 '=lib_basedir=/basedir',
	 '@lib_divisions={"a","b"}',
	 '=lib_localpath[a]=lib/path_a',
	 '=lib_localpath[b]=lib/path_b',
	 '=lib_path[a]=/root/lib/path_a',
	 '=lib_path[b]=/root/lib/path_b',
	],
	"variables_strings"
	);
};

done_testing;
