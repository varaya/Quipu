#  CCmprb.pm - Lista, consulta e imprime comprobantes
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package CCmprb;

use Tk::TList;
use Tk::LabFrame;
use Tk::BrowseEntry;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
my @datos = () ;	# Lista items del comprobante
my ($bCan, $bImp, $mes, $nMes) ; 
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	$Fecha = $ut->fechaHoy();
	$mes = $nMes = '';
	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Consulta Comprobantes");
	$vnt->geometry("400x300+475+4"); # Tamaño y ubicación
	
	# Define marcos
	my $mMes = $vnt->Frame(-borderwidth => 1);
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Comprobantes');
	my $mBtnsC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Define campo para seleccionar mes
	my $tMes = $mMes->Label(-text => "Seleccione mes ") ;
	my $meses = $mMes->BrowseEntry(-variable => \$nMes, -state => 'readonly',
		-disabledbackground => '#FFFFFC', -autolimitheight => 1,
		-disabledforeground => '#000000', -autolistwidth => 1,
		-browse2cmd => \&selecciona );
	# Crea listado de meses
	@lMeses = $ut->meses();
	my $algo;
	foreach $algo ( @lMeses ) {
		$meses->insert('end', $algo->[1] ) ;
	}
	$tMes->pack(-side => "left", -anchor => "w");
	$meses->pack(-side => "left", -anchor => "w");

	my $bMuestra = $mMes->Button(-text => "Mostrar", 
		-command => sub { @datos = muestraLista($esto); } );
	$bMuestra->pack(-side => "right");

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'CCmprb'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
	
	# Define Lista de comprobantes
	my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe', -width => 80,
		-selectmode => 'single', -orient => 'horizontal', -height => 14,
		-font => $tp{mn}, -command => sub { &muestraC($esto, $mt) } );
	$esto->{'vLista'} = $listaS;
	
	# Define botones
	$bCan = $mBtnsC->Button(-text => "Cancela",
		-command => sub { &cancela($esto) } );
	$bImp = $mBtnsC->Button(-text => "Archivo", -command => sub{&imprime($mt)});
	$bLmp = $mBtnsC->Button(-text => "Limpia", 
		-command => sub { $mt->delete('0.0','end'); 
			$bImp->configure(-state => 'disabled');} );

#	@datos = muestraLista($esto);
	
	# Dibuja interfaz
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bLmp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$listaS->pack();
	$mMes->pack(-expand => 1, -fill => 'x');
	$mLista->pack(-expand => 1);
	$mBtnsC->pack();
	$mMensajes->pack(-expand => 1, -fill => 'both');

	$mt->delete('0.0','end');
	$bImp->configure(-state => 'disabled');

	bless $esto;
	return $esto;
}

# Funciones internas
sub selecciona {
	my ($jc, $Index) = @_;
	$mes = $lMeses[$Index]->[0];
}

sub muestraC {

	my ($esto, $marco) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};

	my $tc = {};
	$tc->{'I'} = 'Ingreso';
	$tc->{'E'} = 'Egreso';
	$tc->{'T'} = 'Traspaso';

	# Obtiene item seleccionado
	my @ns = $listaS->info('selection');
	my $sItem = @datos[$ns[0]];
	
	my $nmrC = $sItem->[0];
	my $tipoC = $tc->{$sItem->[1]};
	my $fecha = $ut->cFecha($sItem->[2]);
	my $glosa = decode_utf8($sItem->[4]);
	my $total = $pesos->format_number( $sItem->[3] );

	$marco->insert('end', 
	 "\nComprobante de $tipoC   # $nmrC  del  $fecha\n", 'negrita');
	$marco->insert('end', "Glosa: $glosa\n\n" , 'cuenta');
	$marco->insert('end', "Movimientos\n" , 'grupo');

	my @data = $bd->itemsC($nmrC);

	my ($algo, $mov, $cm, $ncta, $mntD, $mntH, $dt, $ci, $td, $dcm);
	my $lin1 = "Cuenta                            Debe       Haber Detalle";
	my $lin2 = "-"x73;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # Código cuenta
		$ncta = $bd->nmbCuenta($cm);
		$mntD = $mntH = $pesos->format_number(0);
		$mntD = $pesos->format_number( $algo->[2] ); 
		$mntH = $pesos->format_number( $algo->[3] );
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
		$mov1 = sprintf("%-5s %-20s %11s %11s  %-15s", $cm, decode_utf8($ncta),
			$mntD, $mntH, $dt ) ;
		$mov2 = sprintf("       %-15s %-20s", $ci, $dcm ) ;

		$marco->insert('end', "$mov1\n", 'detalle' ) ;
		if ( not ($ci eq '' ) ) { #	and $dcm eq ''
			$marco->insert('end', "$mov2\n", 'detalle' ) ;
		}
	}
	$marco->insert('end', "\nTotal: $total\n" , 'grupo');
	$bImp->configure(-state => 'active');
}

sub muestraLista ( $ ) 
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};

	my ($Numero, $Tipo, $Fecha, $Total, $Glosa) = (0 .. 4);
	
	# Obtiene lista con datos de comprobantes registrados
	my @data = $bd->listaC($mes);
	if (not @data) {
		$Mnsj = "No hay comprobantes registrados";
		return ;
	}

	# Completa TList con datos básicos del comprobante 
	my ($algo, $nm, $tp, $fch, $tt, $gl, $mov);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$nm = $algo->[$Numero]; 
		$tp = $algo->[$Tipo]; 
		$fch = $ut->cFecha($algo->[$Fecha]); 
		$tt = $pesos->format_number( $algo->[$Total] );
		$gl =  decode_utf8($algo->[$Glosa]);
		$mov = sprintf("%5s %1s %10s %12s %-25s", $nm, $tp, $fch, $tt, $gl) ;
		$listaS->insert('end', -itemtype => 'text', -text => "$mov" ) ;
	}
	# Devuelve una lista de listas con datos de los comprobantes
	return @data;
}

sub imprime ( $ )
{
	my ($esto, $marco) = @_;	
	my $ut = $esto->{'mensajes'};
	
	my $algo = $marco->get('0.0','end');

	# Genera archivo de texto
	open ARCHIVO, "> txt/cmprb.txt" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Ver archivo 'txt/cmprb.txt'"
}

sub cancela ( $ )
{
	my ($esto) = @_;	
	my $vn = $esto->{'ventana'};

	$vn->destroy();
}

# Fin del paquete
1;
