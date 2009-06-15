#  Impgs.pm - Consulta e imprime lista de documentos impagos
#  Forma parte del Programa Quipu
#  Propiedad intelectual Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete

package Impgs;
		
sub crea {

	my ($esto, $vp, $marcoT, $bd, $ut, $tipo) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables

	$ut->mError("Documentos Impagos: Falta implementar");

	bless $esto;
	return $esto;
}

# Funciones internas


# Fin del paquete
1;
