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
		return false;
	});


});


