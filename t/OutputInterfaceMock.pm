package OutputInterfaceMock;

use strict;
use warnings;
use v5.14;

use Carp;

sub new {
    my $class = shift;
    my %args  = @_;
    my $self  = {%args};
    bless $self, $class;
    return $self;
}
 
sub classes_strings {
    my $self = shift;
    return ("class");
}

sub variables_strings {
    my $self = shift;
    return ("variable");
}

1;
