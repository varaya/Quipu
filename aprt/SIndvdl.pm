#  SIndvdl.pm - Registra asiento de apertura inicial
#  Forma parte del programa Quipu
#
#  Derechos de Autor (c) Víctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete 
#  UM: 25.06.2009

package SIndvdl;

use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';

# Variables válidas dentro del archivo
my ($TotalDf, $TotalHf, $Nombre, $Rut, $Db, $Hb, $Mnsj, $db, $hb ) ;	# 
my ($nombre, $rut, $bCan, $bReg) ; # Botones
			
sub crea {

	my ($esto, $bd, $ut) = @_;
	
	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
	
	my %tp = $ut->tipos();
	$Nombre = $Rut = '';
	$Db = $Hb = 0;
	
	# Define ventana
	my $vnt = MainWindow->new();
	$esto->{'ventana'} = $vnt;
	my $alt = $^O eq 'MSWin32' ? 190 : 170 ;
	$vnt->title("Saldos");
	$vnt->geometry("280x$alt+2+100"); # Tamaño y ubicación
	
	# Defime marcos
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Cuenta individual");
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
	$bReg = $mBotones->Button(-text => "Registra", -command => sub { &registra($esto) } );  
	my $bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); } );
	
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
	
	$mMensajes->pack(-expand => 1, -fill => 'both');	
	$mDatos->pack(-expand => 1);	
	$mBotones->pack(-expand => 1);

	$bReg->configure(-state => 'disabled');
	$rut->focus;
	
	bless $esto;
	return $esto;
}

# Funciones internas

sub registra ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	if ($Db == 0 and $Hb == 0 ) {
		$Mnsj = "Registre saldo.";
		$db->focus;
		return;
	}
	# Actualiza cuenta individual
	my ($ts,$total);
	$ts = $Db > 0 ? 'D' : 'H';
	$total = $Db > 0 ? $Db : $Hb ;
	$bd->saldoCI($total, $ts, $Rut) ;
	
	$Nombre = $Rut = '';
	$Db = $Hb = 0;
	
	$rut->focus;
}

sub buscaRUT ()
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	if (not $Rut) {
		$Mnsj = "Debe registrar un RUT.";
		$rut->focus;
		return;
	}
	$Rut = uc($Rut);
	if ( not $ut->vRut($Rut) ) {
		$Mnsj = "El RUT no es válido";
		$rut->focus;
		return;
	} else {
		my $nmb = $bd->buscaT($Rut);
		if (not $nmb) {
			$Mnsj = "Ese RUT no aparece registrado.";
			$rut->focus;
			return;
		} 
		$Nombre = decode_utf8(" $nmb");
		$bReg->configure(-state => 'normal');
	}
	$Mnsj = "" ;
}

# Fin del paquete
1;
