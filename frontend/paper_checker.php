<?php
session_start();

increase_question_counter();

$id = $_SESSION['id'];

if (!is_numeric($id)) { //rudimentary sanitisation as we use this id for a db key
	die("$id is not int");
}

include "/etc/db-config/db-config.php";
$database = "papers";
$host = "localhost";

$db_handle=mysql_connect($host,$db_user,$db_pass);

$db_found=mysql_select_db($database, $db_handle);

if ($db_found) {

	$SQL = "UPDATE comments SET votes=votes+1 WHERE id=" .  $id . ";";
	mysql_query($SQL); 

}
?> <div id="answer-report"> <?php
// blend this into 1 function
if($_POST['mail'] && $_SESSION['answer'] == "Daily Mail") 
{ echo "You were right, it was the <strong>Daily Mail</strong><br />";
	register_correct_guess($id);
	gain_a_point(); }

	elseif($_POST['guardian'] && $_SESSION['answer'] == "Guardian") 
{ echo "You were right, it was the <strong>Guardian</strong><br />"; 
	register_correct_guess($id);
	gain_a_point(); }

	else { echo "you were <strong>WRONG</strong> - it was the <strong>${_SESSION['answer']}</strong>!<br />"; 
		register_wrong_guess($id); }

?> </div> <?php
display_trends(get_trends());
flag_if_deceptive($id);	
echo "<div class='wflf-question-controls'>";
echo "<a href=\"" . $_SESSION['url'] . "\">See the original article</a><br />";
echo "<br />";
echo "<a href=\"index.php\">Next question</a><br />";
echo "</div>";
echo "comment id is: " . $id;

function flag_if_deceptive($id) {
	global $db_found;
	if($db_found) {
		$SQL = "update comments set deceptive = 1 where id = ${id} AND (wrong >= correct)";
		mysql_query($SQL);
		$SQL = "update comments set deceptive = 0 where id = ${id} AND (correct > wrong)";
		mysql_query($SQL);
	}
}

function register_wrong_guess($id) {
	global $db_found;
	if ($db_found) {
		$SQL = "UPDATE comments SET wrong = wrong+1 WHERE id = ${id}";
		$_SESSION['wrong'] = $_SESSION['wrong'] +1; //this means we can take the user's guess into account when showing trends for this comment
		mysql_query($SQL);
	}
}

function register_correct_guess($id) {
	global $db_found;
	if ($db_found) {
		$SQL = "UPDATE comments SET correct = correct+1 WHERE id = ${id}";
		$_SESSION['correct'] = $_SESSION['correct'] +1;
		mysql_query($SQL);
	}
}

function gain_a_point() {
	$_SESSION['score'] = $_SESSION['score'] + 1;
}

function increase_question_counter() {
	if ($_POST['mail'] || $_POST['guardian']) {
		$_SESSION['question'] = $_SESSION['question'] + 1; }
}

function display_trends($proportion) {
	if ($proportion < -20) { echo "People tend to guess the wrong source for this comment."; }
	elseif ($proportion > 20) {echo "People tend to guess this comment correctly."; }
	elseif ($proportion == 0) {echo "This comment attracts even numbers of correct and wrong guesses."; }
}

function get_trends() {
	
$positive = $_SESSION['correct'];
$negative = $_SESSION['wrong'];

if ($positive == $negative) {
	return 0; }

$total_votes = $positive + $negative;
$score = $positive - $negative;

if ($total_votes == 1 && $score == -1) {
	return -10; }
elseif ($total_votes == 1 && $score == 1) {
	return 10; }

if ($total_votes % 2 != 0 && $total_votes != 1) {
	$total_votes++;
} elseif ($total_votes == 0) { return false; }

$midpoint = $total_votes / 2;

$trend = $midpoint + $score; // overall weighting towards positive or negative

if ($trend < $midpoint && $trend > 0) { // we want a negative number for our trend if the weighting is below the midpoint
	$trend = $trend*-1;
} 

$proportion = ($trend / $total_votes)*10;

return $proportion;

}

mysql_close($db_handle);

?>
