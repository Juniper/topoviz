#! /usr/bin/perl
# Version 1.2
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
# This script requires 'show isis database extensive | display xml | no-more'
# as input, and creates a json file that lists the nodes and links and their
# connectivity. This file is then parsed by d3 to display the graph
#

use strict;
use List::MoreUtils qw(first_index none indexes);
my $thisline;
my $level;
my $lsp_id;
my @lspid;
my %lspidseen;
my $router_id;
my $rid;
my $advrouter;
my $l1advrouter;
my $l2advrouter;
my %advrouterseen;
my %advrouterstrseen;
my @l1only;
my @l1list;
my @l2list;
my @l1l2list;
my @l1loopbacks;
my %l1loopseen;
my @l1loopidx;
my @templ1l2list;
my $l2eql1l2;
my @l2eql1l2;
my @l2eql1l2_diffhost;
my @l2loopbacks;
my %l2loopseen;
my @l2loopidx;
my $l1l2subnet;
my $l1l2metric;
my $l1l2advrouter;
my $metric;
my $l1metric;
my $l2metric;
my $linkid;
my @node;
my $nodestr;
my @nodestr;
my $links;
my @links;
my @tmp_subnet;
my $subnet;
my $l1subnet;
my $l2subnet;
my @subnet;
my @subnetstr;
my $subnetstr;
my @combostr;
my $routeridx;
my $linkididx;
my $id;
my $nodes_id;
my %subnetseen;
my %nodeseen;
my %linkseen;
my $neighborflag;
my $subnetflag;
my @reachability;
my @tmp_reachability;
my $peer_lsp_id;
my $ip_metric;
my $my_ip;
my $peer_ip;
my $isisheader;
my $prefixstatus;
my $new_level;
my $tlvflag;
my $loop_index;
my $loop_index2;
my $rtrname;
my $idx;
my $loopback;
my @reachidx;
my @l1subnetidx;
my @l2subnetidx;
my @l1subnets_noloopbacks;
my @l2subnets_noloopbacks;
my @l1adjidx;
my @l2adjidx;
my $area_flag;
my $area_address;
my $xml;
my @peer_lsp_id;
my %peerlspseen;
my @sorted_peerlspids;
my $sorted_peerlspids;
my @l1loops;
my @l1subs;
my %l1subseen;
my @l2loops;
my @localips;
my %myipseen;
my @sorted_l1loops;
my @sorted_l2loops;
my @sorted_localips;
my @sorted_l1subs;
my @sorted_l2subs;
my %l2subseen;
my @l2subs;
my $loop_index3;
my $updown;
my $l1updown;
my $debug = 0;

# read in the isis db
# maybe should move away from this simple model to an actual xml parser??

