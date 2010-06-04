#!/usr/bin/perl -w
# Actualiza Mayor, indicado último mes contabilizado
# UM: 27/04/2010

use DBI;
use strict;

my $nm = $ARGV[0];
my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base", { RaiseError => 1, AutoCommit => 0 }) ;
my ($mes, $sql, $algo, $aCta);

$bd->do("UPDATE Mayor SET Debe = 0, Haber = 0");
my @meses = (1..$nm);
for $mes (@meses) {
	print "$mes - " ;
	$sql = $bd->prepare("SELECT CuentaM, Debe, Haber FROM ItemsC 
		WHERE Mes = ? ;");
	$sql->execute($mes);
	$aCta = $bd->prepare("UPDATE Mayor SET Debe = Debe + ?, Haber = Haber + ?
		 WHERE Codigo = ?;");
	while (my @fila = $sql->fetchrow_array) {
		$algo = \@fila;
		$aCta->execute($algo->[1], $algo->[2], $algo->[0]);
	}
}
