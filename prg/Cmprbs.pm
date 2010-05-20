#  Cmprbs.pm - Registra y contabiliza comprobantes
#  Forma parte del programa Quipu
# 
#  Derechos de autor: V�ctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los t�rminos previstos en la 
#  licencia incluida en este paquete 
#  UM: 20.05.2010

package Cmprbs;

use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Tk::BrowseEntry;
use Encode ;
use Number::Format;
use Date::Simple ('today');

# Variables v�lidas dentro del archivo
# Datos a registrar
my ($Numero,$Id,$Glosa,$Fecha,$TotalD,$TotalH,$TotalDf,$TotalHf,$CntaI ) ;
my ($Codigo,$Detalle,$Monto,$DH,$RUT,$Documento,$Cuenta,$Nombre,$FechaV) ;
my ($TipoCmp,$TipoD,$cTipoD,$BH,$Bco,$nBanco,$cBanco,$mBco,$Mnsj,$Empresa) ; 
# Campos
my ($codigo,$detalle,$glosa,$fecha,$totalD,$totalH,$bcos,$nombre,$fechaV ) ;
my ($monto,$debe,$haber,$cuentaI,$tipoD,$documento,$numero,$cuenta,$prd) ;
# Centro de costos
my ($CCto, $cCto, $NCCto) ;

my ($bReg, $bEle, $bNvo, $bCnt, $bImp, $bOtr) ; 	# Botones
my @dCuenta = () ;	# Lista datos cuenta
my @datos = () ;	# Li$fecha->focus;sta items del comprobante
my @listaD = () ;	# Lista tipos de documentos
my @bancos = () ;	# Lista nombre de bancos
my %tabla = () ; 	# Lista de tablas seg�n tipo de documento
my @aa = split /-/, today() ;

