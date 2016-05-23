package ModelMock;

use strict;
use warnings;
use v5.14;

use Carp;

our $divisionorder=[];

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = {%args};
    bless $self, $class;
    return $self;
}

sub divisionorder {
    my $self = shift;
    return $divisionorder;
}

1; 
