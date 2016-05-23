package CFDivisions;

# ABSTRACT: Enable modularized CFEngine script configuration

use strict;
use warnings;
use v5.14;

use Carp;
use Getopt::Long;
use Data::Dumper;

use CFDivisions::Utils;
use CFDivisions::Parser;
use CFDivisions::Model;
use CFDivisions::OutputInterface;

our $class_parser = "CFDivisions::Parser";
our $class_model  = "CFDivisions::Model";
our $class_output = "CFDivisions::OutputInterface";

sub new {
    my $class = shift;
    my %args  = @_;

    GetOptions (
	"verbose"           => \$args{verbose},
	"inputs_path:s"     => \$args{inputs_path},
	"library=s"         => \$args{library},
	"library_subdir:s"  => \$args{library_subdir},
	);

    $args{library} // croak("No --library given.");

    my $self  = {
	verbose          => $args{verbose},
	library          => $args{library},
	library_subdir   => $args{library_subdir},
	inputs_path      => $args{inputs_path},
	output           => [],
    };

    bless $self, $class;
}

sub parser {
    my $self   = shift;

    my $verbose = $self->{verbose};
    my $parser  = $self->{parser};
    return $parser if defined $parser;

    $parser = $class_parser->new(
	verbose             => $verbose,
	inputs_path         => $self->{inputs_path},
	library             => $self->{library},
	library_subdir      => $self->{library_subdir},
	);

    $self->{parser} = $parser;
    return $parser;
}

sub parse {
    my $self    = shift;
    my $verbose = $self->{verbose};

    # Parsing division promise files
    my $parser = $self->parser(); 
    $parser->find_division_promise_files();
    $parser->read_division_promise_files();

    croak "Errors while parsing:\n".join("\n",errors()) 
	if errors();

    if ($verbose) {
	say "Bundlesequences:\n".Dumper(scalar $parser->bundlesequences);
	say "Divisions:\n"      .Dumper(scalar $parser->divisions);
	say "Divisionpaths:\n"  .Dumper(scalar $parser->divisionpaths);
	say "Dependencies:\n"   .Dumper(scalar $parser->dependencies);
    }
}

sub model {
    my $self  = shift;

    my $verbose = $self->{verbose};
    my $model   = $self->{model};
    return $model if defined $model;

    $model = $class_model->new(
	verbose       => $verbose,
	divisions     => scalar $self->parser->divisions(),
	dependencies  => scalar $self->parser->dependencies(),
	);

    $self->{model} = $model;
    return $model;
}

sub build_model {
    my $self   = shift;

    my $verbose = $self->{verbose};

    my $divisionorder = scalar $self->model()->divisionorder;

    croak "Errors while building model:\n".join("\n",errors()) 
	if errors();

    if ($verbose) {
	say "Divisionorder:";
	say Dumper($divisionorder);
    }
}

sub output_interface {
    my $self = shift;

    my $verbose = $self->{verbose};
    my $oi      = $self->{oi};
    return $oi if defined $oi;

    $oi=$class_output->new(
	verbose => $verbose,
	parser  => $self->parser,
	model   => $self->model,
	);

    $self->{oi} = $oi;
    return $oi;
}

sub generate_output {
    my $self   = shift;

    $self->{output} = [ 
	$self->output_interface->classes_strings(),
	$self->output_interface->variables_strings(),
	];
}

sub run {
    my $self  = shift;

    eval {
	# Parsing division promise files
	$self->parse;

	# Building model
	$self->build_model;

	# Generate output
	$self->generate_output;
    };
    
    if ($@) {
	say $@;
	exit 1;
    }

}

sub print_output {
    my $self  = shift;

    map { say $_ } @{$self->{output}}; 
}

1;
