colors = ['red', 'green', 'orange', 'blue', 'yellow'];

$(document).ready(function() {

	$('#menu ul li').each(function(index) {
		$(this).addClass(colors[index]);
});

});
