
use Tk::SlideShow;
use strict;

chdir('t');
print "1..5\n";	
my $p = Tk::SlideShow->init(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->can, $p->h, $p->w);

$p->add('left', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_left(map {"shift/i$_"}(1..10));
	  for (1..10) {$p->shiftaction;}
	  print "ok 1\n";
	});
$p->add('right', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_right(map {"shift/i$_"}(1..10));
	  for (1..10) {$p->shiftaction;}
	  print "ok 2\n";
	});
$p->add('top', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_top(map {"shift/i$_"}(1..10));
	  for (1..10) {$p->shiftaction;}
	  print "ok 3\n";
	});
$p->add('bottom', 
	sub {
	  for (1..10) {$p->Text("shift/i$_","Text$_");}
	  $p->load('shift') ;
	  $p->a_bottom(map {"shift/i$_"}(1..10));
	  for (1..10) {$p->shiftaction;}
	  print "ok 4\n";
	});
$p->add('multipos', 
	sub {
	  my $s = $p->Compuman("t");
	  my @a;
	  my $div = 3;
	  for my $i (0..($div-1)) {
	    for my $j (0..($div-1)) {
	      push @a,int($i*$w/$div),int($j*$h/$div);
	    }
	  }
	  $p->a_multipos('t',$div*$div - 1,-speed,1000,-steps, 5);
	  $s->multipos(@a);
	  for (1..$div**2) {$p->shiftaction;}
	  $p->a_multipos('t',$div*$div - 1,-speed,500,-steps, 10);
	  $s->multipos(@a);
	  for (1..$div**2) {$p->shiftaction;}
	  $p->a_multipos('t',$div*$div - 1);
	  $s->multipos(@a);
	  for (1..$div**2) {$p->shiftaction;}
	  print "ok 5\n";
	});

if (grep /^-abstract$/,@ARGV) {
  $p->latexabstract("abstract.tex");
  exit 0;
}

$p->current($ARGV[0] || 0);

if (@ARGV) {
  $p->play;
} else {
  $p->play(1);
}
