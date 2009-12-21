#!/usr/bin/perl -w

#  central.pl - inicio del programa Quipu [Sistema de Contabilidad]
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete  # use Data::Dumper ;
#  UM : 13.12.2009  

use prg::BaseDatos;
use strict;
use subs qw/opRegistra opContabiliza opConsulta opProcesa/;

use Tk ;
use Tk::BrowseEntry ;
use prg::Utiles ;
use Encode 'decode_utf8' ;

my $version = "central.pl 0.93 al 08/12/2009";
my $pv = sprintf("Perl %vd", $^V) ;

# Define variables básicas
my ($tipo,$Ayd,$Rut,$Empr,$bd, @cnf,$base,$multiE,$interE,$iva,$CBco,$lp,$lt);
my (@datosE,$BltsCV,$OtrosI,$Mnsj,@listaE,@unaE,$vnt,$Titulo,$CCts,$CPto,$TipoL);
$tipo = $Ayd = $Rut = $Empr = $Titulo = $TipoL = '';

# Datos de configuración
$bd = BaseDatos->crea('datosG.db3');
@cnf = $bd->leeCnf();
$base = "$cnf[0].db3" ;	# nombre del archivo de datos (corresponde al año)
$multiE = $cnf[3] ;  # habilita trabajar con varias empresas 
$interE = $cnf[2] ;	# habilita empresas interrelaciondas
$iva = $cnf[4] ;

# Crea la ventana principal
my $vp = MainWindow->new();
# Habilita acceso a rutinas utilitarias
my $ut = Utiles->crea($vp);

$version .= " con $pv, Tk $Tk::version y ";
$version .= "SQLite $bd->{'baseDatos'}->{sqlite_version} en $^O\n";
print "\nIniciando Quipu - Sistema de Contabilidad\n$version";

my @ayds = ( ['G','Una Ayuda Básica'], ['O','Las Funciones'],  
	['E','El Programa'], ['I','Forma de empezar'], ['L','Licencia'] ) ;
# Creación de la interfaz gráfica
my %tp = $ut->tipos();
# Define y prepara la tamaño y ubicación de la ventana
$vp->geometry("470x430+2+2");
$vp->resizable(1,1);
$vp->title("Quipu");

# Define marco para mostrar el Plan de Cuentas
my $mt = $vp->Scrolled('Text', -scrollbars=> 'e', -bg=> '#F2FFE6',
	-wrap => 'word');
$mt->tagConfigure('negrita', -font => $tp{ng}, -foreground => '#008080' ) ;
$mt->tagConfigure('grupo', -font => $tp{gr}, -foreground => 'brown') ;
$mt->tagConfigure('cuenta', -font => $tp{cn} ) ;
$mt->tagConfigure('detalle', -font => $tp{mn} ) ;
#print $mt->fontFamilies;

# Define marcos
my $marcoBM = $vp->Frame(-borderwidth => 2, -relief => 'raised'); # Menú
my $marcoAyd = $vp->Frame(-borderwidth => 1); # Ayuda
my $marcoT = $vp->Frame(-borderwidth => 1);  # Título  
                  
# Define botones de menú
my $mRegistro = $marcoBM->Menubutton(-text => "Registra", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -menuitems => opRegistra);
my $mContabiliza = $marcoBM->Menubutton(-text => "Contabiliza", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -menuitems => opContabiliza);
my $mConsulta = $marcoBM->Menubutton(-text => "Consulta", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -menuitems => opConsulta);
my $mMuestra = $marcoBM->Menubutton(-text => "Procesa",	-tearoff => 0, 
	-underline => 0, -indicatoron => 1, -menuitems => opProcesa );
my $bFin = $marcoBM->Button(-text => "Termina", -relief => 'ridge',
	-command => sub { $vp->destroy();  $bd->cierra(); } );

# Define opciones de ayuda
my $ayd = $marcoAyd->Label(	-text => "Ayudas: ");
my $opA = $marcoAyd->BrowseEntry( -variable => \$Ayd, -state => 'readonly',
		-disabledbackground => '#FFFFFC', -autolimitheight => 1,
		-disabledforeground => '#000000', -listwidth => 40,
		-width => 16, -browse2cmd => \&selecciona );
