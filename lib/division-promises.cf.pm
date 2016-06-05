# POD placeholder for 'division-promises.cf'

# PODNAME: division-promises.cf
# ABSTRACT: Content of division-promises.cf files

=head1 NAME 

division-promises.cf

=head1 SYNOPSIS

<divisionpath>/division-promises.cf

=head1 DESCRIPTION

L<cfdivisions> reads a library containing one or more B<division-promises.cf> files.

=head1 Division name 

The L<canonized|CANONIZATION> absolute directory path to a division-promises file defines the name (and namespace) of the division.
 
=head1 Annotations

A division promises file (L<division-promises.cf>) contains CFEngine promises and special cfdivisions annotations for this division. Annotations are written within commented sections of a division-promises file. A division promises file contains following annotations.

=head2 *cfdivisions_depends

The required (direct) dependency on other divisions within the divisions library namespace.

Example:
The divions depends on two other divisions (webservers_www_mysite1_com &webservers_www_mysite2_com) within the library 

   #
   # *cfdivisions_depends=webservers_www_mysite1_com,webservers_www_mysite2_com
   #

=head2 *cfdivisions_bundlesequence

The divisions own specific bundle sequences, and therefore the sequence of bundles that are run when this B<division> is executed.

Example: 

  #
  # *cfdivisions_bundlesequence=mybundleA,mybundleB
  #

B<Note>:

The bundles in the sequence can also originate from other B<divisons> or promises files which have to be preloaded either 

=over 

=item *

with L<cfdivisions> by B<*cfdivisions_{library}_bundlesequence> or 

=item *

by C<inputs> section in C<body common control> in the top most promise file. 

=back

=head1 Canonzation

Illegal characters are through canonization replaced with a '_' for division names and CFEngine variable and class names.

Example: 'webservers/www.mysite.com' becomes 'webservers_www_mysite_com'

=head1 Division nesting

Divisions can be nested within the sub-directories of other divisions.
Care has to be taken that resources used in a divsion and the nested divisions are not in conflict.

=head1 See also

=over

=item The conceptual overview

L<'CFDivisions'|CFDivisions> 

=item The CFEngine module

L<'cfdivisions'|cfdivisions> 

=item Content of a division promises file

L<'division-promises.cf'|division-promises.cf>

=back

=cut

1;
