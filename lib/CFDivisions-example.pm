# POD placeholder for 'CFDivisions-example'

=head1 NAME

CFDivisions-example

=head1 DESCRIPTION

The following walkthrough example shows how to implement a minimal B<cfdivisions> based library setup.

=head1 Installation of cfdivisions

The program B<cfdivisions> and it's Perl librarie needs to be placed in the folder C<$(sys.workdir)/modules>. The script B<cfdivision> needs to have execution permissions for cf-agent.

=head1 Embedding of cfdivisions into the top most promise file

This example shows how B<cfdivisions> is embedded into a top most promises files (C<promises.cf>) under following conditions:

=over 

=item 1.

The CFEngine C<inputs>-folder contains a subfolder C<divlib>. The subfolder C<divlib> contains all the division folders to be imported and executed.

=item 2.

The C<--library> option is used with the same name as library-subfolder ('divlib'), so no explicit L<"cfdivisions --library_subdir"|cfdivisions/OPTIONS> option needs to be set. 

=back

B<Example>: C<promises.cf>

  bundle common import_divisions
  {
 
    classes:
      # Run module once before entering rest of the bundles sequence 
      # and inputs of "body common control"

      !imported_division::
         "imported_divisions" 
            expression => usemodule ("cfdivisions","--library=divlib");

    reports:
      imported_division::

         "cfdivisions.cfdivisions_inputs: 
              $(cfdivisions.cfdivisions_divlib_inputs)";

         "cfdivisions.cfdivisions_bundlesequence: 
              $(cfdivisions.cfdivisions_divlib_bundlesequence)";
  }

  ...

  body common control
  {
    bundlesequence => { 
                          # Here the magic happens
                          "import_divisions",

                          # The bundlesequence from divlib
                          @(cfdivisions.cfdivisions_divlib_bundlesequence),
                      }; 

    inputs => {
                  "cfengine_stdlib.cf", 
                   ...
                   # The inputs from divlib
                   @(cfdivisions.cfdivisions_divlib_inputs),
                   ...
              };
  }


=head1 Filesystem structure that defines divisions

The below filesystem hierachy examplifies the concept of divisions, nested divisions and canonizing divison names.

  $(sys.workdir)/inputs
    |
    |->promises.cf
    |
    -->divlib (1.)
      |
      |->commons (2.)
      |    |
      |    |->division-promises.cf
      |    |
      |    ...
      |
      |
      |->webservers (3.)
      |    |
      |    |->division-promises.cf
      |    |
      |    |->www.mysite.com (4.)
      |    |    |
      |    |    |->division-promises.cf
      |    |    |
      |    |    ... 
      |    |
      |    ... 
      |
      ...

=over

=item 1. "divlib"

Library folder for divisions

=item 2. divlib/commons

Division "commons". All files below that folder would or could belong to this division.

=item 3. divlib/webservers

Division "webservers". All files below that folder would or could belong to this division.

=item 4. divlib/webservers/www.mysite.com

Nested division "webservers_www_mysite_com". All files below that folder would or could belong to this division, but some might be part of division "webservers" too.

=back

=head1 Examples of the content of division promises files

Each division has its own C<division-promises.cf>.

=head2 The promise file for "commons" division

The promises for division B<commons> can contain annotations like:

  #
  # *cfdivisions_depends=
  # *cfdivisions_bundlesequence=virtualization,network
  #
  ...
  bundle agent virtualization
  ...
  bundle agent network
  ...

No dependencies are defined, but some common bundles will be executed by order of the local bundlesequence. 

=head2 Promise file for "webservers" division

The promises for division B<webservers> could look like:

  #
  # *cfdivisions_depends=commons
  # *cfdivisions_bundlesequence=base_webserver,webserver_log_management
  #
  
  bundle agent base_webserver
    ...
  
  bundle agent virtual_webserver(domain)
    ...

  bundle agent webserver_log_management
    ...
    methods:
    # call a bundle from division 'commons' 
    ...  

This division requires the preloading of division B<commons>, since a bundle from it's own bundlesequence invokes a 'commons'-based bundle.

=head2 Promise file for "webservers_www_mysite_com" division

The promises for division B<webservers_www_mysite_com> could look like:

  #
  # *cfdivisions_depends=webservers
  # *cfdivisions_bundlesequence=vhost_www_mysite_com,vhost_www_mysite_com_upload_area
  #
  
  bundle agent vhost_www_mysite_com
  {
    methods:
    # call bundle 'virtual_webserver' from division 'webservers'
    ...
  }  
  
  bundle agent vhost_www_mysite_com_upload_area
  {
    methods:
    # call a bundle from division 'commons' 
    ...
  }
  
