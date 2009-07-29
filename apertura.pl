#!/usr/bin/perl -w

#  apertura.pl - registra saldos y documentos de la primera apertura 
#  Forma parte del programa Quipu
#
#  Derechos de Autor (c) Víctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete 
#  UM: 06.07.2009

use prg::BaseDatos;
use strict;
use subs qw/opSaldos opDocs/;
use Tk;
use Tk::BrowseEntry ;
use prg::Utiles;
use Encode 'decode_utf8';

# Define variables básicas
my ($tipo,$Rut,$Empr,$bd,@cnf,$base,$multiE,$interE,$Titulo);
my (@datosE,$Mnsj,@listaE,@unaE,$vnt);
$tipo = $Rut = $Empr = $Titulo = '';

# Datos de configuración
$bd = BaseDatos->crea('datosG.db3');
@cnf = $bd->leeCnf();
$base = "$cnf[0].db3" ;	# nombre del archivo de datos (corresponde al año)
$multiE = $cnf[3] ;  # habilita trabajar con varias empresas 

# Crea la ventana principal
my $vp = MainWindow->new();

# Habilita acceso a rutinas utilitarias
my $ut = Utiles->crea($vp);
my %tp = $ut->tipos();

# Creación de la interfaz gráfica
# Define y prepara la tamaño y ubicación de la ventana
$vp->geometry("320x60+1+1");
$vp->resizable(1,1);
$vp->title("Apertura");

# Define marcos
my $marcoBM = $vp->Frame(-borderwidth => 2, -relief => 'raised'); # Menú
my $marcoT = $vp->Frame(-borderwidth => 1);  # Título  
                  
# Define botones de menú
my $mSaldos = $marcoBM->Menubutton(-text => "Saldos", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -menuitems => opSaldos);
my $mDocs = $marcoBM->Menubutton(-text => "Documentos", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -menuitems => opDocs);
my $bFin = $marcoBM->Button(-text => "Termina", -relief => 'ridge',
	-command => sub { $vp->destroy();  $bd->cierra(); } );

# Contenido título
my $cEmpr = $marcoT->Label(-textvariable => \$Titulo, -bg => '#FEFFE6', 
		-fg => '#800000',);
$cEmpr->pack(-side => 'left', -expand => 1, -fill => 'x');
if ($multiE) {
	my $e = $vp->Photo(-file => "e.gif") ;
	my $bSlc = $marcoT->Button(-image => $e, -command => sub { Empresa(); } ); 
	$bSlc->pack(-side => 'right', -expand => 0, -fill => 'none');
}

# Dibuja la interfaz gráfica
# marcos
$marcoT->pack(-side => 'top', -expand => 0, -fill => 'both');
$marcoBM->pack(-side => 'top', -expand => 0, -fill => 'both');

# botones         
$mSaldos->pack(-side => 'left', -expand => 0, -fill => 'none');
$mDocs->pack(-side => 'left', -expand => 0, -fill => 'none');
$bFin->pack(-side => 'right');

if ( not $multiE ) {
	@unaE = $bd->datosE();
	$Rut = $unaE[1];
	$Titulo = decode_utf8($unaE[0]) . " - $cnf[0]" ;
	activaE();
} else {
	$mSaldos->configure(-state => 'disabled');
	$mDocs->configure(-state => 'disabled');
}

# Ejecuta el programa
MainLoop;

# Subrutinas que definen el contenido de los menues
sub opSaldos {
[['command' => "Mayor", -command => sub { use aprt::SMayor;
		SMayor->crea($bd, $ut); } ],
 ['command' => "Individuales", -command => sub { use aprt::SIndvdl;
		SIndvdl->crea($bd, $ut);} ] ]
}

sub opDocs {
 [ ['command' => "F. Ventas", -command => sub { use aprt::Fctrs;
 	Fctrs->crea($bd, $ut,'FV') },],
 ['command' => "F. Compras", -command => sub { use aprt::Fctrs;
 	Fctrs->crea($bd, $ut,'FC') },],
 ['command' => "B. Honorarios",	-command => sub { use aprt::BltsH;
	BltsH->crea($bd, $ut) },],
['command' => "Letras",	-command => sub { use aprt::Ltrs;
	Ltrs->crea($bd, $ut, 'LT') },] ,
['command' => "Cheques", -command => sub { use aprt::Ltrs;
	Ltrs->crea($bd, $ut,'CH') },]   ]	
}

sub elige 
{
	my ($jc, $Index) = @_;
	$Rut = $listaE[$Index]->[0];
	$Titulo = "$Empr - $cnf[0]";
	activaE();
	$vnt->destroy();
}

sub activaE 
{
	$bd->cierra();
	$bd = BaseDatos->crea("$Rut/$base");
	$bd->anexaBD();

	$mSaldos->configure(-state => 'active');
	$mDocs->configure(-state => 'active');
}

sub Empresa
{
	my ($algo,$mnsj,$img,$bAyd,$bCan);
	# Define ventana
	$vnt = $vp->Toplevel();
	$vnt->title("Selecciona Empresa");
	$vnt->geometry("320x60+2+115"); # Tamaño y ubicación

	my $mDatos = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove');
	$Empr = '' ;
	my $emprsT = $mDatos->Label(-text => " Empresa ");
	my $emprs = $mDatos->BrowseEntry( -variable => \$Empr, -state => 'readonly',
		-disabledbackground => '#FFFFFC', -autolimitheight => 1,
		-disabledforeground => '#000000', -autolistwidth => 1,
		-browse2cmd => \&elige );
	# Crea opciones del combobox
	@listaE = $bd->listaEmpresas();
	foreach $algo ( @listaE ) {
		$emprs->insert('end', decode_utf8($algo->[1]) ) ;
	}

	$bCan = $mDatos->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy();} );
	# Barra de mensajes y botón de ayuda
	$mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'left', -expand => 1, -fill => 'x');
	$Mnsj = "Mensajes de error o advertencias.";

	# Dibuja interfaz
	$emprsT->pack(-side => "left", -anchor => "nw");
	$emprs->pack(-side => "left", -anchor => "nw");
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mDatos->pack();
	$mMensajes->pack(-expand => 1, -fill => 'both');
	
	$Mnsj = "NO hay empresa registradas" if not @listaE ;
}

# Termina la ejecución del programa
exit (0);
