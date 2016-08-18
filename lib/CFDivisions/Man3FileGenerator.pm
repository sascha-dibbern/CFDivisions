package CFDivisions::Man3FileGenerator;

# ABSTRACT: Generate POD files out of the CFEngine 'cfdivisions' model

use strict;
use warnings;
use v5.14;

use Carp;
use Data::Dumper;
use File::Spec;
use Pod::Man;
use CFDivisions::Utils;
use CFDivisions::OutputInterface;

use parent qw(CFDivisions::OutputInterface);

sub new {
    my $class = shift;
    my %args  = @_;

    my $self  = CFDivisions::OutputInterface->new(%args);

    my $pod_dir         = $args{pod_dir} // croak('No POD directory defined');
    $self->{pod_dir}    = $pod_dir;

    my $man3_dir        = $args{man3_dir} // croak('No man3 directory defined');
    $self->{man3_dir}   = $man3_dir;

    $self->{pod_parser} = Pod::Man->new (section => 3);

    bless $self, $class;
    return $self;
}

sub pod_path {
    my $self     = shift;
    my $division = shift;

    return File::Spec->catfile(
	$self->{pod_dir},
	$self->{library}.':'.$division.".pod",
	);
}

sub man3_path {
    my $self     = shift;
    my $division = shift;

    return File::Spec->catfile(
	$self->{man3_dir},
	$self->{library}.':'.$division.".3",
	);
}

sub transform_pod_to_man3 {
    my $self = shift;
    my $division = shift;

    $self->{pod_parser}->parse_from_file (
	$self->pod_path($division), 
	$self->man3_path($division)
	);
}

sub run {
    my $self = shift;

    my %divisions = %{$self->{divisions}};

    for my $division (keys %divisions) {
	$self->transform_pod_to_man3($division);
    }
}

1;
