#----------------------------------------
# PLACEABLE
#----------------------------------------
#
# Class for managing placeable objets
#

use strict;

package Tk::SlideShow::Placeable;

use vars qw(@ISA @classes);
@ISA = qw(Tk::SlideShow::Dict);

sub New {
  my ($class,$id) = @_;
  die "An mandatory id is needed !" unless defined $id;
  my $s = bless {'x'=>Tk::SlideShow->w/2,'y'=>Tk::SlideShow->h/2,'id'=>$id};
  $class->Set($id,$s);
  return $s;
}

sub x { return (shift)->{'x'};}
sub y { return (shift)->{'y'};}

sub no { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return ($x1,$y1);
}
sub n { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return (($x1+$x2)/2,$y1);
}
sub ne { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return ($x2,$y1);
}
sub e { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return ($x2,($y1+$y2)/2);
}
sub se { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return ($x2,$y2);
}
sub s { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return (($x1+$x2)/2,$y2);
}
sub so { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
  return ($x1,$y2);
}
sub o { 
  my $s = shift;
  my ($x1,$y1,$x2,$y2) = Tk::SlideShow->canvas->bbox($s->id);
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


sub AddClass{
  shift;
  push @classes,@_;
}

sub evalplace {
  my $s = shift;
  die "La méthode 'evalplace' doit être redéfinie pour la classe ".ref($s)." et ne l'est pas, apparament\n";
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
  my $c = Tk::SlideShow->canvas;
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

1;
