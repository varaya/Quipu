#  Diario.pm - Consulta e imprime Libro Diario
#  Forma parte del programa Quipu
#
#  Derechos de Autor: V�ctor Araya R., 2009 [varayar@gmail.com]
#  
#  Puede ser utilizado y distribuido en los t�rminos previstos en la 
#  licencia incluida en este paquete
#  UM: 06.07.2010

package Diario;

use Tk::TList;
use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;

# Variables v�lidas dentro del archivo
my ($FechaI, $FechaF, $tc, $Mnsj, $ejerc, $rutE, $tgD, $tgH) ;	# Variables
my ($fechaI, $fechaF) ; # Campos
my $totalItemes ;
my ($bCan, $bImp) ; # Botones
# Formato de n�meros
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE, $prd) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	$ejerc = $prd ;
	$rutE = $rtE ;
	$FechaI = "1/1/$ejerc";
	$FechaF = $ut->fechaHoy();
	$tc->{'I'} = 'Ingreso';
	$tc->{'E'} = 'Egreso';
	$tc->{'T'} = 'Traspaso';

	# Define ventanas
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Libro Diario");
	$vnt->geometry("600x450+390+100"); 
	# Define marco para mostrar resultado
	my $mtA = $vnt->Scrolled('Text', -scrollbars=> 'e', -bg=> 'white', -height=> 420 );
	$mtA->tagConfigure('negrita', -font => $tp{ng}) ;
	$mtA->tagConfigure('detalle', -font => $tp{fx}) ;

	# Define marcos
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y bot�n de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Diario'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione bot�n 'i'.";
	
	# Define opciones de seleccion
	$fechaI = $mBotonesC->LabEntry(-label => "Fechas:  Inicial ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaI );
	$fechaF = $mBotonesC->LabEntry(-label => "Final ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaF );
	
	# Define botones
	$bMst = $mBotonesC->Button(-text => "Muestra", 
		-command => sub { &valida($esto, $mtA) } );
	$bImp = $mBotonesC->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mtA);} ],
 	  ['command' => "planilla", -command => sub { csv($esto);} ] ] );
	$bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); } );
	
	# Dibuja interfaz
	$fechaI->pack(-side => 'left', -expand => 0, -fill => 'none');
	$fechaF->pack(-side => 'left', -expand => 0, -fill => 'none');

	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bMst->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mMensajes->pack(-expand => 1, -fill => 'both');
	$mBotonesC->pack();
	$mtA->pack(-fill => 'both');

	$bImp->configure(-state => 'disabled');
	$mtA->delete('0.0','end');

	bless $esto;
	return $esto;
}

# Funciones internas
sub valida ( $ ) 
{
	my ($esto,$mt) = @_;
	my $ut = $esto->{'mensajes'};
	my ($fi, $ff);
	
	# Fecha inicial
	if ( $FechaI eq '' ) {
		$Mnsj = "Debe colocar fecha de inicio"; 
		$fechaI->focus;
		return 
	}
	# Comprueba si la fecha est� escrita correctamente
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
	# Comprueba si la fecha est� escrita correctamente
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
	$TotalItemes = 0 ;
	$tgD = $tgH = 0;
	# Si todo est� bien, muestra informe
	informe($esto,$mt,$fi,$ff);
}

sub informe ( $ $  $) {

	my ($esto, $marco, $fi, $ff) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};
	my ($Numero, $Tipo, $Fecha, $Total, $Glosa, $Nulo, $Ref) = (0 .. 6);

	$fi = substr $fi,0,8 ;
	$ff = substr $ff,0,8 ;
	my @datosC = $bd->diario($fi,$ff);
	$Mnsj = " ";
	if (not @datosC) { 
		$Mnsj = "No hay datos para esas fechas"; 
		$fechaI->focus;
		return;
	}
	my ($algo,$nm,$tp,$fch,$ttD,$ttH,$gl,$empr,$ref,@datosE);
	@datosE = $bd->datosEmpresa($rutE);
	if (@datosE) {
		$empr = decode_utf8($datosE[0]); 
	}
	$marco->delete('0.0','end');
	$marco->insert('end', "Libro Diario  $ejerc  -  $empr\n", 'negrita');
	my $lin1 = "\nFecha      Detalle                            C�digo        Debe        Haber";
	my $lin2 = "-"x80;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	foreach $algo ( @datosC ) {
		$nm = $algo->[$Numero]; 
		$tipoC = $tc->{$algo->[$Tipo]}; 
		$fch = $ut->cFecha($algo->[$Fecha]); 
		$tt = $pesos->format_number( $algo->[$Total] );
		$gl = decode_utf8($algo->[$Glosa]);
		$ref = $algo->[$Ref] ;
		$gl = "Anulado por Comprobante $ref" if $algo->[$Nulo] ;
		$marco->insert('end', "\n$fch -------- $tipoC # $nm --------\n", 'detalle');
		asiento($bd, $marco, $nm, $tt, $gl);	
	}
	$ttD = $pesos->format_number( $tgD );
	$ttH = $pesos->format_number( $tgH );
	$marco->insert('end',"$lin2\n",'detalle');
	$mov1 = sprintf("           %-35s %-5s %12s  %12s", 'Totales', '', $ttD, $ttH) ;
	$marco->insert('end', "$mov1\n", 'detalle' ) ;
	$marco->insert('end',"$lin2\n",'detalle');
	$mov1 = "Total: $totalItemes ";
	$marco->insert('end', "$mov1\n", 'detalle' ) ;
	$bImp->configure(-state => 'active');
}

