package CFDivisions::Model;

# ABSTRACT: Building a logical model of of divisions in a division-library

use strict;
use warnings;
use v5.14;

use Data::Dumper;
use CFDivisions::Utils;
use Carp;

sub new {
    my $class = shift;
    my %args  = @_;

    my $divs  = $args{divisions} // croak "No 'divisions' argument";
    croak "'divisions' argument must be hashref" 
	unless ref($divs) eq 'HASH';

    my $deps  = $args{dependencies} // croak "No 'dependencies' argument";
    croak "'dependencies' argument must be hashref" 
	unless ref($deps) eq 'HASH';

    my $self  = {
	divisions                => $divs,
	dependencies             => $deps,

	divisionorder            => undef,
	divisionordered          => {},

	# checklist for preventing circular division dependencies
	circular_div_ref_stack   => [],

	verbose                  => $args{verbose},
    };

    bless $self, $class;
    return $self;
}

sub assert_no_circular_division_reference {
    my $self  = shift;

    my $stack = $self->{circular_div_ref_stack};
    my %count;
    for my $stacked_division (@$stack) {
	$count{$stacked_division}++;
	croak "Circular division dependencies: ".join(",",@$stack)
	    if $count{$stacked_division}>1;	
    }
}

sub add_to_circular_division_ref_investigation {
    my $self     = shift;
    my $division = shift;
    my $stack    = $self->{circular_div_ref_stack};
    push @$stack,$division;
}

sub remove_from_circular_division_ref_investigation {
    my $self     = shift;
    my $division = pop @{$self->{circular_div_ref_stack}};
}

sub assert_existing_division_dependencies {
    my $self     = shift;
    my $division = shift;
    my $deps     = shift;

    # not necessary due to circular ref check
    # delete $self->{dependencies}->{$division};

    foreach my $dep (@$deps) {
	croak "Illegal division dependency '$dep' in division '$division'"
	    unless exists $self->{divisions}->{$dep};
    }
}

sub assert_existing_division {
    my $self     = shift;
    my $division = shift // croak "No division";

    croak "Nonexisting division" 
	unless defined $self->{divisions}->{$division};
}

sub add_division_to_divisionorder {
    my $self     = shift;
    my $division = shift // croak "No division";

    $self->assert_existing_division($division);
    push @{$self->{divisionorder}},$division;
    $self->{divisionordered}->{$division} = 1;
}

sub is_division_in_divisionorder {
    my $self     = shift;
    my $division = shift // croak "No division";

    return $self->{divisionordered}->{$division};
}

#
# Investigate the order of divisions for later handling of the total bundlesequence
#
sub add_divisiontree_to_divisionorder {
    my $self     = shift;
    my $division = shift // croak "No division";

    # Case 1: division is already in divisionorder
    return 0 if $self->is_division_in_divisionorder($division);
    
    $self->add_to_circular_division_ref_investigation($division);
    $self->assert_no_circular_division_reference();

    my $dependencies = $self->{dependencies}->{$division};

    # Case 2: Division has no dependencies
    unless (defined $dependencies) {
	$self->add_division_to_divisionorder($division);

	$self->remove_from_circular_division_ref_investigation;
	return 1;
    }

    $self->assert_existing_division_dependencies($division,$dependencies);
  
    # Recurse into dependencies 
    map { 
	$self->add_divisiontree_to_divisionorder($_);
    } @$dependencies;
    
    $self->add_division_to_divisionorder($division);

    # remove division from checklist
    $self->remove_from_circular_division_ref_investigation;
}

sub divisionorder {
    my $self = shift;

    unless (defined $self->{divisionorder}) {
	$self->{divisionorder} = [];

	my @divisions=keys %{$self->{divisions}};
	for my $division (@divisions) {
	    eval {
		$self->add_divisiontree_to_divisionorder($division);
	    };
	    if ($@) {
		add_error($@);
	    }
	}
    }

    croak "Errors while building divisionorder:\n".join("\n",errors()) 
	if errors();
 
    return wantarray ?
	@{$self->{divisionorder}} :
	$self->{divisionorder};
}

#sub validate_
1;
