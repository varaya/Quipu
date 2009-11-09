#  Pagos.pm - Registra y contabiliza pagos emitidos y recibidos
#  Forma parte del programa Quipu
# 
#  Derechos de autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM: 06.11.2009 3480554-7

package Pagos;

use Tk::TList;
use Tk::LabEntry;
use Tk::LabFrame;
use Tk::TableMatrix;
use Tk::BrowseEntry;
use Encode 'decode_utf8';
use Number::Format;

# Variables válidas dentro del archivo
# Datos a registrar
my ($Numero,$Id,$Fecha,$TotalD,$TotalH,$TotalDf,$TotalHf,$CntaI,$IdT ) ;
my ($Codigo,$Detalle,$Monto,$DH,$RUT,$Documento,$Cuenta,$Nombre,$FechaV) ;
my ($TipoCmp,$TipoD,$cTipoD,$BH,$cBanco,$Mnsj,$tab) ; 
# Campos
my ($codigo,$detalle,$fecha,$totalD,$totalH,$bcos,$nombre,$fechaV,$t,$archivo) ;
my ($monto,$debe,$haber,$cuentaI,$tipoD,$documento,$numero,$cuenta,$id,$busca) ;
# Centro de costos
my ($CCto, $cCto, $NCCto) ;
my ($bReg, $bEle, $bNvo, $bCnt) ; 	# Botones

my @dCuenta = () ;	# Lista datos cuenta
my @datos = () ;	# L;sta items del comprobante
my @listaD = () ;	# Lista tipos de documentos
my @bancos = () ;	# Lista nombre de bancos
my %tabla = () ;	# Lista de tablas según tipo de documento

# Formato de números
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');
			
