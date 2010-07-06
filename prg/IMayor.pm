#  IMayor.pm - Imprime cuenta de mayor entre fechas
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2010 [varayar@gmail.com]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM: 05.07.2010

package IMayor;

use Tk::TList;
use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;
	
# Variables válidas dentro del archivo
my ($bCan,$bLpr,$fechaF,$fechaI,$Mnsj,$CuentaI,$CuentaF,$ejerc,$empr,$rutE) ;
my ($FechaI,$FechaIA,$FechaF,$cuentaI,$cuentaF) ; 	
my @datos = () ;		# Lista de cuentas
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE, $prd) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	$ejerc = $prd ;
	$CuentaI = $CuentaF = '';
	$rutE = $rtE ;
	$FechaI = "01/01/$ejerc";
	$FechaIA = "01/01/$ejerc";
	$FechaF = $ut->fechaHoy();

	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Imprime Libro Mayor entre Fechas");
	$vnt->geometry("550x90+475+4"); # Tamaño y ubicación

	# Defime marcos
	my $mCmnds = $vnt->Frame(-borderwidth => 1);
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
	
	$cuentaI = $mCmnds->LabEntry(-label => "   Cuentas: Inicio ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CuentaI );
	$cuentaF = $mCmnds->LabEntry(-label => " Fin ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$CuentaF );

	# Define opciones de seleccion
	$fechaI = $mCmnds->LabEntry(-label => "Inicial ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaI );
	$fechaF = $mCmnds->LabEntry(-label => "  Final ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaF );
	# Define botones
	$bLpr = $mBotones->Button(-text => "Imprime", 
		-command => sub { valida($esto); } );
	$bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); } );

	# Dibuja interfaz
	$fechaI->pack(-side => "left", -anchor => "w");
	$fechaF->pack(-side => "left", -anchor => "w");
	$cuentaI->pack(-side => 'left', -expand => 0, -fill => 'none');
	$cuentaF->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bLpr->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

	$mMensajes->pack(-expand => 1, -fill => 'both');
	$mCmnds->pack(-expand => 1);
	$mBotones->pack(-expand => 1);
	
	$mt->delete('0.0','end');
	muestraLista($esto,$mt);
	$fechaI->focus;
	
	bless $esto;
	return $esto;
}

sub valida ( $ ) 
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my ($fi, $ff);
	$Mnsj = '' ;
	# Verifica cuenta
	if ($CuentaI eq '' ) {		
		$Mnsj = "Indique primera cuenta."; 
		$cuentaI->focus;
		return;
	}	
	if ($CuentaF eq '' ) {		
		$Mnsj = "Indique última cuenta."; 
		$cuentaF->focus;
		return;
	}	
	# Fecha inicial
	if ( $FechaI eq '' ) {
		$Mnsj = "Debe colocar fecha de inicio"; 
		$fechaI->focus;
		return 
	}
	# Comprueba si la fecha está escrita correctamente
	if (not $FechaI =~ m|\d+/\d+/\d+|) {
		$Mnsj = "Formato fecha es dd/mm/aaaa";
		$fechaI->focus;
	} elsif ( not $ut->analizaFecha($FechaI) ) {
		$Mnsj = "Fecha incorrecta" ;
		$fechaI->focus ;
	}
	# Fecha final
	if ( $FechaF eq '' ) {
		$Mnsj = "Debe colocar fecha final"; 
		$fechaI->focus;
		return 
	}
	# Comprueba si la fecha está escrita correctamente
	if (not $FechaF =~ m|\d+/\d+/\d+|) {
		$Mnsj = "Formato fecha es dd/mm/aaaa";
		$fechaF->focus;
	} elsif ( not $ut->analizaFecha($FechaF) ) {
		$Mnsj = "Fecha incorrecta" ;
		$fechaF->focus ;
	}
	# Compara fechas
	$fi = $ut->analizaFecha($FechaI);
	$ff = $ut->analizaFecha($FechaF);
	if ($fi > $ff) {
		$Mnsj = "Fecha final es anterior a la inicial.";
		$fechaI->focus;
		return;
	}
	# Si todo está bien, graba informe
	graba($esto,$fi,$ff);
}

sub muestraLista ( $ $ ) 
{
	my ($esto,$mt) = @_;
	my $bd = $esto->{'baseDatos'};
	
	# Obtiene lista de cuentas con movimiento
	@datos = $bd->datosCcM();

	# Completa TList con nombres de los cuentas
	my ($algo,$nm,$TotalD,$TotalH);
	$mt->insert('end',"Cuentas con saldo\n",'detalle');
	foreach $algo ( @datos ) {
		$nm = sprintf("%-5s %-30s", $algo->[1], decode_utf8($algo->[0]) ) ;
		$mt->insert('end', "$nm\n", 'detalle' ) ;
	}
}

