#!/usr/bin/perl -w
	
my @archivos = glob("96537850-2/*.db3");
my $patron = "(.)\/([0-9]+)(.db3)";
my $a = @archivos - 1;
print "$a \n";
foreach $_ ( @archivos ) {
	print  "$2 \n" if /$patron/ ;
}
