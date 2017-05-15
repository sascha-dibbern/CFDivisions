package CFDivisionsDoc;

# ABSTRACT: Generate POD and man3 documentation from division-promise files

use strict;
use warnings;
use v5.14;

use Carp;
use Getopt::Long;
use Data::Dumper;
use File::Spec;

use parent 'CFDivisions';
use CFDivisions::Utils;

our $default_pod_dir = "/var/cfengine/share/pod";
our $default_man_dir = "/var/cfengine/share/man";

# In case of nonroot user
my $login = getlogin || getpwuid($<) || "root";
unless ($login eq 'root') {
    my $share_dir    = File::Spec->catfile($ENV{HOME},"share");
    $default_pod_dir = File::Spec->catfile($share_dir,"pod");
    $default_man_dir = File::Spec->catfile($share_dir,"man");
}

use CFDivisions::PodFileGenerator;
use CFDivisions::Man3FileGenerator;

sub new {
    my $class = shift;
    my %args  = @_;

    my $self=CFDivisions->new(%args);

    GetOptions (
	"pod_dir:s" => \$args{pod_dir} ,
	"man_dir:s" => \$args{man_dir},
	);
    
    my $pod_dir = $args{pod_dir} // $default_pod_dir;
    my $man_dir = $args{man_dir} // $default_man_dir;

    $self->{pod_dir} = $pod_dir;
    $self->{man_dir} = $man_dir;

    $self->{pod_generator_class}  = "CFDivisions::PodFileGenerator";
    $self->{man3_generator_class} = "CFDivisions::Man3FileGenerator";
    
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
        ignore_bundles => $self->{ignore_bundles},
	pod_dir        => $self->{pod_dir},
	);

    $self->{pod_generator} = $gen;
    return $gen;
}


sub generate_pods {
    my $self   = shift;

    mkdir $self->{pod_dir} unless (-d $self->{pod_dir});

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

    my $man_dir  = $self->{man_dir};
    mkdir $man_dir unless (-d $man_dir);

    my $man3_dir = File::Spec->catfile($man_dir,'man3');
    mkdir $man3_dir unless (-d $man3_dir);

    my $verbose = $self->{verbose};
    my $gen     = $self->{man3_generator};
    return $gen if defined $gen;

    $gen=$self->{man3_generator_class}->new(
	verbose        => $verbose,
	parser         => $self->parser,
	model          => $self->model,
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

    say "+".$self->parser->library()."_POD_OK"  unless $self->{pod_error};
    say "+".$self->parser->library()."_MAN3_OK" unless $self->{man3_error};
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
