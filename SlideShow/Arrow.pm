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
