#  AnulaD.pm - Anula documento
#  Forma parte del Programa Quipu
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete

package AnulaD;

		
sub crea {

	my ($esto, $vp, $bd, $ut, $tipo) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables

	$ut->mError("Anula Documento $tipo: Falta implementar");

	bless $esto;
	return $esto;
}

# Funciones internas


# Fin del paquete
1;
