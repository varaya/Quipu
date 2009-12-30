#  AjustaCH.pm - Cambia número cheque en un comprobante
#  (cambios que no afectan las cuentas de mayor o las individuales)
#  Forma parte del programa Quipu
#
#  Derechos de Autor (c) Víctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete 
#  UM: 30.12.2009

package AjustaCH;

use Tk::LabEntry;
use Tk::LabFrame;
use Encode 'decode_utf8';

my ($NumD,$Id,$NumN,$NumA,$numD);

sub crea {
	my ($esto, $vp, $bd, $ut, $mt) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

	# Define ventana
	my $vnt = $vp->Toplevel();
	$vnt->title("Ajusta Comprobante");
	$vnt->geometry("300x230+475+2"); # Tamaño y ubicación

	my %tp = $ut->tipos();
	inicializa();
	# Defime marcos
	my $mDatosC = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Buscar Comprobante:');
	my $mDatos = $vnt->LabFrame(-borderwidth => 1, -labelside => 'acrosstop',
		-label => 'Datos modificables:');
	my $mBtns = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{fx},
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	$Mnsj = "Indique # Comprobante y Cheque";
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
	$numD = $mDatosC->LabEntry(-label => " # ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$NumD );
	$numA = $mDatosC->LabEntry(-label => "Ch #: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$NumA, -disabledbackground => '#FFFFFC', 
		-disabledforeground => '#000000'  );
		
	$numN = $mDatos->LabEntry(-label => "Ch #: ", -width => 10,
		-labelPack => [-side => "left", -anchor => "e"], -bg => '#FFFFCC',
		-textvariable => \$NumN, -disabledbackground => '#FFFFFC', 
		-disabledforeground => '#000000'  );

	$numA->bind("<FocusOut>", sub { &buscaDoc($esto) } );

	# Dibuja interfaz
	$numD->grid(-row => 0, -column => 0, -sticky => 'nw');
	$numA->grid(-row => 0, -column => 1, -sticky => 'nw');
	
	$numN->grid(-row => 1, -column => 0, -sticky => 'nw');
	
	$bNvo->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bCan->pack(-side => 'left', -expand => 0, -fill => 'none');
	$bFin->pack(-side => 'right', -expand => 0, -fill => 'none');

	$mMensajes->pack(-expand => 1, -fill => 'both');
	$mDatosC->pack(-expand => 1);
	$mDatos->pack(-expand => 1);	
	$mBtns->pack(-expand => 1);

	$numN->configure(-state => 'disable');

	$numD->focus;
	
	bless $esto;
	return $esto;
}

# Funciones internas
sub cancela
{
	inicializa();
	$numN->configure(-state => 'disable');
	$numD->focus ;
}

sub registra ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'} ;
	my $ut = $esto->{'mensajes'} ;
	
	# Actualiza datos
	$bd->modificaCH($Id,$NumN,$NumA,$NumD);

	$Mnsj = "Registro actualizado";
	inicializa();
	$numN->configure(-state => 'disable');
	$numD->focus;
}

sub inicializa 
{
	$NumD = $NumN = $NumA = '';

}

sub buscaDoc ( $ )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'} ;
	my $ut = $esto->{'mensajes'} ;
	
	if ($NumD eq '' ) {
		$Mnsj = "Indicar número comprobante";
		$numD->focus;
		return ;
	} 
	if ($NumA eq '' ) {
		$Mnsj = "Indicar número cheque";
		$numA->focus;
		return ;
	} 
	$Id = $bd->buscaCH($NumD,$NumA);
	if (not $Id ) {
		$Mnsj = "Datos errados";
		$numD->focus;
		return ;
	}
	$numN->configure(-state => 'normal');
	$numN->focus;
}

# Fin del paquete
1;
