#!/usr/bin/perl -w
use DBI;
use strict;

my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base", 
	{ RaiseError => 1, AutoCommit => 0 }) ;

my ($mes, $sql, $algo, $aCta, $tabla);
$tabla = "Mayor06";
$bd->do("UPDATE $tabla SET Debe = 0, Haber = 0, Saldo = 0");
my @meses = (1..6);
for $mes (@meses) {
	$sql = $bd->prepare("SELECT CuentaM, Debe, Haber FROM ItemsC 
		WHERE Mes = ? ;");
	$sql->execute($mes);
	$aCta = $bd->prepare("UPDATE $tabla SET Debe = Debe + ?, Haber = Haber + ?
		 WHERE Codigo = ?;");
	while (my @fila = $sql->fetchrow_array) {
		$algo = \@fila;
		$aCta->execute($algo->[1], $algo->[2], $algo->[0]);
	}
}