sub crea {

	my ($esto, $vp, $bd, $ut, $tipo, $marcoT) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Inicializa variables
	my %tp = $ut->tipos();
	%tabla = ('BH' => 'BoletasH' ,'FC' => 'Compras' ,'FV' => 'Ventas', 
	'ND' => 'Compras', 'NC' => '', 'LT' => '', 'CH' => '', 'SD' => '', '' => '' ) ;
	$Nombre = "";
	$Fecha = $ut->fechaHoy();
	$Numero = $bd->numeroC() + 1;
	$Monto = $TotalD = $TotalH = $BH = 0;
	$Codigo = $cTipoD = $TipoD = $DH = $RUT = $Glosa = $FechaV = $Cuenta = '';
	$TipoD = $cBanco = $CCto = $NCCto = $CntaI = $IdT = '' ;
	my $tipoC = '' ;
	if ($tipo eq 'Emitidos') {
		$tipoC = 'Egreso' ;
		$archivo = "Compras" ;
	} else {
		$tipoC = 'Ingreso' ;
		$archivo = "Ventas" ;
	}
	$TipoCmp = substr $tipoC, 0, 1 ;
	@bancos = $bd->datosBcs();
	# Crea archivo temporal para registrar movimientos
	$bd->creaTemp();
	# Define ventana
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Registra Pago $tipo");
	$vnt->geometry("410x660+475+4"); # Tamaño y ubicación
	
	# Defime marcos
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => "Comprobante de $tipoC");
	my $mDocsP = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
			-label => 'Documentos pendientes');
	my $mLista = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Movimientos');
	my $mItems = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Detalle Movimiento');
	my $mOtros = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Cuenta Individual ');
	my $mBotonesL = $vnt->Frame(-borderwidth => 1);
	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );
	
	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Cmprbs'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	$Mnsj = "Para ver Ayuda presione botón 'i'.";
	
	# Lista de datos (items del comprobante)
	my $listaS = $mLista->Scrolled('TList', -scrollbars => 'oe', -width => 60, -height => 8,
		-selectmode => 'single', -orient => 'horizontal', -font => $tp{mn},
		-command => sub { &modifica($esto) } );
	$esto->{'vLista'} = $listaS;
	
	# Define botones
	$bReg = $mBotonesL->Button(-text => "Modifica", 
		-command => sub { &registra($esto) } ); 
	$bEle = $mBotonesL->Button(-text => "Elimina", 
		-command => sub { &elimina($esto) } ); 
	$bNvo = $mBotonesL->Button(-text => "Agrega", 
		-command => sub { &agrega($esto) } ); 
	$bCnt = $mBotonesC->Button(-text => "Contabiliza", 
		-command => sub { &contabiliza($esto) } ); 
	my $bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { &cancela($esto) } );

	# Define campos para datos generales del comprobante
	$numero = $mDatosC->LabEntry(-label => "Numero: ", -width => 6,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$Numero, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
	$fecha = $mDatosC->LabEntry(-label => "Fecha: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Fecha );

	$id = $mDatosC->LabEntry(-label => " RUT: ", -width => 15,
			-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
			-justify => 'left', -textvariable => \$IdT);
	if ( $TipoCmp eq 'E' ) {
		$fct = $mDatosC->Radiobutton( -text => "FC", -value => 0, 
		-variable => \$BH );
		$bhn = $mDatosC->Radiobutton( -text => "BH", -value => 1, 
		-variable => \$BH );
	}
	$busca = $mDatosC->Button(-text => "Busca",	-command => sub { &llenaT($esto) } );
	$x = $mDatosC->Label(-text => ' ' );

	$totalD = $mDatosC->LabEntry(-label => "Totales:  Debe ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$TotalDf, -state => 'disabled', 
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000' );
	$totalH = $mDatosC->LabEntry(-label => "Haber ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'right', -textvariable => \$TotalHf, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');

	# Define campos para registro de items
	$codigo = $mItems->LabEntry(-label => " Cuenta: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Codigo );
	if ( @bancos ) {
		$bcos = $mItems->LabEntry(-label => "Bco", -width => 3,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$cBanco );
	}
	$monto= $mItems->LabEntry(-label => " Monto:  ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Monto); 
	$debe = $mItems->Radiobutton( -text => "Debe", -value => 'D', 
		-variable => \$DH );
	$haber = $mItems->Radiobutton(-text => "Haber", -value => 'H', 
		-variable => \$DH );
	$detalle = $mItems->LabEntry(-label => " Detalle: ", -width => 40,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Detalle);
	$cuentaI = $mOtros->LabEntry(-label => " RUT: ", -width => 15,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-justify => 'left', -textvariable => \$RUT);
	$nombre = $mOtros->Label(-textvariable => \$Nombre, -font => $tp{tx},);	
	$doc = $mOtros->Label(-text => ' Doc.');
	$tipoD = $mOtros->BrowseEntry( -variable => \$TipoD, -state => 'readonly',
		-disabledbackground => '#FFFFFC', -autolimitheight => 1,
		-disabledforeground => '#000000', -width => 12, -listwidth => 30,
		-browse2cmd => \&seleccionaD );
	# Crea tabla para documentos impagos
	$tab = {};
	my ($fila, $rows, $cols);
	$cols = 6 ;
	$rows = 6 ;
	$t = $mDocsP->Scrolled('TableMatrix', -rows => $rows, -cols => $cols, 
			-titlerows =>  1, -titlecols => 0, -roworigin => -1, -colorigin => 0 ,
			-width => 8, -height => 8, -flashmode => 'off', -variable => $tab ,
			-font => $tp{mn}, -scrollbars => 'e' ,-state => 'disabled', -justify => 'right' );
	$t->colWidth(0 => 4, 1 => 3, 2 => 8, 3 => 12, 4 => 12, 5 => 10);
	# Rellena una tabla vacua
	$tab->{"-1,0"} = "";
	$tab->{"-1,1"} = "TD";
	$tab->{"-1,2"} = "#";
	$tab->{"-1,3"} = "Total";
	$tab->{"-1,4"} = "Abonos";
	$tab->{"-1,5"} = "Vence";
	for ($fila = 0, $fila = 6 , $fila++) {
		$tab->{"$fila,0"} = "No";
		$tab->{"$fila,1"} = " " ;
		$tab->{"$fila,2"} = " ";
		$tab->{"$fila,3"} = 0;
		$tab->{"$fila,4"} = 0;
		$tab->{"$fila,5"} = " ";
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
		my ($nd,$td,$mt,$ct,$ab) ;
		my $var = $w->cget(-var);
		my ($r, $c) = split(/,/, $rc);
		if ( $var->{$rc} eq 'SI' ){
			$var->{$rc} = 'No';
			$w->tagCell('No',$rc);
			# borra el registro temporal
			$td = $var->{"$r,1"};
			$nd = $var->{"$r,2"};
			$ab = $var->{"$r,4"} ;
			$mt = $var->{"$r,3"} ;
			$mt =~ s/\.//g ;
			$ab =~ s/\.//g ;
			$mt -= $ab ;
			borraDT($esto,$nd,$mt);
		} elsif ( $var->{$rc} eq 'No' ) {
			$var->{$rc} = 'SI';
			$w->tagCell('SI',$rc);
			# selecciona documento y crea registro temporal
			$td = $var->{"$r,1"};
			$nd = $var->{"$r,2"};
			$ab = $var->{"$r,4"} ;
			$mt = $var->{"$r,3"} ;
			$ct = $var->{"$r,6"};
			$mt =~ s/\.//g ;
			$ab =~ s/\.//g ;
			$mt -= $ab ;
			agregaDT($esto,$td,$nd,$mt,$ct) ;
		}
	});
	# Crea opciones para elegir tipo de documento
	@listaD = $bd->datosDocs();
	push @listaD, ['SD','N.Documento','','',0];
	my $algo;
	foreach $algo ( @listaD ) {
		$tipoD->insert('end', decode_utf8($algo->[1]) ) ;
	}
	$documento = $mOtros->LabEntry(-label => "# ", -width => 12,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Documento);		
	$fechaV = $mOtros->LabEntry(-label => "Vence: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$FechaV );
	
	@datos = muestraLista($esto);
	if ( not @datos ) {
		$listaS->insert('end', -itemtype => 'text', 
			-text => "No hay movimientos registrados" ) ;
	}
	# Habilita validaciones
	$fecha->bind("<FocusOut>", sub { &validaFecha($ut,\$Fecha,\$fecha,1) } );
	$fechaV->bind("<FocusOut>", sub{ &validaFecha($ut,\$FechaV,\$fechaV,0)});
	$monto->bind("<FocusIn>", sub { &buscaCta($esto) } );
	$detalle->bind("<FocusIn>", sub { &monto() } );	
	$tipoD->bind("<FocusIn>", sub { &buscaRut($esto) } );
	$documento->bind("<FocusIn>", sub { &verificaD() } );
	
	# Dibuja interfaz
	$mMensajes->pack(-expand => 1, -fill => 'both');
	$fecha->grid(-row => 0, -column => 0, -columnspan => 2, -sticky => 'nw');
	$numero->grid(-row => 0, -column => 2, -columnspan => 2, -sticky => 'nw');
	$id->grid(-row => 1, -column => 0);
	if ( $TipoCmp eq 'E' ) {
		$fct->grid(-row => 1, -column => 1);
		$bhn->grid(-row => 1, -column => 2);
	}
	$busca->grid(-row => 1, -column => 3);
	$x->grid(-row => 1, -column => 4);
	$totalD->grid(-row => 2, -column => 0, -columnspan => 2);
	$totalH->grid(-row => 2, -column => 2); 
	
	$codigo->grid(-row => 0, -column => 0, -sticky => 'nw');	
	if ( @bancos ) {
		$bcos->grid(-row => 0, -column => 1, -sticky => 'nw');
	}
	$monto->grid(-row => 2, -column => 0, -columnspan => 2, -sticky => 'nw');	
	$debe->grid(-row => 2, -column => 2, -sticky => 'nw');	
	$haber->grid(-row => 2, -column => 3, -columnspan => 2, -sticky => 'nw');	
	$detalle->grid(-row => 3, -column => 0, -columnspan => 4, -sticky => 'nw');
	
	$cuentaI->grid(-row => 0, -column => 0, -columnspan => 2, -sticky => 'nw');
	$nombre->grid(-row => 0, -column => 2, -columnspan => 2, -sticky => 'nw');
	$doc->grid(-row => 1, -column => 0, -sticky => 'nw');
	$tipoD->grid(-row => 1, -column => 1, -sticky => 'nw');
	$documento->grid(-row => 1, -column => 2, -sticky => 'nw');
	$fechaV->grid(-row => 1, -column => 3, -sticky => 'nw');

	$bReg->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bEle->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCnt->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');

	$listaS->pack();
	$mDatosC->pack();
	$t->pack() ;
	$mBotonesC->pack();
	$mDocsP->pack();
	$mLista->pack(-expand => 1);
	$mItems->pack(-expand => 1);

	$mOtros->pack(-side => 'top', -expand => 1, -fill => 'none');
	$mBotonesL->pack( -expand => 1);

	# Inicialmente deshabilita algunos botones
	$bReg->configure(-state => 'disabled');
	$bEle->configure(-state => 'disabled');
	$bCnt->configure(-state => 'disabled');
	# y campos
	$cuentaI->configure(-state => 'disabled');
	$tipoD->configure(-state => 'disabled');
	$documento->configure(-state => 'disabled');
	$fechaV->configure(-state => 'disabled');
	$fecha->focus;
	
	bless $esto;
	return $esto;
}

# Funciones internas
sub seleccionaD {
	my ($jc, $Index) = @_;
	$cTipoD = $listaD[$Index]->[0];
	$BH = 1 if $cTipoD eq 'BH';
	if ( $cTipoD eq 'SD' ) {
		$documento->configure(-state => 'disabled');
	} else {
		$documento->focus;
	}
}

sub buscaBco {
	my $e ;
	$cBanco = "0" . $cBanco if length $cBanco == 1 ;
	for $e (@bancos) {
		return decode_utf8( $e->[1] ) if $e->[0] eq $cBanco ; 
	}
}

sub buscaCta ( ) {

	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};

	# Comprueba largo del código de la cuenta
	if (length $Codigo < 4) {
		$Mnsj = "Código debe tener 4 dígitos";
		$codigo->focus;
		return;
	}
	# Busca código
	@dCuenta = $bd->dtCuenta($Codigo);
	if ( not @dCuenta ) {
		$Mnsj = "Ese código NO está registrado";
		$codigo->focus;
		return ;
	} else {
		$Cuenta = decode_utf8($dCuenta[0]);
		$CntaI = $dCuenta[1];
		$Mnsj = $Cuenta ;
	}
	# Activa campos:
	if ($CntaI eq "B") { # si es cuenta con detalle para Banco
		if ( $cBanco eq '' ) {			
			$Mnsj = "Debe registrar código Banco";
			$bcos->focus;
			return ;
		} else {
			my $b = buscaBco() ;
			if (not $b) {
				$Mnsj = "Código Banco no existe";
				$bcos->focus;
				return ;
			}
			$Mnsj = "Banco $b" ;
		} 
		$cuentaI->configure(-state => 'disabled');
		$documento->configure(-state => 'normal');
		$tipoD->configure(-state => 'normal');
		$fechaV->configure(-state => 'normal');
	} else {
		$cBanco = '' ;
	}
	# si agrupa cuentas individuales
	if ($CntaI eq "I") {
		$cuentaI->configure(-state => 'normal');
		$tipoD->configure(-state => 'normal');
		$documento->configure(-state => 'normal');
		$fechaV->configure(-state => 'normal');
	}
	# o si debe registrar documentos
	if ($CntaI eq "D") {
		$tipoD->configure(-state => 'normal');
		$documento->configure(-state => 'normal');
		$fechaV->configure(-state => 'normal');
	}
}

sub muestraLista ( $ ) 
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	
	# Obtiene lista con datos de itemes registrados
	my @data = $bd->datosItems($Numero);
	# Completa TList con código, nombre cuenta, monto (d o h) 
	my ($algo, $mov, $cm, $mntD, $mntH,$ncta);
	$listaS->delete(0,'end');
	foreach $algo ( @data ) {
		$cm = $algo->[1];  # Código cuenta
		$mntD = $pesos->format_number( $algo->[2] ); 
		$mntH = $pesos->format_number( $algo->[3] );
		$ncta = substr decode_utf8($algo->[10]),0, 24 ;
		$mov = sprintf("%-5s %-24s %11s %11s", 
			$cm, $ncta, $mntD, $mntH ) ;
		$listaS->insert('end', -itemtype => 'text', -text => "$mov" ) ;
	}
	# Devuelve una lista de listas con datos de las cuentas
	return @data;
}

sub agrega ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $ut = $esto->{'mensajes'};
	
	# Verifica que se completen datos de detalle
	if (length $Codigo < 4) {
		$Mnsj = "Registre el código de la cuenta";
		$codigo->focus;
		return;
	}
	if ($Monto == 0) {
		$Mnsj = "Complete el monto";
		$monto->focus;
		return ;
	}
	if ($CntaI eq "I" and $RUT eq '' ) {
		$Mnsj = "Debe registrar RUT de la Cuenta Individual";
		$cuentaI->focus;
		return;
	}
	if ($CntaI eq "I" ) { # Control del documento
		return if not validaD($bd) ;
	}
	# Graba datos
	if ($CntaI eq "B") {
		$RUT = $cBanco ;
	}
	$bd->agregaItemT($Codigo, $Detalle, $Monto, $DH, $RUT, $cTipoD, $Documento, 
		$Cuenta, $Numero, $CCto);
	# Muestra lista modificada de cuentas
	@datos = muestraLista($esto);
	# Totaliza comprobante
	if ($DH eq 'D') {
		$TotalD += $Monto;
		$TotalDf = $pesos->format_number($TotalD);
	} else {
		$TotalH += $Monto;	
		$TotalHf = $pesos->format_number($TotalH);
	}
	limpiaCampos();
	$cuentaI->configure(-state => 'disabled');
	$tipoD->configure(-state => 'disabled');
	$documento->configure(-state => 'disabled');

	$codigo->focus;
}

sub validaD ( $ )
{
	my ($bd) = @_;
	
	my $tbl = $tabla{$cTipoD} ;
	if ( not $TipoD ) {
		$Mnsj = "Seleccione un tipo de documento";
		$tipoD->focus;
		return 0;
	} elsif (not $tbl eq '' ) {
		$tbl = 'Ventas' if $TipoCmp eq 'I' ;
		if ( not $bd->buscaFct($tbl, $RUT, $Documento, 'FechaE') ) {
			$Mnsj = "Ese documento NO está registrado.";
			$documento->focus;
			return 0;
		}
		if ( $bd->buscaFct($tbl, $RUT, $Documento, 'Pagada') ) {
			$Mnsj = "Ese documento ya está pagado.";
			$documento->focus;
			return 0;
		}
		# Compara montos: pagado no puede ser mayor que el total del documento
		my $mnt = 0 ;
		if ( $BH ) {
			$mnt = $bd->montoBH($RUT, $Documento) ;
		} else {
			$mnt = $bd->buscaFct($tbl, $RUT, $Documento, 'Total') ;
		}
		if ( $Monto > $mnt ) {
			my $mt = $pesos->format_number( $mnt );
			$Mnsj = "Monto documento es: \$ $mt";
			$documento->focus;
			return 0;
		}
	}
	return 1;
}

sub buscaRut ()
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};

	# Valida y verifica RUT, siempre que no sea un Banco o cuenta tipo D
	if ($CntaI eq "B" or $CntaI eq "D") {
		return ;
	}
	$RUT = uc($RUT);
	if ( not $ut->vRut($RUT) ) {
		$Mnsj = "RUT no es válido";
		$cuentaI->focus;
		return;
	} else {
		my $nmb = $bd->buscaT($RUT);
		if ( not $nmb ) { # Si no está en Terceros lo busca en Personal
			$nmb = $bd->buscaP($RUT);
			if ( not $nmb ) {
				$Mnsj = "Ese RUT No esta registrado" ;
				$cuentaI->focus;
				return;
			}
		}
		$Nombre = decode_utf8("$nmb");
	}
}

