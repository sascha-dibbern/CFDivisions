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

=head1 NAME

CFDivisions

=head1 DESCRIPTION

CFDivision is enabling the usage of CFengine promises libraries within a component-framework, where promises and their depencencies can be structured more coherent. Programming configuration management based on divisions follows a declarative approach of 'divide and conquere'.

=head1 Elements in CFDivisions

B<CFDivisions> introduces some new concepts to the organization and structure of CFEngine code and functionality.

=head2 Division

A B<division> is a selfcontaining component with capabilities as: 

=over

=item Runtime encapsulation 

Divisions encapsulate their runtime behaviour by defining their own local bundlesequence to control execution their own bundles. 

=item Declarative dependencies

Divisions can depend on other divisions. CFengine code structured as divisions enables the building of configurations in a stacked design represented a dependency graph. Promises of higher stacked divisions logically will build upon the promises of lower stacked divisions. 

=item Configuration containment

Divisions can use their own namespace to scope structural classes and variables. A division can manage, address and contain its own resources.

=head2 Division promises file

A division promises file (L<division-promises.cf>) defines the promises within a division.

=head2 Division library

A division library is a collection of one or more divisions. If no library is specified the default is 'division'.

=head2 Division names

Division names are based on the L<canonized|"division-properties.cf/Canonization"> filesystem paths to the directories containing the division promises definition file. 

=head2 Naming of division artefacts

Variables and classes that are generated under parsing of the division definitions contain 

=over

=item the library name

As a scope identifier

=item the artefact name

=item (sometimes) the division name

=back

=head1 Motivation

The standard way of reading promises files and executing interdependent bundles in CFEngine is really procedural. The developer has only one main bundlesequence, and as alternative he has to resolve into calling other bundles from the calling bundles own methode section. This could easily lead to complex monolithic executions structures that are hard to maintain and test (like using mockup promises). It is also harder to reuse CFEngine-code as distributeable packages/libraries for others to CFEngine implementations. B<cfdivision> is an attempt to distribute the role of the central bundlesequence out into B<divisions>. A division can in other programming languages seen as packages, components or other alike structures.

=head1 Tips and recommendations

Using B<cfdivisions> can be a first step in structuring complex CFengine scripts. With cfdivisions some aspects from object orientation and componentbased programming could be implementet and enhance the code reuse and maintainabillity.

=head2 Naming convention of bundles in divisions

For better readabillity and easier maintenance of bundles defined in division promise files, it is a good idea to prepend the bundle names with the canonized name of its containing division.

Example: Bundle C<content> in organized under division C</webservers/www.mysite.com> (canonized name C<webservers_www_mysite_com>) could be named instead to C<webservers_www_mysite_com_content>.

=head2 Resources in divisions (data artefacts)

It can be an good idea to place resources (template text files, ...) into the same division folder with the promises that are using them. The divisions path (basepath and local path or full path) can be used identify the path to the resources.

=head2 Failsafe mechanism (TODO: rewrite or remove)

Divisions can contain failsafe promises that could be called from C<failsafe.cf>. By creating special C<division-failsafe.cf> files in the divisions and refering to the from central C<failsafe.cf> file.

B<!!! A failback implementation / adjustment needs thorough testing before being put into production !!!>

B<Example> Adjusted C<failsafe.cf>:

  bundle common import_divisions
  {
 
    classes:
      !imported_division::
        "imported_divisions" expression => usemodule ("cfdivisions","--basedir=divlib --promises=division-failsafe.cf --prefix=failback");

    reports:
      imported_division::
         "cfdivisions.failback_inputs: $(cfdivisions.failback_inputs)";
         "cfdivisions.failback_bundlesequence: $(cfdivisions.failback_bundlesequence)";
  }

  ...

  body common control
  {
    inputs => {
               "cfengine_stdlib.cf", 
               @(cfdivisions.failback_inputs),
              };
    bundlesequence => { 
                       "import_divisions",
                       @(cfdivisions.failback_bundlesequence),
                      }; 
  }

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
	verbose   => $verbose,
	parser    => $self->parser,
	model     => $self->model,
	namespace => $self->{namespace},
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

=item Content of a division promises file

L<'division-promises.cf'|division-promises.cf>

=item Examples

L<'CFDivisions-examples'|CFDivisions-examples> 

=back

=head1 Authors 

L<Sascha Dibbern|http://sascha.dibbern.info/> (sascha@dibbern.info) 

=cut

1;
