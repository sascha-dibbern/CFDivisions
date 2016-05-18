package CFDivisions::Parser;

use strict;
use warnings;
use v5.14;

use File::Find;
use File::Spec;
use Data::Dumper;
use CFDivisions::Utils;

our $DIVISION_PROMISE_FILE = "division-promises.cf";

sub new {
    my $class = shift;
    my %args  = @_;
    
    my $inputs_path = $args{inputs_path} // "/var/cfengine/inputs";	
    my ($inputs_vol,$inputs_dir) = File::Spec->splitpath( $inputs_path, 1 );

    my $self  = {
	divisions                   => {},
	divisionpaths               => {},
	bundlesequences             => {},
	dependencies                => {},
	parsed_bundlesequence_token => undef,
	parsed_depends_token        => undef,


	inputs_vol                  => $inputs_vol,	
	inputs_dir                  => $inputs_dir,	
	
	verbose                     => $args{verbose},
	library                     => $args{library} // carp("Failed to create 'library' attribute"),
	library_subdir              => $args{library_subdir} // $args{library},	
    };

    # Defined 'basedir'
    $self->{basedir} = File::Spec->catpath(
	$self->{inputs_vol},
	$self->{inputs_dir},
	$self->{library_subdir},
	);

    bless $self, $class;
    return $self;
}

sub library {
    my $self  = shift;
    my $value = $self->{library};
    return $value;
}

sub bundlesequences {
    my $self  = shift;
    my $value = $self->{bundlesequences};
    return wantarray ? %$value : $value;
}

sub divisions {
    my $self  = shift;
    my $value = $self->{divisions};
    return wantarray ? %$value : $value;
}

sub divisionpaths {
    my $self  = shift;
    my $value = $self->{divisionpaths};
    return wantarray ? %$value : $value;
}

sub dependencies {
    my $self  = shift;
    my $value = $self->{dependencies};
    return wantarray ? %$value : $value;
}

sub is_valid_division_promise_file_path {
    my $self = shift;
    my $path = shift // carp("No path defined");
    my $file = shift // carp("No file defined");

    my $basedir  = $self->{basedir};
    my $rel_path = File::Spec->abs2rel( $path, $basedir ) ;

    # We do not allow breaking out from basedir
    return 0 if $rel_path =~ /\.\./;

    # Promise file must have right name
    return 0 unless ($file eq $DIVISION_PROMISE_FILE) ;

    return 1;
}

sub assert_no_division_name_collision {
    my $self     = shift;
    my $divname  = shift // carp("No division name defined");
    my $relpath  = shift // carp("No relative path defined");
    
    my $otherpath = $self->{divisions}->{$divname};
    if (defined $otherpath) {
	carp("Name collision between for division '$divname' in paths '$relpath' and '$otherpath'");
    }
}


sub register_division_promise_file {
    my $self = shift;
    my $path = shift // carp("No path defined");
    my $file = shift // carp("No file defined");

    return 0 unless $self->is_valid_division_promise_file_path($path,$file);

    my $basedir  = $self->{basedir};
    my $rel_path = File::Spec->abs2rel( $path, $basedir );
    my $divname  = canonize_divisionname($rel_path);    
    $self->assert_no_division_name_collision($divname,$rel_path);

    $self->{divisions}->{$divname}     = $rel_path;
    $self->{divisionpaths}->{$divname} = $path;

    return 1;
}

sub find_division_promise_files {
    my $self    = shift;

    my $verbose     = $self->{verbose};
    my $handle_file = sub  {
	eval {
	    $self->register_division_promise_file($File::Find::dir,$_);
	};
	if ($@) {
	    add_error($@);
	}
    };

    find($handle_file, $self->{basedir});

    if ($verbose) {
	say "Division promise files found:";
	say Dumper($self->{divisions});
    }

    carp("Errors while finding division promise files:\n".join("\n",errors()))
	if $self->errors();
}

sub parse_cfdivisions_bundlesequence_token {
    my $self     = shift;
    my $line     = shift // carp("No line defined");
    my $division = shift // carp("No division name defined");

    return 0 unless ($line =~ /#\s*\*cfdivisions_bundlesequence/);

    my @allbs   = split(/#\s*\*cfdivisions_bundlesequence\s*=\s*/,$line);
    my $bsvalue = pop(@allbs) // ""; # get value side
    $bsvalue    =~ s/\s+//g; # remove spaces
    my @bs;
    eval {
	@bs = map { 
	    assert_cfengine_identifier($_);
	} split(/,/,$bsvalue);
    };
    if ($@) {
	carp("Parsing '*cfdivisions_bundlesequence' failed. $@");
    }
    $self->{bundlesequences}->{$division} = \@bs;
    $self->{parsed_bundlesequence_token}  = 1;

    return 1
}

sub parse_cfdivisions_depends_token {
    my $self     = shift;
    my $line     = shift // carp("No line defined");
    my $division = shift // carp("No division name defined");

    return 0 unless ($line =~ /#\s*\*cfdivisions_depends/);

    my @alldeps  = split(/#\s.*\*cfdivisions_depends\s*=\s*/,$line);
    my $depvalue = pop(@alldeps) // ""; # get value side
    $depvalue    =~ s/\s+//g; # remove spaces
    my @deps;
    eval {
	@deps = map { 
	    assert_cfengine_identifier($_);
	} split(/,/,$depvalue);
    };
    if ($@) {
	carp("Parsing '*cfdivisions_depends' failed. $@");
    }
    
    $self->{dependencies}->{$division} = \@deps;
    $self->{parsed_depends_token}      = 1;

    return 1;
}

sub parse_promisefile_line {
    my $self     = shift;
    my $line     = shift // carp("No line defined");
    my $division = shift // carp("No division name defined");

    chomp $line;
    return 0 unless $line =~ /#/; # only comment lines are parsed
    
    return 1 if $self->parse_cfdivisions_bundlesequence_token($line,$division);
    return 1 if $self->parse_cfdivisions_depends_token($line,$division);
}

sub read_division_promise_file {
    my $self     = shift;
    my $division = shift // carp("No division name defined");
    
    # Clean parse states
    $self->{parsed_bundlesequence_token} = undef;
    $self->{parsed_depends_token}        = undef;

    my $path    = $self->{divisionpaths}->{$division};
    my $line_nr = 1;

    open(my $fh,"<",$path) || carp("Could not open division promise file: $path");
    while (<$fh>) {
	# No need to go further if all things been parsed
	last if $self->{parsed_bundlesequence_token} and $self->{parsed_depends_token};

	eval {
	    $self->parse_promisefile_line($_,$division);
	};
	if ($@) {
	    carp("$@\nFile: '$path'\nLine: $line_nr");
	}
	$line_nr++;
    }
    close $fh;
}

sub read_division_promise_files {
    my $self = shift;

    foreach my $division (keys %{$self->{divisions}}) {
	eval {
	    $self->read_division_promise_file($division);
	};
	add_error($@);
    }

    carp("Errors while parsing:\n".join("\n",errors())) if errors();
}


1;
