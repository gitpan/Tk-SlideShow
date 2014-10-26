#!/usr/local/bin/perl5 -I../blib/lib -w

use Tk::SlideShow;
use strict;

my $P = Tk::SlideShow->init(1024,768) or die;

$P->save;

my ($mw,$c,$h,$w) = ($P->mw, $P->can, $P->h, $P->w);
my $d;

sub title {$P->Text('title',shift,-font,$P->f3);}

sub items {
  my ($id,$items,@options) = @_;
  for (split (/\n/,$items)) {
    $P->Text($id,$_,@options);
	    $id++;
  }
}
$d = $P->add('sommaire',sub {
	  title('Tk::SlideShow');
	  my $c = 'a0';
	  items('a0',"What ?\nWhy ?\nHow ?",
		-font => $P->f2,-fill, 'red');
	  items('b0',"a TkPerl alternative to PowerPoint\nPerl power\nBy examples",
		-font => $P->f2,-fill, 'blue');
	  $P->load;
	  for (0..2) {$P->a_top("a$_"); $P->a_bottom("b$_");}
});

$d->latex("
\\paragraph{What's Tk::SlideShow ?}

Tk::SlideShow is a module that will help perl to be a very
	  powerfull tool for building presentation

\\paragraph{Why using perl for that purpose}

There are good reason for using Tk::SlideShow :

\\begin{enumerate}

\\item Filling the lack of free tools for building presentation like
what you can do with PowerPoint.

\\item Simply building simple slide,

\\item Being able to build very elaborated slides, up to real GUI
interface,

\\item Structured your presentations using a structured language,

\\item Or even a OO presentation using a OO language,

\\end{enumerate}

When using a tool like PowerPoint, you have 2 types of interaction :

\\begin{enumerate}

\\item description of what you want to see thru menus, dialog box and
templates and typing text. This is roughly programming with a mouse ;

\\item interactive and approximative placement of what you want to see
: this is Art !

\\end{enumerate}

Tk::SlideShow will try to target the former with perl script rather than a
two buttons mouse, and will probably be much more powerful. Tk::SlideShow
will try to target the later with Tk interaction. It will probably not
reach the Artistic Quality of a PowerPoint like tools. But one never
know !

\\paragraph{How to use it ?}

Well, mostly by examples, because perl folks don't like having to
learn another theory when explaining there's");



sub example {
  my ($id,$t,@options) = @_;
  $t =~ s/^\s+//; $t =~ s/\s+$//;
  my $s = $P->newSprite($id);
  $c->createText(0,0,-text,'Example',
		 -font => $P->f1, -tags => $id, -anchor => 'sw');
  my $idw = $c->createText(0,0,-text,$t,@options, -tags => $id,
			  -anchor => 'nw');
  $c->createRectangle($c->bbox($idw), -fill,'light green',-tags => $id);
  $c->raise($idw);
  $s->pan(1);
  return $s;
}

#############################################################

$d = $P->add('prerequisite',sub {
	  title('Prerequisite');
	  example('ex',"use Tk::SlideShow;\nmy \$P= Tk::SlideShow->init(1024,768);\n\$P->save;",
		  -font => $P->ff2
		 );
	  items('a0',"You have to know Perl and Tk !
Tell what your screen size
Ask for your Art to be saved",
		-font => $P->f2,-fill, 'red');
	  $P->load;
	  for (0..2) {$P->a_bottom("a$_")}
	});

$d->latex("
\\paragraph{You have to know Perl/Tk}

Yes, there is no power in Tk::SlideShow. The power is in Perl and in Tk. You
will reuse all what you have learn. That's the trick : Tkpp only takes
advantage of what you already know. Leave now this reading,
un(til\|less) you know a little bit perl/Tk.

\\paragraph{Tell what your screen size is}

Sometimes, you are developping your application on 21~inch screen with
a resolution of \$1600 \\times 1280\$ and the projector will only be
able to have \$ 1024 \\times 768\$. This, Perl cannot know, you have
to tell it. If you don't Tk::SlideShow will use the maximum size of you X11
root.

To short the examples given there, I assume that these lines will be
at the beginning of each example.

\\paragraph{Ask for your Art to be saved}

When building your presentation, you will be able to place visual
object with the mouse. This has to be saved so that when restarting
the presentation, objets will be positionned where you have previously
specified it. The class method \\texttt{\\bf save} is there to allow
to save your interactive modification.

");
$d = $P->add('first-slide',sub {
	  title('My first slide');
	  example('ex',
		  q{$P->add('first-slide',
sub {
  $P->Text('t1',"My first Tk::SlideShow slide");
  $P->Text('t2',"This is simple");
  $P->Text('t3',"This is simplist");
  $P->Load;
}
},
		  -font => $P->ff1
		 );
	  items('a0',"Add a slide
Give it a name,
Give the sub
Describe the texts
Load the positions",
		-font => $P->f2,-fill, 'blue');
	  $P->load;
	  for (0..4) {$P->a_bottom("a$_")}
	});

$d->latex("
\\paragraph{Your first slide}
OK, now, you are dying to know how to build a first
slide. That's simple, if what you want is simple.

\\paragraph{Add a slide}
A presentation is a pile of slides. You just have to add
a slide to the presentation by using the method \\texttt{\\bf add}

\\paragraph{Give it a name}
Because your slide is probably something you will reference in the
future, your had better to give it a name. If not, Tk::SlideShow will find one
for you. In this example, this is {\\it first-slide}. This name will also
be used to store positions of the objets you will place interactively
on the screen.

\\paragraph{Give the sub}
Well, a slide for Tk::SlideShow is rougly a sub reference. This sub will be call 
when Tk::SlideShow has to show the slide. That's all.

\\paragraph{Describe the text} Here, you see a new method,
\\texttt{\\bf Text}, that is used to place a text on the screen. You do not
know where the text will be place. This will be done with your mouse,
dragging the text with button one. When the artisitic position are
good for you, then just press key \\texttt{\\bf s} to save the position 
in a file.

\\paragraph{Load the positions} Then, you can load the positions of your
texts, you have previously saved.

");

if (grep (/-latex/,@ARGV)) {
  $P->latex("doc.tex");
  exit 0;
}

$P->current(shift || 0);
$P->play;







