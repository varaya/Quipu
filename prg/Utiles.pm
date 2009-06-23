#  Utiles.pm - Paquete de funciones comunes varias
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM : 22.06.2009 

package Utiles;

use Encode 'decode_utf8';
use Date::Simple ('ymd','today');

sub crea
{
	my ($esto, $vp) = @_;
	
	$esto = {};
	$esto->{'Ventana'} = $vp;
	
	bless $esto;
	return $esto;
}

sub tipos ( )
{
	
	my ($t1, $t2 ,$t3, $tb, $tm, $tf, $fx,%tp);
	$tb = "bitstream-vera-sans";
	$tm = "bitstream-vera-sans-mono";
	$tf = "Courier 9";
	$fx = "monospace 9";
	($t1,$t2,$t3) = (11,10,9) ;
	if ($^O eq 'MSWin32') {
		$tb = "Arial";
		$tm = "Courier";
		$tf = $fx = "Courier 8";
	}
	if ($^O eq 'darwin') {
		$tb = "Arial" ;
		$tf = $fx = "fixed";
		($t1,$t2,$t3) = (12,11,10) ;
	}
	%tp = ( 
		ng => "$tb $t1 bold" ,
		gr => "$tb $t2 bold" ,
		cn => "$tb $t3" ,
		tx => "$tm $t3" ,
		mn => "$tf" ,
		fx => "$fx") ;

	return %tp;	
}

sub tipoDcmt ( )
{
	my %td = ( 
		FC => "Facturas de Compra" ,
		FV => "Facturas de Venta" ,
		ND => "Notas de Débito" ,
		NC => "Notas de Crédito" ) ;
	return %td ;
}

sub grupos ( )
{
	my @grps = (  ['1','Activos','A'],['2','Pasivos','P'],
					['3','Ingresos','I'],['4','Gastos','G'] ) ;
	return @grps ;
}

sub mError
{	
	my ($esto, $mensaje) = @_;
	
	my $vp = $esto->{'Ventana'};
	
	my $altoP = $vp->screenheight();
	my $anchoP = $vp->screenwidth();
	my $xpos = (($anchoP-400)/2);
	my $ypos = (($altoP-100)/2);
	my $vnt = $vp->Toplevel();
	$vnt->geometry("400x100+$xpos+$ypos");
	$vnt->resizable(0,0);
	$vnt->title("Mensaje de Advertencia");
	my $marco = $vnt->Frame(-borderwidth => 0);
	my $texto = $marco->Label(-text => "$mensaje\n",
		-justify => 'center');
	my $btn = $marco->Button(-text => 'Listo',-width => 5, 
		-command => sub {$vnt->destroy();} );
	
	$marco->pack(-side => 'right',-expand => 1);
	$texto->pack(-side => 'top');
	$btn->pack(-side => 'bottom');
		
	$vnt->waitWindow();	
}

sub vRut
{
	my ($esto, $rut) = @_;
	
   for ($rut) {           # trim whitespace in $variable, cheap
        s/^\s+//;
        s/\s+$//;
    }

	my ($rt, $dvp, $lr,$j, $t, $dvc);
	
	$rt = $dvp = '';
	my @campos = split /-/, $rut;
	my @digitos = (3, 2, 7, 6, 5, 4, 3, 2);
	$rt = $campos[0];
	$dvp = $campos[1];
	$lr = length($rt) - 1;
	$j = @digitos;
	$t = 0;

	if ($dvp eq '' ) {return 0;}

	# Calcula dv
	until ($j-- == 0) {
	  last if $lr lt 0;
	  $t += substr($rt,$lr,1) * $digitos[$j];
	  $lr-- ; 
	}

	$dvc = 11 - ($t - int($t/11)*11);
	if ( $dvc == 10 ) { 
		$dvc = "K"; 
	} elsif ( $dvc == 11 ) { 
		$dvc = 0; 
	}
	my $res = ($dvc eq $dvp);
	return($res);
}

