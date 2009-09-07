#!/usr/bin/perl -w
# Revisa conrabilización de FV
# UM : 07.09.2009

use DBI;
use strict;
use Number::Format;
use Data::Dumper; 
my $pesos = new Number::Format(-thousands_sep => '.', -decimal_point => ',');

my $mes = $ARGV[0] ;

my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base",{ RaiseError => 1, AutoCommit => 0 }) ;
	
my @datos = ();
my ($x,$f,$d1,$d2) ;
my $sql = $bd->prepare("select sum(Debe),count(*) from ItemsC where Mes = ? and TipoD = 'FV' and CuentaM = '1101' and Debe > 0;");
$sql->execute($mes);
my @dato1 =  $sql->fetchrow_array ; 
$d1 = $pesos->format_number($dato1[0]) ;
print "$mes : M  $dato1[1]  $d1 - " ;
$sql = $bd->prepare("select sum(Total),count(*) from Ventas where Mes = ? and Total > 0 and Nulo = 0;");
$sql->execute($mes);
my @dato2 =  $sql->fetchrow_array ; 
$d2 = $pesos->format_number($dato2[0]) ;
my $dif = $pesos->format_number( $dato1[0] - $dato2[0] );
print "LV  $dato2[1]  $d2 - D $dif \n" ;
$sql->finish;

$sql = $bd->prepare("select Comprobante from Ventas where Mes = ?;");
$sql->execute($mes);
while (my @fila = $sql->fetchrow_array) {
	push @datos, \@fila;
}
$sql->finish;
# print Dumper @datos;

$sql = $bd->prepare("SELECT Documento FROM ItemsC WHERE Numero = ? and TipoD = 'FV' and CuentaM = '1101';");
foreach $x (@datos) {
	$sql->execute($x->[0]);
	$f = $sql->fetchrow_array;
	print "$x->[0]\n" if not $f and not $x->[0] eq '' ;
}
$sql->finish;
