#  FVentas.pm - Registra Facturas de Ventas para la apertura
#  Forma parte del Programa PartidaDoble
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la licencia
#  incluida en este paquete

package FVentas;

		
sub crea {

	my ($esto, $vp, $bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables

	$ut->mError("FVentas: Falta implementar");

	bless $esto;
	return $esto;
}

# Funciones internas


# Fin del paquete
1;
