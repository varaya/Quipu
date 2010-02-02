#  Rsltds.pm - Consulta e imprime Estados de Resultados mensuales
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM: 02.02.2010

package Rsltds;

use Encode 'decode_utf8';
use Number::Format;
# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
my ($empr, $ejerc, $rutE, $mes, @total, $tg);
my @data = ();
my @m = ('z','Ene','Feb','Mar','Abr','May','Jun','Jul','Ago','Sep','Oct','Nov','Dic') ;

sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE, $prd) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	$rutE = $rtE;
	$ejerc = $prd ;
	my %tp = $ut->tipos();
	$nMes = '' ;
	
	# Define ventanas
	my $vnt = $vp->Toplevel();
	$vnt->title("Procesa Resultados Mensuales");
	$vnt->geometry("1010x450+0+100"); 
	$esto->{'ventana'} = $vnt;

	# Define marco para mostrar resultado
	my $mtA = $vnt->Scrolled('Text', -scrollbars=> 'se', -bg=> 'white',
		-height=> 420 );
	$mtA->tagConfigure('negrita', -font => $tp{ng} ) ;
	$mtA->tagConfigure('detalle', -font => $tp{mn} ) ;

	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );
	
	# Define campo para seleccionar mes
	my $tMes = $mBotonesC->Label(-text => "Seleccione mes ") ;
	my $meses = $mBotonesC->BrowseEntry(-variable => \$nMes, -state => 'readonly',
		-disabledbackground => '#FFFFFC', -autolimitheight => 1,
		-disabledforeground => '#000000', -autolistwidth => 1,
		-browse2cmd => \&selecciona );
	# Crea listado de meses
	@lMeses = $ut->meses();
	my $algo;
	foreach $algo ( @lMeses ) {
		$meses->insert('end', $algo->[1] ) ;
	}
	$meses->delete(12,12); # Elimina el 'Todos' al final

	$bMst = $mBotonesC->Button(-text => "Muestra", 
		-command => sub { &valida($esto, $mtA) } );
	$bImp = $mBotonesC->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mtA);} ],
 	  ['command' => "planilla", -command => sub { csv($bd);} ] ] );
	my $bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { $bd->borraER(); $vnt->destroy();} );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx} ,
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Compras'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');
	$Mnsj = "Para ver Ayuda presione botón 'i'.";

	# Dibuja interfaz
	$mMensajes->pack(-expand => 1, -fill => 'both');
	$tMes->pack(-side => "left", -anchor => "w");
	$meses->pack(-side => "left", -anchor => "w");
	$bMst->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mBotonesC->pack();
	$mtA->pack(-fill => 'both');

	$bImp->configure(-state => 'disabled');

	bless $esto;
	return $esto;
}

# Funciones internas
sub selecciona {
	my ($jc, $Index) = @_;
	$mes = $lMeses[$Index]->[0];
}

sub valida ( $ ) 
{
	my ($esto,$mt) = @_;
	my $bd = $esto->{'baseDatos'};
	
	$Mnsj = " ";
	if (not $mes) {
		$Mnsj = "Debe seleccionar un mes."; 
		return;
	} else {
		muestra($bd,$mt);
	}
}

sub txt ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');
	# Genera archivo de texto
	my $d = "$rutE/txt/resultados$mes.txt" ;
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Grabado en '$d'";
}

sub csv ( $ )
{
	my ($bd) = @_;	

	my @i = (1..$mes);
	$d = "$rutE/csv/resultados$mes.csv" ;
	open ARCHIVO, "> $d" or die $! ;

	print ARCHIVO "$empr\n";
	$l = "Estados de Resultados a $nMes $ejerc";
	print ARCHIVO "$l\n";
	$l = "Cod.,Cuenta";
	foreach ( @i ) {
		$l .= ",$m[$_]" ;
	}
	$l .= ",Total";
	print ARCHIVO "$l\n";
	$asgr = "x";
	foreach $algo ( @data ) {
		$sgr = $algo->[15];
		if (not $sgr eq $asgr) {
			$nsgr = substr decode_utf8( $bd->nombreGrupo($sgr) ),0,21 ;
			$l = "$nsgr";
			@stotal = ();
			foreach ( @i ) {
				push @stotal, $bd->sumaRM($m[$_],$sgr) ;
			}
			foreach ( @i ) {
				$num = int $stotal[$_ - 1]/1000 + 0.5 ;
				$l .= ",$num";
			}
			$num = int $bd->sumaRM('Total',$sgr) / 1000 + 0.5 ;
			$l .= ",$num";
			print ARCHIVO "$l\n";
		}
		$asgr = $sgr ;
		$cta = decode_utf8( $algo->[1] ) ;
		$l = "$algo->[0], $cta";
		foreach ( @i ) {
			$num = int $algo->[$_ + 1]/1000 + 0.5 ;
			$l .= ",$num";
		}
		$num = int $algo->[14]/1000 + 0.5 ;
		$l .= ",$num";
		print ARCHIVO "$l\n";
	}
	$l = ",Resultado" ;
	foreach ( @i ) {
		$num = int $total[$_ - 1]/1000 + 0.5 ;
		$l .= ",$num";
	}
	$l .= ",$tg";
	print ARCHIVO "$l\n";
	close ARCHIVO ;
	$Mnsj = "Ver archivo '$d'";
}