# Formato de n�meros
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $bd, $ut, $tipoC, $mt, $ucc, $emp, $ejer) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	$Empresa = encode_utf8( $emp );
	$prd = $ejer ;
	my %tp = $ut->tipos();
	%tabla = ('BH' => 'BoletasH' ,'FC' => 'Compras' ,'FV' => 'Ventas', 'DB' => '',
	'ND' => 'Compras', 'NC' => '', 'LT' => 'DocsE', 'CH' => 'DocsE', 'SD' => '', '' => '' ) ;
	$Nombre = "";
	$Fecha = $ut->fechaHoy();
	$Numero = $bd->numeroC() + 1;
	$Monto = $TotalD = $TotalH = $BH = 0;
	$Codigo = $cTipoD = $TipoD = $DH = $RUT = $Glosa = $cBanco = $FechaV = $Cuenta = '';
	$TipoD = $Bco = $nBanco = $cBanco = $mBco = $CCto = $NCCto = $CntaI = '' ;
	$TipoCmp = substr $tipoC, 0, 1 ;
	$Bco = $bd->ctaEsp("B");
	@bancos = $bd->datosBcs();
	# Crea archivo temporal para registrar movimientos
	$bd->creaTemp();

	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	my $alt = @bancos ? 590 : 570 ;
	$vnt->title("Registra Comprobante de $tipoC");
	$vnt->geometry("400x$alt+475+4"); # Tama�o y ubicaci�n
	
	# Defime marcos
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Comprobante $tipoC");
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Movimientos');
	my $mItems = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Detalle Movimiento');
	my $mOtros = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Cuenta Individual ');
	my $mBotonesL = $vnt->Frame(-borderwidth => 1);
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );
	
	# Barra de mensajes y bot�n de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Cmprbs'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione bot�n 'i'.";
	
	# Define Lista de datos (items del comprobante)
	my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe', -width => 60,
		-selectmode => 'single', -orient => 'horizontal', -font => $tp{mn},
		-command => sub { &modifica($esto) } );
	$esto->{'vLista'} = $listaS;
	
	# Define botones
	$bReg = $mBotonesL->Button(-text => "Modifica", 
		-command => sub { &registra($esto) } ); 
	$bEle = $mBotonesL->Button(-text => "Elimina", 
		-command => sub { &elimina($esto) } ); 
	$bNvo = $mBotonesL->Button(-text => "Agrega", 
		-command => sub { &agrega($esto) } ); 
	$bCnt = $mBotonesC->Button(-text => "Contabiliza", 
		-command => sub { &contabiliza($esto) } ); 
	$bImp = $mBotonesC->Button(-text => "Imprime", -command => sub { &imprime($esto) } ); 
	$bOtr = $mBotonesC->Button(-text => "Nuevo", -command => sub { &nuevo($esto) } ); 
	my $bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { &cancela($esto) } );

	# Define campos para datos generales del comprobante
	$numero = $mDatosC->LabEntry(-label => "Numero: ", -width => 6,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Numero, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
	$fecha = $mDatosC->LabEntry(-label => "Fecha: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Fecha );
	$glosa = $mDatosC->LabEntry(-label => "Glosa: ", -width => 35,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Glosa );
	$totalD = $mDatosC->LabEntry(-label => "Totales:  Debe ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$TotalDf, -state => 'disabled', 
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000' );
	$totalH = $mDatosC->LabEntry(-label => "Haber ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$TotalHf, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');

	# Define campos para registro de items
	$codigo = $mItems->LabEntry(-label => " Cuenta: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Codigo );
	$cuenta = $mItems->Label(-textvariable => \$Cuenta, -font => $tp{mn});
	if ($ucc) {
	  $cCto = $mItems->LabEntry(-label => " C.Costo: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$CCto );	
	  $nCCto = $mItems->Label(-textvariable => \$NCCto, -font => $tp{tx});	
	}
	$monto= $mItems->LabEntry(-label => " Monto:  ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Monto); 
	$debe = $mItems->Radiobutton( -text => "Debe", -value => 'D', 
		-variable => \$DH );
	$haber = $mItems->Radiobutton(-text => "Haber", -value => 'H', 
		-variable => \$DH );
	$detalle = $mItems->LabEntry(-label => " Detalle: ", -width => 40,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Detalle);
	$cuentaI = $mOtros->LabEntry(-label => " RUT: ", -width => 15,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'left', -textvariable => \$RUT);
	$nombre = $mOtros->Label(-textvariable => \$Nombre, -font => $tp{tx},);	
	$doc = $mOtros->Label(-text => ' Doc.');
	$tipoD = $mOtros->BrowseEntry( -variable => \$TipoD, -state => 'readonly',
		-disabledbackground => '#FFFFFC', -autolimitheight => 1,
		-disabledforeground => '#000000', -width => 12, -listwidth => 30,
		-browse2cmd => \&seleccionaD );
	if ( @bancos ) {
		$mBco = $mItems->Label(-text => "Banco:  " );
		$bcos = $mItems->BrowseEntry( -variable => \$nBanco, -state => 'readonly',
			-disabledbackground => '#FFFFFC', -autolimitheight => 1,
			-disabledforeground => '#000000', -width => 12, -listwidth => 30,
			-browse2cmd => \&seleccionaB );
		foreach $algo ( @bancos ) {
			$bcos->insert('end', decode_utf8($algo->[1]) ) ;
	  	}
	}
	# Crea opciones para elegir tipo de documento
	@listaD = $bd->datosDocs();
	push @listaD, ['SD','N.Documento','','',0];
	my $algo;
	foreach $algo ( @listaD ) {
		$tipoD->insert('end', decode_utf8($algo->[1]) ) ;
	}
	$documento = $mOtros->LabEntry(-label => "# ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Documento);		
	$fechaV = $mOtros->LabEntry(-label => "Vence: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaV );
	
	@datos = muestraLista($esto);
	if ( not @datos ) {
		$listaS->insert('end', -itemtype => 'text', 
			-text => "No hay movimientos registrados" ) ;
	}
	# Habilita validaciones
	$fecha->bind("<FocusOut>", sub { &validaFecha($ut,\$Fecha,\$fecha,1) } );
	$fechaV->bind("<FocusOut>", sub{ &validaFecha($ut,\$FechaV,\$fechaV,0)});
	if ( $ucc ) {
		$cCto->bind("<FocusIn>", sub { &buscaCta($esto) } );
		$monto->bind("<FocusIn>", sub { &buscaCC($bd) } );
	} else {
		$monto->bind("<FocusIn>", sub { &buscaCta($esto) } );
	}
	$detalle->bind("<FocusIn>", sub { &monto() } );	
	$tipoD->bind("<FocusIn>", sub { &buscaRut($esto) } );
	$documento->bind("<FocusIn>", sub { &verificaD() } );
	
	# Dibuja interfaz
	$mMensajes->pack(-expand => 1, -fill => 'both');
	$fecha->grid(-row => 0, -column => 0, -sticky => 'nw');
	$numero->grid(-row => 0, -column => 1, -sticky => 'ne');
	$glosa->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nw');
	$totalD->grid(-row => 2, -column => 0);
	$totalH->grid(-row => 2, -column => 1); 
	
	$codigo->grid(-row => 0, -column => 0, -sticky => 'nw');	
	$cuenta->grid(-row => 0, -column => 1, -columnspan => 2, -sticky => 'nw');
	if ($ucc) {
		$cCto->grid(-row => 1, -column => 0, -sticky => 'nw');
		$nCCto->grid(-row => 1, -column => 1, -columnspan => 2, -sticky => 'nw');		
	}
	$monto->grid(-row => 2, -column => 0, -sticky => 'nw');	
	$debe->grid(-row => 2, -column => 1, -sticky => 'nw');	
	$haber->grid(-row => 2, -column => 2, -sticky => 'nw');	
	$detalle->grid(-row => 3, -column => 0, -columnspan => 3, -sticky => 'nw');
	if ( @bancos ) {
		$mBco->grid(-row => 4, -column => 0, -sticky => 'ne');
		$bcos->grid(-row => 4, -column => 1, -sticky => 'nw');
	}
	$cuentaI->grid(-row => 0, -column => 0, -columnspan => 2, -sticky => 'nw');
	$nombre->grid(-row => 0, -column => 2, -columnspan => 2, -sticky => 'nw');
	$doc->grid(-row => 1, -column => 0, -sticky => 'nw');
	$tipoD->grid(-row => 1, -column => 1, -sticky => 'nw');
	$documento->grid(-row => 1, -column => 2, -sticky => 'nw');
	$fechaV->grid(-row => 1, -column => 3, -sticky => 'nw');

	$bReg->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bEle->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCnt->pack(-side => 'left', -expand => 0, -fill => 'none');
#	if ( $TipoCmp eq 'E') {
		$bImp->pack(-side => 'left', -expand => 0, -fill => 'none');
		$bOtr->pack(-side => 'left', -expand => 0, -fill => 'none');
#	}
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

	$listaS->pack();
	$mDatosC->pack();
	$mBotonesC->pack();
	$mLista->pack(-expand => 1);
	$mItems->pack(-expand => 1);

	$mOtros->pack(-side => 'top', -expand => 1, -fill => 'none');
	$mBotonesL->pack( -expand => 1);

	# Inicialmente deshabilita algunos botones
	$bReg->configure(-state => 'disabled');
	$bEle->configure(-state => 'disabled');
	$bCnt->configure(-state => 'disabled');
#	if ( $TipoCmp eq 'E') {
		$bImp->configure(-state => 'disabled');
		$bOtr->configure(-state => 'disabled');
#	}
	# y campos
	$bcos->configure(-state => 'disabled') if @bancos ;
	$cuentaI->configure(-state => 'disabled');
	$tipoD->configure(-state => 'disabled');
	$documento->configure(-state => 'disabled');
	$fechaV->configure(-state => 'disabled');
	$fecha->focus;
	
	bless $esto;
	return $esto;
}

# Funciones internas
sub seleccionaD {
	my ($jc, $Index) = @_;
	$cTipoD = $listaD[$Index]->[0];
	$BH = 1 if $cTipoD eq 'BH';
	if ( $cTipoD eq 'SD' ) {
		$documento->configure(-state => 'disabled');
	} else {
		$documento->focus;
	}
}

sub seleccionaB {
	my ($jc, $Index) = @_;
	$cBanco = $bancos[$Index]->[0];
}

sub buscaCta ( ) {

	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};

	# Comprueba largo del c�digo de la cuenta
	if (length $Codigo < 4) {
		$Mnsj = "C�digo debe tener 4 d�gitos";
		$codigo->focus;
		return;
	}
	# Busca c�digo
	@dCuenta = $bd->dtCuenta($Codigo);
	if ( not @dCuenta ) {
		$Mnsj = "Ese c�digo NO est� registrado";
		$codigo->focus;
		return ;
	} else {
		$Cuenta = decode_utf8($dCuenta[0]);
		$CntaI = $dCuenta[1];
		$Mnsj = " " ;
	}
	# Activa campos:
	# si es cuenta con detalle para Banco
	if ( $CntaI eq "B" ) {
		$bcos->configure(-state => 'normal') if @bancos ;
		$cuentaI->configure(-state => 'disabled');
		$documento->configure(-state => 'normal');
		$tipoD->configure(-state => 'normal');
		$fechaV->configure(-state => 'normal');
	}
	# si agrupa cuentas individuales
	if ($CntaI eq "I") {
		$cuentaI->configure(-state => 'normal');
		$tipoD->configure(-state => 'normal');
		$documento->configure(-state => 'normal');
		$fechaV->configure(-state => 'normal');
	}
	# o si debe registrar documentos
	if ($CntaI eq "D") {
		$tipoD->configure(-state => 'normal');
		$documento->configure(-state => 'normal');
		$fechaV->configure(-state => 'normal');
	}
	# o bien, es cuenta de resultado
	if ($Codigo =~ /^[34]/) { 
		$cCto->focus ;
	}
}

sub muestraLista ( $ ) 
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	
	# Obtiene lista con datos de itemes registrados
	my @data = $bd->datosItems($Numero);
	# Completa TList con c�digo, nombre cuenta, monto (d o h) 
	my ($algo, $mov, $cm, $mntD, $mntH,$ncta);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # C�digo cuenta
		$mntD = $pesos->format_number( $algo->[2] ); 
		$mntH = $pesos->format_number( $algo->[3] );
		$ncta = substr decode_utf8($algo->[10]),0, 24 ;
		$mov = sprintf("%-5s %-24s %11s %11s",	$cm, $ncta, $mntD, $mntH ) ;
		$listaS->insert('end', -itemtype => 'text', -text => "$mov" ) ;
	}
	# Devuelve una lista de listas con datos de las cuentas
	return @data;
}

sub agrega ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};
	
	# Verifica que se completen datos de detalle
	if (length $Codigo < 4) {
		$Mnsj = "Registre el c�digo de la cuenta";
		$codigo->focus;
		return;
	}
	if ($Monto == 0) {
		$Mnsj = "Complete el monto";
		$monto->focus;
		return ;
	}
	if ($CntaI eq "I" and $RUT eq '' ) {
		$Mnsj = "Debe registrar RUT de la Cuenta Individual";
		$cuentaI->focus;
		return;
	}
	if ($CntaI eq "I" ) { # Control del documento
		return if not validaD($bd) ;
	}
#	$Mnsj = " ";
	# Graba datos
	if ($CntaI eq "B") {
		$RUT = @bancos ? $cBanco : $Codigo ;
	}
	$bd->agregaItemT($Codigo, $Detalle, $Monto, $DH, $RUT, $cTipoD, $Documento, 
		$Cuenta, $Numero, $CCto);
	# Muestra lista modificada de cuentas
	@datos = muestraLista($esto);
	# Totaliza comprobante
	if ($DH eq 'D') {
		$TotalD += $Monto;
		$TotalDf = $pesos->format_number($TotalD);
	} else {
		$TotalH += $Monto;	
		$TotalHf = $pesos->format_number($TotalH);
	}
	limpiaCampos();

	$bcos->configure(-state => 'disabled') if @bancos ;
	$cuentaI->configure(-state => 'disabled');
	$tipoD->configure(-state => 'disabled');
	$documento->configure(-state => 'disabled');

	$codigo->focus;
}

sub validaD ( $ )
{
	my ($bd) = @_;

	# no valida en caso de pago con letras
	return 1 if $DH eq 'H' and $cTipoD eq 'LT' ; 
	
	my $tbl = $tabla{$cTipoD} ;
#	$Mnsj = " " ;
	if ( not $TipoD ) {
		$Mnsj = "Seleccione un tipo de documento";
		$tipoD->focus;
		return 0;
	} elsif (not $tbl eq '' ) {
		$tbl = 'Ventas' if $TipoCmp eq 'I' ;
		if ( not $bd->buscaFct($tbl, $RUT, $Documento, 'FechaE') ) {
			$Mnsj = "Ese documento NO est� registrado.";
			$documento->focus;
			return 0;
		}
		my $cmp = 'Pagada' ;
		$cmp = 'Estado' if $tbl eq 'DocsE' ;
		if ( $bd->buscaFct($tbl, $RUT, $Documento, $cmp ) ) {
			$Mnsj = "Ese documento ya est� pagado.";
			$documento->focus;
			return 0;
		}
		# Compara montos: pagado no puede ser mayor que el monto pendiente
		my $mnt = 0 ;
		if ( $BH ) {
			$mnt = $bd->montoBH($RUT, $Documento) ;
		} else {
			$mnt = $bd->netoFct($tbl, $RUT, $Documento) ;
		}
		if ( $Monto > $mnt ) {
			my $mt = $pesos->format_number( $mnt );
			$Mnsj = "Monto documento es: \$ $mt";
			$monto->focus;
			return 0;
		}
	}
	return 1;
}

sub buscaRut ()
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	# Valida y verifica RUT, siempre que no sea un Banco o cuenta tipo D
	if ($CntaI eq "B" or $CntaI eq "D") {
		return ;
	}
	$RUT = uc($RUT);
#	$Mnsj = " " ;
	if ( not $ut->vRut($RUT) ) {
		$Mnsj = "RUT no es v�lido";
		$cuentaI->focus;
		return;
	} else {
		my $nmb = $bd->buscaT($RUT);
		if ( not $nmb ) { # Si no est� en Terceros lo busca en Personal
			$nmb = $bd->buscaP($RUT);
			if ( not $nmb ) {
				$Mnsj = "Ese RUT No esta registrado" ;
				$cuentaI->focus;
				return;
			}
		}
		$Nombre = decode_utf8("$nmb");
	}
}

sub verificaD
{
	if ($TipoCmp eq 'I' and ( $cTipoD eq 'FC' or $BH )) {
		$Mnsj = "Tipo de documento NO corresponde";
		$tipoD->focus;
	}
	if ($TipoCmp eq 'E' and $cTipoD eq 'FV') {
		$Mnsj = "Tipo de documento NO corresponde";
		$tipoD->focus;
	}
}

sub monto 
{
	if ($DH eq '') {
		$Mnsj = "Indique tipo de movimiento";
		return ;
	}
	if ($Monto == 0) {
		$Mnsj = "Anote alguna cifra";
		$monto->focus;
	}
}

sub modifica ( )
{
	my ($esto) = @_;
	my $listaS = $esto->{'vLista'};
	my $bd = $esto->{'baseDatos'};
		
	$Mnsj = $TipoD = " ";
	if (not @datos) {
		$Mnsj = "NO hay movimientos para modificar";
		return;
	}
	$bNvo->configure(-state => 'disabled');
	$bReg->configure(-state => 'active');
	$bEle->configure(-state => 'active');
	# Obtiene item seleccionado
	my @ns = $listaS->info('selection');
	my $sItem = @datos[$ns[0]];
	# Rellena campos
	if ($sItem->[2] > 0) {
		$Monto = $sItem->[2];
		$DH = "D";
	}
	if ($sItem->[3] > 0) {
		$Monto = $sItem->[3];
		$DH = "H";
	}
	$Codigo = $sItem->[1];
	$Detalle = decode_utf8($sItem->[4]);
	$RUT = $sItem->[5];
	$cTipoD = $sItem->[6];
#	print "$RUT - $cTipoD\n";
	$TipoD = buscaTD( $cTipoD );
	$Documento = $sItem->[7];
	$CCto = $sItem->[8];
	$Cuenta = $sItem->[10];
	@dCuenta = $bd->dtCuenta($Codigo);	
	$CntaI = $dCuenta[1];
	
	$tipoD->configure(-state => 'normal') if $TipoD ;
	$documento->configure(-state => 'normal') if $Documento ;
	$cuentaI->configure(-state => 'normal') if $RUT ;
	# Obtiene Id del registro
	$Id = $sItem->[11];
}

sub buscaTD ( $ )
{
	my ($td) = @_;
	my $e ;
	for $e (@listaD) {
		return decode_utf8( $e->[1] ) if $e->[0] eq $td ; 
	}
}

sub registra ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	# Verifica la existencia del documento 
	if ($CntaI eq "I" ) {
		return if not validaD($bd) ;
	}
	# Graba datos
	$bd->grabaItemT($Codigo, $Detalle, $Monto, $DH, $RUT, $cTipoD, $Documento, 
		$CCto, $Cuenta, $Id);
	# Muestra lista actualizada de items
	@datos = muestraLista($esto);
	# Retotaliza comprobante
	( $TotalD, $TotalH ) = $bd->sumas($Numero);
	$TotalDf = $pesos->format_number($TotalD);
	$TotalHf = $pesos->format_number($TotalH);

	limpiaCampos();
	$bcos->configure(-state => 'disabled') if @bancos;
	$cuentaI->configure(-state => 'disabled');
	$tipoD->configure(-state => 'disabled');
	$documento->configure(-state => 'disabled');
	$fechaV->configure(-state => 'disabled');

	$bNvo->configure(-state => 'active');
	$bEle->configure(-state => 'disabled');
	$bReg->configure(-state => 'disabled');
}

sub elimina ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	# Graba
	$bd->borraItemT( $Id );
	# Muestra lista actualizada de items
	@datos = muestraLista($esto);
	# Retotaliza comprobante
	if ($DH eq 'D') {
		$TotalD -= $Monto;
		$TotalDf = $pesos->format_number($TotalD);
	} else {
		$TotalH -= $Monto;	
		$TotalHf = $pesos->format_number($TotalH);
	}
	
	limpiaCampos();
	$bNvo->configure(-state => 'active');
	$bEle->configure(-state => 'disabled');
	$bReg->configure(-state => 'disabled');
}

