#  NtsC.pm - Registra y contabiliza Notas de Crédito emitidas o recibidas
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varayar@programmers.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM : 23.06.2009

package NtsC;

use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
# Datos a registrar
my ($Numero, $Id, $Glosa, $Fecha, $Neto, $Iva, $AE, $Total,$Nombre) ;
my ($Codigo, $Detalle, $Monto, $DH, $CntaI, $RUT, $Documento, $Cuenta) ;
my ($TipoCmp, $TipoD, $CtaIVA, $NombreCi, $NombreCt) ;
my ($TotalI, $TablaD, $CC, $TCtaT, $Mnsj, $FechaC, $TipoF, $NmrI, $tpD );
# Campos
my ($codigo, $detalle, $glosa, $fecha, $neto, $iva, $especial, $ctaIVA) ;
my ($monto, $rut, $tipoD, $documento, $numero, $cuenta, $nombre) ;
my ($nCtaIVA, $total, $ctaT, $nCtaT, $fechaC);
# Campos y datos opcionales para Centro de Costos
my ($CCto, $cCto, $ncCto, $NCCto, $pIVA, $SGrupo) ;
# Botones
my ($bReg, $bEle, $bNvo, $bCnt) ; 
# Listas de datos	
my @dCuenta = () ;	# Cuenta de mayor
my @datos = () ;	# Items del comprobante
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $bd, $ut, $tipoF, $mt, $ucc, $pIVA ) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
	$esto->{'ventana'} = $vp;
	$esto->{'marcoT'} = $mt;

	# Inicializa variables
	my %tp = $ut->tipos();
	$Numero = $bd->numeroC() + 1;
	$FechaC = $ut->fechaHoy();
	$RUT = $NmrI = $TipoF = $Documento = '';
	inicializaV();
	$AE = 'A' ;
	$TipoCmp = "T" ;
	$TipoD = 'NC';
	if ($tipoF eq 'Recibida') {
		$TablaD = 'Compras'; # Donde se registra el documento
		# como se contabiliza el detalle de la NC
		$DH = 'D';
		$tipoD = 'Cargo'; # sólo titulo
		# como se contabiliza total NC
		$CC = 'H';
		$TCtaT = 'abono'; # es parte de un mensaje
		$tpD = "FC";
	} else { # NC emitida
		$DH = 'H';
		$tipoD = 'Abono';
		$TablaD = 'Ventas';
		$CC = 'D';
		$TCtaT = 'cargo';
		$tpD =  "FV";
	}
	my @dtc = $bd->buscaDoc($tpD) ;
	$CtaT =  $dtc[1];
	$CtaIVA =  $dtc[2];
	
	# Crea archivo temporal para registrar movimientos
	$bd->creaTemp();
	
	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	my $alt = $ucc ? 655 : 570  ;
	$vnt->title("Registra Nota de Crédito");
	$vnt->geometry("420x$alt+475+4"); # Tamaño y ubicación
	
	# Defime marcos
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Nota de Crédito $tipoF");
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Cuentas de $tipoD");
	my $mItems = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Detalle $tipoD");
	my $mBotonesL = $vnt->Frame(-borderwidth => 1);
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'NtsC'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
	
	# Define Lista de datos (cuentas de cargo o de abono)
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
	if ( $tpD eq 'FV' ) {
		my $bNula = $mBotonesC->Button(-text => "Nula", 
			-command => sub { &fNula($esto) } );
		$bNula->pack(-side => 'right', -expand => 0, -fill => 'none');
	}

	# Define campos para datos generales de la NC
	$documento = $mDatosC->LabEntry(-label => "NC # ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Documento);
	$fm = $mDatosC->Radiobutton( -text => "Manual", -value => 'M', 
		-variable => \$TipoF );
	$fe = $mDatosC->Radiobutton( -text => "Electrónica", -value => 'E', 
		-variable => \$TipoF );
	$rut = $mDatosC->LabEntry(-label => "RUT:  ", -width => 15,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'left', -textvariable => \$RUT);
	$nombre = $mDatosC->Label(	-textvariable => \$Nombre, -font => $tp{tx} );
	$fecha = $mDatosC->LabEntry(-label => "Fecha Emisión: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Fecha );
	$glosa = $mDatosC->LabEntry(-label => "Glosa: ", -width => 35,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Glosa );
	$neto = $mDatosC->LabEntry(-label => "Neto: ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Neto);
	$afecto = $mDatosC->Radiobutton( -text => "Afecto", -value => 'A', 
		-variable => \$AE, -command => sub { &activa() } );
	$exento = $mDatosC->Radiobutton( -text => "Exento", -value => 'E', 
		-variable => \$AE, -command => sub { &desactiva() } );
	$iva = $mDatosC->LabEntry(-label => "IVA:   ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Iva );
	$ctaIVA = $mDatosC->LabEntry(-label => "Cuenta: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CtaIVA );
	$nCtaIVA = $mDatosC->Label(	-textvariable => \$NombreCi, -font => $tp{tx} );

	$total = $mDatosC->LabEntry(-label => "Total:     ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Total );
	$ctaT = $mDatosC->LabEntry(-label => "Cuenta: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CtaT );
	$nCtaT = $mDatosC->Label( -textvariable => \$NombreCt, -font => $tp{tx} );
	$fechaC = $mDatosC->LabEntry(-label => "Contabilizada: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaC );
	$nmrO = $mDatosC->LabEntry(-label => "Nº I: ", -width => 4,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$NmrI);
	$numero = $mDatosC->LabEntry(-label => "$TipoCmp #: ", -width => 6,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Numero, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
	
	# Define campos para registro de items
	$codigo = $mItems->LabEntry(-label => " Cuenta: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Codigo );
	$cuenta = $mItems->Label(-textvariable => \$Cuenta, -font => $tp{tx});
	if ($ucc) {
	  $cCto = $mItems->LabEntry(-label => " C.Costo: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CCto );	
	  $nCCto = $mItems->Label(-textvariable => \$NCCto, -font => $tp{tx});	
	}
	$monto= $mItems->LabEntry(-label => " Monto:  ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Monto); 
	$detalle = $mItems->LabEntry(-label => " Detalle: ", -width => 40,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Detalle);
	
	# Habilita validación de datos
	$fecha->bind("<FocusIn>", sub { &buscaDoc($esto) } );	
	$glosa->bind("<FocusIn>", sub { &validaFecha($ut,\$Fecha,\$fecha,1) } );
	$nmrO->bind("<FocusIn>", sub { &validaFechaC($ut, $bd) } );
	$nmrO->bind("<FocusOut>", sub { &validaNI($bd) } );
	$neto->bind("<FocusOut>", sub { &totaliza() } );	
	$iva->bind("<FocusIn>", sub { $Iva = int( $Neto * $pIVA / 100 + 0.5) ;} );
	$iva->bind("<FocusOut>", sub { &totaliza() } );	
	$ctaIVA->bind("<FocusOut>", sub { 
		&buscaCuenta($bd, \$CtaIVA, \$NombreCi, \$ctaIVA) } );
	$ctaT->bind("<FocusOut>", sub { 
		&buscaCuenta($bd, \$CtaT, \$NombreCt, \$ctaT) } );
	$codigo->bind("<FocusIn>", sub { &datosF($esto) } );
	if ( $ucc ) {
		$cCto->bind("<FocusIn>", sub { 
			&buscaCuenta($bd, \$Codigo, \$Cuenta, \$codigo) } );
		$monto->bind("<FocusIn>", sub { &buscaCC($bd) } );
	} else {
		$monto->bind("<FocusIn>", sub { 
			&buscaCuenta($bd, \$Codigo, \$Cuenta, \$codigo) } );
	}

	@datos = muestraLista($esto);
	if (not @datos) {
		$listaS->insert('end', -itemtype => 'text', 
			-text => "No hay movimientos registrados" ) ;
	}
	
	# Dibuja interfaz
	$mMensajes->pack(-expand => 1, -fill => 'both');
	$documento->grid(-row => 0, -column => 0, -sticky => 'nw');
	if ( $tpD eq 'FC' ) {
		$fm->grid(-row => 0, -column => 1, -sticky => 'nw');
		$fe->grid(-row => 0, -column => 2, -sticky => 'nw');
	}
	$rut->grid(-row => 1, -column => 0, -sticky => 'nw');
	$nombre->grid(-row => 1, -column => 1, -columnspan => 2, -sticky => 'nw');
	$fecha->grid(-row => 2, -column => 0, -columnspan => 3, -sticky => 'nw');
	$glosa->grid(-row => 3, -column => 0, -columnspan => 3, -sticky => 'nw');
	$neto->grid(-row => 4, -column => 0, -sticky => 'nw');
	$afecto->grid(-row => 4, -column => 1, -sticky => 'nw');	
	$exento->grid(-row => 4, -column => 2, -sticky => 'nw');	
	$iva->grid(-row => 5, -column => 0, -sticky => 'nw');
	$ctaIVA->grid(-row => 5, -column => 1, -columnspan => 2, -sticky => 'nw');
	$nCtaIVA->grid(-row => 6, -column => 1, -columnspan => 2, -sticky => 'nw'); 
	$total->grid(-row => 7, -column => 0, -sticky => 'nw'); 
	$ctaT->grid(-row => 7, -column => 1, -columnspan => 2, -sticky => 'nw'); 
	$nCtaT->grid(-row => 8, -column => 1, -columnspan => 2, -sticky => 'nw'); 
	$fechaC->grid(-row => 9, -column => 0, -sticky => 'nw');
	$nmrO->grid(-row => 9, -column => 1, -sticky => 'ne');
	$numero->grid(-row => 9, -column => 2, -sticky => 'ne');
	
	$codigo->grid(-row => 0, -column => 0, -sticky => 'nw');	
	$cuenta->grid(-row => 0, -column => 1, -columnspan => 2, -sticky => 'nw');
	if ($ucc) {
		$cCto->grid(-row => 1, -column => 0, -sticky => 'nw');
		$nCCto->grid(-row => 1, -column => 1, -columnspan => 2, -sticky => 'nw');		
	}
	$monto->grid(-row => 2, -column => 0, -sticky => 'nw');	
	$detalle->grid(-row => 3, -column => 0, -columnspan => 2, -sticky => 'nw');
	
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
	$mBotonesL->pack( -expand => 1);

	# Inicialmente deshabilita algunos botones
	$bReg->configure(-state => 'disabled');
	$bEle->configure(-state => 'disabled');
	$bCnt->configure(-state => 'disabled');
	
	$documento->focus;

	bless $esto;
	return $esto;
}

# Funciones internas
sub totaliza ( ) 
{
	$Total = $Neto + $Iva
}

sub desactiva ( ) 
{
	$iva->configure(-state => 'disabled');
	$ctaIVA->configure(-state => 'disabled');	
}

sub activa ( ) 
{
	$iva->configure(-state => 'normal');
	$ctaIVA->configure(-state => 'normal');	
}

sub validaFecha ( $ $ $ $ ) 
{
	my ($ut, $v, $c, $x) = @_;
	
	$Mnsj = " ";
	if ($$v eq '' ) {
		$Mnsj = "Debe colocar fecha de emisión";
		if ($x == 0) { return }
	}
	# Comprueba si la fecha está escrita correctamente
	if ( not $$v =~ m|\d+/\d+/\d+| ) {
		$Mnsj = "Problema con formato. Debe ser dd/mm/aaa";
		$$c->focus;
	} elsif ( not $ut->analizaFecha($$v) ) {
		print chr 7 ;
		$Mnsj = "Fecha incorrecta";
		$$c->focus;
	}
}

sub buscaCuenta ( $ $ $ $ ) 
{
	my ($bd, $a, $b, $c) = @_;

	$Mnsj = " ";
	# Comprueba largo del código de la cuenta
	if (length $$a < 4) {
		$Mnsj = "Código debe tener 4 dígitos";
		$$c->focus;
		return;
	}
	# Busca código
	@dCuenta = $bd->dtCuenta($$a);
	if ( not @dCuenta ) {
		$Mnsj = "Ese código NO está registrado";
		$$c->focus;
	} else {
		$$b = substr decode_utf8(" $dCuenta[0]"),0,35;
		$SGrupo = $dCuenta[2] ;
	}
}

sub buscaCC ( $ ) {

	my ($bd) = @_;

#	$Mnsj = " ";
	# La cuenta debe ser de Pérdida o Ganancia para aplicar C Costo
	if (not $SGrupo =~ /^[34]/) { 
		$Mnsj = "No aplica el Centro de Costo.";
		return ; 
	}
	# Comprueba largo del código del Centro de Costo
	if (length $CCto < 3) {
		$Mnsj = "Código debe tener 3 dígitos";
		$cCto->focus;
		return;
	}
	# Busca código
	my $nCentro = $bd->nombreCentro($CCto);
	if ( not $nCentro ) {
		$Mnsj = "Ese código NO está registrado";
		$NCCto = " " ;
		$cCto->focus;
	} else {
		$NCCto = decode_utf8($nCentro);
	}
}

sub buscaDoc ( $ ) # Valida Rut y evita que se registre dos veces una misma ND
{ 
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	if ($Documento eq '') {
		$Mnsj = "Registre número de la ND";
		$documento->focus;
		return;
	}
	# Valida formato número entero
	if (not $Documento =~ /^(\d+)$/) {
		$Mnsj = "NO es número";
		$documento->focus;
		return ;
	}
	# Busca RUT
	if (not $RUT) {
		$Mnsj = "Debe registrar un RUT.";
		$rut->focus;
		return;
	}
	$RUT = uc($RUT);
	if ( not $ut->vRut($RUT) ) {
		$Mnsj = "El RUT no es válido";
		$rut->focus;
		return;
	} else {
		my $nmb = $bd->buscaT($RUT);
		if (not $nmb) {
			$Mnsj = "Curioso: ese RUT no aparece registrado.";
			$rut->focus;
			return;
		} 
		$Nombre = decode_utf8("  $nmb");
	}
	# Ahora busca ND
	my $fct = $bd->buscaFct($TablaD, $RUT, $Documento);
	if ($fct) {
		$Mnsj = "Esa NC ya está registrada.";
		$documento->focus;
		return;
	}
	$Glosa = "$TipoD# $Documento$Nombre" ;
	$Mnsj = " ";
}

sub datosF ( ) # Verifica los datos mínimos para anotar un item
{ 
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

#	$Mnsj = " ";
	if ($RUT eq '') {
		$Mnsj = "Indique RUT.";
		$rut->focus;
		return;
	}
	if ($Documento eq '') {
		$Mnsj = "Primero registre número de la NC";
		$documento->focus;
		return;
	}
	# Valida fecha contabilización
	if (not $FechaC =~ m|\d+/\d+/\d+|) {
		$Mnsj = "Problema con formato fecha";
		$fechaC->focus;
		return ;
	} elsif ( not $ut->analizaFecha($FechaC) ) {
		$Mnsj = "Fecha incorrecta" ;
		$fechaC->focus ;
		return ;
	}
	# Determina el número de ingreso
	my $mes = substr $FechaC,3,2 ; # Extrae mes
	$mes =~ s/^0// ; # Elimina '0' al inicio
	$NmrI = $bd->numeroI($TablaD, $mes, $TipoD) + 1 ; 

	# Define una propuesta de detalle para los itemes
	$Detalle = "$TipoD# $Documento $RUT" ;
}

sub validaFechaC ( $ $)
{
	my ($ut, $bd) = @_;
	
	if ($FechaC eq '' ) {
		$Mnsj = "Anote la fecha de contabilización.";
		$fechaC->focus;
		return 0;
	}
	# Valida fecha contabilización
	if (not $FechaC =~ m|\d+/\d+/\d+|) {
		$Mnsj = "Problema con formato fecha";
		$fechaC->focus;
		return 0;
	} elsif ( not $ut->analizaFecha($FechaC) ) {
		$Mnsj = "Fecha incorrecta" ;
		$fechaC->focus ;
		return 0;
	}
	
	return 1 ;
}

sub validaNI ( $ )
{
	my ($bd) = @_;
	
	my $mes = substr $FechaC,3,2 ; # Extrae mes
	$mes =~ s/^0// ; # Elimina '0' al inicio
	if ( $bd->numeroI($TablaD, $mes, $tpD, $NmrI) ) {
		$Mnsj = "Número existe";
		$nmrO->focus;
		return ;
	}
	$Mnsj = " ";
}

sub muestraLista ( $ ) 
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	
	# Obtiene lista con datos de ítemes registrados
	my @data = $bd->datosItems($Numero);

	# Completa TList con código, nombre cuenta, monto (d o h) 
	my ($algo, $mov, $cm, $mntD, $mntH);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # Código cuenta
		$mntD = $pesos->format_number( $algo->[2] ); 
		$mntH = $pesos->format_number( $algo->[3] );
		$cta = substr decode_utf8($algo->[10]),0,25 ;
		$mov = sprintf("%-4s %-25s %11s %11s", 
			$cm, $cta, $mntD, $mntH ) ;
		$listaS->insert('end', -itemtype => 'text', -text => "$mov" ) ;
	}
	# Devuelve una lista de listas con datos de las cuentas
	return @data;
}

sub agrega ( )
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	# Verifica que se completen datos de detalle
	if (length $Codigo < 4) {
		$Mnsj = "Registre el código de la cuenta.";
		$codigo->focus;
		return;
	}
	if ($Monto == 0) {
		$Mnsj = "Anote alguna cifra.";
		$monto->focus;
		return;
	}
	# Graba datos: excluye RUT para evitar registro en Cuenta Invidual
	$bd->agregaItemT($Codigo, $Detalle, $Monto, $DH, '', $TipoD, $Documento, 
		$Cuenta, $Numero, $CCto);
	# Muestra lista modificada de cuentas
	@datos = muestraLista($esto);
	# Totaliza itemes
	$TotalI += $Monto ;
	if ($TotalI == $Neto) {	
		$bCnt->configure(-state => 'disabled');
	}
	limpiaCampos();
#	$codigo->focus;
}

sub modifica ( )
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
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
	$Codigo = $sItem->[1];
	$Monto = $sItem->[2] ? $sItem->[2] : $sItem->[3] ;
	$Detalle = decode_utf8($sItem->[4]);
	$Cuenta = $sItem->[8];	

	# Obtiene Id del registro
	$Id = $sItem->[9];
}

sub registra ( )
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	
	# Graba datos
	$bd->grabaItemT($Codigo, $Detalle, $Monto, $DH, '', $TipoD, $Documento, 
		$CCto, $Cuenta, $Id);

	# Muestra lista actualizada de items
	@datos = muestraLista($esto);
	
	# Retotaliza comprobante
	$TotalI = $bd->sumaTC($Numero,$DH);
	if ($TotalI == $Neto) {	
		$bCnt->configure(-state => 'active');
	}
	limpiaCampos();
	
	$bNvo->configure(-state => 'active');
	$bEle->configure(-state => 'disabled');
	$bReg->configure(-state => 'disabled');
	
}

sub elimina ( )
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	
	# Graba
	$bd->borraItemT( $Id );
	
	# Muestra lista actualizada de items
	@datos = muestraLista($esto);

	$TotalI -= $Monto;
	limpiaCampos();

	$bNvo->configure(-state => 'active');
	$bEle->configure(-state => 'disabled');
	$bReg->configure(-state => 'disabled');

}

sub contabiliza ( )
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	
	$Mnsj = " ";
	# Verifica que se completen datos básicos
	if ($AE eq 'A' and $Iva > 0 and $CtaIVA eq '') {
		$Mnsj = "Debe registrar la cuenta del IVA.";
		$ctaIVA->focus;
		return;
	}
	if ($CtaT eq '' ) {
		$Mnsj = "Indique la cuenta de $TCtaT.";
		$ctaT->focus;
		return;
	}
	if ($Glosa eq '' ) {
		$Mnsj = "Escriba alguna glosa para el comprobante.";
		$glosa->focus;
		return;
	}
	if ($Fecha eq '' ) {
		$Mnsj = "Anote la fecha de la NC.";
		$fecha->focus;
		return;
	}	
	# Graba datos
	my $det = "$TipoD $Documento $RUT" ;
	if ($Iva > 0) {
		$bd->agregaItemT($CtaIVA, $det, $Iva, $DH, '', '','', '', $Numero,'');
	}
	$bd->agregaItemT($CtaT, '', $Total, $CC, $RUT, $TipoD, $Documento, 
		'', $Numero,'');
	my $fc = $ut->analizaFecha($FechaC) ; 
	$bd->agregaCmp($Numero, $fc, $Glosa, $Total, $TipoCmp);
	
	my ($Afecto, $Exento);
	if ($AE eq 'A') {
		$Afecto = $Neto;
		$Exento = 0;
	} else {
		$Exento = $Neto;
		$Afecto = 0;
	}
	my $ff = $ut->analizaFecha($Fecha) ;
	$bd->grabaFct($TablaD, $RUT, $Documento, $ff, -$Total, -$Iva, -$Afecto,
		-$Exento, $Numero, $TipoD, '', $fc, $CtaT, $TipoF, $NmrI, 0, 0);

	limpiaCampos();

	$bCnt->configure(-state => 'disabled');
	$listaS->delete(0,'end');
	$listaS->insert('end', -itemtype => 'text', 
			-text => "No hay movimientos registrados" ) ;
	# Inicializa variables
	inicializaV();
	$Numero = $bd->numeroC() + 1;
	$Documento = ($tpD eq "FV") ? $Documento + 1 : '' ; 
	$glosa->delete(0,'end');
	$documento->focus;
}

sub fNula ( )
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	if ($Documento eq '') {
		$Mnsj = "Registre número de Factura";
		$documento->focus;
		return;
	}
	if ( validaFechaC($ut,$bd) ) {
		# Ahora busca Factura
		my $fct = $bd->buscaFct($TablaD, $RUT, $Documento);
		if ($fct) {
			$Mnsj = "Esa Factura ya está registrada.";
			$documento->focus;
			return;
		}
		my $fc = $ut->analizaFecha($FechaC); 
		# Graba Factura
		$bd->grabaFct($TablaD, $RUT, $Documento, $fc, 0, 0, 0, 0,'', $TipoD, '', 
			$fc, '', "M", $NmrI, 1, 0);
		# Siguiente documento
		limpiaCampos();
		$bCnt->configure(-state => 'disabled');
		inicializaV();
		$Documento = ($tpD eq "FV") ? $Documento + 1 : '' ; 
		$documento->focus;
	}
}

sub cancela ( )
{
	my ($esto) = @_;	
	my $ut = $esto->{'mensajes'};
	my $vn = $esto->{'ventana'};
	my $bd = $esto->{'baseDatos'};
	
	$bd->borraTemp();
	$vn->destroy();
}

sub limpiaCampos ( )
{
	$codigo->delete(0,'end');
	$detalle->delete(0,'end');
	$Monto = 0;
	$Cuenta = $NCCto = $CCto = '';
	
	# Activa o desactive el botón para contabilizar el comprobante
	if ($Neto == $TotalI) {
		$bCnt->configure(-state => 'active');
	} else {
		$bCnt->configure(-state => 'disabled');
	}

}

sub inicializaV ( )
{
	$Monto = $TotalI = $Total = $Neto = $Iva = 0;
	$Codigo = $RUT = $Glosa = $Detalle = $CtaIVA = $CtaT = $NmrI = '';
	$NombreCi = $NombreCt = $Nombre = $Fecha = $NmrI = '';
}

# Fin del paquete
1;
