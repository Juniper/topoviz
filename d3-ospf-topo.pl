#! /usr/bin/perl
# Version 0.1

# Copyright (c) 2019, Juniper Networks, Inc
# All rights reserved
# This SOFTWARE is licensed under the LICENSE provided in the
# ./LICENCE file. By downloading, installing, copying, or otherwise
# using the SOFTWARE, you agree to be bound by the terms of that
# LICENSE.

#
# This script takes the output of 'show ospf database router extensive | display xml | no-more'
# as input, and creates a json blob that lists the nodes and links and their connectivity
# This blob is then parsed by d3 to display the graph
#

use strict;
use List::MoreUtils qw(first_index indexes);
my $thisline;
my $advrouter;
my $metric;
my $linkdata;
my $linktype;
my $linkid;
my $area;
my @nodestr;
my $links;
my @links;
my $subnet;
my $subnetstr;
my $routeridx;
my $linkididx;
my $id;
my %subnetstrseen;
my %nodeseen;
my $area_header;
my $db;
my $link;
my $loop_index;
my $lsa_topo;
my $lsa_type_router;
my $neighbor;
my $router_lsa;
my @subnetstr;
my @combostr;
my $combostr;
my @neighbors;
my $nodestr;
my @neighboridx;
my $idx;
my $loop_index2;
my $loopback;
my @loopbacks;
my @loopbackidx;
my @p2pidx;
my $xml;
my $nottransit;
my @transits;
my @bcastidx;
my $tlink;
my @p2pidx;
my @point2points;
my $matchidx;
my $p2mp;
my @p2mpidx;
my $loopstr;
my $address;
my $p2p_subnet;
my @point2pointidx;
my @subnetidx;
my $local_address;
my $bcast_local_address;
my $dr_address;

