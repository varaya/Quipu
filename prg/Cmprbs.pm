#  Cmprbs.pm - Registra y contabiliza comprobantes
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) Víctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package Cmprbs;

use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Tk::BrowseEntry;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
# Datos a registrar
my ($Numero, $Id, $Glosa, $Fecha, $TotalD, $TotalH, $TotalDf, $TotalHf ) ;
my ($Codigo, $Detalle, $Monto, $DH, $CntaI, $RUT, $Documento, $Cuenta ) ;
my ($TipoCmp, $TipoD, $cTipoD, $BH, $Bco, $nBanco, $cBanco, $mBco, $Mnsj ) ; 
# Campos
my ($codigo, $detalle, $glosa, $fecha, $totalD, $totalH, $bcos ) ;
my ($monto, $debe, $haber, $cuentaI, $tipoD, $documento, $numero, $cuenta) ;

my ($bReg, $bEle, $bNvo, $bCnt) ; 	# Botones
my @dCuenta = () ;	# Lista datos cuenta
my @datos = () ;	# Lista items del comprobante
my @listaD = () ;	# Lista tipos de documentos
my @bancos = () ;	# Lista nombre de bancos

# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $bd, $ut, $tipoC, $mt) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	$Fecha = $ut->fechaHoy();
	$Numero = $bd->numeroC() + 1;
	$Monto = $TotalD = $TotalH = $BH = 0;
	$Codigo = $cTipoD = $TipoD = $DH = $RUT = $Glosa = $cBanco = '';
	$TipoCmp = substr $tipoC, 0, 1 ;
	$Bco = $bd->ctaEsp("B");
	@bancos = $bd->datosBcs();
	
	# Crea archivo temporal para registrar movimientos
	$bd->creaTemp();
		
	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	my $alt = @bancos ? 550 : 520 ;
	$vnt->title("Registra Comprobante de $tipoC");
	$vnt->geometry("400x$alt+475+4"); # Tamaño y ubicación
	
	# Defime marcos
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Comprobante $tipoC");
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Movimientos');
	my $mItems = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Detalle ');
	my $mOtros = $vnt->Frame(-borderwidth => 0);
	my $mCntaI = $mOtros->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Cuenta individual ');
	my $mDoc = $mOtros->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Datos documento ');
	my $mBotonesL = $vnt->Frame(-borderwidth => 1);
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Cmprbs'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
	
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
#	$codigo->bind("<FocusOut>", sub { &buscaCta($esto) } );
	$cuenta = $mItems->Label(-textvariable => \$Cuenta, -font => $tp{mn});
	$monto= $mItems->LabEntry(-label => " Monto:  ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Monto); 
	$monto->bind("<FocusIn>", sub { &buscaCta($esto) } );
	$debe = $mItems->Radiobutton( -text => "Debe", -value => 'D', 
		-variable => \$DH );
	$haber = $mItems->Radiobutton(-text => "Haber", -value => 'H', 
		-variable => \$DH );
	$detalle = $mItems->LabEntry(-label => " Detalle: ", -width => 40,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Detalle);

	$cuentaI = $mCntaI->LabEntry(-label => " RUT: ", -width => 15,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$RUT);
		
	$tipoD = $mDoc->BrowseEntry( -variable => \$TipoD, -state => 'readonly',
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
	my $algo;
	foreach $algo ( @listaD ) {
		$tipoD->insert('end', decode_utf8($algo->[1]) ) ;
	}

	$documento = $mDoc->LabEntry(-label => "# ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Documento);		

	$documento = $mDoc->LabEntry(-label => "# ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Documento);		
	
	@datos = muestraLista($esto);
	if ( not @datos ) {
		$listaS->insert('end', -itemtype => 'text', 
			-text => "No hay movimientos registrados" ) ;
	}
	
	# Dibuja interfaz
	$fecha->grid(-row => 0, -column => 0, -sticky => 'nw');
	$numero->grid(-row => 0, -column => 1, -sticky => 'ne');
	$glosa->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nw');
	$totalD->grid(-row => 2, -column => 0);
	$totalH->grid(-row => 2, -column => 1); 
	
	$codigo->grid(-row => 0, -column => 0, -sticky => 'nw');	
	$cuenta->grid(-row => 0, -column => 1, -columnspan => 2, -sticky => 'nw');

	$monto->grid(-row => 1, -column => 0, -sticky => 'nw');	
	$debe->grid(-row => 1, -column => 1, -sticky => 'nw');	
	$haber->grid(-row => 1, -column => 2, -sticky => 'nw');	
	$detalle->grid(-row => 2, -column => 0, -columnspan => 3, -sticky => 'nw');
	if ( @bancos ) {
		$mBco->grid(-row => 3, -column => 0, -sticky => 'ne');
		$bcos->grid(-row => 3, -column => 1, -sticky => 'nw');
	}
	$cuentaI->pack();
	$tipoD->grid(-row => 3, -column => 0, -sticky => 'nw');
	$documento->grid(-row => 3, -column => 1, -sticky => 'nw');

	$bReg->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bEle->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCnt->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

	$listaS->pack();
	$mDatosC->pack();
	$mBotonesC->pack();
	$mLista->pack(-expand => 1);
	$mItems->pack(-expand => 1);

	$mCntaI->pack(-side => 'left', -expand => 0, -fill => 'none');
	$mDoc->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mOtros	->pack(-expand => 1);
	$mBotonesL->pack( -expand => 1);
	$mMensajes->pack(-expand => 1, -fill => 'both');

	# Inicialmente deshabilita algunos botones
	$bReg->configure(-state => 'disabled');
	$bEle->configure(-state => 'disabled');
	$bCnt->configure(-state => 'disabled');
	$bcos->configure(-state => 'disabled');

	bless $esto;
	return $esto;
}

# Funciones internas
sub seleccionaD {
	my ($jc, $Index) = @_;
	$cTipoD = $listaD[$Index]->[0];
	$BH = 1 if $cTipoD eq 'BH';
	$documento->focus;
}

sub seleccionaB {
	my ($jc, $Index) = @_;
	$cBanco = $bancos[$Index]->[0];
}
sub buscaCta ( ) {

	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};

	$Mnsj = " ";
	# Comprueba largo del código de la cuenta
	if (length $Codigo < 4) {
		$Mnsj = "Código debe tener 4 dígitos";
		$codigo->focus;
		return;
	}
	# Busca código
	@dCuenta = $bd->dtCuenta($Codigo);
	my $nc = @dCuenta;
	if ( $nc == 0 ) {
		$Mnsj = "Ese código NO está registrado";
		$codigo->focus;
	} else {
		$Cuenta = decode_utf8($dCuenta[0]);
		$CntaI = $dCuenta[1];
	}
	# Si es cuenta con detalle para Banco
	if ($CntaI eq "B") {
		$bcos->configure(-state => 'active') ;
		$cuentaI->configure(-state => 'disabled');
	}
}

sub muestraLista ( $ ) 
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	
	# Obtiene lista con datos de itemes registrados
	my @data = $bd->datosItems($Numero);
	# Completa TList con código, nombre cuenta, monto (d o h) 
	my ($algo, $mov, $cm, $mntD, $mntH);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # Código cuenta
		$mntD = $pesos->format_number( $algo->[2] ); 
		$mntH = $pesos->format_number( $algo->[3] );
		$mov = sprintf("%-5s %-30s %11s %11s", 
			$cm, decode_utf8($algo->[9]), $mntD, $mntH ) ;
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
	
	my ($tabla);
	$Mnsj = " ";
	# Verifica que se completen datos de detalle
	if (length $Codigo < 4) {
		$Mnsj = "Registre el código de la cuenta";
		$codigo->focus;
		return;
	}
	if ($Monto == 0) {
		$Mnsj = "Anote alguna cifra";
		$monto->focus;
		return;
	}
	if ($DH eq '') {
		$Mnsj = "Indique tipo de movimiento";
		return;
	}
	if ($CntaI eq "I" and $RUT eq '' ) {
		$Mnsj = "Debe registrar RUT de la Cuenta Individual";
		$cuentaI->focus;
		return;
	}
	if ($CntaI eq "I" ) {
		# Valida y verifica RUT
		if ( not $ut->vRut($RUT) ) {
			$Mnsj = "RUT no es válido";
			$cuentaI->focus;
			return;
		} else {
			my $nmb = $bd->buscaT($RUT);
			if ( not $nmb ) {
				$Mnsj = "Ese RUT No esta registrado" ;
				$cuentaI->focus;
				return;
			}
			$Mnsj = $nmb;
		}
		# Control del documento [experimental]
		if ( not $TipoD ) {
			$Mnsj = "Seleccione un tipo de documento";
			$tipoD->focus;
			return;
		} else {
			$tabla = 'BoletasH' if $cTipoD eq 'BH';
			$tabla = 'Compras' if $cTipoD eq 'FC';
			$tabla = 'Ventas' if $cTipoD eq 'FV';
			if (not $bd->buscaFct($tabla, $RUT, $Documento) ) {
				$Mnsj = "Ese documento NO está registrado.";
				$documento->focus;
				return;
			}
		}
	}
	# Graba datos
	if ($CntaI eq "B") {
		$RUT = $cBanco ;
	}
	$bd->agregaItemT($Codigo, $Detalle, $Monto, $DH, $RUT, $cTipoD, $Documento, 
		$Cuenta, $Numero);
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
	$bcos->configure(-state => 'disabled') ;
	$cuentaI->configure(-state => 'active');
	$codigo->focus;
}

sub modifica ( )
{
	my ($esto) = @_;
	my $listaS = $esto->{'vLista'};
	my $bd = $esto->{'baseDatos'};
		
	$Mnsj = " ";
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
	$TipoD = $sItem->[6];
	$Documento = $sItem->[7];
	$Cuenta = $sItem->[9];	

	# Obtiene Id del registro
	$Id = $sItem->[10];
}

sub registra ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	# Graba datos
	$bd->grabaItemT($Codigo, $Detalle, $Monto, $DH, $RUT, $TipoD, $Documento, 
		$Cuenta, $Id);
	# Muestra lista actualizada de items
	@datos = muestraLista($esto);
	# Retotaliza comprobante
	( $TotalD, $TotalH ) = $bd->sumas($Numero);
	$TotalDf = $pesos->format_number($TotalD);
	$TotalHf = $pesos->format_number($TotalH);

	limpiaCampos();
	
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
	my $listaS = $esto->{'vLista'};
	my $ut = $esto->{'mensajes'} ;
	
	$Mnsj = " ";
	# Verifica que se completen datos básicos
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
	$ff =~ s/-//g ; # Convierte a formato AAAAMMDD
	$bd->agregaCmp($Numero, $ff, $Glosa, $TotalD, $TipoCmp, $BH);
	$bd->actualizaCI($Numero, $ff);
	
	limpiaCampos();

	$bCnt->configure(-state => 'disabled');
	$listaS->delete(0,'end');
	$listaS->insert('end', -itemtype => 'text', 
			-text => "No hay movimientos registrados" ) ;
	# Inicializa variables
	$TotalD = $TotalH = 0;
	$TotalDf = $TotalHf = '';
	$Numero = $bd->numeroC() + 1;
	$glosa->delete(0,'end');
	$fecha->focus;
}

sub cancela ( )
{
	my ($esto) = @_;	
	my $vn = $esto->{'ventana'};
	my $bd = $esto->{'baseDatos'};
	
	$bd->borraTemp();
	$vn->destroy();
}

sub limpiaCampos ( )
{
	$codigo->delete(0,'end');
	$detalle->delete(0,'end');
	$Monto = $BH = 0;
	$DH = $TipoD = $Documento = $RUT = $Cuenta = $cBanco = '';
	
	# Activa o no contabilizar el comprobante
	if ($TotalH == $TotalD) {
		$bCnt->configure(-state => 'active');
	} else {
		$bCnt->configure(-state => 'disabled');
	}
}

# Fin del paquete
1;
