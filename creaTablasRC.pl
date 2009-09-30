#!/usr/bin/perl -w

#  creaTablasRC.pl - inicializa la base de datos con SQLite 3
#  Forma parte del programa Quipu
#
#  Derechos de Autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM : 30.09.2009 

use DBI;
use strict;

my $emp = $ARGV[0]; # directorio de la empresa (RUT)
my $prd = $ARGV[1]; # Nombre de la base de datos (año)

if (not -d $emp) { # Verifica si existe el directorio
	mkdir $emp ;
	mkdir "$emp/txt";
	mkdir "$emp/csv";
	mkdir "$emp/pdf";
}

# Conecta a la base de datos
my $base = "$emp/$prd.db3";
if (-e $base ) {
	print "$base ya existe\n"; 
	return ;
}
my $bd = DBI->connect( "dbi:SQLite:$base" ) || 
	die "Imposible establecer conexión: $DBI::errstr";

# REGISTROS CONTABLES
# Cuentas de mayor
# Nota: Los campos 'TSaldo' y 'Saldo' corresponde a la apertura del año
$bd->do("CREATE TABLE Mayor (
	Codigo char(5) NOT NULL PRIMARY KEY,
	Debe int(9) ,
	Haber int(9) ,
	Saldo int(9) ,
	TSaldo char(1) ,
	Fecha_UM char(10) )" );