sub verificaD
{
	if ($TipoCmp eq 'I' and ( $cTipoD eq 'FC' or $BH )) {
		$Mnsj = "Tipo de documento NO corresponde";
		$tipoD->focus;
	}
	if ($TipoCmp eq 'E' and $cTipoD eq 'FV') {
		$Mnsj = "Tipo de documento NO corresponde";
		$tipoD->focus;
	}
}

sub monto 
{
	if ($DH eq '') {
		$Mnsj = "Indique tipo de movimiento";
		return ;
	}
	if ($Monto == 0) {
		$Mnsj = "Anote alguna cifra";
		$monto->focus;
	}
}

sub modifica ( )
{
	my ($esto) = @_;
	my $listaS = $esto->{'vLista'};
	my $bd = $esto->{'baseDatos'};
		
	$Mnsj = $TipoD = " ";
	if (not @datos) {
		$Mnsj = "NO hay movimientos para modificar";
		return;
	}
	$bNvo->configure(-state => 'disabled');
	$bReg->configure(-state => 'active');
	$bEle->configure(-state => 'active');
	# Obtiene item seleccionado
	my @ns = $listaS->info('selection');
	my $sItem = @datos[$ns[0]];
	# Rellena campos
	if ($sItem->[2] > 0) {
		$Monto = $sItem->[2];
		$DH = "D";
	}
	if ($sItem->[3] > 0) {
		$Monto = $sItem->[3];
		$DH = "H";
	}
	$Codigo = $sItem->[1];
	$Detalle = decode_utf8($sItem->[4]);
	$RUT = $sItem->[5];
	$cTipoD = $sItem->[6];
#	print "$RUT - $cTipoD\n";
	$TipoD = buscaTD( $cTipoD );
	$Documento = $sItem->[7];
	$CCto = $sItem->[8];
	$Cuenta = $sItem->[10];
	@dCuenta = $bd->dtCuenta($Codigo);	
	$CntaI = $dCuenta[1];
	
	$tipoD->configure(-state => 'normal') if $TipoD ;
	$documento->configure(-state => 'normal') if $Documento ;
	$cuentaI->configure(-state => 'normal') if $RUT ;
	# Obtiene Id del registro
	$Id = $sItem->[11];
}

