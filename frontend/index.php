<?php include 'header.php'; ?>
<?php if (isset($_GET['action']) && $_GET['action'] == 'reset') { session_unset(); } ?>
<div id="main">
<div id="wflf-content-box">
<?php include 'questions.php'; ?>
</div>
<div id="response"></div>
</div>
<?php include 'footer.php'; ?>
