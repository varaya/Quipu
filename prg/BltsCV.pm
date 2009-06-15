#  BltsCV.pm - Registra boletas de compra y venta
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package BltsCV;

use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';

# Variables válidas dentro del archivo
# Datos a registrar
my ($Numero, $Fecha, $NmrDe, $NmrA, $Monto, $CtaC, $CtaA, $CuentaC, $CuentaA ) ;
# Campos
my ($numero, $fecha, $nmrDe, $nmrA, $monto, $ctaC, $ctaA, $cuentaC, $cuentaA) ;
my ($bCan, $bCnt) ; 	# Botones
my ($mnsj, $Mnsj);
  	
sub crea {

	my ($esto, $vp, $bd, $ut, $tipo) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	my %tp = $ut->tipos();
	$Fecha = $ut->fechaHoy();
	$Numero = $bd->numeroC() + 1;
	$Monto = 0;
	$CtaA = $CtaC = $CuentaC = $CuentaA = $NmrDe = $NmrA = '';
	$Mnsj = "Para ver Ayuda presione botón 'i'.";
	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("*Boletas de $tipo");
	$vnt->geometry("300x270+475+4"); # Tamaño y ubicación

	# Crea archivo temporal para registrar movimientos
	$bd->creaTemp();

	# Defime marcos
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Resumen Diario Boletas de $tipo");
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	$bCnt = $mBotonesC->Button(-text => "Contabiliza", 
		-command => sub { &contabiliza($esto) } ); 
	$bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { &cancela($esto) } );
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'sunken' );
	$mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);

	# Define campos para datos generales del comprobante
	$numero = $mDatosC->LabEntry(-label => "  Numero: ", -width => 6,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Numero, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
	$fecha = $mDatosC->LabEntry(-label => "Fecha: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Fecha );
	$fecha->bind("<FocusOut>", sub { &validaFecha($esto,\$Fecha, \$fecha, 1) } );
	my $nmr = $mDatosC->Label(-text => "Numeración:");
	$nmrDe = $mDatosC->LabEntry(-label => " De ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$NmrDe );
	$nmrA = $mDatosC->LabEntry(-label => "A ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$NmrA );
	my $ctas = $mDatosC->Label(-text => "Cuentas:");
	$ctaC = $mDatosC->LabEntry(-label => " Cargo  ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CtaC );
	$ctaC->bind("<FocusOut>", sub { 
		&buscaCuenta($esto, \$CtaC, \$CuentaC, \$ctaC) } );
	$cuentaC = $mDatosC->Label(-textvariable => \$CuentaC, -font => $tp{mn});
	$ctaA = $mDatosC->LabEntry(-label => " Abono ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CtaA );
	$ctaA->bind("<FocusOut>", sub { 
		&buscaCuenta($esto, \$CtaA, \$CuentaA, \$ctaA) } );
	$cuentaA = $mDatosC->Label(-textvariable => \$CuentaA, -font => $tp{mn});
	$monto = $mDatosC->LabEntry(-label => "Total: ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Monto );
	$monto->bind("<FocusOut>", sub { if ($Monto > 0 ) 
		{ $bCnt->configure(-state => 'active');}  } );

	# Dibuja interfaz
	$fecha->grid(-row => 0, -column => 0, -sticky => 'nw');
	$numero->grid(-row => 0, -column => 1, -sticky => 'ne');
	$nmr->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nw');
	$nmrDe->grid(-row => 2, -column => 0);
	$nmrA->grid(-row => 2, -column => 1); 
	$ctas->grid(-row => 3, -column => 0, -columnspan => 2, -sticky => 'nw');
	$ctaC->grid(-row => 4, -column => 0, -sticky => 'nw');
	$cuentaC->grid(-row => 5, -column => 0, -columnspan => 2, -sticky => 'nw');
	$ctaA->grid(-row => 6, -column => 0, -sticky => 'nw'); 
	$cuentaA->grid(-row => 7, -column => 0, -columnspan => 2, -sticky => 'nw'); 
	$monto->grid(-row => 8, -column => 0, -columnspan => 2, -sticky => 'ne');

	$bCnt->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mnsj->pack(-expand => 1, -fill => 'both');
	
	$mDatosC->pack();
	$mBotonesC->pack();
	$mMensajes->pack(-expand => 1, -fill => 'both');

	# Inicialmente deshabilita algunos botones
	$bCnt->configure(-state => 'disabled');

	bless $esto;
	return $esto;
}

# Funciones internas
sub cancela ( )
{
	my ($esto) = @_;	
	my $vn = $esto->{'ventana'};
	
	$vn->destroy();
}

sub buscaCuenta ( $ $ $ $ ) 
{
	my ($esto, $a, $b, $c) = @_;
	my $bd = $esto->{'baseDatos'};

	$Mnsj = " ";
	if ($$a eq '') {
		$Mnsj = "Debe indicar un código" ;
		$$c->focus;
		return 
	}
	# Comprueba largo del código de la cuenta
	if (length $$a < 4) {
		$Mnsj = "El código debe tener 4 dígitos" ;
		$$c->focus;
		return;
	}
	# Busca código
	@dCuenta = $bd->dtCuenta($$a);
	my $nc = @dCuenta;
	if ( $nc == 0 ) {
		$Mnsj = "Ese código NO está registrado";
		$$c->focus;
	} else {
		$$b = decode_utf8("  $dCuenta[0]");
	}
}

sub validaFecha ( $ $ $ $ ) 
{
	my ($esto, $v, $c) = @_;
	my $ut = $esto->{'mensajes'};	
	$Mnsj = " ";
	if ($$v eq '' ) {
		$Mnsj = "Debe colocar fecha de emisión";
		$$c->focus;
		return;
	}
	# Comprueba si la fecha está escrita correctamente
	if (not $ut->analizaFecha($$v)) {
		$Mnsj = "Fecha incorrecta";
		$$c->focus;
		return;
	}
}

sub contabiliza ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};	
	# Verifica que se completen datos básicos
	if ( $NmrDe eq '') {
		$Mnsj = "Debe registrar número boleta inicial.";
		$nmrDe->focus;
		return;
	}
	if ( $NmrA eq '') {
		$Mnsj = "Registre el número final.";
		$nmrA->focus;
		return;
	}
	if ($Fecha eq '' ) {
		$Mnsj = "Anote la fecha del resumen.";
		$fecha->focus;
		return;
	}
	
	# Graba Comprobante
	my $det = "Ventas del $Fecha" ;
	$bd->agregaItemT($CtaA, $det, $Monto, $DH, '', '','', '', $Numero);
	my $ff = $ut->analizaFecha($Fecha) ;
	$ff =~ s/-//g ; # Convierte a formato AAAAMMDD
	$bd->agregaItemT($CtaC, '', $Total, $CC, $RUT, $TipoD, $Dcmnt,'', $Numero);
	$bd->agregaCmp($Numero, $ff, $det, $Monto, 'I');
	# Graba Resumen
	
	my $fv = $ut->analizaFecha($FechaV) ;
	$fv =~ s/-//g ;
	$bd->grabaBCV($TablaD, $RUT, $Dcmnt, $ff, $Total, $Iva, $Afecto, $Exento,
		$Numero, $TipoD, $fv);

	limpiaCampos();

	$bCnt->configure(-state => 'disabled');
	# Inicializa variables
	inicializaV();
	$Numero = $bd->numeroC() + 1;
	$fecha->focus;
}

# Fin del paquete
1;
