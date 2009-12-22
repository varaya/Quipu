#!/usr/bin/perl -w
# Actualiza pago de BH
# UM: 22/12/2009

use DBI;
use strict;

my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base", { RaiseError => 1, AutoCommit => 0 }) ;
my ($sql1, $sql2, $x, $y);

# Recopila Boletas que figuran como no pagadas
$sql1 = $bd->prepare("SELECT Numero, RUT FROM BoletasH WHERE Pagada = 0 and Rut <> 'Anulada' ;");
$sql1->execute();

my @datos =  () ;
while (my @fila = $sql1->fetchrow_array) {
	push @datos, \@fila;
}
$sql1->finish;

$sql1 = $bd->prepare("SELECT Debe FROM ItemsC WHERE Documento = ? and Rut = ? and Debe > 0 ;");
$sql2 = $bd->prepare("UPDATE BoletasH SET Abonos = Abonos + ? WHERE Numero = ? and RUT = ? " );
foreach $x (@datos) {
	$sql1->execute($x->[0],$x->[1]);
	my @fila = $sql1->fetchrow_array ;
	if ( @fila ) {
		# Actualiza pago
		$sql2->execute( $fila[0],$x->[0],$x->[1] );
		print "$fila[0] - ";
	} 
}
$sql1->finish;
$sql2->finish;
