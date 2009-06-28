#!/usr/bin/perl -w

#  ajustes.pl - Cambia fecha de contabilizacion o número de un documento
#  (cambios que no afectan las cuentas de mayor o las individuales)
#  Forma parte del programa Quipu
#
#  Derechos de Autor (c) Víctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete 
#  UM: 24.06.2009

use prg::BaseDatos;
use Tk;
use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';

use prg::Utiles;

my ($Rut,$Mnsj,$FechaC,$NumD,$Ni,$Tabla,$TipoD,$Mes,$MesC,$NumC,$Id,$TA,$TpD); # Variables
my ($mes,$de,$dr,$fc,$nd,$nc,$ni,$rut,$numD,$fechaC,$numC,$cn,$cf,$tp ); # Campos
my ($bCan, $bNvo) ; # Botones

# Datos de configuración
my $bd = BaseDatos->crea('datosG.db3');
@cnf = $bd->leeCnf();
$base = "$cnf[0].db3" ;	# nombre del archivo de datos (corresponde al año)
@unaE = $bd->datosE();
my $RutE = $unaE[1];
$bd->cierra();
$bd = BaseDatos->crea("$RutE/$base");

# Define ventana
my $vnt = MainWindow->new();
$vnt->title("Ajustes");
$vnt->geometry("280x310+2+2"); # Tamaño y ubicación
my $ut = Utiles->crea($vnt);
my $esto = {};
$esto->{'baseDatos'} = $bd;
$esto->{'mensajes'} = $ut;

my %tp = $ut->tipos();
# Defime marcos
my $mTipoA = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
	-label => 'Seleccione Ajuste:');
my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
	-label => 'Buscar Documento:');
my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
	-label => 'Datos registrados:');
my $mBtns = $vnt->Frame(-borderwidth => 1);
my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

# Barra de mensajes y botón de ayuda
my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{fx},
	-bg => '#F2FFE6', -fg => '#800000',);
$mnsj->pack(-side => 'left', -expand => 1, -fill => 'x');
$Mnsj = "Mensajes de error o advertencias.";

# Define botones
$bNvo = $mBtns->Button(-text => "Registra", -command => sub { &registra($esto)}); 
$bCan = $mBtns->Button(-text => "Termina", 
	-command => sub { &termina ($bd, $vnt) });

# Parametros
$cn = $mTipoA->Radiobutton( -text => "Número", -value => 'N', 
	-variable => \$TA , -command => sub { &activa() });
$cf = $mTipoA ->Radiobutton( -text => "Fecha", -value => 'F', 
	-variable => \$TA, -command => sub { &activa() } );
$tp = $mTipoA->Radiobutton( -text => "Tipo", -value => 'T', 
	-variable => \$TA , -command => sub { &activa() });
$mes = $mDatosC->LabEntry(-label => "Mes: ", -width => 3,
	-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
	-textvariable => \$Mes );
$de = $mDatosC->Radiobutton( -text => "Emitida", -value => 'Ventas', 
	-variable => \$Tabla );
$dr = $mDatosC->Radiobutton( -text => "Recibida", -value => 'Compras', 
	-variable => \$Tabla );
$fc = $mDatosC->Radiobutton( -text => "Factura", -value => 'F', 
	-variable => \$TipoD );
$nc = $mDatosC->Radiobutton( -text => "N.Crédito", -value => 'NC', 
	-variable => \$TipoD );
$nd = $mDatosC->Radiobutton( -text => "N.Débito", -value => 'ND', 
	-variable => \$TipoD );
$ni = $mDatosC->LabEntry(-label => "Nº I: ", -width => 5,
	-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
	-textvariable => \$Ni );

# Define campos para registro de datos de la empresa
$rut = $mDatos->LabEntry(-label => "RUT:  ", -width => 12,
	-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
	-textvariable => \$Rut, -state => 'disabled',
	-disabledbackground => '#FFFFFC', -disabledforeground => '#000000' );
$numD = $mDatos->LabEntry(-label => "Doc. # ", -width => 10,
	-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
	-textvariable => \$NumD, -disabledbackground => '#FFFFFC', 
	-disabledforeground => '#000000'  );
