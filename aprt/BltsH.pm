#  BltsH.pm - Registra Boletas de Honorarios para la apertura
#  Forma parte del Programa PartidaDoble
#  Propiedad intelectual (c) V�ctor Araya R., 2008
#  
#  Puede ser utilizado y distribuido en los t�rminos previstos en la licencia
#  incluida en este paquete

package BltsH;

		
sub crea {

	my ($esto, $vp, $bd, $ut) = @_;

	$esto = {};
	$esto->{'baseDatos'} = $bd;
	$esto->{'mensajes'} = $ut;
  	# Inicializa variables

	$ut->mError("BltsH: Falta implementar");

	bless $esto;
	return $esto;
}

# Funciones internas


# Fin del paquete
1;