sub asiento ( $ $ $ $ $ ) {

	my ($bd, $marco, $nmrC, $total, $gl) = @_;

	my @data = $bd->itemsC($nmrC);

	my ($algo, $mov1, $mov2, $cm, $ncta, $mntD, $mntH, $dt, $ci, $td, $dcm);
	my ($tcD, $tcH) = (0, 0) ;
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # C�digo cuenta
#		$ncta = substr decode_utf8( $bd->nmbCuenta($cm) ),0,35 ; REVISAR
		$mntD = $mntH = $pesos->format_number(0);
		$mntD = $pesos->format_number( $algo->[2] ); 
		$mntH = $pesos->format_number( $algo->[3] );
		$tgD += $algo->[2] ;
		$tgH += $algo->[3] ;
		$tcD += $algo->[2] ;
		$tcH += $algo->[3] ;
		$ci = $dcm = $dt = '' ;
		if ($algo->[4]) {
			$dt = substr decode_utf8($algo->[4]),0,35 ;
		} 
		if ($algo->[5]) {
			$ci = "RUT $algo->[5]";
		}
		if ($algo->[6]) {
			$dcm = $algo->[7] ? "$algo->[6] $algo->[7]" : '' ;
		}
		# el texto en el item puede ser $dt o $ncnta
		$mov1 = sprintf("           %-35s %-5s %12s  %12s", $dt, 
			$cm, $mntD, $mntH) ;
		$mov2 = sprintf("            %-15s %-20s", $ci, $dcm ) ;
		$marco->insert('end', "$mov1\n", 'detalle' ) ;
		$totalItemes += 1 ;
	}
	$marco->insert('end', "            $gl\n" , 'detalle');
	if ( not ($ci eq '' ) ) { #	and $dcm eq ''
		$marco->insert('end', "$mov2\n", 'detalle' ) ;
	}
	# Por si acaso, se produjera alg�n extra�o suceso en la grabaci�n
	print "$nmrC " if not $tcD == $tcH ;
}

sub txt ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');

	# Genera archivo de texto
	my $d = "$rutE/txt/diario.txt" ;
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Ver archivo '$d'"
}

sub csv
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};
	
	my ($Numero, $Tipo, $Fecha, $Total, $Glosa, $Nulo, $Ref) = (0 .. 6);

	$fi = $ut->analizaFecha($FechaI) ;
	$ff = $ut->analizaFecha($FechaF) ;
	my @datosC = $bd->diario($fi,$ff);
	my ($algo, $fh, $gl, $ref, $empr, @datosE, $l, $tg, $d);
	$tg = 0;
	@datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 

	$d = "$rutE/csv/diario.csv" ;
	open ARCHIVO, "> $d" or die $! ;
	$l =  '"'."Libro Diario  $ejerc  -  $empr".'"';
	print ARCHIVO "$l\n";
	$l = "Fecha,Cuenta,C�digo,Debe,Haber,Detalle";
	print ARCHIVO "$l\n";
	foreach $algo ( @datosC ) {
		$tg += $algo->[$Total] ;
		$fh = $ut->cFecha($algo->[$Fecha]) ;
		$ref = $algo->[$Ref] ;
		$gl = '"'.decode_utf8($algo->[$Glosa]).'"' ;
		$l = ( "$fh,-------- $tc->{$algo->[$Tipo]} # $algo->[$Numero] --------" );
		print ARCHIVO "$l\n";
		if ($algo->[$Nulo] ) {
			$l = ("           Anulado por Comprobante $ref");
			print ARCHIVO "$l\n";
		} else {
			asientoCSV($bd, $algo->[$Numero], $gl, $csv);
		}
	}
	$l = ",, ,$tg,$tg" ;
	print ARCHIVO "$l\n";
	close ARCHIVO ;
	$Mnsj = "Grabado en '$d'";
}

sub asientoCSV ( $ $ $ ) {

	my ($bd, $nmrC, $gl) = @_;

	my @data = $bd->itemsC($nmrC);
	my ($algo,$cm,$ncta,$mntD,$mntH,$dt,$ci,$td,$dcm,$x,$l,@cmp);
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # C�digo cuenta
		$ncta = '"'.decode_utf8($bd->nmbCuenta($cm)).'"';
		$mntD = $mntH = 0;
		$mntD =  $algo->[2] ; 
		$mntH =  $algo->[3] ;
		$ci = $dcm = $dt = '' ;
		if ($algo->[4]) {
			$dt = '"'.decode_utf8($algo->[4]).'"';
		} 
		if ($algo->[5]) {
			$ci = '"'."RUT $algo->[5]".'"' ;
		}
		if ($algo->[6]) {
			$dt = '"'."$algo->[6] $algo->[7]".'"';
		}
		$l = ",$ncta, $cm, $mntD, $mntH, $dt" ;
		print ARCHIVO "$l\n";
	}
	$l = ",$gl" ;
	print ARCHIVO "$l\n";
}

# Fin del paquete
1;
