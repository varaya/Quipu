#  CierreA.pm - Efectúa el cierre del año contable
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete
#  UM : 03.01.2010 

package CierreA;

use Date::Simple ('ymd','today');
use DBI;

sub crea {

	my ($esto, $bd, $ut, $rut, $final, $ejer) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	my $mns = $final ? 'final' : 'provisorio' ; 
	my @aa = split /-/, today() ;	
	my $prd = $aa[0] ;
	if ($prd eq $ejer) {
		$ut->mError("NO se puede efectuar el cierre durante el mismo año.");
		return ;		
	}
	if ($final) {
		$ut->mError("Cierre $mns pendiente.");
		return ;
	}
	my $base = "$rut/$prd.db3";
	if (not -e $base ) {
		print "Creando $base\n";
		system "./creaTablasRC.pl", $rut, $prd ;
		print "Copiando tablas\n";
		$bd->copiaTablas($base);
		$ut->mError("Cierre $mns procesado.");
	} else {
		$ut->mError("Cierre $mns YA procesado.");
	}

	bless $esto;
	return $esto;
}

# Fin del paquete
1;