foreach my $algo ( @ayds ) {
		$opA->insert('end', $algo->[1] ) ;
}
my $lst = $marcoAyd->Label(	-text => "  Muestra: ");
$lt = $marcoAyd->Radiobutton( -text => "T ", -value => 'Terceros', 
		-variable => \$TipoL, -command => sub { &listados($TipoL) } );
$lp = $marcoAyd->Radiobutton( -text => "P", -value => 'Personal', 
		-variable => \$TipoL, -command => sub { &listados($TipoL) } );

my $aydPC = $marcoAyd->Button( -text => "P.Cuentas",
	 -command => sub { $Ayd = $TipoL = ''; $ut->muestraPC($mt,$bd,0,$Rut);});
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
$mt->pack(-fill => 'both');
$marcoAyd->pack(-fill => 'both');
# botones         
$mRegistro->pack(-side => 'left', -expand => 0, -fill => 'none');
$mContabiliza->pack(-side => 'left', -expand => 0, -fill => 'none');
$mConsulta->pack(-side => 'left', -expand => 0, -fill => 'none');
$mMuestra->pack(-side => 'left', -expand => 0, -fill => 'none');
$bFin->pack(-side => 'right');
# opciones de ayuda
$ayd->pack(-side => "left", -anchor => "e");
$opA->pack(-side => "left", -anchor => "e");
$lst->pack(-side => "left", -anchor => "e");
$lt->pack(-side => "left", -anchor => "e");
$lp->pack(-side => "left", -anchor => "e");
$aydPC->pack(-side => "right", -anchor => "e");

if ( not $multiE ) {
	@unaE = $bd->datosE();
	$Rut = $unaE[1];
	$Empr = decode_utf8($unaE[0]) ;
	$Titulo = decode_utf8($unaE[0]) . " - $cnf[0]" ;
	activaE();
} else {
	$mRegistro->configure(-state => 'disabled');
	$mContabiliza->configure(-state => 'disabled');
	$mConsulta->configure(-state => 'disabled');
	$mMuestra->configure(-state => 'disabled');
	$aydPC->configure(-state => 'disabled');
	$ut->ayuda($mt,'M');
}

# Ejecuta el programa
MainLoop;

# Subrutinas que definen el contenido de los menues
sub opRegistra {

[['command' => "Terceros", -command => sub { require prg::DatosT;
	DatosT->crea($vp, $bd, $ut, '', $mt); } ],
 ['command' => "Personal", -command => sub { require prg::DatosP; 
	DatosP->crea($vp, $bd, $ut, $mt, $CCts ); } ], "-", 
 ['cascade' => "Plan Cuentas", -tearoff => 0, -menuitems => opCuentas() ],
 ['command' => "Documentos", -command => sub { require prg::TipoD;
	TipoD->crea($vp, $bd, $ut, $mt); } ], "-", 
 ['cascade' => "Ajustes", -tearoff => 0, -menuitems => opAjustes() ] ]
}

sub opAjustes {
[ ['command' => "F - NC - ND", -command => sub { require prg::Ajustes; 
 	Ajustes->crea($vp, $bd, $ut, $mt ); } ],
 ['command' => "BH", -command => sub { require prg::AjustaBH; 
 	AjustaBH->crea($vp, $bd, $ut, $mt ); } ],
 ['command' => "Asigna NC", -command => sub { require prg::AsignaNC; 
 	AsignaNC->crea($vp, $bd, $ut, $mt ); } ]]
}
 
