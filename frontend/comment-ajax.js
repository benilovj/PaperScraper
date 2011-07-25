$(document).ready(function() { 

	$('#response').hide();

	$("input#guardian").click(function() {
		$.ajax({
			type: "POST",
			url: "paper_checker.php?",
			data: "mail=&guardian=guardian",
			success: function(html) { 
				$("#response").append(html); }
		});
		$('#response').show();
		hideButtons();
		return false;
	});

	$("input#mail").click(function() {
		$.ajax({
			type: "POST",
			url: "paper_checker.php?",
			data: "mail=mail&guardian=",
			success: function(html) { 
				$("#response").append(html); }
		});
		$('#response').show();
		hideButtons();
		return false;
	});

function hideButtons() {
	$("#wflf-selection-buttons").hide();
}

});


