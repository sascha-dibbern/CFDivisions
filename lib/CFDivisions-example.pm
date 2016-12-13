# POD placeholder for 'CFDivisions-example'

# PODNAME: CFDivisions-example
# ABSTRACT: An explained example about integration of divisions in CFengine

=head1 NAME

CFDivisions-example

=head1 DESCRIPTION

The following walkthrough example shows how to implement a minimal B<cfdivisions> based setup with a single divisions library called B<divlib>.

=head1 Installation of cfdivisions

The program B<cfdivisions> is placed in the folder C<$(sys.workdir)/modules>. The script B<cfdivision> needs to be executiable (permissions). Also B<cfdivision> depends on supporting Perl libraries, that can be placed in following places:

=over

=item * C<$(sys.workdir)/modules/perl5> (RECOMMENDED and expected)

At this placement the libraries automatically are distributed to the machines under Cfengine control

=item * The default PERL5-installation libraries (NOT RECOMMENDED)

Here automatically distribution to the machnines under Cfengine control is out of control of Cfengines default behaviour. A separate distribution mechanism needs to be invoked to ensure existence of a functional B<cfdivsions> setup on the Cfengine controlled machines.

=back

=head1 Implementation of cfdivisions into the master promise file

This example shows how B<cfdivisions> is implemented in the master promises file (C<$(sys.workdir)/master/promises.cf>) under following conditions:

=over 

=item 1. A library directory C<divlib>

The CFEngine C<$(sys.workdir)/master>-folder contains a subfolder C<divlib>. The subfolder C<divlib> contains all the divisions to be imported and executed for this example cfdivisions library C<divlib>.

=item 2. A C<--library> option

The cfdivisions C<--library> option sets the name of the used library-subfolder (like C<divlib>). Alternatively an explicit L<"cfdivisions --library_subdir"|cfdivisions/OPTIONS> option can be used to set an alternative library-path. 

=back

B<Example>: C<$(sys.workdir)/master/promises.cf>

  # As a common bundle this runs before any 'agent' bundles will be executed
  bundle common import_divisions
  {
 
    classes:
      # Ensure one-time execution of the loading of the cfdivision library 'divlib'
      !imported_divlib_ok::
         "imported_divlib_ok" 
            expression => usemodule ("cfdivisions","--library=divlib");

    reports:
      # When divisions were imported then show the defined inputs and bundlesequence
      imported_division_ok::

         "cfdivisions.cfdivisions_inputs: 
              $(cfdivisions.cfdivisions_divlib_inputs)";

         "cfdivisions.cfdivisions_bundlesequence: 
              $(cfdivisions.cfdivisions_divlib_bundlesequence)";
  }

  ...

  body common control
  {
      inputs => {
                          # File definition for global variables and classes
                          "controls/$(sys.cf_version_major).$(sys.cf_version_minor)/def.cf",
                          "controls/$(sys.cf_version_major).$(sys.cf_version_minor)/def_inputs.cf",

                          # Inventory policy
                          @(inventory.inputs),

                          # Design Center
                          "sketches/meta/api-runfile.cf",
                          @(cfsketch_g.inputs),

                          # CFEngine internal policy for the management of CFEngine itself
                          @(cfe_internal_inputs.inputs),

                          # Control body for all CFEngine robot agents
                          @(cfengine_controls.inputs),

                          # COPBL/Custom libraries.  Eventually this should use wildcards.
                          @(cfengine_stdlib.inputs),

                          # autorun system
                          @(services_autorun.inputs),

                          "services/main.cf",

                          #----------------------------------------------------------------
                          # Here the generated division input(s) are implemented.
                          # cfdivisons ensures a correct order of the input files.
                          #
                          # The inputs from divlib
                          @(cfdivisions.cfdivisions_divlib_inputs),
                          #----------------------------------------------------------------
              };

      bundlesequence => { 
                          # Common bundle first (Best Practice)
                          inventory_control,
                          @(inventory.bundles),
                          def,
                          @(cfengine_enterprise_hub_ha.classification_bundles),

                          # Design Center
                          cfsketch_run,

                          # autorun system
                          services_autorun,
                          @(services_autorun.bundles),

                          # Agent bundle
                          cfe_internal_management,   # See cfe_internal/CFE_cfengine.cf

                          main, # This bundle could also be executed after divsion execution ...

                          #----------------------------------------------------------------
                          # Here the generated divisions bundlesequence(s) are implemented.
                          # cfdivisons ensures a correct order of the bundles based on 
                          # dependency order.
                          #
                          # The bundlesequence from divlib
                          @(cfdivisions.cfdivisions_divlib_bundlesequence),
                          #----------------------------------------------------------------

                          @(cfengine_enterprise_hub_ha.management_bundles)
                      }; 

  }


=head1 The filesystem structure and the divisions library

