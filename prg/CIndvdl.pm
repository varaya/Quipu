#  CIndvdl.pm - Consulta e imprime Cuenta Individual
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM : 21.12.2009

package CIndvdl;

use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
my ($Mnsj, $rut, $RUT, @cnf, $empr, $Tipo, $Nombre, $rutE) ;	# Variables
my @lMeses = () ;
my @datos = () ;
my @data = () ;
my %tabla = () ; # Lista de nombres según tipo de documento
my ($bCan, $bImp, $bBrr) ; # Botones
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
	$RUT = $Tipo = '' ;
	$rutE = $rtE;
	%tabla = ('BH' => 'Boletas Honorarios' ,'FC' => 'Facturas de Compras' ,
		'FV' => 'Facturas de Ventas', 'LT' => 'Letras', 'CH' => 'Cheques',
		'NC' => 'Notas de Crédito', 'ND' => 'Notas de Débito' ) ;
	# Define ventanas
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Cuenta Invididual");
	$vnt->geometry("720x380+400+50"); 
	# Define marco para mostrar resultado
	my $mtA = $vnt->Scrolled('Text', -scrollbars=> 'e', -bg=> 'white');
	$mtA->tagConfigure('negrita', -font => $tp{ng}) ;
	$mtA->tagConfigure('detalle', -font => $tp{mn}) ;
	$mtA->tagConfigure('grupo', -font => $tp{gr}, -foreground => 'brown') ;
	
	# Define marcos
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Define campo para seleccionar mes
	$rut = $mBotonesC->LabEntry(-label => "RUT:  ", -width => 15,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'left', -textvariable => \$RUT);
	my $historial = $mBotonesC->Radiobutton(-text => "Historial", 
		-value => 'H', -variable => \$Tipo );
	my $pendiente = $mBotonesC->Radiobutton(-text => "Pendientes", 
		-value => 'P', -variable => \$Tipo );

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
	$bBrr = $mBotonesC->Button(-text => "Borra", -command => sub { $mtA->delete('0.0','end');} );
	$bCan = $mBotonesC->Button(-text => "Cancela", -command => sub { $vnt->destroy();} );
	
	# Dibuja interfaz
	$mMensajes->pack(-expand => 1, -fill => 'both');
	$rut->pack(-side => "left", -anchor => "w");
	$historial->pack(-side => "left", -anchor => "w");
	$pendiente->pack(-side => "left", -anchor => "w");
	$bMst->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bBrr->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mBotonesC->pack();
	$mtA->pack(-fill => 'both');

	$bImp->configure(-state => 'disabled');
	$rut->focus;

	bless $esto;
	return $esto;
}

# Funciones internas
sub valida ( $ ) 
{
	my ($esto,$mt) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};
	
	$Mnsj = " ";
	my $prs = 0;
	# Busca RUT
	if (not $RUT) {
		$Mnsj = "Debe indicar un RUT.";
		$rut->focus;
		return;
	}
	$RUT = uc($RUT);
	if ( not $ut->vRut($RUT) ) {
		$Mnsj = "El RUT no es válido";
		$rut->focus;
		return;
	} else {
		my $nmb = $bd->buscaT($RUT);
		if (not $nmb) {
			if (not $nmb = $bd->buscaP($RUT) ) {
				$Mnsj = "Curioso: ese RUT no aparece registrado.";
				$rut->focus;
				return;
			}
			$prs = 1 ;
		} 
		$Nombre = decode_utf8("  $nmb");
	}
	$Mnsj = $Nombre ;
	if (not $Tipo) {
		$Mnsj = "Debe seleccionar un tipo de informe."; 
		return;
	} else {
		informeH($esto,$mt) if $Tipo eq "H" ;
		informeP($esto,$mt,$prs) if $Tipo eq "P" ;
	}
}

sub informeP ( $ $ $ ) {

	my ($esto, $marco, $prs) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	if ($prs) {
		$Mnsj = "Ese informe no está disponiblen para el Personal.";
		return ;
	}
	my @info = $bd->infoT($RUT) ;
	my $nmb = decode_utf8( $info[0] );
	my ($tbl, $c,$v,$h ) =  ("Ventas", 0,0,0 );
	$marco->insert('end', "Documentos Pendientes $nmb  Rut: $RUT\n\n", 'grupo');
	@data = $bd->datosFacts($RUT,$tbl,1);
	if (@data) {
		detalle($marco, $ut, $tbl, $h) ;
		$v = 1 ;
	} 
	$tbl = "Compras" ;
	@data = $bd->datosFacts($RUT,$tbl,1);
	if (@data) {
		detalle($marco, $ut, $tbl, $h) ;
		$c = 1 ;
	} 
	$tbl = "BoletasH"  ;
	@data = $bd->datosFacts($RUT,$tbl,1);
	if (@data) {
		$h = 1 ;
		detalle($marco, $ut, $tbl, $h) ;
	}
	if ( $c + $v + $h == 0 ) {
		$marco->insert('end', "NO hay documentos pendientes\n\n", 'grupo');
	}
	$bImp->configure(-state => 'active');	
}

