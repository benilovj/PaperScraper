<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
   "http://www.w3.org/TR/html4/strict.dtd">
<HTML>
<head>
<title>Mail or Guardian?</title>
<link rel="stylesheet" href="stylesheet.css" />
<link href='http://fonts.googleapis.com/css?family=Geo&v2' rel='stylesheet' type='text/css'>
<link href='http://fonts.googleapis.com/css?family=Ovo&v2' rel='stylesheet' type='text/css'>
<!--[if !IE 7]>
	<style type="text/css">
		#wrap {display:table;height:100%}
	</style>
<![endif]-->
<script src="//ajax.googleapis.com/ajax/libs/jquery/1.6.1/jquery.min.js" type="text/javascript"></script>
<script src="comment-ajax.js" type="text/javascript"></script>
<script src="colours.js" type="text/javascript"></script>
<script type="text/javascript">

  var _gaq = _gaq || [];
  _gaq.push(['_setAccount', 'UA-24770572-1']);
  _gaq.push(['_trackPageview']);

  (function() {
    var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
    ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
    var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
  })();

</script>
</head>
<body>
<?php session_start(); ?>
<div id="wrap">
<div id="header">
<div id="branding">
<h2 class="systemfont"><a href="index.php">Mail or Guardian?</a></h2>
<p class="tagline">An absurd guessing game</p>
</div>
<?php if (!isset($_SESSION['playing'])) { $_SESSION['playing'] = 0; } ?>
<?php if ($_SESSION['playing'] == 1 && isset($_SESSION['question']) && $_SESSION['question'] > 1) { ?>
<div id="startbutton">
	 <a href="index.php?action=reset" class="systemfont buttonlike light-bg">Start again</a></div>
<?php } elseif (isset($_SESSION['restarting']) && $_SESSION['restarting'] == 1) { $_SESSION['playing'] = 1; $_SESSION['question'] = 1; ?>
	 <!-- <a href="index.php" class="systemfont buttonlike red-bg">Start</a></div> -->
<?php } ?>
<div id="menu">
<ul>
<li><a href="what.php">what!?</a></li> 
<li><a href="why.php">why?</a></li> 
<li><a href="how.php">how?</a></li>
<li><a href="rankings.php?paper=mail">top Mail comments</a></li>
<li><a href="rankings.php?paper=guardian">top Guardian comments</a></li>
</ul>
</div>
</div>
