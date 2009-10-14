#  Pagos.pm - Contabiliza pagos
#  Forma parte del programa Quipu
# 
#  Derechos de autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM: 05.10.2009

package Pagos;
		
sub crea {

	my ($esto, $vp, $bd, $ut, $tipo, $marcoT,) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables

	$ut->mError("Contabiliza Pagos $tipo: Falta implementar");

	bless $esto;
	return $esto;
}

# Funciones internas


# Fin del paquete
1;
