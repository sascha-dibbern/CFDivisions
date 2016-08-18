#!/bin/env perl

use strict;
use warnings;
use v5.14;

use File::Spec;
use Test::More;
use Test::Exception;
use Data::Dumper;
use Cwd qw/abs_path/;
use File::Temp qw/ tempfile tempdir /;

my $scriptpath;
BEGIN {
    ($scriptpath) = abs_path($0) =~ /(.*)CFDivisionsDoc.t/i;
}
use lib ($scriptpath);

my $testlib1 = 'testlib1';

use CFDivisionsDoc;
BEGIN { 
    use_ok( 'CFDivisionsDoc' ); 
}

subtest "Constructor" => sub {

    lives_ok { 
	my $cfd=CFDivisionsDoc->new();
    } "Success - no arguments";

};

my $tmpdir1 = tempdir( CLEANUP => 1 );
# say $tmpdir1;
my $pod_dir = $tmpdir1.'/cfdivisionsdoc-test-pod/';
my $man_dir = $tmpdir1.'/cfdivisionsdoc-test-man/';

subtest "Integrationtest: Loading testlib1" => sub {

    my $cfd      = CFDivisionsDoc->new(
	inputs_path => $scriptpath,
	library     => $testlib1,
	commments   => 0,
	pod_dir     => $pod_dir,
	man_dir     => $man_dir,
#	verbose     => 1,
	); 

    $cfd->run();
    ok(-e $pod_dir."/testlib1:div1.pod","POD file created");
    ok(-e $man_dir."/man3/testlib1:div1.3","man3 file created");
};

done_testing;
