use strict;
use warnings;
use Test::More;
use Text::FixedWidth;

my $fw = Text::FixedWidth->new();

ok $fw->set_attributes(qw[ fname undef %10s ]), 'set_attributes() fname';
ok $fw->set_attributes(qw[ mi    undef %10s ]), 'set_attributes() mi';
ok $fw->set_attribute(
   name    => 'lname',
   default => undef,
   format  => '%10s',
),                                              'set_attribute() lname';
is $fw->getf_fname, '          ',               'getf_fname()';
is $fw->getf_mi,    '          ',               'getf_mi()';
is $fw->getf_lname, '          ',               'getf_lname()';

ok $fw->set_attribute(
   name    => 'text1',
   default => undef,
   format  => '%10s',
),                                              'set_attribute() text1';
is $fw->getf_text1, '          ',               'getf_text1()';


# Let's try a mathematical reader:
ok $fw->set_attribute(
   name    => 'points',
   reader  => sub { $_[0]->get_points + 1 },
   length  => 1,
),                                              'set_attribute() points w/ reader';
is $fw->get_points,    undef,                   'get_points()';
ok $fw->set_points(3),                          'set_points(3)';
is $fw->get_points,    3,                       'get_points()';
is $fw->getf_points,   4,                       'getf_points()';


# Now let's try a money format that doesn't want a period:
ok $fw->set_attribute(
   name    => 'points2',
   reader  => sub { sprintf("%07d", $_[0]->get_points2 * 100) },
   length  => 7,
),                                              'set_attribute() points2 w/ reader';
is $fw->get_points2,    undef,                  'get_points2()';
ok $fw->set_points2(13.2),                      'set_points2(13.2)';
is $fw->get_points2,    13.2,                   'get_points2()';
is $fw->getf_points2,   '0001320',              'getf_points2()';


done_testing();

