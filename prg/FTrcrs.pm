#  FTrcrs.pm - CFacturas de Compras de Terceros
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) V�ctor Araya R., 2009
#  
#  Puede ser utilizado y distribuido en los t�rminos previstos en la 
#  licencia incluida en este paquete 

package FTrcrs;
		
sub crea {

	my ($esto, $vp, $marcoT, $bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables

	$ut->mError("Facturas de Terceros: Falta implementar");

	bless $esto;
	return $esto;
}

# Funciones internas


# Fin del paquete
1;