while(<STDIN>) {
    $thisline = $_;
    if($thisline =~ '<rpc-reply xmlns') {
        $xml = 1;
    } elsif ($thisline =~ '<ospf-area-header>') {
        $area_header = 1;
    } elsif($thisline =~ '<ospf-area>([0-9\.]+)' && $area_header eq 1) {
        $area = $1;
    } elsif($thisline =~ '</ospf-area-header>') {
        $area_header = 0;
    } elsif($thisline =~ '<ospf-database[ >]') {
        $db = 1;
    } elsif($thisline =~ '<lsa-type>([A-Za-z]+)' && $db eq 1) {
        if ($1 eq 'Router') {
           $lsa_type_router = 1;
        }
    } elsif($thisline =~ '<advertising-router>([a-zA-Z0-9\.\:]+)' && $db eq 1 && $lsa_type_router eq 1) {
        $advrouter = $1;
    } elsif($thisline =~ '<ospf-router-lsa>' && $db eq 1 && $lsa_type_router eq 1) {
        $router_lsa = 1;
        $lsa_type_router = 0;
    } elsif ($thisline =~ '<bits>0x([0-9]+)' && $router_lsa eq 1) {

        #
        # Check which bits are set
        #

        if($1 eq '0') { # NON ABR and NON-ASBR
            push(@nodestr, "{\"name\":\"$advrouter\",\"group\":0") if ! $nodeseen {"$advrouter"}++;
        } elsif($1 eq '1') { # ABR router
            push(@nodestr, "{\"name\":\"$advrouter\",\"group\":1") if ! $nodeseen {"$advrouter"}++;
        } elsif($1 eq '2') { # ASBR router
            push(@nodestr, "{\"name\":\"$advrouter\",\"group\":2") if ! $nodeseen {"$advrouter"}++;
        } elsif($1 eq '3') { # ABR and ASBR router
            push(@nodestr, "{\"name\":\"$advrouter\",\"group\":3")  if ! $nodeseen {"$advrouter"}++;
        }

    } elsif ($thisline =~ '<ospf-link>' && $router_lsa eq 1) {
        $link = 1;
    } elsif ($thisline =~ '<link-id>([0-9a-fA-F\.\:]+)' && $link eq 1) {
        $linkid = $1;
    } elsif ($thisline =~ '<link-data>([0-9\.]+)' && $link eq 1) {
        $linkdata = $1;
    } elsif ($thisline =~ '<link-type-name>([a-zA-Z]+)' && $link eq 1) {
        $linktype = $1;
    } elsif ($thisline =~ '<metric>([0-9]+)' && $link eq 1) {
        $metric = $1;
    } elsif ($thisline =~ '</ospf-link>' && $link eq 1) {
        $link = 0;
        if ($linktype eq 'Stub') {
            if ($linkdata eq '255.255.255.255') {
                #
                # 2 reasons why this could be:
                # its a loopback address
                # its a p2mp interface local address
                # need to walk any PointToPoint <ospf-link> entries to determine if latter is true
                #
                push(@loopbacks, "$advrouter,$linkid");
            } elsif ($linkdata eq '255.255.255.254') {
                push(@subnetstr, "{\"name\":\"$linkid/31\",\"group\":4") if ! $subnetstrseen {"$linkid/31"}++;
                push(@links, "$advrouter,$linkid/31,$metric,$linktype");
            } elsif ($linkdata eq '255.255.255.252') {
                push(@subnetstr, "{\"name\":\"$linkid/30\",\"group\":4") if ! $subnetstrseen {"$linkid/30"}++;
                push(@links, "$advrouter,$linkid/30,$metric,$linktype");
            } elsif ($linkdata eq '255.255.255.248') {
                push(@subnetstr, "{\"name\":\"$linkid/29\",\"group\":4") if ! $subnetstrseen {"$linkid/29"}++;
                push(@links, "$advrouter,$linkid/29,$metric,$linktype");
            } elsif ($linkdata eq '255.255.255.240') {
                push(@subnetstr, "{\"name\":\"$linkid/28\",\"group\":4") if ! $subnetstrseen {"$linkid/28"}++;
                push(@links, "$advrouter,$linkid/28,$metric,$linktype");
            } elsif ($linkdata eq '255.255.255.224') {
                push(@subnetstr, "{\"name\":\"$linkid/27\",\"group\":4") if ! $subnetstrseen {"$linkid/27"}++;
                push(@links, "$advrouter,$linkid/27,$metric,$linktype");
            } elsif ($linkdata eq '255.255.255.192') {
                push(@subnetstr, "{\"name\":\"$linkid/26\",\"group\":4") if ! $subnetstrseen {"$linkid/26"}++;
                push(@links, "$advrouter,$linkid/26,$metric,$linktype");
            } elsif ($linkdata eq '255.255.255.128') {
                push(@subnetstr, "{\"name\":\"$linkid/25\",\"group\":4") if ! $subnetstrseen {"$linkid/25"}++;
                push(@links, "$advrouter,$linkid/25,$metric,$linktype");
            } elsif ($linkdata eq '255.255.255.0') {
                push(@subnetstr, "{\"name\":\"$linkid/24\",\"group\":4") if ! $subnetstrseen {"$linkid/24"}++;
                push(@links, "$advrouter,$linkid/24,$metric,$linktype");
            } else {
                push(@subnetstr, "{\"name\":\"$linkid/$linkdata\",\"group\":4") if ! $subnetstrseen {"$linkid/$linkdata"}++;
                push(@links, "$advrouter,$linkid/$linkdata,$metric,$linktype");
            }
        } elsif ($linktype eq 'Transit') {
            push(@subnetstr, "{\"name\":\"$linkid\",\"group\":5") if ! $subnetstrseen {"$linkid"}++;
            push(@links, "$advrouter,$linkid,$metric,$linktype,$linkdata");
        } elsif ($linktype eq 'PointToPoint') {
            push(@point2points, "$advrouter,$linkdata,$linkid,$metric");
        }
    } elsif ($thisline =~ '<ospf-lsa-topology>' && $router_lsa eq 1) {
        $lsa_topo = 1;
    } elsif ($thisline =~ '<link-type-name>([A-Za-z]+)' && $lsa_topo eq 1) {
        if ($1 ne 'Transit') {
           $nottransit = 1;
        }
    } elsif ($thisline =~ '<ospf-lsa-topology-link-node-id>([0-9a-fA-F\.\:]+)' && $nottransit eq 1) {
        $neighbor = $1;
        push(@neighbors, "$advrouter,$neighbor");
    } elsif ($thisline =~ '</ospf-lsa-topology-link>' && $nottransit eq 1) {
        $nottransit = 0;
    } elsif ($thisline =~ '</ospf-lsa-topology>' && $lsa_topo eq 1) {
        $lsa_topo = 0;
    } elsif ($thisline =~ '</ospf-router-lsa>' && $router_lsa eq 1) {
         $router_lsa = 0;
    } elsif ($thisline =~ '</ospf-database>' && $db eq 1) {
         $db = 0;
    }
}

