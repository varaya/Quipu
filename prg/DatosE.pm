#  DatosE.pm - Registra o modifica la información de la empresa
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la
#  licencia incluida en este paquete 
#  UM : 09.07.2009

package DatosE;

use Tk::NoteBook;
use Tk::LabEntry;
use Encode 'decode_utf8';
	
# Variables que identifican los campos de tabla DatosE 
# [válidas dentro del archivo]
my ($Nombre,$Rut,$Giro,$RutRL,$NmbrRL,$OtrosI,$BltsCV,$CBco,$CCts,$CPto) = (0..9);
my ($Mnsj) ;

sub crea {

	my ($esto, $vp, $bd, $ut, $mt, $ay, $rt) = @_;
	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
	$esto->{'marcoT'} = $mt;
	
	my %tp = $ut->tipos();
	my $vnt = $vp->Toplevel();
	$vnt->title("Registra Datos Empresa");
	# Obtiene datos de la empresa y decodifica textos (utf8)
	my @datos = $bd->datosEmpresa($rt);
	if (@datos) {
		$datos[$Nombre] = decode_utf8($datos[$Nombre]); 
		$datos[$Giro] = decode_utf8($datos[$Giro]); 
		$datos[$NmbrRL] = decode_utf8($datos[$NmbrRL]);
	}
	my $alt = $^O eq 'MSWin32' ? 205 : 225 ;
	$vnt->geometry("390x$alt+475+4"); # Tamaño y ubicación
	$esto->{'ventana'} = $vnt;

	# Defime marcos
	my $mDatos = $vnt->Frame(-borderwidth => 1);
	my $mBotones = $vnt->Frame(-borderwidth => 1);
	my $nb = $mDatos->NoteBook(-ipadx => 6, -ipady => 6);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'DatosE'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";

	# Define pestañas
	my $pEmpresa = $nb->add("datosE", -label => "Datos Básicos", -underline => 0);
	my $pOpc = $nb->add("opc", -label => "Opciones", -underline => 0);
	my $pRLegal = $nb->add("rLegal", -label => "Representante Legal", 
		-underline => 0);
	
	# Define campos datos: primera pestaña
	my $rut = $pEmpresa->LabEntry(-label => "RUT:   ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$datos[$Rut]);
	my $nombre = $pEmpresa->LabEntry(-label => "Nombre: ", -width => 35,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$datos[$Nombre]);
	$nombre->bind("<FocusIn>", sub { &vRUT($esto,\$datos[$Rut],\$rut) } );
	my $giro = $pEmpresa->LabEntry(-label => "Giro: ", -width => 45,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$datos[$Giro]);
	my $algo = $pEmpresa->Label(-text => ' ');
	
	my $cBco = $pOpc->Checkbutton(-variable => \$datos[$CBco], 
		 -text => "Realiza Conciliación bancaria",);
	my $cCts = $pOpc->Checkbutton(-variable => \$datos[$CCts], 
		 -text => "Controla Centros de Costos",);
	my $cPto = $pOpc->Checkbutton(-variable => \$datos[$CPto], 
		 -text => "Control Presupuestario [Pendiente]",);
	my $otrosI = $pOpc->Checkbutton(-variable => \$datos[$OtrosI], 
		 -text => "Registra otros impuestos [Pendiente]",);
	my $bltsCV = $pOpc->Checkbutton(-variable => \$datos[$BltsCV], 
		 -text => "Registra Boletas de Compraventa",);

	# Define campos datos: segunda pestaña
	my $rutRL = $pRLegal->LabEntry(-label => "RUT:   ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$datos[$RutRL]);
	my $nombreRL = $pRLegal->LabEntry(-label => "Nombre: ", -width => 35,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$datos[$NmbrRL]);
	$nombreRL->bind("<FocusIn>", sub { &vRUT($esto,\$datos[$RutRL],\$rutRL) });

	# Define botones
	my $bReg = $mBotones->Button(-text => "Registra", 
		-command => sub { &registra($esto, @datos) } ); 
	my $bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); } ); 
	
	# Dibuja la interfaz
	$mDatos->pack();
	$mBotones->pack();

	$bReg->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	
	$rut->pack(-side => "top", -anchor => "nw");	
	$nombre->pack(-side => "top", -anchor => "nw");
	$giro->pack(-side => "top", -anchor => "nw");
	$algo->pack(-side => "top", -anchor => "nw");
	
	$cBco->pack(-side => "top", -anchor => "nw");
	$cCts->pack(-side => "top", -anchor => "nw");
	$cPto->pack(-side => "top", -anchor => "nw");
	$otrosI->pack(-side => "top", -anchor => "nw");
	$bltsCV->pack(-side => "top", -anchor => "nw");

	$rutRL->pack(-side => "top", -anchor => "nw");	
	$nombreRL->pack(-side => "top", -anchor => "nw");
		
	$nb->pack(-expand => "yes", -fill => "both", -padx => 5, -pady => 5,
		 -side => "top");
	$mMensajes->pack(-expand => 1, -fill => 'both');
	
	$$ay = '';
	$rut->focus();

  bless $esto;
  return $esto;
}

# Funciones auxiliares
sub vRUT ($ $ ) 
{
	my ($esto, $rt, $crt) = @_;
	my $ut = $esto->{'mensajes'};

	$Mnsj = " ";
	if ($$rt eq '') {
		$Mnsj = "Debe registrar el RUT.";
		$$crt->focus;
		return;
	}
	$$rt = uc($$rt);
	$$rt =~ s/^0// ; # Elimina 0 al inicio
	if ( not $ut->vRut($$rt) ) {
		$Mnsj = "RUT no es válido";
		$$crt->focus;
		return;
	} 
}

sub registra ( )
{
	my ($esto, @datos) = @_;	
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	my $vn = $esto->{'ventana'};
	my $mt = $esto->{'marcoT'};

	$Mnsj = " ";
	# Valida Rut Empresa
	if ($datos[$Rut] eq "") {
		$Mnsj = "Debe registrar RUT Empresa";
		return;
	}
	# Verifica que se completen datos de la empresa
	if ($datos[$Nombre] eq "") {
		$Mnsj = "La Empresa debe tener algún nombre";
		return;
	}
	if ($datos[$Giro] eq "") {
		$Mnsj = "Registre el giro de la Empresa";
		return;
	}
	# Valida Rut del Representante Legal
	if ($datos[$RutRL] eq "") {
		$Mnsj = "Debe registrar RUT del Representante Legal";
		return;
	}
	# Verifica que esté registrado el nombre del Representante Legal
	if ($datos[$NmbrRL] eq "") {
		$Mnsj = "Registrar Nombre del Representante Legal";
		return;
	}
	$bd->grabaDatosE(@datos);
	$vn->destroy();
}

1;
