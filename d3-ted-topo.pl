#! /usr/bin/perl
# Version 0.3
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
#
# This script takes the output of 'show ted database extensive | display xml | no-more'
# as input, and creates a json file that lists the nodes and links and their connectivity
# This json is then parsed by d3.js to display the graph
#

use strict;
use List::MoreUtils qw(first_index indexes none);
my $new_ted_entry;
my $new_link_entry;
my $id;
my $proto;
my $to;
my $local;
my $remote;
my $type;
my $local_ifindex;
my $admin_groups;
my $extended_admin_groups;
my $groups;
my $exagroups;
my $loop_index;
my $loop_index2;
my @nodestr;
my $nodestr;
my @agroups;
my @exagroups;
my $metric;
my $static_bw;
my @links;
my @links2;
my @links3;
my @linkidx;
my $linkstr;
my @linkstr;
my $link_count;
my $linkstr_count;
my $idx;
my @nodes;
my $node_count;
my $dst;
my $dst_index;
my $src;
my $src_index;
my %seen;
my $saddr;
my $daddr;
my $debug = 0;
my @inv;
my $node_id = 0;
my $link_id = 0;
my @subnets;
my @combo;
my $subnet_index;
my $linkstr1;
my $linkstr2;
my $strcombi;
my $net;
my $linkin;
my $subnetseen;
my %subnetseen;
my $nodeseen;
my %nodeseen;
my $linkseen;
my %linkseen;
my $xml;

# read from stdin, one line at a time, pull out relevant data and store

