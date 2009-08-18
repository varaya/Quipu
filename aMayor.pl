#!/usr/bin/perl -w
# Recontabiliza todo (en cuentas de mayor)
# UM : 13.08.2009

use DBI;
use strict;

my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base", 
	{ RaiseError => 1, AutoCommit => 0 }) ;

print "Limpia datos.. \n";
$bd->do("UPDATE Mayor SET Debe = 0, Haber = 0, Saldo = 0");
my $sql = $bd->prepare("SELECT max(Numero) FROM DatosC;");
$sql->execute();
my $nmrC = $sql->fetchrow_array;
$sql->finish;

print "Contabilizando $nmrC comprobantes.. \n";
while ($nmrC > 0) {
	actualizaCM();
	$nmrC--;
}
print "Listo \n";

sub actualizaCM {
	$sql = $bd->prepare("SELECT CuentaM, Debe, Haber FROM ItemsC 
		WHERE Numero = ? ;");
	$sql->execute($nmrC);
	my ($algo, $aCta );
	$aCta = $bd->prepare("UPDATE Mayor SET Debe = Debe + ?, Haber = Haber + ?
		 WHERE Codigo = ?;");
	while (my @fila = $sql->fetchrow_array) {
		$algo = \@fila;
		$aCta->execute($algo->[1], $algo->[2], $algo->[0]);
	}
	$aCta->finish;
}
