#!/usr/bin/perl
use warnings;
use strict;
use Tk;
use Tk::Table;
use Tk::Entry;
my $mw    = new MainWindow;
my $title = $mw->title( "kapsule" );

my $show_table_frame =
 $mw->Frame()
 ->pack( -side => "top", -fill => "both", -anchor => "nw", -padx => "10" );

my $button = $mw->Button(
   -text    => "show",
   #-font    => "verdanafont 10 bold",
   -command => sub {

      if ( $show_table_frame->ismapped ) {
         $show_table_frame->packForget();
      }
      else {
         $show_table_frame->pack();
      }
   }
)->pack();


my $show_table = $show_table_frame->Table(
   -columns      => 3,
   -rows         => 5,
   -scrollbars   => "o",
   -fixedrows    => 1,
   -fixedcolumns => 0,
   -relief       => 'raised',
   -takefocus    => "0",
   -pady         => "5"
);


my %chs; # column headers

foreach my $col(1..3){

    $chs{$col}{'button'} = $show_table->Button( -text => "Col $col ", 
              -width => 15, 
              -relief => 'ridge',
              -bg=>'white',
              -command => sub{ 
                  print "Col $col selected\n";    
    
                        for my $row(1..4){
                           print  $chs{$col}{$row}{'ent'}->get,"\n";  
                           $chs{$col}{$row}{'ent'}->configure(-bg=>'lightyellow');                     
                     }
              } );
   $show_table->put(0, $col , $chs{$col}{'button'} );
}


for ( my $col = 1 ; $col < 4 ; $col++ ) {
   for ( my $row = 1 ; $row < 5 ; $row++ ) {
      $chs{$col}{$row}{'ent'} =
       $show_table->Entry( -font => "verdana 10" )->pack( -ipady => "15" );
      $chs{$col}{$row}{'ent'}->insert(0, int rand 100);
      $show_table->put( $row, $col, $chs{$col}{$row}{'ent'} );
   }
}
$show_table->pack();
MainLoop;
