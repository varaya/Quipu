#  Balance.pm - Consulta e imprime Balance tributario
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package Balance;

use Encode 'decode_utf8';
use Number::Format;
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
my ($empr,@cnf, $rutE);
my @data = ();

sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	$rutE = $rtE;
	my %tp = $ut->tipos();

	# Obtiene lista de cuentas con movimiento
	@data = $bd->datosCcM();
	if (not @data) {
		$ut->mError("No hay datos para el Balance.");
		return ;
	}
	
	# Define ventanas
	my $vnt = $vp->Toplevel();
	$vnt->title("Procesa Balance");
	$vnt->geometry("810x395+40+150"); 
	$esto->{'ventana'} = $vnt;

	# Define marco para mostrar resultado
	my $mtA = $vnt->Scrolled('Text', -scrollbars=> 'se', -bg=> 'white');
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
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mBotonesC->pack();
	$mtA->pack(-fill => 'both');
	$mMensajes->pack(-expand => 1, -fill => 'both');
	
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
	my $d = "$rutE/txt/balance.txt" ;
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Grabado en '$d'";
}

sub csv ( $ )
{
	my ($bd) = @_;	

	my ($algo,$l,$cta,$mntD,$mntH,$sldD,$sldH,$sld,$Prd,$Gnc);
	my ($ac,$pa,$pe,$ga,$gr,$tAc,$tPa,$tPe,$tGa,$tmD,$tmH,$tsD,$tsH,$d);

	$d = "$rutE/csv/balance.csv" ;
	open ARCHIVO, "> $d" or die $! ;

	print ARCHIVO "$empr\n";
	$l = "Balance Tributario  $cnf[0]";
	print ARCHIVO "$l\n";
	$l = "Cod.,Cuenta,Debe,Haber,Deudor,Acreedor,Activo,Pasivo,Pérdidas,Ganancias";
	print ARCHIVO "$l\n";
	$tAc = $tPa = $tPe = $tGa = $tmD = $tmH = $tsD = $tsH = 0;
	foreach $algo ( @data ) {
		$cta = abrev($algo->[0]) ;
		my $tSaldo = $algo->[5];
		my $saldoI = $algo->[4];
		$mntD = $algo->[2] ;
		$mntH = $algo->[3] ;
		$mntD += $saldoI if $tSaldo eq 'D';
		$mntH += $saldoI if $tSaldo eq 'A';
		$tmD += $mntD ;
		$tmH += $mntH ;
		$l = "$algo->[1],$cta,$mntD,$mntH" ;
		$gr = substr $algo->[1],0,1;
		$sldD = $sldH = 0;
		if ( $mntD > $mntH ) {
			$sldD = $mntD -  $mntH;
			$tsD += $sldD ;
			$tAc += $sldD if $gr eq '1';
			$tPe += $sldD if $gr eq '4';
		} else {
			$sldH = $mntH - $mntD ;
			$tsH += $sldH ;
			$tPa += $sldH if $gr eq '2';
			$tGa += $sldH if $gr eq '3';
		}
		$l .= ",$sldD,$sldH";
		$ac = $pa = $pe = $ga = 0;
		$ac = $sldD if $gr eq '1';
		$pa = $sldH if $gr eq '2';
		$pe = $sldD if $gr eq '4';
		$ga = $sldH if $gr eq '3';
		$l .= ",$ac,$pa,$pe,$ga";
		print ARCHIVO "$l\n";
	}
	$l = ",Totales,$tmD,$tmH,$tsD,$tsH,$tAc,$tPa,$tPe,$tGa" ;
	print ARCHIVO "$l\n";
	$Prd = $Gnc = 0 ;
	$Prd = $tPe - $tGa if $tPe > $tGa ; 
	$Gnc = $tGa - $tPe if $tPe < $tGa ;
	my $rs = ($Prd == 0) ? "Ganancia" :"Pérdida" ;
	$l = ",$rs,,,,,0,0,$Gnc,$Prd";
	print ARCHIVO "$l\n";
	close ARCHIVO ;
	
	$Mnsj = "Ver archivo '$d'";
}

