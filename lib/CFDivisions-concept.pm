# POD placeholder for 'CFDivisions-concept'

# PODNAME: CFDivisions-concept
# ABSTRACT: Enable modularized CFEngine script configuration

=head1 NAME

CFDivisions-concept : why using division based modularization of CFEngine code

=head1 DESCRIPTION

CFDivisions enables the usage of CFengine promises in libraries based in a modular and goal intention based structure.
It is an inversion of control framework to design effective and maintainable Cfengine code.

=head1 Strategy and principles

CFDivisions based code supports an approach towards a 'divide and conquere'-strategy by using following principles: 

=over

=item 1. a top-down design (division)

CFDivisions based design helps dividing the goal intentions and functional responsibilities into configuration architectural layers. Theses layers are build of modules called divisions. Divisions can dependend to each other. In this way a formal releationship between sets of goals are established. 
An example of the architectural layering of division and the goals defined inside the divisions could look like

=over

=item Layer: the application

=over 

=item * Division: website-frontend

Goals: to define website specific configurations

=item * Division: website-monitoring

Goals: to define logging and monitoring of the website

=item * Divison: website-databackend

Goals: to define the website specific database configuration and datasetup

=back

=item Layer: the supporting services

=over

=item * Division : NFS-service

=over

=item * Goals: configure the filesystem-services (e.q NFS)

=item * Goals: configure usage of specific filesystem-services (client-side)

=back

=item * Division : Web-server

Goals: configure the foundations of the webserver 

=item * Division : Database-server 

Goals: configure the foundations of database-server

=back

=item Layer: OS-specific support for services

=item ...

=back

Ascending to the top layer the division promisses resemble the final goals. Top goals and their promises can only be fullfilled, if fullfillment of lower goals have been reached.
Stratifying and grouping these levels of promises is the essence of what the design of divisions is about.

A good design would in effect have clear vertical dependencies where the Cfengine code becomes more coherent and maintainable.

=item 2. a buttom-up runtime behaviour (conquere)

Code execution follows the given configurations architecture, by configuring the lowest layered artefacts first and then ascending layer by layer upward through the divisions. 
Executing in this way the program flow in Cfengine closely follows the architectural layering og the final product to be configured, thereby making it easier to understand the cause and effect when debugging the Cfengine scripts.
Also this will lead to a shortended and more efficient execution time of reaching a maximum of fullfilled promisses. The reasons for this to happend are:  

=over

=item * the amount of iterative reexecutions of promises are reduced, because the goals you depend on have been processed beforehand

=item * the amount of cf-agent reexecutions is reduced 

=back

=back

=head1 Elements in CFDivisions

B<CFDivisions> introduces some new concepts to the organization and structure of CFEngine code and functionality.

=head2 Division

A B<division> is a selfcontaining component with capabilities as: 

=over

=item Runtime encapsulation 

Divisions encapsulate their runtime behaviour by defining their own local bundlesequence to control execution their own bundles. The division based bundlesequence will in execution time be palced in an optimal place to the global bundlesequence.

=item Declarative dependencies

Divisions can depend on other divisions within the same library. CFengine code structured as divisions enables the building of configurations in a layered design represented a dependency graph. Promises of higher layered divisions logically will therefore build upon the promises of lower layered divisions. 

=item Configuration containment

Divisions can use their own namespace (or library / defined default namespace) to scope structural classes and variables. A division can contain, manage, address and its own resources like

=over 

=item datafiles defined with division's directory in the filesystem 

=item refering to classes, agent bundles and variable in it's own namespace

=back

=head2 Division promises file

A division promises file (L<division-promises.cf>) defines the promises within a division.

=head2 Division library

A division library is a collection of one or more divisions. If no library is specified the default is 'division'.

=head2 Division nesting

Divisions (container-divisions) can have nested divisions. There are no restriction on defining the role of a nested division as either

=over

=item * being sub-division supporting subgoals to the container-division or

=item * being superdivisions that require the container-division to take a sub-division role

=back

