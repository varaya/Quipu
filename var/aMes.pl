#!/usr/bin/perl -w
# Actualiza Mayor, indicado último mes contabilizado
# UM: 27/04/2010

use DBI;
use strict;

my $nm = $ARGV[0];
my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base", { RaiseError => 1, AutoCommit => 0 }) ;
my ($cm, $mes, $sql, $algo, $dato, $aCta);

my @cmp = (1..4153);
$sql = $bd->prepare("SELECT Fecha FROM DatosC WHERE Numero = ? ;");
$aCta = $bd->prepare("UPDATE ItemsC SET Mes = ?	 WHERE Numero = ?;");
for $cm (@cmp) {
	$sql->execute($cm);
	$dato = $sql->fetchrow_array ;
	$mes = substr $dato,4,2 ;
#	print "$dato $mes - ";
	$aCta->execute($mes, $cm);
}
