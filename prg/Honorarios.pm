#  Honorarios.pm - Consulta e imprime Libro de Honorarios
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM : 19.06.2009 

package Honorarios;

use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
my ($Mnsj, $mes, $nMes, @cnf, $empr, $rutE) ;	# Variables
my ($Tt,$Iva,$Aft,$Ext,$IEsp);
my @lMeses = () ;
my @datos = ();
my ($bCan, $bImp) ; # Botones
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	$FechaI = $ut->fechaHoy();
	@cnf = $bd->leeCnf();
	$nMes = '' ;
	$rutE = $rtE ;
	
	# Define ventanas
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Libro Honorarios");
	$vnt->geometry("780x450+40+150"); 
	# Define marco para mostrar resultado
	my $mtA = $vnt->Scrolled('Text', -scrollbars=> 'se', -bg=> 'white', -height=> 420 );
	$mtA->tagConfigure('negrita', -font => $tp{ng}) ;
	$mtA->tagConfigure('detalle', -font => $tp{fx}) ;

	# Define marcos
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Define campo para seleccionar mes
	my $tMes = $mBotonesC->Label(-text => "Seleccione mes ") ;
	my $meses = $mBotonesC->BrowseEntry(-variable => \$nMes, -state => 'readonly',
		-disabledbackground => '#FFFFFC', -autolimitheight => 1,
		-disabledforeground => '#000000', -autolistwidth => 1,
		-browse2cmd => \&selecciona );
	# Crea listado de meses
	@lMeses = $ut->meses();
	my $algo;
	foreach $algo ( @lMeses ) {
		$meses->insert('end', $algo->[1] ) ;
	}
	$meses->delete(12,12); #Elimina el 'Todos' al final

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Compras'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
		
	# Define botones
	$bMst = $mBotonesC->Button(-text => "Muestra", 
		-command => sub { &valida($esto, $mtA) } );
	$bImp = $mBotonesC->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mtA);} ],
 	  ['command' => "planilla", -command => sub { csv($esto);} ] ] );
	$bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy();} );
	
	# Dibuja interfaz
	$mMensajes->pack(-expand => 1, -fill => 'both');
	$tMes->pack(-side => "left", -anchor => "w");
	$meses->pack(-side => "left", -anchor => "w");
	$bMst->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mBotonesC->pack();
	$mtA->pack(-fill => 'both');

	$bImp->configure(-state => 'disabled');
	$mt->delete('0.0','end');

	bless $esto;
	return $esto;
}

# Funciones internas
sub selecciona {
	my ($jc, $Index) = @_;
	$mes = $lMeses[$Index]->[0];
}

sub valida ( $ ) 
{
	my ($esto,$mt) = @_;
	my ($fi, $ff, $mnsj);
	
	$Mnsj = " ";
	if (not $mes) {
		$Mnsj = "Debe seleccionar un mes."; 
		return;
	} else {
		informe($esto,$mt);
	}
}

sub informe ( $ $ ) {

	my ($esto, $marco) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	my $nf = $bd->cuentaDcm('BoletasH',$mes);
	$marco->delete('0.0','end');
	$Mnsj = " ";
	if (not $nf) { 
		$Mnsj = "No hay datos para ese mes"; 
		return;
	}
	my ($algo,$fch,$rt,$tt,$im,$nt,$nulo,@datosE);
	@datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 
	# Titulares
	$marco->insert('end', "$empr\n", 'negrita');
	$marco->insert('end', "Libro Honorarios  $nMes $cnf[0]\n", 'negrita');
	my $lin1 = "\nFecha        Número  RUT       Prestador                        ";
	$lin1 .= "          Neto   Retención       Total";
	my $lin2 = "-"x102;

	my @datos = $bd->listaBH($mes);
	if ( not @datos ) {return ;}

	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');

	$Tt = $Im = $Nt = 0;
	foreach $algo ( @datos ) {
		$fch = $ut->cFecha($algo->[0]); 
		$nm = $algo->[1]; 
		$rt = $algo->[2]; 
		$nmb = substr decode_utf8( $algo->[3] ),0,35 ;
		$tt = $pesos->format_number( $algo->[5] );
		$im = $pesos->format_number( $algo->[4] );
		$nt = $pesos->format_number( $algo->[5] - $algo->[4] );
		$nulo = $algo->[6]; 
		if ( not $nulo ) {
			$mov = sprintf("%10s %8s %10s %-35s %11s %11s %11s ", 
				$fch,$nm,$rt,$nmb,$nt,$im,$tt ) ;
			$marco->insert('end', "$mov\n",'detalle' ) ;
			$Tt += $algo->[5] ;
			$Im += $algo->[4] ;
			$Nt += $algo->[5] - $algo->[4] ;
		}
	}	
	$marco->insert('end',"$lin2\n",'detalle');
	$mov = sprintf("%10s %8s %10s %-35s %11s %11s %11s",'','','',
		'Totales', $pesos->format_number( $Nt ) ,
		$pesos->format_number( $Im ),
		$pesos->format_number( $Tt ) );
	$marco->insert('end', "$mov\n",'detalle' ) ;
	$marco->insert('end',"$lin2\n",'detalle');
	$bImp->configure(-state => 'active');
}
	

sub txt ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');
	# Genera archivo de texto
	my $d = "$rutE/txt/honorarios$mes.txt";
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Ver archivo '$d'"
}

sub csv ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	my ($Tt,$Iva,$Aft,$Ext,$fch,$nm,$rt,$nmb,$nulo,$a,$d);
	$d = "$rutE/csv/honorarios$mes.csv";
	open ARCHIVO, "> $d" or die $! ;
	my $l = "$empr\n";
	print ARCHIVO $l ;
	$l = "Libro Compras  $nMes $cnf[0]\n";
	print ARCHIVO $l ;
	$l = "Fecha,Factura,RUT,Proveedor,Afecto,Exento,IVA,Total\n";
	print ARCHIVO $l ;
	$Tt = $Iva = $Aft = $Ext = 0;
	foreach $a ( @datos ) {
		$fch = $ut->cFecha($a->[0]); 
		$nm = $a->[1]; 
		$rt = $a->[2]; 
		$nmb =  decode_utf8($a->[3]);
		$nulo = $a->[8]; 
		if ( not $nulo ) {
			$l = "$fch,$nm,$rt,$nmb,$a->[6],$a->[7],$a->[5],$a->[4]\n";
			print ARCHIVO $l ;
			$Tt += $a->[4] ;
			$Iva += $a->[5] ;
			$Aft += $a->[6] ;
			$Ext += $a->[7] ;
		}
	}
	$l = ",,,,$Aft,$Ext,$Iva,$Tt \n";
	print ARCHIVO $l ;

	close ARCHIVO ;
	$Mnsj = "Grabado en '$d'";
}

# Fin del paquete
1;
