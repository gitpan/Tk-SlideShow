use strict;

use Tk;
use Tk::Xlib;
use Tk::After;
use Tk::Animation;
use Tk::Font;
use X11::Protocol;


$SIG{__DIE__} = sub { print &pile;};

sub pile {
  my $i=0;
  my $str;
  while(my ($p,$f,$l) = caller($i)) {
    $str .= "\t$f:$l ($p) \n";
    $i++;
  } 
  return $str;
}

package Tk::SlideShow;

use vars qw($VERSION);

$VERSION='0.02';

#
# Class to manage a dictionnary of objects
# ---------------------------------------
# DICT
# ---------------------------------------
package Tk::SlideShow::Dict;
no strict 'refs';
sub Exists {my ($class,$cle) = @_; return ${$class."::dict"}{$cle};}

sub Get {
  my ($class,$cle) = @_;
  warn "$class('$cle') unknown\n" unless exists ${$class."::dict"}{$cle};
  return ${$class."::dict"}{$cle} || $class->null;
}

sub Each {my $class = shift; return (each %{$class."::dict"})[1];}
sub All {my $class = shift; return values (%{$class."::dict"});}
sub Set {my ($class,$cle,$val) = @_; ${$class."::dict"}{$cle} = $val;}
sub Del {my ($class,$cle) = @_; delete ${$class."::dict"}{$cle};}

sub var_getset{
  my ($s,$k,$v) = @_;
  if (defined $v) {$s->{$k} = $v; return $s;}
  else            {               return $s->{$k} ;}
};


#------------------------------------------------
package Tk::SlideShow;
my ($can,$H,$W,$xprot,$present);
my $mw;
my $mode = 'X11';
my $family = "charter";
use vars qw($inMainLoop $nextslide $jumpslide);
$nextslide = 0;
sub var_getset{
  my ($s,$k,$v) = @_;
  if (defined $v) {$s->{$k} = $v; return $s;}
  else            {               return $s->{$k} ;}
};
sub family {
  my ($class,$newfamily) = @_;
  if (defined $newfamily) {$family = $newfamily;}
  return $family;
}
sub f {return $can->Font('family'  => $family, point   => int(150*(shift || 1)));}
sub ff {return $can->Font('family'  => 'courier', point   => int(250*(shift || 1)));}
sub f0_5  {return  $can->Font('family'  => $family, point   => 200);}
sub f1    {return  $can->Font('family'  => $family, point   => 250);}
sub f1_5  {return  $can->Font('family'  => $family, point   => 375);}
sub ff0_5 {return $can->Font('family'  => "courier", point   => 200);}
sub ff1   {return $can->Font('family'  => "courier", point   => 250);}
sub ff2   {return $can->Font('family'  => "courier", point   => 350);}
sub ff3   {return $can->Font('family'  => "courier", point   => 550);}
sub f2    {return  $can->Font('family'  => $family, point   => 500);}
sub f3 {return  $can->Font('family'  => $family, point => 750);}
sub f4 {return  $can->Font('family'  => $family, point => 1000);}
sub f5 {return  $can->Font('family'  => $family, point => 1250);}


sub mw { return $mw;}
sub can {return $can }
sub h { return $H}
sub w { return $W}


sub title_ne {
  my ($s,$texte) = @_;
  $can->createText($W,0,'-text',$texte,
		   -anchor => 'ne', -font => $s->f1, -fill => 'red');
}
sub title_se {
  my ($s,$texte) = @_;
  $can->createText($W,$H,'-text', $texte,
		   -anchor => 'se', -font => $s->f1, -fill => 'red');
}

# internal function for internals needs
my $current_item = "";

sub enter {
  $current_item = ($can->gettags('current'))[0]; 
  # print "entering $current_item\n"; 
}
sub leave {
  # print "leaving $current_item\n"; 
  $current_item = "";
}

sub exec_if_current {
  my ($c,$tag,$fct,@ARGS) = @_;
#  print join('_',@_)."\n";
  if ($current_item eq $tag) {\&$fct(@ARGS);}
}

sub init {
  my ($class,$w,$h) = @_;
  my $m = new MainWindow;
  my $c = $m->Canvas;
  $can = $c;
  $mw = $m;
  $present = bless { 'current' => 0, 'mw' => $m, 'fond'=>'ivory',
		   'slides_names' => {}};
  # util pour forcer le d�placeement de la souris (pointer)
  $xprot = X11::Protocol->new();
  $H = $h || $m->Display->ScreenOfDisplay->HeightOfScreen;
  $W = $w || $m->Display->ScreenOfDisplay->WidthOfScreen;
  print ("H=$H, W=$W\n");
  $m->geometry('-0-20');
  $c->configure(-height,$H,-width,$W);
  $c->pack;
  $present->init_bindings;
  $present->init_choosers;
  return $present;
}

my $sens = 1;
my $setnextslide =  sub { $nextslide = 1;$sens = 1;};
my $setprevslide =  sub { $nextslide = 1;$sens = -1};

sub current {
  my ($class,$val) = @_;
  if (defined $val) {
    my $c;
    if ($val =~ /^\d+$/) {
      $c = $val;
    } else { 
      $c = $present->{'slides_names'}{$val} || 0;
    }
    $present->{'current'} = $c;
  } else {
    return $present->{'current'};
  }
}

sub warp {
  my ($class,$id,$event,$dest) = @_;
  $can->bind($id,$event, sub {$present->current($dest); $Tk::SlideShow::jumpslide = 1; })
}

sub save {
  $mw->Tk::bind('Tk::SlideShow','<s>', [\&Tk::SlideShow::Placeable::save,$present]);
}

sub init_choosers {
  Tk::SlideShow::Sprite->initFontChooser;
  Tk::SlideShow::Sprite->initColorChooser;
}

sub load {
  shift;
  my $numero = $present->currentName;
  my $filename = shift || "slide-$numero.pl";
  print "Loading $filename ...";
  if (-e $filename) {
    do "./$filename";
    warn $@ if $@;
  }
  print "done\n";
}

