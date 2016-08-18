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
	a     => ['bund_a'],
	b     => ['bund_b'],
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
    dependencies    => {},
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

subtest "Variable strings (default namespace)" => sub {
    my $oi=CFDivisions::OutputInterface->new(
	%default_args,
	);

    is($oi->input_files_variable(),
       '@cfdivisions_lib_inputs={"/root/lib/path_a/division-promises.cf","/root/lib/path_b/division-promises.cf"}',
       "input_files_variable");

    is($oi->bundlesequence_variable(),
       q/@cfdivisions_lib_bundlesequence={"default:bund_a","default:bund_b"}/,
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

    #say Dumper(scalar $oi->variables_strings());
    is_deeply(
	scalar $oi->variables_strings(),
	[
          '=lib_basedir=/basedir',
          '@lib_divisions={"a","b"}',
          '@cfdivisions_lib_inputs={"/root/lib/path_a/division-promises.cf","/root/lib/path_b/division-promises.cf"}',
          '@cfdivisions_lib_bundlesequence={"default:bund_a","default:bund_b"}',
          '=lib_localpath[a]=lib/path_a',
          '=lib_localpath[b]=lib/path_b',
          '=lib_path[a]=/root/lib/path_a',
          '=lib_path[b]=/root/lib/path_b'
	],
	"variables_strings"
	);
};

subtest "Variable strings (new namespace)" => sub {
    my $oi=CFDivisions::OutputInterface->new(
	%default_args,
	namespace => 'other',
	);

    is($oi->bundlesequence_variable(),
       q/@cfdivisions_lib_bundlesequence={"other:bund_a","other:bund_b"}/,
       "bundlesequence_variable");
};

subtest "Variable strings (ignore bundles)" => sub {
    my $oi=CFDivisions::OutputInterface->new(
	%default_args,
	ignore_bundles => ['bund_b'],
	);

    is($oi->bundlesequence_variable(),
       q/@cfdivisions_lib_bundlesequence={"default:bund_a"}/,
       "bundlesequence_variable");
};

done_testing;
