#!/usr/bin/perl -w
# Revisa y actualiza comprobantes con registro de BH
# UM: 22/12/2009

use DBI;
use strict;

my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base", { RaiseError => 1, AutoCommit => 0 }) ;
my ($cta, $sql1, $sql2, $x, $y);

$cta = '2008';
$sql1 = $bd->prepare("SELECT Numero FROM ItemsC WHERE Haber > 0 and CuentaM = ? and Rut = '' ;");
$sql1->execute($cta);

my @datos =  () ;
while (my @fila = $sql1->fetchrow_array) {
	push @datos, \@fila;
}
$sql1->finish;

# recopila datos del item 
my @datosI =  () ;
$sql1 = $bd->prepare("SELECT Rut, Documento, Numero FROM ItemsC WHERE Numero = ? and Rut <> '' ;");
foreach $x (@datos) {
	$sql1->execute($x->[0]);
	while (my @fila = $sql1->fetchrow_array) {
		push @datosI, \@fila;
	}
}

# Actualiza datos
$sql1 = $bd->prepare("UPDATE ItemsC SET Rut = ?, Documento = ?, TipoD = 'BH' WHERE Numero = ? and CuentaM = ? ") ;
$sql2 = $bd->prepare("UPDATE ItemsC SET Rut = '' WHERE Numero = ? and CuentaM > '3999'") ;
foreach $y (@datosI) {
	$sql1->execute( $y->[0], $y->[1], $y->[2], $cta );
	$sql2->execute( $y->[2] ) ;
}

$sql1->finish;
$sql2->finish;
