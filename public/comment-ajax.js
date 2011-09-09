$(document).ready(function() {
    $('#response').hide();

    var ajaxPost = function(event) {
        event.preventDefault();
        $.ajax({
            type: "POST",
            url: event.target.getAttribute( 'action' ),
            success: function(html) { 
                $("#response").append(html);
            }
        });
        $('#response').show();
        hideButtons();
    }

    $("#left-form").submit(ajaxPost);
    $("#right-form").submit(ajaxPost);

    function hideButtons() {
        $("#wflf-selection-buttons").hide();
    }
});