Nesting is just a structural tool to enhance encapsulation and separation of concerns.

=head2 Division names

Division names are based on the L<canonized|"division-properties.cf/Canonization"> filesystem paths to the directories containing the division-promises-file. 

=head2 Naming of division artefacts

Variables and classes that are generated under parsing of the division definitions contain 

=over

=item * the library name

The name is given as an argument to C<cfdivisions> and is used as a scope identifier

=item * the division name

To specify the context for the given division of the given variable content.

=back

=head1 Motivation

One can take the analogy of seeing bundles as subroutines or procedures in other programming languages. A division can in other programming languages seen as packages, components or other alike modular structures.
The standard way of parsing promises files and executing non-division-controlled bundles in CFEngine is straight forward procedural from a programming point of view. The developer has one main bundlesequence, and bundles are calling other bundles (using the C<methode> section). This create very rigid procedural structure of code design, which easily leads to monolithic top-down executions structures, that are hard to maintain and test (like injections mockup promises).
Also the goal supporting concept is promises is disturbed when executing bundles in hardcoded and not goal based sequence, that not always match the optimal or a human memorable sequence to create a given configuration.
Under CFDvisions the purpose of bundle becomes more that of a definition of a goal than just being a container of promises, that execute around one ore more goals.
An observation when developing divisions is that the bundles tend to become smaller (covering 3-5 sections). On the other hand the amount of bundles increases, but their sequence is easily maintained locally in the bundlesequence of the C<division-promises.cf> file rather than in a global bundlesequence or obfuscating C<method> section calls distributed around like C<GOTO> statements.

Another claim is also that it is harder to reuse non-divisioned CFEngine-code as distributeable packages/libraries, so that others can implement new CFEngine solutions. B<cfdivision> distributes the role of the central bundlesequence out into B<divisions> with local bundlesequence, and thereby moves control to where the component developers mind is focused. 

=head1 Tips and recommendations

Using B<cfdivisions> can be a first step in structuring complex CFengine configuration scripts. With cfdivisions some aspects from object orientation and componentbased programming could be implementet and enhance the code reuse and maintainabillity.

=head2 Naming convention of bundles in divisions

For better readabillity and easier maintenance of bundles defined in C<division-promises.cf> files, it is a good idea to prepend the bundle names with the canonized name of its containing division.

Example: Bundle C<content> organized under division C</webservers/www.mysite.com> (canonized name C<webservers_www_mysite_com>) could be named instead to C<webservers_www_mysite_com_content>.

But also the usage of CFEngine namespace can be used to geta better degree of local context of division functionality.

=head2 Resources in divisions (data artefacts)

It can be an good idea to place resources (template text files, ...) into the same division folder with the promises that are using them. The divisions path (library path + local path or the division's full path) can be used identify the path to the resources.

=head2 Failsafe mechanism (NOT IMPLEMENTED FUTURE FEATURE)

Divisions can technically be build with failsafe promises that could be called from C<failsafe.cf>. By creating special C<division-failsafe.cf> files in the divisions and refering to the from central C<failsafe.cf> file.

B<!!! BEWARE: A failsafe implementation / adjustment needs thorough testing before being put into production !!!>

B<Example> Adjusted C<failsafe.cf>:

  bundle common import_divisions
  {
 
    classes:
      !imported_division::
        "imported_divisions" 
          expression => usemodule (
            "cfdivisions",
            "--library=divlib --promises=division-failsafe.cf"
          );

    reports:
      imported_division::
         "cfdivisions.failback_inputs: $(cfdivisions.failback_inputs)";
         "cfdivisions.failback_bundlesequence: $(cfdivisions.failback_bundlesequence)";
  }

  ...

  body common control
  {
    inputs => {
               ...
               @(cfdivisions.failback_inputs),
              };

    bundlesequence => { 
                       ...
                       @(cfdivisions.failback_bundlesequence),
                      }; 
  }

=head1 See also

=over

=item Examples

L<'CFDivisions-example'|CFDivisions-example> 

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
