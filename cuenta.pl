#!/usr/bin/perl -w
# Cuenta comprobantes
# UM : 13.08.2009

use DBI;
use strict;

my $mes = $ARGV[0] ;

my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base",{ RaiseError => 1, AutoCommit => 0 }) ;
	
my @datos = ();
my ($x,$f) ;
my $sql = $bd->prepare("select distinct Numero from ItemsC where Mes = ?;");
$sql->execute($mes);
while (my @fila = $sql->fetchrow_array) {
	push @datos, \@fila;
}
$sql->finish;

$sql = $bd->prepare("SELECT Fecha FROM DatosC WHERE Numero = ? ;");
foreach $x (@datos) {
	$sql->execute($x->[0]);
	$f = $sql->fetchrow_array;
	print "$x->[0]	- $f \n" ;
}
$sql->finish;

