#!/usr/local/bin/perl5
# Date de création : Tue Jun 29 07:03:14 1999
# par : Olivier Bouteille (oli@localhost.oleane.com)

use Tk; 
use Tk::After;

$m = new MainWindow;
$c = $m->Canvas->pack;
$m->Button(-text,"cancel",
	   -command => sub {
	     for ($m->after('info')) { print "$_\n";}
	     for ($c->after('info')) { $c->Tk::after('cancel' => $_);}
	   })->pack;;

my $r = $c->repeat(500,sub { print "after 500\n"});

print join(',',@$r)."\n";


MainLoop;

# Local Variables: ***
# mode: perl ***
# End: ***
