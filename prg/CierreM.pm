#  CierreM.pm - Consulta e imprime Balance tributario
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM: 21.07.2009

package CierreM;

use Encode 'decode_utf8';
use Number::Format;
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
my ($empr,@cnf, $rutE, $mes);
my @data = ();

sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	$rutE = $rtE;
	my %tp = $ut->tipos();
	$nMes = '' ;
	
	# Define ventanas
	my $vnt = $vp->Toplevel();
	$vnt->title("Procesa Balance Mensual");
	$vnt->geometry("1010x450+0+100"); 
	$esto->{'ventana'} = $vnt;

	# Define marco para mostrar resultado
	my $mtA = $vnt->Scrolled('Text', -scrollbars=> 'se', -bg=> 'white',
		-height=> 420 );
	$mtA->tagConfigure('negrita', -font => $tp{ng} ) ;
	$mtA->tagConfigure('detalle', -font => $tp{mn} ) ;

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

	$bMst = $mBotonesC->Button(-text => "Muestra", 
		-command => sub { &valida($esto, $mtA) } );
	$bImp = $mBotonesC->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mtA);} ],
 	  ['command' => "planilla", -command => sub { csv($bd);} ] ] );
 	my $bRpr = $mBotonesC->Button(-text => "Reprocesa", 
		-command => sub {&reprocesa($esto, $mtA) } );
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
	$tMes->pack(-side => "left", -anchor => "w");
	$meses->pack(-side => "left", -anchor => "w");
	$bMst->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bRpr->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mBotonesC->pack();
	$mtA->pack(-fill => 'both');
	
#	muestra($bd,$mtA);
	$bImp->configure(-state => 'disabled');
	$bRpr->configure(-state => 'disabled');
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
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	if (not $mes) {
		$Mnsj = "Debe seleccionar un mes."; 
		return;
	} else {
		muestra($bd,$mt);
	}
}

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
			$tAc += $sldD if $gr eq '1' or $gr eq '2';
			$tPe += $sldD if $gr eq '4' or $gr eq '3';
		} else {
			$sldH = $mntH - $mntD ;
			$tsH += $sldH ;
			$tPa += $sldH if $gr eq '2' or $gr eq '1';
			$tGa += $sldH if $gr eq '3' or $gr eq '4';
		}
		$l .= ",$sldD,$sldH";
		$ac = $pa = $pe = $ga = 0;
		$ac = $sldD if $gr eq '1' or $gr eq '2';
		$pa = $sldH if $gr eq '2' or $gr eq '1';
		$pe = $sldD if $gr eq '4' or $gr eq '3';
		$ga = $sldH if $gr eq '3' or $gr eq '4';
		$l .= ",$ac,$pa,$pe,$ga";
		print ARCHIVO "$l\n";
	}
	$l = ",Totales,$tmD,$tmH,$tsD,$tsH,$tAc,$tPa,$tPe,$tGa" ;
	print ARCHIVO "$l\n";
	$Prd = $Gnc = 0 ;
	$Prd = $tPe - $tGa if $tPe > $tGa ; 
	$Gnc = $tGa - $tPe if $tPe < $tGa ;
	my $rs = ($Prd == 0) ? "Ganancia" :"Pérdida" ;
	$l = ",$rs,,,,,$Prd,$Gnc,$Gnc,$Prd";
	print ARCHIVO "$l\n";
	my ($pPrd , $pGnc) = (0, 0) ;
	$pPrd = $tPa - $tAc if $tPa > $tAc ; 
	$pGnc = $tAc - $tPa if $tPa < $tAc ;
	my ($sAc,$sPa,$sPe,$sGa);
	$sAc = $tAc + $pPrd ;	
	$sPa = $tPa + $pGnc ;
	$sPe = $tPe + $Gnc ;
	$sGa = $tGa + $Prd ;
	$l = ",Suma iguales,$tmD,$tmH,$tsD,$tsH,$sAc,$sPa,$sPe,$sGa";
	print ARCHIVO "$l\n";
	close ARCHIVO ;
	
	$Mnsj = "Ver archivo '$d'";
}

