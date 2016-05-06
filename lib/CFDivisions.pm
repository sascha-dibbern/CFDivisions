package CFDivisions;

# ABSTRACT: Enable modularized CFEngine script configuration

use strict;
use warnings;
use v5.14;

use File::Find;
use File::Spec;
use Data::Dumper;

sub new {
    my $class = shift;
    my %args  = @_;
    
    my $inputs_path = $args{inputsdir} // "/var/cfengine/inputs";	
    my ($inputs_vol,$inputs_dir) = File::Spec->splitpath( $inputs_path, 1 );


    my $self  = {
	divisions                   => {},
	divisionpaths               => {},
	divisionfiles               => {},
	bundlesequences             => {},
	dependencies                => {},
	parsed_bundlesequence_token => undef,
	parsed_depends_token        => undef,

	divisionorder               => [],
	divisionordered             => {},

	# checklist datastructures for preventing circular division dependencies
	investigated                => {},
	investigated_stack          => [],

	errors                      => [],
	division_promise_files      => ["division-promises.cf"],
	inputs_vol                  => $inputs_vol,	
	inputs_dir                  => $inputs_dir,	
	library                     => $args{library} // die "Failed to create 'library' attribute",
	library_subdir              => $args{library_subdir} // $args{library} // die "Failed to create library_subdir attribute",	
    };

    # Override 'division_promises_files'
    if (defined $args{division_promise_files}) {
	my @division_promise_files = split /,/,$args{division_promise_files};
	$self->{division_promise_files} = \@division_promise_files;
    }

    # Defined 'basedir'
    $self->{basedir} = File::Spec->catpath(
	$self->{inputs_vol},
	$self->{inputs_dir},
	$args{library_subdir},
	);

    bless $self, $class;
}

sub errors {
    my $self = shift;
    return scalar($self->{errors});
}

sub canonize_divisionname {
    my $self = shift;
    my $name = shift;

    $name    =~ s/\W/_/g;
    $name    =~ s/^_+//;

    return $name
}

sub division_promise_files_in_directory {
    my $self     = shift;
    my $dir      = shift;
    my $file     = shift;

    # TODO: handle '/' in basedir
    my $basedir  = $self->{basedir};
    my @folders  = split(/$basedir/,$dir);
    my $folder   = $folders[1];

    foreach my $promise_file (@{$self->{division_promise_files}}) {
	next unless $file eq $promise_file;
	my $divname = $self->canonize_divisionname($folder);    
	$self->{divisions}->{$divname}     = $folder;
	$self->{divisionpaths}->{$divname} = $dir;
	$self->{divisionfiles}->{$divname} = $file;
	return;
    }
}

sub findDivisions {
    my $self = shift;

    $self->division_promise_files_in_directory($File::Find::dir,$_);
};

sub parse_promisefile_line {
    my $self     = shift;
    my $line     = shift;
    my $division = shift;

    chomp $line;
    return unless $line =~ /#/; # only comment lines are parsed

    if ($line =~ /\*cfdivisions_bundlesequence/) {
	my @allbs   = split(/\*cfdivisions_bundlesequence\s*=\s*/);
	if(scalar(@allbs)>1) {
	    my $bsvalue = pop @allbs; # get value side
	    $bsvalue    =~ s/\s+//g; # remove spaces
	    $self->{bundlesequences}->{$division} = [split(/,/,$bsvalue)];
	    $self->{parsed_bundlesequence_token}  = 1;
	} else {
	    $self->{bundlesequences}->{$division} = [];
	}
    }

    if ($line =~ /\*cfdivisions_depends/) {
	my @alldep   = split(/\*cfdivisions_depends\s*=\s*/);
	if(scalar(@alldep)>1) {
	    my $depvalue = pop @alldep; # get value side
	    $depvalue    =~ s/\s+//g; # remove spaces
	    $self->{dependencies}->{$division} = [
		map { 
		    canonize_divisionname($_) 
		} split(/,/,$depvalue)
		];
	    $self->{parsed_depends_token}      = 1;
	}
    }    
}

sub read_division_promise_iles {
    my $self = shift;

    foreach my $division (keys %{$self->{divisions}}) {
	my $path = File::Spec->catfile(
	    $self->{basedir},
	    $self->{divisions}->{$division},
	    $self->{divisionfiles}->{$division},
	    );
	$self->{parsed_bundlesequence_token} = undef;
	$self->{parsed_depends_token}        = undef;
	open FILE,"<".$path;
	while (<FILE>) {
	    unless ($self->{parsed_bundlesequence_token} and $self->{parsed_depends_token}) {
		$self->parse_promisefile_line($_,$division);
	    } else {
		last;
	    }
	}
	close FILE;
    }
}

