#  RBanco.pm - Registra Conciliación Banco
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) Víctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 

package RBanco;
		
sub crea {

	my ($esto, $vp, $marcoT, $bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables

	$ut->mError("Registra Conciliación Banco: Falta implementar");

	bless $esto;
	return $esto;
}

# Funciones internas


# Fin del paquete
1;