sub detalle ( $ $ $ $ )
{
	my ($marco, $ut, $tbl, $hn ) = @_;
	$marco->insert('end', "$tbl\n", 'grupo');
	my $lin1 = sprintf("%12s  %10s %12s %12s  %10s  %5s",'#','Fecha','Monto','Abonos','Vence','Cmpr') ;
	my $lin2 = "-"x67;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	my ($algo,$fe,$fv,$nmr,$tt,$ab,$nulo,$cmp,$mov,$stt,$sab,$mnt,$tp,$mab);
	$stt = $sab = 0;
	foreach $algo ( @data ) {
		$fe =  $ut->cFecha($algo->[1]);
		$fv =  $ut->cFecha($algo->[4]);
		$nmr = $algo->[0];
		$mnt = $hn ? $algo->[2] - $algo->[7] : $algo->[2] ;
		$tt = $pesos->format_number($mnt);
		$stt += $mnt ;
		$mab = $algo->[3] ;
		$ab = $pesos->format_number( $mab );
		$sab += $mab ;
		$nulo = $algo->[6];
		$cmp = $algo->[5];
		$tp = $hn ? "  " : $algo->[8];
		$mov = sprintf("%10s %2s %10s %12s %12s  %10s  %5s",$nmr,$tp,$fe,$tt,$ab,$fv,$cmp) ;
		$marco->insert('end', "$mov\n", 'detalle' ) ;
	}
	$marco->insert('end',"$lin2\n",'detalle');
	$tt = $pesos->format_number($stt);
	$ab = $pesos->format_number($sab);
	$mov = sprintf("%12s  %10s %12s %12s",'','',$tt,$ab) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	$marco->insert('end',"$lin2\n\n",'detalle') ;
}

sub informeH ( $ $ ) {

	my ($esto, $marco) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};
	# Ordena por Cuenta de Mayor
	@data = $bd->itemsCI($RUT,'CuentaM');
	$Mnsj = " ";
	if (not @data) { 
		$Mnsj = "No hay datos para $Nombre"; 
		return;
	}
