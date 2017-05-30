# POD placeholder for 'CFDivisions-concept'

# PODNAME: CFDivisions-concept
# ABSTRACT: Enable modularized CFEngine script configuration

=head1 NAME

CFDivisions-concept : why using division based modularization of CFEngine code

=head1 DESCRIPTION

The CFDivisions execution framework enables the usage of CFengine promises in libraries based in a modular and goal intention structure.
It is an inversion of control framework to design effective and maintainable Cfengine code, where the CFEngine code leans up an code-design model that follows the dependencies of configuration artefacts.

=head1 Strategy and principles

CFDivisions based code supports an approach towards a 'divide and conquere'-strategy by using following principles: 

=over

=item 1. a top-down design (division)

CFDivisions based design helps dividing the goal intentions and functional responsibilities into configuration architectural layers. Theses layers are build of modules called divisions. Divisions can dependend on each other (but circular dependencies are prohibited). Designing the CFEngine code in this way a formal and functional releationship between sets of goals are established. 

An example of the architectural layering of division and the goals defined inside the divisions could look like

=over

=item Layer: B<the application>

=over 

=item * Division: website-frontend

Goals: to define website specific configurations

=item * Division: website-monitoring

Goals: to define logging and monitoring of the website

=item * Divison: website-databackend

Goals: to define the website specific database configuration and datasetup

=back

=item Layer: B<the supporting services>

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

=item Layer: B<OS-specific support for services>

=item ...

=back

Ascending to the top layer the division promisses resemble the final goals. These top goals (their promises) can only be fullfilled, if fullfillment of lower goals and promises have been reached.
Stratifying and grouping these levels of promises (or the cluster of) is the essence of what the design of divisions is about.

A good design would in effect have clear vertical dependencies where the Cfengine code becomes more coherent and maintainable.

=item 2. a buttom-up runtime behaviour (conquere)

Code execution follows the given configurations architecture, by executing the division configuration in a buttom-up approach ie. the lowest layered artefacts first and then ascending layer by layer upwards through the divisions. 
Executing in this way the program flow in Cfengine closely follows the architectural layering og the final product to be configured, thereby making it easier to understand the cause and effect when debugging the Cfengine scripts.
Also this will lead to a shortended (optimal) and more efficient execution time of reaching a maximum of fullfilled promisses. The reasons for this to happend are:  

=over

=item * the amount of iterative reexecutions of promises are reduced, because the goals you depend on have been processed beforehand

=item * failures of vital promises happen as soon as possible in the execution sequence.

=back

=back

=head1 Elements in CFDivisions

B<CFDivisions> introduces some new concepts to the organization and structure of CFEngine code and functionality.

=head2 Division

A B<division> is a selfcontaining component. Technically it is a promises file with a certain placement within the division library. A division supports following capabilities as: 

=over

=item Runtime encapsulation 

Divisions encapsulate their runtime behaviour by defining their own local bundlesequence to control execution their own bundles. The division based bundlesequence will finally in execution time be placed in an optimal place to the global bundlesequence.

=item Declarative dependencies

Divisions can depend on other divisions. CFengine code structured as divisions enables the building of configurations in a layered design. This layered design derives naturally by the divisions dependency graph. Promises of higher layered divisions logically best perform when building build upon the promises of lower layered divisions. 

=item Configuration containment

Divisions can use their own namespace (or library / defined default namespace) to scope structural classes and variables. A division can also contain, manage, address and its own resources like

=over 

=item datafiles defined with division's directory in the filesystem 

=item refering to classes, agent bundles and variable in it's own namespace

=back

This supports the principles of encapsulation and better separation of concerns.

=head2 Division promises file

A division promises file (L<division-promises.cf>) defines the promises within a division. CFDivision specific tags inside a division promises file provide metadata that supports the intended execution. 

=head2 Division names

Division names are based on the L<canonized|"division-properties.cf/Canonization"> filesystem paths to the directories containing the division-promises-file. 

=head2 Division library

A division library is a collection of one or more divisions. If no library is specified the default is 'division'. The canonized name of a library is assumed to be the default namespace for al it's division-artefacts (bundles,...).

=head2 Division nesting

Divisions (container-divisions) can have nested divisions. There are no restriction on defining the role of the nested divisions as either

=over

=item * being sub-divisions supporting subgoals to the container-division or

