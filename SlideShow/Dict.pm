#
# Class to manage a dictionnary of objects
#

package Tk::SlideShow::Dict;

use strict;

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

1;
