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

open my $fh, '<', $ARGV[0];
while ( <$fh> ) {
    if ($_ =~ m/name\":\"/) {
        my @chunks = split '"', $_;
        my $a = $chunks[3];
        if($chunks[3] = $dict{$chunks[3]}) {
            my $b = $chunks[3];
            $b = uc $b;
            $_ =~ s/name\":\"$a\"/name\":\"$b\"/g;
        }
    } elsif ($_ =~ m/neighbor\":\"/) {
        my @chunks = split '"', $_;
        my $a = $chunks[3];
        if($chunks[3] = $dict{$chunks[3]}) {
            my $b = $chunks[3];
            $b = uc $b;
            $_ =~ s/neighbor\":\"$a\"/neighbor\":\"$b\"/g;
        }
    }
    push (@newjson,$_);
}

open $fh, '>', $ARGV[0];
print $fh @newjson;
close $fh;

