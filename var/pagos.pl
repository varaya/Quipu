# pagos.pl
# prueba de selección de documentos a pagar
# fecha: 30/10/2009

use Tk;
use Tk::TableMatrix;
use Tk::LabEntry;
use Tk::LabFrame;
use Number::Format;
use prg::BaseDatos;
use prg::Utiles ;

# '3480554-7' 85207100-1
my ($RUT,$tbl) = ('','Compras') ;
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
my $top = MainWindow->new;
$top->geometry("400x200+75+4");
my $bd = BaseDatos->crea("96537850-2/2009.db3");
my $ut = Utiles->crea($vp);
my %tp = $ut->tipos();

my $marco = $top->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Cliente');
my $mDatosC = $marco->LabEntry(-label => " RUT: ", -width => 15,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'left', -textvariable => \$RUT);
my $busca = $marco->Button(-text => "Busca", 
		-command => sub { &llenaT() } );
my $mLista = $top->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Documentos pendientes');
# variables para la tabla con documentos
my $tab = {};
my ($algo, $fila, $rows, $cols);
$cols = 6 ;
$rows = 6 ;
my $t = $mLista->Scrolled('TableMatrix', -rows => $rows, -cols => $cols, 
		-titlerows =>  1, -titlecols => 0, -roworigin => -1, -colorigin => 0 ,
		-width => 8, -height => 8, -flashmode => 'off', -variable => $tab ,
		-font => $tp{mn}, -scrollbars => 'e' ,-state => 'disabled', -justify => 'right' );
$t->colWidth(0 => 4, 1 => 3, 2 => 8, 3 => 12, 4 => 12, 5 => 10);
# rellena títulos y algunas filas vacías
$tab->{"-1,0"} = "";
$tab->{"-1,1"} = "TD";
$tab->{"-1,2"} = "#";
$tab->{"-1,3"} = "Total";
$tab->{"-1,4"} = "Abonos";
$tab->{"-1,5"} = "Vence";
for ($fila = 0, $fila = 6 , $fila++) {
	$tab->{"$fila,0"} = "No";
	$tab->{"$fila,1"} = " " ;
	$tab->{"$fila,2"} = " ";
	$tab->{"$fila,3"} = 0;
	$tab->{"$fila,4"} = 0;
	$tab->{"$fila,5"} = " ";
}
# cofigura apariencia de los botones de selección
$t->tagConfigure('No', -bg => 'gray', -relief => 'raised');
$t->tagConfigure('SI', -bg => 'green', -relief => 'sunken');
$t->tagConfigure('sel', -bg => 'gray75', -relief => 'flat');

$t->bind('<FocusOut>',sub{ 
	my $w = shift;
	$w->selectionClear('all'); 
});

$t->bind('<Motion>', sub{
    my $w = shift;
    my $Ev = $w->XEvent;
    if( $w->selectionIncludes('@' . $Ev->x.",".$Ev->y)){
    	Tk->break;
    }
    $w->selectionClear('all');
    $w->selectionSet('@' . $Ev->x.",".$Ev->y);
    Tk->break; 
});

# activa o desactiva botones SI o NO 
$t->bind('<1>', sub {
    my $w = shift;
    $w->focus;
    my ($rc) = @{$w->curselection};
    my $var = $w->cget(-var);
    my ($r, $c) = split(/,/, $rc);
    if ( $var->{$rc} eq 'SI' ){
		$var->{$rc} = 'No';
        $w->tagCell('No',$rc);
    } elsif ( $var->{$rc} eq 'No' ) {
		$var->{$rc} = 'SI';
        $w->tagCell('SI',$rc);
        print $var->{"$r,6"}, "\n" ;
    }
});

$mDatosC->pack(-side => "left", -anchor => "w") ;
$busca->pack(-side => "left", -anchor => "w") ;
$marco->pack ;
$t->pack ;
$mLista->pack ;

Tk::MainLoop;

sub llenaT
{
	my @data = $bd->datosFacts($RUT,$tbl,1);
	$rows = @data ;
	$fila = 0;
	foreach $algo ( @data ) {
		$tab->{"$fila,0"} = "No";
		$tab->{"$fila,1"} = $algo->[8] ;
		$tab->{"$fila,2"} = $algo->[0];
		$tab->{"$fila,3"} = $pesos->format_number($algo->[2]);
		$tab->{"$fila,4"} = $pesos->format_number($algo->[3]);
		$tab->{"$fila,5"} =  $ut->cFecha($algo->[4]);
		$tab->{"$fila,6"} = $algo->[9] ;
		$t->tagCell('No', "$fila,0");
		$fila += 1;
	}
#	print $rows ;
    return if (!$t);
	$t->configure(-rows => $rows ) ;
    $t->configure(-padx =>($t->cget(-padx)));
}
