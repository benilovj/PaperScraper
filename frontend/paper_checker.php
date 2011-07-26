<?php
session_start();

increase_question_counter();

$guardianimage = "<img src='images/guardian.png' alt='It was from the Guardian' />";
$mailimage="<img src ='images/mail.gif' alt='It was from the Daily Mail' />";
$rightimage="<img src='images/right.gif' alt='Right!' />";
$wrongimage="<img src='images/wrong.gif' alt='Wrong!' />";
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
{ echo '<p class="systemfont result">'. get_response('good') . '</p>'; 
	register_correct_guess($id);
	gain_a_point(); }

	elseif($_POST['guardian'] && $_SESSION['answer'] == "Guardian") 
{ echo '<p class="systemfont result">'. get_response('good') . '</p>'; 
	register_correct_guess($id);
	gain_a_point(); }

	else { echo '<p class="systemfont result">'. get_response('bad') . '</p>'; 
		register_wrong_guess($id); }

?> <br /><?php

switch ($_SESSION['answer']) {
	case 'Daily Mail':
		echo $mailimage . "<br />";
		break;
	case 'Guardian':
		echo $guardianimage . "<br />";
}

?> </div> 
<div class="centretext"><p class="systemfont"><?php
display_trends(get_trends()); ?> </p></div><?php
flag_if_deceptive($id);	
echo "<div id='wflf-question-controls'>";

$_SESSION['question'] != 10 ? $navigation_msg = "Next Question" : $navigation_msg="See how you did!";
echo "<br /> <p class='centretext'><a class='systemfont buttonlike' href=\"index.php\">$navigation_msg</a><br />";

echo "<a class='systemfont modestlink' href=\"" . $_SESSION['url'] . "\">See the original article</a>";
echo "</div>";

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
	if ($proportion <= -2) { echo "People tend to guess the wrong source for this comment."; }
	elseif ($proportion >= 2) {echo "People tend to guess this comment correctly."; }
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
	return -1; }
elseif ($total_votes == 1 && $score == 1) {
	return 1; }

return $score;

}

function get_response($tone) {
	$goodwords = array('Super!', 'Great!', 'Well done!', 'Good!', 'Excellent!', 'Good guess!', 'You\'re good!', 'Incredible!', 'You\'re right!');
	$badwords = array('Hard luck!', 'Oh dear', 'Incorrect guess', 'You\'re wrong', 'Pity', 'Nope', 'Oh no!', 'Hard cheese', 'Sorry old thing');
	
switch ($tone) {
	case 'good':
		return $goodwords[array_rand($goodwords, 1)];
		break;
	case 'bad':
		return $badwords[array_rand($badwords, 1)];
		break;
	default:
		return 'Error';
}

}

mysql_close($db_handle);

?>
