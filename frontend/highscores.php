<?php include 'header.php'; ?>
<div id="main">
<div id="wflf-content-box">
<div id="wflf-top-ten-table">
<?php switch ($_GET['paper']) {
	case 'guardian':
		$table = 'guardian';
		break;
	case 'mail':
		$table = 'mail';
		break;
	default:
		die('Malformed, malformed!');
}
?>
<?php include "highscores_" . $table . ".php"; ?>
</div>
</div>
<div id="response"></div>
</div>
<?php include 'footer.php'; ?>
