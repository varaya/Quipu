#  CCmprb.pm - Muestra e imprime comprobantes
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM: 29.12.2009

package CCmprb;

use Tk::TList;
use Tk::LabFrame;
use Encode ;
use Number::Format;
 
# Variables válidas dentro del archivo
my @datos = () ;	# Lista items del comprobante
my ($bCan, $bImp, $rutE, $cuenta, $Numero, $Empresa) ; 
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rt, $emp) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	$rutE = $rt ;
	$Empresa = encode_utf8( $emp );
	my %tp = $ut->tipos();
	$Fecha = $ut->fechaHoy();
	$mes = $nMes = $Numero = '';
	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Consulta Comprobante");
	$vnt->geometry("680x430+475+4"); # Tamaño y ubicación
	# Define marco para mostrar resultado
	my $mtA = $vnt->Scrolled('Text', -scrollbars=> 'e', -bg=> 'white', -height=> 420 );
	$mtA->tagConfigure('negrita', -font => $tp{ng}) ;
	$mtA->tagConfigure('detalle', -font => $tp{fx}) ;
	$mtA->tagConfigure('cuenta', -font => $tp{cn} ) ;
	$mtA->tagConfigure('grupo', -font => $tp{gr}, -foreground => 'brown') ;

	# Defime marcos
	my $mBotones = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'CCmprb'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
	
	$cuenta = $mBotones->LabEntry(-label => "Comprobante #: ", -width => 6,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Numero );
	# Define botones
	my $bLmp = $mBotones->Button(-text => "Muestra", 
		-command => sub { muestraC($esto,$mtA); } );
	$bArc = $mBotones->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mtA);} ],
 	  ['command' => "planilla", -command => sub { csv($esto);} ] ] );
 	$bImp = $mBotones->Button(-text => "Imprime", -command => sub { &imprime($esto) } ); 

	$bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); } );

	# Dibuja interfaz
	$cuenta->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bLmp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bArc->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

	$mMensajes->pack(-expand => 1, -fill => 'both');
	$mBotones->pack(-expand => 1);
	$mtA->pack(-fill => 'both');

	# Inicialmente deshabilita botón Registra
	$bImp->configure(-state => 'disabled');
	$cuenta->focus;

	bless $esto;
	return $esto;
}

# Funciones internas
sub muestraC {

	my ($esto, $marco) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	my $tc = {};
	$tc->{'I'} = 'Ingreso';
	$tc->{'E'} = 'Egreso';
	$tc->{'T'} = 'Traspaso';
	my ($nmrC, $tipoC, $fecha, $glosa, $total, $nulo);
	# Obtiene item seleccionado
	@datos = $bd->datosCmprb($Numero) ;
	if (not @datos) {
		$Mnsj = "NO existe ese comprobante";
		$cuenta->focus ;
		return ;
	}
	$nmrC = $datos[0];
	$tipoC = $tc->{$datos[3]};
	$fecha = $ut->cFecha($datos[2]);
	$glosa = decode_utf8($datos[1]);
	$total = $pesos->format_number( $datos[4] );
	$nulo = $datos[5];
	$ref = $datos[6];

	$marco->delete('0.0','end');
	$marco->insert('end', 
	 "\nComprobante de $tipoC   # $nmrC  del  $fecha\n", 'negrita');
	$marco->insert('end', "Glosa: $glosa\n\n" , 'cuenta');
	if ($nulo == 2) {
		$cuenta->focus ;
		return ; 
	}
	$marco->insert('end', "Movimientos\n" , 'grupo');
	my @data = $bd->itemsC($nmrC);
	my ($algo, $mov, $cm, $ncta, $mntD, $mntH, $dt, $ci, $td, $dcm);
	my ($tD, $tH) = (0, 0);
	my $lin1 = "Cuenta                                       Debe        Haber  Detalle";
	my $lin2 = "-"x85;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # Código cuenta
		$ncta = decode_utf8( substr $bd->nmbCuenta($cm),0,30 );
		$mntD = $mntH = $pesos->format_number(0);
		$mntD = $pesos->format_number( $algo->[2] ); 
		$tD += $algo->[2] ;
		$mntH = $pesos->format_number( $algo->[3] );
		$tH += $algo->[3] ;
		$ci = $dcm = $dt = '' ;
		if ($algo->[4]) {
			$dt = decode_utf8($algo->[4]);
		} 
		if ($algo->[5]) {
			$ci = "RUT $algo->[5]";
		}
		if ($algo->[6]) {
			$dcm = "$algo->[6] $algo->[7]";
		}
		$mov1 = sprintf("%-5s %-30s %12s %12s  %-15s", $cm, $ncta,
			$mntD, $mntH, $dt ) ;
		$mov2 = sprintf("       %-15s %-20s", $ci, $dcm ) ;

		$marco->insert('end', "$mov1\n", 'detalle' ) ;
		if ( not ($ci eq '' ) ) { #	and $dcm eq ''
#			$marco->insert('end', "$mov2\n", 'detalle' ) ;
		}
	}
	$marco->insert('end',"$lin2\n",'detalle');
	$mov1 = sprintf("%36s %12s %12s", "Totales" ,
			$pesos->format_number($tD), $pesos->format_number($tH) );
	$marco->insert('end', "$mov1\n\n", 'detalle' ) ;
	if ( $nulo == 1) {
		$marco->insert('end', "Anulado por Comprobante $ref\n" , 'grupo');
	}
