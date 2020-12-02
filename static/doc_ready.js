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