sub currentName {
  my $c = $present->current;
  my %hn = %{$present->{'slides_names'}};
  while (my ($k,$v) = each %hn)  {
    return $k if $v eq $c;
  }
  return $c+1;
}

#internals
sub nbslides {shift; return scalar(@{$present->{'slides'}})}

sub bg {
  my ($class,$v) = @_;
  if (defined $v) {$present->{'fond'} = $v;} else {return $present->{'fond'};}
}

# internals
sub postscript {
  shift;
  my $nu = $present->current;
  $can->postscript(-file => "slide$nu.ps",
		   -pageheight => "29.7c",
		   -pagewidth => "21.0c",
		   -rotate => 1);
}

#internals
sub warppointer {
  my ($x,$y) = @_;
  $xprot->WarpPointer(0, hex($can->id), 0, 0, 0, 0, $x, $y);
}


sub init_bindings {
  shift;
  my ($m,$c) = ($mw,$can);
  $m->bindtags(['Tk::SlideShow',$m,ref($m),$m->toplevel,'all']);
  $c->bindtags(['Tk::SlideShow']);#,$c,ref($c),$c->toplevel,'all']);
  $c->bind('all', '<Any-Enter>' => \&enter);
  $c->bind('all', '<Any-Leave>' => \&leave);
  $c->CanvasFocus;
  $m->Tk::bind('Tk::SlideShow','<3>', \&shiftaction);
  $m->Tk::bind('Tk::SlideShow','<Control-3>', \&unshiftaction);
  $m->Tk::bind('Tk::SlideShow','<KeyPress-space>', $setnextslide);
  $m->Tk::bind('Tk::SlideShow','<KeyPress-BackSpace>', $setprevslide);
  $m->Tk::bind('Tk::SlideShow','<Alt-q>', sub {$m->destroy; exit});
  $m->Tk::bind('Tk::SlideShow','<Meta-q>', sub {$m->destroy; exit});
  $m->Tk::bind('Tk::SlideShow','<q>', sub {$m->destroy; exit});
  $m->Tk::bind('Tk::SlideShow','<p>', \&postscript);
}

#internals
sub trace_fond {
  shift;
  my $m = $mw;
  if (ref($present->bg) eq 'CODE') {
    &{$present->bg};
  } else {
    $can->configure(-background, $present->bg);
  }
  my $t = $present->currentName. "(".($present->current+1)."/". $present->nbslides.")";

  $can->createText(10,$H - 10,'-text',$t,-anchor,'sw',
		-font, Tk::SlideShow->f1);
}
#internals
sub wait {
  shift;
  while (Tk::MainWindow->Count)
    {
      Tk::DoOneEvent(0);
      last if $nextslide || $jumpslide;
    }
#  print "Je d�bloque\n";
  $nextslide = 0;
}

sub clean { 
  my $class = shift;
  $can->delete('all'); 
  $present->{'action'}= [];
  $present->{'save_action'}= [];
  Tk::SlideShow::Placeable->Clean;
  return $class;
}

sub a_warp {
  my ($class,@tags) = @_;
  for my $tag (@tags) {
    my $bottom = ($can->bbox($tag))[3];
    $can->move($tag,0,0-$bottom);
    push @{$present->{'action'}},[$tag,'a_warp',$bottom];
  }
  return $class;
}

sub a_top {
  my ($class,@tags) = @_;
  return unless $mode eq 'X11';
  for my $tag (@tags) {
    my $bottom = ($can->bbox($tag))[3];
    $can->move($tag,0,0-$bottom);
    push @{$present->{'action'}},[$tag,'a_top',$bottom];
  }
  return $class;
}
sub a_bottom {
  my ($class,@tags) = @_;
  return unless $mode eq 'X11';
  for my $tag (@tags) {
    my $top = ($can->bbox($tag))[1];
    $can->move($tag,0,$H-$top);
    push @{$present->{'action'}},[$tag,'a_bottom',$top];
  }
  return $class;
}
sub a_left {
  my ($class,@tags) = @_;
  return unless $mode eq 'X11';
  for my $tag (@tags) {
    my $right = ($can->bbox($tag))[2];
    $can->move($tag,0-$right,0);
    push @{$present->{'action'}},[$tag,'a_left',$right];
  }
  return $class;
}
sub a_right {
  my ($class,@tags) = @_;
  return unless $mode eq 'X11';
  for my $tag (@tags) {
    my $left = ($can->bbox($tag))[0];
    $can->move($tag,$W-$left,0);
    push @{$present->{'action'}},[$tag,'a_right',$left];
  }
  return $class;
}

sub a_multipos {
  my ($class,$tag,$nbpos,@options) = @_;
  for my $i (1..$nbpos) {
    push @{$present->{'action'}},[$tag,'a_chpos',$i,@options];
  }
}