The below filesystem hierachy examplifies the concept of divisions, nested divisions and the derivation of canonized divison names.

  $(sys.workdir)/master
    |
    |->promises.cf (master promises file)
    |
    -->divlib (1. the division library)
      |
      |->commons (2. a division)
      |    |
      |    |->division-promises.cf
      |    |
      |    ...
      |
      |
      |->webservers (3. a division)
      |    |
      |    |->division-promises.cf
      |    |
      |    |->www.mysite.com (4. a nested division)
      |    |    |
      |    |    |->division-promises.cf
      |    |    |
      |    |    ... 
      |    |
      |    ... 
      |
      ...

=over

=item 1. B<divlib> : $(sys.workdir)/master/divlib

Library folder for divisions used as the library C<divlib>

=item 2. B<divlib/commons> : $(sys.workdir)/master/divlib/commons

The division "commons". All files below that folder could belong to this division.

=item 3. B<divlib/webservers> : $(sys.workdir)/master/divlib/webservers

The division "webservers". All files below that folder would or could belong to this division.

=item 4. B<divlib/webservers/www.mysite.com> : $(sys.workdir)/master/divlib/webservers/www.mysite.com

The nested division "webservers_www_mysite_com". All files below that folder would or could belong to this division, but some could be part of division "webservers" too.

=back

=head2 Division nesting

There is no limitiations or constraints about nesting divisions into divisions. It is up to the developer own design, why and how the nesting is implemented. 

=head1 Examples of the content of division promises files

Each division has its own C<division-promises.cf> file.

=head2 The promise file for the "commons" division

The content for division B<commons> could be like:

  #
  # *cfdivisions_depends=
  # *cfdivisions_bundlesequence=virtualization,network
  #

  body file control
  {
      # Anchor following division artefacts into a namespace equal to the division-name
      namespace => "diblib";
  }
  ...
  # A bundle being part of the divisions bundlesequence
  bundle agent virtualization
  ...
  # A bundle being part of the divisions bundlesequence
  bundle agent network
  ...

No dependencies C<*cfdivisions_depends> are defined, but some agent bundles will be executed by the order of the local bundlesequence C<*cfdivisions_bundlesequence>.

=head2 Promise file for the "webservers" division

The content for division B<webservers> could look like:

  #
  # *cfdivisions_depends=commons
  # *cfdivisions_bundlesequence=base_webserver,webserver_log_management
  #
  
  body file control
  {
      # Anchor following division artefacts into a namespace equal to the division-name
      namespace => "diblib";
  }

  # A bundle being part of the divisions bundlesequence
  bundle agent base_webserver
    ...
  
  # A bundle NOT being part of the divisions bundlesequence
  bundle agent virtual_webserver(domain)
    ...
    vars:
    # refers to variable-value from a bundle in division 'commons' 
    ...

  # A bundle being part of the divisions bundlesequence
  bundle agent webserver_log_management
    ...
    methods:
    # calls a bundle from division 'commons' 
    ...  

This division requires the preloading and preexecution of the division B<commons>, since bundles from it's own bundlesequence could invoke elements from 'commons'-division. Declaring C<*cfdivisions_depends=commons> ensure that this dependency is taken into account in later compilation and execution in cf-agent.

=head2 Promise file for "webservers_www_mysite_com" division

Dependending on the foundation for webservers-building another division for building a dedicated website could be used.
The pathname to the division is a canonized form of the local directory-path C<$(sys.workdir)/master/divlib>.
  
The content of the division B<webservers_www_mysite_com> could look like:

  #
  # *cfdivisions_depends=webservers,commons
  # *cfdivisions_bundlesequence=vhost_www_mysite_com,vhost_www_mysite_com_upload_area
  #

  body file control
  {
      # Anchor following division artefacts into a namespace equal to the division-name
      namespace => "diblib";
  }
  
  bundle agent vhost_www_mysite_com
  {
    methods:
    # call bundle 'virtual_webserver' from division 'webservers'
    ...
  }  
  
  bundle agent vhost_www_mysite_com_upload_area
  {
    methods:
    # might call a bundle from division 'commons' 
    ...
  }
  
This division requires the preloading of the divisions B<webservers> and B<commons>. B<webservers> has already a dependency to B<commons>, so the dependency does not need to be declared explicitely in C<*cfdivisions_depends=...>, but it does not hurt still doing so as seen above. There are also no requirements on the ordering of these dependencies as this will processed optimal by cfdivisions own algorithm.

=head2 Execution of cfdivisions

When cf-agent runs the master promises file (later in $(sys.workdir)/inputs/promises.cf) following actions will occur:

=over 

=item 1.

B<cfdivisions> is started. B<cfdivisions> reads and validates all division-definitions (division-promises.cf) in the inputs-subfolder C<divlib>.

=item 2. 

When B<cfdivisions> fails execution, it will not return any half processes variables or classes but fail completely and thereby disable any partial division execution and incomplete execution.

