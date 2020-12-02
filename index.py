#!/usr/bin/env python3

# Copyright (c) 2019, Juniper Networks, Inc
# All rights reserved
# This SOFTWARE is licensed under the LICENSE provided in the
# ./LICENCE file. By downloading, installing, copying, or otherwise
# using the SOFTWARE, you agree to be bound by the terms of that
# LICENSE.

import cgi
import cgitb
import tempfile
import os
import datetime
import re
import subprocess

cgitb.enable()

header = """
<html xmlns='http://www.w3.org/1999/xhtml'>
    <head>
        <meta http-equiv='X-UA-Compatible' content='IE=edge'; charset='UTF-8'>
        <title>TopoViz</title>
        <link rel='stylesheet' href='https://code.jquery.com/ui/1.12.0/themes/smoothness/jquery-ui.css'></link>
        <link type='text/css' rel=stylesheet href='static/style.css'></link>
        <script src='https://d3js.org/d3.v3.min.js'></script>
        <script src='https://code.jquery.com/jquery-3.4.1.min.js'
            integrity='sha256-CSXorXvZcTkaix6Yvo6HppcZGetbYMGWSFlBw8HfCJo='
            crossorigin='anonymous'>
        </script>
        <script src='https://code.jquery.com/ui/1.12.1/jquery-ui.min.js'
            integrity='sha256-VazP97ZCwtekAsvgPBSUwPFKdrwD3unUfSGVYrahUqU='
            crossorigin='anonymous'>
        </script>
        <script src='static/doc_ready.js'></script>
        <script src='static/error.js'></script>
    </head>
    <body>
        <header class='main-header'>
            <div id='hero3'> </div>  <!-- top logo -->
            <div id='hero2'> </div>  <!-- pin blue to left -->
            <div id='hero1'> </div> <!-- bottom is banner to right -->
        </header>

        <div id='breadcrumb' class='breadcrumb'></div>

        <div id='appheader' class='appheader'>
            <div id='appheadertitle' class='left'>
                <h1>( OSPF || ISIS || TED ) Topology Visualizer</h1>
            </div>
            <div class='clear'> </div>
        </div> <!-- app header -->

        <div class='seperator'></div>
"""

footer = """
   </body>
</html>
"""

