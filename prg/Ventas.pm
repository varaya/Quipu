#  Ventas.pm - Consulta e imprime Libro Ventas por mes
#  Forma parte del programa Quipu
#
#  Derechos de Autor: V�ctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los t�rminos previstos en la 
#  licencia incluida en este paquete
#  UM : 07.04.2010 

package Ventas;

use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;
use Data::Dumper;
# Variables v�lidas dentro del archivo
my ($Mnsj, $mes, $nMes, $empr, $rutE, $ejerc) ;	# Variables
my ($Tt,$Iva,$Aft,$Ext,$IEsp,$TDcmt);
my @lMeses = () ;;
my ($bCan, $bImp) ; # Botones
# Formato de n�meros
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE, $prd) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	$FechaI = $ut->fechaHoy();
	$ejerc = $prd ;
	$nMes = '' ;
	$rutE = $rtE ;
	
	# Define ventanas
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Libro Ventas");
	$vnt->geometry("970x450+40+100"); 
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
	$meses->delete(12,12); # Elimina el 'Todos' al final

	# Barra de mensajes y bot�n de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Ventas'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione bot�n 'i'.";
		
	# Define botones
	$bMst = $mBotonesC->Button(-text => "Muestra", 
		-command => sub { &valida($esto, $mtA) } );
	$bImp = $mBotonesC->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mtA);} ],
 	  ['command' => "planilla", -command => sub { csv($esto);} ] ] );
	$bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { $bd->borraTempRF(); $vnt->destroy();} );
	
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

	my $nf = $bd->cuentaDcm('Ventas',$mes);
	$marco->delete('0.0','end');
	$Mnsj = " ";
	if (not $nf) { 
		$Mnsj = "No hay datos para ese mes"; 
		return;
	}
	my ($algo,$nmb,$tp,$fch,$rt,$tt,$iva,$aft,$ext,$nulo,$ie,$ni,@datosE,%nd,$cmpr);
	
	$bd->borraTempRF();
	$bd->creaTempRF( 'FV', 'FR' ) ;
	
	@datosE = $bd->datosEmpresa($rutE);
	%nd = $ut->tipoDcmt();
	$empr = decode_utf8($datosE[0]); 
	# Titulares
	$marco->insert('end', "$empr\n", 'negrita');
	$marco->insert('end', "Libro Ventas  $nMes $ejerc\n", 'negrita');
	my $lin1 = "\nN�  Fecha        N�mero  RUT        Proveedor                       ";
	my $lin1b = "      Afecto      Exento         IVA    I.Reten.       Total";
	$lin1 .= $lin1b ;
	my $lin2 = "-"x131;
	
	# Muestra Facturas manuales
	detalles($marco,$lin1,$lin2,$ut,$bd,'FV','M', $nd{FE});
	# Muestra Facturas de Compra recibidas
	detalles($marco,$lin1,$lin2,$ut,$bd,'FR','M', $nd{FR});
	# Facturas Electr�nicas
	detalles($marco,$lin1,$lin2,$ut,$bd,'FV','E', 'Facturas Electr�nicas');	
	# Notas de Cr�dito
	detalles($marco,$lin1,$lin2,$ut,$bd,'NC','', $nd{NC} );	
	# Notas de D�bito
	detalles($marco,$lin1,$lin2,$ut,$bd,'ND','', $nd{ND} );
	# Resumen mes
	$marco->insert('end', "\nResumen $nMes $ejerc\n\n", 'negrita');
	
	$lin1 = "Tipo de Documento              Cant." . $lin1b ;
	$lin2 = "-"x96;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	my @dtsR = $bd->datosRF();
	$Tt = $Iva = $Aft = $Ext = $IEsp = $TDcmt = 0;
	foreach $algo ( @dtsR ) {
		$ni = $pesos->format_number( $algo->[0] );
		$tt = $pesos->format_number( $algo->[1] );
		$iva = $pesos->format_number( $algo->[2] );
		$aft = $pesos->format_number( $algo->[3] );
		$ext = $pesos->format_number( $algo->[4] ); 
		$ir = $pesos->format_number( $algo->[6] );
		$tp = $algo->[7] ;
		if ( not $tp eq '' ) {
			$mov = sprintf("%-29s %5s  %11s %11s %11s %11s %11s", 
				$nd{$tp}, $ni,$aft,$ext,$iva,$ir,$tt ) ;
			$marco->insert('end', "$mov\n",'detalle' ) ;
			$Tt += $algo->[1] ;
			$Iva += $algo->[2] ;
			$Aft += $algo->[3] ;
			$Ext += $algo->[4] ;
			$IvaR += $algo->[6];
			$TDcmt += $algo->[0];			
		}
	}
	$marco->insert('end',"$lin2\n",'detalle');
	$mov = sprintf("%-29s %5s  %11s %11s %11s %11s %11s", 'Totales', 
			$pesos->format_number($TDcmt),
			$pesos->format_number($Aft),
			$pesos->format_number($Ext),
			$pesos->format_number($Iva),
			$pesos->format_number($IvaR),
			$pesos->format_number($Tt) ) ;
	$marco->insert('end', "$mov\n",'detalle' ) ;
	$marco->insert('end',"$lin2\n",'detalle');	
	
	$bImp->configure(-state => 'active');
}

