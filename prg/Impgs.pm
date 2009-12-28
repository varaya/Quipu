#  Impgs.pm - Lista documentos impagos
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM: 28.12.2009

package Impgs;

use Tk::TList;
use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;
	
# Variables válidas dentro del archivo
my ($bImp,$bCan,$Mnsj,@cnf,$empr,$ord,$rutE, $tabla) ; 	
my @datos = () ;		# Lista de cuentas
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE, $arc) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	@cnf = $bd->leeCnf();
	$Cuenta = '';
	$rutE = $rtE ;
	$tabla = $arc ;
	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Documentos Impagos: $tabla");
	$vnt->geometry("640x430+475+4"); # Tamaño y ubicación
	# Define marco para mostrar resultado
	my $mtA = $vnt->Scrolled('Text', -scrollbars=> 'e', -bg=> 'white', -height=> 420 );
	$mtA->tagConfigure('negrita', -font => $tp{ng}) ;
	$mtA->tagConfigure('detalle', -font => $tp{fx}) ;
	$mtA->tagConfigure('grupo', -font => $tp{gr}, -foreground => 'brown') ;

	# Defime marcos
	my $mBotones = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'CMayor'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";

	# Define botones
	my $bLmp = $mBotones->Button(-text => "Muestra", 
		-command => sub { valida($esto,$mtA); } );
	$bImp = $mBotones->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mtA);} ],
 	  ['command' => "planilla", -command => sub { csv($esto);} ] ] );
	$bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); } );
		
	my $oR = $mBotones->Radiobutton( -text => "RUT", -variable => \$ord,
	-value => 'RUT' );
	my $oF = $mBotones->Radiobutton( -text => "Vencimiento", -variable => \$ord,
	-value => 'FechaV' );

	# Dibuja interfaz
	$oR->pack(-side => "left", -anchor => "e");
	$oF->pack(-side => "left", -anchor => "e");
	$bLmp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

	$mMensajes->pack(-expand => 1, -fill => 'both');
	$mBotones->pack(-expand => 1);
	$mtA->pack(-fill => 'both');
	
	# Inicialmente deshabilita botón Registra
	$bImp->configure(-state => 'disabled');
	
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
	if (not $ord) {
		$Mnsj = "Debe seleccionar un ordenamiento."; 
		return;
	} else {
		informe($esto,$mt,$ord);
	}
}

sub informe ( $ $ $ ) {

	my ($esto, $marco, $ord) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	$marco->delete('0.0','end');
	$marco->insert('end', "Documentos Impagos al \n\n", 'grupo');
	@data = $bd->datosImps($tabla,$ord);
	if (@data) {
		detalleR($marco, $ut) if $ord eq 'RUT';
		detalleV($marco, $ut) if $ord eq 'FechaV';
	} else {
		$marco->insert('end', "NO hay documentos pendientes\n\n", 'grupo');
		return :
	}
	$bImp->configure(-state => 'active');	
}