#	print Dumper @data ;
	my ($algo,@datosE,@datosCI,$tC,$fecha,$nulo,$tDebe,$tHaber,$mntD,$mntH,$cTd,$sst);
	@datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 
	@datosCI = $bd->datosCI($RUT);
	my $saldoI = $datosCI[3];
	my $tSaldo = $datosCI[4];
	my $fechaUM = $datosCI[5];
	my $lst = "-"x64 ;
	my $movST = sprintf("%17s %-62s",'',$lst) ;
	$marco->insert('end', "$empr  $cnf[0]\n", 'negrita');
	$marco->insert('end', "Cuenta Corriente $Nombre  Rut: $RUT\n\n", 'grupo');
	$marco->insert('end', "Comprobante\n" , 'detalle');
	my $lin1 = "   # T Fecha      Glosa                                 ";
	$lin1 .= "          Debe       Haber  Documento";
	my $lin2 = "-"x93;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	$tDebe = $tHaber = 0 ;
	$dt = "Saldo inicial";
	$mntD = $mntH = $pesos->format_number(0);
	if ( $tSaldo eq 'D') {
		$mntD = $pesos->format_number( $saldoI ); 
		$tDebe += $saldoI;
	}
	if ($tSaldo eq 'A') {
		$mntH = $pesos->format_number( $saldoI );
		$tHaber += $saldoI;
	}
	$mov = sprintf("%4s %-1s %10s %-40s %11s %11s",
		'','',"01/01/$cnf[0]",$dt,$mntD,$mntH) ;
	$marco->insert('end', "$mov\n\n", 'detalle' ) ;
	my ($stD, $stH, $nmbC, $aTd, $Td );
	$nmbC = $aTd = '' ;
	foreach $algo ( @data ) {
		$Td = $algo->[6] ;
		$cTd = $algo->[1] ;
		if ( $cTd < 3000 ) { 
		  if (not $cTd eq $aTd) {
			if (not $aTd eq '' ) {
				$mntD = $mntH = $pesos->format_number(0);
				$mntD = $pesos->format_number( $stD );
				$mntH = $pesos->format_number( $stH );
				$marco->insert('end', "$movST\n", 'detalle' ) ;
#				$dt = $tabla{$aTd} ? "Subtotal $tabla{$aTd}" : "Subtotal" ;
				$dt = "Subtotal $aTd ";
				$mov = sprintf("%17s %40s %11s %11s",'',$dt,$mntD,$mntH ) ;
				$marco->insert('end', "$mov\n", 'detalle' ) ;
				$dt = "Saldo";
				$sst = $stD - $stH ;
				$mntD = $mntH = '';
				$mntD = $pesos->format_number( $sst ) if $sst > 0 ;
				$mntH = $pesos->format_number( -$sst ) if $sst < 0 ;				
				$mov = sprintf("%17s %40s %11s %11s",'',$dt,$mntD,$mntH ) ;
				$marco->insert('end', "$mov\n\n", 'detalle' ) ;

			}
			$aTd = $cTd ;
			($stD, $stH) = (0,0);
#			$marco->insert('end', "$tabla{$cTd}\n", 'grupo' ) if $tabla{$cTd} ;
			$nmb = decode_utf8( $bd->nmbCuenta($cTd) );
			$marco->insert('end', "$cTd $nmb\n", 'grupo' );
		  }
		$stD += $algo->[2];
		$stH += $algo->[3];
		$nCmp = $algo->[0];  # Numero comprobante
		$fecha = $ut->cFecha($algo->[10]);
		$tC = $algo->[11];
		$nulo = $algo->[12];
		$mntD = $mntH = $pesos->format_number(0);
		$mntD = $pesos->format_number( $algo->[2] ); 
		$tDebe += $algo->[2];
		$mntH = $pesos->format_number( $algo->[3] );
		$tHaber += $algo->[3];
		$ci = $dcm = $dt = '' ;
		if ($algo->[13]) {
			$dt = substr decode_utf8($algo->[13]) ,0,40 ;
		} 
		if ($Td) {
			$dcm = substr "$Td $algo->[7]",0,15 ;
		}
		if ( not ($ci eq '' ) ) {
			$dt = "$ci $dcm"; 
		}
		$mov = sprintf("%4s %-1s %10s %-40s %11s %11s  %-15s", $nCmp, $tC, 
			$fecha, $dt, $mntD, $mntH, $dcm ) ;
		$marco->insert('end', "$mov\n", 'detalle' ) ;
		}
	}
	$mntD = $mntH = $pesos->format_number(0);
	$mntD = $pesos->format_number( $stD );
	$mntH = $pesos->format_number( $stH );
	$marco->insert('end', "$movST\n", 'detalle' ) ;
#	$dt = $tabla{$aTd} ? "Subtotal $tabla{$aTd}" : "Subtotal" ;
	$dt = "Subtotal $aTd ";
	$mov = sprintf("%17s %40s %11s %11s",'',$dt,$mntD,$mntH ) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	$dt = "Saldo";
	$sst = $stD - $stH ;
	$mntD = $mntH = '';
	$mntD = $pesos->format_number( $sst ) if $sst > 0 ;
	$mntH = $pesos->format_number( -$sst ) if $sst < 0 ;				
	$mov = sprintf("%17s %40s %11s %11s",'',$dt,$mntD,$mntH ) ;
	$marco->insert('end', "$mov\n\n", 'detalle' ) ;	
	
	$marco->insert('end', "$movST\n", 'detalle' ) ;
	$dt = "Totales";
	$mntD = $pesos->format_number( $tDebe ); 
	$mntH = $pesos->format_number( $tHaber ); 
	$mov = sprintf("%4s %-1s %10s %-40s %11s %11s",'','','',$dt,$mntD,$mntH ) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	# Nuevo saldo
	$dt = "Saldo al $fechaUM";
	$mntD = $mntH = '';
	$mntD = $pesos->format_number($tDebe - $tHaber) if $tDebe > $tHaber ;
	$mntH = $pesos->format_number($tHaber - $tDebe) if $tDebe < $tHaber ;

	$mov = sprintf("%4s %-1s %10s %-40s %11s %11s",'','','',$dt,$mntD,$mntH ) ;
	$marco->insert('end', "$mov\n\n", 'detalle' ) ;

	$bImp->configure(-state => 'active');
}

sub txt ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');
	# Genera archivo de texto
	my $d = "$rutE/txt/cc$RUT.txt" ;
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Ver archivo '$d'"
}

sub csv ( $ ) 
{
	my ($esto) = @_;
	
	if ($Tipo eq "H") { csvH($esto) } else { csvP($esto) }
}

