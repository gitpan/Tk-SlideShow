#!/usr/local/bin/perl5
# Date de création : Tue Jun 29 07:03:14 1999
# par : Olivier Bouteille (oli@localhost.oleane.com)

use Tk; 

$m = new MainWindow;
$c = $m->Canvas->pack;
$x = 0;
$c->createOval(0,0,100,100,-tags,'aaa');
$m->Button('-text','xxx',-command,
	   sub {
	     $x += 5;
	     $c->coords('aaa',$x,$x,100,100);
	   })->pack;
MainLoop;


# Local Variables: ***
# mode: perl ***
# End: ***
