package CFDivisions::Output;

use strict;
use warnings;
use v5.14;

use Carp;
use Data::Dumper;
use CFDivisions::Utils;

sub new {
    my $class = shift;
    my %args  = @_;

    my $parser    = $args{parser};
    my $model     = $args{model};
    my $verbose   = $args{verbose};

    my $library         = $args{library};
    my $basedir         = $args{basedir};
    my $divisions       = $args{divisions};
    my $divisionpaths   = $args{divisionpaths};
    my $bundlesequences = $args{bundlesequences};

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
    }

    my $divisionorder = $args{divisionorder};

    if (defined $model) {
	$divisionorder = $divisionorder 
	    // scalar($model->divisionorder);
    }

    $bundlesequences // croak('No bundlesequences defined');
    $divisions       // croak('No divisions defined');
    $divisionpaths   // croak('No divisionpaths defined');
    $divisionorder   // croak('No divisionorder defined');

    croak "'bundlesequences' is not a HASHREF" 
	unless ref($bundlesequences) eq "HASH"; 
    croak "'divisions' is not a HASHREF" 
	unless ref($divisions) eq "HASH"; 
    croak "'divisionpaths' is not a HASHREF" 
	unless ref($divisionpaths) eq "HASH"; 
    croak "'divisionorder' is not a ARRAYREF" 
	unless ref($divisionorder) eq "ARRAY"; 

    my $self = {
	verbose         => $verbose,
	library         => $library         // croak('No library defined'),
	basedir         => $basedir         // croak('No basedir defined'),
	bundlesequences => $bundlesequences // croak('No bundlesequences defined'),
	divisions       => $divisions       // croak('No divisions defined'),
	divisionpaths   => $divisionpaths   // croak('No divisionpaths defined'),
	divisionorder   => $divisionorder   // croak('No divisionorder defined'),
	
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

    my $verbose = $self->{verbose};
    my $library = $self->{library};
    my @out;

    # Class for used division library: cfdivisionlibrary_{library}
    push @out,"Class for library '$library':" if $verbose;
    push @out,$self->cfdivisionlibrary_class();

    # Defined division classes: {library}_{divisionname}
    push @out,"Division classes for library '$library':" if $verbose;
    push @out,$self->division_classes();
    
    return @out;
}


sub input_files_variable {
    my $self = shift;

    my $library = $self->{library};
    my @input_paths = map { 
	$self->{divisionpaths}->{$_}
    } @{$self->{divisionorder}};
    
    return '@cfdivisions_'.$library.'_inputs={'.join(',',map { '"'.$_.'"' } @input_paths)."}"
}

sub bundlesequence_variable {
    my $self = shift;

    # Bundlesequences are sorted by divisionorder
    my @bundlesequences   = map { 
	@{$self->{bundlesequences}->{$_}} 
    } @{$self->{divisionorder}};
    my $bs_string = join(',',(map { '"'.$_.'"' } @bundlesequences));
    my $library   = $self->{library};
    
    return '@cfdivisions_'.$library.'_bundlesequence={'.$bs_string.'}';
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
    my $verbose    = $self->{verbose};
    
    my @out;

    # Input-files: cfdivisions_{library}_inputs
    push @out,"Input-files for library '$library'" if $verbose;
    push @out,$self->input_files_variable();

    # Bundlesequence: @{library}_bundlesequence
    push @out,"Bundlesequence for library '$library'" if $verbose;
    push @out,$self->bundlesequence_variable();

    # Basedir for the division-library: {library}_basedir
    push @out,"Bundlesequence for library '$library'" if $verbose;
    push @out,$self->library_basedir();
    
    # Division names as array: @{library}_divisions
    push @out,"Library divisions for '".$library."'_divisions" if $verbose;
    push @out,$self->library_divisions();

    # Local paths to divisions as associative array: {library}_localpath[{divisionname}]
    push @out,"Local paths of library divisions for '$library'" if $verbose;    
    @out=(@out,$self->library_division_localpaths());

    # Paths to divisions as associative array: {library}_path[{divisionname}]
    push @out,"Paths of library divisions for '$library'" if $verbose;    
    @out=(@out,$self->library_division_paths());

    return wantarray ? @out : \@out;
}

1;