exit 254 if ! $xml;

#
# To distinguish between a p2mp interface and a loopback
# must first determine if there is a corresponding Point2Point entry
#

$loopstr = (scalar(@loopbacks)-1);

for ($loop_index = 0; $loop_index <= $loopstr; $loop_index++) {

    $advrouter = ( split( /,/, $loopbacks[$loop_index] ) )[0];
    $address = ( split( /,/, $loopbacks[$loop_index] ) )[1];

    #
    # check if the <link-id> of this stub network advertisement matches
    # the <link-data> of any of the point2point advertisements from the same
    # neighbor
    #

    $matchidx = indexes { /$advrouter,$address,/ } @point2points;
    # assumption here is that there is only one of these... may need a defensive check?

    if (defined $matchidx) {

        #
        # found a matching point2point entry, therefore this is not a
        # loopback, but a p2mp interface address. remove this from @loopbacks
        # and add a p2mp subnet
        #

        $loopbacks[$loop_index] = undef;

        $linkdata = (split( /,/, $point2points[$matchidx] ) )[1]; # local p2mp interface address
        $linkid = (split( /,/, $point2points[$matchidx] ) )[2]; # remote loopback
        $metric = (split( /,/, $point2points[$matchidx] ) )[3];

        #
        # problem here is how to link other routers with this subnet node in
        # the graph... 1st attempt will be the view from this box
        #

        push(@subnetstr, "{\"name\":\"p2mp from $advrouter\",\"group\":6") if ! $subnetstrseen {"$linkdata"}++;
        push(@links, "$advrouter,p2mp from $advrouter,$metric,P2MP");
        push(@links, "$linkid,p2mp from $advrouter,$metric,P2MP");

    }

    undef $matchidx;

}

#
# begin to write the json
#

print "{\n  \"nodes\":[\n";

#
# have to print out the subnets first,
# routers must be rendered on top of subnets in the svg
# so their text labels are not obscured
#

$id=0;
$subnetstr = (scalar(@subnetstr)-1);

for ($loop_index = 0; $loop_index <= $subnetstr; $loop_index++) {

    print "    $subnetstr[$loop_index],\"id\":$id},\n";
    $id++

}

#
# subnets done, now for the routers
#

$nodestr = (scalar(@nodestr)-1);

