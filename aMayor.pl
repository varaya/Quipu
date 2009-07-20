#!/usr/bin/perl -w
use DBI;
use strict;

my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base" ) || 
	die "Imposible establecer conexión: $DBI::errstr";

$bd->do("UPDATE Mayor SET Debe = 0, Haber = 0");
my $sql = $bd->prepare("SELECT count(*) FROM DatosC;");
$sql->execute();
my $nmrC = $sql->fetchrow_array;;
while ($nmrC > 0) {
	actualizaCM();
	$nmrC--;
}

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
}