sub shiftaction {
  my $a = shift @{$present->{'action'}};
  my $c = $can;
  return unless $a;
  push @{$present->{'save_action'}},$a;
  my ($tag,$maniere,$dest) = @$a;
  my $step = 50;
  $maniere eq 'a_top'  and 
    do {for(my $i=0;$i<$step;$i++){$c->move($tag,0,$dest/$step); $c->update;}};
  $maniere eq 'a_bottom' 
    and do {for(my $i=0;$i<$step;$i++){$c->move($tag,0,($dest-$H)/$step); $c->update;}};
  $maniere eq 'a_left'
    and do {for(my $i=0;$i<$step;$i++){$c->move($tag,$dest/$step,0); $c->update;}};
  $maniere eq 'a_right'
    and do {for(my $i=0;$i<$step;$i++){$c->move($tag,($dest-$W)/$step,0); $c->update;}};
  $maniere eq 'a_warp'
    and do {$c->move($tag,0,$dest);};
  $maniere eq 'a_chpos' and 
    do {
      my ($tag,$m,$i,@options) = @$a;
      #print "doing $m on tag $tag i=$i\n";
      my $sprite = Tk::SlideShow::Sprite->Get($tag);
      $sprite->chpos($i,@options);
    };
      

}
sub unshiftaction {
  my $a = pop @{$present->{'save_action'}};
  my $c = $can;
  return unless $a;
  unshift @{$present->{'action'}},$a;
  my ($tag,$maniere,$dest) = @$a;
  my $step = 50;
  $maniere eq 'a_top'  and
    do {for(my $i=0;$i<$step;$i++){$c->move($tag,0,- $dest/$step); $c->update;}};
  $maniere eq 'a_bottom'
    and do {for(my $i=0;$i<$step;$i++){$c->move($tag,0,($H-$dest)/$step); $c->update;}};
  $maniere eq 'a_left'
    and do {for(my $i=0;$i<$step;$i++){$c->move($tag,- $dest/$step,0); $c->update;}};
  $maniere eq 'a_right'
    and do {for(my $i=0;$i<$step;$i++){$c->move($tag,($W-$dest)/$step,0); $c->update;}};
  $maniere eq 'a_warp'
    and do {$c->move($tag,0,-$dest);};
  $maniere eq 'a_chpos' and 
    do {
      my ($tag,$m,$i,@options) = @$a;
      return unless $i>0;
      $i--;
      #print "undoing $m on tag $tag i=$i\n";
      my $sprite = Tk::SlideShow::Sprite->Get($tag);
      $sprite->chpos($i,@options);
    };

}

sub start_slide { $present->clean->trace_fond; }

sub fin {
  $present->add(sub {
	    my $c = $can;
	    $present->start_slide;
	    $can->createText($W/2,$H/2, '-text',"FIN", -font, Tk::SlideShow->f5);
	  });
}

sub add {
  my ($class,$name,$sub) = @_;
  if (@_ == 2) {
    $sub = $name;
    $name = @{$present->{'slides'}};
  }
  
  my $diapo = Tk::SlideShow::Diapo->New($name,$sub);
  push @{$present->{'slides'}},$diapo;

  if (@_ == 3) { 
    $present->{'slides_names'}{$name} = @{$present->{'slides'}} - 1 ;
  }

  return $diapo;
}


sub play {
  my ($class,$timetowait) = @_;
  my $current = $present->current;
  my $nbslides = @{$present->{'slides'}};
  while(1) {
    $jumpslide = 0;
    $current =  $present->current;
    my $diapo = $present->{'slides'}[$current];
    print "Executing slide number $current\n";
    $present->start_slide;
    &{$diapo->code};
    if (defined $timetowait) {
      print "Sleeping $timetowait second\n";
      $mw->update;
      sleep $timetowait;
      last if $current == $nbslides-1 ;
      print "Next one;\n";
    } else {
      $present->wait;
    }
#   print "jumpslide = $jumpslide\n";
    next if $jumpslide;
    $current += $sens;
    $current %= $nbslides;
    $present->current($current);
  }
}