while(<STDIN>) {
    if($_ =~ '<rpc-reply xmlns') {
        $xml = 1;
    } elsif ($_ =~ '<ted-database junos:style') {
        $new_ted_entry = 1;
    } elsif ($_ =~ '<ted-database-id>([a-zA-Z0-9\-\.\_]+)' && $new_ted_entry) {
        $id = $1;
    } elsif ($_ =~ '<ted-database-type>Net<' && defined $new_ted_entry) {
        # ISIS & OSPF create a 'Net' TED entry for each broadcast network
        # only use this if the link-in count is > 0
        $net = 1;
    } elsif ($_ =~ 'ted-database-link-in>([0-9]+)') {
        $linkin = $1;
    } elsif ($_ =~ '<ted-database-protocol>([A-Z0-9\.\-\(\)]+)' && defined $new_ted_entry) {
        $proto = $1;
        if (defined $net && $linkin eq 0) {
            # no point creating this broadcast subnet node, as nothing links to it
            undef $net;
            undef $new_ted_entry;
        } elsif (defined $net) {
            # if it gets here is a broadcast network
            push (@subnets,"    {\"name\":\"$id\",\"group\":\"5\",\"id\":\"$node_id\"},") if ! $subnetseen {"$id"}++;
            $node_id++;
            undef $net;
            undef $new_ted_entry;
        } else {
            # if it gets here we are looking at a router node
            if ($id !~ m/[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+/) {
                # strip the fragment id off IS-IS, can't just match on proto.
                # reason being that in mixed OSPF/ISIS TED, have seen OSPF proto with ISIS id's
                $id =~ s/\.[0-9a-f]+$//;
            }
            $nodestr = "    {\"name\":\"$id\",\"database_protocol\":\"$proto\",\"group\":\"30\",";
            push(@nodes,"$id;$nodestr") if ! $nodeseen {"$id"}++;
        }
    } elsif ($_ =~ '<ted-link junos:style' && defined $new_ted_entry) {
        $new_link_entry = 1;
    } elsif ($_ =~ '<ted-link-to>([a-zA-Z0-9\-\.\_]+)' && defined $new_link_entry) {
        $to = $1;
    } elsif ($_ =~ '<ted-link-local-address>([0-9\.\:a-f]+)'  && defined $new_link_entry) {
        $local = $1;
    } elsif ($_ =~ '<ted-link-remote-address>([0-9\.\:a-f]+)' && defined $new_link_entry) {
        $remote = $1;
    } elsif ($_ =~ '<ted-link-local-ifindex>([0-9]+)' && defined $new_link_entry) {
        $local_ifindex = $1;
    } elsif ($_ =~ '<admin-groups heading'  && defined $new_link_entry) {
        $admin_groups = 1;
    } elsif ($_ =~ '<admin-group-name>([A-Za-z0-9\.]+)' && defined $admin_groups) {
        push(@agroups, $1)
    } elsif ($_ =~ '</admin-groups>' && defined $admin_groups) {
        undef $admin_groups;
    } elsif ($_ =~ '<ted-link-extended-admin-group heading'  && defined $new_link_entry) {
        $extended_admin_groups = 1;
    } elsif ($_ =~ '<admin-group-name>([A-Za-z0-9\.\-]+)' && defined $extended_admin_groups) {
        push(@exagroups, $1)
    } elsif ($_ =~ '</ted-link-extended-admin-group>' && defined $extended_admin_groups) {
        undef $extended_admin_groups;
    } elsif ($_ =~ '<ted-link-metric>([0-9]+)' && defined $new_link_entry) {
        $metric = $1;
    } elsif ($_ =~ '<ted-link-static-bandwidth>([0-9a-zA-Z\.]+)' && defined $new_link_entry) {
        $static_bw = $1;
    } elsif ($_ =~ '</ted-link>' && defined $new_link_entry) {
        undef $new_link_entry;

        if (@agroups) {
            $groups = (scalar(@agroups)-1);
            for ($loop_index = 0; $loop_index <= $groups; $loop_index++) {
                if($loop_index < $groups) {
                    $admin_groups = $admin_groups . "$agroups[$loop_index], ";
                } else {
                    $admin_groups = $admin_groups . "$agroups[$loop_index]";
                }
            }
            undef @agroups;
        }
        if (@exagroups) {
            $exagroups = (scalar(@exagroups)-1);
            for ($loop_index = 0; $loop_index <= $exagroups; $loop_index++) {
                if($loop_index < $exagroups) {
                    $extended_admin_groups = $extended_admin_groups . "$exagroups[$loop_index], ";
                } else {
                    $extended_admin_groups = $extended_admin_groups . "$exagroups[$loop_index]";
                }
            }
            undef @exagroups;
        }

        # split this into ISIS and OSPF sections
        if ($proto =~ m/IS-IS/) {
            if ($remote ne "0.0.0.0") {
                # is a P2P link, we can strip off fragment id now
                $to =~ s/\.[0-9a-f]+$//;
                push(@links2,"$id;$to;$local;$remote;$local_ifindex;$metric;$static_bw;$admin_groups;$extended_admin_groups")  if ! $subnetseen {"$id;$to;$local;$remote;$local_ifindex;$metric;$static_bw;$admin_groups;$extended_admin_groups"}++;
            } elsif ($remote eq "0.0.0.0" && $local_ifindex eq 0) {
                # passive link in IS-IS
                push(@links3,"$id;$to;$local;$metric;$static_bw")  if ! $subnetseen {"$id;$to;$local;$metric;$static_bw"}++;
            } elsif ($remote eq "0.0.0.0" && $local_ifindex ne 0) {
                # is a broadcast net
                push(@links3,"$id;$to;$local;$metric;$static_bw")  if ! $subnetseen {"$id;$to;$local;$metric;$static_bw"}++;
            }
         } elsif ($proto =~ m/OSPF/) {
            if ($to !=~ /[A-Za-z]/ && $to =~ /-/) {
                # is a broadcast net
                push(@links3,"$id;$to;$local;$metric;$static_bw")  if ! $subnetseen {"$id;$to;$local;$metric;$static_bw"}++;
            } else {
                # is a P2P link
                push(@links2,"$id;$to;$local;$remote;$local_ifindex;$metric;$static_bw;$admin_groups;$extended_admin_groups")  if ! $subnetseen {"$id;$to;$local;$remote;$local_ifindex;$metric;$static_bw;$admin_groups;$extended_admin_groups"}++;
            }
        }
        $linkstr = "            {\"to\":\"$to\",\"local_address\":\"$local\",\"remote_address\":\"$remote\",\"local_ifindex\":\"$local_ifindex\",\"link_metric\":\"$metric\",\"static_bw\":\"$static_bw\",\"admin_groups\":\"$admin_groups\",\"extended_admin_groups\":\"$extended_admin_groups\"}";

        push (@links,"$id;$linkstr") if ! $linkseen {"$id;$linkstr"}++;
        undef $linkstr;
        undef $admin_groups;
        undef $extended_admin_groups;
    } elsif ($_ =~ '</ted-database>' && $new_ted_entry) {
        undef $new_ted_entry;
    }
}

exit 254 if ! $xml;

if($debug eq 1) {
   print "#########\@nodes##########\n";
   foreach(@nodes) {
        print "$_\n";
    }
    print "#########\@links##########\n";
    foreach(@links) {
        print "$_\n";
    }
    print "#########\@links2##########\n";
    foreach(@links2) {
        print "$_\n";
    }
    print "#########\@links3##########\n";
    foreach(@links3) {
        print "$_\n";
    }
    print "#########\@subnets##########\n";
    foreach(@subnets) {
        print "$_\n";
    }
}

if (@links){
    # start JSON
    print "{\n  \"nodes\":[\n";
}

# whip the source data into usable forms...

# subnets are represented as circles. We dont know the netmask with TED only interface ip's
# interfaces must connect to unique subnets
# possibly check whether we see more than one peer per ifindex (for shared l2 segments) ** todo?
  # actually, not sure this is required

##################################
##          SUBNETS             ##
##################################

# first the passive interfaces (isis) or broadcast lans (ospf)
$link_count = (scalar(@links3)-1);
for ($loop_index = 0; $loop_index <= $link_count; $loop_index++) {
    $src = ( split( /;/, $links3[$loop_index] ) )[0];
    $daddr = ( split( /;/, $links3[$loop_index] ) )[1];
    $dst_index = first_index { /"$daddr"/ } @subnets;
    $saddr = ( split( /;/, $links3[$loop_index] ) )[2];
    $metric = ( split( /;/, $links3[$loop_index] ) )[3];
    $static_bw = ( split( /;/, $links3[$loop_index] ) )[4];
    $proto = ( split( /;/, $links3[$loop_index] ) )[5];

    if(defined $dst_index && $dst_index > -1) {
        push (@linkstr,"    {\"source\":;$src;,\"target\":$dst_index,\"source_address\":\"$saddr\",\"metric\":$metric,\"bw\":\"$static_bw\",\"id\":$link_id}");
        $link_id++;
        undef $dst_index;
    } else {
        push (@subnets,"    {\"name\":\"$src\($saddr\)->\($daddr\)\",\"group\":\"31\",\"id\":\"$node_id\"},");
        push (@linkstr,"    {\"source\":;$src;,\"target\":$node_id,\"source_address\":\"$saddr\",\"metric\":$metric,\"bw\":\"$static_bw\",\"id\":$link_id}");
        $link_id++;
        $node_id++;
    }
}
# get unique list of links
$link_count = (scalar(@links2)-1);
for ($loop_index = 0; $loop_index <= $link_count; $loop_index++) {
    $src = ( split( /;/, $links2[$loop_index] ) )[0];
    $src_index = first_index { /^$src/ } @nodes;
    $dst = ( split( /;/, $links2[$loop_index] ) )[1];
    $dst_index = first_index { /^$dst/ } @nodes;
    $saddr = ( split( /;/, $links2[$loop_index] ) )[2];
    $daddr = ( split( /;/, $links2[$loop_index] ) )[3];
    $metric = ( split( /;/, $links2[$loop_index] ) )[5];
    $static_bw = ( split( /;/, $links2[$loop_index] ) )[6];
    $admin_groups = ( split( /;/, $links2[$loop_index] ) )[7];
    $extended_admin_groups = ( split( /;/, $links2[$loop_index] ) )[8];

    if (@inv) {
        # array must exist or 'none' returns null
        if( none { /$dst_index $src_index $daddr $saddr/ } @inv) {
            push (@inv,"$src_index $dst_index $saddr $daddr");
            push (@subnets,"    {\"name\":\"$src\($saddr\)<->$dst\($daddr\)\",\"group\":\"31\",\"id\":\"$node_id\"},");
            push (@linkstr,"    {\"source\":;$src;,\"target\":$node_id,\"source_address\":\"$saddr\",\"target_address\":\"$daddr\",\"metric\":$metric,\"bw\":\"$static_bw\",\"admin_groups\":\"$admin_groups\",\"extended_admin_groups\":\"$extended_admin_groups\",\"id\":$link_id}");
            $link_id++;
            $node_id++;
        } else {
            $subnet_index = first_index { /$dst\($daddr\)<->$src\($saddr\)/ } @subnets;
            push (@linkstr,"    {\"source\":;$src;,\"target\":$subnet_index,\"source_address\":\"$saddr\",\"target_address\":\"$daddr\",\"metric\":$metric,\"bw\":\"$static_bw\",\"admin_groups\":\"$admin_groups\",\"extended_admin_groups\":\"$extended_admin_groups\",\"id\":$link_id}");
            $link_id++;
        }
    } else {
        push (@inv,"$src_index $dst_index $saddr $daddr");
        push (@subnets,"    {\"name\":\"$src($saddr)<->$dst($daddr)\",\"group\":\"31\",\"id\":\"$node_id\"},");
        push (@linkstr,"    {\"source\":;$src;,\"target\":$node_id,\"source_address\":\"$saddr\",\"target_address\":\"$daddr\",\"metric\":$metric,\"bw\":\"$static_bw\",\"admin_groups\":\"$admin_groups\",\"extended_admin_groups\":\"$extended_admin_groups\",\"id\":$link_id}");
        $link_id++;
        $node_id++;
    }
    undef $admin_groups;
    undef $extended_admin_groups;
}
undef @inv;

# print the subnets first so they are rendered via svg with lower z-axis (appear underneath evething else)
foreach(@subnets) {
    print "$_\n";
}

# loop through each node, printing its links
$node_count = (scalar(@nodes)-1);

for ($loop_index = 0; $loop_index <= $node_count; $loop_index++) {
    $id = ( split( /;/, $nodes[$loop_index] ) )[0];
    $nodestr = ( split( /;/, $nodes[$loop_index] ) )[1];
    print $nodestr;
    print "\"id\":\"$node_id\",\n        \"links\":[\n";
    $node_id++;
    @linkidx = indexes { /$id;/ } @links;
    $link_count = (scalar(@linkidx)-1);
    if($link_count == -1) {
        print "        ]\n";
    }
    for ($loop_index2 = 0; $loop_index2 <= $link_count; $loop_index2++) {
        $idx = $linkidx[$loop_index2];
        $linkstr = ( split( /;/, $links[$idx] ) )[1];
        print $linkstr;
        if($loop_index2 < $link_count) {
            print ",\n";
        } else {
            print "\n        ]\n";
        }
    }
    if($loop_index < $node_count) {
        print "    },\n";
    } else {
        print "    }\n";
    }
}


if(@links) {
    # all done with nodes, now for the links
    print "  ],\n  \"links\":[\n";
}

# combine the @subnet and @nodes to get one index

@combo = (@subnets, @nodes);


# print the list in JSON format

$linkstr_count = (scalar(@linkstr)-1);
for ($loop_index = 0; $loop_index <= $linkstr_count; $loop_index++) {
    if($loop_index < $linkstr_count) {
        $linkstr1 = ( split( /;/, $linkstr[$loop_index] ) )[0];
        $src = ( split( /;/, $linkstr[$loop_index] ) )[1];
        $linkstr2 = ( split( /;/, $linkstr[$loop_index] ) )[2];
        $src_index = first_index { /^$src/ } @combo;
        $strcombi = "$linkstr1$src_index$linkstr2";
        print "$strcombi,\n";
    } else {
        $linkstr1 = ( split( /;/, $linkstr[$loop_index] ) )[0];
        $src = ( split( /;/, $linkstr[$loop_index] ) )[1];
        $linkstr2 = ( split( /;/, $linkstr[$loop_index] ) )[2];
        $src_index = first_index { /^$src/ } @combo;
        $strcombi = "$linkstr1$src_index$linkstr2";
        print "$strcombi\n";
    }
}

if(@links){
    # close out the json
    print "  ]\n}\n";
}
