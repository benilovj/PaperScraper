<?php
//INITIALIZE SESSION VARIABLES IF VISITING FOR THE FIRST TIME 

$_SESSION['playing'] = isset($_SESSION['playing']) ? $_SESSION['playing'] : 0; 

if ($_SESSION['playing'] == 0) {
	show_intro();
	initialise_round();
	echo "</div></div>"; //close out divs from index.php as we're having to die();
	include 'footer.php';
	die();
}
 
$_SESSION['question'] = isset($_SESSION['question']) ? $_SESSION['question'] : 1; 
$_SESSION['score'] = isset($_SESSION['score']) ? $_SESSION['score'] : 0; 

?> 
<?php

if(isset($_SESSION['question']) && $_SESSION['question'] <= 10 && $_SESSION['playing'] != 0 ) {
	ask_question();
	} else {
	present_score();
	$_SESSION['question'] = 1;
	} ?>
<?php
function ask_question() {

	$bias = bias_comments(); //$bias == true on average 1 in 5 times - adjust bias_comments to change
	$comment_details = query_comments_table( $bias ); //if $bias is true, q_c will return a dodgy comment
	$_SESSION['answer'] = $comment_details['answer'];
	$_SESSION['comment'] = $comment_details['comment'];
	$_SESSION['id']=  $comment_details['id'];
	$_SESSION['url']= $comment_details['url'];
	$_SESSION['deceptive']= $comment_details['deceptive'];
	$_SESSION['wrong']= $comment_details['wrong'];
	$_SESSION['correct']= $comment_details['correct'];

	echo "<div id='wflf-question-number'><h3>Question ". $_SESSION['question'] . "/10</h3></div>";

	echo "<div id='wflf-comment'><p>" . $_SESSION['comment'] . "</p></div>";

	echo '<div id="wflf-selection-buttons"><form name="input" id="paper-form" action="paper_checker.php" method="post">
			<input type="hidden" name="mail">
			<input type="hidden" name="guardian">
			<input type="submit" id="mail" name="mail" value="Mail" />
			<input type="submit" id="guardian" name="guardian" value="Guardian" />
	</form></div>';

}

function present_score() { ?>
	<?php if ($_SESSION['score'] == 10) { echo "<div id='winner-image'><img src='images/welldone.gif' alt='well done!' /></div>"; } ?>
	<div id="wflf-scorebox">
<?php
	echo "<p class='systemfont'>You scored</p> <span class='wflf-hugenum'>" . $_SESSION['score'] . "</span><br/>"; ?>
	</div> 
<?php
	echo "<div class='centretext'><a class='systemfont buttonlike final' href='http://twitter.com/home?status=I scored a respectable ". $_SESSION['score'] . "/10! at http://wiflufu.com/mail-or-guardian'>Tweet your score!</a></div>";
	echo "<div class='centretext'><a class='systemfont buttonlike' href='index.php'>Play again</a></div>";
	$_SESSION['score'] = 0;
	$_SESSION['playing'] = 0;
}

function query_comments_table( $bias ) {
//if bias as true, the system will choose a comment that has already been flagged as deceptive
	
	include "/etc/db-config/db-config.php";
	$database = "papers";
	$host = "localhost";

	$db_handle=mysql_connect($host,$db_user,$db_pass);

	$db_found=mysql_select_db($database, $db_handle);
	
	if ($db_found) {
		//get the total number of rows available and choose a random number in that range
		$row_values = fetch_a_comment($bias);
		while ($row_values == false) {
		$row_values = fetch_a_comment($bias); //make sure we don't get a blank result
			}
		mysql_close($db_handle);
	} else {
		die("DB not found");
	}
return $row_values;
}

function fetch_a_comment($bias) {

		$row = get_random_row($bias);
		$result = get_comment($row, $bias);
		$row_values = get_values_from_row($result);		
		return $row_values;

}

function get_random_row($bias) {

		$SQL = "SELECT COUNT(*) FROM comments";
		if ( $bias ) {
			$SQL .= " WHERE deceptive = 1"; }
		$result = mysql_query($SQL); 
		$row_count = implode(mysql_fetch_row($result));
		$row = mt_rand(1, $row_count);
		return $row;

}

function get_values_from_row($SQL_query_result) {
	
	while ($db_field=mysql_fetch_assoc($SQL_query_result)) {
		$present_comment = $db_field['comment'];		
		$correct_answer = $db_field['paper'];
		$comment_id = $db_field['id'];
		$comment_url = $db_field['url'];
		$comment_deceptive_flag = $db_field['deceptive'];
		$comment_correct_count = $db_field['correct'];
		$comment_wrong_count = $db_field['wrong'];
	}
	
	if (!isset($comment_id)) { 
		return false; }

	return array (
		'answer' => $correct_answer,
		'comment' => $present_comment,
		'id' => $comment_id,
		'url' => $comment_url,
		'deceptive' => $comment_deceptive_flag,
		'correct' => $comment_correct_count,
		'wrong' => $comment_wrong_count		
	);
			
}

function get_comment($row, $bias) {
	if ($bias) {
	$SQL = "SELECT * FROM `comments` WHERE deceptive = 1 ORDER BY RAND() LIMIT 1"; }
	else {
	$SQL = "SELECT * FROM comments WHERE id = ${row}";
	}
	$result = mysql_query($SQL);
	return $result;
}

function bias_comments() {
	$result = rand( 1, 5 );
	if ( $result > 1) { return false; 
	} else return true; 
}

function show_intro() {
	include('intro.php');
}

function initialise_round() {
	$_SESSION['playing'] = 0;
	$_SESSION['restarting'] = 1;
	$_SESSION['question'] = 0;
	// $_SESSION['question'] = isset($_SESSION['question']) ? $_SESSION['question'] : 1; 
	echo "<div id='intro'><a href='index.php' class='systemfont buttonlike red-bg'>Start</a></p></div>";
}
?>