sub contabiliza ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'} ;
	
	$Mnsj = " ";
	# Verifica que se completen datos b�sicos
	if ($Glosa eq '' ) {
		$Mnsj = "Escriba alguna glosa para el comprobante";
		$glosa->focus;
		return;
	}
	if ($Fecha eq '' ) {
		$Mnsj = "Anote la fecha del comprobante";
		$fecha->focus;
		return;
	}
	# Graba datos
	my $ff = $ut->analizaFecha($Fecha);
	$bd->agregaCmp($Numero, $ff, $Glosa, $TotalD, $TipoCmp, $BH);
	$bd->actualizaCI($Numero, $ff);
	# Graba documentos de pago, si corresponde
	my $fv = '';
	$fv = $ut->analizaFecha($FechaV) if $FechaV ;
	my $tabla = ( $TipoCmp eq "I" ) ? 'DocsR' : 'DocsE' ;
	$bd->agregaDP($Numero, $ff, $tabla, $fv) if not $TipoCmp eq "T";
	
	$bCnt->configure(-state => 'disabled');
	$bImp->configure(-state => 'active');
	$bOtr->configure(-state => 'active');
	$bNvo->configure(-state => 'disabled');
}

sub nuevo ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};

	$bImp->configure(-state => 'disabled');
	$bOtr->configure(-state => 'disabled');
	$bNvo->configure(-state => 'normal');
	limpiaCampos();
	$listaS->delete(0,'end');
	$listaS->insert('end', -itemtype => 'text', 
			-text => "No hay movimientos registrados" ) ;
	$TotalD = $TotalH = 0;
	$TotalDf = $TotalHf = '';
	$Numero = $bd->numeroC() + 1;
	$glosa->delete(0,'end');
	$fecha->focus;
}

