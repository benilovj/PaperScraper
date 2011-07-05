<?php
session_start();

increase_question_counter();

$id = $_SESSION['id'];

if (!is_numeric($id)) { //rudimentary sanitisation
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

// blend this into 1 function
if($_POST['mail'] && $_SESSION['answer'] == "Daily Mail") 
{ echo "You were right, it was the <strong>Daily Mail</strong>";
	register_correct_guess($id);
	gain_a_point(); }

	elseif($_POST['guardian'] && $_SESSION['answer'] == "Guardian") 
{ echo "You were right, it was the <strong>Guardian</strong>"; 
	register_correct_guess($id);
	gain_a_point(); }

	else { echo "you were <strong>WRONG</strong> - it was the <strong>${_SESSION['answer']}</strong>!"; 
		register_wrong_guess($id); }

flag_if_deceptive($id);	

echo "<p><strong>Original comment: </strong>" . $_SESSION['comment'] . "</p>";
echo "<a href=\"" . $_SESSION['url'] . "\">See the original article</a>";
echo "<br />";
echo "<a href=\"index.php\">Next question</a>";
echo "comment id is: " . $id;

function flag_if_deceptive($id) {
	global $db_found;
	if($db_found) {
		$SQL = "update comments set deceptive = 1 where id = ${id} AND (wrong >= correct)";
		$SQL = "update comments set deceptive = 0 where id = ${id} AND (correct > wrong)";
		mysql_query($SQL);
	}
}

function increase_score() {
	$_SESSION['score']++;
}

function register_wrong_guess($id) {
	global $db_found;
	if ($db_found) {
		$SQL = "UPDATE comments SET wrong = wrong+1 WHERE id = ${id}";
		mysql_query($SQL);
	}
}

function register_correct_guess($id) {
	global $db_found;
	if ($db_found) {
		$SQL = "UPDATE comments SET correct = correct+1 WHERE id = ${id}";
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
mysql_close($db_handle);
?>
