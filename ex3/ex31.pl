#!/usr/local/bin/perl5 -I../blib/lib -w

use Tk::SlideShow;
use strict;
	
my $p = Tk::SlideShow->init(1024,768);
$p->save;
my ($mw,$c,$h,$w) = ($p->mw, $p->can, $p->h, $p->w);

sub bandeau {
  my ($id,$text,$len,@option) = @_;
  my $spri = $p->newSprite($id)->pan(1);
  my $idw = $c->createText(0,0,-text,substr($text,0,$len), 
				  -font => $p->f2, -fill => 'red', -tags => $id,);
  my @bbox = $c->bbox($id);
  my $larg = $bbox[2]-$bbox[0];
  my $haut = $bbox[3]-$bbox[1];
  my $bg = $c->cget(-background);
  my $scan = $mw->Canvas(-height,$haut,-width,$larg,-background,$bg);
  $c->createWindow($w/2,$h/2,-anchor,'nw',-window,$scan,-tags,$id);
  $c->delete($idw);
  my @def = (-anchor, 'nw', -text,$text,-tags => $id, -font => $p->f2, -fill => 'red',-fill,'yellow');
  $idw = $scan->createText(0,0,@def);
  @bbox = $scan->bbox($idw);
  my $txtwidth = $bbox[2];
  $scan->createText($txtwidth,0, @def);
  $c->createRectangle($c->bbox($id),-width,20,-outline,$bg,-tags,$id);
  sub tourne {
    my ($spri,$scan,$txtwidth) = @_;
    my $tag = $spri->id;
    $scan->move($tag,-5,0);
    $scan->move($tag, $txtwidth,0) if ($scan->bbox($tag))[2] < $scan->Width;
    $c->after(50,[\&tourne,$spri,$scan,$txtwidth]);
  }
  tourne($spri,$scan,$txtwidth);
  return $spri;
}

$p->bg('black');
$p->add('bandeau51', sub {
	  bandeau('m2',"Tk::SlideShow has no cause to be jealous of PowerPoint ......", 40);
	  bandeau('m',"short message .. ", 5);
	  $p->load });

$p->current(shift || 0);
$p->play;