while(<STDIN>) {
    $thisline = $_;
    if($thisline =~ '<rpc-reply xmlns') {
        $xml = 1;
    } elsif($thisline =~ '<isis-database>') {
        # start of level
        $new_level = 1;
    } elsif($thisline =~ '<level>([1-2])' && $new_level eq 1){
        # using this check as <level> appears in multiple places
        $level = $1;
    } elsif($thisline =~ '<isis-database-entry>') {
        # new node
        # reset these flags to be safe
        $new_level = 0;
        $subnetflag = 0;
        $neighborflag = 0;
        $isisheader = 0;
        $tlvflag = 0;
    } elsif($thisline =~ '<isis-header>') {
        # set this flag to indicate we are looking at isis-packet and later lines
        $isisheader = 1;
    } elsif($thisline =~ '<lsp-id>([a-zA-Z0-9\.\:\-\_]+)' && $isisheader eq 1) {
        $lsp_id = $1;
        #push(@lspid, "$lsp_id") if ! $lspidseen {"$lsp_id $level"}++;
    } elsif($thisline =~ '<router-id>([0-9\.]+)' && $isisheader eq 1) {
        # only found in 1st fragment
        $rid = $1;
    } elsif($thisline =~ '</isis-header>' && $isisheader eq 1) {
        $isisheader = 0;
    } elsif($thisline =~ '<isis-tlv heading="  TLVs:">') {
        $tlvflag = 1;
    } elsif($thisline =~ '<area-address-tlv>' && $tlvflag eq 1) {
        $area_flag = 1;
    } elsif($thisline =~ '<address>([0-9a-f\.]+)' && $area_flag eq 1) {
        $area_address = $1;
    } elsif($thisline =~ '</area-address-tlv>' && $tlvflag eq 1) {
        $area_flag = 0;
    } elsif($thisline =~ '<hostname>([a-zA-Z0-9\.\:\-\_]+)' && $tlvflag eq 1) {
        $advrouter = $1;
        push(@node, "$advrouter,$rid") if ! $advrouterseen {"$advrouter"}++;
        push(@nodestr, "{\"name\":\"$advrouter\",\"group\":20,\"area_address\":\"$area_address\"") if ! $advrouterstrseen {"$advrouter"}++;
        # not closing the tlv flag here, as its a wrapper for the following sub-sections
    } elsif($thisline =~ '<reachability-tlv heading="IS extended neighbor:"' && $tlvflag eq 1 ) {
        $neighborflag = 1;
        # this section only lists details of its adjacencies
        # has lsp-id, local and far end IP's, (no mask though)
        # also <admin-group-name> which could be useful
    } elsif($thisline =~ '<address-prefix>([a-zA-Z0-9\.\:\-\_]+)' && $neighborflag eq 1) {
        $peer_lsp_id = $1;
        #$peer_lsp_id =~ s/\.[0-9a-f][0-9a-f]$//;   # strip off the fragment id
    } elsif($thisline =~ '<metric>([0-9]+)' && $neighborflag eq 1) {
        $ip_metric = $1;
    } elsif($thisline =~ '<address>([0-9\.]+)' && $neighborflag eq 1) {
        $my_ip = $1;
    } elsif($thisline =~ '<neighbor-prefix>([0-9\.]+)' && $neighborflag eq 1) {
        $peer_ip = $1;
# not using for now
#     } elsif($thisline =~ '<admin-group-name>([A-Za-z0-9\,\.\?\/\-\=\_\+\~\!\@\#\$\%\^\&\*\(\)]+)' && neighborflag eq 1) {
#         $admin_group = $1;
     } elsif($thisline =~ '</reachability-tlv>' && $neighborflag eq 1) {
        push(@tmp_reachability, "$level,$my_ip,$peer_lsp_id,$peer_ip,$ip_metric");
        undef $peer_lsp_id;
        undef $ip_metric;
        undef $my_ip;
        undef $peer_ip;

        $neighborflag = 0;
    } elsif ($thisline =~ '<ip-prefix-tlv' && $tlvflag eq 1) {
        $subnetflag = 1;
    } elsif ($thisline =~ '<address-prefix>([0-9\.]+/[0-9]+)' && $subnetflag eq 1) {
        $subnet = $1;
    } elsif ($thisline =~ '<metric>([0-9]+)' && $subnetflag eq 1) {
        $metric = $1;
    } elsif ($thisline =~ '<prefix-status>([a-z]+)' && $subnetflag eq 1) {
        $updown = $1;
    } elsif ($thisline =~ '</ip-prefix-tlv>' && $subnetflag eq 1) {
        if ($subnet =~ '/32' && $metric != 0) {
            $subnetflag eq 0;
        } else {
            if ($ARGV[0] ne 'no_subnets') {
                push(@tmp_subnet, "$subnet,$level,$metric,$updown");
            }
            $subnetflag eq 0;
        }
    } elsif ($thisline =~ '<ipv6-reachability-tlv' && $tlvflag eq 1) {
        $subnetflag = 1;
    } elsif ($thisline =~ '<ipv6-address>([0-9\.a-f\:]+/[0-9]+)' && $subnetflag eq 1) {
        $subnet = $1;
    } elsif ($thisline =~ '<metric>([0-9]+)' && $subnetflag eq 1) {
        $metric = $1;
    } elsif ($thisline =~ '<prefix-downflag>([a-z]+)' && $subnetflag eq 1) { # need to verify what this looks like
        $updown = $1;
    } elsif ($thisline =~ '</ipv6-reachability-tlv>' && $subnetflag eq 1 && $ARGV[0] =~ 'show_v6' ) {
        if ($subnet =~ '/128' && $metric != 0) {
            $subnetflag eq 0;
        } else {
            push(@tmp_subnet, "$subnet,$level,$metric,$updown");
            $subnetflag eq 0;
        }
    } elsif ($thisline =~ '</isis-database-entry>') {
        foreach (@tmp_subnet) {
            $subnet = ( split( /,/, $_ ) )[ 0 ];
            $level = ( split( /,/, $_ ) )[ 1 ];
            $metric = ( split( /,/, $_ ) )[ 2 ];
            $updown = ( split( /,/, $_ ) )[ 3 ];
            push(@subnet, "$subnet,$level,$metric,$advrouter,$updown") if ! $subnetseen {"$subnet $level $advrouter"}++;
        }
        undef @tmp_subnet;
        undef $subnet;
        undef $metric;
        undef $updown;
        foreach (@tmp_reachability) {
            $level = ( split( /,/, $_ ) )[ 0 ];
            $my_ip = ( split( /,/, $_ ) )[ 1 ];
            $peer_lsp_id = ( split( /,/, $_ ) )[ 2 ];
            $peer_ip = ( split( /,/, $_ ) )[ 3 ];
            $ip_metric = ( split( /,/, $_ ) )[ 4 ];
            if ($advrouter ne $peer_lsp_id) {
                push(@reachability, "$advrouter,$level,$my_ip,$peer_lsp_id,$peer_ip,$ip_metric") if ! $lspidseen {"$advrouter $level $my_ip $peer_lsp_id $peer_ip $ip_metric"}++;
            }
        }
        undef @tmp_reachability;
        undef $my_ip;
        undef $peer_lsp_id;
        undef $peer_ip;
        undef $ip_metric;
    }
}
exit 254 if ! $xml;