sub muestra ( $ $ )
{
	my ($bd, $mt) = @_;
		
	my (@datosE,$algo,$mov,$cta,$num,$sgr,$asgr,$nsgr,@stotal);
	# Procesa datos
	$bd->borraER();
	$bd->creaER();
	if ( not $bd->aRMensual($mes) ) {
		$Mnsj = "No hay datos para $nMes.";
		return ;
	} else {
		$Mnsj = "Procesando $nMes.";
		@data = $bd->datosRM();
	}
	my @i = (1..$mes);
	@total = ();
	foreach ( @i ) {
		push @total, $bd->sumaRM($m[$_],'') ;
	}
	$tg = int $bd->sumaRM('Total','') / 1000 + 0.5 ;
	# Datos generales
	@datosE = $bd->datosEmpresa($rutE);
	$empr = decode_utf8($datosE[0]); 

	# Muestra el Estado de Resultados
	$mt->delete('0.0','end');
	$mt->insert('end', "$empr\n", 'negrita');
	$mt->insert('end', "Estados de Resultados a $nMes $ejerc\n", 'negrita');
	$mt->insert('end', "Cifras en miles de pesos\n");
	my $lin1 = sprintf("%-5s %-21s", 'Cod.', 'Cuenta') ;
	foreach ( @i ) {
		$lin1 .= sprintf("%11s", "$m[$_]");
	}
	$lin1 .= sprintf("%11s", "Total");
	my $lin2 = "-"x104;
	$mt->insert('end',"$lin1\n",'detalle');
	$mt->insert('end',"$lin2",'detalle');
	$asgr = "x" ;
	foreach $algo ( @data ) {
		$sgr = $algo->[15];
		if (not $sgr eq $asgr) {
			$nsgr = decode_utf8( $bd->nombreGrupo($sgr) ) ;
			$mov = sprintf("%-28s", $nsgr);
			@stotal = ();
			foreach ( @i ) {
				push @stotal, $bd->sumaRM($m[$_],$sgr) ;
			}
			foreach ( @i ) {
				$num = int $stotal[$_ - 1]/1000 + 0.5 ;
				$mov .= sprintf("%10s ", $pesos->format_number($num) );
			}
			$num = int $bd->sumaRM('Total',$sgr) / 1000 + 0.5 ;
			$mov .= sprintf("%10s ", $pesos->format_number($num) );
			$mt->insert('end', "\n$mov\n", 'detalle' ) ;
		}
		$asgr = $sgr ;
		$cta = substr abrev($algo->[1]),0,21 ;
		$mov = sprintf("%-5s %-21s ", $algo->[0], $cta);
		foreach ( @i ) {
			$num = int $algo->[$_ + 1]/1000 + 0.5 ;
			$mov .= sprintf("%10s ", $pesos->format_number($num) );
		}
		$num = int $algo->[14]/1000 + 0.5 ;
		$mov .= sprintf("%10s ", $pesos->format_number($num) );
		$mt->insert('end', "$mov\n", 'detalle' ) ;
	}
	$mt->insert('end',"$lin2\n",'detalle');
	$lin1 = sprintf("%26s ", 'Resultado') ;
	foreach ( @i ) {
		$num = int $total[$_ - 1]/1000 + 0.5 ;
		$lin1 .= sprintf("%11s",$pesos->format_number($num) );
	}
	$lin1 .= sprintf("%11s",$pesos->format_number($tg) );
	$mt->insert('end',"$lin1\n",'detalle');
	$lin2 = "="x104;
	$mt->insert('end',"$lin2\n",'detalle');
	
	$bImp->configure(-state => 'active');
}

sub abrev ( $ )
{
	my ($algo) = @_;
	my $ct = decode_utf8($algo) ;
	if (length $ct > 24) {
		my @pl = split / /, $ct;
		my $lt = substr $pl[0],0,1;
		$ct =~ s/^$pl[0]/$lt/;
	}
	return $ct ;
}

# Fin del paquete
1;
