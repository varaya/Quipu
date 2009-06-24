#!/usr/bin/perl -w

#  ajustes.pl - Cambia fecha de contabilizacion de un documento
#  Forma parte del programa Quipu
#
#  Derechos de Autor (c) V�ctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los t�rminos previstos en la licencia
#  incluida en este paquete 
#  UM: 17.06.2009

use prg::BaseDatos;
use Tk;
use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';

use prg::Utiles;

my ($Rut,$Mnsj,$FechaC,$NumD,$Ni,$Tabla,$TipoD,$Mes,$MesC,$NumC,$Id); # Variables
my ($mes, $de, $dr, $fc, $nd, $nc, $ni, $rut, $numD, $fechaC, $numC ); # Campos
my ($bCan, $bNvo) ; # Botones

# Datos de configuraci�n
my $bd = BaseDatos->crea('datosG.db3');
@cnf = $bd->leeCnf();
$base = "$cnf[0].db3" ;	# nombre del archivo de datos (corresponde al a�o)
@unaE = $bd->datosE();
my $RutE = $unaE[1];
$bd->cierra();
$bd = BaseDatos->crea("$RutE/$base");

# Define ventana
my $vnt = MainWindow->new();
$vnt->title("Cambia fecha");
$vnt->geometry("280x250+2+2"); # Tama�o y ubicaci�n
my $ut = Utiles->crea($vnt);
my $esto = {};
$esto->{'baseDatos'} = $bd;
$esto->{'mensajes'} = $ut;

my %tp = $ut->tipos();
# Defime marcos
my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
	-label => 'Buscar Documento:');
my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
	-label => 'Datos obtemidos:');
my $mBtns = $vnt->Frame(-borderwidth => 1);
my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

# Barra de mensajes y bot�n de ayuda
my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{fx},
	-bg => '#F2FFE6', -fg => '#800000',);
$mnsj->pack(-side => 'left', -expand => 1, -fill => 'x');
$Mnsj = "Mensajes de error o advertencias.";

# Define botones
$bNvo = $mBtns->Button(-text => "Registra", -command => sub { &registra($esto)}); 
$bCan = $mBtns->Button(-text => "Termina", 
	-command => sub { &termina ($bd, $vnt) });

# Parametros
$mes = $mDatosC->LabEntry(-label => "Mes: ", -width => 3,
	-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
	-textvariable => \$Mes );
$de = $mDatosC->Radiobutton( -text => "Emitida", -value => 'Ventas', 
	-variable => \$Tabla );
$dr = $mDatosC->Radiobutton( -text => "Recibida", -value => 'Compras', 
	-variable => \$Tabla );
$fc = $mDatosC->Radiobutton( -text => "Factura", -value => 'F', 
	-variable => \$TipoD );
$nc = $mDatosC->Radiobutton( -text => "N.Cr�dito", -value => 'NC', 
	-variable => \$TipoD );
$nd = $mDatosC->Radiobutton( -text => "N.D�bito", -value => 'ND', 
	-variable => \$TipoD );
$ni = $mDatosC->LabEntry(-label => "N� I: ", -width => 5,
	-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
	-textvariable => \$Ni );

# Define campos para registro de datos de la empresa
$rut = $mDatos->LabEntry(-label => "RUT:  ", -width => 12,
	-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
	-textvariable => \$Rut, -state => 'disabled',
	-disabledbackground => '#FFFFFC', -disabledforeground => '#000000' );
$numD = $mDatos->LabEntry(-label => "# ", -width => 10,
	-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
	-textvariable => \$NumD, -state => 'disabled',
	-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
$numC = $mDatos->LabEntry(-label => "N� C ", -width => 6,
	-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
	-textvariable => \$NumC, -state => 'disabled',
	-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
$fechaC = $mDatos->LabEntry(-label => "Fecha: ", -width => 10,
	-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
	-textvariable => \$FechaC );

$ni->bind("<FocusOut>", sub { &buscaDoc($esto) } );

# Dibuja interfaz
$mes->grid(-row => 0, -column => 0, -sticky => 'nw');
$de->grid(-row => 0, -column => 1, -sticky => 'nw');
$dr->grid(-row => 0, -column => 2, -sticky => 'nw');
$fc->grid(-row => 1, -column => 0, -sticky => 'nw');
$nc->grid(-row => 1, -column => 1, -sticky => 'nw');
$nd->grid(-row => 1, -column => 2, -sticky => 'nw');
$ni->grid(-row => 2, -column => 1, -sticky => 'nw');

$rut->grid(-row => 0, -column => 0, -sticky => 'nw');
$numD->grid(-row => 0, -column => 1, -sticky => 'nw');
$numC->grid(-row => 1, -column => 0, -sticky => 'nw');
$fechaC->grid(-row => 1, -column => 1, -sticky => 'nw');

$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

$mDatosC->pack(-expand => 1);
$mDatos->pack(-expand => 1);	
$mBtns->pack(-expand => 1);
$mMensajes->pack(-expand => 1, -fill => 'both');

$mes->focus ;

# Ejecuta el programa
MainLoop;

# Funciones internas
sub validaFechaC ( $ $ )
{
	my ($ut, $bd) = @_;
	
	if ($FechaC eq '' ) {
		$Mnsj = "Anote la fecha de contabilizaci�n.";
		$fechaC->focus;
		return 0;
	}
	# Valida fecha contabilizaci�n
	if (not $FechaC =~ m|\d+/\d+/\d+|) {
		$Mnsj = "Problema con formato fecha";
		$fechaC->focus;
		return 0;
	} elsif ( not $ut->analizaFecha($FechaC) ) {
		$Mnsj = "Fecha incorrecta" ;
		$fechaC->focus ;
		return 0;
	}
	# Determina el n�mero de ingreso
	$MesC = substr $FechaC,3,2 ; # Extrae mes
	$MesC =~ s/^0// ; # Elimina '0' al inicio
	$Ni = $bd->numeroI($Tabla, $mes, $TipoD) + 1 ;
	
	return 1; 
}

sub registra ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'} ;
	my $ut = $esto->{'mensajes'} ;
	
	if ( validaFechaC($ut, $bd) ) {
		# Actualiza datos
		$bd->cambiaDcm($esto,$NumC,$FechaC,$Ni,$MesC,$Tabla,$Id,$TipoD);
		$Mnsj = "Registro actualizado";
	} 
	
}

sub buscaDoc ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'} ;
	my $ut = $esto->{'mensajes'} ;
	
	$TipoD .= substr $Tabla,0,1 if $TipoD eq 'F' ;
	my @datos = $bd->buscaNI($Tabla,$Mes,$Ni,$TipoD);
	if (not @datos) {
		$Mnsj = "NO existe documento con esos datos";
		$mes->focus;
		return ;
	}
	$Rut = $datos[0];
	$NumD = $datos[1];
	$NumC = $datos[2] ;
	my @dtsC = $bd->consultaC($NumC);
	$FechaC = $ut->cFecha($dtsC[2]);
	$Id = $datos[3] ;
}

sub termina ( $ $ )
{
	my ($bd, $vn ) = @_;

	$bd->cierra();
	$vn->destroy(); 
}

# Termina la ejecuci�n del programa
exit (0);