for ($loop_index = 0; $loop_index <= $nodestr; $loop_index++) {

    $advrouter = ( split( /"/, $nodestr[$loop_index] ) )[3];
    @loopbackidx = indexes { /^$advrouter,/ } @loopbacks;
    @neighboridx = indexes { /^$advrouter,/ } @neighbors;
    @p2pidx = indexes { /^$advrouter,.*,Stub/ } @links;
    @bcastidx = indexes { /^$advrouter,.*,Transit/ } @links;
    @point2pointidx = indexes { /^$advrouter,/ } @point2points;

    print "    $nodestr[$loop_index],\"id\":$id,\"router_id\":\"$advrouter\",\n";
    print "        \"loopbacks\":[\n";

    if(@loopbackidx) {
        $loop_index2 = (scalar(@loopbackidx)-1);
        while ($loop_index2 > 0) {
            $idx = $loopbackidx[$loop_index2];
            $loopback = ( split( /,/, $loopbacks[$idx] ) )[1];
            print "            {\"address\":\"$loopback\"},\n";
            $loop_index2 --;
        }
        $idx = $loopbackidx[$loop_index2];
        $loopback = ( split( /,/, $loopbacks[$idx] ) )[1];
        print "            {\"address\":\"$loopback\"}\n";
    }

    print "        ],\n";
    print "        \"neighbors\":[\n";

    if(@neighboridx) {
        $loop_index2 = (scalar(@neighboridx)-1);
        while ($loop_index2 > 0) {
            $idx = $neighboridx[$loop_index2];
            $neighbor = ( split( /,/, $neighbors[$idx] ) )[1];
            print "            {\"neighbor\":\"$neighbor\"},\n";
            $loop_index2 --;
        }
        $idx = $neighboridx[$loop_index2];
        $neighbor = ( split( /,/, $neighbors[$idx] ) )[1];
        print "            {\"neighbor\":\"$neighbor\"}\n";
    }

    print "        ],\n";
    print "        \"p2p\":[\n";

    if(@p2pidx) {
        $loop_index2 = (scalar(@p2pidx)-1);
        while ($loop_index2 > 0) {
            $idx = $p2pidx[$loop_index2];
            $p2p_subnet = ( split( /,/, $links[$idx] ) )[1];
            print "            {\"p2p_subnet\":\"$p2p_subnet\"},\n";
            $loop_index2 --;
        }
        $idx = $p2pidx[$loop_index2];
        $p2p_subnet = ( split( /,/, $links[$idx] ) )[1];
        print "            {\"p2p_subnet\":\"$p2p_subnet\"}\n";
    }

    print "        ],\n";
    print "        \"bcast\":[\n";

    if(@bcastidx) {
        $loop_index2 = (scalar(@bcastidx)-1);
        while ($loop_index2 > 0) {
            $idx = $bcastidx[$loop_index2];
            $dr_address = ( split( /,/, $links[$idx] ) )[1];
            print "            {\"dr_address\":\"$dr_address\"},\n";
            $loop_index2 --;
        }
        $idx = $bcastidx[$loop_index2];
        $dr_address = ( split( /,/, $links[$idx] ) )[1];
        print "            {\"dr_address\":\"$dr_address\"}\n";
    }

    print "        ],\n";
    print "        \"bcast_local_addresses\":[\n";

    if(@bcastidx) {
        $loop_index2 = (scalar(@bcastidx)-1);
        while ($loop_index2 > 0) {
            $idx = $bcastidx[$loop_index2];
            $bcast_local_address = ( split( /,/, $links[$idx] ) )[4];
            print "            {\"bcast_local_address\":\"$bcast_local_address\"},\n";
            $loop_index2 --;
        }
        $idx = $bcastidx[$loop_index2];
        $bcast_local_address = ( split( /,/, $links[$idx] ) )[4];
        print "            {\"bcast_local_address\":\"$bcast_local_address\"}\n";
    }

    print "        ],\n";
    print "        \"p2mp_p2p_local_addresses\":[\n";

    if(@point2pointidx) {
        $loop_index2 = (scalar(@point2pointidx)-1);
        while ($loop_index2 > 0) {
            $idx = $point2pointidx[$loop_index2];
            $local_address = ( split( /,/, $point2points[$idx] ) )[1];
            print "            {\"local_address\":\"$local_address\"},\n";
            $loop_index2 --;
        }
        $idx = $point2pointidx[$loop_index2];
        $local_address = ( split( /,/, $point2points[$idx] ) )[1];
        print "            {\"local_address\":\"$local_address\"}\n";
    }

    $id++;

    if($loop_index < $nodestr) {
        print "        ]\n    },\n";
    } else {
        # json format requires last entry in array does not end with a ,
        print "        ]\n    }\n";
    }

}



print "  ],\n  \"links\":[\n";

#
# combine the @subnetstr and @nodestr arrays so we have one array index
#

@combostr = (@subnetstr, @nodestr);

#
# print the connections between all nodes
# for each entry in @links, split the entry into node,linkid
#

$links = (scalar(@links)-1);
$id = 0;

for ($loop_index = 0; $loop_index <= $links; $loop_index++) {

    $advrouter = ( split( /,/, $links[$loop_index] ) )[ 0 ];
    $linkid = ( split( /,/, $links[$loop_index] ) )[ 1 ];
    $metric = ( split( /,/, $links[$loop_index] ) )[ 2 ];
    $routeridx = ( first_index { /"$advrouter"/ } @combostr );
    $linkididx = ( first_index { /"$linkid"/ } @combostr );
    if($loop_index < $links) {
        print "    {\"source\":$routeridx,\"target\":$linkididx,\"metric\":$metric,\"id\":$id},\n";
        $id++;
    } else {
        # json format requires last entry in array does not end with a ,
        print "    {\"source\":$routeridx,\"target\":$linkididx,\"metric\":$metric,\"id\":$id}\n";
    }

}

print "  ]\n}\n"