sub latexheader {
  my ($p,$value) = @_;

  return ($p->{'latexheader'} || 
	  "\\documentclass{article}
\\usepackage{graphicx}
\\begin{document}
")
    unless defined $value;

  $p->{'latexheader'} = $value;
  return $p;
}

sub latexfooter {
  my ($p,$value) = @_;

  return ($p->{'latexfooter'} || 
	  "\\end{document}")
    unless defined $value;

  $p->{'latexfooter'} = $value;
  return $p;
}

# saving diapo in a single latex file
sub latex {
  my ($s,$latexfname) = @_;
  $mode ='latex';
  my $nbdiapo = @{$present->{'slides'}};

  open(OUT,">$latexfname") or die "$!";
  print OUT latexheader();
  for (my $i=0; $i<$nbdiapo; $i++) {
    $present->current($i);
    print "Chargement de la diapo : ".$s->currentName."\n";
    $s->start_slide;
    my $diapo = $present->{'slides'}[$i];
    &{$diapo->code};
    $mw->update;
    my $file = 'slide'.$diapo->name.'.ps';
    $can->postscript(-file => $file);
    print OUT "\\includegraphics[width=\\textwidth]{$file}\n";
    print OUT "".$diapo->latex;
    print OUT "\n\\newpage";
  }
  print OUT latexfooter();
  close OUT;
  
}
# make an abstract of slides
sub latexabstract {
  my ($s,$latexfname) = @_;
  $mode ='latex';
  my $nbdiapo = @{$present->{'slides'}};

  open(OUT,">$latexfname") or die "$!";
  print OUT latexheader();
  for (my $i=0; $i<$nbdiapo; $i++) {
    $present->current($i);
    print "Chargement de la diapo : ".$s->currentName."\n";
    $s->start_slide;
    my $diapo = $present->{'slides'}[$i];
    &{$diapo->code};
    $mw->update;
    my $file = 'slide'.$diapo->name.'.ps';
    $can->postscript(-file => $file);
    print OUT "\\noindent\\includegraphics[width=.5\\textwidth]{$file}\n";
    print OUT "";
  }
  print OUT latexfooter();
  close OUT;
}


# wrappers

sub newSprite {shift; return Tk::SlideShow::Sprite->New(@_);}
sub newLink   {shift; return Tk::SlideShow::Link->New(@_);  }
sub newArrow   {shift; return Tk::SlideShow::Arrow->New(@_);  }
sub newDblArrow   {shift; return Tk::SlideShow::DblArrow->New(@_);  }
sub newOrg    {shift; return Tk::SlideShow::Org->New(@_);  }


sub Text {return Tk::SlideShow::Sprite::text(@_);}
sub Framed {return Tk::SlideShow::Sprite::framed(@_);}
sub Image {return Tk::SlideShow::Sprite::image(@_);}
sub Anim {return Tk::SlideShow::Sprite::anim(@_);}

sub TickerTape {return Tk::SlideShow::Sprite::tickertape(@_);}
sub Compuman {return Tk::SlideShow::Sprite::compuman(@_);}

package Tk::SlideShow::Diapo;

sub New {
  my ($class,$name,$code) = @_;
  my $s =  bless { 'name' => $name, 
		   'latex'=> 'No documentation',
		   'code' => $code
		 };
  return $s;
}

sub name { return (shift)->{'name'};}
sub code { return (shift)->{'code'};}

sub latex { my ($s,$v) = @_;
	    if (defined ($v)) { $s->{'latex'} = $v; return $s; }
	    return $s->{'latex'}
	  }


#----------------------------------------
# PLACEABLE
#----------------------------------------
#
# Classe de gestion des objets placables sur le canvas par l'utilisateur
# et sauvegardeable dans une fichier sous la forme d'un script perl.
#


package Tk::SlideShow::Placeable;
use vars qw(@ISA @classes);
@ISA = qw(Tk::SlideShow::Dict);

sub x { return (shift)->{'x'};}
sub y { return (shift)->{'y'};}

sub no { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->can->bbox($s->id);
  return ($x1,$y1);
}
sub n { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->can->bbox($s->id);
  return (($x1+$x2)/2,$y1);
}
sub ne { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->can->bbox($s->id);
  return ($x2,$y1);
}
sub e { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->can->bbox($s->id);
  return ($x2,($y1+$y2)/2);
}
sub se { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->can->bbox($s->id);
  return ($x2,$y2);
}
sub s { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->can->bbox($s->id);
  return (($x1+$x2)/2,$y2);
}
sub so { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->can->bbox($s->id);
  return ($x1,$y2);
}
sub o { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->can->bbox($s->id);
  return ($x1,($y1+$y2)/2);
}

sub pos {
  my $s = shift;
  my $pos = shift;
  $pos = ( $pos + 8 ) % 8;
  return $s->no if $pos == 0;
  return $s->n  if $pos == 1;
  return $s->ne if $pos == 2;
  return $s->e  if $pos == 3;
  return $s->se if $pos == 4;
  return $s->s  if $pos == 5;
  return $s->so if $pos == 6;
  return $s->o  if $pos == 7;
  return (0,0);
}

sub addLink {
  my ($s,$l) = @_;
  push @{$s->{'link'}},$l;
}

sub links { return @{(shift)->{'link'}};}


sub id { return (shift)->{'id'};}

sub New {
  my ($class,$id) = @_;
  die "An mandatory id is needed !" unless defined $id;
  my $s = bless {'x'=>Tk::SlideShow->w/2,'y'=>Tk::SlideShow->h/2,'id'=>$id};
  $class->Set($id,$s);
  return $s;
}

sub AddClass{
  shift;
  push @classes,@_;
}

sub evalplace {
  my $s = shift;
  die "La m�thode 'evalplace' doit �tre red�finie pour la classe ".ref($s)." et ne l'est pas, apparament\n";
}
use Cwd;


sub save {
  shift;
  my $slides = shift;
  my $numero = $slides->currentName;
  my $dfltfname = "slide-$numero.pl";
  my %files = ();
  print "saving slide $numero\n";
  foreach my $cl (@classes) {
    #print "Scanning class $cl\n";
    while (my $s = $cl->Each) {
      my $id = $s->id;
      next if $id eq '__null__';
      $id =~ s/['\\]/\\$&/g;
      my $fname = ($id =~ m|/|) ? $`: $dfltfname ;
      $files{$fname} .= "$cl->Get('$id')->".$s->evalplace.";\n";
    }
  }
  while(my($k,$v) = each %files) {
    print "Generating file  $k\n";
    open(OUT,">$k") or die;
    print OUT $v;
    close OUT;
  }
};


sub Clean {
  foreach my $cl (@classes) {
    while (my $s = $cl->Each) {
      $cl->Del($s->id);
    }
  }
}
sub pan {
  my ($s,$button) = @_;
  my $c = Tk::SlideShow->can;
  my $id = $s->id;
  $c->bind($id,"<Control-$button>", sub {$c->lower($id)});
  $c->bind($id,"<$button>", 
	   sub { 
	       my $e = (shift)->XEvent;
#	       my $id = $s->id;
	       $c->raise($id);
	       ($s->{'sx'},$s->{'sy'}) = ($c->canvasx($e->x),$c->canvasy($e->y));
	     });
  $c->bind($id,"<B$button-Motion>", 
	   sub {
	     my $e = (shift)->XEvent;
#	     my $id = $s->id;
	     my ($nx,$ny) = ($c->canvasx($e->x),$c->canvasy($e->y));
	     my ($dx,$dy) = ($nx-$s->{'sx'},$ny-$s->{'sy'});
	     $c->move($id, $dx,$dy);
	     ($s->{'sx'}, $s->{'sy'}) = ($nx,$ny);
	     $s->{'x'} += $dx; $s->{'y'} += $dy; 
	     for my $l ($s->links) {$l->show;}

	   });
  return $s;
}       


package Tk::SlideShow::Sprite;
use vars qw(@ISA); @ISA = qw(Tk::SlideShow::Placeable);

Tk::SlideShow::Placeable->AddClass('Tk::SlideShow::Sprite');

# keeping memory of tag to sprite association
my %tagtosprite;

sub New {
  my ($class,$id) = @_;
  my $s = $class->SUPER::New($id);
  $s->{'link'}= [];
  bless $s;
  $tagtosprite{$id} = $s;
  return $s;
}

sub getSpriteof {
  my ($class,$tag) = @_;
  return $tagtosprite{$tag} if exists $tagtosprite{$tag};
  return undef;
}


sub null {
  my ($class) = @_;
  my $s = $class->SUPER::New('__null__');
  bless $s;
  return $s;
}

sub evalplace {
  my $s = shift;
  my $ret = "";
  if (exists $s->{'multipos'}) {
    $s->{'multipos'}[$s->{'curposindex'}] = [$s->x,$s->y];
    $ret .= "multipos(". join(',',map {join(',',@$_)} @{$s->{'multipos'}}). ")";
  } else {
    $ret .= sprintf("place(%d,%d)",$s->x,$s->y);
  }
  $ret .= sprintf("->fontFamily('%s')",$s->fontFamily) 
    if exists $s->{'-font'} && $s->{'-font'};
  $ret .= sprintf("->color('%s')",$s->color) 
    if exists $s->{'-color'} && $s->{'-color'};
  return $ret;
}


sub place {
  my ($s,$x,$y) = @_;
  my ($dx,$dy) = ($x-$s->x,$y-$s->y);
  Tk::SlideShow->can->move($s->id,$dx,$dy);
  $s->{'x'} = $x;
  $s->{'y'} = $y;
  return $s;
}

sub multipos {
  my ($s,@xy) = @_;
  my $i = 0;
  while(@xy) {$s->{'multipos'}[$i] = [splice(@xy,0,2)]; $i++}
  $s->place(@{$s->{'multipos'}[0]});
}

sub chpos {
  my ($s,$i,%options) = @_;
  my $tag = $s->{'id'};
  my $lasti;
  $s->{'multipos'} = [] unless exists $s->{'multipos'};

  if (exists $s->{'curposindex'}) {
    $lasti = $s->{'curposindex'};
  } else {
    $lasti = 0;
  }
  #print "Saving pos $lasti for $tag\n";
  my ($x,$y) = ($s->x,$s->y);
  $s->{'multipos'}[$lasti] = [$x,$y];

  #print "moving tag $tag to position $i\n";
  $s->{'multipos'}[$i] = [$H/2,$W/2] 
    unless defined $s->{'multipos'}[$i];
  my ($destx,$desty) = @{$s->{'multipos'}[$i]};
  # number of pixel per second
  my $speed = $options{'-speed'} || 500;
  my $distance = (($destx-$x)**2+($desty-$y)**2)**.5;
  #printf ("deplacement de %d,%d a $destx,$desty\n",$x,$y);
  my $steps = $options{'-steps'} || 50;
  my $step = int($distance/$steps);
  my $dt = $distance / $speed;
  #print "dt=$dt  distance=$distance step=$step\n";
  my ($x0,$y0) = ($x,$y);
  my $dx = ($destx-$x0)/$step;
  my $dy = ($desty-$y0)/$step;
  for (my $t=1; $t<=$step; $t++) {
    my $tx = $x0+$t*$dx;
    my $ty = $y0+$t*$dy;
    my ($tdx,$tdy)  = (int($tx-$x),int($ty-$y));
    $can->move($tag,$tdx,$tdy);
    $x += $tdx; $y += $tdy;
    $can->update;
    select(undef,undef,undef,$dt/$step);
  }
  ($s->{'x'},$s->{'y'}) = ($destx, $desty);
  $s->{'curposindex'} = $i;
}

sub text {
  shift;
  my $id = shift;
  my $text = shift;
  my $s = New('Tk::SlideShow::Sprite',$id);
  my $c = Tk::SlideShow->can;
  my $item = 
    $c->createText
      (Tk::SlideShow->w/2,Tk::SlideShow->h/ 2,'-text', $text,
       -font, Tk::SlideShow->f1, -tags,$id);
  $c->itemconfigure($item,@_);
  $s->{-font} = "";   bindfontchoosermenu($id);
  $s->{-color} = ""; bindcolorchoosermenu($id);
  $s->pan(1);
  return $s;
}

# managing font for Sprites with text
{
  my (%f,@f);
  my $fontmenu; my $lbox;
  my ($curit, $cursp);
  sub initFontChooser {
    open(FONT,"xlsfonts |") or die;
    while(<FONT>) {next unless /^-/; my @a = split /-/; $f{$a[2]} = 1;}
    close (FONT);
    $fontmenu = $mw->Menu;
    my $lb = $fontmenu->Scrolled('Listbox')->pack;
    $lbox = $lb->Subwidget('listbox');
    $lbox->bind('<Double-1>',
		sub {
		  my $fontindex = $lbox->curselection;
		  if (defined $curit and defined $cursp) {
		    my $font = $can->itemcget($curit,-font);
		    $font->configure('-family',$f[$fontindex]);
		    #print "on passe a la fontindex=$fontindex :".$f[$fontindex]."\n";
		    $cursp->{-font} = $f[$fontindex];
		  }
		  #print "item = $curit\n";
		  $fontmenu->unpost;
		  $curit =$cursp = undef;
		});
    @f = sort keys %f;
    $lb->insert('end',@f);
  }
  sub bindfontchoosermenu {
    my $tagorid = shift;
    my $c = Tk::SlideShow->can;
    $c->bind($tagorid,'<Double-1>',
	     sub {
	       my $e = (shift)->XEvent;
	       $curit = $current_item;
	       $cursp = $tagtosprite{$curit} 
		 if defined $curit;
	       $fontmenu->post($e->X,$e->Y);
	       }
	    );
  }
  sub fontFamily {
    my ($s,$fam) = @_;
    return $s->{-font} unless defined $fam;
    $s->{-font} = $fam;
    my $font = $can->itemcget($s->{'id'},-font);
    $font->configure('-family',$fam);
    return $s;
  }
}
# managing color for Sprites with color
{
  my (%color,@color);
  my $colormenu; my $lbox;
  my ($curit, $cursp);
  sub initColorChooser {
    $colormenu = $mw->Menu;
    @color = qw(red green blue yellow black purple magenta);
    my $lb = $colormenu->Scrolled('Listbox')->pack;
    $lbox = $lb->Subwidget('listbox');
    $lb->insert('end',@color);
    $lbox->bind('<Double-1>',
		sub {
		  my $colorindex = $lbox->curselection;
		  if (defined $curit and defined $cursp) {
		    $can->itemconfigure($curit,-fill,$color[$colorindex]);
		    #print "on passe a la couleur=$colorindex :".$color[$colorindex]."\n";
		    $cursp->{-color} = $color[$colorindex] ;
		  }
		  #print "item = $curit\n";
		  $colormenu->unpost;
		  $curit =$cursp = undef;
		});
  }
  sub bindcolorchoosermenu {
    my $tagorid = shift;
    my $c = Tk::SlideShow->can;
    $c->bind($tagorid,'<Double-2>',
	     sub {
	       my $e = (shift)->XEvent;
	       $curit = $current_item;
	       $cursp = $tagtosprite{$curit} 
		 if defined $curit;
	       $colormenu->post($e->X,$e->Y);
	       }
	    );
  }
  sub color {
    my ($s,$col) = @_;
    return $s->{-color} unless defined $col;
    $s->{-color} = $col;
    $can->itemconfigure($s->{'id'},-fill,$col);
    #print "on met $s->{'id'} en $col\n";
    return $s;
  }
}

sub point {
  shift; my $id = shift;
  my $s = Tk::SlideShow::Sprite->New($id);
  my $c = Tk::SlideShow->can;
  my $item = 
    $c->createOval(qw(0 0 5 5),-fill,'blue', -tags ,$id);
  $s->pan(1);
  return $s;
}


sub anim {
  shift;
  my $id = shift;
  my $fn;
  if (not -e $id) {
    $fn = shift;
    die "je ne trouve pas $fn\n" unless -e $fn;
  } else { $fn = $id;}
  my $s = Tk::SlideShow::Sprite->New($id);
  $s->{'state'} = shift || 1;
  my $freq = shift || 200;
  my $c = Tk::SlideShow->can;
  my $mw = Tk::SlideShow->mw;
  my $im = $mw->Animation('-format' => 'gif',-file => $fn);
  $im->start_animation($freq) if $s->{'state'};
  $c->bind($id,'<3>',
	   [ sub { 
	       my ($c,$s,$im) = @_;
	       if ($s->{'state'}) {
		 #print "stopping ".$s->id."\n";
		 $im->stop_animation;
	       } else {
		 #print "starting ".$s->id."\n";
		 $im->start_animation($freq); 
	       }
	       $s->{'state'} =  1 - $s->{'state'};
	     },$s,$im]);
  $c->createImage(Tk::SlideShow->w/2,Tk::SlideShow->h/2,-image, $im, -tags,$id, @_);
  $s->pan(1);
  return $s;
}
sub image {
  shift;
  my $id = shift;
  my $s = Tk::SlideShow::Sprite->New($id);
  my $c = Tk::SlideShow->can;
  my $mw = Tk::SlideShow->mw;
  my $fn;
  if (not -e $id) {
    $fn = shift;
  } else {
    $fn = $id;
  }
  $mw->Photo($id,-file => $fn);
  $c->createImage(Tk::SlideShow->w/2,Tk::SlideShow->h/2,-image, $id, -tags,$id, @_);
  $s->pan(1);
  return $s;
}

sub window {
  shift;
  my $id = shift;
  my $s = Tk::SlideShow::Sprite->New($id);
  my $c = Tk::SlideShow->can;
  my $mw = Tk::SlideShow->mw;
  my $window = shift;

  $c->createWindow(Tk::SlideShow->w/2, Tk::SlideShow->h/2,
		   -window, $window, -tags,$id, @_);
  #printf("%s %s window\n",Tk::SlideShow->w/2, Tk::SlideShow->h/2);
  $s->pan(3);
  return $s;
}

sub hommeord {
  shift; # on supprime la classe
  my $s = Tk::SlideShow::Sprite->New(@_);
  my $c = Tk::SlideShow->can;
  my $id = $s->id;
  $c->createLine(qw(10 20 10 40 25 40 25 50),-width ,4,-fill, 'black', -tags ,$id); #chaise
  $c->createLine(qw(15 15 15 35 30 35 30 50 35 50),-width ,4,-fill,'blue', -tags ,$id);# corps 
  $c->createOval(qw(11 11 18 18),-fill,'blue', -tags ,$id);# tete
  $c->createLine(qw(15 25 30 25),-width ,4,-fill,'blue', -tags ,$id);# pieds
  $c->createLine(qw(30 27 40 22),-width ,4,-fill,'red', -tags ,$id);# clavier
  $c->createPolygon(qw(35 20 40 0 55 10 55 20),-width ,2,-fill,'red', -tags ,$id); # ecran
  $c->createLine(qw(45 20 45 30 35 30 35 30),-width ,2, -fill,'red', -tags ,$id);# support d'ecran
  $s->pan(1);
  return $s;  
}

sub moteur {
  shift;
  my $s = Tk::SlideShow::Sprite->New(@_);
  my $c = Tk::SlideShow->can;
  my $id = $s->id;

  $c->createOval(qw(0 0 50 50),-fill,'blue', -tags ,$id);
  $c->createText(qw(0 0),'-text',$id,-anchor,'e',-tags ,$id);
  my @ids;
  my @colors = qw(red blue);
  push @ids, $c->createLine(qw(10 10 40 40),-width ,10,-fill, 'red', -tags ,$id);
  push @ids, $c->createLine(qw(25 0 25 50),-width ,10,-fill, 'blue', -tags ,$id);
  push @ids, $c->createLine(qw(10 40 40 10),-width ,10,-fill, 'blue', -tags ,$id);
  push @ids, $c->createLine(qw(0 25 50 25),-width ,10,-fill, 'blue', -tags ,$id);
  $c->raise($ids[0]);
  $s->{'ids'} = [@ids];
  $s->{'toggle'} = 1;
  sub toggle {
    my $s = shift;
    my $c = Tk::SlideShow->can;
    $s->{'r'}->cancel if exists $s->{'r'};
    $c->itemconfigure ($s->{'ids'}[$s->{'toggle'}],-fill, 'blue');
    $s->{'toggle'}++; $s->{'toggle'} %= @{$s->{'ids'}};
    $c->itemconfigure ($s->{'ids'}[$s->{'toggle'}],-fill, 'red');
    $c->raise($s->{'ids'}[$s->{'toggle'}]);
    $s->{'r'} = $c->after(100,[\&toggle,$s]);
  }
  $c->bind($id,'<3>',
	   sub {
	     if (exists $s->{'r'}) {
	       $s->{'r'}->cancel;
	       delete $s->{'r'}
	     } else {
	       &toggle($s)
	     }
	   });
  toggle($s);
  $s->pan(1);
  return $s;
}

sub framed {
  shift;
  my ($id,$text) = @_;
  my $s = Tk::SlideShow::Sprite->New($id);
  my $c = Tk::SlideShow->can;
  my $t = $text || $id;
  my $idw = $c->createText(0,0,'-text',$t,
			   -justify, 'center',
			   -font => Tk::SlideShow->f1, -tags => $id);
  $c->createRectangle($c->bbox($idw), -fill,'light blue',-tags => $id);
  $c->raise($idw);
  $s->pan(1);
  return $s;
}
sub compuman {
  my ($p,$id) = @_;
  my $s = Tk::SlideShow::Sprite->New($id);
  my @o1 = (-width ,4,-fill, 'black', -tags ,$id);
  my @o2 = (-fill,'blue', -tags ,$id);
  my @o3 = (-width ,4,-fill,'red', -tags ,$id);
  $can->createLine(qw(10 20 10 40 25 40 25 50),@o1); #chair
  $can->createLine(qw(15 15 15 35 30 35 30 50 35 50),@o1); # body
  $can->createOval(qw(11 11 18 18),@o2); # head
  $can->createLine(qw(15 25 30 25),@o1); # feet
  $can->createLine(qw(30 27 40 22),@o3); # keyborad
  $can->createPolygon(qw(35 20 40 0 55 10 55 20),@o3); # ecran
  $can->createLine(qw(45 20 45 30 35 30 35 30),@o3); # 
  ($s->{'x'},$s->{'y'}) = (0,0);
  $s->pan(1);
  return $s;
}

sub tickertape {
  my ($p,$id,$text,$len,@options) = @_;

  my $spri = $p->newSprite($id)->pan(1);

  my $idw = $can->createText(0,0,
			     '-text',substr($text,0,$len), 
			     -tags => $id,
			     @options
			    );
  my @bbox = $can->bbox($id);
  my $larg = $bbox[2]-$bbox[0];
  my $haut = $bbox[3]-$bbox[1];
  my $bg = $can->cget(-background);
  my $scan = $mw->Canvas(-height,$haut,-width,$larg,-background,$bg);
  $can->createWindow($W/2,$H/2,'-anchor','nw','-window',$scan,'-tags',$id);
  $can->delete($idw);
  my @def = (-anchor, 'nw','-text',$text,'-tags' => $id, @options);
  $idw = $scan->createText(0,0,@def);
  @bbox = $scan->bbox($idw);
  my $txtwidth = $bbox[2];
  $scan->createText($txtwidth,0, @def);
  $can->createRectangle($can->bbox($id),-width,20,-outline,$bg,-tags,$id);
  sub tourne {
    my ($spri,$scan,$txtwidth) = @_;
    my $tag = $spri->id;
    $scan->move($tag,-5,0);
    $scan->move($tag, $txtwidth,0) if ($scan->bbox($tag))[2] < $scan->Width;
    $can->after(50,[\&tourne,$spri,$scan,$txtwidth]);
  }
  tourne($spri,$scan,$txtwidth);
  return $spri;
}


package Tk::SlideShow::Link;
@Tk::SlideShow::Link::ISA = qw(Tk::SlideShow::Placeable);
Tk::SlideShow::Placeable->AddClass('Tk::SlideShow::Link');

sub New {
  my ($class,$from,$to,$titre) = @_;
  $to = Tk::SlideShow::Sprite->point($from->id."-to") unless $to;
  my $id = sprintf("%s-%s",$from->id,$to->id);
  my $s =  bless {'from'=>$from, 'to'=>$to, 'id'=> $id, 'titre' => $titre || "",
		 'tpos' => 0, 'fpos' => 0};
  $class->Set($id,$s);
  $from->addLink($s);
  $to->addLink($s);
  $s->show;
  $s->bind;
  return $s;
}
sub bind {
  my $s = shift;
  my $c = Tk::SlideShow->can ;
  my $id = $s->id;
  my $movepos = sub {
    my $e = (shift)->XEvent;
    my ($id,$incr) = @_;
    $c->raise($id);
    my ($x,$y) = ($c->canvasx($e->x),$c->canvasy($e->y));
    if ((abs($s->fx - $x)+abs($s->fy-$y)) >
	(abs($s->tx - $x)+abs($s->ty-$y))) {
      $s->{'tpos'} += $incr;
      my ($x,$y) = $s->to->pos($s->tpos);
      Tk::SlideShow::warppointer($x,$y);
    } else {
      $s->{'fpos'} += $incr;
      my ($x,$y) = $s->from->pos($s->fpos);
      Tk::SlideShow::warppointer($x,$y);
    }
    $s->show;
  };
  $c->bind($id,"<1>", [$movepos, $id, 1]);
  $c->bind($id,"<3>", [$movepos, $id,-1]);

}
sub from { return (shift)->{'from'} }
sub to { return (shift)->{'to'} }
sub titre { return (shift)->{'titre'} }
sub id { return (shift)->{'id'} }
sub fpos { return (shift)->var_getset('fpos',(shift))}
sub tpos { return (shift)->var_getset('tpos',(shift))}
sub ftpos {
  my ($s,$f,$t) = @_;
  $s->{'fpos'}=$f;
  $s->{'tpos'}=$t;
  $s->show;
  return $s;
}
sub fx { return (shift)->{'fx'} }
sub fy { return (shift)->{'fy'} }
sub tx { return (shift)->{'tx'} }
sub ty { return (shift)->{'ty'} }

sub show {
  my $s = shift;

  my $from = $s->from;
  my $to = $s->to;

  my $can = Tk::SlideShow->can;
  my $id = $s->id;
  
  $can->delete($s->id);
  my $fpos = $s->fpos % 8;
  my ($fx,$fy) = $from->pos($fpos);
  $s->{'fpos'} = $fpos;
  $s->{'fx'} = $fx;
  $s->{'fy'} = $fy;

  my $tpos = $s->tpos % 8;
  my ($tx,$ty) = $to->pos($tpos);
  $s->{'tpos'} =$tpos;
  $s->{'tx'} = $tx;
  $s->{'ty'} = $ty;

#  print "createline ($fx,$fy,$tx,$ty)\n";
  $s->trace_link($fx,$fy,$tx,$ty);

  return $s;
}

sub trace_link {
  my ($s,$fx,$fy,$tx,$ty) = @_;
  my $id = $s->id;

  $can->createLine($fx,$fy,$tx,$ty,-tags,$id);
  if ($s->titre) {
    my $wid = $can->createText(($fx+$tx)/2,($fy+$ty)/2,'-text',$s->titre, -tags,$id);
    $can->createRectangle($can->bbox($wid),-fill,'lightYellow',-outline,'red',-tags,$id);
    $can->raise($wid);
  }
}

sub evalplace {
  my $s = shift;
  return sprintf("ftpos(%d,%d)",$s->fpos,$s->tpos);
}

package Tk::SlideShow::Arrow;
@Tk::SlideShow::Arrow::ISA = qw(Tk::SlideShow::Link);
Tk::SlideShow::Placeable->AddClass('Tk::SlideShow::Arrow');

my $chshape = sub  {
  my ($s,$what,$how) = @_;
  $s->{'shape'}[$what]+=$how;
  $s->show;
};

my $chwidth = sub  {
  my ($s,$how) = @_;
  $s->{'width'} +=$how;
  $s->show;
};

sub New {
  my $class = shift;
  my $s = $class->SUPER::New(@_);
  bless $s;
  $s->{'shape'}=[8,10,3];
  $s->{'width'} = 1;

  my $id = $s->id;
  my $c = Tk::SlideShow->can;
  $c->CanvasBind('Tk::SlideShow','<Up>',[\&Tk::SlideShow::exec_if_current,$id,$chshape,$s,0,1]);
  $c->CanvasBind('Tk::SlideShow','<Control-Up>',[\&Tk::SlideShow::exec_if_current,$id,$chshape,$s,0,-1]);
  $c->CanvasBind('Tk::SlideShow','<Down>',[\&Tk::SlideShow::exec_if_current,$id,$chshape,$s,1,1]);
  $c->CanvasBind('Tk::SlideShow','<Control-Down>',[\&Tk::SlideShow::exec_if_current,$id,$chshape,$s,1,-1]);
  $c->CanvasBind('Tk::SlideShow','<Left>',[\&Tk::SlideShow::exec_if_current,$id,$chshape,$s,2,1]);
  $c->CanvasBind('Tk::SlideShow','<Control-Left>',[\&Tk::SlideShow::exec_if_current,$id,$chshape,$s,2,-1]);
  $c->CanvasBind('Tk::SlideShow','<Right>',[\&Tk::SlideShow::exec_if_current,$id,$chwidth,$s,1]);
  $c->CanvasBind('Tk::SlideShow','<Control-Right>',[\&Tk::SlideShow::exec_if_current,$id,$chwidth,$s,-1]);
  return $s;
}

sub evalplace {
  my $s = shift;
  return sprintf("ftpos(%d,%d)->width(%d)->shape(%d,%d,%d)",
		 $s->fpos,$s->tpos,$s->width,@{$s->shape});
}

sub shape {
  my ($s,@vals) = @_;
  if (defined @vals and @vals == 3) {
    $s->{'shape'} = [@vals];
    $s->show;
    return $s;
  }
  return $s->{'shape'};
}
sub width {
  my ($s,$val) = @_;
  if (defined $val) {
    $s->{'width'} = $val;
    $s->show;
    return $s;
  }
  return $s->{'width'};
}

sub trace_link {
  my ($s,$fx,$fy,$tx,$ty) = @_;
  my $id = $s->id;

  $can->createLine($fx,$fy,$tx,$ty,-arrow,'last',
		   '-arrowshape', $s->shape,
		   '-width', $s->width,
		   -tags,$id);
  if ($s->titre) {
    my $wid = $can->createText(($fx+$tx)/2,($fy+$ty)/2,'-text',$s->titre, -tags,$id);
    $can->createRectangle($can->bbox($wid),-fill,'lightYellow',-outline,'red',-tags,$id);
    $can->raise($wid);
  }

  return $s;
}

package Tk::SlideShow::DblArrow;

@Tk::SlideShow::DblArrow::ISA = qw(Tk::SlideShow::Arrow);
Tk::SlideShow::Placeable->AddClass('Tk::SlideShow::DblArrow');

sub New {
  my $class = shift;
  my $s = $class->SUPER::New(@_);
  bless $s;
}

sub trace_link {
  my ($s,$fx,$fy,$tx,$ty) = @_;
  my $id = $s->id;

  $can->createLine($fx,$fy,$tx,$ty,-arrow,'both',
		   '-arrowshape', $s->shape,
		   '-width', $s->width,
		   -tags,$id);
  if ($s->titre) {
    my $wid = $can->createText(($fx+$tx)/2,($fy+$ty)/2,'-text',$s->titre, -tags,$id);
    $can->createRectangle($can->bbox($wid),-fill,'lightYellow',-outline,'red',-tags,$id);
    $can->raise($wid);
  }

  return $s;
}


package Tk::SlideShow::Org;
@Tk::SlideShow::Org::ISA = qw(Tk::SlideShow::Link);
Tk::SlideShow::Placeable->AddClass('Tk::SlideShow::Org');

sub New {
  my $class = shift;
  my $s = $class->SUPER::New(@_);
  $s->{'fpos'} = 5;
  $s->{'tpos'} = 1;
  bless $s;
}

sub trace_link {
  my ($s,$fx,$fy,$tx,$ty) = @_;
  my $id = $s->id;

  my $midy = int(($fy+$ty)/2);
  $can->createLine($fx,$fy,$fx,$midy,$tx,$midy,$tx,$ty,-tags,$id);
  return $s;
}


1;

# Local Variables: ***
# mode: perl ***
# End: ***


__END__