sub imprime ( $ )
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'} ;
	my $bd = $esto->{'baseDatos'};
	
	if (not $Numero) {
		$Mnsj = "Falta n�mero comprobante";
		$bImp->configure(-state => 'disable');
	} else {
		$ut->imprimirC($bd,$Numero,$Empresa);
	}
}

sub validaFecha ($ $ $ $ ) 
{
	my ($ut, $v, $c, $x) = @_;
	
	$Mnsj = " ";
	if ( not $$v ) {	
		if ($x == 0) { 
			$FechaV = $Fecha ;
			return; 
		}
		$Mnsj = "Debe colocar fecha de emisi�n";
		$$c->focus;
		return ;
	} 
	if ( not $$v =~ m|\d+/\d+/\d+| ) {
		$Mnsj = "Formato errado: debe ser dd/mm/aaa";
		$$c->focus;
	} elsif ( not $ut->analizaFecha($$v) ) {
		$Mnsj = "Fecha incorrecta";
		$$c->focus;
	}
	# Compara a�os
	my @fch = split /\//, $$v ;
	if (not $fch[2] eq $prd ) {
		$Mnsj = "A�o NO corresponde";
		$$c->focus;		
	}
}

sub cancela ( )
{
	my ($esto) = @_;	
	my $vn = $esto->{'ventana'};
	my $bd = $esto->{'baseDatos'};
	
	limpiaCampos();
	$bd->borraTemp();
	$vn->destroy();
}

