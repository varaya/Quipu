#  Ltrs.pm - Registra Letras y Cheques para la apertura
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la
#  licencia incluida en este paquete 
#  UM : 28.06.2009
 
package Ltrs;

use prg::BaseDatos;
use Tk;
use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';

my ($RUT,$Mnsj,$NumD,$Total,$Nombre,$TablaD,$TipoD,$Cuenta); # Variables
my ($rut,$numD,$total,$nombre,$cuenta,$em,$rc); # Campos
my ($bCan, $bNvo) ; # Botones

sub crea {

	my ($esto, $bd, $ut, $tf) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Define ventana
	my $vnt = MainWindow->new();
	$vnt->title("Documentos");
	$vnt->geometry("290x210+2+115"); # Tamaño y ubicación

	my %tp = $ut->tipos();
	$TipoD = $tf ;
	$TablaD = '' ;
	my $sTit = $TipoD eq "LT" ? "Letras" : "Cheques";
	$Total = 0;
	
	# Defime marcos
	my $mTipo = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "$sTit");
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Datos:");
	my $mBtns = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{fx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'left', -expand => 1, -fill => 'x');
	$Mnsj = "Se actualizan saldos";

	# Define botones
	$bNvo = $mBtns->Button(-text => "Registra", -command => sub { &registra($bd)}); 
	$bCan = $mBtns->Button(-text => "Cancela", -command => sub { $vnt->destroy()});

	$em = $mTipo->Radiobutton( -text => "Emitidos", -value => 'DocsE', 
		-variable => \$TablaD);
	$rc = $mTipo->Radiobutton( -text => "Recibidos", -value => 'DocsR', 
		-variable => \$TablaD);

	$rut = $mDatos->LabEntry(-label => "RUT: ", -width => 12,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$RUT);
	$numD = $mDatos->LabEntry(-label => " Doc. # ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$NumD );
	$nombre = $mDatos->Label(-textvariable => \$Nombre, -font => $tp{tx}) ;
	$cuenta = $mDatos->LabEntry(-label => "Cuenta ", -width => 5,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$Cuenta);
	$total = $mDatos->LabEntry(-label => "Total ", -width => 12,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$Total);

	$numD->bind("<FocusIn>", sub { &buscaRUT($esto) } );
	$cuenta->bind("<FocusIn>", sub { &buscaDoc($esto) } );
	$total->bind("<FocusIn>", sub { &buscaCta($bd) } );
	$total->bind("<FocusOut>", sub { &valida() } );

	$em->grid(-row => 0, -column => 0, -sticky => 'nw');
	$rc->grid(-row => 0, -column => 1, -sticky => 'nw');
	
	$rut->grid(-row => 0, -column => 0, -sticky => 'nw');
	$numD->grid(-row => 0, -column => 1, -sticky => 'nw');
	$nombre->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nw');
	$cuenta->grid(-row => 2, -column => 0, -sticky => 'nw');
	$total->grid(-row => 2, -column => 1, -sticky => 'nw');

	$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

	$mMensajes->pack(-expand => 1, -fill => 'both');
	$mTipo->pack(-expand => 1);
	$mDatos->pack(-expand => 1);	
	$mBtns->pack(-expand => 1);

	$bNvo->configure(-state => 'disabled');
	$em->focus ;
		
	bless $esto;
	return $esto;
}

# Funciones internas
sub buscaRUT ()
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

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
			$Mnsj = "Ese RUT no aparece registrado.";
			$rut->focus;
			return;
		} 
		$Nombre = decode_utf8(" $nmb");
	}
}
sub buscaDoc ( $ )
{ 
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	if ($NumD eq '') {
		$Mnsj = "Registre número del Documento";
		$numD->focus;
		return;
	}
	# Valida que sea número entero
	if (not $NumD =~ /^(\d+)$/) {
		$Mnsj = "NO es un número válido.";
		$numD->focus;
		return ;
	}
	# Verifica que esté marcado tipo de documento
	if ( $TablaD eq '') {
		$Mnsj = "Marcar tipo documento.";
		$em->focus;
		return ;
	}
	# Ahora busca Factura
	my $fct = $bd->buscaFct($TablaD, $RUT, $NumD);
	if ($fct) {
		$Mnsj = "Ese Documento ya está registrada.";
		$numD->focus;
		return;
	}
#	$Mnsj = "";
}

sub buscaCta ( $  ) 
{
	my ($bd) = @_;

	# Comprueba largo del código de la cuenta
	if (not length $Cuenta == 4) {
		$Mnsj = "Código debe tener 4 dígitos";
		$cuenta->focus;
		return;
	}
	# Busca código
	@dCuenta = $bd->dtCuenta($Cuenta);
	if ( not @dCuenta ) {
		$Mnsj = "Ese código NO está registrado";
		$cuenta->focus;
		return;
	} 
	$Mnsj = "$dCuenta[0] ";
}

sub valida ( ) 
{
	$bNvo->configure(-state => 'normal') if $Total > 0 ;
}
 

sub registra ( $ ) 
{
	my ($bd ) = @_;
	
	$bd->registraD($RUT, $NumD, $Total, $Cuenta, $TablaD, $TipoD);
	
	$NumD = $Nombre = '';
	$Total = 0;
	
	$bNvo->configure(-state => 'disabled');
	$rut->focus ;
}

# Fin del paquete
1;
