package Text::FixedWidth;

use warnings;
use strict;
use Carp;
use vars ('$AUTOLOAD');
use Storable ();

=head1 NAME

Text::FixedWidth - Easy OO manipulation of fixed width text files

=cut

our $VERSION = '0.08_01';

=head1 SYNOPSIS

   use Text::FixedWidth;

   my $fw = new Text::FixedWidth;
   $fw->set_attributes(qw(
      fname            undef  %10s
      lname            undef  %-10s
      points           0      %04d
   ));

   $fw->parse(string => '       JayHannah    0003');
   $fw->get_fname;               # Jay
   $fw->get_lname;               # Hannah
   $fw->get_points;              # 0003

   $fw->set_fname('Chuck');
   $fw->set_lname('Norris');
   $fw->set_points(17);
   $fw->string;                  # '     ChuckNorris    0017'

If you're familiar with printf formats, then this class should make processing
fixed width files trivial.
Just define your attributes and then you can get_* and set_* all day long. When
you're happy w/ your values envoke string() to spit out your object in your
defined fixed width format.

When reading a fixed width file, simply pass each line of the file into parse(), and
then you can use the get_ methods to retrieve the value of whatever attributes you
care about.

=head1 METHODS

=head2 new

Constructor. Does nothing fancy.

=cut

sub new {
   my ($caller,%args) = (@_);

   my $caller_is_obj = ref($caller);
   my $class = $caller_is_obj || $caller;
   my $self = bless {}, ref($class) || $class;
   return $self;
}


=head2 set_attributes

Pass in arguments in sets of 3 and we'll set up attributes for you.

