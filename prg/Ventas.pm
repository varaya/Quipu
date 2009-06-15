#  Ventas.pm - Consulta e imprime Libro Ventas
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package Ventas;

use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
my ($Mnsj, $mes, $nMes, @cnf,$rutE) ;	# Variables
my @lMeses = () ;
my ($bCan, $bImp) ; # Botones
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	$FechaI = $ut->fechaHoy();
	@cnf = $bd->leeCnf();
	$nMes = '' ;
	$rutE = $rtE ;
	
	# Define ventanas
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Procesa Libro Ventas");
	$vnt->geometry("300x110+475+4"); # Tamaño y ubicación
	my $vntA = $vp->Toplevel();
	$vntA->title("Libro CVentas");
	$vntA->geometry("690x320+40+150"); 
	# Define marco para mostrar resultado
	my $mtA = $vntA->Scrolled('Text', -scrollbars=> 'e', -bg=> 'white');
	$mtA->tagConfigure('negrita', -font => $tp{ng} ) ;
	$mtA->tagConfigure('detalle', -font => $tp{mn} ) ;
	$mtA->pack(-fill => 'both');
	
	# Define marcos
	my $mMes = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Seleccione mes');
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );
	# Define campo para seleccionar mes
	my $meses = $mMes->BrowseEntry( -variable => \$nMes, -state => 'readonly',
		-disabledbackground => '#FFFFFC', -autolimitheight => 1,
		-disabledforeground => '#000000', -autolistwidth => 1,
		-browse2cmd => \&selecciona );
	# Crea listado de meses
	@lMeses = $ut->meses();
	my $algo;
	foreach $algo ( @lMeses ) {
		$meses->insert('end', $algo->[1] ) ;
	}
	$meses->delete(12,12); #Elimina el 'Todos' al final
	$meses->pack(-side => "left", -anchor => "w");

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Compras'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
		
	# Define botones
	$bMst = $mBotonesC->Button(-text => "Muestra", 
		-command => sub { &valida($esto, $mtA) } );
	$bImp = $mBotonesC->Button(-text => "Archivo", 
		-command => sub { &imprime($mtA) } );
	$bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); $vntA->destroy();} );
	
	# Dibuja interfaz
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bMst->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mMes->pack(-expand => 1);
	$mBotonesC->pack();
	$mMensajes->pack(-expand => 1, -fill => 'both');

	$bImp->configure(-state => 'disabled');
	$mt->delete('0.0','end');

	bless $esto;
	return $esto;
}

# Funciones internas
sub selecciona {
	my ($jc, $Index) = @_;
	$mes = $lMeses[$Index]->[0];
}

sub valida ( $ ) 
{
	my ($esto,$mt) = @_;
	my ($fi, $ff, $mnsj);
	
	$Mnsj = " ";
	if (not $mes) {
		$Mnsj = "Debe seleccionar un mes."; 
		return;
	} else {
		informe($esto,$mt);
	}
}

sub informe ( $ $ ) {

	my ($esto, $marco) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	my @datos = $bd->listaFct('Ventas',$mes);
	$marco->delete('0.0','end');
	$Mnsj = " ";
	if (not @datos) { 
		$Mnsj = "No hay datos para ese mes"; 
		return;
	}
	my ($algo,$nmb,$tp,$fch,$rt,$tt,$iva,$aft,$ext,$nulo,$empr,@datosE);
	@datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 

	$marco->insert('end', "$empr\n", 'negrita');
	$marco->insert('end', "Libro Ventas  $nMes $cnf[0]\n", 'negrita');
	my $lin1 = "\nFecha       Factura RUT        Cliente                     ";
	$lin1 .= "      Afecto      Exento         IVA       Total";
	my $lin2 = "-"x107;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	foreach $algo ( @datos ) {
		$fch = $ut->cFecha($algo->[0]); 
		$nm = $algo->[1]; 
		$rt = $algo->[2]; 
		$nmb =  decode_utf8($algo->[3]);
		$tt = $pesos->format_number( $algo->[4] );
		$iva = $pesos->format_number( $algo->[5] );
		$aft = $pesos->format_number( $algo->[6] );
		$ext = $pesos->format_number( $algo->[7] );
		$nulo = $algo->[8]; 
		if ( not $nulo ) {
			$mov = sprintf("%10s %8s %10s %-28s %11s %11s %11s %11s", 
				$fch,$nm,$rt,$nmb,$aft,$ext,$iva,$tt ) ;
			$marco->insert('end', "$mov\n",'detalle' ) ;
		}
	}

	$bImp->configure(-state => 'active');
}

sub imprime ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');
	# Genera archivo de texto
	open ARCHIVO, "> inf/ventas$mes.txt" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
}

# Fin del paquete
1;