sub detalles ( $ $ $ $)
{
	my ($marco,$lin1,$lin2,$ut,$bd,$td,$tf,$nmb) = @_;
	
	my @datos = $bd->listaFct('Ventas',$mes, $td, $tf);
	if ( not @datos ) {return ;}
	
	$marco->insert('end', "\n$nmb", 'negrita');
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	$Tt = $Iva = $Aft = $Ext = $IEsp = $TDcmt = $IvaR = 0;
	foreach $algo ( @datos ) {
		$fch = $ut->cFecha($algo->[0]); 
		$nm = $algo->[1]; 
		$rt = $algo->[2]; 
		$tt = $pesos->format_number( $algo->[3] );
		$iva = $pesos->format_number( $algo->[4] );
		$aft = $pesos->format_number( $algo->[5] );
		$ext = $pesos->format_number( $algo->[6] );
		$nulo = $algo->[7]; 
		$ie = $pesos->format_number( $algo->[8] );
		$ni = $algo->[9];
		$cmpr = $algo->[10];
		$ivaR = $pesos->format_number( $algo->[11] );
		if ( $nulo < 2 ) { # Se excluyen las Anuladas: c�digo 2
			$nmb =  $rt eq '' ? 'Nula' : substr decode_utf8( $bd->buscaT($rt) ),0,32 ;
			$mov = sprintf("%3s  %10s %8s %10s %-32s %11s %11s %11s %11s %11s %4s", 
				$ni,$fch,$nm,$rt,$nmb,$aft,$ext,$iva,$ivaR,$tt,$cmpr) ;
			$marco->insert('end', "$mov\n",'detalle' ) ;
			$Tt += $algo->[3] ;
			$Iva += $algo->[4] ;
			$Aft += $algo->[5] ;
			$Ext += $algo->[6] ;
			$IEsp += $algo->[8];
			$IvaR += $algo->[11] ? $algo->[11] : 0 ;
			$TDcmt += 1 if $algo->[3];
		}
	}	
	$marco->insert('end',"$lin2\n",'detalle');
	$mov = sprintf("%4s %10s %8s %10s %-32s %11s %11s %11s %11s %11s",'','','',
		'', 'Totales', $pesos->format_number( $Aft ) ,
		$pesos->format_number( $Ext ),
		$pesos->format_number( $Iva ),
		$pesos->format_number( $IvaR ),
		$pesos->format_number( $Tt ) );
	$marco->insert('end', "$mov\n",'detalle' ) ;
	$marco->insert('end',"$lin2\n",'detalle');
	# Registra totales para Resumen
	$bd->actualizaRF($td,$TDcmt,$Tt,$Iva,$Aft,$Ext,$IEsp,$IvaR);
}