sub detalleR ( $ $ )
{
	my ($marco, $ut ) = @_;
	$marco->insert('end', "$tabla\n", 'grupo');
	my $lin1 = sprintf("%10s   %10s %12s %12s   %10s  %5s",'#','Fecha','Monto','Abonos','Saldo','Vence','Cmpr') ;
	my $lin2 = "-"x75;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	my ($algo,$fe,$fv,$nmr,$tt,$ab,$nulo,$cmp,$mov,$stt,$sab,$mnt,$tp,$mab,$msld,$sld,$rt);
	$stt = $sab = 0;
	my ($stR,$saR) = (0,0) ;
	my $art = '' ;
	foreach $algo ( @data ) {
		$rt = $algo->[10];
		if (not $rt eq $art) {
			if (not $art eq '') { # Aquí van los subtotales
				$mntR = $mntA = $mntS = $pesos->format_number(0);
				$mntR = $pesos->format_number( $stR );
				$mntA = $pesos->format_number( $saR );
				$mntS = $pesos->format_number( $stR - $saR );
				$dt = "Subtotal";
				$mov = sprintf("%23s %12s %12s %12s",$dt,$mntR,$mntA,$mntS ) ;
				$marco->insert('end', "$mov\n", 'detalle' ) ;				
			}
			($stR,$saR) = (0,0) ;
			$art = $rt ;
			$marco->insert('end', "$rt\n", 'grupo' );
		}	
		$fe =  $ut->cFecha($algo->[1]);
		$fv =  $ut->cFecha($algo->[4]);
		$nmr = $algo->[0];
		$mnt = $tabla eq 'BoletasH' ? $algo->[2] - $algo->[7] : $algo->[2] ;
		$tt = $pesos->format_number($mnt);
		$stt += $mnt ;
		$stR += $mnt ;
		$mab = $algo->[3] ;
		$ab = $pesos->format_number( $mab );
		$sab += $mab ;
		$saR += $mab ;
		$msld = $mnt - $mab ;
		$sld = $pesos->format_number( $msld );
		$nulo = $algo->[6];
		$cmp = $algo->[5];
		$tp = $tabla eq 'BoletasH' ? "  " : $algo->[8];
		$mov = sprintf("%2s %8s  %10s %12s %12s %12s  %10s  %5s",$tp,$nmr,$fe,$tt,$ab,$sld,$fv,$cmp) ;
		$marco->insert('end', "$mov\n", 'detalle' ) ;
	}
	$mntR = $mntA = $mntS = $pesos->format_number(0);
	$mntR = $pesos->format_number( $stR );
	$mntA = $pesos->format_number( $saR );
	$mntS = $pesos->format_number( $stR - $saR );
	$dt = "Subtotal";
	$mov = sprintf("%23s %12s %12s %12s",$dt,$mntR,$mntA,$mntS ) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;				

	$marco->insert('end',"$lin2\n",'detalle');
	$tt = $pesos->format_number($stt);
	$ab = $pesos->format_number($sab);
	my $sd = $pesos->format_number($stt - $sab);
	$mov = sprintf("%23s %12s %12s %12s",'Total',$tt,$ab,$sd) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	$marco->insert('end',"$lin2\n\n",'detalle') ;
}

sub detalleV ( $ $ )
{
	my ($marco, $ut ) = @_;
	$marco->insert('end', "$tabla\n", 'grupo');
	my $lin1 = sprintf("%10s   %10s %12s %12s   %10s  %5s",'#','Fecha','Monto','Abonos','Saldo','Vence','Cmpr') ;
	my $lin2 = "-"x75;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	my ($algo,$fe,$fv,$nmr,$tt,$ab,$nulo,$cmp,$mov,$stt,$sab,$mnt,$tp,$mab,$msld,$sld,$rt);
	$stt = $sab = $sld = 0;
	foreach $algo ( @data ) {
		$rt = $algo->[10];
		$fe =  $ut->cFecha($algo->[1]);
		$fv =  $ut->cFecha($algo->[4]);
		$nmr = $algo->[0];
		$mnt = $tabla eq 'BoletasH' ? $algo->[2] - $algo->[7] : $algo->[2] ;
		$tt = $pesos->format_number($mnt);
		$stt += $mnt ;
		$mab = $algo->[3] ;
		$ab = $pesos->format_number( $mab );
		$sab += $mab ;
		$msld = $mnt - $mab ;
		$sld = $pesos->format_number( $msld );
		$nulo = $algo->[6];
		$cmp = $algo->[5];
		$tp = $tabla eq 'BoletasH' ? "  " : $algo->[8];
		$mov = sprintf("%2s %8s  %10s %12s %12s %12s  %10s  %5s",$tp,$nmr,$fe,$tt,$ab,$sld,$fv,$rt) ;
		$marco->insert('end', "$mov\n", 'detalle' ) ;
	}
	$marco->insert('end',"$lin2\n",'detalle');
	$tt = $pesos->format_number($stt);
	$ab = $pesos->format_number($sab);
	my $sd = $pesos->format_number($stt - $sab);
	$mov = sprintf("%23s %12s %12s %12s",'Total',$tt,$ab,$sd) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	$marco->insert('end',"$lin2\n\n",'detalle') ;
}

sub txt ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');

	# Genera archivo de texto
	my $d ;
	$d = "$rutE/txt/ir$tabla.txt"  if $ord eq 'RUT' ;
	$d = "$rutE/txt/iv$tabla.txt"  if $ord eq 'FechaV' ;
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;

	$Mnsj = "Ver archivo '$d'";
}