sub csvH ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	my ($tDebe,$tHaber,$fchI,$mntD,$mntH,$dt,$nCmp,$fecha,$tC,$nulo,$ci,$dcm,$d);

	my @datosCI = $bd->datosCI($RUT);
	my $saldoI = $datosCI[3];
	my $tSaldo = $datosCI[4];
	my $fechaUM = $datosCI[5];
	
	$d = "$rutE/csv/cc$RUT.csv" ;
	open ARCHIVO, "> $d" or die $! ;
	$l =  '"'."$empr  $cnf[0]".'"';
	print ARCHIVO "$l\n";
	$l = '"'."Cuenta Corriente  $Nombre  Rut: $RUT".'"';
	print ARCHIVO "$l\n";
	$l = "Comprobante";
	print ARCHIVO "$l\n";
	$l = "#,T,Fecha,Detalle,Debe,Haber,Documento";
	print ARCHIVO "$l\n";
	$tDebe = $tHaber = $mntD = $mntH = 0 ;
	if ( $tSaldo eq 'D') {
		$mntD = $saldoI; 
		$tDebe += $saldoI;
	}
	if ($tSaldo eq 'A') {
		$mntH = $saldoI;
		$tHaber += $saldoI;
	}
	$fchI = "01/01/$cnf[0]";
	$l = ",,$fchI,".'"'."Saldo inicial".'"'.",$mntD,$mntH" ;
	print ARCHIVO "$l\n";
	
	my @data = $bd->itemsCI($RUT,'CuentaM');
	my ($stD, $stH, $nmbC, $aTd, $Td );
	$nmbC = $aTd = '' ;
	foreach $algo ( @data ) {
		$cTd = $algo->[1] ;
		$Td = $algo->[6] ;
		if ( $cTd < 3000 ) {
		  if (not $cTd eq $aTd) {
			if (not $aTd eq '' ) {
				$dt = "Subtotal $aTd ";
				$l = ",,,$dt,$stD,$stH" ;
				print ARCHIVO "$l\n";
				$dt = "Saldo";
				$sst = $stD - $stH ;
				$mntD = $mntH = 0;
				$mntD =  $sst  if $sst > 0 ;
				$mntH =  -$sst  if $sst < 0 ;				
				$l = ",,,$dt,$mntD,$mntH" ;
				print ARCHIVO "$l\n\n";
			}
			$aTd = $cTd ;
			($stD, $stH) = (0,0);
			$nmb = $bd->nmbCuenta($cTd);
			print ARCHIVO "$cTd $nmb\n";
		  }	
		$stD += $algo->[2];
		$stH += $algo->[3];
		$nCmp = $algo->[0]; 
		$fecha = $ut->cFecha($algo->[10]);
		$tC = $algo->[11];
		$nulo = $algo->[12];
		$mntD = $mntH = 0;
		$mntD = $algo->[2] ; 
		$tDebe += $algo->[2];
		$mntH = $algo->[3] ;
		$tHaber += $algo->[3];
		$ci = $dcm = $dt = '' ;
		if ($algo->[13]) {
			$dt = decode_utf8($algo->[13]);
		} 
		if ($algo->[6]) {
			$dcm = "$algo->[6] $algo->[7]";
		}
		if ( not ($ci eq '' ) ) {
			$dt = "$ci $dcm"; 
		}
		$l = "$nCmp,$tC,$fecha,".'"'."$dt".'"'.",$mntD,$mntH,$dcm" ;
		print ARCHIVO "$l\n";
	  }
	}
	$dt = "Subtotal $aTd ";
	$l = ",,,$dt,$stD,$stH" ;
	print ARCHIVO "$l\n";
	$dt = "Saldo";
	$sst = $stD - $stH ;
	$mntD = $mntH = 0;
	$mntD =  $sst  if $sst > 0 ;
	$mntH =  -$sst  if $sst < 0 ;				
	$l = ",,,$dt,$mntD,$mntH" ;
	print ARCHIVO "$l\n\n";
	
	$l = ",,,Totales,$tDebe,$tHaber" ;
	print ARCHIVO "$l\n";
	$dt = '"'."Saldo al $fechaUM".'"';
	$mntD = $mntH = '';
	$mntD = $tDebe - $tHaber if $tDebe > $tHaber ;
	$mntH = $tHaber - $tDebe if $tDebe < $tHaber ;
	$l = ",,,$dt,$mntD,$mntH";
	print ARCHIVO "$l\n";

	close ARCHIVO ;
	$Mnsj = "Grabado en '$d'";
}

sub csvP ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	$ut->mError("Falta implementar");	
	
}

# Fin del paquete
1;
