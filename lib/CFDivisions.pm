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

our $default_class_parser = "CFDivisions::Parser";
our $default_class_model  = "CFDivisions::Model";
our $default_class_output = "CFDivisions::OutputInterface";

=head1 NAME

CFDivisions

=head1 DESCRIPTION

CFDivisions is the primary Perl class for the C<cfdivisions> CFEngine3 module.

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    # Default library
    $args{library} = 'division' unless defined $args{library};

    GetOptions (
	"verbose"           => \$args{verbose},
	"divisionfilter:s"  => \$args{divisionfilter},
	"inputs_path:s"     => \$args{inputs_path},
	"library:s"         => \$args{library},
	"library_subdir:s"  => \$args{library_subdir},
	"namespace:s"       => \$args{namespace},
	"ignore_bundles:s"  => \$args{ignore_bundles},
	);
    
    # Default for divisionfilter is empty
    $args{divisionfilter} = $args{divisionfilter} // "";

    # Default for ignore_bundles
    $args{ignore_bundles} = $args{ignore_bundles} // "";

    # Transform arguments
    my $divisionfilter = [ split /\s*,\s*/,$args{divisionfilter} ];
    my $ignore_bundles = [ split /\s*,\s*/,$args{ignore_bundles} ];

    my $self  = {
	verbose          => $args{verbose},
	divisionfilter   => $divisionfilter,
        ignore_bundles   => $ignore_bundles,
	library          => $args{library},
	library_subdir   => $args{library_subdir},
	inputs_path      => $args{inputs_path},
	namespace        => $args{namespace},
	output           => [],
	class_parser     => "CFDivisions::Parser",
	class_model      => "CFDivisions::Model",
	class_output     => "CFDivisions::OutputInterface",
    };

    bless $self, $class;
}

sub divisionfilter {
    my $self = shift;
    return wantarray ? @{$self->{divisionfilter}} : $self->{divisionfilter};
}

sub parser {
    my $self   = shift;

    my $verbose = $self->{verbose};
    my $parser  = $self->{parser};
    return $parser if defined $parser;

    $parser = $self->{class_parser}->new(
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

    speak("Bundlesequences:\n".Dumper(scalar $parser->bundlesequences),$verbose);
    speak("Divisions:\n"      .Dumper(scalar $parser->divisions),      $verbose);
    speak("Divisionpaths:\n"  .Dumper(scalar $parser->divisionpaths),  $verbose);
    speak("Dependencies:\n"   .Dumper(scalar $parser->dependencies),   $verbose);
}

sub model {
    my $self  = shift;

    my $verbose = $self->{verbose};
    my $model   = $self->{model};
    return $model if defined $model;

    $model = $self->{class_model}->new(
	verbose        => $verbose,
	divisionfilter => $self->{divisionfilter},
	divisions      => scalar $self->parser->divisions(),
	dependencies   => scalar $self->parser->dependencies(),
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

    speak("Divisionorder:",      $verbose);
    speak(Dumper($divisionorder),$verbose);
}

sub output_interface {
    my $self = shift;

    my $verbose = $self->{verbose};
    my $oi      = $self->{oi};
    return $oi if defined $oi;

    $oi=$self->{class_output}->new(
	verbose        => $verbose,
	parser         => $self->parser,
	model          => $self->model,
	namespace      => $self->{namespace},
        ignore_bundles => $self->{ignore_bundles},
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

=head1 See also

=over

=item The CFEngine module

L<'cfdivisions'|cfdivisions> 

=item The conceptual overview

L<'CFDivisions concept'|CFDivisions-concept> 

=item Content of a division promises file

L<'division-promises.cf'|division-promises.cf>

=item Examples

L<'CFDivisions-example'|CFDivisions-example> 

=back

=head1 Project

L<CFDivisions on github.com|https://github.com/sascha-dibbern/CFDivisions/>

=head1 Authors 

L<Sascha Dibbern|http://sascha.dibbern.info/> (sascha@dibbern.info) 

=cut

1;
