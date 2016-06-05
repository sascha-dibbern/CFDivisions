# POD placeholder for 'CFDivisions-development-example'

1;

=head1 NAME

CFDivisions-development-example

=head1 DESCRIPTION

The following example explains the setup of a minimal division-development setup for a non-root user.
The development setup contains a division-library called 'divlib' with a division 'hellodiv'.

=head1 Prerequisites and assumptions

=over

=item 1.

A unixoid operative system.

=item 2.

CFEngine is installed.

=item 3.

A non-root user.

=back

=head1 Prepare CFDivisions

The module C<cfdivisions> and its Perl-modules needs either 

=over 

=item to be copied into ~/.cfagent/modules

  mkdir -p ~/.cfagent/modules
  cp /var/cfengine/modules/cfdivisions ~/.cfagent/modules/ 
  cp -r /var/cfengine/modules/perl5 ~/.cfagent/modules/

=item linked from ~/.cfagent/modules

  ln -s /var/cfengine/modules/cfdivisions ~/.cfagent/modules/cfdivisions
  ln -s /var/cfengine/modules/perl5 ~/.cfagent/modules/perl5

=back

=head1 ~/.cfagent/.inputs/promises.cf

The top promises file should contain:

=over

=item a control block for reading the divisions

=item a parametrized C<bundlesequence> definition

=item a parametrized C<inputs> defintion

=back 

=head2 Content

  bundle common import_devdivs
  {

    classes:
    # Run module once before entering rest of the bundles sequence
    # and inputs of "body common control"

    !import_devdivs::
      "import_devdivs"
        expression => usemodule ("cfdivisions","--library=devdivs --inputs_path=/home/user/.cfagent/inputs");

    reports:
      import_devdivs::

        "import_devdivs/cfdivisions.cfdivisions_devdivs_inputs:
          $(cfdivisions.cfdivisions_devdivs_inputs)";

        "import_devdivs/cfdivisions.cfdivisions_devdivs_bundlesequence:
          $(cfdivisions.cfdivisions_devdivs_bundlesequence)";
  }

  body common control
  {
      bundlesequence => {
        # Bundles from 'devdivs' library
        @(cfdivisions.cfdivisions_devdivs_bundlesequence),
        hello
      };

      inputs => {
        # Promisefiles from 'devdivs' library
        @(cfdivisions.cfdivisions_devdivs_inputs)
      };
  }

  # Just a bundle outside of CFDivisions
  bundle agent hello 
  {
    reports:
      any::
        "top hello";

  }

=head2 Access rights

chmod 644 ~/.cfagent/inputs/promises.cf

=head1 ~/.cfagent/inputs/devdivs

The division library to be developed

=head2 Access rights

chmod 644 ~/.cfagent/inputs/devdivs

=head1 ~/.cfagent/inputs/devdivs/hellodiv

A specific division in the division library

=head2 Access rights

chmod 644 ~/.cfagent/inputs/devdivs/hellodiv

=head1 ~/.cfagent/inputs/devdivs/hellodiv/division-promises.cf

=head2 Content

#
# *cfdivisions_depends=
# *cfdivisions_bundlesequence=hello_from_div
#

bundle agent hello_from_div
{
  reports:
    any::
      "hello from division";
}

=head2 Access rights

chmod 644 ~/.cfagent/inputs/devdivs/hellodiv/division-promises.cf

=cut


