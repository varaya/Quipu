#  CDcmts.pm - Consulta e imprime documentos individuales
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM: 09.12.2009

package CDcmts;

use Tk::TList;
use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
my @datos = () ;	# Lista items del documento
my @lMeses = () ;
my ($bCan, $bImp, $td, $Tipo, $ord, $tabla, $mes, $nMes) ; 
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');

sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $tipo) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	my %tp = $ut->tipos();
	$mes = $td = $nMes = '';
	$ord = 'RUT' ; # ordenamiento primario
	$Tipo = $tipo;
	my $tx = 'FV';
	if ($Tipo eq 'Recibidos') { $tx = 'FC';}
	
	$Fecha = $ut->fechaHoy();
	
	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Consulta Documento");
	$vnt->geometry("400x300+475+4"); # Tamaño y ubicación
	
	# Define marcos
	my $mListaT = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Documentos $tipo");
	my $mLista = $vnt->Frame(-borderwidth => 1);
	my $mOrden = $vnt->Frame(-borderwidth => 1);
	my $mMes = $vnt->Frame(-borderwidth => 1);
	my $mBtnsC = $vnt->Frame(-borderwidth => 1);
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
	
	my $tdF = $mListaT->Radiobutton( -text => "Facturas", -variable => \$td,
	-value => $tx, -command => sub { muestraL($esto);} );
	$tdF->pack(-side => "left", -anchor => "e");
	my $tdNC = $mListaT->Radiobutton( -text => "N. Credito",-variable => \$td,
	-value => 'NC', -command => sub { muestraL($esto);} );
	$tdNC->pack(-side => "left", -anchor => "e");
	my $tdND = $mListaT->Radiobutton( -text => "N. Debito",-variable => \$td,
	-value => 'ND', -command => sub { muestraL($esto);} );
	$tdND->pack(-side => "left", -anchor => "e");
	if ($Tipo eq 'Recibidos') {
		my $tdBH = $mListaT->Radiobutton( -text => "B. Honorarios", -value => 'BH',
			-variable => \$td, -command => sub { muestraL($esto);});
		$tdBH->pack(-side => "left", -anchor => "e");
	}

	my $to = $mOrden->Label( -text => "Ordenado por: ");
	my $oR = $mOrden->Radiobutton( -text => "RUT", -variable => \$ord,
	-value => 'RUT', -command => sub { muestraL($esto);} );
	my $oN = $mOrden->Radiobutton( -text => "Número", -variable => \$ord,
	-value => 'Numero', -command => sub { muestraL($esto);} );
	my $oF = $mOrden->Radiobutton( -text => "Fecha", -variable => \$ord,
	-value => 'FechaE', -command => sub { muestraL($esto);} );
	$to->pack(-side => "left", -anchor => "e");
	$oR->pack(-side => "left", -anchor => "e");
	$oN->pack(-side => "left", -anchor => "e");
	$oF->pack(-side => "left", -anchor => "e");
	# Define campo para seleccionar mes
	my $tMes = $mMes->Label(-text => "Seleccione mes ");
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
	$tMes->pack(-side => "left", -anchor => "nw");
	$meses->pack(-side => "left", -anchor => "nw");
	
	# Define Lista de documentos
	my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe', -width => 80,
		-selectmode => 'single', -orient => 'horizontal', -font => $tp{mn},
		-command => sub { &muestraD($esto, $mt) } );
	$esto->{'vLista'} = $listaS;
	
	# Define botones
	$bCan = $mBtnsC->Button(-text => "Cancela",
		-command => sub { &cancela($esto, $mt) } );
	$bImp = $mBtnsC->Button(-text => "Archivo", -command => sub{&imprime($mt)});
	$bLmp = $mBtnsC->Button(-text => "Limpia", 
		-command => sub { $mt->delete('0.0','end');
			$bImp->configure(-state => 'disabled'); } );
	
	# Dibuja interfaz
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bLmp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$listaS->pack();
	$mListaT->pack(-expand => 1, -fill => 'x');
	$mOrden->pack(-expand => 1, -fill => 'x');
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

