#!/usr/bin/perl

use strict;
use warnings;

print "Verificando: \n";

my @modules = qw(Tk  Tk::TableMatrix  Tk::BrowseEntry Tk::NoteBook 
	DBI  DBD::Pg DBD::SQLite  Encode Number::Format Date::Simple  
	Data::Dumper PDF::API2 );
for my $module (@modules) {
  eval "require $module";
  my $ok = '';
  if ($@) { $ok =  "Instalar"; } else { $ok = "Disponible"; }
  printf ("%-23s  %-s \n", ($module, $ok)); 
}

