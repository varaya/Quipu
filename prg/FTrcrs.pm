#  FTrcrs.pm - CFacturas de Compras de Terceros
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la
#  licencia incluida en este paquete 
#  UM : 23.06.2009

package FTrcrs;
		
sub crea {

	my ($esto, $vp, $bd, $ut, $tipoF, $mt, $ucc, $pIVA ) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables

	$ut->mError("Facturas de Terceros $tipoF: Falta implementar");

	bless $esto;
	return $esto;
}

# Funciones internas


# Fin del paquete
1;