if ( $debug eq 1) {

    print "#### node  -  node  rid ####\n";
    foreach (@node) {
        print "$_\n";
    }
    print "\n\n\n\n";
    print "#### subnet -  subnet  level  metric  advrouter  prefixstatus ####\n";
    foreach (@subnet) {
        print "$_\n";
    }
    print "\n\n\n\n";
    print "#### reachability - level  my_ip  peer_lsp_id  peer_ip  ip_metric ###\n";
    foreach (@reachability) {
        print "$_\n";
    }
    print "\n\n\n\n";

}

###################################
# start of subnet data collection #
###################################

# walk the @subnet array and create two arrays, one for L1 subnets, one for L2 subnets

# this catches v4 and v6
@l1list = indexes { /\/[0-9]+,1,/ } @subnet;
@l2list = indexes { /\/[0-9]+,2,/ } @subnet;


if ( $debug eq 1) {

    print "@l1list\n\n\n";
    print "@l2list\n\n\n";

}

$id = 0;
$nodes_id = 0;

# get the list of L1 subnet indexes in the @subnet array

foreach (@l1list) {

    # grab the info from this index in the @subnet array

    $l1subnet = ( split( /,/, @subnet[$_] ) )[ 0 ];
    $l1metric = ( split( /,/, @subnet[$_] ) )[ 2 ];
    $l1advrouter = ( split( /,/, @subnet[$_] ) )[ 3 ];
    $l1updown = ( split( /,/, @subnet[$_] ) )[ 4 ];

    # clear ths array before we begin each loop
    undef @templ1l2list;

    # dont worry about /32's for drawing nodes/links

    if ("$l1subnet" !~ '/32' && "$l1subnet" !~ '/128' && "$l1subnet" !~ "^::/") {

        # this array is just for printing subnets to the infobar
        # only do this if down bit not set

        if ($l1updown ne "down") {
            push(@l1subnets_noloopbacks, "$l1subnet,$l1advrouter");
        }

        # get the list of L2 indexes in the @subnet array

        foreach (@l2list) {

            # grab the info from this index in the @subnet array

            $l2subnet = ( split( /,/, @subnet[$_] ) )[ 0 ];
            $l2metric = ( split( /,/, @subnet[$_] ) )[ 2 ];
            $l2advrouter = ( split( /,/, @subnet[$_] ) )[ 3 ];

            # find out whether this subnet also has an L2 entry originated by this host

            if ( "$l1subnet" eq "$l2subnet" && "$l1advrouter" eq "$l2advrouter") {
                push(@templ1l2list, "$_,$l2metric");
                push(@l1l2list, "$_,$l2metric");
            }

        }

        # check if this is an L1/L2 subnet

        if ( @templ1l2list ) {

            # pull the L2 metric out

            $l2metric = ( split( /,/, @templ1l2list[0] ) ) [ 1];

            # add a new L1/L2 subnet
            # also create a link from this node to this subnet

            push(@subnetstr, "{\"name\":\"$l1subnet\",\"level\":\"1/2\",\"group\":13,\"id\":$nodes_id}") && $nodes_id++ if ! $nodeseen {"$l1subnet $l2subnet 1/2"}++;
            push(@links, "$l1advrouter,$rid,\"1/2\",$l1subnet,\"$l1metric/$l2metric\",$id") && $id++ if ! $linkseen {"$l1advrouter $l1subnet"}++;

        } else {

            # at this point we know there is no L2 subnet advertised by the same host.
            # we now need to put check for scenario where this router is configured for L1 only
            # and peer router is set to L1/L2 AND this router is before the peer router in the xml file order.
            # we can't print the subnet out at L1 only, because we'd end up with two nodes, one for L1 from
            # this node and a L1/L2 node from the peer router.

            # So, we must hold off creating the subnet node until all L2 and L1/L2 subnets are known,

            # Create a link from this node to this subnet, as long as down bit not set indicating it came from L2

            if ($l1updown ne "down") {

                push(@l1only, "\"$l1subnet\"");
                push(@links, "$l1advrouter,$rid,1,$l1subnet,$l1metric,$id") && $id++ if ! $linkseen {"$l1advrouter $l1subnet"}++;

            }

        }

    } else {

        #
        # L1 loopbacks, for these we want to present upon mouseover in the info panel
        #

        if ($l1updown ne "down") {
            push (@l1loopbacks, "$l1advrouter,$l1subnet") if ! $l1loopseen {"$l1advrouter $l1subnet"}++;
        }

    }

}


