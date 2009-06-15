#  PlanC.pm - Muestra y archiva Plan de Cuentas
#  Forma parte del programa QUIPU
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete 


	my ($bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables

	# Define ventanas
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Selecciona Empresa");
	$vnt->geometry("300x60+495+40"); # Tamaño y ubicación

	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	my $bImp = $mBotonesC->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mt);} ],
 	  ['command' => "planilla", -command => sub { csv($bd);} ] ] );
	my $bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy();} );
	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => 'fixed',
		-bg => '#F2FFE6', -fg => '#800000',);
	$mnsj->pack(-side => 'right', -expand => 1, -fill => 'x');
	my $img = $vnt->Photo(-file => "info.gif") ;
	my $bAyd = $mMensajes->Button(-image => $img, 
		-command => sub { $ut->ayuda($mt, 'Compras'); } ); 
	$bAyd->pack(-side => 'left', -expand => 0, -fill => 'none');
	$Mnsj = "Mensajes de error o advertencias.";

	# Dibuja interfaz
	$bCan->pack(-side => 'right', -expand => 0, -fill => 'none');
	$bImp->pack(-side => 'right', -expand => 0, -fill => 'none');
	$mBotonesC->pack();
	$mMensajes->pack(-expand => 1, -fill => 'both');
	
	return ;
}

# Funciones internas
sub txt ($)
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');
	# Genera archivo de texto
	open ARCHIVO, "> inf/planC.txt" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Grabado en 'txt/planC.txt'";
}

sub csv ($)
{
	my ($bd) = @_;
	
	my @listaG = $bd->datosGrupos() ;
	my @datosC = $bd->datosCuentas() ;
	my @datosE = $bd->datosEmpresa() ;

	my ($xgrp, $ngrp, $dcta, $xy, $xt);
	my $empresa = decode_utf8($datosE[0]) ;

	open ARCHIVO, "> csv/planC.csv" or die $! ;
	$l =  "PLAN DE CUENTAS - $empresa";
	print ARCHIVO "$l\n";
	$l = "Código,Cuenta,IE,CI,SN";
	print ARCHIVO "$l\n";
	foreach $xgrp ( @listaG ) {
		$xt = decode_utf8($xgrp->[1]) ;
		$l = '"'."$xgrp->[0] $xt".'"';
		print ARCHIVO "$l\n";
		foreach $dcta ( @datosC ) {
			if ( $xgrp->[0] eq $dcta->[2] ) {
				$xy = '"'.decode_utf8($dcta->[1]).'"' ;
				$l = "$dcta->[0],$xy,$dcta->[3],$dcta->[4],$dcta->[5]" ;
				print ARCHIVO "$l\n";
			}
		}
	}
	
	close ARCHIVO ;
	$Mnsj = "Grabado en 'csv/planC.csv'";
}

# Fin del paquete
1;