modal = """
        <div id='modal_overlay' class='modal_overlay'></div>
        <div id='modal' class='modal'>
            <form action='index.py' method='POST' id='input' enctype='multipart/form-data'>
                <div id=tabs class=tabs>
                  <ul>
                    <li><a class='ospf_tab' href='#ospf_tab'>OSPF</a></li>
                    <li><a class='isis_tab' href='#isis_tab'>ISIS</a></li>
                    <li><a class='ted_tab' href='#ted_tab'>TED</a></li>
                    <li><a class='import_json_tab' href='#import_json_tab'>IMPORT JSON</a></li>
                  </ul>
                  <div id='ospf_tab'>
                      </br>Save the db to a file:</br>
                      <b>'show ospf database router extensive | display xml | no-more | save &ltfile&gt'</b>
                      </br></br>
                      <fieldset>
                          <legend>Select XML file</legend>
                          <div class=ospf_db_upload>
                              <input type='file' class='upload' name='db_file' />
                              <input class='upload' type='hidden' name='ospf' value='True' />
                          </div>
                      </fieldset>
                      </br>
                      <fieldset>
                          <legend>Select /etc/hosts file (optional, converts lo0 ip to hostname)</legend>
                          <div class=ospf_host_upload>
                              <input type='file' class='upload' name='host_file' />
                          </div>
                      </fieldset>
                      </br></br>
                      <button type='button' id='submitBtn_ospf' class='submitBtn'>Import</button>
                  </div>
                  <div id='isis_tab'>
                      </br>Save the db to a file:</br>
                      <b>'show isis database extensive | display xml | no-more | save &ltfile&gt'</b>
                      </br></br>
                      <fieldset>
                          <legend>Select XML file</legend>
                          <div class=isis_db_upload>
                          </div>
                      </fieldset>
                      </br>
                      <fieldset>
                          <legend>Select Options</legend>
                          <label for='radio-1'>Show V6 subnets?</label>
                          <input type='radio' name='opt' value='show_v6' id='radio-1'>
                          <label for='radio-2'>Only render routers (no subnets)</label>
                          <input type='radio' name='opt' value='no_subnets' id='radio-2'>
                          <label for='radio-3'>Default</label>
                          <input type='radio' name='opt' value='default' id='radio-3'>
                          </fieldset>
                      </br>
                      <button type='button' id='submitBtn_isis' class='submitBtn'>Import</button>
                  </div>
                  <div id='ted_tab'>
                      </br>Save the db to a file:</br>
                      <b>'show ted database extensive | display xml | no-more | save &ltfile&gt'</b>
                      </br></br>
                      <fieldset>
                          <legend>Select XML file</legend>
                          <div class=ted_db_upload>
                          </div>
                      </fieldset>
                      </br>
                      <fieldset>
                          <legend>Select /etc/hosts file (optional, converts lo0 ip to hostname)</legend>
                          <div class=ted_host_upload></div>
                      </fieldset>
                      </br></br>
                      <button type='button' id='submitBtn_ted' class='submitBtn'>Import</button>
                  </div>
                  <div id='import_json_tab'>
                      </br></br>
                      <fieldset>
                          <legend>Select previously exported topoviz JSON file</legend>
                          <div class=import_json_db_upload></div>
                      </fieldset>
                      </br></br></br></br></br></br></br></br>
                      <button type='button' id='submitBtn_json' class='submitBtn'>Import</button>
                  </div>
                </div> <!-- end of tabs -->
            </form>
        </div> <!-- end of modal -->
"""

ospf_key = """
                <div id=ospf_key class=key>
                    <svg height=100% width=100%>
                        <g>
                            <circle cx='40' cy='40'  r='15' stroke='DarkBlue' stroke-width='2' fill='Blue' />
                            <text class='keytext' x='50' y='40' dx='20' dy='5'>Non ABR/Non ASBR</text>
                            <circle cx='40' cy='90' r='15' stroke='DarkGreen' stroke-width='2' fill='Green' />
                            <text class=keytext x='50' y='90' dx='20' dy='5'>ABR</text>
                            <circle cx='40' cy='140' r='15' stroke='DarkCyan' stroke-width='2' fill='CadetBlue' />
                            <text class=keytext x='50' y='140' dx='20' dy='5'>ASBR</text>
                            <circle cx='40' cy='190' r='15' stroke='Indigo' stroke-width='2' fill='RebeccaPurple' />
                            <text class=keytext x='50' y='190' dx='20' dy='5'>ABR + ASBR</text>
                            <circle cx='40' cy='240' r='15' stroke='#6091d2' stroke-width='2' fill='#aec7e8' />
                            <text class=keytext x='50'y='240' dx='20' dy='5'>P2P Segment (subnet + mask)</text>
                            <circle cx='40' cy='290' r='15' stroke='#ff8533' stroke-width='2' fill='#ffc299' />
                            <text class=keytext x='50'y='290' dx='20' dy='5'>Bcast Segment (ip is DR)</text>
                            <circle cx='40' cy='340' r='15' stroke='#33ff77' stroke-width='2' fill='#99ffbb' />
                            <text class=keytext x='50'y='340' dx='20' dy='5'>P2MP Segment</text>
                        </g>
                    </svg>
                </div>
"""

