#!/usr/bin/perl -w
# Verifica cuadratura de comprobantes
# UM : 27.04.2010

use DBI;
use strict;

my $mes = $ARGV[0] ;

my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base",{ RaiseError => 1, AutoCommit => 0 }) ;

my ($cmp, $sql, $db, $hb, @dt);

my @cmps = (1..4153);
for $cmp (@cmps) {
	$sql = $bd->prepare("SELECT sum(Debe), sum(Haber) FROM ItemsC 
		WHERE Numero = ? ;");
	$sql->execute($cmp);
	@dt = $sql->fetchrow_array ;
#	print "$cmp - " if not $dt[0] ;
	if (not $dt[0] == $dt[1] ) {
		print "Cmp. $cmp - ";
	}
}

