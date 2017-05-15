package CFDivisions::OutputInterface;

# ABSTRACT: The output-interface of the CFEngine module 'cfdivisions'

use strict;
use warnings;
use v5.14;

use Carp;
use Data::Dumper;
use CFDivisions::Utils;
use CFDivisions::Parser;

=pod

=head1 Name

CFDivisions::OutputInterface
cfdivisions - A CFEngine3 module for using a component based promise management.

=head1 SYNOPSIS

=head1 DESCRIPTION

Class that create CFEngine classes and variables from CFDivision-metadata.

=head1 CFENGINE CLASSES

Classes for every identified and loaded division will be created:

=over

=item *

cfdivisionlibrary_{library} : class for loaded library

=item *

{library}_{division} : class for a loaded division within a library

=back

=head1 CFENGINES VARIABLES

=head2 Simple variables

=over

=item *

cfdivisions.{library}_basedir

The given libraries the base directory (directory under the inputs directory).

=back

=head2 Array variables

=over

=item *

@(cfdivisions.{library}_divisions

A list over all parsed canonized division names in library.

=item *

cfdivisions.cfdivisions_{library}_inputs)

The ordered load list of division promise files to be loaded.

=item *

@(cfdivisions.cfdivisions_{library}_bundlesequence)

The ordered list of division bundles to be executed.

=back

=head2 Associative array variables

=over

=item *

cfdivisions.{library}_localpath[{division}]

The local path of the division root directory within the library.

=item *

cfdivisions.{library}_path[{division}]

The full path of the division root directory within the library.

=back

=cut

sub new {
    my $class = shift;
    my %args  = @_;

    my $parser            = $args{parser};
    my $model             = $args{model};
    my $verbose           = $args{verbose};
    my $comments          = $args{comments};
    my $default_namespace = $args{default_namespace};
    my $ignore_bundles    = $args{ignore_bundles};

    my $library           = $args{library};
    my $basedir           = $args{basedir};
    my $divisions         = $args{divisions};
    my $divisionpaths     = $args{divisionpaths};
    my $bundlesequences   = $args{bundlesequences};
    my $dependencies      = $args{dependencies};

    if (defined $parser) {
	$library         = $library
	    // $parser->library();
	$basedir         = $basedir
	    // $parser->basedir();
	$divisions       = $divisions       
	    // scalar $parser->divisions();
	$divisionpaths   = $divisionpaths
	    // scalar $parser->divisionpaths();
	$bundlesequences = $bundlesequences
	    // scalar $parser->bundlesequences();
	$dependencies    = $dependencies
	    // { $parser->dependencies() };
    }

    my $divisionorder = $args{divisionorder};

    if (defined $model) {
	$divisionorder = $divisionorder 
	    // scalar($model->divisionorder);
    }

    $library         // croak('No library defined');
    $basedir         // croak('No basedir defined');
    $bundlesequences // croak('No bundlesequences defined');
    $divisions       // croak('No divisions defined');
    $divisionpaths   // croak('No divisionpaths defined');
    $divisionorder   // croak('No divisionorder defined');
    $dependencies    // croak('No dependencies defined');

    croak "'bundlesequences' is not a HASHREF" 
	unless ref($bundlesequences) eq "HASH"; 
    croak "'divisions' is not a HASHREF" 
	unless ref($divisions) eq "HASH"; 
    croak "'divisionpaths' is not a HASHREF" 
	unless ref($divisionpaths) eq "HASH"; 
    croak "'divisionorder' is not a ARRAYREF" 
	unless ref($divisionorder) eq "ARRAY"; 
    croak "'dependencies' is not a HASHREF" 
	unless ref($dependencies) eq "HASH"; 

    my $self = {
	verbose         => $verbose,
	comments        => $comments,
        ignore_bundles  => $ignore_bundles  // [],
	library         => $library,
	basedir         => $basedir,
	bundlesequences => $bundlesequences,
	divisions       => $divisions,
	divisionpaths   => $divisionpaths,
	divisionorder   => $divisionorder,
	dependencies    => $dependencies,
    };

    bless $self, $class;
    return $self;
}

