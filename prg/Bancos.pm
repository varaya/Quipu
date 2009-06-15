#  Bancos.pm - Registra Bancos, como subcuentas
#  Forma parte del programa PartidaDoble
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete 

package Bancos;

use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';
	
# Variables válidas dentro del archivo
my ($Codigo, $Nombre, $Id, $Mnsj);	# Datos
my ($codigo, $nombre) ;	# Campos
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
	$vnt->geometry("260x300+475+4"); # Tamaño y ubicación
	
	# Inicializa variables
	$Codigo = $Nombre = "";
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
	my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe',
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

	$nombre = $mDatos->LabEntry(-label => " Nombre: ", -width => 20,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Nombre);
	
	@datos = muestraLista($esto);
	if (not @datos) {
		$Mnsj = "No hay Bancos registrados" ;
	}
		
	# Dibuja interfaz
	$codigo->pack(-side => "top", -anchor => "nw");	
	$nombre->pack(-side => "top", -anchor => "nw");

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
	$Id = $sGrupo->[2];
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
	$bd->grabaDatosB($Codigo, $Nombre, $Id);

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
	$bd->agregaB($Codigo, $Nombre);

	# Muestra lista modificada de grupos
	@datos = muestraLista($esto);
	
	limpiaCampos();
}

sub limpiaCampos ( )
{
	$Codigo = $Nombre = "";
	$codigo->delete(0,'end');
	$nombre->delete(0,'end');
	$codigo->focus ;
}

# Fin del paquete
1;
