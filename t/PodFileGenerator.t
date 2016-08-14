#!/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Exception;
use Data::Dumper;
use v5.14;

use CFDivisions::PodFileGenerator;

BEGIN { use_ok( 'CFDivisions::PodFileGenerator' ); }

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
    poddir => "/tmp",
);

package TestGenerator;

use parent qw(CFDivisions::PodFileGenerator);

sub new {
    my $class = shift;
    my %args  = @_;

    my $self        = CFDivisions::PodFileGenerator->new(%args);
    my $input       = $args{input}; 
    $self->{input}  = \$input;
    my $output      = "";
    $self->{output} = \$output;

    bless $self, $class;
    return $self;
}

sub promises_file_path {
    my $self     = shift;
    my $division = shift;

    return $self->{input};
}

sub pod_path {
    my $self     = shift;
    my $division = shift;

    return $self->{output};
}

sub output {
    my $self = shift;
    return ${$self->{output}};
}

package main;

subtest "Constructor" => sub {
    my $pfg;
    lives_ok {
	$pfg=CFDivisions::PodFileGenerator->new(
	    %default_args,
	    );
    } "Argumentative constructor";

    lives_ok {
	$pfg=TestGenerator->new(
	    %default_args,
	    );
    } "Testgenerator: Argumentative constructor";

};

my $test_data1=<<EOD;
#
# *cfdivisions_bundlesequence = bund_a
# *cfdivisions_depends = dep_x
#text1
xyz
#text2

EOD

subtest "Generate POD" => sub {
    my $pfg=TestGenerator->new(
	%default_args,
	input => $test_data1,
	);
    $pfg->write_pod_from_division('a');
    my $out=$pfg->output;
    ok($out=~/text1/,"Comment text found");
    ok($out=~/text2/,"Comment text found");
    ok(!($out=~/cfdiv/),"No cfdivison tags found");
    ok(!($out=~/xyz/),"No normal text found");
#    print $out;
};

done_testing();