sub cfdivisionlibrary_class {
    my $self = shift;
    return "+cfdivisionlibrary_".$self->{library};
}

sub division_classes {
    my $self = shift;
    return map { 
	'+'.join('_',$self->{library},$_) 
    } @{$self->{divisionorder}};
}

sub classes_strings {
    my $self = shift;

    my $comments = $self->{comments};
    my $library  = $self->{library};
    my @out;

    # Class for used division library: cfdivisionlibrary_{library}
    push @out,"Class for library '$library':" if $comments;
    push @out,$self->cfdivisionlibrary_class();

    # Defined division classes: {library}_{divisionname}
    push @out,"Division classes for library '$library':" if $comments;
    push @out,$self->division_classes();
    
    return @out;
}


sub input_files_variable {
    my $self = shift;

    my $library = $self->{library};
    my @input_paths = map {
	my @path=File::Spec->splitpath($self->{divisionpaths}->{$_},1);
	File::Spec->catfile(@path,$CFDivisions::Parser::DIVISION_PROMISE_FILE);
    } @{$self->{divisionorder}};
    
    return '@cfdivisions_'.$library.'_inputs={'.join(',',map { '"'.$_.'"' } @input_paths)."}"
}

sub bundlesequence_variable {
    my $self = shift;

    # Bundlesequences are sorted by divisionorder
    my @gross_bundlesequence   = map { 
	@{$self->{bundlesequences}->{$_}} 
    } @{$self->{divisionorder}};

    # Filter out ignored bundles
    my %ignore_bundles = map { $_ => 1 } @{$self->{ignore_bundles}};
    my @bundlesequence = grep { ! defined $ignore_bundles{$_} } @gross_bundlesequence;

    my $bs_string = join('","',@bundlesequence);

    my $library   = $self->{library};
    
    return '@cfdivisions_'.$library.'_bundlesequence={"'.$bs_string.'"}';
}

sub library_basedir {
    my $self = shift;

    my $library = $self->{library};

    return "=".$library."_basedir=".$self->{basedir};
}

sub library_divisions {
    my $self = shift;

    my $library   = $self->{library};
    my $divisions = $self->{divisions};

    return "@".$library."_divisions={".join(',',map { '"'.$_.'"' } keys %$divisions)."}";
}

sub library_division_localpaths {
    my $self = shift;

    my $library   = $self->{library};
    my $divisions = $self->{divisions};
    my @dlps      = map {
	"=".$library."_localpath[".$_."]=".$divisions->{$_};
    } keys %$divisions;
    
    return wantarray ? @dlps : \@dlps;
}

sub library_division_paths {
    my $self = shift;

    my $library       = $self->{library};
    my $divisions     = $self->{divisions};
    my $divisionpaths = $self->{divisionpaths};
    my @dlps          = map {
	"=".$library."_path[".$_."]=".$divisionpaths->{$_};
    } keys %$divisions;

    return wantarray ? @dlps : \@dlps;
} 

sub variables_strings {
    my $self = shift;

    my $library    = $self->{library};
    my $comments   = $self->{comments};
    
    my @out;

    # Basedir for the division-library: {library}_basedir
    push @out,"Basedir for library '$library'" if $comments;
    push @out,$self->library_basedir();
    
    # Division names as array: @{library}_divisions
    push @out,"Library divisions for '".$library."'_divisions" if $comments;
    push @out,$self->library_divisions();

    # Input-files: @cfdivisions_{library}_inputs
    push @out,"Input-files for library '$library'" if $comments;
    push @out,$self->input_files_variable();

    # Bundlesequence: @cfdivisions_{library}_bundlesequence
    push @out,"Bundlesequence for library '$library'" if $comments;
    push @out,$self->bundlesequence_variable();

    # Local paths to divisions as associative array: {library}_localpath[{divisionname}]
    push @out,"Local paths of library divisions for '$library'" if $comments;    
    @out=(@out,$self->library_division_localpaths());

    # Paths to divisions as associative array: {library}_path[{divisionname}]
    push @out,"Paths of library divisions for '$library'" if $comments;
    @out=(@out,$self->library_division_paths());

    return wantarray ? @out : \@out;
}

1;