The first argument is the attribute name. The second argument is the default
value we should use until told otherwise. The third is the printf format we should
use to read and write this attribute from/to a string.

  $fw->set_attributes(qw(
    fname            undef  %10s
    lname            undef  %-10s
    points           0      %04d
  );

=cut

sub set_attributes {
   my ($self, @att) = @_;

   my $order_by = 1;
   unless (@att % 3 == 0) { die "set_attributes() requires sets of 3 parameters"; }
   while (@att) {
      my ($att, $value, $sprintf) = splice @att, 0, 3;
      if (exists $self->{_attributes}{$att}) {
         die "You already set attribute name '$att'! You can't set it again! All your attribute names must be unique";
      }
      if ($value eq "undef") { $value = undef; }
      $order_by++;
      $self->{_attributes}{$att}{sprintf} = $sprintf;
      $self->{_attributes}{$att}{value}   = $value;
      my ($length) = ($sprintf =~ /(\d+)/g);
      $self->{_attributes}{$att}{length}  = $length;
      push @{$self->{_attribute_order}}, $att;
   }

   return 1;
}


=head2 parse

Parses the string you hand in. Sets each attribute to the value it finds in the string.

  $fw->parse(string => '       JayHannah    0003');

=cut

sub parse {
   my ($self, %args) = @_;

   die ref($self).":Please provide a string argument" if (!$args{string});
   my $string = $args{string};

   $self = $self->clone if $args{clone};

   my $offset = 0;
   foreach (@{$self->{_attribute_order}}) {
      my $length = $self->{_attributes}{$_}{length};
      $self->{_attributes}{$_}{value}  = substr $string, $offset, $length;
      $offset += $length;
   }

   return $args{clone}? $self : 1;
}


=head2 string

Dump the object to a string. Walks each attribute in order and outputs each in the
format that was specified during set_attributes().

  print $fw->string;      #  '     ChuckNorris    0017'

=cut

sub string {
   my ($self) = @_;

   my ($value, $length, $sprintf, $return);
   foreach my $att (@{$self->{_attribute_order}}) {
      $value   = $self->{_attributes}{$att}{value};
      $length  = $self->{_attributes}{$att}{length};
      $sprintf = $self->{_attributes}{$att}{sprintf};

      if (defined ($value) and length($value) > $length) {
         warn "string() error! " . ref($self) . " length of attribute '$att' cannot exceed '$length', but it does. Please shorten the value '$value'";
         return 0;
      }
      if (not defined $value) {
         $value = '';
      }
      unless ($sprintf) {
         warn "string() error! " . ref($self) . " sprintf not set on attribute $att. Using '%s'";
         $sprintf = '%s';
      }

      my $tmp;
      if (
         $sprintf =~ /\%\d*[duoxefgXEGbB]/ && (       # perldoc -f sprintf
            (not defined $value) ||
            $value eq "" ||
            $value !~ /^(\d+\.?\d*|\.\d+)$/        # match valid number
         )
      ) {
         $value = '' if (not defined $value);
         warn "string() warning: " . ref($self) . " attribute '$att' contains '$value' which is not numeric, yet the sprintf '$sprintf' appears to be numeric. Using 0";
         $value = 0;
      }
      $tmp = sprintf($sprintf, (defined $value ? $value : ""));

      if (length($tmp) != $length) {
         die "string() error: " . ref($self) . " is loaded with an sprintf format which returns a string that is NOT the correct length! Please correct the class! The error occured on attribute '$att' converting value '$value' via sprintf '$sprintf', which is '$tmp', which is not '$length' characters long";
      }

      $return .= $tmp;
   }

   return $return;
}


=head2 auto_truncate

Text::FixedWidth can automatically truncate long values for you. Use this method to tell your $fw
object which attributes should behave this way.

  $fw->auto_truncate("fname", "lname");

(The default behavior if you pass in a value that is too long is to carp out a warning,
ignore your set(), and return undef.)

=cut

sub auto_truncate {
   my ($self, @attrs) = @_;
   $self->{_auto_truncate} = {};
   foreach my $attr (@attrs) {
      unless ($self->{_attributes}{$attr}) {
         carp "Can't auto_truncate attribute '$attr' because that attribute does not exist";
         next;
      }
      $self->{_auto_truncate}->{$attr} = 1;
   }
   return 1;
}

=head2 clone

Provides a clone of a Text::FixedWidth object. If available it will attempt
to use L<Clone::Fast> or L<Clone::More> falling back on L<Storable/dclone>.

   my $fw_copy = $fw->clone;

This method is most useful when being called from with in the L</parse> method.

   while( my $row = $fw->parse( clone => 1, string => $str ) ) {
      print $row->foobar;
   }

See L</parse> for further information.

=cut

sub clone {
   my $self = shift;
   return Storable::dclone($self);
}




sub DESTROY { }

# Using Damian methodology so I don't need to require Moose.
#    Object Oriented Perl (1st edition)
#    Damian Conway
#    Release date  15 Aug 1999
#    Publisher   Manning Publications
sub AUTOLOAD {
  no strict "refs";
  if ($AUTOLOAD =~ /.*::get_(\w+)/) {
    my $att = $1;
    *{$AUTOLOAD} = sub {
      croak "Can't get_$att(). No such attribute: $att" unless (defined $_[0]->{_attributes}{$att});
      my $ret = $_[0]->{_attributes}{$att}{value};
      $ret =~ s/\s+$// if $ret;
      $ret =~ s/^\s+// if $ret;
      return $ret;
    };
    return &{$AUTOLOAD};
  }

  if ($AUTOLOAD =~ /.*::set_(\w+)/) {
    my $att  = $1;
    *{$AUTOLOAD} = sub {
      my $self = $_[0];
      my $val  = $_[1];
      croak "Can't set_$att(). No such attribute: $att" unless (defined $self->{_attributes}{$att});
      if (defined $self->{_attributes}{$att}) {
        if (defined $val && length($val) > $self->{_attributes}{$att}{length}) {
          if ($self->{_auto_truncate}{$att}) {
            $val = substr($val, 0, $self->{_attributes}{$att}{length});
            $self->{_attributes}{$att}{value} = $val;
          } else {
            carp "Can't set_$att('$val'). Value must be " .
              $self->{_attributes}{$att}{length} . " characters or shorter";
            return undef;
          }
        }
        $self->{_attributes}{$att}{value} = $val;
        return 1;
      } else {
        return 0;
      }
    };
    return &{$AUTOLOAD};
  }

  confess ref($_[0]).":No such method: $AUTOLOAD";
}


=head1 ALTERNATIVES

Other modules that may do similar things:
L<Parse::FixedLength>,
L<Text::FixedLength>,
L<Data::FixedFormat>,
L<AnyData::Format::Fixed>

=head1 AUTHOR

Jay Hannah, C<< <jay at jays.net> >>, http://jays.net

=head1 BUGS

Please report any bugs or feature requests to C<bug-text-fixedwidth at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Text-FixedWidth>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Text::FixedWidth

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Text-FixedWidth>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Text-FixedWidth>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Text-FixedWidth>

=item * Search CPAN

L<http://search.cpan.org/dist/Text-FixedWidth>

=item * Source code

L<http://github.com/jhannah/text-fixedwidth>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2008-2010 Jay Hannah, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of Text::FixedWidth
