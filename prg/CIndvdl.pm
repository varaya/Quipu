#  CIndvdl.pm - Consulta e imprime Cuenta Invididual
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM : 10.08.2009

package CIndvdl;

use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
my ($Mnsj, $rut, $RUT, @cnf, $empr, $Tipo, $Nombre, $rutE) ;	# Variables
my @lMeses = () ;
my @datos = () ;
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
	$vnt->geometry("690x380+40+150"); 
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
	my ($nmb,$cl,$pr,$sc,$hn,$tbl) = (decode_utf8($info[0]),$info[1],$info[2],$info[3],$info[4],'');
	$tbl = "Ventas" if $cl ;
	$tbl = "Compras" if $pr ;
	$tbl = "BoletasH" if $hn ;
	my @data = $bd->datosFacts($RUT,$tbl,1);
	
	if (not @data) {
		$Mnsj = "NO hay datos para $nmb";
		return ;
	}
	$marco->insert('end', "Documentos Pendientes $nmb  Rut: $RUT\n\n", 'grupo');
	$marco->insert('end', "$tbl\n", 'grupo');
	my $lin1 = sprintf("%10s  %10s %12s %12s  %10s  %5s",'#','Fecha','Monto','Abonos','Vence','Cmpr') ;
	my $lin2 = "-"x67;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	my ($algo,$fe,$fv,$nmr,$tt,$ab,$nulo,$cmp,$mov,$stt,$sab,$mnt);
	$stt = $sab = 0;
	foreach $algo ( @data ) {
		$fe =  $ut->cFecha($algo->[1]);
		$fv =  $ut->cFecha($algo->[4]);
		$nmr = $algo->[0];
		$mnt = $hn ? $algo->[2] - $algo->[7] : $algo->[2] ;
		$tt = $pesos->format_number($mnt);
		$stt += $mnt ;
		$ab = $pesos->format_number($algo->[3]);
		$sab += $algo->[3] ;
		$nulo = $algo->[6];
		$cmp = $algo->[5];
		$mov = sprintf("%10s  %10s %12s %12s  %10s  %5s",$nmr,$fe,$tt,$ab,$fv,$cmp) ;
		$marco->insert('end', "$mov\n", 'detalle' ) ;
	}
	$marco->insert('end',"$lin2\n",'detalle');
	$tt = $pesos->format_number($stt);
	$ab = $pesos->format_number($sba) if $sab ;
	$mov = sprintf("%10s  %10s %12s %12s",'','',$tt,$ab) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	$marco->insert('end',"$lin2\n\n",'detalle') ;

	$bImp->configure(-state => 'active');	
}

sub informeH ( $ $ ) {

	my ($esto, $marco) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	my @data = $bd->itemsCI($RUT);
	$Mnsj = " ";
	if (not @data) { 
		$Mnsj = "No hay datos para $Nombre"; 
		return;
	}
	my ($algo,@datosE,@datosCI,$tC,$fecha,$nulo,$tDebe,$tHaber,$mntD,$mntH,$cTd);
	@datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 
	@datosCI = $bd->datosCI($RUT);
	my $saldoI = $datosCI[3];
	my $tSaldo = $datosCI[4];
	my $fechaUM = $datosCI[5];
	my $lst = "-"x54 ;
	my $movST = sprintf("%17s %-52s",'',$lst) ;
	$marco->insert('end', "$empr  $cnf[0]\n", 'negrita');
	$marco->insert('end', "Cuenta Corriente $Nombre  Rut: $RUT\n\n", 'grupo');
	$marco->insert('end', "Comprobante\n" , 'detalle');
	my $lin1 = "   # T Fecha      Glosa                                 ";
	$lin1 .= "Debe       Haber  Documento";
	my $lin2 = "-"x83;
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
	$mov = sprintf("%4s %-1s %10s %-30s %11s %11s",
		'','',"01/01/$cnf[0]",$dt,$mntD,$mntH) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
#	$marco->insert('end',"$lin2\n",'detalle');
	my $aTd = '' ;
	my ($stD, $stH);
	foreach $algo ( @data ) {
		$cTd = $algo->[6] ;
		if (not $cTd eq $aTd) {
			if (not $aTd eq '' ) {
				$mntD = $mntH = $pesos->format_number(0);
				$mntD = $pesos->format_number( $stD );
				$mntH = $pesos->format_number( $stH );
				$marco->insert('end', "$movST\n", 'detalle' ) ;
				$dt = "Subtotal $tabla{$aTd}";
				$mov = sprintf("%17s %30s %11s %11s",'',$dt,$mntD,$mntH ) ;
				$marco->insert('end', "$mov\n", 'detalle' ) ;
			}
			$aTd = $cTd ;
			($stD, $stH) = (0,0);
			$marco->insert('end', "$tabla{$cTd}\n", 'grupo' ) ;
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
			$dt = decode_utf8($algo->[13]);
		} 
		if ($cTd) {
			$dcm = substr "$algo->[7]",0,20 ;
		}
		if ( not ($ci eq '' ) ) {
			$dt = "$ci $dcm"; 
		}
		$mov = sprintf("%4s %-1s %10s %-30s %11s %11s  %-20s", $nCmp, $tC, 
			$fecha, $dt, $mntD, $mntH, $dcm ) ;
		$marco->insert('end', "$mov\n", 'detalle' ) ;
	}
	$mntD = $mntH = $pesos->format_number(0);
	$mntD = $pesos->format_number( $stD );
	$mntH = $pesos->format_number( $stH );
	$marco->insert('end', "$movST\n", 'detalle' ) ;
	$dt = "Subtotal $tabla{$aTd}";
	$mov = sprintf("%17s %30s %11s %11s",'',$dt,$mntD,$mntH ) ;
	$marco->insert('end', "$mov\n\n", 'detalle' ) ;
	$marco->insert('end', "$movST\n", 'detalle' ) ;
	$dt = "Totales";
	$mntD = $pesos->format_number( $tDebe ); 
	$mntH = $pesos->format_number( $tHaber ); 
	$mov = sprintf("%4s %-1s %10s %-30s %11s %11s",'','','',$dt,$mntD,$mntH ) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	# Nuevo saldo
	$dt = "Saldo al $fechaUM";
	$mntD = $mntH = '';
	$mntD = $pesos->format_number($tDebe - $tHaber) if $tDebe > $tHaber ;
	$mntH = $pesos->format_number($tHaber - $tDebe) if $tDebe < $tHaber ;

	$mov = sprintf("%4s %-1s %10s %-30s %11s %11s",'','','',$dt,$mntD,$mntH ) ;
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
	
	my @data = $bd->itemsCI($RUT);
	my $aTd = '' ;
	my ($stD, $stH, $cTd);
	foreach $algo ( @data ) {
		$cTd = $algo->[6] ;
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
			$dcm = "$algo->[7]";
		}
		if ( not ($ci eq '' ) ) {
			$dt = "$ci $dcm"; 
		}
		$l = "$nCmp,$tC,$fecha,".'"'."$dt".'"'.",$mntD,$mntH,$dcm" ;
		print ARCHIVO "$l\n";
	}
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