This division requires the preloading of division B<webservers> and B<commons>. The division B<webservers> already has a dependency to B<commons>, so the dependency does not need to be declared in C<*cfdivisions_depends=...>

=head2 Execution

When cf-agent runs the top most promises file following actions will occur:

=over 

=item 1.

B<cfdivisions> is started. B<cfdivisions> reads and validated the divisions from inputs-subfolder 'divlib'.

=item 2.

B<cfdivisions> returns some CFEngine variables and classes.

=over

=item *

C<@(cfdivisions.cfdivisions_{prefix}_inputs)> contains the ordered load list of division promise files:

=over

=item 1.

divlib/commons/division-promises.cf

=item 2.

divlib/webservers/division-promises.cf

=item 3.

webservers/www.mysite.com/division-promises.cf

=back

=item *

C<@(cfdivisions.cfdivisions_{prefix}_bundlesequence)> contains the ordered list of division bundles to be executed:

=over

=item 1.

base_webserver

=item 2.

webserver_log_management

=item 3.

vhost_www_mysite_com

=item 4.

vhost_www_mysite_com_upload_area

=back

=item *

Classes for every identified and loaded division will be created:

=over

=item 1.

C<division_mylib>

=item 2.

C<division_webservers>

=item 3.

C<division_webservers_www_mysite_com>

=back

=back

=item 3.

In section C<inputs> from C<body common control> cf-agent continues the loading of promise files defined in C<@(cfdivisions.cfdivisions_{library}_inputs)>.

=item 4.

In section C<bundlesequence> from C<body common control> cf-agent executes then the bundles defined in C<@(cfdivisions.cfdivisions_{prefix}_bundlesequence)>.

=back

=head1 CLASSES

Classes for every identified and loaded division will be created:

=over

=item *

cfdivisionlibrary_{library} 

Class for loaded library

Example: 

  "cfdivisionlibrary_divlib" expression => "any";

=item *

{library}_{division}

Class for a loaded division within a library

Example: 

  "divlib_webservers_www_mysite_com" expression => "any";

=back

=head1 VARIABLES

=head2 Simple variables

=over

=item *

cfdivisions.{library}_basedir 

The given libraries the base directory (directory under the inputs directory).

Example: 

  "libdiv_basedir" string = "libdiv";

=back

=head2 Array variables

=over

=item *

@(cfdivisions.{library}_divisions 

A list over all parsed canonized division names in library.

Example: 

  "cfdivisions.libdiv_divisions" slist => {
      "commons", 
      "webservers", 
      "webservers_www_mysite_com"
  };

=item *

@(cfdivisions.cfdivisions_{library}_inputs)

The ordered load list of division promise files to be loaded.

Example: 

  "cfdivisions.mydivision_inputs" slist => {
      "divlib/commons/division-promises.cf", 
      "divlib/webservers/division-promises.cf", 
      "webservers/www.mysite.com/division-promises.cf"
  };

=item *

@(cfdivisions.cfdivisions_{library}_bundlesequence)

The ordered list of division bundles to be executed.

Example: 

  "cfdivisions_libdiv_bundlesequence" slist => {
      "virtualization",
      "network",
      "base_webserver", 
      "webserver_log_management", 
      "vhost_www_mysite_com", 
      "vhost_www_mysite_com_upload_area"
   };

=back

=head2 Associative array variables

=over

=item *

cfdivisions.{library}_localpath[{division}] 

The local path of the division root directory within the library.

Example: 

  "cfdivisions.libdiv_localpath[webservers]" string = "/webservers/www.mysite.com";

=item *

cfdivisions.{library}_path[{division}]

The full path of the division root directory within the library.

Example: 

  "cfdivisions.libdiv_path[webservers_www_mysite_com]" string = "/var/cfengine/inputs/divlib/webservers/www.mysite.com";

=back

=head1 See also

=over

=item L<'CFDivisions'|CFDivisions> : the concepts behind the CFEngine module

=item L<'cfdivisions'|cfdivisions> : the CFEngine module

=back

=head1 Authors 

L<Sascha Dibbern|http://sascha.dibbern.info/> (sascha@dibbern.info) 

=cut


1;
