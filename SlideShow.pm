use strict;

use Tk;
use Tk::Xlib;
use Tk::After;
use Tk::Animation;
use Tk::Font;
use X11::Protocol;

use Tk::SlideShow::Dict;
use Tk::SlideShow::Placeable;
use Tk::SlideShow::Diapo;
use Tk::SlideShow::Sprite;


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

#------------------------------------------------
package Tk::SlideShow;

use vars qw($VERSION);

$VERSION='0.03';

my ($can,$H,$W,$xprot,$present);
my $mainwindow;
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


sub mw { return $mainwindow;}
sub canvas {return $can }
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

sub current_item {
  return $current_item;
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
  $mainwindow = $m;
  $present = bless { 'current' => 0, 'mw' => $m, 'fond'=>'ivory',
		   'slides_names' => {}};
  # util pour forcer le déplaceement de la souris (pointer)
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
  $mainwindow->Tk::bind('Tk::SlideShow','<s>', [\&Tk::SlideShow::Placeable::save,$present]);
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
  my ($m,$c) = ($mainwindow,$can);
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
  my $m = $mainwindow;
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
#  print "Je débloque\n";
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
      $mainwindow->update;
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
    print "Loading slide : ".$s->currentName."\n";
    $s->start_slide;
    my $diapo = $present->{'slides'}[$i];
    &{$diapo->code};
    $mainwindow->update;
    my $file = 'slide'.$diapo->name.'.ps';
    $can->postscript(-file => $file);
    print OUT "\\includegraphics[width=\\textwidth]{$file}\n";
    print OUT "".$diapo->latex;
    print OUT "\n\\newpage";
  }
  print OUT latexfooter();
  close OUT;
  
}

# building an html index and gif snapshots
sub htmlheader {return ""}
sub htmlfooter {return ""}
sub html {
  my ($s,$dirname) = @_;
  $mode = 'html';
  my $nbdiapo = @{$present->{'slides'}};

  if(not -d "$dirname") {
    mkdir $dirname,0750 or die "$!";
  }
  open(INDEX,">$dirname/index.html") or die "$!";
  print INDEX $s->htmlheader;
  for (my $i=0; $i<$nbdiapo; $i++) {
    $present->current($i);
    my $name = $s->currentName;
    print "Loading slide $name\n";
    $s->start_slide;
    my $diapo = $present->{'slides'}[$i];
    &{$diapo->code};
    $mainwindow->update;
    my $fxwd_name = "/tmp/tkss.$$.xwd";
    my $fpng_name = "$dirname/$name.png";
    my $fmpng_name = "$dirname/m.$name.png";
    my $fspng_name = "$dirname/s.$name.png";
    my $title = $mainwindow->title;
    print "Snapshooting it (xwd -name $title -out $fxwd_name)\n";
    system("xwd -name $title -out $fxwd_name");
    print "Converting to png\n";
    system("convert $fxwd_name $fpng_name");
    my ($w,$h) = ($s->w,$s->h);
    my ($mw,$mh) = (int($w/2),int($h/2));
    print "Rescaling it for medium png (${mw}x${mh}) access\n";
    system("convert -sample ${mw}x${mh} $fpng_name $fmpng_name");
    my ($sw,$sh) = (int($w/4),int($h/4));
    print "Rescaling it for small png (${sw}x${sh}) access\n";
    system("convert -sample ${sw}x${sh} $fpng_name $fspng_name");
    print INDEX "<li> <a href='$name.html'> $name  </a></li><br> 
                 <a href=m.$name.png> <img src=s.$name.png> </a> \n";
    open(HTML,">$dirname/$name.html") or die "$!";
    print HTML "<img src=$name.png><br>\n";
    print HTML $diapo->html;
    close HTML;
  }
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
    $mainwindow->update;
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
  my $c = Tk::SlideShow->canvas ;
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

  my $can = Tk::SlideShow->canvas;
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
  my $c = Tk::SlideShow->canvas;
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


