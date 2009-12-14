#  AsignaNC.pm - Paga o abona con Notas de Crédito 
#  Forma parte del programa Quipu
#
#  Derechos de Autor (c) Víctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete 
#  UM: 13.12.2009

package AsignaNC;

use Tk::LabEntry;
use Tk::LabFrame;
use Tk::TableMatrix;
use Number::Format;

my ($FechaC,$FechaE,$NumD,$Ni,$Id,$Mes,$NumN,$NumC,$Rut,$Monto,$MontoA,$Total) ;
my ($rows,$tab, $totalR) ;
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
my ( $bNvo ) ; 	# Botones

sub crea {
	my ($esto, $vp, $bd, $ut, $mt) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Asigna NC");
	$vnt->geometry("340x300+475+2"); # Tamaño y ubicación

	my %tp = $ut->tipos();
	inicializa();
	# Defime marcos
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Buscar NC:');
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Facturas:');
	my $mBtns = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{fx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	$Mnsj = "Indique Rut y # NC";
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Ajustes'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	# Define botones
	$bNvo = $mBtns->Button(-text => "Registra", -command => sub { &registra($esto)}); 
	$bCan = $mBtns->Button(-text => "Cancela", -command => sub { &cancela() });
	$bFin = $mBtns->Button(-text => "Termina", -command => sub { $vnt->destroy(); });

	# Parametros
	# Define campos para registro de datos de la empresa
	$rut = $mDatosC->LabEntry(-label => "RUT:  ", -width => 12,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$Rut );
	$numD = $mDatosC->LabEntry(-label => " # ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$NumD );
	# Crea tabla para documentos impagos
	$tab = {};
	my ($fila, $rows, $cols);
	$cols = 5 ;
	$rows = 6 ;
	$t = $mDatos->Scrolled('TableMatrix', -rows => $rows, -cols => $cols, 
			-titlerows =>  1, -titlecols => 0, -roworigin => -1, -colorigin => 0 ,
			-width => 8, -height => 8, -flashmode => 'off', -variable => $tab ,
			-font => $tp{mn}, -scrollbars => 'e' ,-state => 'disabled', -justify => 'right' );
	$t->colWidth(0 => 4, 1 => 3, 2 => 8, 3 => 12, 4 => 12);
	# Rellena una tabla vacua
	$tab->{"-1,0"} = "";
	$tab->{"-1,1"} = "TD";
	$tab->{"-1,2"} = "#";
	$tab->{"-1,3"} = "Total";
	$tab->{"-1,4"} = "Abonos";
	for ($fila = 0, $fila = 6 , $fila++) {
		$tab->{"$fila,0"} = "No";
		$tab->{"$fila,1"} = " " ;
		$tab->{"$fila,2"} = " ";
		$tab->{"$fila,3"} = 0;
		$tab->{"$fila,4"} = 0;
	}
	# configura botones de selección de documentos
	$t->tagConfigure('No', -bg => 'gray', -relief => 'raised');
	$t->tagConfigure('SI', -bg => 'green', -relief => 'sunken');
	$t->tagConfigure('sel', -bg => 'gray75', -relief => 'flat');
	# y las acciones del ratón de cola larga
	$t->bind('<FocusOut>',sub{ 
		my $w = shift;
		$w->selectionClear('all'); 
		});
	$t->bind('<Motion>', sub{
		my $w = shift;
		my $Ev = $w->XEvent;
		if( $w->selectionIncludes('@' . $Ev->x.",".$Ev->y)){ Tk->break; }
		$w->selectionClear('all');
		$w->selectionSet('@' . $Ev->x.",".$Ev->y);
		Tk->break; 
		} );
	# activa o desactiva botones SI o NO 
	$t->bind('<1>', sub {
		my $w = shift;
		$w->focus;
		my ($rc) = @{$w->curselection};
		my ($nd,$td,$mt,$mnt,$ab) ;
		my $var = $w->cget(-var);
		my ($r, $c) = split(/,/, $rc);
		if ( $var->{$rc} eq 'SI' ) {
			$var->{$rc} = 'No';
			$w->tagCell('No',$rc);
			# Elimina documento ya seleccionado
			$td = $var->{"$r,1"};
			$nd = $var->{"$r,2"};
			$ab = $var->{"$r,4"} ;
			$mt = $var->{"$r,3"} ;
			$mt =~ s/\.//g ;
			$ab =~ s/\.//g ;
			$mt -= $ab ;
			if ($mt > $MontoA) {
				$Total -= $MontoA;
				$Monto = $MontoA ;
			} else {
				$Total -= $mt;
				$Monto += $mt ;
			}
			$bNvo->configure(-state => 'disabled') if $Monto > 0;
		} elsif ( $var->{$rc} eq 'No' ) {
			$var->{$rc} = 'SI';
			$w->tagCell('SI',$rc);
			# selecciona documento y totaliza
			$td = $var->{"$r,1"};
			$nd = $var->{"$r,2"};
			$ab = $var->{"$r,4"} ;
			$mt = $var->{"$r,3"} ;
			$mt =~ s/\.//g ;
			$ab =~ s/\.//g ;
			$mt -= $ab ;
			if ($mt > $Monto) {
				$Total += $Monto ;
				$var->{"$r,4"} = $Monto ;
				$Monto = 0 ;
			} else {
				$Total += $mt ;
				$Monto -= $mt ;
				$var->{"$r,4"} = $mt ;
			}
		}
		$mnt = $pesos->format_number( $Monto );
		$Mnsj = "Remanente $mnt";
		$bNvo->configure(-state => 'active') if $Monto == 0 ;
	});
	$total = $mDatos->LabEntry(-label => "Total Asignado", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$Total );
		
	$numD->bind("<FocusOut>", sub { &buscaDoc($esto) } );

	# Dibuja interfaz
	$rut->grid(-row => 0, -column => 0, -sticky => 'nw');
	$numD->grid(-row => 0, -column => 1, -sticky => 'nw');
		
	$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bFin->pack(-side => 'right', -expand => 0, -fill => 'none');

	$mMensajes->pack(-expand => 1, -fill => 'both');
	$mDatosC->pack(-expand => 1);
	$t->pack() ;
	$total->pack() ;
	$mDatos->pack();	
	$mBtns->pack(-expand => 1);

	$bNvo->configure(-state => 'disabled');
	$rut->focus;
	
	bless $esto;
	return $esto;
}

# Funciones internas
sub cancela
{
	inicializa();
	$rut->focus ;
}

sub registra ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'} ;
	my $ut = $esto->{'mensajes'} ;
	
	my ($nf,$fc,$tl) ;
	$fc = $ut->fechaHoy();
	$fc = $ut->analizaFecha($fc) ;
	my @filas = (0 .. $totalR) ;
	foreach  (@filas )  {
		if (  $tab->{"$_,0"} eq "SI" ) {
			$nf = $tab->{"$_,2"} ; # Numero factura
			$tl = $tab->{"$_,4"}; # Abonos
#			print "$fc, $Rut, $nf, $tl, $NumD \n";
			$bd->pagaF( $fc, $Rut, 'Compras', $nf, $tl, $NumD )
		}
	}

	$Mnsj = "Registro actualizado";
	inicializa();
	$rut->focus;
}

sub inicializa 
{
	$NumD = $Rut = '';
	$Total = 0 ;
}

sub buscaDoc ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'} ;
	my $ut = $esto->{'mensajes'} ;
	
	if ($Rut eq '') {
		$Mnsj = "Indicar RUT";
		$rut->focus ;
		return ;
	}
	if ($NumD eq '' ) {
		$Mnsj = "Indicar número documento";
		$numD->focus;
		return ;
	} 
	$Ni = $bd->buscaFct('Compras',$Rut,$NumD,'ROWID');
	if (not $Ni) {
		$Mnsj = "NO existe documento con esos datos";
		$rut->focus;
		return ;
	} 
	if ( $bd->buscaFct('Compras',$Rut,$NumD, 'Pagada') ) {
		$Mnsj = "Ese documento ya está pagado.";
		$numD->focus;
		return ;
	} else {
		my @datos = $bd->datosFct('Compras',$Rut,$NumD);
		$NumC = $datos[7];
		$Monto = $MontoA = -$datos[3] ;
		my $mnt = $pesos->format_number( $Monto );
		$Mnsj = "Monto $mnt";
		llenaT( $esto ) ;
	}
}

sub llenaT ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};

	my $tb = "Compras"; ;
	my @data = $bd->datosFacts($Rut,$tb,1);
	if ( not @data ) {
			$Mnsj = "NO hay datos para ese RUT" ;
			$rut->focus;
			return;		
	}
	$rows = @data + 1;
	$fila = 0;
	my $algo ;
	foreach $algo ( @data ) {
		if ($algo->[8] eq 'NC') {
			$rows -= 1 ;
		} else {
			$tab->{"$fila,0"} = "No";
			$tab->{"$fila,1"} = $algo->[8];
			$tab->{"$fila,2"} = $algo->[0];
			$tab->{"$fila,3"} = $pesos->format_number($algo->[2]);
			$tab->{"$fila,4"} = $pesos->format_number($algo->[3]);
			$t->tagCell('No', "$fila,0");
			$fila += 1;
		}
	}
	$totalR = $fila - 1 ;
    return if (!$t);
	$t->configure(-rows => $rows ) ;
    $t->configure(-padx =>($t->cget(-padx)));
}

# Fin del paquete
1;
