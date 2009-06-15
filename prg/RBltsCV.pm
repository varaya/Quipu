#  RBltsCV.pm - Registra resumen diario boletas de compra y venta
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package RBltsCV;

use Tk::LabEntry;
use Tk::LabFrame;

# Variables válidas dentro del archivo
# Datos a registrar
my ($Fecha, $NmrDe, $NmrA, $Monto, $Mnsj ) ;
# Campos
my ($fecha, $nmrDe, $nmrA, $monto) ;
my ($bCan, $bReg) ; 	# Botones
  	
sub crea {

	my ($esto, $vp, $bd, $ut, $mt) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	my %tp = $ut->tipos();
	my $tipo = "Compraventa";
	inicializaV();
	$Fecha = $ut->fechaHoy();

	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("*Boletas de $tipo");
	$vnt->geometry("300x152+475+4"); # Tamaño y ubicación

	# Defime marcos
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Resumen Boletas de $tipo");
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	$bReg = $mBotonesC->Button(-text => "Registra", 
		-command => sub { &registra($esto) } ); 
	$bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { &cancela($esto) } );

	# Barra de mensajes y botón de ayuda
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'left', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'RBltsV'); } ); 
	$bAyd->pack(-side => 'right', -expand => 0, -fill => 'none');

	$Mnsj = "Mensajes de error o advertencias.";

	# Define campos para datos generales del comprobante
	$fecha = $mDatosC->LabEntry(-label => "Fecha: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Fecha );
	$fecha->bind("<FocusOut>", sub { &validaFecha($esto) } );
	$monto = $mDatosC->LabEntry(-label => "Total: ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Monto );
	my $nmr = $mDatosC->Label(-text => "Numeración:");
	$nmrDe = $mDatosC->LabEntry(-label => " De ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$NmrDe );
	$nmrA = $mDatosC->LabEntry(-label => "A ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$NmrA );
	$monto->bind("<FocusOut>", sub { if ($Monto > 0 ) 
		{ $bReg->configure(-state => 'active');}  } );

	# Dibuja interfaz
	$fecha->grid(-row => 0, -column => 0, -sticky => 'nw');
	$monto->grid(-row => 0, -column => 1, -sticky => 'ne');
	$nmr->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nw');
	$nmrDe->grid(-row => 2, -column => 0);
	$nmrA->grid(-row => 2, -column => 1); 

	$bReg->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mnsj->pack(-expand => 1, -fill => 'both');
	
	$mDatosC->pack();
	$mBotonesC->pack();
	$mMensajes->pack(-expand => 1, -fill => 'both');

	# Inicialmente deshabilita algunos botones
	$bReg->configure(-state => 'disabled');

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

sub validaFecha ( ) 
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'} ;
	
	$Mnsj = " ";
	if ($Fecha eq '' ) {
		$Mnsj = "Debe colocar fecha del resumen";
		$fecha->focus;
		return;
	}
	# Comprueba si la fecha está escrita correctamente
	if (not $ut->analizaFecha($Fecha)) {
		$Mnsj = "Fecha incorrecta";
		$fecha->focus;
		return;
	}
	# Verifica que no esté registrada
	my $fch = $bd->buscaBCV($Fecha);
	if ($fch) {
		$Mnsj = "Datos ya registrados para el $fch.";
		dSiguiente($esto->{'mensajes'});
		$fecha->focus;
		return;
	}
	
}

sub dSiguiente( $ )
{
	my ($ut) = @_;
	
	my $fs = $ut->analizaFecha($Fecha) + 1 ;
	$Fecha = $ut->cFecha($fs) ;
	$Fecha =~ s/^0//;
}

sub registra ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};
	
	$Mnsj = " ";
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
	
	# Graba Resumen
	$bd->grabaBCV($Fecha,$NmrDe,$NmrA,$Monto);

	# Inicializa variables
	inicializaV();
	$bReg->configure(-state => 'disabled');
	dSiguiente($ut);
	$fecha->focus;
}

sub inicializaV ( )
{
	$Monto = 0;
	$NmrDe = $NmrA = '';

}

# Fin del paquete
1;