isis_key = """
                <div id=isis_key class=key>
                    <svg height=100% width=100%>
                        <g>
                            <circle cx='40' cy='40'  r='15' stroke='DarkCyan' stroke-width='2' fill='CadetBlue' />
                            <text class='keytext' x='50' y='40' dx='20' dy='5'>Level 1 Subnet</text>
                            <circle cx='40' cy='90' r='15' stroke='DarkGreen' stroke-width='2' fill='Green' />
                            <text class=keytext x='50' y='90' dx='20' dy='5'>Level 2 Subnet</text>
                            <circle cx='40' cy='140' r='15' stroke='Indigo' stroke-width='2' fill='RebeccaPurple' />
                            <text class=keytext x='50' y='140' dx='20' dy='5'>Level 1/2 Subnet</text>
                            <circle cx='40' cy='190' r='15' stroke='DarkBlue' stroke-width='2' fill='Blue' />
                            <text class=keytext x='50' y='190' dx='20' dy='5'>ISIS nodes</text>
                        </g>
                    </svg>
                </div>
"""

ted_key = """
                <div id=ted_key class=key>
                    <svg height=100% width=100%>
                        <g>
                            <circle cx='40' cy='40'  r='15' stroke='DarkBlue' stroke-width='2' fill='Blue' />
                            <text class='keytext' x='50' y='40' dx='20' dy='5'>Router</text>
                            <circle cx='40' cy='90' r='15' stroke='#6091d2' stroke-width='2' fill='#aec7e8' />
                            <text class=keytext x='50'y='90' dx='20' dy='5'>P2P Subnet</text>
                            <circle cx='40' cy='140' r='15' stroke='#ff8533' stroke-width='2' fill='#ffc299' />
                            <text class=keytext x='50'y='140' dx='20' dy='5'>Bcast Subnet</text>
                        </g>
                    </svg>
                </div>
"""

lsp_trace_div = """
            <h3>Ingress LSP Trace</h3>
            <div id=lsp_trace_div>
                <div>
                    <span>Requires 'show mpls lsp ingress detail name &lt;&gt;' output</br></br>
                        <textarea type='text' name='lsp_trace' id='lsp_trace'></textarea></br></br>
                        <button onclick='_gettopo._traceon()'>Show</button>&nbsp&nbsp
                        <button onclick='_gettopo._traceoff()'>Hide</button>
                    </span>
                    </br></br>
                    <span>Only works for v4 addresses currently</span>
                </div>
            </div>
"""


def body(key, dl, lsp_trace):
    print(
        f"""
        <script src='static/d3_body.js'></script>
        <div id=content_wrapper>

            <!-- side bar div, used for setting attributes etc -->

            <div id=sidebar class=left>
                <h3>Info</h3>
                <div id=infopanel><span>To zoom:</br><ul><li>mousewheel</li><li>pinch/expand</li><li>2 finger drag up/down</li></ul>Click on a router to:<ul><li>list its details in info pane</li></ul>Mouseover a router to:<ul><li>highlight connected nodes</li></ul>Drag any node to:<ul><li>fix its position</li></ul>Double click a fixed node to:<ul><li>release it</li></ul>Mouseover a link to:<ul><li>show its metric</li></ul></span></div>
                <h3>Color Key</h3>
                <div id=key>
                    {key}
                </div>
                <h3>Search</h3>
                <div id=search>
                    <span>Enter one of the following:</br>
                        <ul class=ul>
                            <li>v4/v6 address</li>
                            <li>subnet</li>
                            <li>hostname</li>
                        </ul>
                        <input type='text' name='search_box' id='search_box'></br></br>
                    </span>
                    <button onclick='_gettopo._search()'>Find</button>
                    </br></br>
                    exact text only - no wildcards</br>
                    no whitespace</br>
                    case sensitive</br>
                    ted only - no subnets</br>
                    subnet must specify mask</br>
                    subnet mask in cidr format</br>
                </div>
                <h3>Export JSON</h3>
                <div id=download>
                    <button onclick="var file='{dl}';_gettopo._download(file)">Export</button>
                </div>
                {lsp_trace}
            </div>
            <script src='static/sidebar.js'></script> 
            <!-- div for the svg -->
            <div id=svgcontainer class=left></div>
        </div>
    """
    )

def error_out(errstr):
    print(f"<script>var txt='{errstr}'; _throw_error(txt)</script>")
    raise SystemExit

