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
#
*/ 
$(document).ready(function () {
        $('button').button();
        $('.submitBtn').click(function(){
            $('#input').submit();
        });
        $( "input[type='radio']" ).checkboxradio();
        $('#tabs').tabs({heightStyle: 'auto'});
        $('.ospf_tab').click(function () {
            $('.upload').remove();
            $('.ospf_db_upload').append(
                $('<input/>').attr('class','upload').attr('type','file').attr('name','db_file'),
                $('<input/>').attr('class','upload').attr('type','hidden').attr('name','ospf').attr('value','True'),
            );
            $('.ospf_host_upload').append(
                $('<input/>').attr('class','upload').attr('type','file').attr('name','host_file')
            );
        });
        $('.isis_tab').click(function () {
            $('.upload').remove();
            $('.isis_db_upload').append(
                $('<input/>').attr('class','upload').attr('type','file').attr('name','db_file'),
                $('<input/>').attr('class','upload').attr('type','hidden').attr('name','isis').attr('value','True'),
            );
            $('.isis_host_upload').append(
                $('<input/>').attr('class','upload').attr('type','file').attr('name','host_file')
            );
        });
        $('.ted_tab').click(function () {
            $('.upload').remove();
            $('.ted_db_upload').append(
                $('<input/>').attr('class','upload').attr('type','file').attr('name','db_file'),
                $('<input/>').attr('class','upload').attr('type','hidden').attr('name','ted').attr('value','True'),
            );
            $('.ted_host_upload').append(
                $('<input/>').attr('class','upload').attr('type','file').attr('name','host_file')
            );
        });
        $('.import_json_tab').click(function () {
            $('.upload').remove();
            $('.import_json_db_upload').append(
                $('<input/>').attr('class','upload').attr('type','file').attr('name','db_file'),
                $('<input/>').attr('class','upload').attr('type','hidden').attr('name','import_json').attr('value','True'),
            );
        });
    });
