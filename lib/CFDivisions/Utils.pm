package CFDivisions::Utils;

use strict;
use warnings;
use v5.14;

use Data::Dumper;
use Exporter 'import'; 

our @EXPORT = qw(
    canonize_divisionname 
    errors 
    add_error 
    assert_cfengine_identifier
); 

sub canonize_divisionname {
    my $name = shift;

    $name    =~ s/\W/_/g;
    $name    =~ s/^_+//g;
    $name    =~ s/_+$//g;

    return $name
}

my @errors;

sub errors {
    my $self = shift;

    return wantarray ? @errors : scalar(@errors);
}

sub add_error {
    my $self  = shift;
    my $error = shift;

    if (defined $error) {
	push @errors,$error;
    }
}

sub assert_cfengine_identifier {
    my $identifier = shift;

    die "Illegal CFEngine identifier. Contains non-word characters." 
	if $identifier=~/\W/;
    die "Illegal CFEngine identifier. Starting with '_'." 
	if $identifier=~/^_/;

    return $identifier;
}


1;