sub muestra ( $ $ )
{
	my ($bd, $mt) = @_;
		
	my (@datosE,$algo,$mov,$cta,$mntD,$mntH,$sldD,$sldH,$sld,$Prd,$Gnc);
	my ($ac,$pa,$pe,$ga,$gr,$tAc,$tPa,$tPe,$tGa,$tmD,$tmH,$tsD,$tsH);

	# Datos generales
	@datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 
	@cnf = $bd->leeCnf(); 

	$mt->delete('0.0','end');
	$mt->insert('end', "$empr\n", 'negrita');
	$mt->insert('end', "Balance Tributario  $cnf[0]\n\n", 'negrita');
	my $lin1 = sprintf("%-5s %-25s", 'Cod.', 'Cuenta') ;
	$lin1 .= "        Debe        Haber      Deudor     Acreedor",
	$lin1 .= "      Activo     Pasivo     Pérdidas   Ganancias";
	my $lin2 = "-"x129;
	$mt->insert('end',"$lin1\n",'detalle');
	$mt->insert('end',"$lin2\n",'detalle');
	$tAc = $tPa = $tPe = $tGa = $tmD = $tmH = $tsD = $tsH = 0;
	foreach $algo ( @data ) {
		$cta = abrev($algo->[0]) ;
		my $tSaldo = $algo->[5];
		my $saldoI = $algo->[4];
		$mntD = $algo->[2] ;
		$mntH = $algo->[3] ;
		$mntD += $saldoI if $tSaldo eq 'D';
		$mntH += $saldoI if $tSaldo eq 'A';
		$tmD += $mntD ;
		$tmH += $mntH ;
		$mov = sprintf("%-5s %-25s %12s %12s", $algo->[1], $cta,
			$pesos->format_number($mntD), $pesos->format_number($mntH)) ;
		$gr = substr $algo->[1],0,1;
		$sldD = $sldH = $pesos->format_number(0);
		if ( $mntD > $mntH ) {
			$sldD = $pesos->format_number($mntD -  $mntH);
			$tsD += $mntD -  $mntH ;
			$tAc += $mntD -  $mntH if $gr eq '1';
			$tPe += $mntD -  $mntH if $gr eq '4';
		} else {
			$sldH = $pesos->format_number($mntH - $mntD) ;
			$tsH += $mntH - $mntD ;
			$tPa += $mntH - $mntD if $gr eq '2';
			$tGa += $mntH - $mntD if $gr eq '3';
		}
		$mov .= sprintf(" %11s %11s",$sldD, $sldH);
		# Distribuye saldo 
		$ac = $pa = $pe = $ga = $pesos->format_number(0) ;
		$ac = $sldD if $gr eq '1';
		$pa = $sldH if $gr eq '2';
		$pe = $sldD if $gr eq '4';
		$ga = $sldH if $gr eq '3';
		$mov .= sprintf(" %11s %11s %11s %11s",$ac, $pa, $pe, $ga);
		$mt->insert('end', "$mov\n", 'detalle' ) ;
	}
	$mt->insert('end',"$lin2\n",'detalle');
	$mov = sprintf("%5s %25s %12s %12s %11s %11s %11s %11s %11s %11s", 
		' ', 'Totales', 
		$pesos->format_number($tmD),
		$pesos->format_number($tmH),
		$pesos->format_number($tsD),
		$pesos->format_number($tsH),
		$pesos->format_number($tAc),
		$pesos->format_number($tPa),
		$pesos->format_number($tPe),
		$pesos->format_number($tGa)) ;
	$mt->insert('end',"$mov\n",'detalle');
	$Prd = $Gnc = 0 ;
	$Prd = $tPe - $tGa if $tPe > $tGa ; 
	$Gnc = $tGa - $tPe if $tPe < $tGa ;
	my $rs = ($Prd == 0) ? "Ganancia" :"Pérdida" ;
	$mov = sprintf("%5s %25s %49s %11s %11s %11s %11s",' ',$rs,' ','0','0',
		$pesos->format_number($Gnc),
		$pesos->format_number($Prd) );
	$mt->insert('end',"$mov\n",'detalle');
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