sub txt ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');
	# Genera archivo de texto
	my $d = "$rutE/txt/ventas$mes.txt";
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

	my ($Tt,$Iva,$Aft,$Ext,$IvaR,$fch,$nm,$rt,$nmb,$nulo,$a,$d,%nd,$cmpr,$ir);
	%nd = $ut->tipoDcmt();
	$d = "$rutE/csv/ventas$mes.csv";
	open ARCHIVO, "> $d" or die $! ;
	my $l = "$empr\n";
	print ARCHIVO $l ;
	$l = "Libro Ventas  $nMes $ejerc\n";
	print ARCHIVO $l ;
	$l = "N�,Fecha,Factura,RUT,Cliente,Afecto,Exento,IVA,IReten.,Total\n";
	print ARCHIVO $l ;
 
	detalleCSV($ut,$bd,'FV','M',$nd{FE});
	detalleCSV($ut,$bd,'FR','M',$nd{FR});
	detalleCSV($ut,$bd,'FV','E','Facturas Electr�nicas');
	detalleCSV($ut,$bd,'NC','',$nd{NC});
	detalleCSV($ut,$bd,'ND','',$nd{ND});
	# Resumen
	$l = "\n,,,,Resumen $nMes $ejerc\n";
	print ARCHIVO $l ;
	$l = ",,,,Tipo de Documento,Afecto,Exento,IVA,I.Reten.,Total,Cant.\n";
	print ARCHIVO $l ;
	my @dtsR = $bd->datosRF();
	$Tt = $Iva = $Aft = $Ext = $IvaR = $TDcmt = 0;
	foreach $algo ( @dtsR ) {
		$ni = $algo->[0] ;
		$tt = $algo->[1] ;
		$iva = $algo->[2] ;
		$aft = $algo->[3] ;
		$ext = $algo->[4] ; 
		$ir = $algo->[6] ;
		$tp = $algo->[7] ;
		if ( not $tp eq '' ) {
			$l = ",,,,$nd{$tp},$aft,$ext,$iva,$ir,$tt,$ni\n" ;
			print ARCHIVO $l ;
			$Tt += $algo->[1] ;
			$Iva += $algo->[2] ;
			$Aft += $algo->[3] ;
			$Ext += $algo->[4] ;
			$IvaR += $algo->[6];
			$TDcmt += $algo->[0];			
		}
	}
	$l = ",,,,Totales,$Aft,$Ext,$Iva,$IvaR,$Tt,$TDcmt\n" ;
	print ARCHIVO $l ;
	
	close ARCHIVO ;
	$Mnsj = "Grabado en '$d'";
}

sub detalleCSV ( )
{
	my ($ut,$bd,$td,$tf,$stit) = @_;
	my ($Tt,$Iva,$Aft,$Ext,$IvaR,$l,$a);

	my @datos = $bd->listaFct('Ventas', $mes, $td, $tf);
	if ( not @datos ) { return ;}
	
	print ARCHIVO "$stit\n ";
	$Tt = $Iva = $Aft = $Ext = $IvaR = 0;
	foreach $a ( @datos ) {
		$fch = $ut->cFecha($a->[0]); 
		$nm = $a->[1]; 
		$rt = $a->[2]; 
		$nmb = $rt eq '' ? 'Nula' : substr decode_utf8( $bd->buscaT($rt) ),0,35 ;
		$nulo = $a->[7]; 
		$ni = $a->[9];
		$cmpr = $a->[10];
		$a->[11] = 0 if not $a->[11] ;
		$l = "$ni,$fch,$nm,$rt,$nmb,$a->[5],$a->[6],$a->[4],$a->[11],$a->[3],$cmpr\n";
		print ARCHIVO $l ;
		$Tt += $a->[3] ;
		$Iva += $a->[4] ;
		$Aft += $a->[5] ;
		$Ext += $a->[6] ;
		$IvaR += $a->[11] ;
	}
	$l = ",,,,Totales,$Aft,$Ext,$Iva,$IvaR,$Tt\n";
	print ARCHIVO $l ;
}

# Fin del paquete
1;