# get the list of L2 subnet indexes in the @subnet array

foreach (@l2list) {

    # grab the info from this index in the @subnet array

    $l2subnet = ( split( /,/, @subnet[$_] ) )[ 0 ];
    $l2metric = ( split( /,/, @subnet[$_] ) )[ 2 ];
    $l2advrouter = ( split( /,/, @subnet[$_] ) )[ 3 ];

    # clear these arrays before we begin each loop

    undef @l2eql1l2;
    undef @l2eql1l2_diffhost;

    # dont worry about /32's for drawing nodes/links

    if ("$l2subnet" !~ '/32' && "$l2subnet" !~ '/128' && "$l2subnet" !~ "^::/") {

        # this array is just for printing subnets to the infobar

        push(@l2subnets_noloopbacks, "$l2subnet,$l2advrouter");

        # get the list of L1/L2 indexes in the @subnet array

        foreach (@l1l2list) {

            # grab the info from this index in the @subnet array

            $l1l2subnet = ( split( /,/, @subnet[$_] ) )[ 0 ];
            $l1l2advrouter = ( split( /,/, @subnet[$_] ) )[ 3 ];

            # find out whether this subnet is already known as an L1/L2 subnet

            if ( "$l2subnet" eq "$l1l2subnet" && "$l2advrouter" eq "$l1l2advrouter") {
                push(@l2eql1l2, $_);
            } elsif ( "$l2subnet" eq "$l1l2subnet" ) {
                # this is for corner cases where other end is l1/l2 and ths end is l2 only
                push(@l2eql1l2_diffhost, $_);
            }
        }

        if ( @l2eql1l2_diffhost ) {

            # corner case where one end is L1/L2 and this end is L2 only
            # we don't add a subnet node in this case
            # must add a link from this host to the subnet

            push(@links, "$l2advrouter,$rid,2,$l2subnet,$l2metric,$id") && $id++ if ! $linkseen {"$l2advrouter $l2subnet"}++;

        } elsif ( ! @l2eql1l2 ) {

            # for non L1/L2 subnets (i.e. L2 only ) we add the new subnet and a link from this node to it

            push(@subnetstr, "{\"name\":\"$l2subnet\",\"level\":2,\"group\":12,\"id\":$nodes_id}") && $nodes_id++ if ! $nodeseen {"$l2subnet 2"}++;
            push(@links, "$l2advrouter,$rid,2,$l2subnet,$l2metric,$id") && $id++ if ! $linkseen {"$l2advrouter $l2subnet"}++;

        }

    } else {

        #
        # L2 loopbacks
        #

        push (@l2loopbacks, "$l2advrouter,$l2subnet") if ! $l2loopseen {"$l2advrouter $l2subnet"}++;

    }
}

# at this point we have added all the L2 only, and L1/L2 subnets to the array (if there were any)
# now for the L1 subnets

# first check if there are any L2 or L1/L2 subnets in the array
# If not just add the L1's
# if yes, double check that the L1 subnet isn't present in the array
# reason for this is that 'none' will return false for an empty list

if ( ! @subnetstr) {

    foreach(@l1only) {

        push(@subnetstr, "{\"name\":$_,\"level\":1,\"group\":11,\"id\":$nodes_id}") && $nodes_id++ if ! $nodeseen {"$_ 1"}++;

    }

} else {

    foreach(@l1only) {

        if ( none { /$_/ } @subnetstr ) {

            # L1 subnet string not found in list of L2 or L1/L2 subnet nodes

            push(@subnetstr, "{\"name\":$_,\"level\":1,\"group\":11,\"id\":$nodes_id}") && $nodes_id++ if ! $nodeseen {"$_ 1"}++;

        }

    }

}

#################################
# end of subnet data collection #
#################################

if ( $debug eq 1) {

    print "#### links advrouter rid level subnet metric ####\n";
    foreach (@links) {
        print "$_\n";
    }
    print "\n\n\n\n";

    print "#### l2 subnets ####\n";
    foreach (@l2subnets_noloopbacks) {
                print "$_\n";
    }
    print "\n\n\n\n";

}

