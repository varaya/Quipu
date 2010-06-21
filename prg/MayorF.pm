#  MayorF.pm - Procesa cuenta de mayor entre fechas
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2010 [varayar@gmail.com]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM: 21.06.2010

package MayorF;

use Tk::TList;
use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;
	
# Variables válidas dentro del archivo
my ($bImp,$bCan,$fechaF,$fechaI,$Mnsj,$Cuenta,$ejerc,$empr,$rutE,$FechaI,$FechaF,$cuenta) ; 	
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
	$Cuenta = '';
	$rutE = $rtE ;
#	$FechaI = $FechaF = "";
	$FechaI = "01/01/$ejerc";
	$FechaF = $ut->fechaHoy();

	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Procesa Libro Mayor entre Fechas");
	$vnt->geometry("720x430+475+4"); # Tamaño y ubicación
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
	
	$cuenta = $mBotones->LabEntry(-label => "Cuenta: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Cuenta );
	# Define opciones de seleccion
	$fechaI = $mBotones->LabEntry(-label => "Inicial ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaI );
	$fechaF = $mBotones->LabEntry(-label => "Final ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaF );
	# Define botones
	my $bLmp = $mBotones->Button(-text => "Muestra", 
		-command => sub { valida($esto,$mtA); } );
	$bImp = $mBotones->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mtA);} ],
 	  ['command' => "planilla", -command => sub { csv($esto);} ] ] );
	$bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); } );

	# Dibuja interfaz
	$cuenta->pack(-side => 'left', -expand => 0, -fill => 'none');
	$fechaI->pack(-side => "left", -anchor => "w");
	$fechaF->pack(-side => "left", -anchor => "w");
	$bLmp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

	$mMensajes->pack(-expand => 1, -fill => 'both');
	$mBotones->pack(-expand => 1);
	$mtA->pack(-fill => 'both');
	
	# Inicialmente deshabilita botón Registra
	$bImp->configure(-state => 'disabled');
	$mt->delete('0.0','end');
	muestraLista($esto,$mt);
	$cuenta->focus;
	
	bless $esto;
	return $esto;
}

sub valida ( $ ) 
{
	my ($esto,$mt) = @_;
	my $ut = $esto->{'mensajes'};
	my ($fi, $ff);
	$Mnsj = '' ;
	# Verifica cuenta
	if ($Cuenta eq '' ) {		
		$Mnsj = "Indique una cuenta."; 
		$cuenta->focus;
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
	# Si todo está bien, muestra informe
	muestraM($esto,$mt,$fi,$ff);
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

sub resumen ( $ $ ) 
{
	my ($esto, $m) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};

	my ($algo,$cd,$nm,$sldI,$tSld,$siD,$siH,$lin,$mntD,$mntH,$gtD,$gtH,$msd);
	($gtD,$gtH) = (0,0);
	foreach $algo ( @datos ) {
		$cd = $algo->[1] ;
		$sldI = $algo->[4];
		$tSld = $algo->[5];
		$siD = $siH = $sd = 0 ;
		$nm = substr decode_utf8($algo->[0]),0,35 ;
		$siD += $sldI if $tSld eq 'D';
		$siH += $sldI if $tSld eq 'A';
		($TotalD,$TotalH) = $bd->totalesF($cd,$fi,$ff);
		$TotalD += $siD ;
		$TotalH += $siH ;
		if ($TotalD + $TotalH > 0) {
			$sd = $TotalD - $TotalH ;
			$gtD += $TotalD ;
			$gtH += $TotalH ;
			$mntD = $mntH = $msd = $pesos->format_number(0);
			$mntD = $pesos->format_number( $TotalD ); 
			$mntH = $pesos->format_number( $TotalH );
			$msd = $pesos->format_number( $TotalD - $TotalH );
			$lin = sprintf("%-5s %-35s  %11s  %11s %11s", $cd,$nm,$mntD,$mntH,$msd);
			$m->insert('end', "$lin\n", 'detalle' ) ;
		}
	}
	$mntD = $mntH = $pesos->format_number(0);
	$mntD = $pesos->format_number( $gtD ); 
	$mntH = $pesos->format_number( $gtH ); 
	$lin = sprintf("%-5s %-35s  %11s  %11s ", '', 'Totales', $mntD, $mntH);
	$m->insert('end', "$lin\n", 'detalle' ) ;

}

sub muestraM ( $ $ $ $)
{
	my ($esto, $marco, $fi, $ff) = @_;
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
	$dt = "Saldo inicial";
	$mntD = $mntH = $pesos->format_number(0);
	if ( $tSaldo eq 'D') {
		$mntD = $pesos->format_number( $saldoI ); 
		$siDebe += $saldoI;
	}
	if ($tSaldo eq 'A') {
		$mntH = $pesos->format_number( $saldoI );
		$siHaber += $saldoI;
	}
	$mov = sprintf($frm, '','',"01/01/$ejerc",$dt,$mntD,$mntH,'') ;
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
	$dt = "Totales";
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
	$dt = "Totales acumulados";
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
}

sub txt ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');

	# Genera archivo de texto
	my $d = "$rutE/txt/myr$Cuenta.txt" ;
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;

	$Mnsj = "Ver archivo '$d'";
}

