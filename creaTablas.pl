#!/usr/bin/perl -w

#  creaTablas.pl - inicializa la base de datos con SQLite 3
#  Forma parte del Programa Quipu
#
#  Derechos de autor: Víctor Araya R., 2009 [varaya@programmer.net]
#  
#  Puede ser utilizado y distribuido en los términos previstos en la 
#  licencia incluida en este paquete 
#  UM: 19.05.2010

use DBI;
use strict;

# EMPRESAS y DATOS COMUNES
# Conecta a la base de datos
my $bd = DBI->connect( "dbi:SQLite:datosG.db3" ) || 
	die "Imposible establecer conexión: $DBI::errstr";

# Datos empresas
$bd->do("CREATE TABLE Config (
	Periodo int(4),
	PlanC int(1),
	InterE int(1),
	MultiE int(1),
	IVA int(2),
	Cierre char(5) )" );

$bd->do("CREATE TABLE DatosE (
	Nombre text(30),
	Rut char(10),
	Giro text(35),
	RutRL char(10),
	NombreRL text(30),
	OtrosI int(1),
	BltsCV int(1),
	CBanco int(1),
	CCostos int(1),
	CPto int(1),
	Datos int(1),
	Inicio int(4) )" );

# Plan de Cuentas
$bd->do("CREATE TABLE Cuentas (
	Codigo char(5) NOT NULL PRIMARY KEY,
	Cuenta text(35),
	SGrupo char(2),
	ImptoE char(1),
	CuentaI char(1),
	Negativo char(1) )" );

# Subgrupos
$bd->do("CREATE TABLE SGrupos (
	Codigo char(5) NOT NULL PRIMARY KEY,
	Nombre text(35),
	Grupo char(1) )" );
	
$bd->do("INSERT INTO SGrupos VALUES('10','Disponible','A') ");
$bd->do("INSERT INTO SGrupos VALUES('11','Realizable','A') ");
$bd->do("INSERT INTO SGrupos VALUES('20','Corto Plazo','P') ");
$bd->do("INSERT INTO SGrupos VALUES('22','Patrimonio','P') ");
$bd->do("INSERT INTO SGrupos VALUES('30','Ventas','I') ");
$bd->do("INSERT INTO SGrupos VALUES('40','Gastos','G') ");

# Documentos
$bd->do("CREATE TABLE Documentos (
	Codice char(2) NOT NULL PRIMARY KEY,
	Nombre char(15),
	CTotal char(5),
	CIva char(5) )" );

$bd->do("INSERT INTO Documentos VALUES('FV','F.Venta','','') ");
$bd->do("INSERT INTO Documentos VALUES('FC','F.Compra','','') ");
$bd->do("INSERT INTO Documentos VALUES('FE','FCT.Emitida','','') ");
$bd->do("INSERT INTO Documentos VALUES('FR','FCT.Recibida','','') ");
$bd->do("INSERT INTO Documentos VALUES('BH','B.Honorario','','') ");
$bd->do("INSERT INTO Documentos VALUES('NC','N.Crédito','','') ");
$bd->do("INSERT INTO Documentos VALUES('ND','N.Débito','','')");
$bd->do("INSERT INTO Documentos VALUES('CH','Cheque','','')");
$bd->do("INSERT INTO Documentos VALUES('LT','Letra','','')");
$bd->do("INSERT INTO Documentos VALUES('DB','Depósito','','')");

# Desconecta la base de datos
$bd->disconnect;
