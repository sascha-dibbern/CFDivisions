# CFDivisions

# DESCRIPTION

CFDivisions enables the usage of CFengine promises in libraries based in a modular and goal intention based structure.
Programming configuration management based on divisions follows a declarative approach of a 'divide and conquere'-strategy, where dependencies are clearly defined.

# DISTRIBUTION

CFDivision can be installed to the CFEngine hub-server(s)
 1.  as a binary package (a rpm-file generated by Dist::Zilla) 
 2.  or by unpacking a .tar.gz file and using Perls traditional Makefile.PL approach

After installing on the CFEngine hubserver, it will reside in the CFEngines modules directory.
Further distribution to CFEngine managed nodes is done by CFEngines own module distribution mechanisms.

# BUILD REQUIREMENTS

Installation of Perl-packages 
  * Dist::Zilla
  * Dist::Zilla::Plugin::Git
  * Dist::Zilla::Plugin::RPM
  * Dist::Zilla::Plugin::CopyFilesFromBuild
  * Test::Exception
  * Test::More

Other requirements:
  * the tool 'rpmbuild'
  * an valid rpmbuild-directory setup

# Build, release and deploy as rpm with Dist::Zilla

## Build base-package

With Dist::Zilla the build of the binary base-packages

    > dzil build

## Test build-artefacts

Testing the artefacts before distribution can be done by writing

    > dzil test

## Releasing the rpm and code-changes

    > dzil release

When releasing it will

 1. tag the local git repository
 2. push git commits to origin repository
 3. generate automatically a rpm (CFDivisions-<version>.noarch.rpm )for distribution / installation under the rpmbuild-destination (~/rpmbuild/RPMS/noarch/)

## Deployment of the rpm-file

On the CFEngine hubserver the rpm can be install either by the rpm-tool

    > rpm -i CFDivisions-<version>.noarch.rpm

or by yum, when the rpm is placed in accessible your repository

    > yum install CFDivisions

# Build and deploy by traditional Makefile.PL approach

When using this method it is important to direct installation towards CFEngines modules directory (/var/cfengine/modules)

## Building the binary package (.tar.gz)

    > perl Makefile.PL
    > make test
    > make

## Install the binary package

Unpack the .tar.gz file an install the module in CFEngines modules destination 

    > export CFMODULES=${CFMODULES:-'/var/cfengine/modules'}
    > export PERL_MM_OPT="INSTALLDIRS=site INSTALLSITEARCH=${INSTALLSITEARCH:-'${CFMODULES}/lib64/perl5'} INSTALLSITEBIN=${INSTALLSITEBIN:-'${CFMODULES}/bin'} INSTALLSITELIB=${INSTALLSITELIB:-'${CFMODULES}/perl5'} INSTALLSITEMAN1DIR=${INSTALLSITEMAN1DIR:-'/usr/local/share/man/man1'} INSTALLSITEMAN3DIR=${INSTALLSITEMAN3DIR:-'/usr/local/share/man/man3'} INSTALLSITESCRIPT=${INSTALLSITESCRIPT:-'${CFMODULES}'}"
    > perl Makefile.PL
    > make test
    > make install

# SEE ALSO

Unix man-pages are generated or perldoc-pages in source code can be browsed about following themes 

  * CFDivisions-concept : The conceptual overview and introduction to CFDivisions
  * CFDivisions-example : An example of using CFDivisions
  * cfdivisions : The CFEngine module for CFDivisions
  * cfdivisionsdoc : Generating perldoc-files and man-pages from division-promises-files 
  * division-promises.cf : Content of a division promises file

## CFDivisions libraries and examples
  * [dibbern_info_divisions](https://github.com/sascha-dibbern/common_divisions) : A collection og generic reusable code to build configuration stacks
  * [dibbern_info_divisions](https://github.com/sascha-dibbern/dibbern_info_divisions) : An example CFDivisions library build upon *common_divisions*

# LICENSE

See LICENSE file.

# AUTHORS

 *  Sascha Dibbern [http://sascha.dibbern.info/](http://sascha.dibbern.info/)
    (email: sascha at dibbern.info)

