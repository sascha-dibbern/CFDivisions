package CFDivisions::PodFileGenerator;

# ABSTRACT: Generate POD files out of the CFEngine 'cfdivisions' model

use strict;
use warnings;
use v5.14;

use Carp;
use Data::Dumper;
use File::Spec;
use CFDivisions::Utils;
use CFDivisions::OutputInterface;

use parent qw(CFDivisions::OutputInterface);

sub new {
    my $class = shift;
    my %args  = @_;

    my $self        = CFDivisions::OutputInterface->new(%args);
    my $poddir      = $args{poddir} // croak('No basedir defined');
    $self->{poddir} = $poddir;

    bless $self, $class;
    return $self;
}

sub read_division_promises_file {
    my $self = shift;
    my $path = shift;

    open(my $fh,"<",$path) || croak("Could not open division promise file: $path");
    my @lines=<$fh>;
    close $fh;

    return \@lines;
}

sub extract_pod_string {
    my $self  = shift;
    my $lines = shift;

    my @result;
    for my $line (@$lines) {
	# Any non-comment lines are ignored
	next if ! ($line =~ /^#/);
	
	# Any cfdivison tags
	next if $line =~ /^\s*.*cfdivisions_bundlesequence\s*=/;
	next if $line =~ /^\s*.*cfdivisions_depends\s*=/;

	# Remove comment hash
	$line =~ s/^#//;

	push @result,$line;
    }

    return \@result;
}

sub promises_file_path {
    my $self     = shift;
    my $division = shift;

    return $self->{divisionpaths}->{$division};
}

sub make_pod_from_division {
    my $self     = shift;
    my $division = shift;

    my $namespace = $self->{namespace};
    my $library   = $self->{library};
    my $path      = $self->promises_file_path($division);

    my @head;
#    push @head,"=pod";

    push @head,"=head1 Division name\n";
    push @head,$division."\n";

    push @head,"=head1 Scope\n";
    push @head,"=over\n";
    push @head,"=item Library:   ".$library."\n";
    push @head,"=item Namespace: ".$namespace."\n";
    push @head,"=back\n";

    # Division defined bundlesequence
    push @head,"=head1 Bundlesequence\n";
    my @bs = @{$self->{bundlesequences}->{$division}};
    push @head,"=over\n";
    for my $bundle (@bs) {
	push @head,'=item L<"'.$namespace.':'.$bundle.'"|/"'.$bundle.'"'.">\n";
    }
    push @head,"=back\n";

    # All direct divisions to be loaded until this division
    my @direct_dep = @{$self->{dependencies}->{$division}};
    push @head,"=head1 Depends direcly on divisions\n";
    push @head,"=over\n";
    for my $dependency (@direct_dep) {
	push @head,'=item L<"'.$library.':'.$dependency.'">'."\n";
    }
    push @head,"=back\n";

    
    # All divisions be loaded until this division
    my $up_til_same_division = 0;
    my @all_division_dependencies = grep {
	$up_til_same_division = 1 if $_ eq $division; 
	! $up_til_same_division
    } @{$self->{divisionorder}};
    push @head,"=head1 Division stack\n";
    push @head,"Depend overall on divisions and bundles\n";
    push @head,"=over\n";
    for my $dependency (reverse @all_division_dependencies) {
	push @head,'=item Division: L<"'.$library.':'.$dependency.'">'."\n";

	push @head,"=over\n";
	for my $bundle (@{$self->{bundlesequences}->{$dependency}}) {
	    push @head,'=item L<"'.$namespace.':'.$bundle.'"|'.$dependency.'/"'.$bundle.'"'.">\n";
	}
	push @head,"=back\n";
    }
    push @head,"=back\n";

    # End POD HEAD
    push @head,"=cut\n";

    my $promises_lines = $self->read_division_promises_file($path);
    my @lines          = (@head,@{$self->extract_pod_string($promises_lines)});
    
    return join("\n",@lines);
}

sub pod_path {
    my $self     = shift;
    my $division = shift;

    return File::Spec->catfile(
	$self->{poddir},
	$self->{namespace}.':'.$division.".pod",
	);
}

sub write_pod_from_division {
    my $self     = shift;
    my $division = shift;

    my $pod      = $self->make_pod_from_division($division);
    my $pod_path = $self->pod_path($division);

    open(my $fh,">",$pod_path) || croak("Could not open POD file: $pod_path");
    print $fh $pod;
    close $fh;
}

sub run {
    my $self     = shift;

    my @divisions = keys %{$self->{divisions}};

    for my $division (@divisions) {
	$self->write_pod_from_division($division);
    }
}


1;