def process_xml(proto, opt, form, tmpfile, filepath):
    try:
        cmd = f"cat '{tmpfile}' | perl d3-{proto}-topo.pl {opt} > {filepath}"
        cmd_out = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError:
       error_out("Input file is not XML formatted")

    # Check if hosts file was uploaded
    if "host_file" in form and form["host_file"].filename:
        try:
            host_file = form["host_file"]
            # strip leading path from file name to avoid
            # directory traversal attacks
            fn = os.path.basename(host_file.filename)
            tmpfile = f"/tmp/{fn}"
            with open(tmpfile, "wb") as foo:
                foo.write(host_file.file.read())
        except OSError:
            error_out("unable to read from host file, or write its contents to /tmp")
        try:
            cmd = f"cat '{tmpfile}' | perl host_replace_{proto}.pl {filepath}"
            cmd_out = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
        except subprocess.CalledProcessError as exc:
            error_out("loopback conversion failed with error {}:\n".format(exc.output.decode()))

def process_json(json_file, tmpfile):
    fn = os.path.basename(json_file.filename)
    fn = re.sub(r"\.json$", "", fn)
    dl = fn
    filepath = f"json/{fn}"

    try:
        cmd = f"mv '{tmpfile}' '{filepath}'"
        cmd_out = subprocess.run(cmd, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    except subprocess.CalledProcessError as exc:
        error_out("moving json file failed with error {}:\n".format(exc.output.decode()))

    proto = ""
    with open(filepath, "r") as foo:
        line = foo.readline()
        while line:
            re_out = re.search(r'"protocol": "([a-z]+)"', line)
            if re_out:
                proto = re_out.group(1)
                break
            line = foo.readline()

        if not re.match(r"ospf|isis|ted", proto):
            error_out("unable to determine protocol from input file")

    return filepath, dl, proto

def main():
    print("Content-type:text/html\r\n\r\n")
    print(header)
    if os.environ.get('REQUEST_METHOD') and os.environ['REQUEST_METHOD'] == 'POST':
        form = cgi.FieldStorage()
        if not form["db_file"].filename:
            error_out("no xml file provided")

        # strip leading path from file name to avoid
        # directory traversal attacks
        db_file = form["db_file"]
        fn = os.path.basename(db_file.filename)
        tmpfile = f"/tmp/{fn}"
        with open(tmpfile, "wb") as foo:
            foo.write(db_file.file.read())
        output_db_file = re.sub(r" ", "_", db_file.filename)
        ts = datetime.datetime.strftime(datetime.datetime.now(), "%y%m%d%H%M%S")
        filepath = f"json/{output_db_file}-{ts}"
        dl = f"{output_db_file}-{ts}";


        opt = ""
        lsp_trace = lsp_trace_div

        if form.getvalue("ospf"):
            proto = "ospf"
            key = ospf_key
            db_file = form["db_file"]
            process_xml(proto, opt, form, tmpfile, filepath)
        elif form.getvalue("isis"):
            proto = "isis"
            key = isis_key
            opt = form.getvalue("opt")
            db_file = form["db_file"]
            process_xml(proto, opt, form, tmpfile, filepath)
        elif form.getvalue("ted"):
            proto = "ted"
            key = ted_key
            lsp_trace = ""
            db_file = form["db_file"]
            process_xml(proto, opt, form, tmpfile, filepath)
        elif form.getvalue("import_json"):
            json_file = form["db_file"]
            filepath, dl, proto = process_json(json_file, tmpfile)
            key = f"{proto}_key"
            if proto == "ted":
                lsp_trace = "" 

        # load remaining scripts and content elements
        body(key, dl, lsp_trace)

        # json creation/transform completed, its time to render
        print(f"<script>var file='{filepath}';var proto='{proto}';var args='{opt}';_get_json(file,proto,args);</script>")
        print(footer)

    else:
        print(modal)
        print(footer)

if __name__ == "__main__":
    main()
