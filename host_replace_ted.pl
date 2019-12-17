#!/usr/bin/perl 

# Copyright (c) 2019, Juniper Networks, Inc
# All rights reserved
# This SOFTWARE is licensed under the LICENSE provided in the
# ./LICENCE file. By downloading, installing, copying, or otherwise
# using the SOFTWARE, you agree to be bound by the terms of that
# LICENSE.

use strict;
use warnings;
use autodie;


my %dict;
while ( <STDIN> ) {
  my ($k, $v) = (split)[0,1];
  $dict{$k} = $v;
}

my @newjson;
my $a;
my $b;

open my $fh, '<', $ARGV[0];
while ( <$fh> ) {
    if ($_ =~ m/{\"name\":\".*database_protocol/) {
        my @chunks = split '"', $_;
        $a = $chunks[3];
        if($chunks[3] = $dict{$chunks[3]}) {
            $b = $chunks[3];
            $b = uc $b;
            $_ =~ s/{\"name\":\"$a\"/{\"name\":\"$b\"/g;
        }
    } elsif ($_ =~ m/{\"name\":\".*<->/) {
        my @chunks = split '"', $_;
        my @chunks2 = split '\(', $chunks[3];
        my @chunks3 = split '>', $chunks2[1];
        $a = $chunks2[0];
        if($chunks2[0] = $dict{$chunks2[0]}) {
            $b = $chunks2[0];
            $b = uc $b;
            $_ =~ s/{\"name\":\"$a/{\"name\":\"$b/g;
        }
        $a = $chunks3[1];
        if($chunks3[1] = $dict{$chunks3[1]}) {
            $b = $chunks3[1];
            $b = uc $b;
            $_ =~ s/>$a\(/>$b\(/g;
        }
    } elsif ($_ =~ m/{\"to\":\"/) {
        my @chunks = split '"', $_;
        $a = $chunks[3];
        if($chunks[3] = $dict{$chunks[3]}) {
            $b = $chunks[3];
            $b = uc $b;
            $_ =~ s/{\"to\":\"$a\"/{\"to\":\"$b\"/g;
        }
    }
    push (@newjson,$_);
}

open $fh, '>', $ARGV[0];
print $fh @newjson;
close $fh;

