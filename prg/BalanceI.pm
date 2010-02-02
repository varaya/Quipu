#  BalanceI.pm - Consulta e imprime Balance tributario
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM: 13.08.2009

package BalanceI;

use Encode 'decode_utf8';
use Number::Format;
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
my ($empr, $ejerc, $rutE);
my @data = ();

sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE, $prd) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	$rutE = $rtE;
	$ejerc = $prd ;
	my %tp = $ut->tipos();

	# Obtiene lista de cuentas con movimiento
	@data = $bd->datosCcM(1);
	if (not @data) {
		$ut->mError("No hay datos para el Balance.");
		return ;
	}
	
	# Define ventanas
	my $vnt = $vp->Toplevel();
	$vnt->title("Balance Inicial");
	$vnt->geometry("650x450+0+100"); 
	$esto->{'ventana'} = $vnt;

	# Define marco para mostrar resultado
	my $mtA = $vnt->Scrolled('Text', -scrollbars=> 'se', -bg=> 'white',
		-height=> 420 );
	$mtA->tagConfigure('negrita', -font => $tp{ng} ) ;
	$mtA->tagConfigure('detalle', -font => $tp{mn} ) ;

	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	$bImp = $mBotonesC->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mtA);} ],
 	  ['command' => "planilla", -command => sub { csv($bd);} ] ] );
	my $bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy();} );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx} ,
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Compras'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');
	$Mnsj = "Para ver Ayuda presione botón 'i'.";

	# Dibuja interfaz
	$mMensajes->pack(-expand => 1, -fill => 'both');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mBotonesC->pack();
	$mtA->pack(-fill => 'both');
	
	muestra($bd,$mtA);

	bless $esto;
	return $esto;
}

# Funciones internas
sub txt ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');
	# Genera archivo de texto
	my $d = "$rutE/txt/balanceI.txt" ;
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Grabado en '$d'";
}

sub csv ( $ )
{
	my ($bd) = @_;	

	my ($algo,$l,$cta,$mntD,$mntH,$sldD,$sldH,$sld);
	my ($ac,$pa,$gr,$tAc,$tPa,$tsD,$tsH,$d);

	$d = "$rutE/csv/balanceI.csv" ;
	open ARCHIVO, "> $d" or die $! ;

	print ARCHIVO "$empr\n";
	$l = "Balance Inicial  $ejerc";
	print ARCHIVO "$l\n";
	$l = "Cod.,Cuenta,Deudor,Acreedor,Activo,Pasivo";
	print ARCHIVO "$l\n";
	$tAc = $tPa = $tsD = $tsH = 0;
	foreach $algo ( @data ) {
		$cta = abrev($algo->[0]) ;
		my $tSaldo = $algo->[5];
		my $saldoI = $algo->[4];
		($mntD,$mntH) = (0,0) ;
		$mntD += $saldoI if $tSaldo eq 'D';
		$mntH += $saldoI if $tSaldo eq 'A';
		$l = "$algo->[1],$cta" ;
		$gr = substr $algo->[1],0,1;
		$sldD = $sldH = 0;
		if ( $mntD > $mntH ) {
			$sldD = $mntD -  $mntH;
			$tsD += $sldD ;
			$tAc += $sldD if $gr eq '1' or $gr eq '2';
		} else {
			$sldH = $mntH - $mntD ;
			$tsH += $sldH ;
			$tPa += $sldH if $gr eq '2' or $gr eq '1';
		}
		$l .= ",$sldD,$sldH";
		$ac = $pa = 0;
		$ac = $sldD if $gr eq '1' or $gr eq '2';
		$pa = $sldH if $gr eq '2' or $gr eq '1';
		$l .= ",$ac,$pa";
		print ARCHIVO "$l\n";
	}
	$l = ",Totales,$tsD,$tsH,$tAc,$tPa" ;
	print ARCHIVO "$l\n";
	close ARCHIVO ;
	
	$Mnsj = "Ver archivo '$d'";
}

sub muestra ( $ $ )
{
	my ($bd, $mt) = @_;
		
	my (@datosE,$algo,$mov,$cta,$mntD,$mntH,$sldD,$sldH,$sld);
	my ($ac,$pa,$gr,$tAc,$tPa,$tsD,$tsH);

	# Datos generales
	@datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 

	$mt->delete('0.0','end');
	$mt->insert('end', "$empr\n", 'negrita');
	$mt->insert('end', "Balance Inicial  $ejerc\n\n", 'negrita');
	my $lin1 = sprintf("%-5s %-21s", 'Cod.', 'Cuenta') ;
	$lin1 .= "           Deudor      Acreedor        Activo       Pasivo";
	my $lin2 = "-"x85;
	$mt->insert('end',"$lin1\n",'detalle');
	$mt->insert('end',"$lin2\n",'detalle');
	$tAc = $tPa = $tsD = $tsH = 0;
	foreach $algo ( @data ) {
		$cta = substr abrev($algo->[0]),0,21 ;
		my $tSaldo = $algo->[5];
		my $saldoI = $algo->[4];
		($mntD,$mntH) = (0,0) ;
		$mntD = $saldoI if $tSaldo eq 'D';
		$mntH = $saldoI if $tSaldo eq 'A';
		$mov = sprintf("%-5s %-21s  ", $algo->[1], $cta ) ;
		$gr = substr $algo->[1],0,1;
		$sldD = $sldH = $pesos->format_number(0);
		if ( $mntD > $mntH ) {
			$sldD = $pesos->format_number($mntD -  $mntH);
			$tsD += $mntD -  $mntH ;
			$tAc += $mntD -  $mntH if $gr eq '1' or $gr eq '2' ;
		} else {
			$sldH = $pesos->format_number($mntH - $mntD) ;
			$tsH += $mntH - $mntD ;
			$tPa += $mntH - $mntD if $gr eq '2' or $gr eq '1' ;
		}
		$mov .= sprintf(" %13s %13s",$sldD, $sldH);
		# Distribuye saldo 
		$ac = $pa = $pesos->format_number(0) ;
		$ac = $sldD if $gr eq '1' or $gr eq '2' ;
		$pa = $sldH if $gr eq '2' or $gr eq '1' ;
		$mov .= sprintf(" %13s %13s",$ac, $pa);
		$mt->insert('end', "$mov\n", 'detalle' ) ;
	}
	$mt->insert('end',"$lin2\n",'detalle');
	my ( $ftsD, $ftsH );
	$ftsD = $pesos->format_number($tsD);
	$ftsH = $pesos->format_number($tsH);
	$mov = sprintf("%5s %21s   %13s %13s %13s %13s", 
		' ', 'Totales', $ftsD,$ftsH,
		$pesos->format_number($tAc),
		$pesos->format_number($tPa)) ;
	$mt->insert('end',"$mov\n",'detalle');
	$lin2 = "="x85;
	$mt->insert('end',"$lin2\n",'detalle');
}

sub abrev ( $ )
{
	my ($algo) = @_;
	my $ct = decode_utf8($algo) ;
	if (length $ct > 24) {
		my @pl = split / /, $ct;
		my $lt = substr $pl[0],0,1;
		$ct =~ s/^$pl[0]/$lt/;
	}
	return $ct ;
}

# Fin del paquete
1;
