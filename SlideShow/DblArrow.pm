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

1;
