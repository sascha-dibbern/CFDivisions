package CFDivisions;

# ABSTRACT: Enable modularized CFEngine script configuration

use strict;
use warnings;
use v5.14;

use Carp;
use Getopt::Long;
use Data::Dumper;
use File::Spec;

use parent 'CFDivisions';
use CFDivisions::Utils;

our $class_parser = "CFDivisions::Parser";
our $class_model  = "CFDivisions::Model";
our $class_output = "CFDivisions::OutputInterface";

# TODO: make user-context sensitive
our $default_pod_dir = "/var/cfengine/pod";

sub new {
    my $class = shift;
    my %args  = @_;

    my $self=CFDivisions->new(%args);

    GetOptions (
	"pod_dir:s" => \$args{pod_dir},
	);
    
    $pod_dir = File::Spec->catfile(
	$args{pod_dir} // $default_pod_dir,
	$self->library,
	);
    mkdir $pod_dir unless (-d $pod_dir);

    $self->{pod_dir}             = $pod_dir;
    $self->{pod_generator_class} = "CFDivisions::PodFileGenerator";
    
    bless $self, $class;
}

sub pod_generator {
    my $self = shift;

    my $verbose = $self->{verbose};
    my $gen     = $self->{pod_generator};
    return $gen if defined $gen;

    $gen=$self->{pod_generator_class}->new(
	verbose        => $verbose,
	parser         => $self->parser,
	model          => $self->model,
	namespace      => $self->{namespace},
        ignore_bundles => $self->{ignore_bundles},
	pod_dir        => $self->{pod_dir},
	);

    $self->{pod_generator} = $gen;
    return $gen;
}


sub generate_pods {
    my $self   = shift;

    eval {
	$self->pod_generator->run;
    };
    if ($@) {
	$self->{pod_error} = $@;
	die $@;
    }
}

sub man3_generator {
    my $self = shift;

    my $cfe_share_dir = "/var/cfengine/share";
    my $man_dir       = File::Spec->catfile($cfe_share_dir,'man');
    my $man3_dir      = File::Spec->catfile($man_dir,'man3');

    mkdir $man_dir;
    mkdir $man3_dir;

    my $verbose = $self->{verbose};
    my $gen     = $self->{man3_generator};
    return $gen if defined $gen;

    $gen=$self->{man3_generator_class}->new(
	verbose        => $verbose,
	parser         => $self->parser,
	model          => $self->model,
#	namespace      => $self->{namespace},
#        ignore_bundles => $self->{ignore_bundles},
	pod_dir        => $self->{pod_dir},
	man3_dir       => $man3_dir,
	);

    $self->{man3_generator} = $gen;
    return $gen;
}

sub generate_man3 {
    my $self   = shift;


    eval {
	$self->man3_generator->run;
    };
    if ($@) {
	$self->{man3_error} = $@;
	die $@;
    }

}

sub generate_output {
    my $self   = shift;

    print "+POD_OK_". $self->parser->library() unless $self->{pod_error};
    print "+MAN3_OK_".$self->parser->library() unless $self->{man3_error};
}

sub run {
    my $self  = shift;

    eval {
	# Parsing division promise files
	$self->parse;

	# Building model
	$self->build_model;

	# Building PODS
	$self->generate_pods();

	# Building man3
	$self->generate_man3();

	# Generate output
	$self->generate_output;
    };
    
    if ($@) {
	say $@;
	exit 1;
    }

}

1;
