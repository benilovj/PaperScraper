<?php

include "/etc/db-config/db-config.php";
$database = "papers";
$host = "localhost";

$db_handle=mysql_connect($host,$db_user,$db_pass);

$db_found=mysql_select_db($database, $db_handle);

//begin high score table
?>

<img src="images/mail.gif" />
<div id="subheading">
<span class="wflf-broad-text">Top 10: The ones most people get right</span>
</div>
<ol>
<?php
if ($db_found) {
	$SQL = "SELECT * FROM comments WHERE `paper`='Daily Mail' AND correct > wrong ORDER BY correct DESC LIMIT 10";
	$result = mysql_query($SQL) or die(mysql_error()); 
	while ($db_field=mysql_fetch_array($result)) {
	echo "<li>". $db_field['comment'] ."</li>"; }	
}
?>
</ol>