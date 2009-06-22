#  BaseDatos.pm - Manejo de la base de datos en SQLite 3.2 o superior
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM: 19.06.2009

package BaseDatos;

use strict;
use DBI;

sub crea
{
  my ($esto, $nBD) = @_;
  
  $esto = {};
  $esto->{'baseDatos'} = DBI->connect( "dbi:SQLite:$nBD" ) || 
	die "NO se pudo conectar base de datos: $DBI::errstr";
  $esto->{'baseDatos'}->{'RaiseError'} = 1;

  bless $esto;
  return $esto;
}

sub cierra
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};
	
	$bd->disconnect();
}

sub anexaBD
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};

	$bd->do("ATTACH DATABASE 'datosG.db3' AS dg;");
	
}


# CONFIG: Rescata datos de configuración
sub leeCnf( )
{
	my ($esto) = @_;
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT * FROM Config;");
	$sql->execute();
	my @dts = $sql->fetchrow_array;
	$sql->finish();
	
	return @dts; 
}

sub grabaCnf($ $ )
{
	my ($esto, $me, $prd) = @_;
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("INSERT OR IGNORE INTO Config VALUES(?,0,0,?);");
	$sql->execute($prd, $me);
	$sql->finish();	 
}


# EMPRESAS: Lee y registra DatosE
sub listaEmpresas( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT Rut,Nombre FROM DatosE ORDER BY Nombre;");
	$sql->execute();
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub buscaE( $ )
{
	my ($esto, $rut) = @_;	
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT Nombre FROM DatosE WHERE Rut = ?;");
	$sql->execute($rut);
	my $dato = $sql->fetchrow_array;
	$sql->finish();

	return $dato; 
}

sub datosEmpresa( $ )
{
	my ($esto, $rut) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT * FROM dg.DatosE WHERE Rut = ?;");
	$sql->execute($rut);
	my @dts = $sql->fetchrow_array;
	$sql->finish();
	
	return @dts; 
}	

sub datosE( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT * FROM DatosE");
	$sql->execute();
	my @dts = $sql->fetchrow_array;
	$sql->finish();
	
	return @dts; 
}	

sub grabaDatosE( $ )
{
	my ($esto, @dt) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("UPDATE dg.DatosE SET Datos=1, Nombre=?, Giro=?,   
		RutRL=?, NombreRL=?, OtrosI = ?, BltsCV = ?, CBanco = ?, CCostos = ?, 
		CPto = ? WHERE Rut=?;");
	$sql->execute($dt[0],$dt[2],$dt[3],$dt[4],$dt[5],$dt[6],$dt[7],$dt[8],$dt[9],$dt[1]);
	$sql->finish();
} 

sub agregaE($ $ $ $ )
{
	my ($esto, $rut, $nmr, $multi, $prd) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("INSERT INTO DatosE VALUES(?,?,'','','',0,0,0,0,0,0,?);");
	$sql->execute($nmr,$rut,$prd);
	$sql = $bd->prepare("UPDATE Config SET InterE = 0,Periodo = ?, MultiE = ?");
	$sql->execute($prd,$multi);
	$sql->finish();
} 


# PERSONAL: Lee, agrega y actualiza datos del Personal
sub datosP( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();
	
	my $sql = $bd->prepare("SELECT * FROM Personal ORDER BY Rut");
	$sql->execute();
	
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();

	return @datos; 
}	

sub agregaP($ $ $ $ $ $ $ $ $) 
{
	my ($esto, $Rut, $Nmbr, $Drccn, $Cmn, $Fns, $FcI, $FcR, $FcH, $CC) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("INSERT INTO Personal VALUES(?,?,?,?,?,?,?,?,?);");
	$sql->execute($Rut, $Nmbr, $Drccn, $Cmn, $Fns, $FcI, $FcR, $FcH, $CC);
	
	$sql = $bd->prepare("INSERT OR IGNORE INTO CuentasI VALUES(?,?,?,?,?,?);");
	$sql->execute($Rut, 0, 0, 0, ' ', ' ');
	$sql->finish();
} 

sub grabaP($ $ $ $ $ $ $ $)
{
	my ($esto, $Nmbr, $Rut, $Drccn, $Cmn, $Fns, $FcI, $FcR, $CC) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("UPDATE Personal SET Nombre = ?, Direccion = ?,
		Comuna = ?, Fonos = ?, FIngreso = ?, FRetiro = ?, CCosto = ? WHERE Rut = ?;");
	$sql->execute($Nmbr, $Drccn, $Cmn, $Fns, $FcI, $FcR, $CC, $Rut);
	$sql->finish();
} 

sub buscaP( $ )
{
	my ($esto, $rt) = @_;	
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT Nombre FROM Personal WHERE RUT = ?;");
	$sql->execute($rt);
	my $dato = $sql->fetchrow_array;
	$sql->finish();

	return $dato; 
}


# TERCEROS: Lee, agrega y actualiza datos de Proveedores, Clientes o Socios
sub datosT( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();
	
	my $sql = $bd->prepare("SELECT * FROM Terceros ORDER BY Rut");
	$sql->execute();
	
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();

	return @datos; 
}	

sub agregaT($ $ $ $ $ $ $ $ $ $)
{
	my ($esto, $Rut, $Nmbr, $Drccn, $Cmn, $Fns, $Pr, $Cl, $Sc, $Hr, $Fch) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("INSERT INTO Terceros VALUES(?,?,?,?,?,?,?,?,?,?);");
	$sql->execute($Rut, $Nmbr, $Drccn, $Cmn, $Fns, $Cl, $Pr, $Sc,$Hr, $Fch);
	
	$sql = $bd->prepare("INSERT OR IGNORE INTO CuentasI VALUES(?,?,?,?,?,?);");
	$sql->execute($Rut, 0, 0, 0, ' ', ' ');
	$sql->finish();
} 

sub grabaDatosT($ $ $ $ $ $ $ $ $)
{
	my ($esto, $Rut, $Nmbr, $Drccn, $Cmn, $Fns, $Pr, $Cl, $Sc, $Hr) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("UPDATE Terceros SET Nombre = ?, Direccion = ?,
		Comuna = ?, Fonos = ?, Cliente = ?, Proveedor = ?, Socio = ?,
		Honorario = ? WHERE Rut = ?;");
	$sql->execute($Nmbr, $Drccn, $Cmn, $Fns, $Cl, $Pr, $Sc, $Hr, $Rut);
	$sql->finish();
} 

sub buscaT( )
{
	my ($esto, $rt) = @_;	
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT Nombre FROM Terceros WHERE RUT = ?;");
	$sql->execute($rt);
	my $dato = $sql->fetchrow_array;
	$sql->finish();

	return $dato; 
}

sub datosCI( $ )
{
	my ($esto, $rt) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT * FROM CuentasI WHERE RUT = ?;");
	$sql->execute($rt);
	my @dts = $sql->fetchrow_array;
	$sql->finish();
	
	return @dts; 
}	


# SUBGRUPOS: Lee, agrega y actualiza tabla Grupos
sub datosSG( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT * FROM dg.SGrupos ORDER BY Codigo;");
	$sql->execute();
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub idGrupo( $ )
{
	my ($esto, $Cdg) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT ROWID FROM dg.SGrupos WHERE Codigo = ?;");
	$sql->execute($Cdg);
	my $dato = $sql->fetchrow_array;
	$sql->finish();
	
	return $dato; 
}

sub nombreGrupo( $ )
{
	my ($esto, $Cdg) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT Nombre FROM dg.SGrupos WHERE Codigo = ?;");
	$sql->execute($Cdg);
	my $dato = $sql->fetchrow_array;
	$sql->finish();
	
	return $dato; 
}

sub agregaGrupo( $ $ $ )
{
	my ($esto, $Cdg, $Nmbr, $Grp) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("INSERT INTO dg.SGrupos VALUES(?, ?, ?);");
	$sql->execute($Cdg, $Nmbr, $Grp);
	$sql->finish();
} 

sub grabaGrupo( $ $ $ $ )
{
	my ($esto, $Cdg, $Nmbr, $Grp, $Id) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("UPDATE dg.SGrupos SET Codigo = ?, Nombre = ?, 
		Grupo = ? WHERE ROWID = ?;");
	$sql->execute($Cdg, $Nmbr, $Grp, $Id);
	$sql->finish();
} 


# CUENTAS DE MAYOR: Lee, agrega y actualiza tablas Cuentas y Mayor
sub datosCuentas( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT * FROM dg.Cuentas ORDER BY Codigo;");
	$sql->execute();
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub datosCcM( ) # Lista de cuentas con movimiento
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT c.Cuenta, m.* FROM Mayor AS m, 
		dg.Cuentas AS c WHERE m.Debe + m.Haber > 0 AND m.Codigo = c.Codigo
		ORDER BY m.Codigo ;");
	$sql->execute();
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub idCuenta( $ )
{
	my ($esto, $Cdg) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT ROWID FROM dg.Cuentas WHERE Codigo = ?;");
	$sql->execute($Cdg);
	my $dato = $sql->fetchrow_array;
	$sql->finish();
	
	return $dato; 
}

sub dtCuenta( $ )
{
	my ($esto, $Cdg) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT Cuenta,CuentaI,SGrupo FROM dg.Cuentas 
		WHERE Codigo = ?;");
	$sql->execute($Cdg);
	my @dato = $sql->fetchrow_array;
	$sql->finish();
	
	return @dato; 
}

sub nmbCuenta( $ )
{
	my ($esto, $Cdg) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT Cuenta FROM dg.Cuentas WHERE Codigo = ?;");
	$sql->execute($Cdg);
	my $dato = $sql->fetchrow_array;
	$sql->finish();
	
	return $dato; 
}

sub agregaCuenta($ $ $ $ $ $ )
{
	my ($esto, $Cdg, $Nmbr, $Grp, $IEsp, $CntI, $Ngtv) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("INSERT INTO dg.Cuentas VALUES(?,?,?,?,?,?);");
	$sql->execute($Cdg, $Nmbr, $Grp, $IEsp, $CntI, $Ngtv);
	$sql->finish();
	$bd->do("INSERT INTO Mayor VALUES($Cdg,0,0,0,' ',' ');");
	$bd->do("UPDATE dg.Config SET PlanC = 1");
} 

sub grabaCuenta($ $ $ $ $ $ $ )
{
	my ($esto, $Cdg, $Nmbr, $Grp, $IEsp, $CntI, $Ngtv, $Id) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("UPDATE dg.Cuentas SET Codigo = ?, Cuenta = ?, 
		SGrupo = ?,	ImptoE = ?, CuentaI = ?, Negativo = ? WHERE ROWID = ?;");
	$sql->execute($Cdg, $Nmbr, $Grp, $IEsp, $CntI, $Ngtv, $Id);
	$sql->finish();

} 

sub apertura( $ $ $ )
{
	my ($esto, $Cd, $Mn, $Ts) = @_;	
	my $b = $esto->{'baseDatos'};

	# Crea la cuenta si no existe
	$b->do("INSERT INTO Mayor VALUES(?,0,0,0,' ',' ');", undef,
		$Cd) if not existeCM($b,$Cd);
	# Registra saldo inicial
	my $sql = $b->prepare("UPDATE Mayor SET Saldo = ?, TSaldo = ?
		WHERE Codigo = ?;");
	$sql->execute($Mn,$Ts,$Cd);
	$sql->finish();
}

sub existeCM( $ $ )
{
	my ($bd, $Cdg) = @_;	

	my $sql = $bd->prepare("SELECT Codigo FROM Mayor WHERE Codigo = ?;");
	$sql->execute($Cdg);
	my $dato = $sql->fetchrow_array;
	$sql->finish();
	if (not $dato ) { return 0; } else { return $dato eq $Cdg ; }
}

sub ctaEsp( $ )
{
	my ($esto, $tp) = @_;	
	
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT Codigo FROM dg.Cuentas WHERE CuentaI = ?;");
	$sql->execute($tp);
	my $dato = $sql->fetchrow_array;
	$sql->finish();
	if (not $dato ) { return " "; } else { return $dato; }
}


# COMPROBANTES: Lee, agrega y actualiza tablas DatosC e ItemsC
sub creaTemp( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};

$bd->do("CREATE TEMPORARY TABLE ItemsT (
	Numero int(5),
	CuentaM char(5),
	Debe int(9),
	Haber int(9),
	Detalle char(15),
	RUT char(10),
	TipoD char(2),
	Documento char(10),
	CCosto char(3),
	Mes int(2),
	NombreC char(35) )" );
}

sub borraTemp( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};

	$bd->do("DROP Table ItemsT;");
}

sub datosItems( $ )
{
	my ($esto, $NmrC) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT *,ROWID FROM ItemsT WHERE Numero = ?;");
	$sql->execute($NmrC);
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub itemsC( $ )
{
	my ($esto, $NmrC) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT * FROM ItemsC WHERE Numero = ?;");
	$sql->execute($NmrC);
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub itemsM( $ ) # Movimientos de cuentas de mayor
{
	my ($esto, $NmrC) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT i.*, d.Fecha, d.TipoC, d.Anulado 
		FROM ItemsC AS i, DatosC AS d WHERE i.CuentaM = ? AND i.Numero = d.Numero;");
	$sql->execute($NmrC);
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub itemsCI( $ ) # Movimientos de cuentas individuales
{
	my ($esto, $Rut) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT i.*, d.Fecha, d.TipoC, d.Anulado, d.Glosa 
		FROM ItemsC AS i, DatosC AS d WHERE i.RUT = ? AND i.Numero = d.Numero;");
	$sql->execute($Rut);
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub listaC( $ )
{
	my ($esto, $mes) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sel = "SELECT Numero, TipoC, Fecha, Total, Glosa FROM DatosC " ;
	if ( $mes ) {
		$mes = "0$mes" if length $mes < 2 ;
		$sel .= "WHERE substr(Fecha,5,2) = '$mes'";
	} 

	my $sql = $bd->prepare($sel);
	$sql->execute();
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub diario( $ $ )
{
	my ($esto, $fi, $ff) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT Numero, TipoC, Fecha, Total, Glosa 
		FROM DatosC WHERE Fecha >= ? AND Fecha <= ?;");
	$sql->execute($fi, $ff);
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub consultaC( $ )
{
	my ($esto,$NmrC) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT * FROM DatosC WHERE Numero = ?;");
	$sql->execute($NmrC);

	my @datos = $sql->fetchrow_array;
	$sql->finish();
	
	return @datos; 
}

sub numeroC( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT count(*) FROM DatosC;");
	$sql->execute();

	my $dato = $sql->fetchrow_array;
	$sql->finish();
	
	return $dato; 
}

sub numeroI( $ $ $ )
{
	my ($esto, $tabla, $mes, $td ) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT count(*) FROM $tabla WHERE Mes = ? AND Tipo = ?;");
	$sql->execute($mes,$td);
	my $dato = $sql->fetchrow_array;
	$sql->finish();
	
	return $dato;
}

sub agregaItemT( $ $ $ $ $ $ $ $ $ $)
{
	my ($esto, $Cod, $Det, $Mnt, $DH, $RUT, $cTD, $Doc, $Cnta, $Num, $CCto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my ($sql, $Db, $Hb);
	
	$Db = $Hb = 0;

	if ($DH eq 'D') { $Db = $Mnt; } else { $Hb = $Mnt; }
	$sql = $bd->prepare("INSERT INTO ItemsT VALUES(?,?,?,?,?,?,?,?,?,?,?);");
	$sql->execute($Num, $Cod, $Db, $Hb, $Det, $RUT, $cTD, $Doc, $CCto, 0, $Cnta );
	$sql->finish();
	# Actualiza archivo Mayor, si no existe la cuenta en una empresa
	$bd->do("INSERT INTO Mayor VALUES(?,0,0,0,' ',' ');", undef, 
		$Cod) if not existeCM($bd,$Cod);

} 

sub grabaItemT( $ $ $ $ $ $ $ $ $ $)
{
	my ($esto,$Cod,$Det,$Mnt,$DH,$RUT,$cTipoD,$Doc,$CC,$Cnta,$Id) = @_;	
	my $bd = $esto->{'baseDatos'};
	my ($sql, $Db, $Hb);

	$Db = $Hb = 0;
	if ($DH eq 'D') { $Db = $Mnt; } else { $Hb = $Mnt; }
	$sql = $bd->prepare("UPDATE ItemsT SET CuentaM = ?, Debe = ?, Haber = ?,
		Detalle = ?, RUT = ?, TipoD = ?,Documento = ?,CCosto = ?,NombreC = ?
		WHERE ROWID = ?;");
	$sql->execute($Cod,$Db,$Hb,$Det,$RUT,$cTipoD,$Doc,$CC,$Cnta,$Id);
	$sql->finish();
	
} 

sub borraItemT( $ )
{
	my ($esto, $Id) = @_;	
	my $bd = $esto->{'baseDatos'};

	$bd->do("DELETE FROM ItemsT WHERE ROWID = $Id ;");
}

sub sumaTC( $ )
{
	my ($esto, $Nmr) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT sum(Debe),sum(Haber) FROM ItemsT
		WHERE Numero = ?;");
	$sql->execute($Nmr);
	my @dato = $sql->fetchrow_array;
	$sql->finish();
	
	return ($dato[0], $dato[1]); 
}

sub agregaCmp( $ $ $ $ $ $ )
{
	my ($esto, $Numero, $Fecha, $Glosa, $Total, $Tipo, $bh) = @_;	
	my $bd = $esto->{'baseDatos'};
	my (@fila, $mes, $algo, $sql);

	# Graba datos basicos del Comprobante
	$sql = $bd->prepare("INSERT INTO DatosC VALUES(?, ?, ?, ?, ?, ?, ?);");
	$sql->execute($Numero, $Glosa, $Fecha, $Tipo, $Total, 0, 0);

	# Actualiza mes en ItemsT
	$mes = substr $Fecha,4,2 ;
	$mes =~ s/^0// ;
	$sql = $bd->prepare("UPDATE ItemsT SET Mes = ? WHERE Numero = ?;");
	$sql->execute($mes,$Numero);
	$sql->finish();
	# Graba items desde el archivo temporal
	$bd->do("INSERT INTO ItemsC SELECT Numero, CuentaM, Debe, Haber, Detalle,  
		RUT, TipoD, Documento,CCosto, Mes FROM ItemsT WHERE Numero = $Numero ;") ;
	# Las Cuentas de Mayor las actualiza SQLite [trigger]

	# Actualiza pago de documentos 
	if ($Tipo eq 'I') { # Facturas de Venta, si es ingreso
		actualizaP($bd,'Haber','FV','Ventas',$Numero,$Fecha) ;
	}
	if ($Tipo eq 'E') { # Si es egreso Facturas de Compra 
		actualizaP($bd,'Debe','FC','Compras',$Numero,$Fecha);
		actualizaP($bd,'Debe','BH','BoletasH',$Numero,$Fecha) if $bh;
	}
}

sub actualizaP ( $ $ $ $ )
{
	my ($bd, $cm, $td, $tbl, $nmr, $fch) = @_;	
	my ($aCta, $algo, $sql, $i);

	$sql = $bd->prepare("SELECT RUT, Documento, $cm FROM ItemsC
		WHERE Numero = ? AND RUT <> '' AND TipoD = ?;");
	$sql->execute($nmr,$td);
	$aCta = $bd->prepare("UPDATE $tbl SET Abonos = Abonos + ?, 
		FechaP = ? WHERE RUT = ? AND Numero = ?;");
	while (my @fila = $sql->fetchrow_array) {
		$algo = \@fila;
		$aCta->execute($algo->[2], $fch, $algo->[0], $algo->[1]);
	}
	$sql->finish();
	$aCta->finish();
}

sub actualizaCI ( $ $ )
{
	my ($esto, $Numero, $Fecha) = @_;	
	my $bd = $esto->{'baseDatos'};
	my ($sql, $algo, $aCta);

	$sql = $bd->prepare("SELECT RUT, Debe, Haber FROM ItemsC 
		WHERE Numero = ? AND RUT <> '';");
	$sql->execute($Numero);
	$aCta = $bd->prepare("UPDATE CuentasI SET Debe = Debe + ?,Haber = Haber + ?,
		Fecha_UM = ? WHERE RUT = ?;");
	while (my @fila = $sql->fetchrow_array) {
		$algo = \@fila;
		$aCta->execute($algo->[1], $algo->[2], $Fecha, $algo->[0]);
	}
}

sub anulaCmp( $ )
{


}

# BANCOS
sub datosBcs( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT Codigo, Nombre, ROWID FROM Bancos ;");
	$sql->execute();
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub agregaB($ $  )
{
	my ($esto, $Cod, $Nmbr) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("INSERT INTO Bancos VALUES(?,?);");
	$sql->execute($Cod, $Nmbr);
	
	$sql = $bd->prepare("INSERT OR IGNORE INTO CuentasI VALUES(?,?,?,?,?,?);");
	$sql->execute($Cod, 0, 0, 0, ' ', ' ');
	$sql->finish();
} 

sub grabaDatosB($ $  )
{
	my ($esto, $Cod, $Nmbr) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("UPDATE Bancos SET Nombre = ?
		WHERE Codigo = ?;");
	$sql->execute($Nmbr, $Cod);
	$sql->finish();
} 

sub buscaB( )
{
	my ($esto, $rt) = @_;	
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT Nombre FROM Bancos WHERE Codigo = ?;");
	$sql->execute($rt);
	my $dato = $sql->fetchrow_array;
	$sql->finish();

	return $dato; 
}


# DOCUMENTOS: tipos de documentos contable-tributarios
sub datosDocs( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT *, ROWID FROM dg.Documentos ;");
	$sql->execute();
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub agregaDoc( $ $ $ $)
{
	my ($esto, $Cdg, $Nmbr, $CT, $CI) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("INSERT INTO dg.Documentos VALUES(?, ?, ?, ?);");
	$sql->execute($Cdg, $Nmbr, $CT, $CI);
	$sql->finish();
} 

sub grabaDoc( $ $ $ $ $ )
{
	my ($esto, $Cdg, $Nmbr, $CT, $CI, $Id) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("UPDATE dg.Documentos SET Codice = ?, Nombre = ?, 
		CTotal = ?, CIva = ? WHERE ROWID = ?;");
	$sql->execute($Cdg, $Nmbr, $CT, $CI, $Id);
	$sql->finish();
} 

sub buscaDoc( $ )
{
	my ($esto, $doc) = @_;	
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT Nombre, CTotal, CIva FROM dg.Documentos 
		WHERE Codice = ?;");
	$sql->execute($doc);
	my @dato = $sql->fetchrow_array;
	$sql->finish();

	return @dato; 
}


# FACTURAS Ventas o Compras; NOTAS emitidas o recibidas
sub cuentaDcm ( $ $ )
{
	my ($esto, $tbl, $mes) = @_;
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT count(*) FROM $tbl WHERE Mes = ?");
	$sql->execute($mes);
	my $dato = $sql->fetchrow_array;
	$sql->finish();

	return $dato; 
}

sub buscaFct( $ $ $ )
{
	my ($esto, $tbl, $rut, $doc) = @_;	
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT FechaE FROM $tbl WHERE RUT=? AND Numero=?;");
	$sql->execute($rut, $doc);
	my $dato = $sql->fetchrow_array;
	$sql->finish();

	return $dato; 
}

sub buscaNI ()
{
	my ($esto, $tbl, $mes, $ni, $td) = @_;	
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT Rut, Numero, Comprobante, ROWID FROM $tbl 
		WHERE Orden = ? AND Tipo = ? AND Mes = ?;");
	$sql->execute($ni,$td,$mes);
	my @dato = $sql->fetchrow_array;
	$sql->finish();

	return @dato; 
	
}

sub datosFct( $ $ $ )
{
	my ($esto, $tbl, $rut, $doc) = @_;	
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT t.*, c.Glosa FROM $tbl AS t, DatosC AS c
		WHERE t.RUT = ? AND t.Numero = ? AND t.Comprobante = c.Numero;");
	$sql->execute($rut, $doc);
	my @dts = $sql->fetchrow_array;
	$sql->finish();

	return @dts; 
}

sub grabaFct( $ $ $ $ $ $ $ $ $ $ $ $ $ $ $ $)
{
	my ($esto,$tb,$rut,$doc,$fch,$t,$i,$af,$ex,$nmr,$td,$fv,$fc,$cta,$tf,$no,$nl,$ie) = @_;	
	my $bd = $esto->{'baseDatos'};
	my ($mnD, $mnH, $mes, $sql);

	$mes = substr $fc,4,2 ; # Extrae mes
	$mes =~ s/^0// ; # Elimina '0' al inicio
	$sql = $bd->prepare("INSERT INTO $tb VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?,?);");
	$sql->execute($rut,$doc,$fch,$t,$i,$af,$ex,$nmr,$fv,0,0,'',$td,$mes,$nl,$cta,$tf,$no,$ie);
	
	# Actualiza cuenta individual
	$mnD = $mnH = 0;
	$mnD = $t if $td eq 'FV' or $td eq 'ND';
	$mnH = $t if $td eq 'FC' or $td eq 'NC';
	$sql = $bd->prepare("UPDATE CuentasI SET Debe = Debe + ?, Haber = Haber + ?, 
		Fecha_UM = ? WHERE RUT = ?;");
	$sql->execute($mnD, $mnH, $fch, $rut);
	$sql->finish();
}

sub anulaFct( )
{

}

sub listaD( $ $ )
{
	my ($esto, $tabla, $td, $ord, $mes) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sel = "SELECT d.RUT, d.Numero, d.FechaE, d.Total, t.Nombre 
		FROM $tabla AS d, Terceros AS t WHERE d.RUT = t.RUT ";
	$sel .= " AND Mes = '$mes' " if $mes ;
	$sel .= " AND Tipo = '$td' " if not $td eq 'BH' ;
	$sel .= "ORDER BY d.$ord " if $ord ;
	my $sql = $bd->prepare($sel); 
	$sql->execute();
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub listaFct( $ $ $ $)
{
	my ($esto, $tabla, $mes, $td, $tf) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sel = "SELECT FechaE, Numero, RUT, Total, IVA, Afecto, Exento, 
		Nulo, IEspec, Orden FROM $tabla WHERE Mes = ? AND Tipo = ?" ;
	$sel .= " AND TF = '$tf' " if $tf ;
	$sel .= " ORDER BY Orden " ; 
	my $sql = $bd->prepare($sel); 
	$sql->execute($mes,$td);
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub cambiaDcm ( ) 
{
	my ($esto,$NumC,$FechaC,$Ni,$MesC,$Tabla,$Id,$TD) = @_ ;
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("UPDATE $Tabla SET Fecha = ?, Mes = ?, Orden = ? 
		WHERE ROWID = ?"); 
	$sql->execute($FechaC,$Ni,$MesC,$Id);

	$sql = $bd->prepare("UPDATE DatosC SET Fecha = ? WHERE Numero = ?");
	$sql->execute($FechaC,$NumC);
	
	$sql = $bd->prepare("UPDATE ItemsC SET Mes = ? WHERE Numero = ?");
	$sql->execute($MesC,$NumC);
	# Falta actualizar número de orden
	$sql->finish();

}

sub creaTempF( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	
$bd->do("CREATE TEMPORARY TABLE Facts (
	RUT char(10),
	Numero char(10),
	FechaE char(10),
	Total int(8),
	IVA int(8),
	Afecto int(8),
	Exento int(8),
	Comprobante int(5),
	FechaV char(10),
	Abonos int(8),
	Pagada int(1) ,
	FechaP char(10),
	Tipo char(2),
	Mes int(2),
	Nulo int(1),
	Cuenta int(4),
	TF char(1),
	Orden int(2),
	IEspec int(8)  )" );

}

sub borraTempF( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};

	$bd->do("DROP Table Facts;");
}

sub creaTempRF( $ )
{
	my ($esto, $td) = @_;	
	my $bd = $esto->{'baseDatos'};
	
$bd->do("CREATE TEMPORARY TABLE RFcts (
	Numero int(5),
	Total int(8),
	IVA int(8),
	Afecto int(8),
	Exento int(8),
	IEspec int(8) ,
	Tipo char(2) )" );

$bd->do("INSERT INTO RFcts VALUES(0,0,0,0,0,0,'$td' ) " );
$bd->do("INSERT INTO RFcts VALUES(0,0,0,0,0,0,'NC' ) " );
$bd->do("INSERT INTO RFcts VALUES(0,0,0,0,0,0,'ND' ) " );

}

sub actualizaRF( $ $ $ $ $ $ $ )
{
	my ($esto, $td, $n, $t, $i, $a, $e, $ie) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("UPDATE RFcts SET Numero = Numero + ?, 
		Total = Total + ?, IVA = IVA + ?, Afecto = Afecto + ?,
		Exento = Exento + ?, IEspec = IEspec + ?  WHERE Tipo = ?;");
	$sql->execute( $n, $t, $i, $a, $e, $ie, $td );	
	$sql->finish();
}

sub borraTempRF( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};

	$bd->do("DROP Table RFcts;");
}

sub datosRF( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT * FROM RFcts;");
	$sql->execute();
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}

sub datosFacts( $ )
{
	my ($esto, $Rut) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT *,ROWID FROM Facts WHERE RUT = ?;");
	$sql->execute($Rut);
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	


# BOLETAS de CompraVenta
sub buscaBCV( $ )
{
	my ($esto, $fecha) = @_;	
	my $bd = $esto->{'baseDatos'};
	
	my $sql = $bd->prepare("SELECT Fecha FROM BoletasV WHERE Fecha = ?;");
	$sql->execute($fecha);
	my $dato = $sql->fetchrow_array;
	$sql->finish();

	return $dato; 
}

sub grabaBCV( $ $ $ $ )
{
	my ($esto, $fch, $de, $a, $mnt) = @_;	
	my $bd = $esto->{'baseDatos'};

	my @cmps = split /\//, $fch ;

	my $sql = $bd->prepare("INSERT INTO BoletasV VALUES(?,?,?,?,?,?,?);");
	$sql->execute($fch, $de, $a, $mnt, 0, '', $cmps[1]);
	$sql->finish();
	
}


# HONORARIOS
sub grabaBH( $ $ $ $ $ $ $ $ $ )
{
	my ($esto, $rut, $doc, $fch, $t, $im, $nmr, $fv, $cta, $nt) = @_;	
	my $bd = $esto->{'baseDatos'};
	my ($ms,$sql);

	$ms = substr $fch,4,2 ; # Extrae mes
	$sql = $bd->prepare("INSERT INTO BoletasH VALUES(?,?,?,?,?,?,?,?,?,?,?,?,?);");
	$sql->execute($rut,$doc,$fch,$t,$im,$nmr,$fv,0,0,'',$ms,0,$cta);
	
	# Actualiza cuenta individual
	$sql = $bd->prepare("UPDATE CuentasI SET Haber = Haber + ?, Fecha_UM = ?
		WHERE RUT = ?;");
	$sql->execute($nt, $fch, $rut);	
	$sql->finish();
}

sub listaBH( $ )
{
	my ($esto, $mes) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();
	
	my $sql = $bd->prepare("SELECT b.FechaE, b.Numero, b.RUT, t.Nombre,
		b.Retenido, b.Total, b.Nulo FROM BoletasH AS b, Terceros AS t 
		WHERE b.RUT = t.RUT AND b.Mes = ?");
	$sql->execute($mes);
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();

	return @datos; 	
}


# CENTROS: Lee, agrega y actualiza tabla CCostos
sub datosCentros( )
{
	my ($esto) = @_;	
	my $bd = $esto->{'baseDatos'};
	my @datos = ();

	my $sql = $bd->prepare("SELECT * FROM CCostos ORDER BY Codigo;");
	$sql->execute();
	# crea una lista con referencias a las listas de registros
	while (my @fila = $sql->fetchrow_array) {
		push @datos, \@fila;
	}
	$sql->finish();
	
	return @datos; 
}	

sub idCentro( $ )
{
	my ($esto, $Cdg) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT ROWID FROM CCostos WHERE Codigo = ?;");
	$sql->execute($Cdg);
	my $dato = $sql->fetchrow_array;
	$sql->finish();
	
	return $dato; 
}

sub nombreCentro( $ )
{
	my ($esto, $Cdg) = @_;	
	my $bd = $esto->{'baseDatos'};

	my $sql = $bd->prepare("SELECT Nombre FROM CCostos WHERE Codigo = ?;");
	$sql->execute($Cdg);
	my $dato = $sql->fetchrow_array;
	$sql->finish();
	
	return $dato; 
}

sub agregaCentro( $ $ $ $ $ )
{
	my ($esto, $Cdg, $Nmbr, $Tp, $Grp, $Agr) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("INSERT INTO CCostos VALUES(?, ?, ?, ?, ?);");
	$sql->execute($Cdg, $Nmbr, $Tp, $Grp, $Agr);
	$sql->finish();
} 

sub grabaCentro( $ $ $ $ $)
{
	my ($esto, $Cdg, $Nmbr, $Tp, $Grp, $Agr, $Id) = @_;	
	my $bd = $esto->{'baseDatos'};
	 
	my $sql = $bd->prepare("UPDATE CCostos SET Codigo = ?, Nombre = ?, 
		Tipo = ?, Grupo = ?, Agrupa = ? WHERE ROWID = ?;");
	$sql->execute($Cdg, $Nmbr, $Tp, $Grp, $Agr, $Id);
	$sql->finish();
} 

# Termina el paquete
1;
