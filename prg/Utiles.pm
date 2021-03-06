#  Utiles.pm - Paquete de funciones comunes varias
#  Forma parte del programa Quipu
#
#  Derechos de Autor: V�ctor Araya R., 2010
#  
#  Puede ser utilizado y distribuido en los t�rminos previstos en la 
#  licencia incluida en este paquete 
#  UM : 25.06.2010 

package Utiles;

use Encode 'decode_utf8';
use Date::Simple ('ymd','today','d8');
use Number::Format;

my $valida = 1 ;

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
	my %td = ( FC => "Facturas Recibidas" , FV => "Facturas Emitidas" ,
		FR => "Facturas Recibidas" , FE => "Facturas Emitidas" ,
		ND => "Notas de D�bito" , NC => "Notas de Cr�dito" ) ;
	return %td ;
}

sub tablaD ( )
{
	my %td = ('FC' => "Compras" , 'FV' => "Ventas" , 'FE' => "Compras" , 
		'FR' => "Ventas" , 'BH' => "BoletasH" , 'LT' => "Docs", 'CH' => "Docs") ;
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
	
	return 1 if not $valida ;
	
	for ($rut) {           # elimina espacios en blanco
        s/^\s+//;
        s/\s+$//;
    }

	my ($rt, $dvp, $lr,$j, $t, $dvc);
	
	$rt = $dvp = '';
	my @campos = split /-/, $rut;
	return 0 if not defined $campos[1]  ;
	
	my @digitos = (3, 2, 7, 6, 5, 4, 3, 2);
	$rt = $campos[0];
	$dvp = $campos[1]  ;
	$lr = length($rt) - 1;
	$j = @digitos;
	$t = 0;
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
	my @datosC = $bd->datosCuentas(1);		# Lista de cuentas
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
	# Devuelve una fecha v�lida o 'undef' en caso contrario
	$ff = ymd($cmp[2],$cmp[1],$cmp[0]) ;
	# Convierte a formato AAAAMMDD si es v�lida
	$ff =~ s/-//g if $ff ;
	return $ff ;
}

sub diaAnterior ( $ )
{
	my ($esto, $ff) = @_;
	my $date = d8($ff);
	my @cmp = split /-/, $date - 1 ;
	return "$cmp[2]/$cmp[1]/$cmp[0]" ;
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
		['04','Abril'], ['05','Mayo'], ['06','Junio'], ['07','Julio'], 
		['08','Agosto'], ['09','Septiembre'], ['10','Octubre'], 
		['11','Noviembre'], ['12','Diciembre'], ['0','Todos'] ) ;
	
	return @m ;
}

sub imprimirC ( $ $ $ ) # imprime comprobante
{
	my ($esto, $bd, $Numero, $Empresa) = @_;
	
	my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
	my $tc = {};
	$tc->{'I'} = 'Ingreso';
	$tc->{'E'} = 'Egreso';
	$tc->{'T'} = 'Traspaso';
	my ($nmrC, $tipoC, $fecha, $glosa, $total, $nulo, $a, $mes, $dm, $ff);
	
	my @datos = $bd->datosCmprb($Numero) ;
	$nmrC = $datos[0];
	$tipoC = $tc->{$datos[3]};
	$ff = $datos[2];
	$a = substr $ff,0,4;
	$mes = substr $ff,4,2;
	$dm = substr $ff,6,2;
	$fecha = "$dm/$mes/$a" ;
	$glosa = $datos[1];
	$total = $pesos->format_number( $datos[4] );
	$nulo = $datos[5];
	$ref = $datos[6];
	
	my $d = "var/cmprb.txt" ;
	open ARCHIVO, "> $d" or die $! ;

	my $lin = "\n$Empresa\n\nComprobante de $tipoC  # $nmrC              Fecha: $fecha\n" ;
	print ARCHIVO $lin ;
	print ARCHIVO "Glosa: $glosa\n\n";
	my @data = $bd->itemsC($nmrC);
	my ($algo, $ch, $cm, $ncta, $mntD, $mntH, $dt, $ci, $td, $dcm, $rtF, $nmb);
	my ($tD, $tH, $tch) = (0, 0, 0);
	$rtF = $nmb = $dcm = '' ;
	my $lin1 = "Cuenta                                       Debe        Haber"  . "\n";
	print ARCHIVO $lin1 ;
	my $lin2 = "-"x62;
	print ARCHIVO $lin2 . "\n" ;
	foreach $algo ( @data ) {
		$cm = $algo->[1];  
		$ncta = substr $bd->nmbCuenta($cm),0,30 ;
		$mntD = $mntH = $pesos->format_number(0);
		$mntD = $pesos->format_number( $algo->[2] ); 
		$tD += $algo->[2] ;
		$mntH = $pesos->format_number( $algo->[3] );
		$tH += $algo->[3] ;
		$ci = $algo->[6] ? substr $algo->[6], 0, 1 : '' ;
		$dcm = " " ;
		if ( $ci eq 'S' and $algo->[5] ) {
			$dcm = $bd->buscaT($algo->[5]) ;
			$dcm = $bd->buscaP($algo->[5]) if not $dcm ;
		} else {
			$dcm =  "$algo->[6] $algo->[7]" if $algo->[7] ;
			$dcm = $algo->[4] if $ci eq '' or $algo->[6] eq 'XZ';
		}
		$rtF = $algo->[5] if $ci eq 'F';
		if ($algo->[6] eq 'CH') {
			$ch = $algo->[7] ;
			$nBanco = $ncta;
			$tch += 1 ;
		}
		$dcm = substr $dcm,0,32 ;
		$lin = sprintf("%-5s %-30s %12s %12s  %-12s", $cm, $ncta, $mntD, $mntH, $dcm )  . "\n" ;
		print ARCHIVO $lin ;
	}
	print ARCHIVO $lin2 . "\n";
	$lin = sprintf("%36s %12s %12s", "Totales" ,
			$pesos->format_number($tD), $pesos->format_number($tH) ) . "\n";
	print ARCHIVO $lin ;
	print ARCHIVO $lin2 . "\n\n";
	
	$nmb = $bd->buscaT($rtF) ;
	print ARCHIVO "Pagado a: $nmb   RUT: $rtF\n" if $nmb;
	if ( $tch == 1 ) {
		print ARCHIVO "Cheque #: $ch   Banco: $nBanco \n" ;
	} else {
		print ARCHIVO "Cheques del Banco $nBanco\n" if $tch > 0 ;
	}
	
	print ARCHIVO "\n\n__________________     _______________    __________________   ______________" ;
	print ARCHIVO "\n    Emitido                 V� B�          Recibo Conforme           RUT" ;
	
	close ARCHIVO ;
	system "lp -o cpi=12 $d";
}

1;