sub buscaTD ( $ )
{
	my ($td) = @_;
	my $e ;
	for $e (@listaD) {
		return decode_utf8( $e->[1] ) if $e->[0] eq $td ; 
	}
}

sub registra ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	# Verifica la existencia del documento 
	if ($CntaI eq "I" ) {
		return if not validaD($bd) ;
	}
	# Graba datos
	$bd->grabaItemT($Codigo, $Detalle, $Monto, $DH, $RUT, $cTipoD, $Documento, 
		$CCto, $Cuenta, $Id);
	# Muestra lista actualizada de items
	@datos = muestraLista($esto);
	# Retotaliza comprobante
	( $TotalD, $TotalH ) = $bd->sumas($Numero);
	$TotalDf = $pesos->format_number($TotalD);
	$TotalHf = $pesos->format_number($TotalH);

	limpiaCampos();

	$cuentaI->configure(-state => 'disabled');
	$tipoD->configure(-state => 'disabled');
	$documento->configure(-state => 'disabled');
	$fechaV->configure(-state => 'disabled');

	$bNvo->configure(-state => 'active');
	$bEle->configure(-state => 'disabled');
	$bReg->configure(-state => 'disabled');
}

sub elimina ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	# Graba
	$bd->borraItemT( $Id );
	# Muestra lista actualizada de items
	@datos = muestraLista($esto);
	# Retotaliza comprobante
	if ($DH eq 'D') {
		$TotalD -= $Monto;
		$TotalDf = $pesos->format_number($TotalD);
	} else {
		$TotalH -= $Monto;	
		$TotalHf = $pesos->format_number($TotalH);
	}
	
	limpiaCampos();
	$bNvo->configure(-state => 'active');
	$bEle->configure(-state => 'disabled');
	$bReg->configure(-state => 'disabled');
}