Typical errors are often division misconfigurations like:

=over

=item * syntax errors

=item * unknown referenced divisions

=item * circular referenced divisions

=back

=item 3.

B<cfdivisions> returns a consistent set of CFEngine variables and classes for the ordered execution of divisions.
The variables and classes are anchored in the C<default> cfengine namespace, and their name always will contain the identifier of the given division library (C<--library> option).

=item 4.

In the master promises file under section C<inputs> cf-agent loads the division promises files defined in C<@(default:cfdivisions.cfdivisions_divlib_inputs)>.

=item 5.

In the master promises file under section C<bundlesequence> cf-agent executes the bundles defined in C<@(default:cfdivisions.cfdivisions_divlib_bundlesequence)> .

=back

=head1 CLASSES

C<cfdivisions> creates for every valid division library and divisionset with a collection of classes. These classes are anchored in a C<default> cfengine namespace:

=over

=item * C<default:cfdivisionlibrary_{library}>

Class for the existence of the usable library like C<default:cfdivisionlibrary_divlib>

=item * C<default:{library}_{division}>

Classes for the existence of usable divisions

=over

=item C<default:divlib_commons>

=item C<default:divlib_webservers>

=item C<default:divlib_webservers_www_mysite_com>

=back

=back

=head1 VARIABLES

C<cfdivisions> creates for every valid division library and divisionset a collection of variables. These variables are anchored in a C<default> cfengine namespace:

=head2 Simple variables

=over

=item * default:cfdivisions.{library}_basedir 

The given libraries base directory, which is the library subdirectory under the C<$(sys.workdir)/inputs> directory.
In the used example it would be a variable called C<libdiv_basedir> with the value C<libdiv>".

=back

=head2 Array variables

=over

=item * @(default:cfdivisions.{library}_divisions)

Here C<cfdivisions.libdiv_divisions> contains a list over all parsed (canonized) division names in the library.
The order of the divisions equals the dependency stack, were most fundament divisions start the the list.

=over

=item 1. C<commons> 

=item 2. C<webservers>

=item 3. C<webservers_www_mysite_com>

=back

=item * @(cfdivisions.cfdivisions_{library}_inputs)

C<@(cfdivisions.cfdivisions_divlib_inputs)> contains the ordered load list of division promise files.
The order ensures that division can depend on definitions of more fundamental divisions like in the case of dependencies between C<bundle common ...> definitions.

=over

=item 1. C<divlib/commons/division-promises.cf>

=item 2. C<divlib/webservers/division-promises.cf>

=item 3. C<webservers/www.mysite.com/division-promises.cf>

=back

=item * C<@(cfdivisions.cfdivisions_{library}_bundlesequence)>

Here C<@(cfdivisions.cfdivisions_divlib_bundlesequence)> contains the ordered list of division bundles to be executed. 
The list order ensures the correct execution of dependencies between C<bundle agent ...> definitions.
The bundlenames will include the given library-name as a cfengine namespace-prefix:

=over

=item 1. C<divlib:virtualization>

=item 2. C<divlib:network>

=item 3. C<divlib:base_webserver>

=item 4. C<divlib:webserver_log_management>

=item 5. C<divlib:vhost_www_mysite_com>

=item 6. C<divlib:vhost_www_mysite_com_upload_area>

=back

=back

=head2 Associative array variables

The associative array variables help to give tom meta-data about the loaded divisions.

=over

=item * C<cfdivisions.{library}_localpath[{division}]>

These variables contain the local path of a divisions directory within the library path.

=over

=item * C<cfdivisions.libdiv_localpath[commons]> has "/commons".

=item * C<cfdivisions.libdiv_localpath[webservers]> has "/webservers".

=item * C<cfdivisions.libdiv_localpath[webservers_www_mysite_com]> has "/webservers/www.mysite.com".

=back

=item * cfdivisions.{library}_path[{division}]

These variables contain the full path of a divisions directory in the file system.

=over

=item * C<cfdivisions.libdiv_path[commons]> has "/var/cfengine/inputs/divlib/commons".

=item * C<cfdivisions.libdiv_path[webservers]> has "/var/cfengine/inputs/divlib/webservers".

=item * C<cfdivisions.libdiv_path[webservers_www_mysite_com]> has "/var/cfengine/inputs/divlib/webservers/www.mysite.com".

=back

=back

=head1 See also

=over

=item The conceptual overview

L<'CFDivisions concept'|CFDivisions-concept> 

=item Content of a division promises file

L<'division-promises.cf'|division-promises.cf>

=item  The CFEngine module for CFDivisions

L<'cfdivisions'|cfdivisions>

=back

=head1 Project

L<CFDivisions on github.com|https://github.com/sascha-dibbern/CFDivisions/>

=head1 Authors 

L<Sascha Dibbern|http://sascha.dibbern.info/> (sascha@dibbern.info) 

=cut


1;