sub muestra ( $ $ )
{
	my ($bd, $mt) = @_;
		
	my (@datosE,$algo,$mov,$cta,$mntD,$mntH,$sldD,$sldH,$sld,$Prd,$Gnc);
	my ($ac,$pa,$pe,$ga,$gr,$tAc,$tPa,$tPe,$tGa,$tmD,$tmH,$tsD,$tsH,$tbl);

	# Obtiene lista de cuentas con movimiento

	@data = $bd->datosBM($mes);
	if (not @data) {
		$Mnsj = "No hay Balance para $nMes.";
		if ( not $bd->aBMensual($mes) ) {
			$Mnsj = "No hay datos para $nMes.";
			return ;
		} else {
			$Mnsj = "Procesando $nMes.";
#			@data = $bd->datosBM($mes);
		}
	}
	$mt->insert('end', "En desarrollo", 'negrita');
return ;
	# Datos generales
	@datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 
	@cnf = $bd->leeCnf(); 

	$mt->delete('0.0','end');
	$mt->insert('end', "$empr\n", 'negrita');
	$mt->insert('end', "Balance a $nMes $cnf[0]\n\n", 'negrita');
	my $lin1 = sprintf("%-5s %-21s", 'Cod.', 'Cuenta') ;
	$lin1 .= "           Debe          Haber        Deudor      Acreedor",
	$lin1 .= "        Activo       Pasivo      Pérdidas    Ganancias";
	my $lin2 = "-"x139;
	$mt->insert('end',"$lin1\n",'detalle');
	$mt->insert('end',"$lin2\n",'detalle');
	$tAc = $tPa = $tPe = $tGa = $tmD = $tmH = $tsD = $tsH = 0;
	foreach $algo ( @data ) {
		$cta = substr abrev($algo->[0]),0,21 ;
		my $tSaldo = $algo->[5];
		my $saldoI = $algo->[4];
		$mntD = $algo->[2] ;
		$mntH = $algo->[3] ;
		$mntD += $saldoI if $tSaldo eq 'D';
		$mntH += $saldoI if $tSaldo eq 'A';
		$tmD += $mntD ;
		$tmH += $mntH ;
		$mov = sprintf("%-5s %-21s %14s %14s", $algo->[1], $cta,
			$pesos->format_number($mntD), $pesos->format_number($mntH)) ;
		$gr = substr $algo->[1],0,1;
		$sldD = $sldH = $pesos->format_number(0);
		if ( $mntD > $mntH ) {
			$sldD = $pesos->format_number($mntD -  $mntH);
			$tsD += $mntD -  $mntH ;
			$tAc += $mntD -  $mntH if $gr eq '1' or $gr eq '2' ;
			$tPe += $mntD -  $mntH if $gr eq '4' or $gr eq '3';
		} else {
			$sldH = $pesos->format_number($mntH - $mntD) ;
			$tsH += $mntH - $mntD ;
			$tPa += $mntH - $mntD if $gr eq '2' or $gr eq '1' ;
			$tGa += $mntH - $mntD if $gr eq '3' or $gr eq '4';
		}
		$mov .= sprintf(" %13s %13s",$sldD, $sldH);
		# Distribuye saldo 
		$ac = $pa = $pe = $ga = $pesos->format_number(0) ;
		$ac = $sldD if $gr eq '1' or $gr eq '2' ;
		$pa = $sldH if $gr eq '2' or $gr eq '1' ;
		$pe = $sldD if $gr eq '4' or $gr eq '3';
		$ga = $sldH if $gr eq '3' or $gr eq '4';
		$mov .= sprintf(" %13s %13s %12s %12s",$ac, $pa, $pe, $ga);
		$mt->insert('end', "$mov\n", 'detalle' ) ;
	}
	$mt->insert('end',"$lin2\n",'detalle');
	my ($ftmD, $ftmH, $ftsD, $ftsH );
	$ftmD = $pesos->format_number($tmD);
	$ftmH = $pesos->format_number($tmH);
	$ftsD = $pesos->format_number($tsD);
	$ftsH = $pesos->format_number($tsH);
	$mov = sprintf("%5s %21s %14s %14s %13s %13s %13s %13s %12s %12s", 
		' ', 'Totales', $ftmD,$ftmH,$ftsD,$ftsH,
		$pesos->format_number($tAc),
		$pesos->format_number($tPa),
		$pesos->format_number($tPe),
		$pesos->format_number($tGa)) ;
	$mt->insert('end',"$mov\n",'detalle');
	$Prd = $Gnc = 0 ;
	$Prd = $tPe - $tGa if $tPe > $tGa ; 
	$Gnc = $tGa - $tPe if $tPe < $tGa ;
	my $fGnc = $pesos->format_number($Gnc) ;
	my $fPrd = $pesos->format_number($Prd) ;
	my $rs = ($Prd == 0) ? "Ganancia" :"Pérdida" ;
	my ($pPrd , $pGnc) = (0, 0) ;
	$pPrd = $tPa - $tAc if $tPa > $tAc ; 
	$pGnc = $tAc - $tPa if $tPa < $tAc ;	
	$mov = sprintf("%5s %21s %57s %13s %13s %12s %12s",' ',$rs,' ',
		$pesos->format_number($pPrd),
		$pesos->format_number($pGnc),$fGnc,$fPrd);
	$mt->insert('end',"$mov\n",'detalle');
	$mt->insert('end',"$lin2\n",'detalle');
	$mov = sprintf("%5s %21s %14s %14s %13s %13s %13s %13s %12s %12s", 
		' ', 'Sumas iguales', $ftmD,$ftmH,$ftsD,$ftsH,
		$pesos->format_number($tAc + $pPrd),
		$pesos->format_number($tPa + $pGnc),
		$pesos->format_number($tPe + $Gnc),
		$pesos->format_number($tGa + $Prd)) ;
	$mt->insert('end',"$mov\n",'detalle');
	$lin2 = "="x139;
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