sub csv (  )
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	$ut->mError("Falta implementar");	
return ;
	# Datos cuenta
	foreach $algo ( @datos ) {
		if ( $Cuenta == $algo->[1]) {
			$nmC = decode_utf8($algo->[0]);
			$saldoI = $algo->[4];
			$tSaldo = $algo->[5];
			$fechaUM = $algo->[6]; 
			last if $Cuenta == $algo->[1] ;		
		} 
	}
	my @data = $bd->itemsM($Cuenta,$mes);
	
	my ($tDebe,$tHaber,$fchI,$mntD,$mntH,$dt,$nCmp,$fecha,$tC,$nulo,$ci,$dcm,$d,$siDebe,$siHaber);
	$d = "$rutE/csv/myr$Cuenta.csv";
	open ARCHIVO, "> $d" or die $! ;
	$l =  '"'."$empr".'"';
	print ARCHIVO "$l\n";
	$l =  '"'."Libro Mayor  $cnf[0]  $nMes".'"';
	print ARCHIVO "$l\n";
	$l = '"'."Cuenta: $Cuenta - $nmC".'"';
	print ARCHIVO "$l\n";
	$l = "Comprobante";
	print ARCHIVO "$l\n";
	$l = "#,T,Fecha,Detalle,Debe,Haber";
	print ARCHIVO "$l\n";

	$tDebe = $tHaber = $mntD = $mntH =  $siDebe = $siHaber = 0 ;
	if ( $tSaldo eq 'D') {
		$mntD = $saldoI; 
		$siDebe += $saldoI;
	}
	if ($tSaldo eq 'A') {
		$mntH = $saldoI;
		$siHaber += $saldoI;
	}
	$fchI = "01/01/$cnf[0]";
	$l = ",,$fchI,".'"'."Saldo inicial".'"'.",$mntD,$mntH" ;
	print ARCHIVO "$l\n";
	
	foreach $algo ( @data ) {
		$nCmp = $algo->[0];  # Numero comprobante
		$fecha = $ut->cFecha($algo->[10]);
		$tC = $algo->[11];
		$nulo = $algo->[12];
		$mntD = $mntH = 0;
		$mntD = $algo->[2]; 
		$tDebe += $algo->[2];
		$mntH = $algo->[3] ;
		$tHaber += $algo->[3];
		$ci = $dcm = $dt = '' ;
		if ($algo->[4]) {
			$dt = decode_utf8($algo->[4]);
		} 
		if ($algo->[5]) {
			$ci = "RUT $algo->[5]";
		}
		if ($algo->[6]) {
			$dcm = "$algo->[6] $algo->[7]";
		}
		if ( not ($ci eq '' ) ) {
			$dt = "$ci $dcm"; 
		}
		$l = "$nCmp,$tC,$fecha,".'"'."$dt".'"'.",$mntD,$mntH" ;
		print ARCHIVO "$l\n";
	}
	$l = ",,,Totales mes,$tDebe,$tHaber" ;
	print ARCHIVO "$l\n";
	$dt = '"'."Saldo $mes".'"';
	$mntD = $mntH = '';
	$mntD = $tDebe - $tHaber if $tDebe > $tHaber ;
	$mntH = $tHaber - $tDebe if $tDebe < $tHaber ;
	$l = ",,,$dt,$mntD,$mntH";
	print ARCHIVO "$l\n";
	my ($TotalD,$TotalH) = $bd->totales($Cuenta,$mes);
	$TotalD += $siDebe ;
	$TotalH += $siHaber ;
	$l = ",,,Totales acumulados,$TotalD,$TotalH" ;
	print ARCHIVO "$l\n";
	$dt = "Saldo acumulado";
	$mntD = $mntH = '';
	$mntD = $TotalD - $TotalH if $TotalD > $TotalH ;
	$mntH = $TotalH - $TotalD if $TotalD < $TotalH ;
	$l = ",,,$dt,$mntD,$mntH";
	print ARCHIVO "$l\n";

	close ARCHIVO ;
	$Mnsj = "Grabado en '$d'";
}

# Fin del paquete
1;
