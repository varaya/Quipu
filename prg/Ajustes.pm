#  Ajustes.pm - Cambia fecha de contabilizacion o número de un documento
#  (cambios que no afectan las cuentas de mayor o las individuales)
#  Forma parte del programa Quipu
#
#  Derechos de Autor (c) Víctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete 
#  UM: 21.07.2009

package Ajustes;

use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';

my ($NumC,$FechaC,$FechaE,$TpD,$NumD,$Ni,$Tabla,$Id,$TipoD,$Mes,$TD);

sub crea {
	my ($esto, $vp, $bd, $ut, $mt) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Ajustes");
	$vnt->geometry("300x310+475+2"); # Tamaño y ubicación

	my %tp = $ut->tipos();
	inicializa();
	# Defime marcos
	my $mTipoA = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Seleccione Ajuste:');
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Buscar Documento:');
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Datos registrados:');
	my $mBtns = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{fx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	$Mnsj = "Seleccione tipo de ajustes.";
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Ajustes'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');

	# Define botones
	$bNvo = $mBtns->Button(-text => "Registra", -command => sub { &registra($esto)}); 
	$bCan = $mBtns->Button(-text => "Cancela", -command => sub { &cancela() });
	$bFin = $mBtns->Button(-text => "Termina", -command => sub { $vnt->destroy(); });

	# Parametros
	$cn = $mTipoA->Radiobutton( -text => "Número", -value => 'N', 
		-variable => \$TA , -command => sub { &activa() });
	$cf = $mTipoA ->Radiobutton( -text => "Fechas", -value => 'F', 
		-variable => \$TA, -command => sub { &activa() } );
	$tp = $mTipoA->Radiobutton( -text => "Tipo", -value => 'T', 
		-variable => \$TA , -command => sub { &activa() });
	$mes = $mDatosC->LabEntry(-label => "Mes: ", -width => 3,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Mes );
	$de = $mDatosC->Radiobutton( -text => "Emitida", -value => 'Ventas', 
		-variable => \$Tabla );
	$dr = $mDatosC->Radiobutton( -text => "Recibida", -value => 'Compras', 
		-variable => \$Tabla );
	$fc = $mDatosC->Radiobutton( -text => "Factura", -value => 'F', 
		-variable => \$TipoD );
	$nc = $mDatosC->Radiobutton( -text => "N.Crédito", -value => 'NC', 
		-variable => \$TipoD );
	$nd = $mDatosC->Radiobutton( -text => "N.Débito", -value => 'ND', 
		-variable => \$TipoD );
	$ni = $mDatosC->LabEntry(-label => "Nº I: ", -width => 5,
		-labelPack => [-side => "left", -anchor => "w"], -bg => '#FFFFCC',
		-textvariable => \$Ni );

	# Define campos para registro de datos de la empresa
	$rut = $mDatos->LabEntry(-label => "RUT:  ", -width => 12,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$Rut, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000' );
	$numD = $mDatos->LabEntry(-label => "Doc. # ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$NumD, -disabledbackground => '#FFFFFC', 
		-disabledforeground => '#000000'  );
	$numC = $mDatos->LabEntry(-label => "Nº C ", -width => 6,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$NumC, -state => 'disabled',
		-disabledbackground => '#FFFFFC', -disabledforeground => '#000000');
	$tipoD = $mDatos->LabEntry(-label => "M o E: ", -width => 3,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$TpD, -disabledbackground => '#FFFFFC', 
		-disabledforeground => '#000000' );
	$fechaE = $mDatos->LabEntry(-label => "Emitida: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$FechaE, -disabledbackground => '#FFFFFC', 
		-disabledforeground => '#000000' );
	$fechaC = $mDatos->LabEntry(-label => "Contabilizada: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$FechaC, -disabledbackground => '#FFFFFC', 
		-disabledforeground => '#000000' );

	$ni->bind("<FocusOut>", sub { &buscaDoc($esto) } );

	# Dibuja interfaz
	$cn->grid(-row => 0, -column => 0, -sticky => 'nw');
	$cf->grid(-row => 0, -column => 1, -sticky => 'nw');
	$tp->grid(-row => 0, -column => 2, -sticky => 'nw');
	$mes->grid(-row => 0, -column => 0, -sticky => 'nw');
	$de->grid(-row => 0, -column => 1, -sticky => 'nw');
	$dr->grid(-row => 0, -column => 2, -sticky => 'nw');
	$fc->grid(-row => 1, -column => 0, -sticky => 'nw');
	$nc->grid(-row => 1, -column => 1, -sticky => 'nw');
	$nd->grid(-row => 1, -column => 2, -sticky => 'nw');
	$ni->grid(-row => 2, -column => 2, -sticky => 'nw');

	$rut->grid(-row => 0, -column => 0, -sticky => 'nw');
	$numD->grid(-row => 0, -column => 1, -sticky => 'nw');
	$numC->grid(-row => 1, -column => 0, -sticky => 'nw');
	$tipoD->grid(-row => 1, -column => 1, -sticky => 'nw') ;
	$fechaE->grid(-row => 2, -column => 0, -sticky => 'nw');
	$fechaC->grid(-row => 2, -column => 1, -sticky => 'nw');
	
	$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bFin->pack(-side => 'right', -expand => 0, -fill => 'none');

	$mMensajes->pack(-expand => 1, -fill => 'both');
	$mTipoA->pack(-expand => 1);
	$mDatosC->pack(-expand => 1);
	$mDatos->pack(-expand => 1);	
	$mBtns->pack(-expand => 1);

	$ni->configure(-state => 'disable');
	$numD->configure(-state => 'disable');
	$mes->configure(-state => 'disable');
	$fechaC->configure(-state => 'disable');
	$fechaE->configure(-state => 'disable');
	$tipoD->configure(-state => 'disable');

	$cn->focus ;

	bless $esto;
	return $esto;
}

# Funciones internas
sub cancela
{
	inicializa();
	$ni->configure(-state => 'disable');
	$numD->configure(-state => 'disable');
	$mes->configure(-state => 'disable');
	$fechaC->configure(-state => 'disable');
	$fechaE->configure(-state => 'disable');
	$tipoD->configure(-state => 'disable');
	$cn->focus ;
}

sub validaFecha ( $ $ $ $ )
{
	my ($ut, $bd, $fch, $txt) = @_;
	
	if ($fch eq '' ) {
		$Mnsj = "Anote la fecha de $txt.";
		return 0;
	}
	# Valida fecha contabilización
	if (not $FechaC =~ m|\d+/\d+/\d+|) {
		$Mnsj = "Problema con formato fecha";
		return 0;
	} elsif ( not $ut->analizaFecha($fch) ) {
		$Mnsj = "Fecha incorrecta" ;
		return 0;
	}	
	return 1; 
}

sub registra ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'} ;
	my $ut = $esto->{'mensajes'} ;
	
	if ( not validaFecha($ut,$bd,$FechaE,'emisión') ) {
		$fechaE->focus;
		return ;
	} 
	if ( not validaFecha($ut,$bd,$FechaC,'contabilización') ) {
		$fechaC->focus;
		return ;
	} 
	# Actualiza datos
	my $fc = $ut->analizaFecha($FechaC) ;
	my $fe = $ut->analizaFecha($FechaE) ;
	$bd->cambiaDcm($NumC,$fc,$fe,$TpD,$NumD,$Ni,$Tabla,$Id,$TD);

	$Mnsj = "Registro actualizado";
	inicializa();
	$cn->focus;
}

