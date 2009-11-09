#!/usr/bin/perl
use strict;
use warnings;
use Tk;
use Tk::TableMatrix;
use Tk::TableMatrix::Spreadsheet;

my $top = MainWindow->new;

my $arrayVar = {};

print "Filling Array...\n";
my ($rows,$cols) = (40000, 10);

foreach my $row  (0..($rows-1)){
           $arrayVar->{"$row,0"} = "$row";
    }

foreach my $col  (0..($cols-1)){
           $arrayVar->{"0,$col"} = "$col";
    }

print "Creating Table...\n";
sub colSub{
    my $col = shift;
    return "OddCol" if( $col > 0 && $col%2) ;
}

my $label = $top->Label(-text => "TableMatrix v2 Example")
            ->pack( -expand => 1, -fill => 'both');

my $t = $top->Scrolled('Spreadsheet', 
		-rows => $rows, 
		-cols => $cols,
                -width => 6, 
		-height => 12,
		-titlerows => 1, 
		-titlecols => 1,
		-variable => $arrayVar,
		-coltagcommand => \&colSub,
		-colstretchmode => 'last',
		-flashmode => 1,
		-flashtime => 2,
		-wrap=>1,
		-rowstretchmode => 'last',
		-selectmode => 'extended',
		-selecttype=>'cell',
		-selecttitles => 0,
		-drawmode => 'slow',
		-scrollbars=>'se',
		-sparsearray=>0
                )->pack(-expand => 1, -fill => 'both');

#my $realmatrix = $t->Subwidget('scrolled');

$top->Button( -text => "Clear", 
      -command => sub{&clear})->pack(-expand => 1, -fill => 'x');
$top->Button( -text => "Fill", 
      -command => sub{&fill})->pack(-expand => 1, -fill => 'x');
$top->Button( -text => "Exit", 
      -command => sub{$top->destroy})->pack(-expand => 1, -fill => 'x');

$t->colWidth( -2 => 8, -1 => 9, 0=> 12,  4=> 14);

$arrayVar->{"1,1"} = 42;

Tk::MainLoop;
#########################################
sub TMRefresh {
    #Required input TableMatrix object.
    #use to force matrix to update, a code trick
    return if (!$_[0]);
    $_[0]->configure(-padx =>($_[0]->cget(-padx)));

#$realmatrix->update;
#$t->update;
#$top->update;
#$t->see("100,100");  #trick to force update?
#$t->see("end");
#$t->see("1,1");
}   
#######################################
sub clear{
#$t->clearAll('0,0','end');
 foreach my $row(1..$rows){
    foreach my $col(1..$cols){
     $arrayVar->{"$row,$col"} = 0;
   }
 }

&TMRefresh($t);
}
#####################################
sub fill{

 foreach my $row(1..$rows){
    foreach my $col(1..$cols){
     $arrayVar->{"$row,$col"} = 1000;
   }
 }

&TMRefresh($t);
}
#######################################