$numC = $mDatos->LabEntry(-label => "Nº C ", -width => 6,
	-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
	-textvariable => \$NumC, -state => 'disabled',
	-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
$fechaC = $mDatos->LabEntry(-label => "Fecha: ", -width => 10,
	-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
	-textvariable => \$FechaC, -disabledbackground => '#FFFFFC', 
	-disabledforeground => '#000000' );
$tipoD = $mDatos->LabEntry(-label => "M o E: ", -width => 3,
	-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
	-textvariable => \$TpD, -disabledbackground => '#FFFFFC', 
	-disabledforeground => '#000000' );

$ni->bind("<FocusOut>", sub { &buscaDoc($esto) } );

# Dibuja interfaz
$cn->grid(-row => 0, -column => 0, -sticky => 'nw');
$cf->grid(-row => 0, -column => 1, -sticky => 'nw');
$tp->grid(-row => 0, -column => 2, -sticky => 'nw');
$mes->grid(-row => 0, -column => 0, -sticky => 'nw');
$de->grid(-row => 0, -column => 1, -sticky => 'nw');
$dr->grid(-row => 0, -column => 2, -sticky => 'nw');
$fc->grid(-row => 1, -column => 0, -sticky => 'nw');
$nc->grid(-row => 1, -column => 1, -sticky => 'nw');
$nd->grid(-row => 1, -column => 2, -sticky => 'nw');
$ni->grid(-row => 2, -column => 2, -sticky => 'nw');

$rut->grid(-row => 0, -column => 0, -sticky => 'nw');
$numD->grid(-row => 0, -column => 1, -sticky => 'nw');
$numC->grid(-row => 1, -column => 0, -sticky => 'nw');
$fechaC->grid(-row => 1, -column => 1, -sticky => 'nw');
$tipoD->grid(-row => 2, -column => 1, -sticky => 'nw') ;

$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

$mMensajes->pack(-expand => 1, -fill => 'both');
$mTipoA->pack(-expand => 1);
$mDatosC->pack(-expand => 1);
$mDatos->pack(-expand => 1);	
$mBtns->pack(-expand => 1);

$ni->configure(-state => 'disable');
$numD->configure(-state => 'disable');
$mes->configure(-state => 'disable');
$fechaC->configure(-state => 'disable');
$tipoD->configure(-state => 'disable');

$cn->focus ;

# Ejecuta el programa
MainLoop;

# Funciones internas
sub validaFechaC ( $ $ )
{
	my ($ut, $bd) = @_;
	
	if ($FechaC eq '' ) {
		$Mnsj = "Anote la fecha de contabilización.";
		$fechaC->focus;
		return 0;
	}
	# Valida fecha contabilización
	if (not $FechaC =~ m|\d+/\d+/\d+|) {
		$Mnsj = "Problema con formato fecha";
		$fechaC->focus;
		return 0;
	} elsif ( not $ut->analizaFecha($FechaC) ) {
		$Mnsj = "Fecha incorrecta" ;
		$fechaC->focus ;
		return 0;
	}
	# Determina el número de ingreso
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
		$bd->cambiaDcm($esto,$NumC,$FechaC,$TpD,$NumD,$Ni,$MesC,$Tabla,$Id,$TipoD);
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
	$Rut =  $datos[0];
	$NumD = $datos[1];
	$NumC = $datos[2];
	$TpD =  $datos[3];
	$Id  =  $datos[4];
	my @dtsC = $bd->consultaC($NumC);
	$FechaC = $ut->cFecha($dtsC[2]);
}

sub activa ( ) 
{
	$mes->configure(-state => 'normal');
	$ni->configure(-state => 'normal');
	if ( $TA eq 'F') {
		$numD->configure(-state => 'disable');
		$fechaC->configure(-state => 'normal');
		$tipoD->configure(-state => 'disable');
	} elsif ($TA eq 'N') {
		$numD->configure(-state => 'normal');
		$fechaC->configure(-state => 'disable');
		$tipoD->configure(-state => 'disable');
	} else {
		$numD->configure(-state => 'disable');
		$fechaC->configure(-state => 'disable');
		$tipoD->configure(-state => 'normal');
	}
}

sub termina ( $ $ )
{
	my ($bd, $vn ) = @_;

	$bd->cierra();
	$vn->destroy(); 
}

# Termina la ejecución del programa
exit (0);