#
# Investigate the order of divisions for later handling of the total bundlesequence
#
sub investigateDepOrder {
    my $self = shift;

    my ($divname)=shift;
    return if $self->{divisionordered}->{$divname};

    push @{$self->{investigated_stack}},$divname;
    if ($self->{investigated}->{$divname}) {
	push @{$self->{errors}},"Circular division dependencies:".join(",",@{$self->{investigated_stack}});
	pop @{$self->{investigated_stack}};
	return ;
    }
    # Add division to checklist
    $self->{investigated}->{$divname}=1;

    # Handle no dependency
    unless (exists $self->{dependencies}->{$divname}) {
	push @{$self->{divisionorder}},$divname;
	$self->{divisionordered}->{$divname} = 1;

	# remove division from checklist
	pop @{$self->{investigated_stack}};
	delete $self->{investigated}->{$divname};
	return;
    }

    # Handle direct dependencies
    my @directdeps = @{$self->{dependencies}->{$divname}};
    delete $self->{dependencies}->{$divname};
    foreach my $dep (@directdeps) {
	if (exists $self->{divisions}->{$dep}) {
	    $self->investigateDepOrder($dep);
	} else {
	    push @{$self->{errors}},"Illegal dependency '$dep' in division '$divname'";
	}
    }
    
    push @{$self->{divisionorder}},$divname;
    $self->{divisionordered}->{$divname} = 1;

    # remove division from checklist
    pop @{$self->{investigated_stack}};
    delete $self->{investigated}->{$divname};
}

sub orderDivisionExecution {
    my $self = shift;

    my @divnames=keys %{$self->{divisions}};
    while (@divnames) {
	my $divname=pop @divnames;
	$self->investigateDepOrder($divname);
    }
}

#
# Extract information
#

sub cfdivisionlibrary_class {
    my $self = shift;
    return "+cfdivisionlibrary_".$self->library;
}

sub division_classes {
    my $self = shift;
    return map { '+'.join('_',$self->{library},$_) } @{$self->divisionorder};
}

sub classes_strings {
    my $self = shift;

    my $verbose = $self->{verbose};
    my $debug   = $self->{debug};
    my $library = $self->{library};
    my $basedir = $self->{basedir};
    my @out;

    # Class for used division library: cfdivisionlibrary_{library}
    push @out,"Class for library '$library':" if $verbose;
    push @out,cfdivisionlibrary_class(
	library => $library,
	);

    # Defined division classes: {library}_{divisionname}
    push @out,"Division classes for library '$library':" if $verbose;
    push @out, division_classes();
    
    return @out;
}

sub input_files_variable {
    my $self = shift;

    my $library = $self->{library};
    my @input_paths = map { 
	File::Spec->catfile(
	    $self->{basedir},
	    $self->{divisions}->{$_},
	    $self->{divisionfiles}->{$_},
	    ) 
    } @{$self->{divisionorder}};
    
    return '@cfdivisions_'.$library.'_inputs={'.join(',',map { '"'.$_.'"' } @input_paths)."}"
}

sub bundlesequence_variable {
    my $self = shift;

    my $library = $self->{library};
    
    # Bundlesequences are sorted by divisionorder
    my @bundlesequence   = map { 
	@{$self->{bundlesequences}->{$_}} 
    } @{$self->{divisionorder}};

    my $bs_string = join(',',map { '"'.$_.'"' } @bundlesequence);

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

sub library_division_localpaths{
    my $self = shift;

    my $library   = $self->{library};
    my $divisions = $self->{divisions};

    return map {
	"=".$library."_localpath[".$_."]=".$divisions->{$_};
    } keys %$divisions;
}

sub library_division_paths{
    my $self = shift;

    my $library       = $self->{library};
    my $divisions     = $self->{divisions};
    my $divisionpaths = $self->{divisionpaths};

    return map {
	"=".$library."_path[".$_."]=".$divisionpaths->{$_};
    } keys %$divisions;
} 

sub variables_strings{
    my $self = shift;

    my $library    = $self->{library};
    my $basedir    = $self->{basedir};
    my $verbose    = $self->{verbose};
    
    my @out;

    # Input-files: cfdivisions_{library}_inputs
    push @out,"Input-files for library '$library'" if $verbose;
    push @out,$self->input_files_variable();

    # Bundlesequence: @{library}_bundlesequence
    push @out,"Bundlesequence for library '$library'" if $verbose;
    push @out,$self->bundlesequence_variable();

    # Basedir for the division-library: {library}_basedir
    my $lib_basedir = "=".$library."_basedir=".$basedir;
    push @out,"Bundlesequence for library '$library'" if $verbose;
    push @out,$self->library_basedir();
    
    # Division names as array: @{library}_divisions
    push @out,"Library divisions for '".$library."'_divisions" if $verbose;
    push @out,$self->library_divisions();

    # Local paths to divisions as associative array: {library}_localpath[{divisionname}]
    push @out,"Local paths of library divisions for '$library'" if $verbose;    
    map { push @out,$_ } library_division_localpaths();

    # Paths to divisions as associative array: {library}_path[{divisionname}]
    push @out,"Paths of library divisions for '$library'" if $verbose;    
    map { push @out,$_ } library_division_paths();

    return @out;
}

sub main {
    my $self  = shift;
    my %args  = @_;

    my $debug = $self->{debug};

    find(\&findDivisions, $self->{basedir});
    if ($debug) {
	say "Divisions:";
	say Dumper($self->{divisions});
    }
    exit 1 if $self->errors();

    read_division_promisefiles();
    if ($debug) {
	say "Bundlesequences:\n".Dumper($self->{bundlesequences});
	say "Dependencies:\n".Dumper($self->{dependencies});
    }
    exit 1 if $self->errors();

    orderDivisionExecution;
    if ($debug) {
	say "Divisionorder:";
	say Dumper($self->{divisionorder});
    }
    exit 1 if $self->errors();

    map { say $_ } ( 
	classes_strings(%args),
	variables_strings(%args),
    );
}



1;
