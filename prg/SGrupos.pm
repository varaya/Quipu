#  SGrupos.pm - Registra o modifica el Plan de Cuentas: subgrupos de cuentas
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM: 20.06.2009

package SGrupos;

use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';
	
# Variables válidas dentro del archivo
my ($Codigo, $Nombre, $Grupo, $Id, $Mnsj);	# Datos
my ($codigo, $nombre, $grupo, $grupoA, $grupoP, $grupoI, $grupoG) ;	# Campos
my ($bReg, $bNvo) ; 	# Botones
my @datos = () ;		# Lista de grupos
			
sub crea {

	my ($esto, $vp, $bd, $ut, $mt) = @_;
	
	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	my %tp = $ut->tipos();
	$Codigo = $Nombre = $Grupo = '';

	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Agrega o Modifica SubGrupos de Cuentas");
	$vnt->geometry("380x350+475+4"); # Tamaño y ubicación
	
	# Defime marcos
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Subgrupos registrados');
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Datos subgrupo');
	my $mBotones = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'SGrupos'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";

	# Define Lista de datos
	my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe',
		-selectmode => 'single', -orient => 'horizontal', -width => 35,
		-command => sub { &modifica($esto) } );
	$esto->{'vLista'} = $listaS;
	
	# Define botones
	$bReg = $mBotones->Button(-text => "Registra", 
		-command => sub { &registra($esto, @grupo) } ); 
	$bNvo = $mBotones->Button(-text => "Agrega", 
		-command => sub { &agrega($esto, @grupo) } ); 
	my $bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { &cancela($esto) } );
	
	# Define campos para registro de datos del subgrupo
	$codigo = $mDatos->LabEntry(-label => " Código:   ", -width => 3,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000',
		-textvariable => \$Codigo );

	$nombre = $mDatos->LabEntry(-label => " Nombre: ", -width => 40,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Nombre);

	$grupo = $mDatos->Label(-text => " Grupo: ");
	$grupoA = $mDatos->Radiobutton( -text => "Activo", -value => 'A', 
		-variable => \$Grupo );
	$grupoP = $mDatos->Radiobutton(-text => "Pasivo", -value => 'P', 
		-variable => \$Grupo );
	$grupoI = $mDatos->Radiobutton(-text => "Ingresos", -value => 'I', 
		-variable => \$Grupo );
	$grupoG = $mDatos->Radiobutton(-text => "Gastos", -value => 'G', 
		-variable => \$Grupo );
		
	@datos = muestraLista($esto);
	if (not @datos) {
		$Mnsj = "No hay subgrupos registrados" ;
	}
		
	# Dibuja interfaz
	$codigo->pack(-side => "top", -anchor => "nw");	
	$nombre->pack(-side => "top", -anchor => "nw");
	$grupo->pack(-side => "left", -anchor => "nw");
	$grupoA->pack(-side => "left", -anchor => "e");
	$grupoP->pack(-side => "left", -anchor => "e");
	$grupoI->pack(-side => "left", -anchor => "e");
	$grupoG->pack(-side => "left", -anchor => "e");

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
	my @data = $bd->datosSG();

	# Completa TList con nombres de los grupos
	my ($algo, $nm);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$nm = sprintf("%-5s %-30s", $algo->[0], decode_utf8($algo->[1]) ) ;
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
	$Grupo =  $sGrupo->[2];
	$codigo->configure(-state => 'disabled');
	
	# Obtiene Id del registro
	$Id = $bd->idGrupo($Codigo);
}

sub registra ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	# Comprueba registro del código
	if ($Codigo eq "") {
		$Mnsj = "Falta Código.";
		$codigo->focus;
		return;
	}
	# Verifica que se completen datos del grupo
	if ($Nombre eq "") {
		$Mnsj = "El subgrupo debe tener un nombre.";
		$nombre->focus;
		return;
	}
	if ($Grupo eq "") {
		$Mnsj = "Debe marcar un grupo.";
		return;
	}

	# Graba datos
	$bd->grabaGrupo($Codigo, $Nombre, $Grupo, $Id);

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
		$codigo->focus;
		return;
	}
	# Verifica codigo no duplicado
	my $rid = $bd->idGrupo($Codigo);
	if ($rid) {
		$Mnsj = "Código duplicado.";
		$codigo->focus;
		return;
	} 
	# Verifica que se completen datos del grupo
	if ($Nombre eq "") {
		$Mnsj = "Debe registrar un nombre.";
		$nombre->focus;
		return;
	}
	if ($Grupo eq "") {
		$Mnsj = "Tenga a bien indicar un grupo.";
		return;
	}

	# Graba datos
	$bd->agregaGrupo($Codigo, $Nombre, $Grupo);

	# Muestra lista modificada de grupos
	@datos = muestraLista($esto);
	
	limpiaCampos();
	$codigo->focus;

}

sub limpiaCampos
{
	$codigo->delete(0,'end');
	$nombre->delete(0,'end');
	$Grupo = '';
	$codigo->configure(-state => 'normal');
}

sub cancela ( )
{
	my ($esto) = @_;	
	my $vn = $esto->{'ventana'};
	
	$vn->destroy();
}

# Fin del paquete
1;