sub _ip2bin {

    my $ip = shift;
    my $bin_ip = '';
    use constant IPV6IPV4HEAD => '0' x 80 . '1' x 16;

    if ($ip =~ /:/) {
        # IPv6 address

        return '0' x 128 if $ip eq '::';

        return '' if $ip =~ s/^:// && $ip !~ /^:/;
        return '' if $ip =~ s/:$// && $ip !~ /:$/;

        my @words = split(/:/, $ip, -1);
        my $words_amount = scalar @words;

        # IPv4 representation
        $words_amount++ if $ip =~ /\./;

        my $reduct = 0;
        my $i = 0;
        for my $word (@words) {
            $i++;
            if ($word =~ /\./) {
                # IPv4 representation
                return '' if $i != scalar @words || $bin_ip ne IPV6IPV4HEAD;
                my @octets = split(/\./, $word);
                return '' if scalar @octets != 4;
                for my $octet (@octets) {
                    return '' if $octet !~ /^\d+$/ || $octet > 255;
                    $bin_ip .= unpack('B8', pack('C', $octet));
                }
                return $bin_ip;
            } elsif (!length $word) {
                return '' if $reduct;
                $reduct = 1;
                my $len = (9 - $words_amount) << 4;
                return '' unless $len;
                $bin_ip .= '0' x ((9 - $words_amount) << 4);
            } elsif ($word =~ /^[0-9a-f]+$/i) {
                $word =~ s/^0+//i;
                return '' if length($word) > 4;
                my $int = hex($word);
                $bin_ip .= unpack('B16', pack('n', $int));
            } else {
                return '';
            }
            return '' if length($bin_ip) > 128;
        }
        return '' if length($bin_ip) < 128;
    } else {
        # IPV4
        my @octets = split(/\./, $ip, -1);
        return '' if scalar @octets > 4;
        for my $octet (@octets) {
            $bin_ip .= unpack('B8', pack('C', $octet));
        }
        return $bin_ip;
    }
}

sub _is_ip_in_subnet {
    my $ip = shift;
    my $subl1subnetidx_ref = shift;
    my $subl1subnets_noloopbacks_ref = shift;
    my $subl2subnetidx_ref = shift;
    my $subl2subnets_noloopbacks_ref = shift;
    my @subl1subnetidx = @{$subl1subnetidx_ref};
    my @subl1subnets_noloopbacks = @{$subl1subnets_noloopbacks_ref};
    my @subl2subnetidx = @{$subl2subnetidx_ref};
    my @subl2subnets_noloopbacks = @{$subl2subnets_noloopbacks_ref};
    my $l1retval;
    my $l2retval;
    my $bin_ip = _ip2bin($ip);
    if (@subl1subnetidx) {
 #       $l1retval = _match_addr_to_subnet($bin_ip, \@subl1subnetidx, \@subl1subnets_noloopbacks);
    }
    if (@subl2subnetidx) {
        $l2retval = _match_addr_to_subnet($bin_ip, \@subl2subnetidx, \@subl2subnets_noloopbacks);
    }
    if ( ($l1retval eq 'false') && (!(@subl2subnetidx)) ) {
        # no match, create link between routers
        return 'false';
    }
    if ( ($l1retval eq 'false') && ($l2retval eq 'false') ) {
        # no match, create link between routers
        return 'false';
    }
    if ( (!(@subl1subnetidx)) && ($l2retval eq 'false')  ) {
        # no match, create link between routers
        return 'false';
    }
    return 'true';
}

