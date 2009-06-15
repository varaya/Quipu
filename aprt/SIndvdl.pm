#  SIndvdl.pm - Registra asiento de apertura inicial
#  Forma parte del programa PartidaDoble
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete

package SIndvdl;

use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
my ($TotalDf, $TotalHf, $Nombre, $Rut, $Db, $Hb, $Mnsj, $db, $hb ) ;	# 
my ($nombre, $rut, $bCan, $bReg) ; # Botones
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $bd, $ut, $rt, $mt) = @_;
	
	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	my %tp = $ut->tipos();
	$Rut = $rt ;
	$Nombre = '';
	$Fecha = $ut->fechaHoy();
	$Db = $Hb = 0;
	
	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	my $alt = $^O eq 'MSWin32' ? 190 : 170 ;
	$vnt->title("Registra saldos Cuentas Individuales");
	$vnt->geometry("280x$alt+415+2"); # Tamaño y ubicación
	
	# Defime marcos
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Datos de Terceros");
	my $mBotones = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'DatosT'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
		
	# Define botones
	$bReg = $mBotones->Button(-text => "Registra", 
		-command => sub { &registra($esto) } );  
	my $bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { &cancela($esto) } );
	
	# Define campos para registro de datos del cliente o proveedor
	$rut = $mDatos->LabEntry(-label => "RUT:      ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Rut );
	$nombre = $mDatos->Label(-textvariable => \$Nombre, -font => $tp{mn});
	$db = $mDatos->LabEntry(-label => " Debe ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Db, 
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000' );
	$db->bind("<FocusIn>", sub { &buscaRUT($esto) } );
	$hb = $mDatos->LabEntry(-label => "Haber ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Hb,
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
				
	# Dibuja interfaz
	$rut->grid(-row => 0, -column => 0,-columnspan => 2, -sticky => 'nw');	
	$nombre->grid(-row => 1, -column => 0,-columnspan => 2, -sticky => 'nw');
	$db->grid(-row => 2, -column => 0, -sticky => 'nw');
	$hb->grid(-row => 2, -column => 1, -sticky => 'nw');

	$bReg->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	
	$mDatos->pack(-expand => 1);	
	$mBotones->pack(-expand => 1);
	$mMensajes->pack(-expand => 1, -fill => 'both');

	$rut->focus;
	
	bless $esto;
	return $esto;
}

# Funciones internas

sub registra ($)
{
	my ($esto, $c) = @_;	
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	if ($Rut eq "") {
		$Mnsj = "Debe registrar el RUT.";
		$rut->focus;
		return;
	}
	if ($Db == 0 and $Hb == 0 ) {
		$Mnsj = "Registre saldo.";
		$db->focus;
		return;
	}
	# Graba datos
	$bd->grabaSI($Rut, $Db, $Hb);
}

sub buscaRUT ()
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = "" ;
	if ( not $ut->vRut($Rut) ) {
		$Mnsj = "RUT no es válido";
		$rut->focus;
		return;
	} else {
		my $nmb = $bd->buscaT($Rut);
		if ( not $nmb ) {
			$Mnsj = "Ese RUT No esta registrado" ;
			$rut->focus;
			return;
		}
		$Nombre = $nmb;
	}
}

sub cancela ($)
{
	my ($esto) = @_;	
	my $vn = $esto->{'ventana'};

	$vn->destroy();
}

# Fin del paquete
1;
