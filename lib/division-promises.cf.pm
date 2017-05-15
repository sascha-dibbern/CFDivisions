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

=over

=item *cfdivisions_depends

The division's required (direct) dependency on other divisions within the divisions library.

=item *cfdivisions_bundlesequence

The division's own specific bundlesequence. These agent bundles are run in given order when this B<division> is executed.

=back

=head2 About "*cfdivisions_depends" annotation

Here any dependency directly to any prerequired other division from the same division-library can be defined.

Example:
A divisons depends on two other divisions (webservers_www_mysite1_com & webservers_www_mysite2_com) within the library 

  #
  # *cfdivisions_depends=webservers_www_mysite1_com,webservers_www_mysite2_com
  #

=head2 About "*cfdivisions_bundlesequence" annotation

Each divisions has its own specific bundlesequence where agent bundles are executed given order. 

=head3 Example: 

An division's agent bundles can be designed around the lifecycle of a service or a set of configuration items

  #
  # *cfdivisions_bundlesequence=serviceX_takedown,serviceX_installation,serviceX_configuration,serviceX_monitoring,serviceX_execution
  #

B<Note>:

The bundles in the sequence can also refer to other agent bundles from other B<divisons> or preloaded promises files. But generally this is not recommended since this break the concept of encapsulation.

=head3 Namespacing of agent bundles in the bundlesequence

Agent bundles that are defined without any namespace-prefix will automatically be given the namespace as defined in the C<--default_namespace> argument (see L<cfdivisions/"OPTIONS">).

The namespace can also explicitly be given to the bundle names, if the promises-file's namespace diverges from the default namespace of the library.

Example: 

  #
  # *cfdivisions_bundlesequence=webserver_domain_x:setup_server,webserver_domain_x:setup_logging
  #

  body file control
  {
    namespace => "webserver_domain_x";
  }

=head1 Processing all C<division-promises.cf> files

After processing of all divisions following type of variables are generated:

=over 

=item * @(default:cfdivisions.cfdivisions_{library}_inputs)

An array of the load and compilation order of all division-promises.cf files. This affects also the execution order of 'common bundles', since they are executed in the same order.

=item * @(default:cfdivisions.cfdivisions_{library}_bundlesequence)

An array of bundlesequence execution order of all agent bundles in all division-promises.cf files

=head2 Canonzation

Division names can (because of their origin in directory names) contain illegal characters for CFEngine. During the processing canonization replaces illegal characters with a '_' for division names to ensure consistency with CFEngine variable and class names.

Example: 'webservers/www.mysite.com' becomes 'webservers_www_mysite_com'

=head1 Division nesting

Divisions can be nested within the sub-directories of other divisions.

Example in filesystem:

  $(sys.workdir)/master
    |
    --> weblib                     [division library]
      |
      |-> Websites        [directory of top division]
      | |-> division-promises.cf   [promises file]
      | |-> config.dat             [data file]
      | |
      | |-> website_a              [directory of nested division]
      | | |-> division-promises.cf [promises file of nested division]
      | |
      | |-> website_b              [directory of nested division]
      |   |-> division-promises.cf [promises file of nested division]
      |
      |-> Webservices
      ...

Care has to be taken that resources like names of bodies, agent bundles, classes and alike, that used in a division and the nested divisions, are not in conflict. Here the usage of namespaces can help for  better seperation.

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
