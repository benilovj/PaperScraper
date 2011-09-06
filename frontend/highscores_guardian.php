<img src="images/guardian.png" /> 
<div id="subheading">
<span class="wflf-broad-text">Top 10: The ones most people get right</span>
</div>
<ol>
	$SQL = "SELECT * FROM comments WHERE `paper`='Guardian' AND correct > wrong ORDER BY correct DESC LIMIT 10";
	$result = mysql_query($SQL) or die(mysql_error()); 
	while ($db_field=mysql_fetch_array($result)) {
	echo "<li>". $db_field['comment'] ."</li>"; }	
</ol>
