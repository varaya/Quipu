#  Diario.pm - Consulta e imprime Libro Diario
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package Diario;

use Tk::TList;
use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
my ($FechaI, $FechaF, $tc, $Mnsj, @cnf, $rutE) ;	# Variables
my ($fechaI, $fechaF) ; # Campos

my ($bCan, $bImp) ; # Botones
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	@cnf = $bd->leeCnf();
	$rutE = $rtE ;
	$FechaI = "1/1/$cnf[0]";
	$FechaF = $ut->fechaHoy();
	$tc->{'I'} = 'Ingreso';
	$tc->{'E'} = 'Egreso';
	$tc->{'T'} = 'Traspaso';
	
	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Procesa Libro Diario");
	$vnt->geometry("350x110+475+4"); # Tamaño y ubicación
	
	# Define marcos
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Fechas');
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Diario'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
	
	# Define opciones de seleccion
	$fechaI = $mDatos->LabEntry(-label => "Inicial: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaI );
	$fechaF = $mDatos->LabEntry(-label => "Final: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaF );
	
	# Define botones
	$bMst = $mBotonesC->Button(-text => "Muestra", 
		-command => sub { &valida($esto, $mt) } );
	$bImp = $mBotonesC->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mt);} ],
 	  ['command' => "planilla", -command => sub { csv($esto);} ] ] );
	$bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); } );
	
	# Dibuja interfaz
	$fechaI->pack(-side => 'left', -expand => 0, -fill => 'none');
	$fechaF->pack(-side => 'right', -expand => 0, -fill => 'none');

	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bMst->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mDatos->pack(-expand => 1);
	$mBotonesC->pack();
	$mMensajes->pack(-expand => 1, -fill => 'both');

	$bImp->configure(-state => 'disabled');
	$mt->delete('0.0','end');

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
	informe($esto,$mt,$fi,$ff);
}

sub informe ( $ $ ) {

	my ($esto, $marco, $fi, $ff) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};
	my ($Numero, $Tipo, $Fecha, $Total, $Glosa) = (0 .. 4);

	$fi = substr $fi,0,8 ;
	$ff = substr $ff,0,8 ;
	my @datosC = $bd->diario($fi,$ff);
	$Mnsj = " ";
	if (not @datosC) { 
		$Mnsj = "No hay datos para esas fechas"; 
		$fechaI->focus;
		return;
	}
	my ($algo, $nm, $tp, $fch, $tt, $gl, $empr, @datosE);
	@datosE = $bd->datosEmpresa($rutE);
	if (@datosE) {
		$empr = decode_utf8($datosE[0]); 
	}

	$marco->insert('end', "Libro Diario  $cnf[0]  -  $empr\n", 'negrita');
	my $lin1 = "\nFecha      Detalle                       Código        Debe       Haber";
	my $lin2 = "-"x71;
	$marco->insert('end',"$lin1\n",'detalle');
	$marco->insert('end',"$lin2\n",'detalle');
	foreach $algo ( @datosC ) {
		$nm = $algo->[$Numero]; 
		$tipoC = $tc->{$algo->[$Tipo]}; 
		$fch = $ut->cFecha($algo->[$Fecha]); 
		$tt = $pesos->format_number( $algo->[$Total] );
		$gl = decode_utf8($algo->[$Glosa]);
		$marco->insert('end', "\n$fch -------- $tipoC # $nm --------\n", 'detalle');
		asiento($bd, $marco, $nm, $tt, $gl);
	}

	$bImp->configure(-state => 'active');
}

sub asiento ( $ $ $ $ $ ) {

	my ($bd, $marco, $nmrC, $total, $gl) = @_;

	my @data = $bd->itemsC($nmrC);

	my ($algo, $mov1, $mov2, $cm, $ncta, $mntD, $mntH, $dt, $ci, $td, $dcm);
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # Código cuenta
		$ncta = $bd->nmbCuenta($cm);
		$mntD = $mntH = $pesos->format_number(0);
		$mntD = $pesos->format_number( $algo->[2] ); 
		$mntH = $pesos->format_number( $algo->[3] );
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
		$mov1 = sprintf("           %-30s %-5s %11s %11s", decode_utf8($ncta), 
			$cm, $mntD, $mntH) ;
		$mov2 = sprintf("            %-15s %-20s", $ci, $dcm ) ;
		$marco->insert('end', "$mov1\n", 'detalle' ) ;
	}
	$marco->insert('end', "            $gl\n" , 'detalle');
	if ( not ($ci eq '' ) ) { #	and $dcm eq ''
		$marco->insert('end', "$mov2\n", 'detalle' ) ;
	}
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
	
	my ($Numero, $Tipo, $Fecha, $Total, $Glosa) = (0 .. 4);

	$fi = $ut->analizaFecha($FechaI) ;
	$fi =~ s/-//g ; # Convierte a formato AAAAMMDD
	$ff = $ut->analizaFecha($FechaF) ;
	$ff =~ s/-//g ; # Convierte a formato AAAAMMDD
	my @datosC = $bd->diario($fi,$ff);
	my ($algo, $fh, $gl, $empr, @datosE, $l, $d);
	@datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 

	$d = "$rutE/csv/diario.csv" ;
	open ARCHIVO, "> $d" or die $! ;
	$l =  '"'."Libro Diario  $cnf[0]  -  $empr".'"';
	print ARCHIVO "$l\n";
	$l = "Fecha,Detalle,Código,Debe,Haber";
	print ARCHIVO "$l\n";
	foreach $algo ( @datosC ) {
		$fh = $ut->cFecha($algo->[$Fecha]) ;
		$l = ( "$fh,-------- $tc->{$algo->[$Tipo]} # $algo->[$Numero] --------" );
		print ARCHIVO "$l\n";
		$gl = '"'.decode_utf8($algo->[$Glosa]).'"'; 
		asientoCSV($bd, $algo->[$Numero], $gl, $csv);
	}
	close ARCHIVO ;
	$Mnsj = "Grabado en '$d'";
}

sub asientoCSV ( $ $ $ ) {

	my ($bd, $nmrC, $gl) = @_;

	my @data = $bd->itemsC($nmrC);
	my ($algo,$cm,$ncta,$mntD,$mntH,$dt,$ci,$td,$dcm,$x,$l,@cmp);
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # Código cuenta
		$ncta = '"'.decode_utf8($bd->nmbCuenta($cm)).'"';
		$mntD = $mntH = 0;
		$mntD =  $algo->[2] ; 
		$mntH =  $algo->[3] ;
		$ci = $dcm = $dt = '' ;
		if ($algo->[4]) {
			$dt = '"'.decode_utf8($algo->[4]).'"';
		} 
		if ($algo->[5]) {
			$ci = '"'."RUT $algo->[5]".'"';
		}
		if ($algo->[6]) {
			$dcm = '"'."$algo->[6] $algo->[7]".'"';
		}
		$l = ",$ncta, $cm, $mntD, $mntH" ;
		print ARCHIVO "$l\n";
	}
	$l = ",$gl" ;
	print ARCHIVO "$l\n";
	if ( not ($ci eq '' ) ) { #	and $dcm eq ''
		$l = ",$ci $dcm" ;
		print ARCHIVO "$l\n";
	}
}

# Fin del paquete
1;
