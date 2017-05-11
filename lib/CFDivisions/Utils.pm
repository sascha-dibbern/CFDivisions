package CFDivisions::Utils;

# ABSTRACT: Helper classes for CFDivisions

use strict;
use warnings;
use v5.14;

use Carp;
use Data::Dumper;
use Exporter 'import'; 

our @EXPORT = qw(
    canonized_cfe_identifier
    errors 
    add_error 
    assert_cfengine_identifier
    speak
    is_cfe_identifier
    is_cfe_namespaced_identifier
); 

sub canonized_cfe_identifier {
    my $name = shift;

    $name    =~ s/\W/_/g;
#    $name    =~ s/^_+//g;
#    $name    =~ s/_+$//g;

    return $name
}

my @errors;

sub errors {
    return wantarray ? @errors : scalar @errors ;
}

sub add_error {
    my $error   = shift;

    if (defined $error) {
	# croak "Here: .$error.";
	push @errors,$error;
    }
}

sub assert_cfengine_identifier {
    my $identifier = shift;

    return $identifier if is_cfe_namespaced_identifier($identifier);
    return $identifier if is_cfe_identifier($identifier);

    croak "Illegal CFEngine identifier ($identifier)." 
}

sub speak {
    my $text    = shift;
    my $verbose = shift;
    
    return unless $verbose;

    my @lines     = split /\n/,$text;
    my @commented = map { "# ".$_ } @lines;
    
    say join("\n",@commented);
}

sub is_cfe_identifier { 
    my $identifier = shift;

    # Undefined identifier
    return 0 unless defined $identifier;
 
    # Empty identifier
    return 0 if $identifier eq '';

    # Identifier does not start with a number
    return 0 if $identifier=~/^\d/;
 
   # Identifier that does not change by canonization
    return $identifier eq canonized_cfe_identifier($identifier);
}

sub is_cfe_namespaced_identifier {
    my $identifier = shift;

    # Undefined identifier
    return 0 unless defined $identifier;

    # Empty identifier
    return 0 if $identifier eq '';

    # Illegal number of elements
    my @elements = split /:/,$identifier;
    return 0 unless scalar(@elements) == 2;

    # Namespace not starting with '_'
    return 0 if $elements[0]=~/^_/;

    # Assume no content change when canonized
    my @compared = grep {
	is_cfe_identifier($_)
    } @elements;
    return 1 if scalar(@compared)==scalar(@elements);

    return 0;
}

1;
