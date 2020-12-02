#!/usr/bin/perl 
#
# Copyright (c) Juniper Networks, Inc., 2019-2020. All rights reserved.
#
# Notice and Disclaimer: This code is licensed to you under the MIT License
# (the "License"). You may not use this code except in compliance with the License.
# This code is not an official Juniper product.
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in the
# Software without restriction, including without limitation the rights to use,
# copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the
# Software, and to permit persons to whom the Software is furnished to do so,
# subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
# WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR
# IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#
# Third-Party Code: This code may depend on other components under separate
# copyright notice and license terms. Your use of the source code for those
# components is subject to the terms and conditions of the respective license
# as noted in the Third-Party source code file.
#

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

