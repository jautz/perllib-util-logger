use 5.006000;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'Util::Logger',
    VERSION_FROM      => 'lib/Util/Logger.pm', # finds $VERSION
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/Util/Logger.pm', # retrieve abstract from module
       AUTHOR         => 'Joachim Jautz <http://www.jay-jay.net/contact.html>') : ()),
);
