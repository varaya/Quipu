#!/usr/bin/perl -w
# Elimina definitivamente comprobantes anulados
# UM: 18.08.2009

use DBI;
use strict;

my ($Rut, $base) = ('96537850-2','2009.db3') ;
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base",{RaiseError => 1, AutoCommit => 0}) ;

my ($nm,$rf,$x) ;
my $sql = $bd->prepare("SELECT Numero, Ref FROM DatosC WHERE Anulado ;");
$sql->execute();

while (my @datos = $sql->fetchrow_array) {
	$x = \@datos ;
	$nm = $x->[0] ;
	$rf = $x->[1] ;
	$bd->do("UPDATE DatosC SET Glosa = 'Anulado', Total = 0, Anulado = 2,
		Ref = 0 WHERE Numero = $nm ;") ;
	$bd->do("DELETE FROM ItemsC WHERE Numero = $nm ;") ;
	$bd->do("UPDATE DatosC SET Glosa = 'Eliminado', Total = 0, Anulado = 2
		WHERE Numero = $rf ;") ;
	$bd->do("DELETE FROM ItemsC WHERE Numero = $rf ;") ;
}

$sql->finish;
