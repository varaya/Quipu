#  RCCsts.pm - Registra o modifica la definición de Centros de Costos
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package RCCsts;
use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';
	
# Variables válidas dentro del archivo
my ($Codigo, $Nombre, $Grupo, $Tipo, $Id, $Mnsj, $Agr );	# Datos
my ($codigo, $nombre, $grupo, $grupoT, $grupoP, $tipo, $tipoR, $tipoG); # Campos
my ($bReg, $bNvo, $agrupa ) ; 	# Botones
my @datos = () ;		# Lista de grupos
		
sub crea {

	my ($esto, $vp, $mt, $bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	my %tp = $ut->tipos();
	$Codigo = $Nombre = $Grupo = $Tipo = '';
	$Agr = 0;

	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Centros de Costos");
	$vnt->geometry("380x380+475+4"); # Tamaño y ubicación
	
	# Defime marcos
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Centros registrados', -width => 400);
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Datos centro');
	my $mBotones = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'CCostos'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para Ayuda presione botón 'i'.";

	# Define Lista de datos
	my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe',
		-selectmode => 'single', -orient => 'horizontal', -width => 45,
		-command => sub { &modifica($esto) } );
	$esto->{'vLista'} = $listaS;
	
	# Define botones
	$bReg = $mBotones->Button(-text => "Registra", 
		-command => sub { &registra($esto, @grupo) } ); 
	$bNvo = $mBotones->Button(-text => "Agrega", 
		-command => sub { &agrega($esto, @grupo) } ); 
	my $bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy();  } );
	
	# Define campos para registro de datos del subgrupo
	$codigo = $mDatos->LabEntry(-label => " Código:   ", -width => 3,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000',
		-textvariable => \$Codigo );
	$agrupa = $mDatos->Checkbutton(-text => "Agrupa sub centros",
		-variable => \$Agr, -offvalue => '0', -onvalue => '1');	
	$nombre = $mDatos->LabEntry(-label => " Nombre: ", -width => 40,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Nombre);
	$grupo = $mDatos->Label(-text => "  Grupo: ");
	$grupoT = $mDatos->Radiobutton( -text => "Temporal", -value => 'T', 
		-variable => \$Grupo );
	$grupoP = $mDatos->Radiobutton(-text => "Permanente", -value => 'P', 
		-variable => \$Grupo );
	$tipo = $mDatos->Label(-text => "  Tipo: ");
	$tipoR = $mDatos->Radiobutton(-text => "Resultados", -value => 'R', 
		-variable => \$Tipo );
	$tipoG = $mDatos->Radiobutton(-text => "Gastos", -value => 'G', 
		-variable => \$Tipo );
		
	@datos = muestraLista($esto);
	if (not @datos) {
		$Mnsj = "No hay centros registrados" ;
	}
		
	# Dibuja interfaz
	$codigo->grid(-row => 0, -column => 0, -sticky => 'nw');
	$agrupa->grid(-row => 0, -column => 1, -columnspan => 2, -sticky => 'ne');	
	$nombre->grid(-row => 1, -column => 0, -columnspan => 3, -sticky => 'nw');	
	$grupo->grid(-row => 2, -column => 0, -sticky => 'nw');
	$grupoT->grid(-row => 2, -column => 1, -sticky => 'nw');
	$grupoP->grid(-row => 2, -column => 2, -sticky => 'nw');
	$tipo->grid(-row => 3, -column => 0, -sticky => 'nw');
	$tipoR->grid(-row => 3, -column => 1, -sticky => 'nw');
	$tipoG->grid(-row => 3, -column => 2, -sticky => 'nw');

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
	my @data = $bd->datosCentros();
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
	$Tipo =  $sGrupo->[2];
	$Grupo =  $sGrupo->[3];
	$Agr =  $sGrupo->[4];
	$codigo->configure(-state => 'disabled');
	
	# Obtiene Id del registro
	$Id = $bd->idCentro($Codigo);
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
		$Mnsj = "El Centro debe tener un nombre.";
		$nombre->focus;
		return;
	}
	if ($Grupo eq "") {
		$Mnsj = "Debe marcar un grupo.";
		return;
	}
	if ($Tipo eq "") {
		$Mnsj = "Debe indicar un tipo.";
		return;
	}

	# Graba datos
	$bd->grabaCentro($Codigo, $Nombre, $Tipo, $Grupo, $Agr, $Id);

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
	my $rid = $bd->idCentro($Codigo);
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
	if ($Tipo eq "") {
		$Mnsj = "Indique un tipo de centro.";
		return;
	}

	# Graba datos
	$bd->agregaCentro($Codigo, $Nombre, $Tipo, $Grupo, $Agr);

	# Muestra lista modificada de grupos
	@datos = muestraLista($esto);
	
	limpiaCampos();
	$codigo->focus;

}

sub limpiaCampos
{
	$codigo->delete(0,'end');
	$nombre->delete(0,'end');
	$Grupo = $Tipo = $Codigo = '';
	$Agr = 0;
	$codigo->configure(-state => 'normal');
}

# Fin del paquete
1;
