
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

1;
