#!/usr/bin/perl

# Copy Templates from V::C::Plugin::FormFields to the current directory

use warnings;
use strict;

package MyVal;
{
  $MyVal::VERSION = '0.0.7';
} use Validation::Class; __PACKAGE__->load_plugins('FormFields');

package main ;
{
  $main::VERSION = '0.0.7';
}

use File::Copy;

# copy templates to the cwd

my  $class = MyVal->new;

    foreach my $type (keys %{ $class->field_templates }) {
        
        my  $target = $ARGV[0];
            $target =~ s/\/$//g if $target;
            $target ||= ".";
        
        my  @tofrom = (
            $class->field_template($type),
            "$target/" . $class->field_templates->{$type}
        );
        
        print join "\n", "copying ... ", $tofrom[0], "to ... ", $tofrom[1], "\n";
        copy @tofrom;
        
    }

1;