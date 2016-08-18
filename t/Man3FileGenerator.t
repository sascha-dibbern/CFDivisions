#!/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use v5.14;

use CFDivisions::Man3FileGenerator;

BEGIN { use_ok( 'CFDivisions::Man3FileGenerator' ); }

my %default_args=(
    library         => 'lib',
    basedir         => '/basedir',
    bundlesequences => {
	a=>['bund_a'],
	b=>['bund_b'],
	dep_x => ['bund_x1','bund_x2'],
	dep_y => ['bund_y1','bund_y2'],
    },
    divisions   => {
	a=>'lib/path_a',
	b=>'lib/path_b',
    },
    divisionpaths   => {
	a=>'/root/lib/path_a',
	b=>'/root/lib/path_b',
    },
    divisionorder   => ['dep_x','dep_y','a','b'],
    dependencies    => {
	b=>['a'],
	a=>['dep_x'],
    },
    pod_dir => "/tmp",
    man3_dir => "/tmp",
);

subtest "Constructor" => sub {
    my $pfg;
    lives_ok {
	$pfg=CFDivisions::Man3FileGenerator->new(
	    %default_args,
	    );
    } "Argumentative constructor";
};

done_testing();