sub opContabiliza {
 my ($tipoC, $tipoB, $tipoNC, $tipoND, $tipoA );
 $tipoC = $tipoB = $tipoNC = $tipoND = $tipoA = ' ';

[['cascade' => "Ventas", -tearoff => 0, -menuitems => opVentas() ],
 ['cascade' => "Compras", -tearoff => 0, -menuitems => opCompras() ],
 ['command' => "Honorarios",	-command => sub { require prg::BltsH;
	BltsH->crea($vp, $bd, $ut, $mt, $CCts) },],
 ['cascade' => "N. Crédito", -tearoff => 0,
 	-menuitems => [ map [ 'radiobutton', $_, -variable => \$tipoNC ,  
	-command => sub { require prg::NtsC;
	NtsC->crea($vp,$bd,$ut,$tipoNC,$mt,$CCts,$iva);} ], qw/Emitida Recibida/,],] ,
 ['cascade' => "N. Débito", -tearoff => 0,
 	-menuitems => [ map [ 'radiobutton', $_, -variable => \$tipoND ,  
	-command => sub { require prg::NtsD;
	NtsD->crea($vp,$bd,$ut,$tipoND,$mt,$CCts,$iva);} ], qw/Emitida Recibida/,],] , "-",
['cascade' => "Comprobante", -tearoff => 0,
 	-menuitems => [ map [ 'radiobutton', $_, -variable => \$tipoC ,
	-command => sub { require prg::Cmprbs; Cmprbs->crea($vp,$bd,$ut,$tipoC,$mt,$CCts,$Empr);}],
		 qw/Ingreso Egreso Traspaso/,], ], "-",
['command' => "Anula", -command => sub { require prg::AnulaC; 
	AnulaC->crea($vp, $mt, $bd, $ut);} ] ]
}

sub opVentas {
[['command' => "F. Emitidas", -command => sub { require prg::Fctrs; 
	Fctrs->crea($vp,$bd,$ut,'Ventas',$mt,$CCts,$iva,0);} ], 
 ['command' => "FC Recibidas", -command => sub { require prg::Fctrs;
 	Fctrs->crea($vp,$bd,$ut,'Ventas',$mt,$CCts,$iva,1);} ] ]
}

sub opCompras {
[['command' => "F. Recibidas", -command => sub { require prg::Fctrs; 
	Fctrs->crea($vp,$bd,$ut,'Compras',$mt,$CCts,$iva,0); } ],
 ['command' => "F. Especiales", -command => sub { require prg::FcmpE; 
	FcmpE->crea($vp,$bd,$ut, $mt, $CCts, $iva) } ], 
 ['command' => "FT Emitidas", -command => sub { require prg::Fctrs;
 	Fctrs->crea($vp,$bd,$ut,'Compras',$mt,$CCts,$iva,1);} ] ]
}

sub opConsulta {
my $tipoD = $tipo = '';
[ ['command' => "Balance inicial", -command => sub { require prg::BalanceI;
	BalanceI->crea($vp, $mt, $bd, $ut, $Rut);} ],
  ['command' => "Balance al día", -command => sub { require prg::Balance;
	Balance->crea($vp, $mt, $bd, $ut, $Rut);} ], "-",
 ['command' => "Cuenta Individual", -command => sub { require prg::CIndvdl;
	CIndvdl->crea($vp, $mt, $bd, $ut, $Rut);} ],  
 ['cascade' => "-Impagos", -tearoff => 0,
 	-menuitems => [ map [ 'radiobutton', $_, -variable => \$tipo , 
	-command => sub { require prg::Impgs; Impgs->crea($vp,$mt,$bd,$ut,$tipo);} ], 
	qw/Clientes Proveedores/,], ] , "-", 
 ['command' => "Comprobantes", -command => sub { require prg::CCmprb;
	CCmprb->crea($vp, $mt, $bd, $ut, $Rut);} ],
 ['cascade' => "Documentos", -tearoff => 0,
 	-menuitems => [ map [ 'radiobutton', $_, -variable => \$tipoD ,  
	-command => sub { require prg::CDcmts; CDcmts->crea($vp,$mt,$bd,$ut,$tipoD);}], 
	qw/Recibidos Emitidos/,],] ]
}

