#  CuentasM.pm - Registra o modifica el Plan de Cuentas: cuentas de mayor
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM: 24.06.2009

package CuentasM;

use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Tk::BrowseEntry;
use Encode 'decode_utf8';
#use Data::Dumper; print Dumper \@listaG;
	
# Variables válidas dentro del archivo
my ($Codigo, $Nombre, $nGrupo, $cGrupo, $Id, $CuentaI, $IEspcl, $Ngtv);	# Datos
my ($codigo, $nombre, $grupos,$tipoI,$tipoN,$tipoC,$tipoB,$iEspcl,$ngtv) ;	# Campos 
my ($bReg, $bNvo) ; 	# Botones
my @listaG = () ;		# Lista de grupos
my @datos = () ;		# Lista de cuentas
			
sub crea {

	my ($esto, $vp, $marcoT, $bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	$Nombre = $nGrupo = $cGrupo = $Codigo = '';
	$CuentaI = $IEspcl = $Ngtv = 'N';

	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Cuentas de Mayor");
	$vnt->geometry("380x420+475+4"); # Tamaño y ubicación
	
	# Defime marcos
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Cuentas registradas');
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Datos cuenta');
	my $mGrupos = $mDatos->Frame();
	my $mBotones = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($marcoT, 'CuentasM'); } ); 
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
		-command => sub { $vnt->destroy(); } );
	
	# Define campos para registro de datos de la cuenta
	$codigo = $mDatos->LabEntry(-label => " Código:   ", -width => 4,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000',
		-textvariable => \$Codigo );

	$nombre = $mDatos->LabEntry(-label => " Nombre: ", -width => 40,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Nombre);
	$tipo = $mDatos->Label(-text => " Tipo: ");
	$tipoN = $mDatos->Radiobutton( -text => "Normal", -value => 'N', 
		-variable => \$CuentaI );
	$tipoI = $mDatos->Radiobutton(-text => "CtaCte", -value => 'I', 
		-variable => \$CuentaI );
	$tipoB = $mDatos->Radiobutton(-text => "Bancos", -value => 'B', 
		-variable => \$CuentaI );
	$tipoC = $mDatos->Radiobutton(-text => "Cierre", -value => 'C', 
		-variable => \$CuentaI );

	my $grupoT = $mGrupos->Label(-text => " Subgrupo ");
	$grupos = $mGrupos->BrowseEntry( -variable => \$nGrupo, -state => 'readonly',
		-disabledbackground => '#FFFFFC', -autolimitheight => 1,
		-disabledforeground => '#000000', -autolistwidth => 1,
		-browse2cmd => \&selecciona );
	# Crea opciones del combobox
	@listaG = $bd->datosSG();
	my $algo;
	foreach $algo ( @listaG ) {
		$grupos->insert('end', decode_utf8($algo->[1]) ) ;
	}
			
	@datos = muestraLista($esto);
	if (not @datos) {
		$listaS->insert('end', -itemtype => 'text', 
			-text => "No hay cuentas registradas" ) ;
	}
	
#	$cuentaI = $mDatos->Checkbutton(-text => 'Controla cuentas individuales',
#		-variable => \$CuentaI, -offvalue => 'N', -onvalue => 'S');
	$iEspcl = $mDatos->Checkbutton(-text => "ILA o Impuesto Especial",
		-variable => \$IEspcl, -offvalue => 'N', -onvalue => 'S');
	$ngtv = $mDatos->Checkbutton(-text => "Signo negativo",
		-variable => \$Ngtv, -offvalue => 'N', -onvalue => 'S');
	
	# Dibuja interfaz
	$grupoT->pack(-side => "left", -anchor => "nw");
	$grupos->pack(-side => "left", -anchor => "nw");
	$mGrupos->pack(-side => "top", -anchor => "nw");
	$codigo->pack(-side => "top", -anchor => "nw");	
	$nombre->pack(-side => "top", -anchor => "nw");
	$iEspcl->pack(-side => "top", -anchor => "nw");
	$ngtv->pack(-side => "top", -anchor => "nw");

	$tipo->pack(-side => "left", -anchor => "nw");
	$tipoN->pack(-side => "left", -anchor => "e");
	$tipoI->pack(-side => "left", -anchor => "e");
	$tipoB->pack(-side => "left", -anchor => "e");
	$tipoC->pack(-side => "left", -anchor => "e");
	
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
	# y verifica que esten definidos los subgrupos
	if (not @listaG) {
		$marcoT->insert('end', "\n Falta definir subgrupos\n", 'grupo' ) ;
		$bNvo->configure(-state => 'disabled');
	}

	bless $esto;
	return $esto;
}

