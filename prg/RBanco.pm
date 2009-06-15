#  RBanco.pm - Registra Conciliaci�n Banco
#  Forma parte del programa Quipu
#
#  Propiedad intelectual (c) V�ctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los t�rminos previstos en la 
#  licencia incluida en este paquete 

package RBanco;
		
sub crea {

	my ($esto, $vp, $marcoT, $bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables

	$ut->mError("Registra Conciliaci�n Banco: Falta implementar");

	bless $esto;
	return $esto;
}

# Funciones internas


# Fin del paquete
1;