#	$Numero = '' ;
	$bImp->configure(-state => 'active');
}

sub txt ( $ )
{
	my ( $marco) = @_;	
	
	my $algo = $marco->get('0.0','end');

	# Genera archivo de texto
	my $d = "$rutE/txt/cmprb.txt" ;
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Ver archivo '$d'"
}

sub imprime ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'} ;
	
	my $tc = {};
	$tc->{'I'} = 'Ingreso';
	$tc->{'E'} = 'Egreso';
	$tc->{'T'} = 'Traspaso';
	my ($nmrC, $tipoC, $fecha, $glosa, $total, $nulo);
	@datos = $bd->datosCmprb($Numero) ;

	$nmrC = $datos[0];
	$tipoC = $tc->{$datos[3]};
	$fecha = $ut->cFecha($datos[2]);
	$glosa = $datos[1];
	$total = $pesos->format_number( $datos[4] );
	$nulo = $datos[5];
	$ref = $datos[6];
	
	my $d = "var/cmprb.txt" ;
	open ARCHIVO, "> $d" or die $! ;

	my $lin = "\n$Empresa\n\nComprobante de $tipoC  # $nmrC              Fecha: $fecha\n" ;
	print ARCHIVO $lin ;
	print ARCHIVO "Glosa: $glosa\n\n";
	my @data = $bd->itemsC($nmrC);
	my ($algo, $ch, $cm, $ncta, $mntD, $mntH, $dt, $ci, $td, $dcm, $rtF, $nmb);
	my ($tD, $tH, $tch) = (0, 0, 0);
	$rtF = $nmb = '' ;
	my $lin1 = "Cuenta                                       Debe        Haber"  . "\n";
	print ARCHIVO $lin1 ;
	my $lin2 = "-"x63;
	print ARCHIVO $lin2 . "\n" ;
	foreach $algo ( @data ) {
		$cm = $algo->[1];  
		$ncta = substr $bd->nmbCuenta($cm),0,30 ;
		$mntD = $mntH = $pesos->format_number(0);
		$mntD = $pesos->format_number( $algo->[2] ); 
		$tD += $algo->[2] ;
		$mntH = $pesos->format_number( $algo->[3] );
		$tH += $algo->[3] ;
		$ci = $algo->[6] ? substr $algo->[6], 0, 1 : '' ;
		$dcm = $ci eq '' ? '' : "$algo->[6] $algo->[7]" ;
		$rtF = $algo->[5] if $ci eq 'F';
		if ($algo->[6] eq 'CH') {
			$ch = $algo->[7] ;
			$nBanco = $ncta;
			$tch += 1 ;
		}
		$lin = sprintf("%-5s %-30s %12s %12s  %-12s", $cm, $ncta, $mntD, $mntH, $dcm )  . "\n" ;
		print ARCHIVO $lin ;
	}
	print ARCHIVO $lin2 . "\n";
	$lin = sprintf("%36s %12s %12s", "Totales" ,
			$pesos->format_number($tD), $pesos->format_number($tH) ) . "\n";
	print ARCHIVO $lin ;
	print ARCHIVO $lin2 . "\n\n";
	
	$nmb = $bd->buscaT($rtF) ;
	print ARCHIVO "Pagado a: $nmb   RUT: $rtF\n" if $nmb;
	if ( $tch == 1 ) {
		print ARCHIVO "Cheque #: $ch   Banco: $nBanco \n" ;
	} else {
		print ARCHIVO "Cheques del Banco $nBanco\n" if $tch > 0 ;
	}
	
	print ARCHIVO "\n\n__________________     _______________    __________________   ___________" ;
	print ARCHIVO "\n    Emitido                 Vº Bº          Recibo Conforme         RUT" ;
	
	close ARCHIVO ;
	system "lp $d";
	$Numero = ' ' ;
}

# Fin del paquete
1;
