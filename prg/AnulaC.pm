#  AnulaC.pm - Anula comprobantes, incluyendo docs. incluidos
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM: 08.09.2009

package AnulaC;

use Encode 'decode_utf8';
use Number::Format;
 
# Variables válidas dentro del archivo
my @datos = () ; # Datos comprobante
my @data = () ; # Lista items del comprobante
my ($bCan, $bImp, $rutE, $cuenta, $Cuenta, $Numero, $Fecha, $fecha) ; 
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	$rutE = $rt ;
	my %tp = $ut->tipos();
	$Fecha = $ut->fechaHoy();
	$mes = $nMes = $Cuenta = '';
	$Numero = $bd->numeroC() + 1;
	# Crea archivo temporal para registrar movimientos
	$bd->creaTemp();

	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Anula Comprobante");
	$vnt->geometry("650x430+475+4"); # Tamaño y ubicación
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
		-command => sub { $ut->ayuda($mt, 'AnulaC'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
	
	$cuenta = $mBotones->LabEntry(-label => "Comprobante #: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Cuenta );
	$fecha = $mBotones->LabEntry(-label => "Fecha: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Fecha );
	$numero = $mBotones->LabEntry(-label => "Nº C: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Numero, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
	# Define botones
	my $bLmp = $mBotones->Button(-text => "Muestra", 
		-command => sub { muestraC($esto,$mtA); } );
	$bImp = $mBotones->Button(-text => "Anula", 
		-command => sub { anula($esto); } );
	$bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { cancela($esto); } );

	# Dibuja interfaz
	$cuenta->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bLmp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$fecha->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$numero->pack(-side => 'left', -expand => 0, -fill => 'none');
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
	my ($nmrC, $tipoC, $fch, $glosa, $total, $nulo, $ref);
	# Obtiene item seleccionado
	@datos = $bd->datosCmprb($Cuenta) ;
	if (not @datos) {
		$Mnsj = "NO existe el comprobante # $Cuenta";
		$Cuenta = '';
		$cuenta->focus ;
		return ;
	}
	$nmrC = $datos[0];
	$tipoC = $tc->{$datos[3]};
	$fch = $ut->cFecha($datos[2]);
	$glosa = decode_utf8($datos[1]);
	$total = $pesos->format_number( $datos[4] );
	$nulo = $datos[5];
	$ref = $datos[6];

	$marco->delete('0.0','end');
	$marco->insert('end', 
	 "\nComprobante de $tipoC   # $nmrC  del  $fch\n", 'negrita');
	$marco->insert('end', "Glosa: $glosa\n\n" , 'cuenta');
	if ( $nulo ) {
		$marco->insert('end', "Anulado por Comprobante $ref\n" , 'grupo');
		$Cuenta = '';
		$cuenta->focus;
		return ;
	} else {
		$marco->insert('end', "Movimientos\n" , 'grupo');
	}
	@data = $bd->itemsC($nmrC);
	my ($algo, $mov, $cm,$ncta, $mntD, $mntH, $dt, $ci,$td, $dcm,$pago);
	my $lin1 = "Cuenta                                      Debe       Haber Detalle";
	my $lin2 = "-"x80;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	$pago = 0;
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # Código cuenta
		$ncta = decode_utf8($bd->nmbCuenta($cm) );
		$mntD = $mntH = $pesos->format_number(0);
		$mntD = $pesos->format_number( $algo->[2] ); 
		$mntH = $pesos->format_number( $algo->[3] );
		$ci = $dcm = $dt = '' ;
		$td =  $algo->[6] ;
		if ($algo->[4]) {
			$dt = decode_utf8($algo->[4]);
		} 
		if ($algo->[5]) {
			$ci = "RUT $algo->[5]";
		}
		if ( $td ) {
			$dcm = "$td $algo->[7]";
			$tabla = tbl( $td );
			$pago = $bd->buscaFct($tabla, $algo->[5], $algo->[7], 'Pagada')
		}
		$mov1 = sprintf("%-5s %-30s %11s %11s  %-15s", $cm, substr($ncta,0,30) ,
			$mntD, $mntH, $dt ) ;
		$mov2 = sprintf("       %-15s %-20s", $ci, $dcm ) ;

		$marco->insert('end', "$mov1\n", 'detalle' ) ;
		if ( not ($ci eq '' ) ) { #	and $dcm eq ''
			$marco->insert('end', "$mov2\n", 'detalle' ) ;
		}
	}
	$marco->insert('end', "\nTotal: $total\n" , 'grupo');
	if ($pago) {
		$marco->insert('end', "\nDocumento Pagado: no se puede anular\n" , 'negrita');
		$marco->insert('end', "Debe anular previamente el pago.\n" , 'negrita');
	}
	if ( not $pago ) {
		$bImp->configure(-state => 'active');
		$fecha->focus;
	} else {
		$cuenta->focus;
		$bImp->configure(-state => 'disabled');
	}
}

sub anula 
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	my ($nmrC, $tpC, $glosa, $total);
	$nmrC = $datos[0];
	$tpC = $datos[3];
	$glosa = "Anula Comprobante $nmrC";
	$total = $datos[4] ;
	my $aD = 0;
	# Registra items temporales
	my ($algo,$cm,$mntD,$mntH,$ci,$td,$dcm,$Mnt,$DH,$rut,$tabla);
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # Código cuenta
		$mntD =  $algo->[3] ; # Aquí se reversa la contabilización
		$mntH =  $algo->[2] ;
		$rut =  $algo->[5] if $algo->[5];
		$td =  $algo->[6] ;
		$dcm = $algo->[7] if $algo->[7];
		$aD = 1 if $dcm and $rut ; # Marca para actualizar documento
		if ($mntD == 0) { 
			$DH = 'H';
			$Mnt = $mntH; 
		} else { 
			$DH = 'D';
			$Mnt = $mntD ; 
		}
		$bd->agregaItemT($cm,$glosa,$Mnt,$DH,$rut,$td,$dcm,'',$Numero,'');
	}
	my $ff = $ut->analizaFecha($Fecha);
	# Registra nuevo comprobante
	$bd->agregaCmp($Numero,$ff,$glosa,$total,'T',0);
	$bd->actualizaCI($Numero,$ff);
	# Anula documento, si corresponde
	$tabla = tbl( $td );
	$Mnsj = "$rut - $dcm - $tabla";
	$bd->anulaDct($rut,$dcm,$tabla) if $aD and $tpC eq "T" ;
	# o bien elimina el pago contabilizado
	if ($aD and $tpC eq 'I') { # Facturas de Venta, si es ingreso
		$bd->anulaPago('Haber','FV','Ventas',$nmrC) ;
	}
	if ($aD and $tpC eq 'E') { # Si es egreso Facturas de Compra o Boleta H.
		$bd->anulaPago('Debe','FC','Compras',$nmrC) ;
		$bd->anulaPago('Debe','BH','BoletasH',$nmrC) if $td eq 'BH' ;
	}
	# Finalmente marca como nulo el comprobante anterior
	$bd->anulaCmp($nmrC,$Numero);
	$Numero = $bd->numeroC() + 1;
	$bImp->configure(-state => 'disabled');
	$Cuenta = '';
	$cuenta->focus;
}

sub cancela ( )
{
	my ($esto) = @_;	
	my $vn = $esto->{'ventana'};
	my $bd = $esto->{'baseDatos'};
	
	$bd->borraTemp();
	$vn->destroy();
}

sub tbl ( $ )
{
	my ($td) = @_;
	
	$tabla = 'BoletasH' if $td eq 'BH';
	$tabla = 'Compras' if $td eq 'FC' or $td eq 'FR';
	$tabla = 'Ventas' if $td eq 'FV' or $td eq 'FE';
	return $tabla;
}
# Fin del paquete
1;
