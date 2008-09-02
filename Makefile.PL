use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Text::FixedWidth',
    AUTHOR              => 'Jay Hannah <jay@jays.net>',
    VERSION_FROM        => 'lib/Text/FixedWidth.pm',
    ABSTRACT_FROM       => 'lib/Text/FixedWidth.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'Test::Warn' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Text-FixedWidth-*' },
);
