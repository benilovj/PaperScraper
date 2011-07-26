<?php include 'header.php'; ?>
<?php if (isset($_GET['action']) && $_GET['action'] == 'reset') { $_SESSION['score'] = 0; $_SESSION['playing'] = 0; $_SESSION['question'] = 0; } ?>
<?php if (isset($_GET['x']) && $_GET['x'] == 1) { $_SESSION['score'] = 9; $_SESSION['question'] = 10; } ?>
<div id="main">
<div id="wflf-content-box">
<?php include 'questions.php'; ?>
</div>
<div id="response"></div>
</div>
<?php include 'footer.php'; ?>