sub contabiliza ( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	my $listaS = $esto->{'vLista'};
	my $ut = $esto->{'mensajes'} ;
	
	$Mnsj = " ";
	# Verifica que se completen datos básicos
	if ($Fecha eq '' ) {
		$Mnsj = "Anote la fecha del comprobante";
		$fecha->focus;
		return;
	}
	$Glosa = "Cancela docs. RUT $IdT" ;
	# Graba datos
	my $ff = $ut->analizaFecha($Fecha);
	$bd->agregaCmp($Numero, $ff, $Glosa, $TotalD, $TipoCmp, $BH);
	$bd->actualizaCI($Numero, $ff);
	# Graba documentos de pago, si corresponde
	my $fv = '';
	$fv = $ut->analizaFecha($FechaV) if $FechaV ;
	my $tabla = ( $TipoCmp eq "I" ) ? 'DocsR' : 'DocsE' ;
	$bd->agregaDP($Numero, $ff, $tabla, $fv);
	
	limpiaCampos();
	$bCnt->configure(-state => 'disabled');
	$listaS->delete(0,'end');
	$listaS->insert('end', -itemtype => 'text', 
			-text => "No hay movimientos registrados" ) ;
	# Inicializa variables
	$TotalD = $TotalH = 0;
	$TotalDf = $TotalHf = '';
	$Numero = $bd->numeroC() + 1;
	$fecha->focus;
}