sub inicializa 
{
	$NumC = $FechaC = $FechaE = $TpD = $NumD = $Ni = $Tabla = $Id = '';
	$TipoD = $Mes = $Rut = $TA = $TD = '';
}

sub buscaDoc ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'} ;
	my $ut = $esto->{'mensajes'} ;
	
	if ($TipoD eq '') {
		$Mnsj = "Indicar tipo";
		$fc->focus ;
		return ;
	}
	if ($Tabla eq '' ) {
		$Mnsj = "Marcar Emitida o Recibida";
		$de->focus;
		return ;
	}
	$TD = $TipoD eq 'F' ? $TipoD . substr $Tabla,0,1 : $TipoD ;
	print "$Tabla, $Mes, $Ni, $TD";
	my @datos = $bd->buscaNI($Tabla,$Mes,$Ni,$TD);
	if (not @datos) {
		$Mnsj = "NO existe documento con esos datos";
		$mes->focus;
		return ;
	}
	$Rut =  $datos[0];
	$NumD = $datos[1];
	$NumC = $datos[2];
	$TpD =  $datos[3];
	$Id  =  $datos[5];
	$FechaE = $ut->cFecha($datos[4]) ;
	my @dtsC = $bd->consultaC($NumC);
	$FechaC = $ut->cFecha($dtsC[2]);
}

sub activa ( ) 
{
	$mes->configure(-state => 'normal');
	$ni->configure(-state => 'normal');
	if ( $TA eq 'F') {
		$numD->configure(-state => 'disable');
		$fechaE->configure(-state => 'normal');
		$fechaC->configure(-state => 'normal');
		$tipoD->configure(-state => 'disable');
	} elsif ($TA eq 'N') {
		$numD->configure(-state => 'normal');
		$fechaC->configure(-state => 'disable');
		$fechaE->configure(-state => 'disable');
		$tipoD->configure(-state => 'disable');
	} else {
		$numD->configure(-state => 'disable');
		$fechaC->configure(-state => 'disable');
		$fechaE->configure(-state => 'disable');
		$tipoD->configure(-state => 'normal');
	}
}

# Fin del paquete
1;
