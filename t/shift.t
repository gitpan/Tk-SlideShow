
use Tk::SlideShow;
use strict;

chdir('t');
print "1..4\n";	
my $p = Tk::SlideShow->init(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->can, $p->h, $p->w);

$p->add('left', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_left(map {"shift/i$_"}(1..10));
	  for (1..10) {$p->shiftarrive;}
	  print "ok 1\n";
	});
$p->add('right', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_right(map {"shift/i$_"}(1..10));
	  for (1..10) {$p->shiftarrive;}
	  print "ok 2\n";
	});
$p->add('top', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_top(map {"shift/i$_"}(1..10));
	  for (1..10) {$p->shiftarrive;}
	  print "ok 3\n";
	});
$p->add('bottom', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_bottom(map {"shift/i$_"}(1..10));
	  for (1..10) {$p->shiftarrive;}
	  print "ok 4\n";
	});

if (grep /^-abstract$/,@ARGV) {
  $p->latexabstract("abstract.tex");
  exit 0;
}
			      

$p->current($_[0] || 0);

if (@ARGV) {
  $p->play;
} else {
  $p->play(1);
}