=item * being superdivisions that require the container-division to take a sub-division role

=back

Nesting is just a structural tool to enhance encapsulation and separation of concerns.

Nested divisions names (in canonized form) are just extended names of container-division.

=head2 Naming of division artefacts

Sctrucural variables and classes are generated under parsing of the division definitions. These artefacts contain 

=over

=item * the library name

The name is given as an argument to C<cfdivisions> and is used as a scope identifier

=item * the division name

To specify the context for the given division of the given variable content.

=back

=head1 CFengine execution phases

To supply the functionality of CFDivisions it's structural elementss are processed before or at the same time CFengine executes "body common control". 

This fact enables CFDivisions to control major parts of the CFengines execution order:

=over

=item Phase 1: execution of common bundles ('bootstrapping')

Since C<common bundles> are executed first and in the order how promises files are parsed by CFengine (cf-agent,cf-server,...). The CFDivisions-provided order will naturally be respected. C<Common bundles> will therefore be executed in a sequence that is derived of the division dependency sequence. 

Remember the the order of execution of B<common bundles> within af promises file though is defined by the sequence they have been written in the file.

=item Phase 2: other bundles 

=over 

=item agent bundles

Each division provides it's own local bundlesequence. All these local bundlesequences are aggregated into, what becomes the global bundlesequence. The order in which this aggregation is done, is logically derived from the dependency-structure of the divisions.

=item server and monitor bundles

These bundles behave equally to the C<common bundles>. 

=back

=back

=head1 Motivation

One can take the analogy of seeing bundles as subroutines or procedures in other programming languages. A division can in other programming languagesbe seen as packages, components or other alike modular structures.
The standard way of parsing promises files and executing non-division-controlled bundles in CFEngine is straightforward procedural from a programming point of view. The developer has one main bundlesequence, and bundles can call other bundles (using the C<methode> section). This way of execution creates very rigid procedural structure of code design, which easily leads to monolithic top-down executions structures, that are hard to maintain and test (like injections mockup promises). Everything is functionally hardwired and it is hard to separate the aspects of execution.
Also the goal supporting concept of promises is disturbed when executing bundles in hardcoded procedural and not goal based sequence. Procedural bundle execution sequences will not guarantee to match an optimal execution order. As a consequence cf-agent needs to be run multiple times before a maximum of fullfilled promises reached. This is not bug of CFengine, but a consequence of the heuristical part of the CFengine language. CFDivisions bring architecural alignment into CFengine. This minimizes theoretically the amount cf-agent reexecutions to reach the maximum of fullfilled promises. 

Under CFDvisions the purpose of bundle becomes more that of a definition of a goal than just being a container of promises, that execute around one ore more goals.
An observation when developing divisions is that the bundles tend to become smaller (covering 3-5 promises-type-sections). On the other hand the amount of bundles increases, but their sequence is easily maintained locally in the bundlesequence of the C<division-promises.cf> file rather than in a global bundlesequence or obfuscating C<method> section calls distributed around like infamous C<GOTO> statements in programming languages like Basic.

Another claim is also that it is harder to reuse non-divisioned CFEngine-code as distributeable packages/libraries, so that others can implement new CFEngine solutions. B<cfdivision> distributes the role of the central bundlesequence out into B<divisions> with local bundlesequence, and thereby moves control to where the component developers mind is focused. 

=head1 Tips and recommendations

Using B<cfdivisions> can be a first step in structuring complex CFengine configuration scripts in an easy way. With cfdivisions some aspects from object orientation and componentbased programming could be implementet and enhance the code reuse and maintainabillity.

=head2 Naming recommendations of bundles in divisions

For better readabillity and easier maintenance of bundles defined in C<division-promises.cf> files, it is a good idea to prepend the bundle names with the canonized name of its containing division.

Example: Bundle C<content> defined under division C</webservers/www.mysite.com> (canonized name C<webservers_www_mysite_com>) could be named instead to C<webservers_www_mysite_com_content>.

But also CFEngine namespace can be used to get a better degree of local context of division functionality.

Example: Bundle C<content> defined under division C</webservers/www.mysite.com> in library C<webhosting>. This division could have a canonized name C<webhosting_webservers_www_mysite_com>) so the bundle now can be referenced by C<webhosting_webservers_www_mysite_com:content>.

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
