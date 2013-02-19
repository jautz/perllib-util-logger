package Util::Logger;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.21';



=pod

=head1 NAME

Util::Logger - write messages to screen or file



=head1 SYNOPSIS

  use Util::Logger;

  # simple example using default options
  my $log = Util::Logger->new();
  $log->print('INFO',
              'You will see this as well as WARN, ERROR and FATAL messages');

  # let´s play with the log levels...
  my $log_less = Util::Logger->new({ loglevel => 'WARN' });
  $log_less->print('INFO', 'This message won´t be logged.');
  $log_less->print('WARN', 'This message will be logged.');
  $log_less->print('ERROR', 'This message will be logged.');

  # write log file and disable line wrapping that is mainly for screen display
  my $log_to_file = Util::Logger->new({ loglevel => 'ERROR',
                                        file => '/tmp/stuff.log',
                                        wrap => 0 });



=head1 DESCRIPTION

This class allows you to print messages to the screen or into a file. With each
call to the C<print> method you will (besides the actual message) pass a
category name. The categories have a certain order of severity and by adjusting
the log level you can easily control the verbosity of your program without
touching your code.

The log level categories in descending severity:

  FATAL
  ERROR
  WARN
  INFO
  MORE
  DEBUG

=head2 USAGE HINT

All methods of this class (except of the constructor C<new>) are meant to be
called on an instance only (see C<SYNOPSIS>). Do NOT call them as class methods.
Perl gives you the freedom to do so, but don´t blame me for the result; you have
been warned.

=cut

my %CATEGORIES = ( FATAL => 0,
                   ERROR => 1,
                   WARN  => 2,
                   INFO  => 3,
                   MORE  => 4,
                   DEBUG => 5 );

my $CATEGORIES_MAX_STRING_LENGTH = 5;

my @WARNINGS = ();

=pod

=head1 ATTRIBUTES

=over 4

=item ERR

methods that fail and therefore return undef will put an error message into this
variable which can be accessed via C<$instance->{ERR}>.

=back



=head1 METHODS

=over 4

=cut

################################################################################
################################################################################

my $priv_warn = sub {
  my $message = shift;
  if (defined $message) {
    push @WARNINGS, $message;
  }
};

################################################################################
################################################################################

=pod

=item new([<hashRef>])

Constructor. You can pass a hash refernece to customize the logger´s behaviour.
Supported hash keys:

=over 4

=item loglevel => <string>

Default: C<'INFO'>.
Only messages of this category or a more severe one will be printed.

=item file => <string>

Default: C<undef>.
If the given filename exists and is writable, messages will be appended.
Otherwise a new file is created at the given location. If that fails, messages
are printed to the screen.

=item wrap => <number>

Default: C<80>.
Defines the number of columns that can be printed into a line before a newline
character is inserted; this is useful when writing to the screen.
If set to 0 then lines won´t be wrapped at all, which is recommended for logging
to a file.

=item print_category => <boolean>

Default: C<1>.
Toggles printing of the category name in front of the actual message.

=item print_timestamp => <boolean>

Default: C<0>.
Toggles printing of a timestamp in front of the actual message, which is
recommended for logging to a file.

=item seperator => <string>

Default: C<' | '>.
Sets the string that is used to seperate a log enty´s components (timestamp,
category, message text) from each other.

=back

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;
  my $self = { ERR => '' };
  bless($self, $class);

  # set default configuration options
  $self->{loglevel} = 'INFO';
  $self->{file} = undef;
  $self->{wrap} = 80;
  $self->{print_category} = 1;
  $self->{print_timestamp} = 0;
  $self->{seperator} = ' | ';

  # check user defined configuration options
  my $config = shift;
  if (ref($config) eq 'HASH') {
    foreach my $key (keys %{$config}) {
      if (exists $self->{$key}) {
        my $value = $config->{$key};
        next unless (defined $value);

        if ($key eq 'loglevel') {
          $value = uc $value;             # capitalize the log level name
          $self->{$key} = $value if (exists $CATEGORIES{$value});

        } elsif ($key eq 'file') {
          if (-e $value  &&  -w $value) { # file already exists and is writable
            $self->{$key} = $value;
          } else {                        # try to create logfile
            if (open FH, ">$value") {
              close FH;
              $self->{$key} = $value;
            }
          }

        } elsif ($key eq 'wrap') {
          $self->{$key} = $value if ($value >= 0);

        # boolean options
        } elsif ($key eq 'print_category' ||
                 $key eq 'print_timestamp') {

          $self->{$key} = (defined($value) && $value != 0 ? 1 : 0);

        } elsif ($key eq 'seperator') {
          $self->{$key} = $value;
        }
      }
    }
  }

  return $self;
}

################################################################################

=pod

=item flushWarnings

