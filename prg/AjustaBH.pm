#  AjustaBH.pm - Cambia fecha de contabilizacion o número de una BH
#  (cambios que no afectan las cuentas de mayor o las individuales)
#  Forma parte del programa Quipu
#
#  Derechos de Autor (c) Víctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete 
#  UM: 30.07.2009

package AjustaBH;

use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';

my ($FechaC,$FechaE,$NumD,$Ni,$Id,$Mes,$NumN,$NumC,$Rut);

sub crea {
	my ($esto, $vp, $bd, $ut, $mt) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Ajusta Boleta");
	$vnt->geometry("300x230+475+2"); # Tamaño y ubicación

	my %tp = $ut->tipos();
	inicializa();
	# Defime marcos
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Buscar Documento:');
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Datos modificables:');
	my $mBtns = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{fx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	$Mnsj = "Indique Rut y # documento";
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

	$numN = $mDatos->LabEntry(-label => "Número: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$NumN, -disabledbackground => '#FFFFFC', 
		-disabledforeground => '#000000'  );
	$fechaE = $mDatos->LabEntry(-label => "Emitida: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$FechaE, -disabledbackground => '#FFFFFC', 
		-disabledforeground => '#000000' );
	$fechaC = $mDatos->LabEntry(-label => "Contabilizada: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$FechaC, -disabledbackground => '#FFFFFC', 
		-disabledforeground => '#000000' );

	$numD->bind("<FocusOut>", sub { &buscaDoc($esto) } );

	# Dibuja interfaz
	$rut->grid(-row => 0, -column => 0, -sticky => 'nw');
	$numD->grid(-row => 0, -column => 1, -sticky => 'nw');
	
	$numN->grid(-row => 1, -column => 0, -sticky => 'nw');
	$fechaE->grid(-row => 2, -column => 0, -sticky => 'nw');
	$fechaC->grid(-row => 2, -column => 1, -sticky => 'nw');
	
	$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bFin->pack(-side => 'right', -expand => 0, -fill => 'none');

	$mMensajes->pack(-expand => 1, -fill => 'both');
	$mDatosC->pack(-expand => 1);
	$mDatos->pack(-expand => 1);	
	$mBtns->pack(-expand => 1);

	$fechaC->configure(-state => 'disable');
	$fechaE->configure(-state => 'disable');
	$numN->configure(-state => 'disable');

	$rut->focus;
	
	bless $esto;
	return $esto;
}

# Funciones internas
sub cancela
{
	inicializa();
	$fechaC->configure(-state => 'disable');
	$fechaE->configure(-state => 'disable');
	$numN->configure(-state => 'disable');
	$rut->focus ;
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
	$NumN = $NumD if $NumN eq '' ;
	print " $NumC \n";
	$bd->cambiaBH($Rut,$NumC,$fc,$fe,$NumN,$Ni);

	$Mnsj = "Registro actualizado";
	inicializa();
	$rut->focus;
}

sub inicializa 
{
	$FechaC = $FechaE = $NumD = $NumN = $Ni = $Mes = $Rut = '';
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
	$Ni = $bd->buscaFct('BoletasH',$Rut,$NumD,'ROWID');
	if (not $Ni) {
		$Mnsj = "NO existe documento con esos datos";
		$rut->focus;
		return ;
	} else {
		my @datos = $bd->datosFct('BoletasH',$Rut,$NumD);
		$FechaE = $ut->cFecha($datos[2]);
		$NumC = $datos[5];
		$Mes = $datos[10];
		my @dtsC = $bd->consultaC($NumC);
		$FechaC = $ut->cFecha($dtsC[2]);
		$fechaC->configure(-state => 'normal');
		$fechaE->configure(-state => 'normal');
		$numN->configure(-state => 'normal');
		$numN->focus;
		$Mnsj = "Comprobante $NumC - mes $Mes";
	}
}

# Fin del paquete
1;
