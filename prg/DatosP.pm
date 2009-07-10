#  DatosP.pm - Registra o modifica datos del personal de la empresa
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package DatosP;

use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Tk::Balloon;
use Encode 'decode_utf8';
	
# Variables válidas dentro del archivo
my ($Nombre, $Rut, $Direc, $Comuna, $Fonos, $FechaI, $FechaR, $Fecha, $Mnsj);
my ($CCto, $cCto, $ncCto, $NCCto) ;
my ($nombre, $rut, $direc, $comuna, $fonos, $fechaI, $fechaR); # Campos
my ($bReg, $bNvo) ; # Botones
my @datos = () ;	# Lista del personal
my @dCentro = () ;	
		
sub crea {

	my ($esto, $vp, $bd, $ut, $mt, $ucc) = @_;
	
	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
	
	my %tp = $ut->tipos();
	$Fecha = $ut->fechaHoy();
	$Nombre = $Rut = $Direc = $Comuna = $Fonos = $FechaI = $FechaR = '';
	$CCto = $NCCto = '';
	
	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Registra Datos del Personal");
	my $alt = $^O eq 'MSWin32' ? 390 : 400 ;
	$alt += $ucc ? 30 : 0 ;
	$vnt->geometry("370x$alt+475+4"); # Tamaño y ubicación
	# Defime marcos
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Personas registradas');
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Datos individuales');
	my $mBotones = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'DatosP'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
	
	# Define Lista de datos
	my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe', -width => 45,
		-selectmode => 'single', -orient => 'horizontal', -font => $tp{mn}, 
		-command => sub { &modifica($esto) } );
	$esto->{'vLista'} = $listaS;
	
	# Define botones
	$bReg = $mBotones->Button(-text => "Registra", 
		-command => sub { &registra($esto, $ucc) } ); 
	$bNvo = $mBotones->Button(-text => "Agrega", 
		-command => sub { &agrega($esto, $ucc) } ); 
	my $bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); } );
	
	# Define campos para registro de datos del socio
	$rut = $mDatos->LabEntry(-label => "RUT:   ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Rut );
	# Si es que utiliza centros de costos
	$nombre = $mDatos->LabEntry(-label => "Nombre: ", -width => 40,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Nombre);
	$nombre->bind("<FocusIn>", sub { &buscaRUT($esto) } );
	if ($ucc) {
	  $cCto = $mDatos->LabEntry(-label => "Centro Costo:   ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CCto );	
	  $nCCto = $mDatos->Label(-textvariable => \$NCCto, -font => $tp{mn});	
	}
	$fechaI = $mDatos->LabEntry(-label => "Fechas:   Ingreso ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaI );
	if ($ucc) {
		$fechaI->bind("<FocusIn>", sub { &buscaCC($esto) } );	
	}
	$fechaR = $mDatos->LabEntry(-label => "Retiro ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaR );
	$direc = $mDatos->LabEntry(-label => "Dirección: ", -width => 40,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Direc);
	$comuna = $mDatos->LabEntry(-label => "Comuna: ", -width => 20,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Comuna);
	$fonos = $mDatos->LabEntry(-label => "Fono: ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Fonos);
		
	@datos = muestraLista($esto);
	if (not @datos) {
		$Mnsj = "No hay registros" ;
	}
	
	# Dibuja interfaz
	$rut->grid(-row => 0, -column => 0, -columnspan => 2, -sticky => 'nw');	
	$nombre->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nw');
	if ($ucc) {	# Si es que utiliza centros de costos
		$cCto->grid(-row => 2, -column => 0, -columnspan => 2, -sticky => 'nw');
		$nCCto->grid(-row => 3, -column => 0, -columnspan => 2, -sticky => 'nw');
	}
	$fechaI->grid(-row => 4, -column => 0, -sticky => 'nw');
	$fechaR->grid(-row => 4, -column => 1, -sticky => 'nw');
	$direc->grid(-row => 5, -column => 0, -columnspan => 2, -sticky => 'nw');
	$comuna->grid(-row => 6, -column => 0, -sticky => 'nw');
	$fonos->grid(-row => 6, -column => 1,  -sticky => 'nw');

	$bReg->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	
	$listaS->pack();
	$mLista->pack(-expand => 1);
	$mDatos->pack(-expand => 1);	
	$mBotones->pack(-expand => 1);
	$mMensajes->pack(-expand => 1, -fill => 'both');
	
	# Inicialmente deshabilita botón Registra
	$bReg->configure(-state => 'disabled');

	bless $esto;
	return $esto;
}

# Funciones internas
sub buscaRUT ( $ ) {

	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	if ( $bReg->cget('-state') eq 'active' ) { return ;}

	$Mnsj = " ";
	if (not $Rut) {
		$Mnsj = "Debe registrar un RUT";
		$rut->focus;
		return;
	}
	$Rut = uc($Rut); # Convierte k en K
	$Rut =~ s/^0// ; # Elimina 0 al inicio
	if ( not $ut->vRut($Rut) ) {
		$Mnsj = "RUT no es válido";
		$rut->focus;
	} else {
		if ( $bd->buscaP($Rut)) {
			$Mnsj = "Ese RUT ya esta registrado.";
			$rut->focus;
		}
	}
	return;
}

sub buscaCC ( $ ) {

	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};

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

sub muestraLista ( $ ) 
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	
	# Obtiene lista con datos del personal registrado
	my @data = $bd->datosP();

	# Completa TList con nombres y rut del peersonal
	my ($algo, $nm);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$nm = sprintf("%10s %-32s", $algo->[0], decode_utf8($algo->[1]) ) ;
		$listaS->insert('end', -itemtype => 'text', -text => "$nm" ) ;
	}
	# Devuelve una lista de listas con datos socios
	return @data;
}

sub modifica ( )
{
	my ($esto) = @_;
	my $listaS = $esto->{'vLista'};
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	if (not @datos) {
		$Mnsj = "NO hay datos para modificar";
		return;
	}
	
	$bNvo->configure(-state => 'disabled');
	$bReg->configure(-state => 'active');
	
	# Obtiene datos de persona seleccionada
	my @ns = $listaS->info('selection');
	my $socio = @datos[$ns[0]];
	
	# Rellena campos
	$Nombre = decode_utf8($socio->[1]);
	$Rut =  $socio->[0];
	$Direc =  $socio->[2];
	$Comuna =  $socio->[3];
	$Fonos = $socio->[4];
	$FechaI = $socio->[5]; 
	$FechaR = $socio->[6];
	$CCto = $socio->[8];
	$NCCto = decode_utf8($bd->nombreCentro($CCto));
	# Impide modificar RUT
	$rut->configure(-state => 'disabled');

}

sub registra ( $ )
{
	my ($esto, $cc) = @_;
	my $bd = $esto->{'baseDatos'};
	
	# Verifica que se completen datos
	$Mnsj = " ";
	if ($Nombre eq "") {
		$Mnsj = "Debe registrar un nombre";
		return;
	}
	if ($cc and $CCto eq "") {
		$Mnsj = "Indique código Centro de Costo";
		return;		
	}

	# Graba datos
	$bd->grabaP($Nombre,$Rut,$Direc,$Comuna,$Fonos,$FechaI,$FechaR,$CCto);

	# Muestra lista actualizada 
	@datos = muestraLista($esto);
	
	limpiaCampos();
	
	$rut->configure(-state => 'normal');
	$bNvo->configure(-state => 'active');
	$bReg->configure(-state => 'disabled');
	$rut->focus;
}

sub agrega ( $ )
{
	my ($esto, $cc) = @_;
	my $bd = $esto->{'baseDatos'};
	
	# Comprueba RUT
	$Mnsj = " ";
	if ($Rut eq "") {
		$Mnsj = "Debe registrar RUT de la persona.";
		$rut->focus;
		return;
	}
	# Verifica que se completen datos
	if ($Nombre eq "") {
		$Mnsj = "Registre el nombre";
		$nombre->focus;
		return;
	}
	# Si usa Centros de Costos
	if ($cc and $CCto eq "") {
		$Mnsj = "Indique el Centro de Costo";
		$cCto->focus;
		return;		
	}

	# Graba datos
	$bd->agregaP($Rut,$Nombre,$Direc,$Comuna,$Fonos,$FechaI,$FechaR,$Fecha,$CCto);

	@datos = muestraLista($esto);
	limpiaCampos();
	$rut->focus;
}

sub limpiaCampos( )
{
	$rut->delete(0,'end');
	$nombre->delete(0,'end');
	$direc->delete(0,'end');
	$comuna->delete(0,'end');
	$fonos->delete(0,'end');
	$fechaI->delete(0,'end');
	$fechaR->delete(0,'end');
	
	$Nombre = $Rut = $Direc = $Comuna = $Fonos = '' ;
	$CCto = $FechaI = $FechaR = $NCCto = '';
}

# Fin del paquete
1;