sub validaFecha ($ $ $ $ ) 
{
	my ($ut, $v, $c, $x) = @_;
	
	$Mnsj = " ";
	if ( not $$v ) {	
		if ($x == 0) { 
			$FechaV = $Fecha ;
			return; 
		}
		$Mnsj = "Debe colocar fecha de emisión";
		$$c->focus;
		return ;
	} 
	if ( not $$v =~ m|\d+/\d+/\d+| ) {
		$Mnsj = "Formato errado: debe ser dd/mm/aaa";
		$$c->focus;
	} elsif ( not $ut->analizaFecha($$v) ) {
		$Mnsj = "Fecha incorrecta";
		$$c->focus;
	}
}

sub cancela ( )
{
	my ($esto) = @_;	
	my $vn = $esto->{'ventana'};
	my $bd = $esto->{'baseDatos'};
	limpiaCampos();
	$bd->borraTemp();
	$vn->destroy();
}

sub limpiaCampos ( )
{
	$codigo->delete(0,'end');
	$detalle->delete(0,'end');
	$Monto = $BH = 0;
	$DH = $TipoD = $Documento = $RUT = $Cuenta = $cBanco = $FechaV = $Nombre = $IdT = '' ;
	$NCCto = $CCto = '';
	# Activa o no contabilizar el comprobante
	if ($TotalH == $TotalD) {
		$bCnt->configure(-state => 'active');
	} else {
		$bCnt->configure(-state => 'disabled');
	}
}

