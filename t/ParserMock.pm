package ParserMock;

use strict;
use warnings;
use v5.14;

use Carp;

our $library;
our $bundlesequences;
our $divisions;
our $divisionpaths;
our $dependencies;

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = {%args};
    bless $self, $class;
    return $self;
}
 
sub library {
    my $self  = shift;
    my $value = $library;
    return $value;
}

sub bundlesequences {
    my $self  = shift;
    my $value = $bundlesequences;
    return wantarray ? %$value : $value;
}

sub divisions {
    my $self  = shift;
    my $value = $divisions;
    return wantarray ? %$value : $value;
}

sub divisionpaths {
    my $self  = shift;
    my $value = $divisionpaths;
    return wantarray ? %$value : $value;
}

sub dependencies {
    my $self  = shift;
    my $value = $dependencies;
    return wantarray ? %$value : $value;
}

sub find_division_promise_files {
    my $self    = shift;

}

sub read_division_promise_files {
    my $self = shift;
}

1;