# Funciones internas
sub selecciona {
	my ($jc, $Index) = @_;
	$Codigo = $cGrupo = $listaG[$Index]->[0];
	$codigo->icursor('end');
	$codigo->focus;
}

sub muestraLista ( $ ) 
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	
	# Obtiene lista con datos de cuentas registradas
	my @data = $bd->datosCuentas(1);

	# Completa TList con nombres de los cuentas
	my ($algo, $nm);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$nm = sprintf("%-5s %-30s", $algo->[0], decode_utf8($algo->[1]) ) ;
		$listaS->insert('end', -itemtype => 'text', -text => "$nm" ) ;
	}
	# Devuelde una lista de listas con datos de las cuentas
	return @data;
}

sub modifica ( )
{
	my ($esto) = @_;
	my $listaS = $esto->{'vLista'};
	my $bd = $esto->{'baseDatos'};
		
	$Mnsj = " ";
	my $nd = @datos;
	if ($nd == 0) {
		$Mnsj = "NO hay datos para modificar";
		return;
	}
	
	$bNvo->configure(-state => 'disabled');
	$bReg->configure(-state => 'active');
	
	# Obtiene cuenta seleccionada
	my @ns = $listaS->info('selection');
	my $sGrupo = @datos[$ns[0]];
	
	# Rellena campos
	$cGrupo = $sGrupo->[2];
	$nGrupo = $bd->nombreGrupo($cGrupo);
	$Codigo = $sGrupo->[0];
	$Nombre =  decode_utf8( $sGrupo->[1] );
	$IEspcl = $sGrupo->[3];
	$CuentaI = $sGrupo->[4];
	$Ngtv = $sGrupo->[5];
	$codigo->configure(-state => 'disabled');
	
	# Obtiene Id del registro
	$Id = $bd->idCuenta($Codigo);
}

sub registra ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	if ($nGrupo eq "") {
		$Mnsj = "Debe seleccionar un subgrupo.";
		$grupos->focus;
		return;
	}
	# Comprueba largo del código
	if (not length $Codigo == 4 ) {
		$Mnsj = "Código debe tener 4 dígitos";
		$codigo->focus;
		return;
	}
	# Verifica que se completen datos de la cuenta
	if ($Nombre eq "") {
		$Mnsj = "La cuenta debe tener un nombre";
		$nombre->focus;
		return;
	}

	# Graba datos
	$bd->grabaCuenta($Codigo,$Nombre,$cGrupo,$IEspcl,$CuentaI,$Ngtv,$Id);

	# Muestra lista actualizada de cuentas
	@datos = muestraLista($esto);
	
	limpiaCampos();
	$grupos->focus;
	
	$bNvo->configure(-state => 'active');
	$bReg->configure(-state => 'disabled');
}

sub agrega ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	if ($nGrupo eq "") {
		$Mnsj = "Tenga a bien indicar un subgrupo";
		$grupos->focus;
		return;
	}
	# Comprueba registro del código
	if (not length $Codigo == 4) {
		$Mnsj = "Código debe tener 4 dígitos";
		$codigo->focus;
		return;
	}
	# Verifica código no duplicado
	my $rid = $bd->idCuenta($Codigo);
	if ($rid) {
		$Mnsj = "Código duplicado";
		$codigo->icursor('end');
		$codigo->focus;
		return;
	} 
	# Verifica que se completen datos de la cuenta
	if ($Nombre eq "") {
		$Mnsj = "Debe registrar un nombre";
		$nombre->focus;
		return;
	}
	# Graba datos
	$bd->agregaCuenta($Codigo,$Nombre,$cGrupo,$IEspcl,$CuentaI,$Ngtv);

	# Muestra lista modificada de cuentas
	@datos = muestraLista($esto);
	
	limpiaCampos();
	$grupos->focus;
}

sub limpiaCampos ( )
{
	$codigo->delete(0,'end');
	$nombre->delete(0,'end');
	$IEspecial = $CuentaI = $Ngtv= 'N';
	$Nombre = $nGrupo = $cGrupo = $Codigo = '';
	$codigo->configure(-state => 'normal');
}

# Fin del paquete
1;
