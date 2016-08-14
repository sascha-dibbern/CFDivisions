package CFDivisions;

# ABSTRACT: Enable modularized CFEngine script configuration

use strict;
use warnings;
use v5.14;

use Carp;
use Getopt::Long;
use Data::Dumper;

use parent 'CFDivisions';
use CFDivisions::Utils;

our $class_parser = "CFDivisions::Parser";
our $class_model  = "CFDivisions::Model";
our $class_output = "CFDivisions::OutputInterface";

sub new {
    my $class = shift;
    my %args  = @_;

    my $self=CFDivisions->new(%args);

    GetOptions (
	"podfolder:s" => \$args{podfolder},
	);
    
    $self->{podfolder}    = $args{podfolder};
    $self->{class_output} = "CFDivisions::PodFileGenerator";

    bless $self, $class;
}

sub pod_generator {
    my $self = shift;

    my $verbose = $self->{verbose};
    my $gen     = $self->{gen};
    return $gen if defined $gen;

    $gen=$self->{class_output}->new(
	verbose        => $verbose,
	parser         => $self->parser,
	model          => $self->model,
	namespace      => $self->{namespace},
        ignore_bundles => $self->{ignore_bundles},
	podfolder      => $self->{podfolder},
	);

    $self->{gen} = $gen;
    return $gen;
}


sub generate_output {
    my $self   = shift;

    $self->pod_generator->run;
}


1;
