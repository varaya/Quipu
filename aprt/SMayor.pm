#  SMayor.pm - Registra asiento de apertura inicial
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM: 24.06.2009

package SMayor;

use Tk::TableMatrix;
use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
my ($TotalDf, $TotalHf, $cuentas, $Mnsj) ;	# 
my ($bCan, $bReg) ; # Botones
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables
	$cuentas = {};
	my %tp = $ut->tipos();
	# Titulos de la tabla
	$cuentas->{"-1,0"} = "Código";
	$cuentas->{"-1,1"} = "Cuenta";
	$cuentas->{"-1,2"} = "Debe";
	$cuentas->{"-1,3"} = "Haber";

	my @data = $bd->datosCuentas(0);
	my ($algo, $fila, $nc);
	$nc = @data + 1;
	$fila = 0;
	foreach $algo ( @data ) {
		if ( $algo->[0] lt '3000' ) {
			$cuentas->{"$fila,0"} = " $algo->[0]";
			$cuentas->{"$fila,1"} = decode_utf8($algo->[1]) ;
			$cuentas->{"$fila,2"} = $cuentas->{"$fila,3"} = 0 ;
			$fila += 1;
		}
	}
	
	# Define ventana
	my $vnt = MainWindow->new();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Saldos");
	$vnt->geometry("460x390+2+120"); # Tamaño y ubicación

	# Define marcos
	my $mTabla = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Asiento de Apertura');
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mDatosC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'left', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Aprt'); } ); 
	$bAyd->pack(-side => 'right', -expand => 0, -fill => 'none');

	$Mnsj = "Mensajes de error o advertencias.";
	
	# Define Campos
	$totalD = $mDatosC->LabEntry(-label => "Totales:  Debe ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$TotalDf, -state => 'disabled', 
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000' );
	$totalH = $mDatosC->LabEntry(-label => "Haber ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$TotalHf, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
	
	# Define tabla 
	my $tabla = $mTabla->Scrolled('TableMatrix', -rows => $nc, -cols => 4,
		-width => 6, -height => 15, -titlerows => 1, -titlecols => 0,
		-roworigin => -1, -colorigin => 0, -variable => $cuentas,
		-selectmode => 'single', -font => $tp{mn}, -scrollbars => 'e',
		-anchor => 'e', -command => [ \&total, $nc - 1] );
 
	$tabla->colWidth(0 => 7, 1 => 30, 2 => 11, 3 => 11);
	$tabla->tagConfigure('lectura',-relief => 'groove', -state => 'disabled',
		-anchor => 'w');
	$tabla->tagCol('lectura',0,1);
	
	# Define botones
	$bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { &cancela($esto) } );
	$bReg = $mBotonesC->Button(-text => "Registra", 
		-command => sub { &registra($esto, $nc - 1) } );

	# Dibuja interfaz
	$mMensajes->pack(-expand => 1, -fill => 'both');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bReg->pack(-side => 'right', -expand => 0, -fill => 'none');
	$totalD->grid(-row => 0, -column => 0);
	$totalH->grid(-row => 0, -column => 1); 
	$tabla->pack();
	$mTabla->pack(-expand => 1);
	$mDatosC->pack();
	$mBotonesC->pack();

	$bReg->configure(-state => 'disabled');

	bless $esto;
	return $esto;
}

# Funciones internas

sub total ()
{
	my ($c, $set, $fila, $col, $valor) = @_;

	if ($set) {	
		$cuentas->{"$fila,$col"} = $valor ;
		my ($td, $th, $j) ;
		$td = $th = 0 ;
		for ($j = 0; $j < $c; $j++ ) {
			$td += $cuentas->{"$j,2"} ;
			$th += $cuentas->{"$j,3"} ;
		}
		$TotalDf = $pesos->format_number($td);
		$TotalHf = $pesos->format_number($th);
		
		if ($th == $td) {
			$bReg->configure(-state => 'active');
		} else {
			$bReg->configure(-state => 'disabled');
		}
	} else {
		return $cuentas->{"$fila,$col"} ;
	}
}

sub registra ($)
{
	my ($esto, $c) = @_;	
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	# Graba datos
	my ($ttl, $tSld, $cdg, $th, $td, $j) ;
	for ($j = 0; $j < $c; $j++ ) {
		$td = $cuentas->{"$j,2"} ;
		$th = $cuentas->{"$j,3"} ;
		# solamente las cuentas con saldo
		if ($td + $th > 0) {
			$cdg = substr $cuentas->{"$j,0"},1 ;
			$ttl = $td ;
			$tSld = "D" ;
			if ($td == 0) {$ttl = $th; $tSld = "A"; }
			$bd->apertura($cdg, $ttl, $tSld);
		}
	}
	$Mnsj = "Apertura registrada.";
	cancela($esto) ;
}

sub cancela ($)
{
	my ($esto) = @_;	
	my $vn = $esto->{'ventana'};

	$vn->destroy();
}


# Fin del paquete
1;
