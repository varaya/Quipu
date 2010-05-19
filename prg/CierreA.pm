#  CierreA.pm - Efect�a el cierre del a�o contable
#  Forma parte del programa Quipu
#
#  Derechos de Autor: V�ctor Araya R., 2010 [varayar@gmail.com]
#  
#  Puede ser utilizado y distribuido en los t�rminos previstos en la 
#  licencia incluida en este paquete
#  UM : 19.05.2010 

package CierreA;

use Date::Simple ('ymd','today');
use DBI;

sub crea {

	my ($esto, $bd, $ut, $rut, $final, $ejer, $cierre) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;

  	# Inicializa variables
	my $mns = $final ? 'final' : 'provisorio' ; 
	my @aa = split /-/, today() ;	
	my $prd = $aa[0] ;
	if ($prd eq $ejer) {
		$ut->mError("NO se puede efectuar el cierre durante el mismo a�o.");
		return ;		
	}
	my $base = "$rut/$prd.db3";
	if ($final) {
		print "Copiando saldos\n";
		$bd->copiaSaldos($base,$cierre) ;
		$ut->mError("Cierre $mns procesado.");
		return ;
	}
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