sub _match_addr_to_subnet {
    my $bin_ip1 = shift;
    my $subnetidx_ref = shift;
    my $subnets_noloopbacks_ref = shift;
    my @subnetidx = @{$subnetidx_ref};
    my @subnets_noloopbacks = @{$subnets_noloopbacks_ref};
    my $subloop_index = (scalar(@subnetidx)-1);
    until($subloop_index < 0) {
        my $subidx = $subnetidx[$subloop_index];
        my $subnet = ( split( /,/, $subnets_noloopbacks[$subidx] ) )[0];
        my $ip = ( split (/\//, $subnet )) [0];
        my $bin_ip2 = _ip2bin($ip);
        my $mask = ( split (/\//, $subnet )) [1];
        my $short_bin_ip1 = substr $bin_ip1, 0, $mask;
        my $short_bin_ip2 = substr $bin_ip2, 0, $mask;
        if ($short_bin_ip1 eq $short_bin_ip2) {
            return 'true';
        }
        $subloop_index --;
    }
    return 'false';
}

sub _create_r2r_link {
    my $subrtrname = shift;
    my $subrid = shift;
    my $subip = shift;
    my $subreachidx_ref = shift;
    my $subreachability_ref = shift;
    my @subreachidx = @{$subreachidx_ref};
    my @subreachability = @{$subreachability_ref};
    my $subloop_index = (scalar(@subreachidx)-1);
    until ($subloop_index < 0) {
        my $subidx = $subreachidx[$subloop_index];
        my $subadvrouter = ( split( /,/, $subreachability[$subidx] ) )[0];
        my $sublevel = ( split( /,/, $subreachability[$subidx] ) )[1];
        my $submyip = ( split( /,/, $subreachability[$subidx] ) )[2];
        my $subpeer_lsp_id = ( split( /,/, $subreachability[$subidx] ) )[3];
        $subpeer_lsp_id =~ s/\.[0-9a-f][0-9a-f]$//;
        my $submetric = ( split( /,/, $subreachability[$subidx] ) )[5];
    if ($subip eq $submyip) {
            push(@links, "$subrtrname,$subrid,$sublevel,$subpeer_lsp_id,$submetric,$id") && $id++ if ! $linkseen {"$subpeer_lsp_id $subrtrname"}++;
    }
    push(@links, "$subrtrname,$subrid,$sublevel,$subpeer_lsp_id,$submetric,$id") && $id++ if ! $linkseen {"$subpeer_lsp_id $subrtrname"}++;
        $subloop_index --;
    }
}

##########################
# start of json creation #
##########################

$nodestr = (scalar(@nodestr)-1);
if ($nodestr == -1) {
    print "{\n    \"nodes\":[\n    ],\n    \"links\":[\n    ]\n}\n";
    exit;
}

print "{\n    \"nodes\":[\n";

# first we print all subnet nodes, then router nodes
# this ensures that subnets sit behind router nodes in the z-axis
# svg layers nodes in the order its given
# this way the routers text labels never hide behind subnet nodes

foreach (@subnetstr) {
    print "        $_,\n"
}

for ($loop_index = 0; $loop_index <= $nodestr; $loop_index++) {

    $rtrname = ( split( /"/, $nodestr[$loop_index] ) )[3];
    $router_id = first_index { /$rtrname/ } @node;
    $rid = ( split( /,/, $node[$router_id] ) )[1];
    $area_address = ( split( /,/, $node[$router_id] ) )[2];
    @l1loopidx = indexes { /^$rtrname,/ } @l1loopbacks;
    @l2loopidx = indexes { /^$rtrname,/ } @l2loopbacks;
    @reachidx = indexes { /^$rtrname,/ } @reachability;
    @l1subnetidx = indexes { /,$rtrname$/ } @l1subnets_noloopbacks;
    @l2subnetidx = indexes { /,$rtrname$/ } @l2subnets_noloopbacks;
    @l1adjidx = indexes { /^$rtrname,1,/ } @reachability;
    @l2adjidx = indexes { /^$rtrname,2,/ } @reachability;

    print "        $nodestr[$loop_index],\"id\":$nodes_id,\"router_id\":\"$rid\",\n";
    print "            \"l1loopbacks\":[\n";

    if (@l1loopidx) {
        $loop_index2 = (scalar(@l1loopidx)-1);
        until ($loop_index2 < 0) {
            $idx = $l1loopidx[$loop_index2];
            $loopback = ( split( /,/, $l1loopbacks[$idx] ) )[1];
            push(@l1loops, "$loopback") if ! $l1loopseen {"$loopback $rtrname"}++;
            $loop_index2 --;
        }

        # sort

        @sorted_l1loops = sort @l1loops;
        $loop_index3 = (scalar(@sorted_l1loops)-1);
        while ($loop_index3 > 0) {
            print "                {\"address\":\"$sorted_l1loops[$loop_index3]\"},\n";
            $loop_index3 --;
        }
        print "                {\"address\":\"$sorted_l1loops[$loop_index3]\"}\n";

        # remove tmp arrays

        undef @sorted_l1loops;
        undef @l1loops;

    }

    print "            ],\n";
    print "            \"l2loopbacks\":[\n";

    if (@l2loopidx) {
        $loop_index2 = (scalar(@l2loopidx)-1);
        until ($loop_index2 < 0) {
            $idx = $l2loopidx[$loop_index2];
            $loopback = ( split( /,/, $l2loopbacks[$idx] ) )[1];
            push(@l2loops, "$loopback") if ! $l2loopseen {"$loopback $rtrname"}++;
            $loop_index2 --;
        }

        # sort

        @sorted_l2loops = sort @l2loops;
        $loop_index3 = (scalar(@sorted_l2loops)-1);
        while ($loop_index3 > 0) {
            print "                {\"address\":\"$sorted_l2loops[$loop_index3]\"},\n";
            $loop_index3 --;
        }
        print "                {\"address\":\"$sorted_l2loops[$loop_index3]\"}\n";

        # remove tmp arrays

        undef @sorted_l2loops;
        undef @l2loops;

    }

    print "            ],\n";
    print "            \"local_ips\":[\n";

    if (@reachidx) {
        $loop_index2 = (scalar(@reachidx)-1);
        until ($loop_index2 < 0) {
            $idx = $reachidx[$loop_index2];
            $my_ip = ( split( /,/, $reachability[$idx] ) )[2];
            if ($my_ip ne "") {
                push(@localips, "$my_ip") if ! $myipseen {"$my_ip $rtrname"}++;
            }
            $loop_index2 --;
        }

        # sort

        @sorted_localips = sort @localips;
        $loop_index3 = (scalar(@sorted_localips)-1);

    # in cases where there are no local ip's, see if there are adjacencies we can show
    if ( ! @sorted_localips ) {
        _create_r2r_link($rtrname,$rid,undef,\@reachidx,\@reachability);
    }

        while ($loop_index3 > 0) {
            if (( ! @l1subnetidx ) && ( ! @l2subnetidx)) {
                _create_r2r_link($rtrname,$rid,$sorted_localips[$loop_index3],\@reachidx,\@reachability);
            } else {
                my $retval = _is_ip_in_subnet($sorted_localips[$loop_index3],\@l1subnetidx,\@l1subnets_noloopbacks,\@l2subnetidx,\@l2subnets_noloopbacks);
                if ($retval eq 'false') {
                    _create_r2r_link($rtrname,$rid,$sorted_localips[$loop_index3],\@reachidx,\@reachability);
                }
            }
            print "                {\"address\":\"$sorted_localips[$loop_index3]\"},\n";
            $loop_index3 --;
        }

        if ($loop_index3 eq 0) {
            if (( ! @l1subnetidx ) && ( ! @l2subnetidx)) {
                _create_r2r_link($rtrname,$rid,$sorted_localips[$loop_index3],\@reachidx,\@reachability);
            } else {
                my $retval = _is_ip_in_subnet($sorted_localips[$loop_index3],\@l1subnetidx,\@l1subnets_noloopbacks,\@l2subnetidx,\@l2subnets_noloopbacks);
                if ($retval eq 'false') {
                    _create_r2r_link($rtrname,$rid,$sorted_localips[$loop_index3],\@reachidx,\@reachability);
                }
            }
            print "                {\"address\":\"$sorted_localips[$loop_index3]\"}\n";
        }
        # remove tmp arrays

        undef @sorted_localips;
        undef @localips;

    }

    print "            ],\n";
    print "            \"l1adjacencies\":[\n";

    if (@l1adjidx) {
        $loop_index2 = (scalar(@l1adjidx)-1);
        until ($loop_index2 < 0) {
            $idx = $l1adjidx[$loop_index2];
            $peer_lsp_id = ( split( /,/, $reachability[$idx] ) )[3];
            # strip off the fragment id
            $peer_lsp_id =~ s/\.[0-9a-f][0-9a-f]$//;
            # remove this router from adjacency list (in case of pseudonode id)
            if ($peer_lsp_id ne $rtrname) {
                push(@peer_lsp_id, "$peer_lsp_id") if ! $peerlspseen {"$peer_lsp_id $rtrname"}++;
            }
            $loop_index2 --;
        }

        # sort

        @sorted_peerlspids = sort @peer_lsp_id;
        $loop_index3 = (scalar(@sorted_peerlspids)-1);
        while ($loop_index3 > 0) {
            print "                {\"lsp_id\":\"$sorted_peerlspids[$loop_index3]\"},\n";
            $loop_index3 --;
        }
        print "                {\"lsp_id\":\"$sorted_peerlspids[$loop_index3]\"}\n";

        # remove tmp arrays

        undef @sorted_peerlspids;
        undef @peer_lsp_id;

    }

    print "            ],\n";
    print "            \"l2adjacencies\":[\n";

    if (@l2adjidx) {
        $loop_index2 = (scalar(@l2adjidx)-1);
        until ($loop_index2 < 0 ) {
            $idx = $l2adjidx[$loop_index2];
            $peer_lsp_id = ( split( /,/, $reachability[$idx] ) )[3];
            # strip off the fragment id
            $peer_lsp_id =~ s/\.[0-9a-f][0-9a-f]$//;
            # remove this router from adjacency list (in case of pseudonode id)
            if ($peer_lsp_id ne $rtrname) {
                push(@peer_lsp_id, "$peer_lsp_id") if ! $peerlspseen {"$peer_lsp_id $rtrname"}++;
            }
            $loop_index2 --;
         }

        # sort

        @sorted_peerlspids = sort @peer_lsp_id;
        $loop_index3 = (scalar(@sorted_peerlspids)-1);
        while ($loop_index3 > 0) {
            print "                {\"lsp_id\":\"$sorted_peerlspids[$loop_index3]\"},\n";
            $loop_index3 --;
        }
        print "                {\"lsp_id\":\"$sorted_peerlspids[$loop_index3]\"}\n";

        # remove tmp arrays

        undef @sorted_peerlspids;
        undef @peer_lsp_id;

    }

    print "            ],\n";
    print "            \"local_l1_subnets\":[\n";

    if (@l1subnetidx) {
        $loop_index2 = (scalar(@l1subnetidx)-1);
        until($loop_index2 < 0) {
            $idx = $l1subnetidx[$loop_index2];
            $l1subnet = ( split( /,/, $l1subnets_noloopbacks[$idx] ) )[0];
            push(@l1subs, "$l1subnet") if ! $l1subseen {"$l1subnet $rtrname"}++;
            $loop_index2 --;
        }

        # sort

        @sorted_l1subs = sort @l1subs;
        $loop_index3 = (scalar(@sorted_l1subs)-1);
        while ($loop_index3 > 0) {
            print "                {\"subnet\":\"$sorted_l1subs[$loop_index3]\"},\n";
            $loop_index3 --;
        }
        print "                {\"subnet\":\"$sorted_l1subs[$loop_index3]\"}\n";

        # remove tmp arrays

        undef @sorted_l1subs;
        undef @l1subs;

    }

    print "            ],\n";
    print "            \"local_l2_subnets\":[\n";

    if (@l2subnetidx) {
        $loop_index2 = (scalar(@l2subnetidx)-1);
        until ($loop_index2 < 0) {
            $idx = $l2subnetidx[$loop_index2];
            $l2subnet = ( split( /,/, $l2subnets_noloopbacks[$idx] ) )[0];
            push(@l2subs, "$l2subnet") if ! $l2subseen {"$l2subnet $rtrname"}++;
            $loop_index2 --;
        }

        # sort

        @sorted_l2subs = sort @l2subs;
        $loop_index3 = (scalar(@sorted_l2subs)-1);
        while ($loop_index3 > 0) {
            print "                {\"subnet\":\"$sorted_l2subs[$loop_index3]\"},\n";
            $loop_index3 --;
        }
        print "                {\"subnet\":\"$sorted_l2subs[$loop_index3]\"}\n";

        # remove tmp arrays

        undef @sorted_l2subs;
        undef @l2subs;

    }

    $nodes_id ++;

    if($loop_index < $nodestr) {
        print "            ]\n        },\n";
    } else {
        # json format requires last entry in array does not end with a ,
        print "            ]\n        }\n    ],\n    \"links\":[\n";
    }

}

#
# combine the @subnetstr and @nodestr arrays so we have one array index
#

@combostr = (@subnetstr, @nodestr);

#
# print the connections between all nodes
# for each entry in @links, split the entry into node,linkid
# find the matching index number in @combostr for the node
# find the matching index number in @combostr for the linkid
#

$links = (scalar(@links)-1);

for ($loop_index = 0; $loop_index <= $links; $loop_index++) {

    $advrouter = ( split( /,/, $links[$loop_index] ) )[ 0 ];
    $rid = ( split( /,/, $links[$loop_index] ) )[ 1 ];
    $level = ( split( /,/, $links[$loop_index] ) )[ 2 ];
    $linkid = ( split( /,/, $links[$loop_index] ) )[ 3 ];
    $metric = ( split( /,/, $links[$loop_index] ) )[ 4 ];
    $id = ( split( /,/, $links[$loop_index] ) )[ 5 ];

    $routeridx = ( first_index { /"$advrouter"/ } @combostr );
    $linkididx = ( first_index { /"$linkid"/ } @combostr );
    # defensive fix, sometimes links point to nodes that don't exist in db or nodes that have been timed out
    if($linkididx > -1) {
        if($loop_index > 0) {
            print ",\n";
        }
        print "        {\"source\":$routeridx,\"target\":$linkididx,\"level\":$level,\"metric\":$metric,\"id\":$id}";

    }

    if($loop_index == $links) {
        # json format requires last entry in array does not end with a ,
        print "\n    ]\n}\n";
    }

}

########################
# end of json creation #
########################
