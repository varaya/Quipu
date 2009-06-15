#!/usr/bin/perl -w

#  apertura.pl - registra saldos de la apertura inicial y los documento
#  Propiedad intelectual Víctor Araya R., 2008 [varayar@gmail.com]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete
# [ á é í ó ú ^]

if (defined $ARGV[0]) { print "\nVersión en red, pendiente.\n\n"; exit ;
  } else { use prg::BaseDatos; }
use strict;
use subs qw/opSaldos opDocs/;
use Tk;
use Tk::BrowseEntry ;
use prg::Utiles;
use Encode 'decode_utf8';

# Define variables básicas
my ($tipo,$Rut,$Empr,$bd,@cnf,$base,$multiE,$interE);
my (@datosE,$Mnsj,@listaE,@unaE,$vnt);
$tipo = $Rut = $Empr = '';

# Datos de configuración
$bd = BaseDatos->crea('datosG.db3');
@cnf = $bd->leeCnf();
$base = "$cnf[0].db3" ;	# nombre del archivo de datos (corresponde al año)
$multiE = $cnf[3] ;  # habilita trabajar con varias empresas 

# Crea la ventana principal
my $vp = MainWindow->new();

# Habilita acceso a rutinas utilitarias
my $ut = Utiles->crea($vp);

# Creación de la interfaz gráfica
# Define y prepara la tamaño y ubicación de la ventana
$vp->geometry("410x350+2+2");
$vp->resizable(1,1);
$vp->title("Quipu");

# Define marco para mostrar el Plan de Cuentas
my $mt = $vp->Scrolled('Text', -scrollbars=> 'e', -bg=> '#F2FFE6',
	-wrap => 'word');
$mt->tagConfigure('negrita', -font => "Arial 12 bold") ;
$mt->tagConfigure('grupo', -font => "Arial 10 bold", -foreground => 'brown') ;
$mt->tagConfigure('cuenta', -font => "Arial 10") ;
$mt->tagConfigure('detalle', -font => "fixed") ;

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
my $cEmpr = $marcoT->Label(-textvariable => \$Empr, -bg => '#FEFFE6', 
		-fg => '#800000');
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
$mt->pack(-fill => 'both');
# botones         
$mSaldos->pack(-side => 'left', -expand => 0, -fill => 'none');
$mDocs->pack(-side => 'left', -expand => 0, -fill => 'none');
$bFin->pack(-side => 'right');

if ( not $multiE ) {
	@unaE = $bd->datosE();
	$Rut = $unaE[1];
	$Empr = decode_utf8($unaE[0]) ;
	activaE();
} else {
	$mSaldos->configure(-state => 'disabled');
	$mDocs->configure(-state => 'disabled');
	$ut->ayuda($mt,'A');
}

# Ejecuta el programa
MainLoop;

# Subrutinas que definen el contenido de los menues
sub opSaldos {

[['command' => "Mayor", -command => sub { use aprt::SMayor;
		SMayor->crea($vp, $bd, $ut, $mt); } ],
 ['command' => "Individuales", -command => sub { use aprt::SIndvdl;
		SIndvdl->crea($vp, $bd, $ut, '', $mt);} ] ]
}

sub opDocs {
 [ ['command' => "F. Ventas", -command => sub { use aprt::FVentas;
 	FVentas->crea($vp, $bd, $ut, $mt) },],
 ['command' => "F. Compras", -command => sub { use aprt::FCompras;
 	FCompras->crea($vp, $bd, $ut, $mt) },],
 ['command' => "B. Honorarios",	-command => sub { use aprt::BltsH;
	BltsH->crea($vp, $bd, $ut, $mt) },]  ]
	
}

sub Empresa
{
	my ($algo,$mnsj,$img,$bAyd,$bCan);
	# Define ventana
	$vnt = $vp->Toplevel();
	$vnt->title("Selecciona Empresa");
	$vnt->geometry("360x60+435+40"); # Tamaño y ubicación

	my $mDatos = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );
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
	$mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => 'fixed',
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'left', -expand => 1, -fill => 'x');
	$img = $vnt->Photo(-file => "info.gif") ;
	$bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Compras'); } ); 
	$bAyd->pack(-side => 'right', -expand => 0, -fill => 'none');
	$Mnsj = "Mensajes de error o advertencias.";

	# Dibuja interfaz
	$emprsT->pack(-side => "left", -anchor => "nw");
	$emprs->pack(-side => "left", -anchor => "nw");
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mDatos->pack();
	$mMensajes->pack(-expand => 1, -fill => 'both');
	
	$Mnsj = "NO hay empresa registradas" if not @listaE ;

}

sub elige {

	my ($jc, $Index) = @_;
	$Rut = $listaE[$Index]->[0];
	$Empr .= " - Apertura";
	activaE();
	$vnt->destroy();
}

sub activaE {

	$bd->cierra();
	$bd = BaseDatos->crea("$Rut/$base");
	$bd->anexaBD();
	$mSaldos->configure(-state => 'active');
	$mDocs->configure(-state => 'active');

	# Muestra información inicial: si faltan datos, deshabilita menues
	if (not $cnf[1] ) {
		$mSaldos->configure(-state => 'disabled');
		$ut->muestraPC($mt,$bd,0, $Rut);
	}
	$ut->ayuda($mt,'G') if $datosE[7] and $cnf[1] ;
}

# Termina la ejecución del programa
exit (0);
