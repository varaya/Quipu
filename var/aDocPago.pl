#!/usr/bin/perl -w
# Actualiza pago de documento en archivo Compras
# UM: 25/05/2010

use DBI;
use strict;

my ($Rut, $base) = ('96537850-2','2010.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base", { RaiseError => 1, AutoCommit => 0 }) ;
my ( $sql1, $sql2, $sql3, $rt, $mt, $dc, $nm, $nd, @dt);

$sql1 = $bd->prepare("SELECT Haber,Documento,Numero FROM ItemsC 
	WHERE CuentaM = '1002' AND Haber > 0 AND TipoD = 'CH';");
$sql2 = $bd->prepare("SELECT RUT,Documento FROM ItemsC 
	WHERE Numero = ? AND TipoD = 'FC';");
$sql3 = $bd->prepare("UPDATE Compras SET DocPago = ? WHERE RUT = ? AND Numero = ?;");

$sql1->execute();
while (my @fila = $sql1->fetchrow_array) {
	$mt = $fila[0] ;
	$dc = "CH $fila[1] ";
	$nm = $fila[2] ;
	$sql2->execute($nm) ;
	@dt = $sql2->fetchrow_array ;
	if ( @dt ) {
		$rt = $dt[0] ;
		$nd = $dt[1] ;
		print "$nm $mt $dc - $rt $nd : " ;
		$sql3->execute($dc,$rt,$nd);
	}
}