sub opProcesa {
[['cascade' => "Balances",-tearoff => 0, -menuitems => opBalances() ],
 ['cascade' => "Resultados",-tearoff => 0, -menuitems => opResultados() ],"-",
 ['command' => "Libro Diario", -command => sub { require prg::Diario;
	Diario->crea($vp, $mt, $bd, $ut, $Rut);} ], 
 ['cascade' => "Libro Mayor", -tearoff => 0, -menuitems => opLMayor() ], "-",
 ['command' => "Libro Ventas", -command => sub { require prg::Ventas;
	Ventas->crea($vp, $mt, $bd, $ut, $Rut);} ],
 ['command' => "Libro Compras",	-command => sub { require prg::Compras;
	Compras->crea($vp, $mt, $bd, $ut, $Rut);} ],
 ['command' => "Libro Honorarios",	-command => sub { require prg::Honorarios;
	Honorarios->crea($vp, $mt, $bd, $ut, $Rut);} ],"-",
 ['cascade' => "Listados", -tearoff => 0, -menuitems => opListados() ] ]
}

sub opLMayor {
[['command' => "por mes", -command => sub { require prg::Mayor;
	Mayor->crea($vp, $mt, $bd, $ut, $Rut);} ],
['command' => "entre fechas", -command => sub { require prg::MayorF;
	MayorF->crea($vp, $mt, $bd, $ut, $Rut);} ] ]
}

sub opBalances {
[['command' => "Mensuales", -command => sub { require prg::CierreM;
	CierreM->crea($vp, $mt, $bd, $ut, $Rut);} ], 
 ['command' => "Clasificado", -command => sub { require prg::Trcrs;
 	Trcrs->crea($vp, $mt, $bd, $ut);} ],
 ['command' => "-Otros", -command => sub { require prg::Prsnl;
 	Prsnl->crea($vp, $mt, $bd, $ut);} ] ]
}

sub opResultados {
[['command' => "Mensuales", -command => sub { require prg::Rsltds;
	Rsltds->crea($vp, $mt, $bd, $ut, $Rut);} ], 
 ['command' => "por Centros de Costos", -command => sub { require prg::CCCsts;
 	CCCsts->crea($vp, $mt, $bd, $ut, $Rut);} ] ]
}

sub opListados {
[['command' => "Plan de Cuentas", -command => sub { require prg::PlanC;
	PlanC->crea($vp, $mt, $bd, $ut, $Rut);} ], 
 ['command' => "-Terceros", -command => sub { require prg::Trcrs;
 	Trcrs->crea($vp, $mt, $bd, $ut);} ],
 ['command' => "-Personal", -command => sub { require prg::Prsnl;
 	Prsnl->crea($vp, $mt, $bd, $ut);} ] ]
}

sub opCierre {
[['command' => "Provisorio", -command => sub { require prg::CierreA;
 	CierreA->crea($vp, $mt, $bd, $ut, $Rut,0);} ],
 ['command' => "Final", -command => sub { require prg::CierreA;
 	CierreA->crea($vp, $mt, $bd, $ut, $Rut,1);} ] ]
}

sub opCuentas {
	[['command' => "SubGrupos", -command => sub { require prg::SGrupos; 
		SGrupos->crea($vp, $bd, $ut, $mt);} ], 
	 ['command' => "Cuentas", -command => sub { require prg::CuentasM;
		CuentasM->crea($vp, $mt, $bd, $ut);} ]  ]
}

sub opAnula {
my $tipoA = '' ;
[['command' => "Comprobante", -command => sub { require prg::AnulaC; 
	AnulaC->crea($vp, $mt, $bd, $ut);} ],
 ['cascade' => "Documento", -tearoff => 0,
 	-menuitems => [ map [ 'radiobutton', $_, -variable => \$tipoA , 
	-command => sub { require prg::AnulaD; 
	  AnulaD->crea($vp, $bd, $ut, $tipoA);} ], qw/Clientes Proveedores Honorarios/,] ] ]
}

sub Empresa
{
	my ($algo, $mnsj, $img, $bAyd, $bCan);
	# Define ventana
	$vnt = $vp->Toplevel();
	$vnt->title("Selecciona Empresa");
	$vnt->geometry("360x60+475+4"); # Tamaño y ubicación

	my $mDatos = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	my $emprsT = $mDatos->Label(-text => " Empresa ");
	require Tk::BrowseEntry ;
	my $emprs = $mDatos->BrowseEntry( -variable => \$Empr, -state => 'readonly',
		-disabledbackground => '#FFFFFC', -autolimitheight => 1,
		-disabledforeground => '#000000', -autolistwidth => 1,
		-browse2cmd => \&elige );
	# Crea opciones para seleccionar empresa
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
	$Titulo = "$Empr - $cnf[0]";
	activaE();
	$vnt->destroy();
}

