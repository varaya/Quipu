#  BltsH.pm -  Registra Boletas de Honorarios
#  Forma parte del programa Quipu
#
#  Derechos de autor: Víctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM: 19.06.2009

package BltsH;

use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';

# Variables válidas dentro del archivo
# Datos a registrar
my ($Numero, $Fecha, $RUT, $Mnsj, $Dcmnt, $NombreCi, $NombreCt, $NombreCn) ;
my ($FechaV, $CtaIm, $Impt, $CtaNt, $Neto, $CtaTt, $Total, $TipoD, $Glosa) ;
# Campos
my ($numero, $fecha, $fechaV, $rut, $dcmnt, $neto, $ctaNt, $ctaIm, $ctaTl ) ;
# Campos y datos opcionales para Centro de Costos
my ($CCto, $cCto, $ncCto, $NCCto) ;
my ($bCan, $bCnt) ; 	# Botones
	
sub crea {

	my ($esto, $vp, $bd, $ut, $mt, $ucc) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	my %tp = $ut->tipos();
	$Fecha = $ut->fechaHoy();
	$Numero = $bd->numeroC() + 1;
	inicializaV();
	$TipoD = "BH";

	# Crea archivo temporal para registrar movimientos
	$bd->creaTemp();

	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	my $alt = $ucc ? 340 : 320 ;
	$vnt->title("Boletas de Honorarios");
	$vnt->geometry("360x$alt+475+4"); # Tamaño y ubicación

	# Defime marcos
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Registra Boleta de Honorarios");
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	$bCnt = $mBotonesC->Button(-text => "Contabiliza", 
		-command => sub { &contabiliza($esto,$bd) } ); 
	$bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { $bd->borraTemp(); $vnt->destroy() } );
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'BltsH'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";

	# Define campos para datos de la boleta
	$numero = $mDatosC->LabEntry(-label => "Comprobante #: ", -width => 6,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Numero, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
	$fecha = $mDatosC->LabEntry(-label => "Fecha: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Fecha );
	$rut = $mDatosC->LabEntry(-label => "RUT:  ", -width => 15,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'left', -textvariable => \$RUT);
	$nombre = $mDatosC->Label(	-textvariable => \$Nombre, -font => $tp{tx});
	$dcmnt = $mDatosC->LabEntry(-label => "Boleta # ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Dcmnt);
	$fechaV = $mDatosC->LabEntry(-label => "Vence: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaV );
	$glosa = $mDatosC->LabEntry(-label => "Glosa: ", -width => 35,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Glosa );
	if ($ucc) {
	  $cCto = $mDatosC->LabEntry(-label => "C.Costo: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CCto );	
	  $nCCto = $mDatosC->Label(-textvariable => \$NCCto, -font => $tp{tx});		
	}
	$neto = $mDatosC->LabEntry(-label => "Neto:    ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Neto);
	$ctaNt = $mDatosC->LabEntry(-label => "Cuenta:  ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CtaNt );
	$nCtaNt = $mDatosC->Label(-textvariable => \$NombreCn, -font => $tp{tx});
	$impt = $mDatosC->LabEntry(-label => "Impuesto:", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Impt );
	$ctaIm = $mDatosC->LabEntry(-label => "Cuenta:  ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CtaIm );
	$nCtaIm = $mDatosC->Label(-textvariable => \$NombreCi, -font => $tp{tx});
	$total = $mDatosC->LabEntry(-label => "Total:     ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Total );
	$ctaTl = $mDatosC->LabEntry(-label => "Cuenta: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CtaTl );
	$nCtaTl = $mDatosC->Label( -textvariable => \$NombreCt, -font => $tp{tx});

	# Habilita validación de datos
	$rut->bind("<FocusIn>", sub { &vFecha($esto) } );
	$dcmnt->bind("<FocusIn>", sub { &buscaRUT($esto) } );
	$fechaV->bind("<FocusOut>", sub { &vFechaV($esto) });
	$glosa->bind("<FocusIn>", sub { &buscaDoc($bd) } );	
	if ( $ucc ) {
		$neto->bind("<FocusIn>", sub { &buscaCC($bd) } );
	}
	$ctaNt->bind("<FocusOut>", sub { 
		&buscaCuenta($bd, \$CtaNt, \$NombreCn, \$ctaNt) } );
	$impt->bind("<FocusOut>", sub { $Total = $Neto + $Impt; } );	
	$ctaIm->bind("<FocusOut>", sub { 
		&buscaCuenta($bd, \$CtaIm, \$NombreCi, \$ctaIm) } );
	$ctaTl->bind("<FocusIn>", sub { $bCnt->configure(-state => 'normal'); } );
	$ctaTl->bind("<FocusOut>", sub {
		&buscaCuenta($bd, \$CtaTl, \$NombreCt, \$ctaTl) } );

	# Dibuja interfaz
	$fecha->grid(-row => 0, -column => 0, -sticky => 'nw');
	$numero->grid(-row => 0, -column => 1, -columnspan => 2, -sticky => 'ne');
	$rut->grid(-row => 1, -column => 0, -sticky => 'nw');
	$dcmnt->grid(-row => 1, -column => 1, -columnspan => 2, -sticky => 'ne');
	$nombre->grid(-row => 2, -column => 0, -sticky => 'nw');
	$fechaV->grid(-row => 2, -column => 1, -columnspan => 2, -sticky => 'ne');
	$glosa->grid(-row => 3, -column => 0, -columnspan => 2, -sticky => 'nw');
	if ($ucc) {
		$cCto->grid(-row => 4, -column => 0, -sticky => 'nw');
		$nCCto->grid(-row => 4, -column => 1, -columnspan => 2, -sticky => 'nw');		
	}
	$neto->grid(-row => 5, -column => 0, -sticky => 'nw');
	$ctaNt->grid(-row => 5, -column => 1, -sticky => 'nw');
	$nCtaNt->grid(-row => 6, -column => 0, -columnspan => 2, -sticky => 'ne'); 
	$impt->grid(-row => 7, -column => 0, -sticky => 'nw');
	$ctaIm->grid(-row => 7, -column => 1, -sticky => 'nw');
	$nCtaIm->grid(-row => 8, -column => 0, -columnspan => 2, -sticky => 'ne'); 
	$total->grid(-row => 9, -column => 0, -sticky => 'nw'); 
	$ctaTl->grid(-row => 9, -column => 1, -sticky => 'nw'); 
	$nCtaTl->grid(-row => 10, -column => 0, -columnspan => 2, -sticky => 'ne'); 

	$bCnt->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

	$mDatosC->pack();
	$mBotonesC->pack();
	$mMensajes->pack(-expand => 1, -fill => 'both');

	# Inicialmente deshabilita algunos botones
	$bCnt->configure(-state => 'disabled');
	$fecha->focus;

	bless $esto;
	return $esto;
}

# Funciones internas
sub vFecha ( ) 
{
	my ($esto) = @_;	
	my $ut = $esto->{'mensajes'};

#	$Mnsj = " ";
	if ( $Fecha eq '' ) {
		$Mnsj = "Debe colocar fecha de emisión"; 
		$fecha->focus;
		return 
	}
	# Comprueba si la fecha está escrita correctamente
	if (not $Fecha =~ m|\d+/\d+/\d+|) {
		$Mnsj = "Problema con formato fecha";
		$fecha->focus;
	} elsif ( not $ut->analizaFecha($Fecha) ) {
		$Mnsj = "Fecha incorrecta" ;
		$fecha->focus ;
	}
}

sub vFechaV ( ) 
{
	my ($esto) = @_;	
	my $ut = $esto->{'mensajes'};

	if ($FechaV eq '' ) {
		return 
	}
	# Comprueba si la fecha está escrita correctamente
	if (not $FechaV =~ m|\d+/\d+/\d+|) {
		$Mnsj = "Problema con formato fecha";
		$fechaV->focus;
	} elsif ( not $ut->analizaFecha($FechaV) ) {
		$Mnsj = "Fecha incorrecta" ;
		$fechaV->focus ;
	}
}

sub buscaCC ( $ ) {

	my ($bd) = @_;

	$Mnsj = " ";
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

sub buscaCuenta ( $ $ $ $ ) 
{
	my ($bd, $a, $b, $c) = @_;

	$Mnsj = " ";
	if (not $$a ) {
		$Mnsj = "Registre un código";
		$$c->focus;
		return;
	}
	# Comprueba largo del código de la cuenta
	if (length $$a < 4) {
		$Mnsj = "Código debe tener 4 dígitos";
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
		$$b = decode_utf8("$dCuenta[0] ");
	}
}

sub buscaRUT ( $ ) 
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	$Mnsj = " ";
	if ($RUT eq '') {
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
		$Nombre = decode_utf8(" $nmb");
	}
}

sub buscaDoc ( $ ) # Evita que se registre dos veces una misma boleta
{ 
	my ($bd) = @_;

	if ($Dcmnt eq '') {
		$Mnsj = "Registre número de la Boleta";
		$dcmnt->focus;
		return;
	}
	# Busca factura
	my $fct = $bd->buscaFct('BoletasH', $RUT, $Dcmnt);
	if ($fct) {
		$Mnsj = "Esa Boleta ya está registrada.";
		$dcmnt->focus;
		return;
	}
#	$Glosa = "$TipoD# $Dcmnt$Nombre" ;
}

sub contabiliza ( $ )
{
	my ($esto,$bd) = @_;
	my $ut = $esto->{'mensajes'};
	
	$Mnsj = " ";
	# Verifica que se completen datos básicos
	if ($Glosa eq '' ) {
		$Mnsj = "Escriba alguna glosa para el comprobante.";
		$glosa->focus;
		return;
	}
	# Graba Comprobante
	my $det = "$TipoD $Dcmnt $RUT" ;
	# Registra impuesto
	$bd->agregaItemT($CtaIm, $det, $Impt, 'H', '', '', '', '', $Numero,'');
	# Registra neto
	$bd->agregaItemT($CtaNt, $det, $Neto, 'H', '', '', '', '', $Numero,'');
	# Registra total
	$bd->agregaItemT($CtaTl,'',$Total,'D',$RUT,$TipoD,$Dcmnt,'',$Numero,$CCto);
	my $ff = $ut->analizaFecha($Fecha) ;
	$bd->agregaCmp($Numero, $ff, $Glosa, $Total, 'T');
	# Graba Boleta
	my $fv = $ut->analizaFecha($FechaV) if $FechaV ; 
	$bd->grabaBH($RUT,$Dcmnt,$ff,$Total,$Impt,$Numero,$fv,$CtaTl,$Neto);

	$bCnt->configure(-state => 'disabled');
	
	inicializaV();
	$Numero = $bd->numeroC() + 1;
	$glosa->delete(0,'end');
	$fecha->focus;
}

sub inicializaV
{
	$Total = $Impt = $Neto = 0;
	$NombreCi = $NombreCt = $NombreCn = $RUT = $FechaV = $Fecha = $Glosa = '';
	$Nombre = $Dcmnt = $CtaIm = $CtaNt = $CtaTl = $NCCto = $CCto = '' ;
}

# Fin del paquete
1;