sub llenaT ( $ ) # Muestra en la tabla datos de los documentos impagos
{
	my ($esto) = @_;
	my $ut = $esto->{'mensajes'};
	my $bd = $esto->{'baseDatos'};
	
	$IdT = uc($IdT);
	if ( $IdT eq '' ) {
		$Mnsj = "Indique un RUT";
		$id->focus;
		return;
	}
	if ( not $ut->vRut($IdT) ) {
		$Mnsj = "RUT no es válido";
		$id->focus;
		return;
	} else {
		my $nmb = $bd->buscaT($IdT);
		if ( not $nmb ) { 
			$Mnsj = "Ese RUT No esta registrado" ;
			$id->focus;
			return;
		}
	}
	my $tb = $BH ? "BoletasH" : $archivo ;
	my @data = $bd->datosFacts($IdT,$tb,1);
	if ( not @data ) {
			$Mnsj = "NO hay datos para ese RUT" ;
			$id->focus;
			return;		
	}
	$rows = @data ;
	$fila = 0;
	my $algo ;
	foreach $algo ( @data ) {
		$tab->{"$fila,0"} = "No";
		$tab->{"$fila,1"} = $algo->[8];
		$tab->{"$fila,2"} = $algo->[0];
		$tab->{"$fila,3"} = $pesos->format_number($algo->[2]);
		$tab->{"$fila,4"} = $pesos->format_number($algo->[3]);
		$tab->{"$fila,5"} =  $ut->cFecha($algo->[4]);
		$tab->{"$fila,6"} = $algo->[9]; # Cuenta de mayor
		$t->tagCell('No', "$fila,0");
		$fila += 1;
	}
    return if (!$t);
	$t->configure(-rows => $rows ) ;
    $t->configure(-padx =>($t->cget(-padx)));
}

sub agregaDT ( $ $ $ $)
{
	my ($esto,$td,$nd,$mt,$ct) = @_;
	my $bd = $esto->{'baseDatos'};
	
	$DH = ($TipoCmp eq 'E') ? 'D' : 'H' ;
	@dCuenta = $bd->dtCuenta($ct);
	$Cuenta = decode_utf8($dCuenta[0]);
	my $dt = "$td #$nd $Idt";
	$bd->agregaItemT($ct, $dt, $mt, $DH, $IdT, $td, $nd, $Cuenta, $Numero, '');
	# Muestra lista modificada de items
	@datos = muestraLista($esto);
	# Totaliza comprobante
	if ($DH eq 'D') {
		$TotalD += $mt;
		$TotalDf = $pesos->format_number($TotalD);
	} else {
		$TotalH += $mt;	
		$TotalHf = $pesos->format_number($TotalH);
	}
}

sub borraDT ( $ $ )
{
	my ($esto,$nd,$mt) = @_;
	my $bd = $esto->{'baseDatos'};
	
	print "del: $td $nd $Numero \n";
	$bd->borraItemDT( $nd, $Numero );
	# Muestra lista modificada de items
	@datos = muestraLista($esto);
	# Retotaliza comprobante
	if ($TipoCmp eq 'E') {
		$TotalD -= $mt;
		$TotalDf = $pesos->format_number($TotalD);
	} else {
		$TotalH -= $mt;	
		$TotalHf = $pesos->format_number($TotalH);
	}
}

# Fin del paquete
1;
