#!/usr/bin/perl -w
# Borra items de un comprobante, indicado numero inferior y superior de 
# los registros
# UM_ 05/10/2009

use DBI;
use strict;

my $nmi = $ARGV[0] - 1;
my $nms = $ARGV[1] + 1;
print "$nmi - $nms \n";

my ($Rut, $base) = ('96537850-2','2009.db3');
my $bd = DBI->connect( "dbi:SQLite:$Rut/$base", 
	{ RaiseError => 1, AutoCommit => 0 }) ;

my $sql = $bd->prepare("DELETE FROM ItemsC WHERE ROWID > ? AND ROWID < ?");
$sql->execute($nmi, $nms);
