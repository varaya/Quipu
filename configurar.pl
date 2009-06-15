#!/usr/bin/perl -w

#  configurar.pl - Define parámetros básicos y agrega empresas
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete 

if (defined $ARGV[0]) { print "\nVersión en red, pendiente.\n\n"; exit ;
  } else { use prg::BaseDatos; }
use Tk;
use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';

use prg::Utiles;

my ($nbd, $Nombre, $Rut, $Mnsj, $Prd, $Multi, $ne); # Variables
my ($nombre, $rut, $prd, $multi ); # Campos
my ($bCan, $bNvo) ; # Botones
my @datos = () ;	# Lista de empresas
$nbd = 'datosG.db3' ;
if (not -e $nbd) {
	system "./creaTablas.pl";
}		
my $bd = BaseDatos->crea($nbd);
my @cnf = $bd->leeCnf();
$Prd = $cnf[0];
$Multi = $cnf[3];
$Nombre = $Rut = '';

# Define ventana
my $vnt = MainWindow->new();
$vnt->title("Configura Programa Quipu");
$vnt->geometry("370x380+2+2"); # Tamaño y ubicación
my $ut = Utiles->crea($vnt);
my $esto = {};
$esto->{'baseDatos'} = $bd;
$esto->{'mensajes'} = $ut;

# Defime marcos
my $mParametros = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
	-label => 'Datos iniciales');
my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
	-label => 'Empresas creadas');
my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
	-label => 'Datos empresa');
my $mBtns = $vnt->Frame(-borderwidth => 1);
my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

# Barra de mensajes y botón de ayuda
my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => 'fixed',
	-bg => '#F2FFE6', -fg => '#800000',);
$mnsj->pack(-side => 'left', -expand => 1, -fill => 'x');
$Mnsj = "Mensajes de error o advertencias.";

# Define Lista de datos
my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe', -width => 65,
	-selectmode => 'single', -orient => 'horizontal', -font => 'fixed', 
	-height => 12 );
$esto->{'vLista'} = $listaS;

# Define botones
$bNvo = $mBtns->Button(-text => "Agrega", -command => sub { &agrega($esto)}); 
$bCan = $mBtns->Button(-text => "Termina", 
	-command => sub { $vnt->destroy(); $bd->cierra();});

# Parametros
$prd = $mParametros->LabEntry(-label => "Año inicial", -width => 5,
	-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
	-textvariable => \$Prd );
$multi = $mParametros->Checkbutton(-variable => \$Multi, 
		 -text => "Multiempresa",);
# Define campos para registro de datos de la empresa
$rut = $mDatos->LabEntry(-label => "RUT:   ", -width => 12,
	-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
	-textvariable => \$Rut );

$nombre = $mDatos->LabEntry(-label => "Razón Social: ", -width => 35,
	-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
	-textvariable => \$Nombre);
$nombre->bind("<FocusIn>", sub { &buscaRUT($esto) } );

# Dibuja interfaz
$prd->pack(-side => 'left', -expand => 0, -fill => 'none');
$multi->pack(-side => 'left', -expand => 0, -fill => 'none');
$rut->grid(-row => 0, -column => 0, -columnspan => 2, -sticky => 'nw');	
$nombre->grid(-row => 1, -column => 0, -columnspan => 2, -sticky => 'nw');

$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

$mParametros->pack(-expand => 1);
$listaS->pack();
$mLista->pack(-expand => 1);
$mDatos->pack(-expand => 1);	
$mBtns->pack(-expand => 1);
$mMensajes->pack(-expand => 1, -fill => 'both');

@datos = &muestraLista($esto);
$ne = @datos; # Número de empresas
if (not $ne) {
	$Mnsj = "No hay registros" ;
}

# Ejecuta el programa
MainLoop;

# Funciones internas
sub buscaRUT ($) {

	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	$Mnsj = " ";
	if (not $Rut) {
		$Mnsj = "Debe registrar un RUT";
		$rut->focus;
		return;
	}
	if ( not $ut->vRut($Rut) ) {
		$Mnsj = "RUT no es válido";
		$rut->focus;
	} else {
		if ( $bd->buscaE($Rut)) {
			$Mnsj = "Ese RUT ya esta registrado.";
			$rut->focus;
		}
	}
	return;
}

sub muestraLista ($) 
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	
	# Obtiene lista con datos de las empresas
	my @data = $bd->listaEmpresas();

	# Completa TList con nombres y rut de la empresas
	my ($algo, $nm);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$nm = sprintf("%10s %-32s", $algo->[0], decode_utf8($algo->[1]) ) ;
		$listaS->insert('end', -itemtype => 'text', -text => "$nm" ) ;
	}
	# Devuelve una lista de listas con datos
	return @data;
}

sub agrega ()
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	# Comprueba RUT
	$Mnsj = " ";
	if ($Rut eq "") {
		$Mnsj = "Debe registrar RUT de la Empresa.";
		$rut->focus;
		return;
	}
	# Verifica que se completen datos
	if ($Nombre eq "") {
		$Mnsj = "Debe registrar un nombre";
		$nombre->focus;
		return;
	}
	if ($Prd eq "") {
		$Mnsj = "Indique año inicial";
		$prd->focus;
		return;
	}

	# Graba datos
	$bd->agregaE($Rut,$Nombre,$Multi,$Prd);
	$bd->grabaCnf($Multi,$Prd) if not $ne ;
	# Crea tablas
	system "./creaTablasRC.pl", $Rut, $Prd ;

	@datos = muestraLista($esto);
	$ne = @datos;
	
	$rut->delete(0,'end');
	$nombre->delete(0,'end');
	$Nombre = $Rut = '';
	$rut->focus;
}

# Termina la ejecución del programa
exit (0);
