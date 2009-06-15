#  Mayor.pm - Procesa cuenta de mayor
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) V�ctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los t�rminos previstos en la 
#  licencia incluida en este paquete 

package Mayor;

use Tk::TList;
use Tk::LabFrame;
use Encode 'decode_utf8';
use Number::Format;
#use Data::Dumper; print Dumper \@dtsCmp;
	
# Variables v�lidas dentro del archivo
my ($bImp, $bCan, $Mnsj, $cdC, @cnf, $sItem,$empr,$rutE) ; 	
my @datos = () ;		# Lista de cuentas
# Formato de n�meros
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	@cnf = $bd->leeCnf();
	$cdC = '';
	$rutE = $rtE ;
	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Procesa Libro Mayor");
	$vnt->geometry("380x310+475+4"); # Tama�o y ubicaci�n
	
	# Defime marcos
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Cuentas con movimiento');
	my $mBotones = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y bot�n de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'CMayor'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione bot�n 'i'.";
	
	# Define Lista de datos
	my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe', -height => 16,
		-selectmode => 'single', -orient => 'horizontal', -width => 45,
		-command => sub { &muestraM($esto, $mt) } );
	$esto->{'vLista'} = $listaS;
	
	# Define botones
	my $bLmp = $mBotones->Button(-text => "Limpia", 
		-command => sub { $mt->delete('0.0','end'); } );
	$bImp = $mBotones->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mt);} ],
 	  ['command' => "planilla", -command => sub { csv($esto);} ] ] );
	$bCan = $mBotones->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy(); } );
	
	@datos = muestraLista($esto);
	if (not @datos) {
		$Mnsj = "No hay cuentas registradas" ;
	}
	# Dibuja interfaz
	$bLmp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

	$listaS->pack();
	$mLista->pack(-expand => 1);
	$mBotones->pack(-expand => 1);
	$mMensajes->pack(-expand => 1, -fill => 'both');
	
	# Inicialmente deshabilita bot�n Registra
	$bImp->configure(-state => 'disabled');
	$mt->delete('0.0','end');

	bless $esto;
	return $esto;
}

# Funciones internas
sub muestraLista ( $ ) 
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	
	# Obtiene lista de cuentas con movimiento
	my @data = $bd->datosCcM();

	# Completa TList con nombres de los cuentas
	my ($algo, $nm);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$nm = sprintf("%-5s %-30s", $algo->[1], decode_utf8($algo->[0]) ) ;
		$listaS->insert('end', -itemtype => 'text', -text => "$nm" ) ;
	}
	# Devuelde una lista de listas con datos de las cuentas
	return @data;
}

sub muestraM {

	my ($esto, $marco) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};

	# Obtiene item seleccionado
	my @ns = $listaS->info('selection');
	$sItem = @datos[$ns[0]];
	# Datos cuenta
	$cdC = $sItem->[1];
	my $nmC = decode_utf8($sItem->[0]);
	my $saldoI = $sItem->[4];
	my $tSaldo = $sItem->[5];
	my $fechaUM = $sItem->[6]; 
	my @datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 

	$marco->insert('end', "Libro Mayor  $cnf[0]  -  $empr\n", 'negrita');
	$marco->insert('end', "Cuenta: $cdC - $nmC\n\n" , 'grupo');
	$marco->insert('end', "Comprobante\n" , 'detalle');

	my @data = $bd->itemsM($cdC);

	my ($algo, $mov, $nCmp, $mntD, $mntH, $dt, $ci, $tDebe, $tHaber, $dcm);
	my($tC, $fecha, $nulo );
	my $lin1 = "   # T Fecha      Detalle                          Debe       Haber";
	my $lin2 = "-"x67;
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
	$mov = sprintf("%4s %-1s %10s %-25s %11s %11s",
		'','',"01/01/$cnf[0]",$dt,$mntD,$mntH) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	foreach $algo ( @data ) {
		$nCmp = $algo->[0];  # Numero comprobante
		$fecha = $ut->cFecha($algo->[9]);
		$tC = $algo->[10];
		$nulo = $algo->[11];
		$mntD = $mntH = $pesos->format_number(0);
		$mntD = $pesos->format_number( $algo->[2] ); 
		$tDebe += $algo->[2];
		$mntH = $pesos->format_number( $algo->[3] );
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
		$mov = sprintf("%4s %-1s %10s %-25s %11s %11s", $nCmp, $tC, 
			$fecha, $dt, $mntD, $mntH ) ;

		$marco->insert('end', "$mov\n", 'detalle' ) ;
	}
	$marco->insert('end',"$lin2\n",'detalle');
	$dt = "Totales";
	$mntD = $pesos->format_number( $tDebe ); 
	$mntH = $pesos->format_number( $tHaber ); 
	$mov = sprintf("%4s %-1s %10s %-25s %11s %11s",'','','',$dt,$mntD,$mntH ) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	# Nuevo saldo
	$dt = "Saldo al $fechaUM";
	$mntD = $mntH = '';
	$mntD = $pesos->format_number($tDebe - $tHaber) if $tDebe > $tHaber ;
	$mntH = $pesos->format_number($tHaber - $tDebe) if $tDebe < $tHaber ;
	$marco->insert('end',"$lin2\n",'detalle');
	$mov = sprintf("%4s %-1s %10s %-25s %11s %11s",'','','',$dt,$mntD,$mntH ) ;
	$marco->insert('end', "$mov\n", 'detalle' ) ;
	
	$bImp->configure(-state => 'active');

}

sub txt ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');

	# Genera archivo de texto
	my $d = "$rutE/txt/myr$cdC.txt" ;
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;

	$Mnsj = "Ver archivo '$d'";
}

sub csv ( $ )
{
	my ($esto, $marco) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	my $nmC = decode_utf8($sItem->[0]);
	my $saldoI = $sItem->[4];
	my $tSaldo = $sItem->[5];
	my $fechaUM = $sItem->[6];

	my ($tDebe,$tHaber,$fchI,$mntD,$mntH,$dt,$nCmp,$fecha,$tC,$nulo,$ci,$dcm,$d);
	$d = "$rutE/csv/myr$cdC.csv";
	open ARCHIVO, "> $d" or die $! ;
	$l =  '"'."Libro Mayor  $cnf[0]  -  $empr".'"';
	print ARCHIVO "$l\n";
	$l = '"'."Cuenta: $cdC - $nmC".'"';
	print ARCHIVO "$l\n";
	$l = "Comprobante";
	print ARCHIVO "$l\n";
	$l = "#,T,Fecha,Detalle,Debe,Haber";
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
	
	my @data = $bd->itemsM($cdC);
	foreach $algo ( @data ) {
		$nCmp = $algo->[0];  # Numero comprobante
		$fecha = $ut->cFecha($algo->[9]);
		$tC = $algo->[10];
		$nulo = $algo->[11];
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

# Fin del paquete
1;
