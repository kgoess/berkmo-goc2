#use 5.018004;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'GoC',
    VERSION_FROM      => 'lib/GoC.pm', # finds $VERSION
    PREREQ_PM         => {
        JSON => 2.59,
        DBI  => 1.642,
        'Class::Accessor::Lite' => 0.08,
        'Data::Dump'  => 1.23,
        'DBD::SQLite' => 1.64,
    }, # e.g., Module::Name => 1.1
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/GoC.pm', # retrieve abstract from module
       AUTHOR         => 'Kevin M. Goess <kevin@sd.apple.com>') : ()),
);
