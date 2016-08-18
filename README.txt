CFDivisions

DESCRIPTION

CFDivision enables the usage of CFengine promises libraries within a component-framework, where promises and their depencencies can be structured more coherent. Programming configuration management based on divisions follows a declarative approach of a 'divide and conquere'-strategy, where dependencies are clearly defined.

DISTRIBUTION

CFDivision is intended to be distributed as a binary package (rpm) to the CFEngine hub-server(s). Further distribution to CFEngine managed nodes could/would be managed by CFEngines own module distribution mechanisms.

BUILD REQUIREMENTS

Installation of Perl-packages 
  * Dist::Zilla
  * Dist::Zilla::Plugin::Git
  * Dist::Zilla::Plugin::RPM
  * Test::Exception
  * Test::More

Other requirements:
  * the tool 'rpmbuild'
  * an valid rpmbuild-directory setup

BUILDING

Dist::Zilla does the building of the binary base-packages

> dzil build

TESTING

Testing the artefacts before distribution can be done by writing

> dzil test

RELEASING

When releasing by writing 

> dzil release

Thereby it will

 1. tag the local git repository
 2. push git commits to origin repository
 3. generate automatically a rpm for distribution / installation

AUTHORS
* Sascha Dibbern [sascha@dibbern.info] (http://sascha.dibbern.info/)