sub limpiaCampos ( )
{
	$codigo->delete(0,'end');
	$detalle->delete(0,'end');
	$Monto = $BH = 0;
	$DH = $TipoD = $Documento = $RUT = $Cuenta = $cBanco = $FechaV = $Nombre = $cTipoD = '' ;
	$NCCto = $CCto = '';
	# Activa o no contabilizar el comprobante
	if ($TotalH == $TotalD) {
		$bCnt->configure(-state => 'active');
	} else {
		$bCnt->configure(-state => 'disabled');
	}
}

sub buscaCC ( $ ) {

	my ($bd) = @_;
	# Permite NO indicar C.Costo
	return if $CCto eq '' ;
	# y lo elimina si cuenta es de Activo o Pasivo
	if ($Codigo =~ /^[12]/) { 
		$Mnsj = "Centro de Costos no se aplica a esta cuenta";
		$CCto = '';
		return ;
	}
	# Busca c�digo
	my $nCentro = $bd->nombreCentro($CCto);
	if ( not $nCentro ) {
		$Mnsj = "Ese c�digo NO est� registrado";
		$NCCto = " " ;
		$cCto->focus;
	} else {
		$NCCto = substr decode_utf8($nCentro), 0, 35 ;
	}
}

# Fin del paquete
1;