sub graba ( $ $ $ )
{
	my ($esto, $fi, $ff) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	my ($saldoI,$tSaldo,$fechaUM,$tipoCta);
	# Datos cuenta
	foreach $algo ( @datos ) {
		if ( $Cuenta eq $algo->[1]) {
			$nmC = decode_utf8($algo->[0]);
			$saldoI = $algo->[4];
			$tSaldo = $algo->[5];
			$fechaUM = $algo->[6]; 
			$tipoCta = $algo->[7];
			last if $Cuenta eq $algo->[1] ;		
		} 
	}
	if ( not $nmC ) {
		$Mnsj = "Cuenta no existe o sin movimientos";
		return ;
	}
	
	my @datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 
	$marco->delete('0.0','end');
	$marco->insert('end', "$empr\n", 'negrita');
	$marco->insert('end', "Libro Mayor  $ejerc del $FechaI al $FechaF\n", 'negrita');
	$marco->insert('end', "Cuenta: $Cuenta - $nmC\n\n" , 'grupo');
	$marco->insert('end', "Comprobante\n" , 'detalle');

	my @data = $bd->itemsMF($Cuenta,$fi,$ff);
	my $frm = "%4s %-1s  %10s  %-35s %13s %13s %-15s" ;
	my ($algo,$mov,$nCmp,$mntD,$mntH,$dt,$ci,$tDebe,$tHaber,$dcm,$siDebe,$siHaber);
	my($tC, $fecha, $nulo, $glosaC );
	my $lin1 = "   # T  Fecha       Detalle                               ";
	$lin1 .= "      Debe         Haber";
	my $lin2 = "-"x83;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	$tDebe = $tHaber = $siDebe = $siHaber = 0 ;
	my $diaA = $ut->diaAnterior($fi);
	$dt = "Saldo al $FechaIA";
	my $fa = $ut->analizaFecha($diaA);
	my $fia = $ut->analizaFecha($FechaIA);
	if ( $fa > $fia ) {
		$dt = "Acumulado al $diaA";
		($siDebe, $siHaber) = $bd->totalesF($Cuenta,$fia,$fa) ;
	}
	$mntD = $mntH = $pesos->format_number(0);
	if ( $tSaldo eq 'D') {
		$siDebe += $saldoI;
	}
	if ($tSaldo eq 'A') {
		$siHaber += $saldoI;
	}
	$mntH = $pesos->format_number( $siHaber );
	$mntD = $pesos->format_number( $siDebe ); 
	$mov = sprintf($frm, '','',"",$dt,$mntD,$mntH,'') ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	foreach $algo ( @data ) {
		$nCmp = $algo->[0];  # Numero comprobante
		$fecha = $ut->cFecha($algo->[10]);
		$tC = $algo->[11];
		$nulo = $algo->[12];
		$glosaC = $algo->[13];
		$mntD = $mntH = $pesos->format_number(0);
		$mntD = $pesos->format_number( $algo->[2] ); 
		$tDebe += $algo->[2];
		$mntH = $pesos->format_number( $algo->[3] );
		$tHaber += $algo->[3];
		$ci = $dcm = $dt = '' ;
		if ($algo->[4]) {
			$dt = substr decode_utf8($algo->[4]),0,35 ;
		} 
		if ($algo->[6]) {
			my $tabla = 'Compras' ;
			$dcm = $bd->buscaDP($algo->[5], $algo->[7], $tabla);
			if ($tipoCta eq 'B') {
				$dcm = " $algo->[6] $algo->[7]";
			}
		}
		$dt = "$glosaC " if $dt eq '' ; 
		$mov = sprintf($frm, $nCmp, $tC, $fecha, $dt, $mntD, $mntH, $dcm ) ;
		$marco->insert('end', "$mov\n", 'detalle' ) ;
	}
	$marco->insert('end',"$lin2\n",'detalle');
	$dt = "Totales período";
	$mntD = $pesos->format_number( $tDebe ); 
	$mntH = $pesos->format_number( $tHaber ); 
	$mov = sprintf($frm,'','','',$dt,$mntD,$mntH,'') ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	# Nuevo saldo
	$dt = "Saldo ";
	$mntD = $mntH = '';
	$mntD = $pesos->format_number($tDebe - $tHaber) if $tDebe > $tHaber ;
	$mntH = $pesos->format_number($tHaber - $tDebe) if $tDebe < $tHaber ;
	$marco->insert('end',"$lin2\n",'detalle');
	$mov = sprintf($frm,'','','',$dt,$mntD,$mntH,'') ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	my ($TotalD,$TotalH) = $bd->totalesF($Cuenta,$fi,$ff);
	$TotalD += $siDebe ;
	$TotalH += $siHaber ;
	$marco->insert('end',"$lin2\n",'detalle');
	$dt = "Totales acumulados al $FechaF";
	$mntD = $pesos->format_number( $TotalD ); 
	$mntH = $pesos->format_number( $TotalH ); 
	$mov = sprintf($frm,'','','',$dt,$mntD,$mntH,'') ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;

	$dt = "Saldo acumulado";
	$mntD = $mntH = '';
	$mntD = $pesos->format_number($TotalD - $TotalH) if $TotalD > $TotalH ;
	$mntH = $pesos->format_number($TotalH - $TotalD) if $TotalD < $TotalH ;
	
	$mov = sprintf("%4s %-1s  %10s  %-35s %13s %13s",'','','',$dt,$mntD,$mntH ) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	
	$bImp->configure(-state => 'active');
	$bLpr->configure(-state => 'active');
}

sub imp ( $ )
{
	my ($marco) = @_;	
	my ($algo,$enca,$d,$m,$ln) ;
	
	$algo = $marco->get('0.0','end');
	$ln = 1 ;
	$enca = "\n";
	while ($ln < 8 ) {
		$enca = $enca . "    " . $marco->get("$ln.0","$ln.end") . "\n";
		$ln++ ;
	}
	$d = "$rutE/txt/myr$Cuenta.txt" ;
	$m = "$rutE/txt/mayor.txt" ;
	
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	open MAYOR, "> $m" or die $! ;
	open ARCHIVO, "$d" ;
	
	$ln = 1 ;
	print MAYOR "\n";
	while ( <ARCHIVO> ) {
		print MAYOR "    $_";
		$linea++ ;
		if ($linea == 60) {
			print MAYOR chr 12 ;
			print MAYOR "$enca \n";
			$linea = 8 ;
		}
	}
	print MAYOR chr 12 ;
	close MAYOR ;
	$Mnsj = "Imprimiendo";
#	system "lp -o cpi=16 $m";
}

# Fin del paquete
1;