sub muestraD {

	my ($esto, $marco) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};
	my $listaS = $esto->{'vLista'};

	# Obtiene item seleccionado
	my @ns = $listaS->info('selection');
	my $sItem = @datos[$ns[0]];

	my ($nmr,$fch,$tt,$rt,$nmb,$iva,$aft,$ext,$nmc,$fv,$ab,$pg,$fp,$tx,$gl);
	$rt = $sItem->[0];
	$nmr = $sItem->[1];
	$fch = $ut->cFecha($sItem->[2]);
	$tt = $pesos->format_number($sItem->[3]);
	$nmb = $sItem->[4];

	my @dts = $bd->datosFct($tabla,$rt,$nmr);
	if ( $tabla eq 'BoletasH' ) { 
		$aft = $pesos->format_number($sItem->[3] - $dts[3] ); #
		$iva = $pesos->format_number($dts[4]); # Corresponde a Impto. Retenido
		$nmc = $dts[5];
		$fv = $ut->cFecha($dts[6]);
		$ab = $pesos->format_number($dts[7]);
		$pg = $dts[8];
		$fp = $ut->cFecha($dts[9]);
		$gl = decode_utf8($dts[10]);
		$tx = "Boleta";
	} else {
		$iva = $pesos->format_number($dts[4]);
		$aft = $pesos->format_number($dts[5]);
		$ext = $pesos->format_number($dts[6]);
		$nmc = $dts[7];
		$fv = $ut->cFecha($dts[8]);
		$ab = $pesos->format_number($dts[9]);
		$pg = $dts[10];
		$fp = $ut->cFecha($dts[11]);
		$gl = decode_utf8($dts[12]);
		$tx = "Factura";
	}
	# Muestra datos del documento
	my $mv;
	$marco->insert('end', "$tx  # $nmr  del  $fch\n", 'negrita');
	$marco->insert('end', "RUT: $rt  $nmb  \n\n" , 'grupo');
	$marco->insert('end', "Glosa: $gl   Vence: $fv\n" , 'cuenta');
	$marco->insert('end', "Detalle:\n" , 'cuenta');
	if ( $tabla eq 'BoletasH' ) { 
	  $marco->insert('end', "     Total   Impuesto       Neto\n");
	  $mv = sprintf("%10s %10s %10s ", $tt, $iva, $aft) ;
	} else {
	  $marco->insert('end', "     Total        IVA     Afecto     Exento\n");
	  $mv = sprintf("%10s %10s %10s %10s ", $tt, $iva, $aft, $ext) ;
	}
	$marco->insert('end', "$mv\n" ) ;
	if ($ab eq '0') {
		$marco->insert('end', "No hay abonos registrados.\n" ) ;
	} else {
		$marco->insert('end', "Abonos: $ab  Fecha: $fp\n" ) ;
	}
	$bImp->configure(-state => 'active');
}

sub muestraL ( $ ) 
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	$tabla = 'Ventas';
	$tabla = 'Compras' if $Tipo eq 'Recibidos' ;
	$tabla = 'BoletasH' if $td eq 'BH' ;
	my $td2 = '';
	my ($Rut, $Numero, $Fecha, $Total, $Nombre) = (0 .. 4);
	# Obtiene lista con datos de comprobantes registrados
	$td2 = 'FR' if $td eq 'FC';
	$td2 = 'FE' if $td eq 'FV';
	my @data = $bd->listaD($tabla,$td,$ord,$mes,$td2);
	$listaS->delete(0,'end');
	if (not @data) {
		$listaS->insert('end', -itemtype => 'text', 
			-text => "No hay documentos registrados." ) ;
		return ;
	}

	# Completa TList con datos básicos del comprobante 
	my ($algo, $nm, $fch, $tt, $mov, $nmb);
	foreach $algo ( @data ) {
		$nm = $algo->[$Numero]; 
		$rt = $algo->[$Rut]; 
		$nmb = decode_utf8($algo->[$Nombre]);
		$fch = $ut->cFecha($algo->[$Fecha]); 
		$tt = $pesos->format_number( $algo->[$Total] );
		$mov = sprintf("%6s %10s %12s  %10s %-25s",$nm,$fch,$tt,$rt,$nmb) ;
		$listaS->insert('end', -itemtype => 'text', -text => "$mov" ) ;
	}
	@datos = @data;
}

sub imprime ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');

	# Genera archivo de texto
	open ARCHIVO, "> txt/dcmnt.txt" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Ver archivo 'txt/dcmnt.txt'"
}

sub cancela ( $ )
{
	my ($esto, $marco) = @_;	
	my $vn = $esto->{'ventana'};

	$vn->destroy();
}

# Fin del paquete
1;
