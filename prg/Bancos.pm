#  Bancos.pm - Registra Bancos, como subcuentas
#  Forma parte del programa Quipu
#
#  Derechos de autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM: 02.07.2009

package Bancos;

use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';
	
# Variables válidas dentro del archivo
my ($Codigo, $Nombre, $RUT, $Id, $Mnsj);	# Datos
my ($codigo, $nombre, $rut) ;	# Campos
my ($bReg, $bNvo) ; 	# Botones
my @datos = () ;		# Lista de grupos
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut) = @_;
	
	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
	
	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Agrega o Modifica Bancos");
	$vnt->geometry("260x330+475+4"); # Tamaño y ubicación
	
	# Inicializa variables
	$Codigo = $RUT = $Nombre = "";
	my %tp = $ut->tipos();
	
	# Defime marcos
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Bancos registrados');
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Identificación Banco');
	my $mBotones = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'TipoD'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para Ayuda presione botón 'i'.";
	
	# Define lista de datos
	my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe', -height => 8,
		-selectmode => 'single', -orient => 'horizontal', -width => 30,
		-command => sub { &modifica($esto) } );
	$esto->{'vLista'} = $listaS;
	
	# Define botones
	$bReg = $mBotones->Button(-text => "Registra", 
		-command => sub { &registra($esto, @grupo) } ); 
	$bNvo = $mBotones->Button(-text => "Agrega", 
		-command => sub { &agrega($esto, @grupo) } ); 
	my $bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy() } );
	
	# Define campos para registro de datos del subgrupo
	$codigo = $mDatos->LabEntry(-label => " Código:   ", -width => 4,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Codigo );
	$codigo->bind("<FocusOut>", sub { $Codigo = uc($Codigo); } );
	$rut = $mDatos->LabEntry(-label => " RUT: ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$RUT);
	$nombre = $mDatos->LabEntry(-label => " Nombre: ", -width => 20,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Nombre);
	$nombre->bind("<FocusIn>", sub { &buscaRUT($esto) } );

	@datos = muestraLista($esto);
	if (not @datos) {
		$Mnsj = "No hay Bancos registrados" ;
	}
		
	# Dibuja interfaz
	$codigo->pack(-side => "top", -anchor => "nw");	
	$rut->pack(-side => "top", -anchor => "nw");
	$nombre->pack(-side => "top", -anchor => "nw");

	$bReg->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	
	$mMensajes->pack(-expand => 1, -fill => 'both');
	$listaS->pack();
	$mLista->pack(-expand => 1);
	$mDatos->pack(-expand => 1);	
	$mBotones->pack(-expand => 1);
	
	# Inicialmente deshabilita botón Registra
	$bReg->configure(-state => 'disabled');

	bless $esto;
	return $esto;
}

# Funciones internas
sub muestraLista ( $ ) 
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	
	# Obtiene lista con datos de grupos registrados
	my @data = $bd->datosBcs();

	# Completa TList con nombres de los grupos
	my ($algo, $nm);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$nm = sprintf("%-3s  %-15s", $algo->[0], decode_utf8($algo->[1]) ) ;
		$listaS->insert('end', -itemtype => 'text', -text => "$nm" ) ;
	}
	# Devuelve una lista de listas con datos grupos
	return @data;
}

sub buscaRUT ($ ) {

	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};
	
	$Mnsj = " ";
	if (not $RUT) {
		$Mnsj = "Debe registrar un RUT.";
		$rut->focus;
		return;
	}
	$RUT = uc($RUT);
	$RUT =~ s/^0// ; # Elimina 0 al inicio
	if ( not $ut->vRut($RUT) ) {
		$Mnsj = "RUT no es válido.";
		$rut->focus;
	} else {
		my $nmb = $bd->buscaT($RUT);
		if ( $nmb) {
			$Mnsj = "Ese RUT ya está registrado.";
			$rut->focus;
		}
	}
	return;
}

sub modifica ( )
{
	my ($esto) = @_;
	my $listaS = $esto->{'vLista'};
	my $bd = $esto->{'baseDatos'};
		
	$Mnsj = " ";
	if (not @datos) {
		$Mnsj = "NO hay datos para modificar.";
		return;
	}
	
	$bNvo->configure(-state => 'disabled');
	$bReg->configure(-state => 'active');
	
	# Obtiene grupo seleccionado
	my @ns = $listaS->info('selection');
	my $sGrupo = @datos[$ns[0]];
	
	# Rellena campos
	$Codigo = $sGrupo->[0];
	$Nombre =  decode_utf8( $sGrupo->[1] );
	$RUT = $sGrupo->[2];
	$Id = $sGrupo->[3];
}

sub registra ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	# Comprueba registro del código
	if ($Codigo eq "") {
		$Mnsj = "Falta Código.";
		$codigo->focus ;
		return;
	}
	# Verifica que se completen datos del grupo
	if ($Nombre eq "") {
		$Mnsj = "Indique el nombre.";
		$nombre->focus ;
		return;
	}

	# Graba datos
	$bd->grabaDatosB($Codigo, $Nombre, $RUT);

	# Muestra lista actualizada de grupos
	@datos = muestraLista($esto);
	
	limpiaCampos();
	
	$bNvo->configure(-state => 'active');
	$bReg->configure(-state => 'disabled');
}

sub agrega ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	# Comprueba registro del código
	if ($Codigo eq "") {
		$Mnsj = "Debe registrar Código.";
		$codigo->focus ;
		return;
	}
	# Verifica código no duplicado
	if ( $bd->buscaB($Codigo) ) {
		$Mnsj = "Código duplicado.";
		$codigo->focus ;
		return;
	} 
	# Verifica que se completen datos del grupo
	if ($Nombre eq "") {
		$Mnsj = "Debe registrar un nombre.";
		$nombre->focus ;
		return;
	}
	# Graba datos
	$bd->agregaB($Codigo, $Nombre, $RUT);

	# Muestra lista modificada de grupos
	@datos = muestraLista($esto);
	
	limpiaCampos();
}

sub limpiaCampos ( )
{
	$Codigo = $Nombre = $RUT = "";
	$codigo->delete(0,'end');
	$nombre->delete(0,'end');
	$rut->delete(0,'end');
	$codigo->focus ;
}

# Fin del paquete
1;