sub muestraPC( $ $ $ $ )
{
	# Muestra Plan de Cuentas
	my ($esto, $marco, $bd, $todo, $rut) = @_;
	
	my @listaG = $bd->datosSG();		# Lista de grupos
	my @datosC = $bd->datosCuentas();		# Lista de cuentas
	my @datosE = $bd->datosEmpresa($rut);
	my ($xgrp, $ngrp, $dcta, $xy, $xt);
	my $empresa = ' ' ;
	if (@datosE) {
		$empresa = decode_utf8($datosE[0]); 
	}
	
	$marco->delete('0.0','end');
	$marco->insert('end', "PLAN DE CUENTAS - $empresa\n\n", 'negrita' ) ;
	if (not @listaG) {
		$marco->insert('end', "Falta definir los subgrupos Plan\n",'grupo');
		return 0;
	} elsif (not @datosC) {
		$marco->insert('end', " Falta definir las Cuentas de Mayor\n",'grupo');
		return 0;
	} 
	if ($todo) {
		$xt = sprintf("   %-5s %-38s   %2s  %2s  %2s",'', '', 'CI', 'IE','SN' );
		$marco->insert('end', "$xt\n", 'detalle' ) ;
	}
	foreach $xgrp ( @listaG ) {
		$ngrp = sprintf("%-3s %-30s", $xgrp->[0], decode_utf8($xgrp->[1] ) );
		$marco->insert('end', "$ngrp\n", 'grupo' ) ;
		foreach $dcta ( @datosC ) {
			$xy = sprintf("   %-5s %-38s", $dcta->[0], decode_utf8($dcta->[1]) ) ;
			$xt = sprintf("   %1s   %1s   %1s",$dcta->[4],$dcta->[3],$dcta->[5] ) ;
			if ( $xgrp->[0] eq $dcta->[2] ) {
				if ($todo) {
					$marco->insert('end', "$xy $xt\n", 'detalle' ) ;
				} else {
					$marco->insert('end', "$xy\n", 'cuenta' ) ;
				}
			}
		}
	}
	return 1;
}

sub fechaHoy( )
{
	my @cmp = split /-/, today() ;
	
	return "$cmp[2]/$cmp[1]/$cmp[0]";
}

sub cFecha( $ )
{
	my ($esto, $ff) = @_;
	my ($dm, $mes, $a);
	
	if (not $ff) { return "";}
	$a = substr $ff,0,4;
	$mes = substr $ff,4,2;
	$dm = substr $ff,6,2;
	
	return "$dm/$mes/$a";
}

sub analizaFecha ( $ ) 
{	
	my ($esto, $ff) = @_;
	# La fecha debe pasar en el formato "dd/mm/aaaa"
	my @cmp = split /\//, $ff ;
	# Devuelve una fecha válida o 'undef' en caso contrario
	$ff = ymd($cmp[2],$cmp[1],$cmp[0]) ;
	# Convierte a formato AAAAMMDD si es válida
	$ff =~ s/-//g if $ff ;
	return $ff ;
}

sub ayuda 
{
	my ($esto, $mt, $ayd) = @_;

	$mt->delete('0.0','end');
	open AYD, "ayd/$ayd.txt" or die $!;
	my $i = 0;
	while ( <AYD> ) {
		if ($i == 0) { 
			$mt->insert('end', "$_", 'negrita' );
		} else { 
			if ($_ =~ s/^\.n//) {
				$mt->insert('end',"$_", 'grupo'); 
			} else {
				$mt->insert('end',"$_"); 
			}
		}
		$i += 1;
	} 
}

sub meses
{
	my @m = ( ['01','Enero'], ['02','Febrero'], ['03','Marzo'],
		['04','Abril'], ['05','Mayo'], ['06','Junio'], 
		['07','Julio'], ['08','Agosto'], ['09','Septiembre'],
		['10','Octubre'], ['11','Noviembre'], ['12','Diciembre'],
		['0','Todos'] ) ;
	
	return @m ;
}

1;
