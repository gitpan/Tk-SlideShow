
use Tk::SlideShow;
use strict;

chdir('t');
print "1..4\n";	
my $p = Tk::SlideShow->init(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->can, $p->h, $p->w);

$p->add('dblarrow', 
	sub { 
	  $p->newDblArrow($p->Text('id1','TOTO'), $p->Text('id2','TITI'));
	  $p->load ;
	  print "ok 1\n";
	});

$p->add('arrow', 
	sub {
	  my $last = $p->Text('i0','Origin');
	  for my $i (1..10) {
	    my $cur = $p->Text("i$i","Text$i");
	    $p->newArrow($last,$cur);
	    $last = $cur;
	  }
	    
	  $p->load ;
	  print "ok 2\n";
	});

$p->add('link',
	sub {
	  my $last = $p->Text('i0','Origin');
	  for my $i (1..10) {
	    my $cur = $p->Text("i$i","Text$i");
	    $p->newLink($last,$cur);
	    $last = $cur;
	  }
	  $p->load ;
	  print "ok 3\n";
	  
	}
);
$p->add('org',
	sub {
	  my $last = $p->Text('i0','Origin');
	  for my $i (1..10) {
	    my $cur = $p->Text("i$i","Text$i");
	    $p->newOrg($last,$cur);
	    $last = $cur;
	  }
	  $p->load ;
	  print "ok 4\n";
	  
	}
);
$p->current($_[0] || 0);
if (@ARGV) {
  $p->play;
} else {
  $p->play(1);
}
