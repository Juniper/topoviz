/*
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
*/

var json;
var proto;
var args;
var linkedbyindex;

function _get_json(fh,proto,subnets) {
    $.getJSON(fh)
        .done(function(data) {
            json = data;
            proto = proto;
            args = args;
            _gettopo();
        })
        .fail(function(jqxhr, textStatus, error) {
            _throw_error("getJSON returned: "+error);
        })
};

function _gettopo() {

    /* set vars used to svg size to something appropriate for the amount of nodes */

    var node_count = json.nodes.length;
    console.log('node count is '+node_count);
    var link_count = json.links.length;
    console.log('link count is '+link_count);
    if (node_count === 0) {
       _throw_error("no nodes found in the xml provided")
    } else if (node_count < 100) {
        w = 1000;
        h = 1000;
    } else if (node_count < 250) {
        w = 1666;
        h = 1666;
    } else if (node_count < 750) {
        w = 2333;
        h = 2333;
    } else if (node_count < 1000) {
        w = 3000;
        h = 3000;
    } else if (node_count < 3000) {
        w = 4000;
        h = 4000;
    } else {
        w = 6000;
        h = 6000;
    }

    /* define vars local to this function */

    var width = w,
        height = h,
        r = 5,
        fill_0 = 'Blue',
        fill_1 = 'Green',
        fill_2 = 'CadetBlue',
        fill_3 = 'RebeccaPurple',
        fill_4 = '#aec7e8',
        fill_5 = '#ffc299',
        fill_6 = '#b3e6b3',
        fill_11 = 'CadetBlue',
        fill_12 = 'Green',
        fill_13 = 'RebeccaPurple',
        fill_20 = 'Blue',
        fill_30 = 'Blue',
        fill_31 = '#aec7e8'
        stroke_0 = 'DarkBlue',
        stroke_1 = 'DarkGreen',
        stroke_2 = 'DarkCyan',
        stroke_3 = 'Indigo',
        stroke_4 = '#6091d2',
        stroke_5 = '#ff8533',
        stroke_6 = '#66cc66',
        stroke_11 = 'DarkCyan',
        stroke_12 = 'DarkGreen',
        stroke_13 = 'Indigo',
        stroke_20 = 'DarkBlue',
        stroke_30 = 'DarkBlue',
        stroke_31 = '#6091d2';

    var randomX = d3.random.normal(width / 2, 80),
        randomY = d3.random.normal(height / 2, 80);

    var data = d3.range(2000).map(function() {
        return [
            randomX(),
            randomY()
        ];});

    var calcDistance = function(link){
	    var l = (link.source.group == link.target.group) ? 60 : 30;
        return l;
    }

    if (proto === "isis") {
        var force = d3.layout.force()
            .linkDistance(calcDistance)
            .charge(-300)
	    .size([w, h]);
    } else {
	var force = d3.layout.force()
            .linkDistance(30)
            .charge(-100)
	    .size([w, h]);
    }

    var drag = force.drag()
        .on("dragstart", _dragstart);

    var svg = d3.select("#svgcontainer")
        .append("svg")
        .attr("id", "toposvg")
        .attr("width", "100%")
        .attr("height", "100%")
        .attr("viewBox", "0 0 " + w + " " + h)
        .attr("preserveAspectRatio", "xMidYMid slice")
        .append("g")
        .call(d3.behavior.zoom().scaleExtent([0.5, 8]).on("zoom", _zoom))
        .on("dblclick.zoom", null)  /* without this dblclick to release selected node also zooms in */
        .on("touchstart.zoom", null) /* this made selecting nodes flaky */
        .append("g");

    svg.append("rect")
        .attr("class", "overlay")
        .attr("width", 5000)
        .attr("height", 5000);

    var link = svg.append("svg:g").selectAll(".link")
        .data(json.links)
        .enter()
        .append("g")
        .attr("class", "link")
        .append("line")
        .attr("class", "link-line")
//        .attr("class", function(d) { return "link_" + d.id; })
        .on("mouseover", _showlinklabel)
        .on("mouseout", _hidelinklabel);


    var linklabel = svg.selectAll(".link")
        .append("text")
        .attr("class", function(d) { return "linklabel_" + d.id; })
        .attr("fill", "Black")
        .style("display", "none")
        .attr("dy", ".35em")
        .attr("text-anchor", "middle")
        .text(function(d) { return d.metric });

    var node = svg.append("svg:g").selectAll("circle")
        .data(json.nodes)
        .enter()
        .append("g")
        .attr("class", "node")
        .call(drag)
        .on("dblclick", _dblclick)
        .on("mouseover", _fade(.1))
        .on("mouseout", _fade(1));

        node.append("circle")
            .attr('class', function(d) { return "circle_" + d.id; })
            .style("fill", function(d) {
                if (d.group == "0"){  /* ospf non-abr non-asbr */
                    return fill_0;
                } else if (d.group == "1"){   /* ospf abr */
                    return fill_1;
                } else if (d.group == "2"){   /* ospf asbr */
                    return fill_2;
                } else if (d.group == "3"){  /* ospf abr asbr */
                    return fill_3;
                } else if (d.group == "4"){  /* ospf p2p link */
                    return fill_4;
                } else if (d.group == "5"){  /* ospf bcast link */
                    return fill_5;
                } else if (d.group == "6"){  /* ospf p2mp link */
                    return fill_6;
                } else if (d.group == "11"){  /* isis L1 subnet */
                    return fill_11;
                } else if (d.group == "12"){  /* isis L2 subnet */
                    return fill_12;
                } else if (d.group == "13"){   /* isis L1/L2 subnet */
                    return fill_13;
                } else if (d.group == "20"){  /* isis nodes */
                    return fill_20;
                } else if (d.group == "30"){  /* ted nodes */
                    return fill_30;
                } else if (d.group == "31"){  /* ted subnets */
                    return fill_31;
                }
            })
            .attr("r", r - .75)
            .style("stroke", function(d) {
                if (d.group == "0"){  /* ospf non-abr non-asbr */
                    return stroke_0;
                } else if (d.group == "1"){   /* ospf abr */
                    return stroke_1;
                } else if (d.group == "2"){   /* ospf asbr */
                    return stroke_2;
                } else if (d.group == "3"){  /* ospf abr asbr */
                    return stroke_3;
                } else if (d.group == "4"){  /* ospf p2p link */
                    return stroke_4;
                } else if (d.group == "5"){  /* ospf bcast link*/
                    return stroke_5;
                } else if (d.group == "6"){  /* ospf p2mp link*/
                    return stroke_6;
                } else if (d.group == "11"){  /* isis L1 subnet */
                    return stroke_11;
                } else if (d.group == "12"){  /* isis L2 subnet */
                    return stroke_12;
                } else if (d.group == "13"){   /* isis L1/L2 subnet */
                    return stroke_13;
                } else if (d.group == "20"){  /* isis nodes */
                    return stroke_20;
                } else if (d.group == "30"){  /* ted nodes */
                    return stroke_30;
                } else if (d.group == "31"){  /* ted subnets */
                    return stroke_31;
                }
            });

        node.append("text")
            .attr('class', function(d) { return "circletext_" + d.id; })
            .attr("dx", 12)
            .attr("dy", ".35em")
            .text(function(d) { return d.name })
            .style("fill-opacity", function(d) {
                if (d.group == "4" || d.group == "5" || d.group == "6" || d.group == "11" || d.group == "12" || d.group == "13" || d.group == "31"){
                    return "0";
                }
            });

    force
        .nodes(json.nodes)
        .links(json.links)
        .start();

    linkedbyindex = {};

    json.links.forEach(function(d) {
        linkedbyindex[d.source.index + "," + d.target.index] = 1;
    });

    function _isconnected(a, b) {
        return linkedbyindex[a.index + "," + b.index] || linkedbyindex[b.index + "," + a.index] || a.index == b.index;
    }

    force.on("tick", function() {
        node.attr("transform", function(d) {
            d.x = Math.max(r, Math.min(w - r, d.x));
            d.y = Math.max(r, Math.min(h - r, d.y));
            return "translate(" + d.x + "," + d.y + ")";
        });
        link.attr("x1", function(d) { return d.source.x; })
            .attr("y1", function(d) { return d.source.y; })
            .attr("x2", function(d) { return d.target.x; })
            .attr("y2", function(d) { return d.target.y; });
        linklabel
           .attr("x", function(d) { return (d.source.x + d.target.x)/2; })
           .attr("y", function(d) { return (d.source.y + d.target.y)/2; });
    });

    function _fade(opacity) {

        return function(d) {
            var connected = [d];
            if(d.group == "0" || d.group == "1" || d.group == "2" || d.group == "3" || d.group == "20" || d.group == "30") {
                if(args == "no_subnets" ) {
                    node.each(function(o) { if(_isconnected(d, o)) { connected.push(d); } });
                } else {
                    node.each(function(o) { if(_isconnected(d, o)) { if(o.group != "20") { connected.push(o); } } });
                }
            }

            node.style("stroke-opacity", function(o) {
                thisopacity = opacity;
                connected.forEach(function(e) {
                    if(_isconnected(e, o)) {
                        thisopacity = 1;
                    }
                });
                this.setAttribute('fill-opacity', thisopacity);
                return thisopacity;
            });

            link.style("stroke-opacity", function(o) {
                thisopacity = opacity;
                connected.forEach(function(e) {
                    if(o.source === e || o.target === e) {
                        thisopacity = 1;
                    }
                });
                this.setAttribute('stroke-opacity', thisopacity);
                return thisopacity;
            });

            d3.select(this)
            if ((d.group == "4" || d.group == "5" || d.group == "6" || d.group == "11" || d.group == "12" || d.group == "13" || d.group == "31") && opacity == ".1") {
                /* visible */
                var id = d.id;
                var className = ".circletext_" + id
                var textNode = d3.select(className);
                textNode.style("fill-opacity", "1");
            }
            if ((d.group == "4" || d.group == "5" || d.group == "6" || d.group == "11" || d.group == "12" || d.group == "13" || d.group == "31") && opacity == "1") {
                /* invisible */
                var id = d.id;
                var className = ".circletext_" + id
                var textNode = d3.select(className);
                textNode.style("fill-opacity", "0");
            }
        }
    }
    function _hidelinklabel(d) {
        d3.select(this)
        var id = d.id;
        var className = ".linklabel_" + id
        var linkText = d3.select(className);
        linkText.style("display", "none");
    }
    function _showlinklabel(d) {
        d3.select(this)
        var id = d.id;
        var className = ".linklabel_" + id
        var linkText = d3.select(className);
        linkText.style("display", "inline");
    }
    function _dblclick(d) {
        d3.select(this)
        .classed("fixed", d.fixed = false);
        document.getElementById("infopanel").innerHTML="";

    }
    function _dragstart(d) {
        d3.event.sourceEvent.stopPropagation();
        d3.select(this)
        .classed("fixed", d.fixed = true);
        var id = d.id;
        var className = "circle.circle_" + id
        var circleNode = d3.select(className);

        if (d.group == "20" ) {
            /* ISIS router details - write to info panel */
            document.getElementById("infopanel").innerHTML="<b>" + d.name + "</b></br></br>";
            document.getElementById("infopanel").innerHTML+= "<b>area address</b></br>";
            document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + d.area_address + "</br>";
            document.getElementById("infopanel").innerHTML+= "<b>router-id</b></br>";
            document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + d.router_id + "</br>";
            document.getElementById("infopanel").innerHTML+= "<b>level 1 loopbacks</b></br>";
            var l1loopbacks = d.l1loopbacks;
            for (var i = 0; i < l1loopbacks.length; i++) {
                var counter = l1loopbacks[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.address + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>level 2 loopbacks</b></br>";
            var l2loopbacks = d.l2loopbacks;
            for (var i = 0; i < l2loopbacks.length; i++) {
                var counter = l2loopbacks[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.address + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>local IPs</b></br>";
            var localips = d.local_ips;
            for (var i = 0; i < localips.length; i++) {
                var counter = localips[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.address + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>level 1 adjacencies</b></br>";
            var adjacencies = d.l1adjacencies;
            for (var i = 0; i < adjacencies.length; i++) {
                var counter = adjacencies[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.lsp_id + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>level 2 adjacencies</b></br>";
            var adjacencies = d.l2adjacencies;
            for (var i = 0; i < adjacencies.length; i++) {
                var counter = adjacencies[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.lsp_id + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>level 1 subnets</b></br>";
            var local_l1subnets = d.local_l1_subnets;
            for (var i = 0; i < local_l1subnets.length; i++) {
                var counter = local_l1subnets[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.subnet + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>Level 2 subnets</b></br>";
            var local_l2subnets = d.local_l2_subnets;
            for (var i = 0; i < local_l2subnets.length; i++) {
                var counter = local_l2subnets[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.subnet + "</br>";
            }
        } else if ( d.group == "0" || d.group == "1" || d.group == "2" || d.group == "3") {
            /* OSPF router details - write to info panel */
            document.getElementById("infopanel").innerHTML="<b>" + d.name + "</b></br></br>";
            document.getElementById("infopanel").innerHTML+= "<b>node type</b></br>";
            if ( d.group == "0") {
                var node_type = "internal";
            } else if ( d.group == "1") {
                var node_type = "abr";
            } else if ( d.group == "2") {
                var node_type = "asbr";
            } else if ( d.group == "3") {
                var node_type = "abr & asbr";
            }
            document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + node_type + "</br>";
            document.getElementById("infopanel").innerHTML+= "<b>router-id</b></br>";
            document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + d.router_id + "</br>";
            document.getElementById("infopanel").innerHTML+= "<b>loopbacks</b></br>";
            var loopbacks = d.loopbacks;
            for (var i = 0; i < loopbacks.length; i++) {
                var counter = loopbacks[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.address + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>p2p || p2mp neighbors</b></br>";
            var neighbors = d.neighbors;
            for (var i = 0; i < neighbors.length; i++) {
                var counter = neighbors[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.neighbor + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>p2p || p2mp int local ips</b></br>";
            var localips = d.p2mp_p2p_local_addresses;
            for (var i = 0; i < localips.length; i++) {
                var counter = localips[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.local_address + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>p2p int subnets</b></br>";
            var p2p_subnets = d.p2p;
            for (var i = 0; i < p2p_subnets.length; i++) {
                var counter = p2p_subnets[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.p2p_subnet + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>broadcast int subnet dr</b></br>";
            var bcast = d.bcast;
            for (var i = 0; i < bcast.length; i++) {
                var counter = bcast[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.dr_address + "</br>";
            }
            document.getElementById("infopanel").innerHTML+= "<b>broadcast int local ips</b></br>";
            var bcast = d.bcast_local_addresses;
            for (var i = 0; i < bcast.length; i++) {
                var counter = bcast[i];
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + counter.bcast_local_address + "</br>";
            }
        } else if ( d.group == "30") {
            /* TED router details - write to info panel */
            document.getElementById("infopanel").innerHTML="<b>" + d.name + "</b></br></br>";
            var links = d.links;
            for (var i = 0; i < links.length; i++) {
                var counter = links[i];
                document.getElementById("infopanel").innerHTML+= "<b>ted link</b></br>";
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + "to: " + counter.to + "</br>";
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + "local_ifa: " + counter.local_address + "</br>";
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + "remote_ifa: " + counter.remote_address + "</br>";
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + "ifindex: " + counter.local_ifindex + "</br>";
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + "metric: " + counter.link_metric + "</br>";
                document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + "bw: " + counter.static_bw + "</br>";
                if( counter.admin_groups ) {
                    document.getElementById("infopanel").innerHTML+= "&nbsp&nbsp" + "groups: " + counter.admin_groups + "</br></br>";
                } else {
                    document.getElementById("infopanel").innerHTML+= "</br>";
                }
            }
        }
    }

    function _zoom() {
        svg.attr("transform", "translate(" + d3.event.translate + ")scale(" + d3.event.scale + ")");
    }

    function _traceon() {

        var ingress_lsp = document.getElementById('lsp_trace').value;
        //var egress1 = ingress_lsp.replace(/\n  From:(.*\n.*)+/, "");
        //var egress_lsr = egress1.replace(/(.*\n)+/, "");
        var str1 = ingress_lsp.replace(/(.*\n)+  From:/, "");
        var str2 = str1.replace(/,.*/, "");
        var ingress_lsr = str2.replace(/(\n.*)+/g, "");
        var str4 = ingress_lsp.replace(/(.*\n)+    Received RRO.*\n/, "");
        var str5 = str4.replace(/\n[\W\w]*/g, "");
        var str6 = str5.replace(/\)/g, "\n");
        var rro = str6.replace(/\(.*\n/g, "");
        var ingress_lsrandrro = ingress_lsr + ' ' + rro;
        var path_list = ingress_lsrandrro.split(/ +/).filter(Boolean);
        var path_list_binary=[];
        var subnet_array=[];
        var link_array=[];
        var router_array=[];
        var router_and_subnet_array=[];
        var uniq_router_and_subnet_array=[];
        var inv_router_and_subnet_array=[];
        var inv_link_array=[];
        var subnets_connected_to_both=[];


        function _ip_to_binary_string(ip){
            var split = ip.split(/\./);
            var binarystring = "";
            for(var n=0; n < split.length; n++){
                var octet = split[n];
                var tonum = parseInt(octet, 10);
                bin  = tonum.toString(2);
                var padded = "00000000" + bin;
                padded = padded.substr(-8);
                binarystring = binarystring.concat(padded);
            }
            return binarystring;
        }

        for(var i=0; i < path_list.length; i++){

            // create binary string representing each ip in the path list
            ip = path_list[i];
            var binarystring = _ip_to_binary_string(ip);
            path_list_binary.push(binarystring);

            // first we need to identify the indexes of each node in the list
            // invert search order as routers are at the bottom of nodes array

            for (var n = (json.nodes.length-1); n >= 0; n--) {
                var router = json.nodes[n];
                if (router.group !== 20 && router.group !== 30 && router.group > 3) {
                    // skip if not a ted, isis or ospf router node type
                    break;
                } else if (router.name == "" + path_list[i] || router.router_id == "" + path_list[i]) {
                    router_array.push(router.index);
                    break;
                } else if (router.group <= 3 ) {   // catches all ospf router types
                    router_obj = router.p2mp_p2p_local_addresses;
                    for (var k = 0; k < router_obj.length; k++) {
                        if (router_obj[k].local_address == path_list[i]) {
                            router_array.push(router.index);
                            break;
                        }
                    }
                    router_obj = router.bcast_local_addresses;
                    for (var k = 0; k < router_obj.length; k++) {
                        if (router_obj[k].bcast_local_address == path_list[i]) {
                            router_array.push(router.index);
                            break;
                        }
                    }
                    router_obj = router.loopbacks;
                    for (var k = 0; k < router_obj.length; k++) {
                        if (router_obj[k].address == path_list[i]) {
                            router_array.push(router.index);
                            break;
                        }
                    }
                } else if (router.group == 20) {
                    router_obj = router.local_ips;
                    for (var k = 0; k < router_obj.length; k++) {
                        if (router_obj[k].address == path_list[i]) {
                            router_array.push(router.index);
                            break;
                        }
                    }
                    router_obj = router.l2loopbacks;
                    for (var k = 0; k < router_obj.length; k++) {
                        if (router_obj[k].address == path_list[i]) {
                            router_array.push(router.index);
                            break;
                        }
                    }
                    router_obj = router.l1loopbacks;
                    for (var k = 0; k < router_obj.length; k++) {
                        if (router_obj[k].address == path_list[i]) {
                            router_array.push(router.index);
                            break;
                        }
                    }
                } else if (router.group == 30) {
                    router_obj = router.links;
                    for (var k = 0; k < router_obj.length; k++) {
                        if (router_obj[k].local_address == path_list[i]) {
                            router_array.push(router.index);
                            break;
                        }
                    }
                }
            }
        }

        //
        // this method selects all .nodes, filters the ones we want and returns an array
        // then uses .each to call a function for each entry in the list
        //
        // var update = d3.selectAll(".node")
        //    .filter(function(d) { return router_array.indexOf((d.id)) > -1})
        //    .each(function (d) {
        //       _fade(d,.1);
        //    });
        //
        // this method selects a single node and uses .each to call a function
        //var update = d3.select(".circle_59")
        //    .each(function (d) { console.log(d); _fade(d,.1); });
        //



        //  we now have a list of routers, now we need the connecting subnets and their links

        var a = ""
        var lsr = '.circle_' + router_array[0];
        var update = d3.select(lsr)
            .each(function (d) {
                a = d;
            });

        for(var i=1; i < router_array.length; i++){
            var lsr = '.circle_' + router_array[i];
            var update = d3.select(lsr)
               .each(function (d) {
                   _lsp_join(link_array, subnet_array, a, d);
                   a = d;
               });
        }

        function _lsp_join(link_array, subnet_array, a, b) {
            // problem here is that each router only connects to subnets.
            // need to either pass in array that includes the subnets
            // or walk all subnets connected to a node a, repeat for node b
            var subnet_array_a=[];
            var subnet_array_b=[];
            var link_array_a=[];
            var link_array_b=[];
            var subnets_connected_to_both=[];

            // linkedbyindex is a list of node to node connections
            for (var entry in linkedbyindex) {
                var re_a = new RegExp(a.index + ",[0-9]+");
                var re_b = new RegExp(b.index + ",[0-9]+");
                if (re_a.test(entry)) {
                    // get the indexes of all nodes connecting to 'a'
                    var str = entry.replace(/^[0-9]+,/,"");
                    var num = parseInt(str, 10);
                    subnet_array_a.push(num);
                } else if (re_b.test(entry)) {
                    // get the indexes of all nodes connecting to 'b'
                    var str = entry.replace(/^[0-9]+,/,"");
                    var num = parseInt(str, 10);
                    subnet_array_b.push(num);
                }
            }

            // find which of these nodes are connected to both 'a' and 'b'
            for(var i=0; i < subnet_array_a.length; i++){
                var index = subnet_array_b.indexOf(subnet_array_a[i]);
                if(index > -1) {
                    // we have a match, append to subnet_array array
                    // subnet_array.push(subnet_array_b[index]);
                    // find the links that connect 'a' and 'b' to this node
                    //potentially less expensive to add the link id to linkedbyindex and read that
                    //json.links.forEach(function(d) {
                    //    if((d.source.id === b.index && d.target.id === subnet_array_b[index]) || (d.source.id === a.index && d.target.id === subnet_array_b[index])){
                    //        link_array.push(d.id);
                    //    }
                    //});
                    subnets_connected_to_both.push(subnet_array_b[index]);
                }
            }

            // if there are multiple links between 'a' and 'b' then try to isolate
            // which subnet is a match to the ip in the RRO list
            if(subnets_connected_to_both.length == 1) {
                subnet_array.push(subnets_connected_to_both[0]);
                json.links.forEach(function(d) {
                    if((d.source.id === b.index && d.target.id === subnets_connected_to_both[0]) || (d.source.id === a.index && d.target.id === subnets_connected_to_both[0])){
                        link_array.push(d.id);
                    }
                });
            } else if (subnets_connected_to_both.length > 1) {
                for(var i=0; i < subnets_connected_to_both.length; i++){
                    var subnet = json.nodes[subnets_connected_to_both[i]].name;
                    var split = subnet.split(/\//);
                    var mask = split[1];
                    mask = parseInt(mask, 10);
                    var ip = split[0];
                    var binarystring = _ip_to_binary_string(ip);
                    var trimbinarystring1 = binarystring.substring(0,mask);
                    for(var n=0; n < path_list_binary.length; n++){
                        var trimbinarystring2 = path_list_binary[n].substring(0,mask);
                        if(trimbinarystring1 === trimbinarystring2){
                            subnet_array.push(subnets_connected_to_both[i]);
                            json.links.forEach(function(d) {
                                if((d.source.id === b.index && d.target.id === subnets_connected_to_both[i]) || (d.source.id === a.index && d.target.id === subnets_connected_to_both[i])){
                                    link_array.push(d.id);
                                }
                            });
                        }
                    }
                }
            }
        }

        //join these two arrays so we can act on it once
        router_and_subnet_array = router_array.concat(subnet_array);
        // need to invert the arrays in order to filter correctly
        router_and_subnet_array.sort(function(a, b){return a-b});
        uniq_router_and_subnet_array.push(router_and_subnet_array[0]);
        for (var i = 1; i < router_and_subnet_array.length; i++) { // start loop at 1 as element 0 can never be a duplicate
            if (router_and_subnet_array[i-1] !== router_and_subnet_array[i]) {
                uniq_router_and_subnet_array.push(router_and_subnet_array[i]);
            }
        }

        var n=0;
        for(i=0; i < json.nodes.length; i++){
            if (i === uniq_router_and_subnet_array[n]) {
                n++;
            } else if ( i > -1 ) {
                inv_router_and_subnet_array.push(i);
            }
        }

        var n=0;
        link_array.sort(function(a, b){return a-b});
        for(i=0; i < json.links.length; i++){
            if (i === link_array[n]) {
                n++;
            } else if ( i > -1 ) {
                inv_link_array.push(i);
            }
        }

        var shade_nodes = d3.selectAll(".node")
            .on('mouseout',null)
            .on('mouseover',null)
            .filter(function(d) { return inv_router_and_subnet_array.indexOf((d.id)) > -1})
            .each(function(d) {
                this.setAttribute('fill-opacity', .1)
                this.setAttribute("style","stroke-opacity: .1;");
            });

        var allow_subnet_textlabel = d3.selectAll(".node")
            .filter(function(d) { return subnet_array.indexOf((d.id)) > -1})
            .on('mouseout', _show_label(0))
            .on('mouseover',_show_label(1));

        var shade_links = d3.selectAll(".link-line")
            .filter(function(d) { return inv_link_array.indexOf((d.id)) > -1})
            .on("mouseover", null)
            .on("mouseout", null)
            .each(function(d) {
                this.setAttribute("style","stroke-opacity: .1;");
                this.setAttribute('stroke-opacity', .1);
            });

        function _show_label(opacity) {
            return function(d) {
                d3.select(this)
                var id = d.id;
                var className = ".circletext_" + id;
                var textNode = d3.select(className);
                textNode.style("fill-opacity", opacity);
            }
        }

    }

    _gettopo._traceon = _traceon;

    function _traceoff() {

        var unshade_nodes = d3.selectAll(".node")
            .on("mouseover", _fade(.1))
            .on("mouseout", _fade(1))
            .each(function(d) {
                this.setAttribute('fill-opacity', 1)
                this.setAttribute("style","stroke-opacity: 1;");
            });

        var unshade_links = d3.selectAll(".link-line")
            .on("mouseover", _showlinklabel)
            .on("mouseout", _hidelinklabel)
            .each(function(d) {
                this.setAttribute("style","stroke-opacity: 1;");
                this.setAttribute('stroke-opacity', 1);
            });

    }

    _gettopo._traceoff = _traceoff;

    function _search() {

        var findme = document.getElementById("search_box").value;

        var nodes = json.nodes;

        for (var i = 0; i < nodes.length; i++) {
            var counter = nodes[i];
            if (counter.name == "" + findme || counter.router_id == "" + findme) {
                var findclass = ".circle_" + counter.id;
                d3.select(findclass).transition().duration(1000)
                .attr("r", "50")
                .transition()
                .attr("r", "5")
                .transition()
                .attr("r", "50")
                .transition()
                .attr("r", "5")
                return;
            }

            // ospf only
            if (counter.group == 0 || counter.group == 1 || counter.group == 2 || counter.group == 3) {

                counter2 = counter.loopbacks;
                for (var k = 0; k < counter2.length; k++) {
                    if (counter2[k].address == "" + findme) {
                        var findclass = ".circle_" + counter.id;
                        d3.select(findclass).transition().duration(1000)
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        .transition()
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        return;
                    }
                }

                counter2 = counter.p2p;
                for (var k = 0; k < counter2.length; k++) {
                    if (counter2[k].p2p_subnet == "" + findme) {
                        var findclass = ".circle_" + counter.id;
                        d3.select(findclass).transition().duration(1000)
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        .transition()
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        return;
                    }
                }

                counter2 = counter.bcast_local_addresses;
                for (var k = 0; k < counter2.length; k++) {
                    if (counter2[k].bcast_local_address == "" + findme) {
                        var findclass = ".circle_" + counter.id;
                        d3.select(findclass).transition().duration(1000)
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        .transition()
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        return;
                    }
                }

                counter2 = counter.p2mp_p2p_local_addresses;
                for (var k = 0; k < counter2.length; k++) {
                    if (counter2[k].local_address == "" + findme) {
                        var findclass = ".circle_" + counter.id;
                        d3.select(findclass).transition().duration(1000)
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        .transition()
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        return;
                    }
                }

            // isis only
            } else if (counter.group == 20) {

                counter2 = counter.l1loopbacks;
                for (var k = 0; k < counter2.length; k++) {
                    if (counter2[k].address == "" + findme) {
                        var findclass = ".circle_" + counter.id;
                        d3.select(findclass).transition().duration(1000)
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        .transition()
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        return;
                    }
                }

                counter2 = counter.l2loopbacks;
                for (var k = 0; k < counter2.length; k++) {
                    if (counter2[k].address == "" + findme) {
                        var findclass = ".circle_" + counter.id;
                        d3.select(findclass).transition().duration(1000)
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        .transition()
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        return;
                    }
                }

                counter2 = counter.local_ips;
                for (var k = 0; k < counter2.length; k++) {
                    if (counter2[k].address == "" + findme) {
                        var findclass = ".circle_" + counter.id;
                        d3.select(findclass).transition().duration(1000)
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        .transition()
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        return;
                    }
                }
            } else if (counter.group == 30) {

                counter2 = counter.links;
                for (var k = 0; k < counter2.length; k++) {
                    if (counter2[k].local_address == "" + findme) {
                        var findclass = ".circle_" + counter.id;
                        d3.select(findclass).transition().duration(1000)
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        .transition()
                        .attr("r", "50")
                        .transition()
                        .attr("r", "5")
                        return;
                    }
                }
            }
        }
    }

    _gettopo._search = _search;

    function _download(file) {

        // because of the way d3 stores data inside json.links array
        // we have to create a new object that contains only
        // the data required for a successful import.
        var new_json = {'protocol': proto,nodes:[],links:[]};

        // the nodes array is ok, we can just copy this from the json object
        new_json.nodes = json.nodes;

        // pull the relevant info from the json.links array
        var i;
        for (i=0;i<json.links.length;i++){
            if(proto == "ospf") {
                new_json.links.push({'source': json.links[i].source.index,
                                     'target': json.links[i].target.index,
                                     'metric': json.links[i].metric,
                                     'id': json.links[i].id });

            } else if (proto === "isis") {
                new_json.links.push({'source': json.links[i].source.index,
                                     'target': json.links[i].target.index,
                                     'level': json.links[i].level,
                                     'metric': json.links[i].metric,
                                     'id': json.links[i].id });

            } else if (proto === "ted") {
                new_json.links.push({'source': json.links[i].source.index,
                                     'target': json.links[i].target.index,
                                     'source_address': json.links[i].source_address,
                                     'target_address': json.links[i].target_address,
                                     'metric': json.links[i].metric,
                                     'bw': json.links[i].bw,
                                     'id': json.links[i].id });
            }
        }

        // convert new object into json
        var json_out = JSON.stringify(new_json, null, '  ');

        // create element that contains the hyperlink to the json string
        var a = window.document.createElement('a');
        a.href = window.URL.createObjectURL(new Blob([json_out], {type: 'application/json'}));
        a.download = file+'.json';

        // Append anchor to body.
        document.body.appendChild(a)

        // trigger the download
        a.click();

        // Remove anchor from body
        document.body.removeChild(a)

    }

    _gettopo._download = _download;

    // end of gettopo function

}