Returns an array containing the warnings produced by methods of this class.
These warnings do not indicate that something is wrong with the program but
rather are informative messages that something happended that the user might
not have expected.
Thus, you're free to ignore these warnings but maybe you should keep an eye on
them while developing a program based on this logger.
The internal list of warnings will be erased (`flushed') after calling this
method.


=cut

sub flushWarnings {
  my $self = shift;
  my @warns = @WARNINGS;
  @WARNINGS = ();
  return @warns;
}

################################################################################

=pod

=item print(<string> category, <string> message)

Logs the C<message> if its C<category> is high enough for the current loglevel.
If not, the message will be discarded.
If the given C<category> is not valid, a warning will be issued and the current
loglevel will be used instead.
Newline characters in C<message> are not allowed and will be replaced by tabs.

Returns C<undef> if an error occured, C<true> otherwise.

=cut

sub print {
  my $self = shift;
  my $category = shift;
  my $message = shift;
  unless (defined $message) {
    $self->{ERR} = 'no message defined';
    return undef;
  }
  $category = $self->_getVerifiedCategoryName($category);

  # check whether current loglevel allows logging of this category´s messages
  if ($CATEGORIES{$self->{loglevel}}  >=  $CATEGORIES{$category}) {

    # check message argument
    $message =~ s/^\s+|\s+$//g; # trim leading and trailing whitespace
    unless (length $message > 0) {
      $self->{ERR} = 'cowardly refusing to write an empty log message';
      return undef;
    }
    if ($message =~ m/\n/) {
      $message =~ s/\n/\t/g;
      &$priv_warn('print: line breaks in log message replaced with tabs');
    }

    # format output string
    my $output = '';

    if ($self->{print_timestamp}) {
      $output .= $self->_getTimestamp().$self->{seperator};
    }

    if ($self->{print_category}) {
      $category = $self->_normalizeStringLength($category,
                                                $CATEGORIES_MAX_STRING_LENGTH);
      $output .= $category.$self->{seperator};
    }

    $output .= ($self->{wrap}
                ? $self->_getWrappedMessage($output, $message, $self->{wrap})
                : $message);
    $output .= "\n";

    if ($self->{file}  &&  open(HANDLE, '>>'.$self->{file})) { # write to file
      print HANDLE $output;
      close HANDLE;
    } else {                                                   # write to screen
      print $output;
    }

  }
  return 1;
}

################################################################################

sub _getWrappedMessage {
  my $self = shift;
  my $prefix = shift;
  my $message = shift;
  my $maxWidth = shift;

  return undef unless(defined $prefix && defined $message && defined $maxWidth);

  # decide formatting depending on the length of the given prefix:
  # - if the prefix is shorter than 40% of the available output width
  #   then put the message text into the same line and indent wrapped lines
  #   to the appropriate depth
  # - otherwise start writing the message in a new line indented by 4 blanks
  my ($firstchar, $linePrefix);
  if (length $prefix < $maxWidth * 0.4) {
    # continue writing into this line ...
    # ... and indent following lines up to the current position
    $firstchar = '';
    $linePrefix = '';
    $linePrefix .= ' ' while (length($linePrefix) < length($prefix));
  } else {
    # start writing into a new line and indent with 4 blanks
    $linePrefix = "    ";
    $firstchar = "\n".$linePrefix;
  }

  # reformat message
  my @words = split / /, $message;
  my @lines = ();
  my $line = $linePrefix;
  while (defined (my $word = shift @words)) {
    if (length($line) + length($word) <= $maxWidth) {
      $line .= $word.' ';

    } elsif ($line eq $linePrefix) {
      # nothing written into this line up to now, override max width
      $line .= $word.' ';

    } else {
      chop $line; # remove last whitespace
      push @lines, $line;
      $line = $linePrefix.$word.' ';
    }
  }
  # return result
  if (@lines > 0) {
    push(@lines, $line);
    $line = join("\n", @lines);
  }
  $line =~ s/^\s+//; # remove leading whitespace
  return $firstchar.$line;
}

################################################################################

sub _getVerifiedCategoryName {
  my $self = shift;
  my $category = shift;

  if (defined $category) {
    unless (exists $CATEGORIES{$category}) {
      # try harder by ignoring case
      my $match = 0;
      foreach (keys %CATEGORIES) {
        if (m/^\s*$category/i) {
          $category = $_;
          $match = 1;
          last;
        }
      }
      if ($match) {
        &$priv_warn("print: using category $category; UPPERCASE preferred");
      } else {
        &$priv_warn("print: category $category unknown, ".
                    "using default one: $self->{category}");
        $category = $self->{category}
      }
    }
  } else {
    $category = $self->{loglevel};
    &$priv_warn("print: category undefined, using default one: $category");
  }

  return $category;
}

################################################################################

sub _normalizeStringLength {
  my $self = shift;
  my $str = shift;
  my $len = shift;

  return undef unless (defined $str);
  return $str unless (defined $len);

  unless (length $str == $len) {
    if (length $str < $len) {
      $str .= ' ' while (length $str < $len);
    } else {
      $str = substr $str, 0, $len;
    }
  }
  return $str;
}

################################################################################
# _getTimestamp([<number> time])
#
# Creates a string representation of a time (in seconds since 1970-01-01)
# that is ISO conform and looks like this: `2004-03-12 16:07:02'.
# The time is adapted to the local time zone by means of the Perl built-in
# localtime command.
# If the optional time argument is omitted the current time is used.
#
# Returns a string.

sub _getTimestamp {
  my $time = shift;
  $time = time unless ($time);

  my @t = localtime($time);

  return sprintf("%d-%02d-%02d %02d:%02d:%02d",
                 (1900 + $t[5]), ++$t[4], $t[3], $t[2], $t[1], $t[0]);
}

################################################################################


1;

__END__

=pod

=back



=head1 TODO

- use existing namespace, e.g. Log::Dual Log::Levels

- add convenience methods like info($text) as shortcut for print('INFO', $text)

- add setLevel() for readjustment of logging level

- allow logging to screen _and_ file simultaneously

- dto. and allow different settings, loglevels etc.



=head1 AUTHOR

Joachim Jautz

http://www.jay-jay.net/contact.html



=head1 COPYRIGHT AND LICENCE

Copyright (c) 2004 Joachim Jautz.  All rights reserved.  This program
is free software; you can redistribute it and/or modify it under the terms
of the Artistic License, distributed with Perl.

=cut
