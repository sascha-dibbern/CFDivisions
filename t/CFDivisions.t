#!/bin/env perl

use strict;
use warnings;
use v5.14;

use File::Spec;
use Test::More;
use Test::Exception;
use Data::Dumper;
use Cwd qw/abs_path/;

my $scriptpath;
BEGIN {
    ($scriptpath) = abs_path($0) =~ /(.*)CFDivisions.t/i;
}
use lib ($scriptpath);

use CFDivisions;
BEGIN { 
    use_ok( 'CFDivisions' ); 
    use_ok( 'ParserMock' ); 
    use_ok( 'ModelMock' ); 
    use_ok( 'OutputInterfaceMock' ); 
}


subtest "Constructor" => sub {
    $CFDivisions::class_parser="ParserMock";
    $CFDivisions::class_model ="ModelMock";
    $CFDivisions::class_output="OutputInterfaceMock";
    
    lives_ok { 
	my $cfd=CFDivisions->new();
    } "Success - no arguments";

    lives_ok { 
	my $cfd=CFDivisions->new(
	    library => 'lib',	    
	    ); 
    } "Success - with arguments";


    $CFDivisions::class_parser="CFDivisions::Parser";
    my $cfd=CFDivisions->new(divisionfilter=>'a ,  b');

    is($cfd->parser->library,"division","Default library: division");

    my $df = $cfd->divisionfilter();
    is_deeply($df,['a','b'],"Divisionfilter parsed")
};


subtest "Integrationtest: Loading testlib1" => sub {
    $CFDivisions::class_parser="CFDivisions::Parser";
    $CFDivisions::class_model ="CFDivisions::Model";
    $CFDivisions::class_output="CFDivisions::OutputInterface";

    my $testlib1 = 'testlib1';

    my $cfd      = CFDivisions->new(
	inputs_path => $scriptpath,
	library     => $testlib1,
	commments   => 0,
#	verbose     => 1,
	); 

#    lives_ok { $cfd->run(); } "Running";
    
    is($cfd->parser->library,$testlib1,"Right library");
    
    lives_ok { $cfd->parse; } "Survived parsing";
    my $bs = $cfd->parser->bundlesequences();
    is_deeply(
	$bs,
	{
	    'div1' => [
		'testlib1:div1_b1',
		'testlib1:div1_b2',
		],
	    'div3' => [
		    'testlib1:div3_b1'
		],
	    'path1_div2' => [
		'testlib1:path1_div2_b1',
		'testlib1:path1_div2_b2'
	    ],
	},
	"Getting bundlesequences",
	);
    #say Dumper($bs);

    lives_ok { $cfd->build_model; } "Survived building model";
    my $divord = $cfd->model->divisionorder;
    is_deeply(
	$divord,
	[
	 'div1',
	 'path1_div2',
	 'div3',
        ],
	"Getting division order",
	);
    #say "Dumper($divord);

    lives_ok { $cfd->generate_output; } "Survived output generation";

    my @classes=$cfd->output_interface->classes_strings();
    is_deeply(
	\@classes,
	[
	 '+cfdivisionlibrary_testlib1',
	 '+testlib1_div1',
	 '+testlib1_path1_div2',
	 '+testlib1_div3'
        ],
	'Valid class definitions',
	);
#    say Dumper(\@classes);
    my @variables=$cfd->output_interface->variables_strings();
    is_deeply(
	\@variables,
	[
          '=testlib1_basedir='.$scriptpath.'testlib1/',
          '@testlib1_divisions={"div1","div3","path1_div2"}',
          '@cfdivisions_testlib1_inputs={"'.
	 $scriptpath.'testlib1/div1/division-promises.cf","'.
	 $scriptpath.'testlib1/path1/div2/division-promises.cf","'.
	 $scriptpath.'testlib1/div3/division-promises.cf"}',
          '@cfdivisions_testlib1_bundlesequence={"testlib1:div1_b1","testlib1:div1_b2","testlib1:path1_div2_b1","testlib1:path1_div2_b2","testlib1:div3_b1"}',
          '=testlib1_localpath[div1]=div1',
          '=testlib1_localpath[div3]=div3',
          '=testlib1_localpath[path1_div2]=path1/div2',
          '=testlib1_path[div1]='.$scriptpath.'testlib1/div1',
          '=testlib1_path[div3]='.$scriptpath.'testlib1/div3',
          '=testlib1_path[path1_div2]='.$scriptpath.'testlib1/path1/div2',
        ],
	'Valid variable definitions'
	);
#    say Dumper(\@variables);

};

done_testing;