# Actualización de Fecha_UM en Cuenta de Mayor
$bd->do("CREATE TRIGGER AFechaM AFTER UPDATE OF Debe, Haber ON Mayor
  BEGIN
    UPDATE Mayor SET Fecha_UM = substr(datetime('now'),0,10) 
	WHERE rowid = old.rowid ;
  END" );

# Encabezado del Comprobante de Contabilidad
$bd->do("CREATE TABLE DatosC (
	Numero int(5),
	Glosa text(25),
	Fecha char(10),
	TipoC char(1),
	Total int(9),
	Anulado int(1), 
	Ref int(5) )" );

# Líneas del Comprobante de Contabilidad
$bd->do("CREATE TABLE ItemsC (
	Numero int(5),
	CuentaM char(5),
	Debe int(9),
	Haber int(9),
	Detalle char(15),
	RUT char(10),
	TipoD char(2),
	Documento char(10),
	CCosto char(3),
	Mes int(2) )" );

# Contabiliza movimiento en Cuentas de Mayor
$bd->do("CREATE TRIGGER Actualiza AFTER INSERT ON ItemsC
  BEGIN
    UPDATE Mayor SET Debe = Debe + new.Debe, Haber = Haber + new.Haber 
		WHERE Codigo = new.CuentaM ;
  END" );

# Facturas de Compras y Notas de Débito y Crédito de Proveedores
# Campo Nulo: 0 Vigente; 1 Emitido como nulo; 2 Anulado luego de emitido
# Similar para Ventas y BoletasH
$bd->do("CREATE TABLE Compras (
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
	IEspec int(8),
	IRetenido int(8) )" );

# Actualización de Pagada en F. Compras
$bd->do("CREATE TRIGGER PagoFC AFTER UPDATE OF Abonos ON Compras
  BEGIN
    UPDATE Compras SET Pagada = CASE WHEN Abonos >= Total THEN 1
		ELSE 0 END ;
  END" );

# Facturas de Ventas y Notas de Débito y Crédito de Clientes
$bd->do("CREATE TABLE Ventas (
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
	IEspec int(8),
	IRetenido int(8) )" );

# Actualización de Pagada en F. Ventas
$bd->do("CREATE TRIGGER PagoFV AFTER UPDATE OF Abonos ON Ventas
  BEGIN
    UPDATE Ventas SET Pagada = CASE WHEN Abonos >= Total THEN 1
		ELSE 0 END ;
  END " );

# Boletas de Ventas
$bd->do("CREATE TABLE BoletasV (
	Fecha char(10),
	De char(10),
	A char(10),
	Total int(8),
	IVA int(8),
	Comprobante int(5),
	Mes int(2) )" );

# Boletas de Honorarios
$bd->do("CREATE TABLE BoletasH (
	RUT char(10),
	Numero char(10),
	FechaE char(10),
	Total int(8),
	Retenido int(8),
	Comprobante int(5),
	FechaV char(10),
	Abonos int(8),
	Pagada int(1) ,
	FechaP char(10),
	Mes int(2),
	Nulo int(1),
	Cuenta int(4) )" );

# Actualización de Pagada en B. Honorarios
$bd->do("CREATE TRIGGER PagoBH AFTER UPDATE OF Abonos ON BoletasH
  BEGIN
    UPDATE BoletasH SET Pagada = CASE WHEN Abonos >= Total - Retenido THEN 1 
		ELSE 0 END ;
  END" );

# Documentos emitidos (cheques y letras)
$bd->do("CREATE TABLE DocsE (
	Numero char(10),
	Cuenta int(4) ,
	RUT char(10),
	FechaE char(10),
	Monto int(8),
	Comprobante int(5),
	FechaV char(10),
	Abonos int(8),
	FechaP char(10),
	Estado char(1) ,
	Nulo int(1),
	Tipo char(2) )" );

# Documentos recibidos (cheques y letras)
$bd->do("CREATE TABLE DocsR (
	Numero char(10),
	Cuenta int(4) ,
	RUT char(10),
	FechaE char(10),
	Monto int(8),
	Comprobante int(5),
	FechaV char(10),
	Abonos int(8),
	FechaP char(10),
	Estado char(1) ,
	Nulo int(1),
	Tipo char(2) )" );

# Impuestos especiales
$bd->do("CREATE TABLE ImptosE (
	Comprobante int(5),
	CuentaM char(5),
	Monto int(8),
	Anulado int(1) )" );

# Cuentas Individuales (Clientes, Proveedores, Socios y Personal)
$bd->do("CREATE TABLE CuentasI (
	RUT char(10) NOT NULL PRIMARY KEY,
	Debe int(9) ,
	Haber int(9) ,
	Saldo int(9) ,
	TSaldo char(1),
	Fecha_UM char(10) )" );

# Actualización de Saldo, TSaldo y Fecha_UM en cuenta individual
$bd->do("CREATE TRIGGER AFechaCI AFTER UPDATE OF Debe, Haber ON CuentasI
  BEGIN
    UPDATE CuentasI SET Fecha_UM = substr(datetime('now'),0,10) 
	WHERE rowid = old.rowid ;
  END " );

# DATOS ADICIONALES
# Terceros: Socios, Clientes y Proveedores
$bd->do("CREATE TABLE Terceros (
	RUT char(10) NOT NULL PRIMARY KEY,
	Nombre char(35),
	Direccion char(40),
	Comuna char(20),
	Fonos char(20),
	Cliente char(1),
	Proveedor char(1),
	Socio char(1), 
	Fecha_R char(10) )" );

# Personal
$bd->do("CREATE TABLE Personal (
	RUT char(10) NOT NULL PRIMARY KEY,
	Nombre char(35),
	Direccion char(40),
	Comuna char(20),
	Fonos char(12),
	FIngreso char(10),
	FRetiro char(10),
	Fecha_R char(10),
	CCosto char(3) )" );

# Bancos
$bd->do("CREATE TABLE Bancos (
	Codigo char(3) NOT NULL PRIMARY KEY,
	Nombre text(30) )" );
	
# Centros de Costos
$bd->do("CREATE TABLE CCostos (
	Codigo char(3) NOT NULL PRIMARY KEY,
	Nombre text(30) ,
	Tipo char(1) ,
	Grupo char(1),
	Agrupa int(1) )" );

# Desconecta la base de datos
$bd->disconnect;
