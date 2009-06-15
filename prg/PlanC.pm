#  PlanC.pm - Muestra y archiva Plan de Cuentas
#  Forma parte del programa Quipu 
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package PlanC;

use Encode 'decode_utf8';
use prg::Listado;

my ($rutE);
my $informe = 'Plan de Cuentas';

sub crea {

	my ($esto, $vp, $mt, $bd, $ut, $rtE) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	$rutE = $rtE ;
	my %tp = $ut->tipos();

	# Define ventanas
	my $vnt = $vp->Toplevel();
	$esto->{'ventana'} = $vnt;
	$vnt->title("Plan de Cuentas");
	$vnt->geometry("300x60+475+4"); # Tamaño y ubicación

	my $mBotonesC = $vnt->Frame(-borderwidth => 1);
	my $mMensajes = $vnt->Frame(-borderwidth => 2, -relief=> 'groove' );

	my $bImp = $mBotonesC->Menubutton(-text => "Archivo", -tearoff => 0, 
	-underline => 0, -indicatoron => 1, -relief => 'raised',-menuitems => 
	[ ['command' => "texto", -command => sub { txt($mt);} ],
 	  ['command' => "planilla", -command => sub { csv($bd);} ],
	  ['command' => "pdf", -command => sub { pdf($bd,$ut);} ] ] );
	my $bCan = $mBotonesC->Button(-text => "Cancela", 
		-command => sub { $vnt->destroy();} );
	# Barra de mensajes y botón de ayuda
	my $mnsj = $mMensajes->Label(-textvariable => \$Mnsj, -font => $tp{tx},
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
	
	$ut->muestraPC($mt,$bd,1,$rutE);

	bless $esto;
	return $esto;
}

# Funciones internas
sub txt ( $ )
{
	my ($marco) = @_;	
	
	my $algo = $marco->get('0.0','end');
	# Genera archivo de texto
	my $d = "$rutE/txt/planC.txt" ;
	open ARCHIVO, "> $d" or die $! ;
	print ARCHIVO $algo ;
	close ARCHIVO ;
	$Mnsj = "Ver en '$d'";
}

sub csv ( $ )
{
	my ($bd) = @_;
	
	my @listaG = $bd->datosGrupos() ;
	my @datosC = $bd->datosCuentas() ;
	my @datosE = $bd->datosEmpresa($rutE) ;

	my ($xgrp, $ngrp, $dcta, $xy, $xt, $d);
	my $empresa = decode_utf8($datosE[0]) ;
	
	$d = "$rutE/csv/planC.csv";
	open ARCHIVO, "> $d" or die $! ;
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
	$Mnsj = "Grabado en '$d'";
}

sub pdf ( $ $ )
{
	my ($bd, $ut) = @_;
	
	my @listaG = $bd->datosGrupos() ;
	my @datosC = $bd->datosCuentas() ;
	my @datosE = $bd->datosEmpresa($rutE) ;
	my $fecha = $ut->fechaHoy();
	my $empresa = decode_utf8($datosE[0]) ;
	my $tG = @listaG ;
	my $tC = @datosC ;
	my $tR = $tG + $tC ; # Permite determinar el último registro

	my $pdf = Listado->crea(CreationDate => $fecha , Title => $informe ,
		Subject => 'Listados', Author => $empresa );
	$pdf->nuevaPgn();

	my $inicio = $pdf->{AltoCaja};
	my ($iz, $dr) = ('izquierda', 'derecha');
	my ($xgrp, $ngrp, $dcta, $xy, $xt, $d);
	
	$d = "$rutE/pdf/planC.pdf";
	$pdf->iTitulo("PLAN DE CUENTAS - $empresa",'darkblue','Helvetica-Bold',14);
	$pdf->saltaLineas(1); 

	my $aCols = [45, 230, 25, 25, 25];
	my $fCols = [$iz, $iz, $dr, $dr, $dr];
	my $encabezado = ['Código','Cuenta','CI','IE','SN'];
	$pdf->iRegistro($encabezado, $aCols, $fCols, $tR, titulo => 1, 
		 color => 'darkgreen', fuente => 'Helvetica-Oblique', cuerpo => 11);  
	$pdf->fuente('Helvetica'); $pdf->cuerpo(11);
	my $datos = [];
	my $bordeI = $pdf->{margenY} * 2 ;

	foreach $xgrp ( @listaG ) {
		if ( ($pdf->{vPos} - $pdf->{cuerpo}) < $bordeI ) {
		  finPgn($pdf, $encabezado, $aCols, $fCols);
		}
		$xt = decode_utf8($xgrp->[1]) ;
		$datos = [ $xgrp->[0], $xt, ' ', ' ', ' ' ];
		$tR -= 1;
		$pdf->iRegistro($datos, $aCols, $fCols, $tR, color => 'firebrick');
		foreach $dcta ( @datosC ) {
			if ( $xgrp->[0] eq $dcta->[2] ) {
				if ( ($pdf->{vPos} - $pdf->{cuerpo}) < $bordeI ) {
				  finPgn($pdf, $encabezado, $aCols, $fCols);
				}
				$xy = decode_utf8($dcta->[1]) ;
				$datos = [ $dcta->[0],$xy,$dcta->[4],$dcta->[3],$dcta->[5] ] ;
				$tR -= 1;
				$pdf->iRegistro($datos, $aCols, $fCols, $tR);
			}
		}
	}
	$pdf->numeroPgn($informe);
	$pdf->grabar($d); 
	$Mnsj = "Grabado en '$d'";
	system "xpdf", $d ;
}

sub finPgn {
	my ($obj, $d, $a, $f) = @_;

	$obj->numeroPgn($informe);
	$obj->nuevaPgn();
	$obj->{vPos} = $obj->{AltoCaja} ;
	$obj->iRegistro($d, $a, $f, fuente => 'Helvetica-Oblique', cuerpo => 11,
		color => 'darkgreen', titulo => 1);
	$obj->fuente('Helvetica'); 
	$obj->cuerpo(11);
}

# Fin del paquete
1;