sub csv ( )
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	
	my $fi = $ut->analizaFecha($FechaI);
	my $ff = $ut->analizaFecha($FechaF);
	# Datos cuenta
	foreach $algo ( @datos ) {
		if ( $Cuenta == $algo->[1]) {
			$nmC = decode_utf8($algo->[0]);
			$saldoI = $algo->[4];
			$tSaldo = $algo->[5];
			$fechaUM = $algo->[6]; 
			$tipoCta = $algo->[7];
			last if $Cuenta == $algo->[1] ;		
		} 
	}
	print "$fi - $ff \n";
	my @data = $bd->itemsMF($Cuenta,$fi,$ff);
	
	my ($tDebe,$tHaber,$fchI,$mntD,$mntH,$dt,$nCmp,$fecha,$tC,$nulo,$ci,$dcm,$d,$siDebe,$siHaber);
	$d = "$rutE/csv/myr$Cuenta.csv";
	open ARCHIVO, "> $d" or die $! ;
	$l =  '"'."$empr".'"';
	print ARCHIVO "$l\n";
	$l =  '"'."Libro Mayor  $ejerc ".'"';
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
	$fchI = "01/01/$ejerc";
	$l = ",,$fchI,".'"'."Saldo inicial".'"'.",$mntD,$mntH" ;
	print ARCHIVO "$l\n";
	
	foreach $algo ( @data ) {
		$nCmp = $algo->[0];  # Numero comprobante
		$fecha = $ut->cFecha($algo->[10]);
		$tC = $algo->[11];
		$nulo = $algo->[12];
		$glosaC = $algo->[13];
		$mntD = $mntH = 0;
		$mntD = $algo->[2]; 
		$tDebe += $algo->[2];
		$mntH = $algo->[3] ;
		$tHaber += $algo->[3];
		$ci = $dcm = $dt = '' ;
		if ($algo->[4]) {
			$dt = substr decode_utf8($algo->[4]),0,32 ;
		} 
		if ($algo->[6]) {
			my $tabla = 'Compras' ;
			$dcm = $bd->buscaDP($algo->[5], $algo->[7], $tabla);
			if ($tipoCta eq 'B') {
				$dcm = " $algo->[6] $algo->[7]";
			}
		}
		$dt = "$glosaC " if $dt eq '' ; 
		$l = "$nCmp,$tC,$fecha,".'"'."$dt".'"'.",$mntD,$mntH" ;
		print ARCHIVO "$l\n";
	}
	$l = ",,,Totales mes,$tDebe,$tHaber" ;
	print ARCHIVO "$l\n";
	$dt = '"'."Saldo al $FechaF".'"';
	$mntD = $mntH = '';
	$mntD = $tDebe - $tHaber if $tDebe > $tHaber ;
	$mntH = $tHaber - $tDebe if $tDebe < $tHaber ;
	$l = ",,,$dt,$mntD,$mntH";
	print ARCHIVO "$l\n";
	my ($TotalD,$TotalH) = $bd->totalesF($Cuenta,$fi,$ff);
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
