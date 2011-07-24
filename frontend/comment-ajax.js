$(document).ready(function() { 

/*$('form#paper-form :submit').submit(function() {
	var _data = $(this).closest('form').serializeArray();
	_data.push({ name : this.name, value: this.value });
    _data = $.param(_data);                          
    $.ajax({
      type: 'POST',
      url: "php.php?",
      data: _data,
      success: function(html){
        $('div#1').html(html);
      }
    });
    return false; //prevent default submit
  });
*/

	$("input#guardian").click(function() {
		$.ajax({
			type: "POST",
			url: "paper_checker.php?",
			data: "mail=&guardian=guardian",
			success: function(html) { 
				$("#response").append(html); }
		});
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
		return false;
	});


});