sub activaE {

	$bd->cierra();
	$bd = BaseDatos->crea("$Rut/$base");
	$bd->anexaBD();
	datosBase() ;
	# Agrega más opciones de menu, según la configuración
	if ($CCts) { 
		$mRegistro->AddItems("-", ['command' => "Centros de Costos",
		-command => sub { use prg::RCCsts; RCCsts->crea($vp,$mt,$bd,$ut);}] );
	}
	if ($OtrosI) {
		
	}
	# Esto es para que siempre quede al final
	$mMuestra->AddItems("-", ['cascade' => "Cierre", -tearoff => 0, 
		-menuitems => opCierre() ] );
	if ($BltsCV) {
		$mRegistro->AddItems("-", ['command' => "Resumen BCV",
		-command => sub { use prg::RBltsCV; RBltsCV->crea($vp,$bd,$ut,$mt);}] );
		$mConsulta->AddItems( ['command' => "Resumen BCV",
		-command => sub { use prg::CBltsCV; CBltsCV->crea($vp,$mt,$bd,$ut);}] );
	}
	if ($CBco) { 
		$mRegistro->command( -label => "Bancos", -command => sub { require prg::Bancos;
		Bancos->crea($vp, $mt, $bd, $ut);} ) ;
		$mRegistro->command( -label => "Conciliación Banco",
		-command => sub { use prg::RBanco; RBanco->crea($vp,$mt,$bd,$ut);} );
	}
	$mRegistro->configure(-state => 'active');
	$mContabiliza->configure(-state => 'active');
	$mConsulta->configure(-state => 'active');
	$mMuestra->configure(-state => 'active');
	$aydPC->configure(-state => 'active');

	# Muestra información inicial: si faltan datos, deshabilita menues
	if (not $cnf[1] ) {
		$mContabiliza->configure(-state => 'disabled');
		$ut->muestraPC($mt,$bd,0, $Rut);
	}
	if (not $datosE[10] ) {
		$mt->insert('end', "\nATENCION\n", 'negrita' ) ;
		$mt->insert('end', "\n Falta completar datos de la empresa.\n", 
			'grupo' ) ;
		$mConsulta->configure(-state => 'disabled');
		$mMuestra->configure(-state => 'disabled');
	} 
	$ut->ayuda($mt,'G') if $datosE[10] and $cnf[1] ;
}

sub datosBase {

	$OtrosI = $BltsCV = $CBco = $CCts = $CPto = 0;
	@datosE = $bd->datosEmpresa($Rut);
	if (@datosE) {
		$OtrosI = $datosE[5]; # registra otros impuestos: ILAs, Especial
		$BltsCV = $datosE[6]; # utiliza boletas de compraventa 
		$CBco = $datosE[7]; # Bancos como subcuentas
		$CCts = $datosE[8]; # usa centros de costos
		$CPto = $datosE[9];
	}
}

sub selecciona {
	
	my ($jc, $Index) = @_;
	$Ayd = $ayds[$Index]->[1];
	$ut->ayuda($mt, $ayds[$Index]->[0]);
}

sub listados ( $ )
{
	my ($lstd) = @_ ;
	
	my ($algo, $nm, @data);
	$Ayd = '';
	if ($lstd eq 'Terceros' ) {
		@data = $bd->datosT();
	} else {
		@data = $bd->datosP();
	}
	$mt->delete('0.0','end');
	$mt->insert('end',"$lstd\n\n", 'grupo');
	foreach $algo ( @data ) {
		$nm = sprintf("%10s  %-35s", $algo->[0], decode_utf8($algo->[1])) ;
		$mt->insert('end', "$nm\n") ;
	}
}

# Termina la ejecución del programa
exit (0);
