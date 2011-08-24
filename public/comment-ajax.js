$(document).ready(function() {
    $('#response').hide();

    $("#left-form").submit(function(event) {
		event.preventDefault(); 
        $.ajax({
            type: "POST",
            url: "/game/answer/Daily%20Mail",
            success: function(html) { 
                $("#response").append(html); }
        });
        $('#response').show();
        hideButtons();
	})
	
    $("#right-form").submit(function(event) {
		event.preventDefault(); 
        $.ajax({
            type: "POST",
            url: "/game/answer/Guardian",
            success: function(html) { 
                $("#response").append(html); }
        });
        $('#response').show();
        hideButtons();
	})

	function hideButtons() {
	    $("#wflf-selection-buttons").hide();
	}
});